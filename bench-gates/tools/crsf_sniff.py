#!/usr/bin/env python3
"""CRSF frame sniffer / decoder for a READ-ONLY USB serial tap (W17 bench gates).

WHAT THIS IS FOR
    Gate BG-06 "CRSF on the wire" and Phase B item B1.1 both ask the same
    question: are real CRSF frames actually on the wire, and do they decode?
    This tool answers it from a passive tap. It NEVER writes a byte to the
    serial port, never opens a port for writing, and has no transmit path at
    all -- a sniffer that can talk is a sniffer that can move a car.

    It also runs entirely offline against a captured byte file, which is how
    it was tested (see test_crsf_sniff.py) with no hardware present.

PROTOCOL (authoritative source: w17-control-fw/lib/crsf/include/crsf/CrsfFrame.hpp)
    frame  = [sync 0xC8][length][type][payload ...][crc8]
      - `length` counts everything after itself: type + payload + crc
        (CrsfFrame.hpp:9-12).
      - CRC8 poly 0xD5 (DVB-S2 style) over [type + payload] only -- not sync,
        not length, not the crc byte (CrsfFrame.hpp:11-12, :51-52;
        implementation mirrored from CrsfParser.cpp:5-15).
      - RC_CHANNELS_PACKED type 0x16, payload 22 B = 16 x 11 bits, LSB-first
        little-endian packing (CrsfFrame.hpp:23, :54-56; CrsfParser.cpp:17-37).
      - LINK_STATISTICS 0x14, payload 10 B (CrsfFrame.hpp:28, :99-112).
      - BATTERY_SENSOR 0x08, payload 8 B, big-endian (CrsfFrame.hpp:33-34).
      - GPS 0x02, payload 15 B, big-endian (CrsfFrame.hpp:40-41).
      - FLIGHTMODE 0x21, NUL-terminated string, <=16 B (CrsfFrame.hpp:48-49).
      - Raw channel scale: 172 = -100 %, 992 = 0 %, 1811 = +100 %
        (CrsfFrame.hpp:66-68).

    Baud rates on this project, both 8N1 and NOT inverted:
      - RP1 receiver -> ESP32 #1 GPIO16 : 420000
        (CrsfFrame.hpp:89 `kCrsfBaud`, D8_BENCH_BRINGUP.md:65-66)
      - PC (mapper) -> ELRS TX module   : 921600 (mapper default)
        (w17-mapper/cmd/elrs-joystick-control/main.go:62,
         w17-mapper/configs/README.md:18-19)

USAGE
    python3 crsf_sniff.py --file capture.bin [--summary]
    python3 crsf_sniff.py --port /dev/tty.usbserial-XXXX --baud 420000 \
                          --seconds 20 --raw-out capture.bin --summary
    cat capture.bin | python3 crsf_sniff.py --stdin --summary

    --port needs pyserial (`python3 -m pip install pyserial`). Everything else
    -- decoding, replay, the tests -- is pure stdlib.

EXIT CODES
    0  ran to completion (this is NOT a gate verdict: read the summary)
    2  bad arguments / missing dependency
    3  I/O error on the port or file
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from dataclasses import dataclass, field
from typing import Iterator, Optional

# ---------------------------------------------------------------------------
# Protocol constants -- transcribed from CrsfFrame.hpp, not invented here.
# ---------------------------------------------------------------------------

SYNC_BYTE = 0xC8
CRC8_POLY = 0xD5

TYPE_GPS = 0x02
TYPE_BATTERY = 0x08
TYPE_LINK_STATISTICS = 0x14
TYPE_RC_CHANNELS_PACKED = 0x16
TYPE_FLIGHTMODE = 0x21

RC_CHANNELS_PAYLOAD_LEN = 22
NUM_CHANNELS = 16
RC_CHANNELS_LENGTH_BYTE = 1 + RC_CHANNELS_PAYLOAD_LEN + 1  # type + payload + crc = 24
LINK_STATISTICS_PAYLOAD_LEN = 10
BATTERY_PAYLOAD_LEN = 8
GPS_PAYLOAD_LEN = 15
FLIGHTMODE_MAX_LEN = 16

CHANNEL_RAW_MIN = 172
CHANNEL_RAW_CENTER = 992
CHANNEL_RAW_MAX = 1811

# `length` covers type + payload + crc. Minimum sane value is 2 (type + crc);
# the CRSF maximum frame is 64 bytes on the wire, so length <= 62.
MIN_LENGTH_BYTE = 2
MAX_LENGTH_BYTE = 62

TYPE_NAMES = {
    TYPE_GPS: "GPS",
    TYPE_BATTERY: "BATTERY",
    TYPE_LINK_STATISTICS: "LINK_STATISTICS",
    TYPE_RC_CHANNELS_PACKED: "RC_CHANNELS_PACKED",
    TYPE_FLIGHTMODE: "FLIGHTMODE",
}


def compute_crc8(data: bytes) -> int:
    """CRSF CRC8, poly 0xD5, MSB-first, init 0.

    Byte-for-byte the same algorithm as crsf::computeCrc8
    (w17-control-fw/lib/crsf/src/CrsfParser.cpp:5-15).
    """
    crc = 0
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = ((crc << 1) ^ CRC8_POLY) & 0xFF if crc & 0x80 else (crc << 1) & 0xFF
    return crc


def unpack_channels(payload: bytes) -> list[int]:
    """16 x 11-bit LSB-first channels out of a 22-byte payload.

    Mirrors crsf::unpackChannels (CrsfParser.cpp:17-37).
    """
    if len(payload) != RC_CHANNELS_PAYLOAD_LEN:
        raise ValueError(f"RC payload must be {RC_CHANNELS_PAYLOAD_LEN} bytes")
    out = []
    for ch in range(NUM_CHANNELS):
        bit_pos = ch * 11
        byte_idx, bit_off = divmod(bit_pos, 8)
        chunk = payload[byte_idx]
        if byte_idx + 1 < RC_CHANNELS_PAYLOAD_LEN:
            chunk |= payload[byte_idx + 1] << 8
        if byte_idx + 2 < RC_CHANNELS_PAYLOAD_LEN:
            chunk |= payload[byte_idx + 2] << 16
        out.append((chunk >> bit_off) & 0x7FF)
    return out


def pack_channels(channels: list[int]) -> bytes:
    """Inverse of unpack_channels -- used to build synthetic test frames."""
    if len(channels) != NUM_CHANNELS:
        raise ValueError(f"need exactly {NUM_CHANNELS} channels")
    acc = 0
    for i, value in enumerate(channels):
        if not 0 <= value <= 0x7FF:
            raise ValueError(f"channel {i} out of 11-bit range: {value}")
        acc |= value << (i * 11)
    return acc.to_bytes(RC_CHANNELS_PAYLOAD_LEN, "little")


def build_frame(frame_type: int, payload: bytes) -> bytes:
    """Assemble a complete on-wire CRSF frame with a correct CRC."""
    body = bytes([frame_type]) + payload
    return bytes([SYNC_BYTE, len(body) + 1]) + body + bytes([compute_crc8(body)])


def raw_to_percent(raw: int) -> float:
    """172/992/1811 -> -100/0/+100 %, linear on each side of centre."""
    if raw >= CHANNEL_RAW_CENTER:
        span = CHANNEL_RAW_MAX - CHANNEL_RAW_CENTER
        return 100.0 * (raw - CHANNEL_RAW_CENTER) / span
    span = CHANNEL_RAW_CENTER - CHANNEL_RAW_MIN
    return -100.0 * (CHANNEL_RAW_CENTER - raw) / span


# ---------------------------------------------------------------------------
# Frame model + per-type decoders
# ---------------------------------------------------------------------------


@dataclass
class Frame:
    t_ms: float
    frame_type: int
    payload: bytes
    crc_ok: bool
    raw: bytes

    @property
    def type_name(self) -> str:
        return TYPE_NAMES.get(self.frame_type, f"0x{self.frame_type:02X}")

    def decode(self) -> dict:
        """Decoded fields, or {} for a type this tool does not model."""
        p = self.payload
        if self.frame_type == TYPE_RC_CHANNELS_PACKED and len(p) == RC_CHANNELS_PAYLOAD_LEN:
            ch = unpack_channels(p)
            return {"channels": ch, "percent": [round(raw_to_percent(c), 1) for c in ch]}
        if self.frame_type == TYPE_LINK_STATISTICS and len(p) == LINK_STATISTICS_PAYLOAD_LEN:
            return {
                "uplink_rssi_ant1_dbm": -p[0],
                "uplink_rssi_ant2_dbm": -p[1],
                "uplink_lq": p[2],
                "uplink_snr_db": p[3] - 256 if p[3] > 127 else p[3],
                "active_antenna": p[4],
                "rf_mode_raw": p[5],
                "uplink_tx_power_raw": p[6],
                "downlink_rssi_dbm": -p[7],
                "downlink_lq": p[8],
                "downlink_snr_db": p[9] - 256 if p[9] > 127 else p[9],
            }
        if self.frame_type == TYPE_BATTERY and len(p) == BATTERY_PAYLOAD_LEN:
            return {
                "voltage_mv": int.from_bytes(p[0:2], "big") * 100,
                "current_ma": int.from_bytes(p[2:4], "big") * 100,
                "capacity_mah": int.from_bytes(p[4:7], "big"),
                "remaining_pct": p[7],
            }
        if self.frame_type == TYPE_GPS and len(p) == GPS_PAYLOAD_LEN:
            return {
                "lat_1e7": int.from_bytes(p[0:4], "big", signed=True),
                "lon_1e7": int.from_bytes(p[4:8], "big", signed=True),
                "groundspeed_kmh": int.from_bytes(p[8:10], "big") / 10.0,
                "heading_cdeg": int.from_bytes(p[10:12], "big"),
                "altitude_m": int.from_bytes(p[12:14], "big") - 1000,
                "sats": p[14],
            }
        if self.frame_type == TYPE_FLIGHTMODE and 0 < len(p) <= FLIGHTMODE_MAX_LEN:
            text = p.split(b"\x00", 1)[0].decode("ascii", errors="replace")
            return {"text": text}
        return {}

    def line(self) -> str:
        head = f"[{self.t_ms / 1000.0:9.3f}s] {self.type_name:<18}"
        if not self.crc_ok:
            return head + f" CRC-FAIL  len={len(self.payload)}  {self.raw.hex()}"
        d = self.decode()
        if self.frame_type == TYPE_RC_CHANNELS_PACKED:
            ch = d["channels"]
            shown = " ".join(f"{c:4d}" for c in ch[:8])
            return head + f" ch1-8 {shown}   (ch9={ch[8]} ch10={ch[9]})"
        if self.frame_type == TYPE_LINK_STATISTICS:
            return head + (
                f" upLQ={d['uplink_lq']:3d}%  upRSSI={d['uplink_rssi_ant1_dbm']}dBm"
                f"  SNR={d['uplink_snr_db']}dB  dnLQ={d['downlink_lq']}%"
            )
        if self.frame_type == TYPE_BATTERY:
            return head + f" {d['voltage_mv']} mV  {d['current_ma']} mA  {d['remaining_pct']}%"
        if self.frame_type == TYPE_FLIGHTMODE:
            return head + f" \"{d['text']}\""
        if self.frame_type == TYPE_GPS:
            return head + f" speed={d['groundspeed_kmh']} km/h  sats={d['sats']}"
        return head + f" len={len(self.payload)}  {self.payload.hex()}"


@dataclass
class Stats:
    bytes_in: int = 0
    frames_ok: int = 0
    frames_crc_fail: int = 0
    bytes_discarded: int = 0  # bytes dropped while hunting for a sync
    resyncs: int = 0
    by_type: dict = field(default_factory=dict)
    first_ms: Optional[float] = None
    last_ms: Optional[float] = None
    # True only for a live serial tap. File/stdin replay carries no real
    # timing, so a frame rate computed from it would be a fabricated number in
    # an evidence file -- it is reported as null instead.
    real_time: bool = False

    def note(self, frame: Frame) -> None:
        if frame.crc_ok:
            self.frames_ok += 1
            self.by_type[frame.type_name] = self.by_type.get(frame.type_name, 0) + 1
        else:
            self.frames_crc_fail += 1
        if self.first_ms is None:
            self.first_ms = frame.t_ms
        self.last_ms = frame.t_ms

    def summary(self) -> dict:
        span_s = 0.0
        if self.first_ms is not None and self.last_ms is not None:
            span_s = (self.last_ms - self.first_ms) / 1000.0
        rc = self.by_type.get("RC_CHANNELS_PACKED", 0)
        total = self.frames_ok + self.frames_crc_fail
        return {
            "bytes_in": self.bytes_in,
            "frames_ok": self.frames_ok,
            "frames_crc_fail": self.frames_crc_fail,
            "crc_fail_pct": round(100.0 * self.frames_crc_fail / total, 3) if total else 0.0,
            "bytes_discarded": self.bytes_discarded,
            "resyncs": self.resyncs,
            "timing": "live-serial" if self.real_time else "replay (no real timing)",
            "span_s": round(span_s, 3) if self.real_time else None,
            "rc_frame_rate_hz": (
                round(rc / span_s, 1) if (self.real_time and span_s > 0) else None
            ),
            "by_type": dict(sorted(self.by_type.items())),
        }


class CrsfStreamDecoder:
    """Byte-at-a-time resynchronising CRSF assembler.

    Deliberately conservative: a candidate sync byte whose length byte is out
    of range, or whose CRC fails, costs exactly ONE byte of resynchronisation,
    so a 0xC8 that happens to sit inside a payload cannot swallow the real
    frame that follows it.
    """

    def __init__(self, stats: Optional[Stats] = None) -> None:
        self.buf = bytearray()
        self.stats = stats if stats is not None else Stats()

    def feed(self, data: bytes, t_ms: float) -> Iterator[Frame]:
        self.stats.bytes_in += len(data)
        self.buf.extend(data)
        while True:
            # 1. Hunt for a sync byte.
            if not self.buf:
                return
            if self.buf[0] != SYNC_BYTE:
                idx = self.buf.find(bytes([SYNC_BYTE]))
                if idx < 0:
                    self.stats.bytes_discarded += len(self.buf)
                    self.buf.clear()
                    return
                self.stats.bytes_discarded += idx
                self.stats.resyncs += 1
                del self.buf[:idx]
                continue

            # 2. Need the length byte.
            if len(self.buf) < 2:
                return
            length = self.buf[1]
            if not (MIN_LENGTH_BYTE <= length <= MAX_LENGTH_BYTE):
                # Not a frame start after all -- drop one byte and rehunt.
                self.stats.bytes_discarded += 1
                self.stats.resyncs += 1
                del self.buf[:1]
                continue

            total = 2 + length
            if len(self.buf) < total:
                return

            raw = bytes(self.buf[:total])
            body = raw[2:-1]                 # type + payload
            received_crc = raw[-1]
            if compute_crc8(body) != received_crc:
                frame = Frame(t_ms, raw[2], raw[3:-1], False, raw)
                self.stats.note(frame)
                # One byte of resync, not `total` -- see the class docstring.
                self.stats.bytes_discarded += 1
                self.stats.resyncs += 1
                del self.buf[:1]
                yield frame
                continue

            frame = Frame(t_ms, raw[2], raw[3:-1], True, raw)
            self.stats.note(frame)
            del self.buf[:total]
            yield frame


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------


def iter_file(path: str, chunk: int = 256) -> Iterator[tuple[bytes, float]]:
    with open(path, "rb") as fh:
        t = 0.0
        while True:
            data = fh.read(chunk)
            if not data:
                return
            yield data, t
            t += 1.0  # synthetic 1 ms per chunk; replay carries no real timing


def iter_stdin(chunk: int = 256) -> Iterator[tuple[bytes, float]]:
    stream = sys.stdin.buffer
    t = 0.0
    while True:
        data = stream.read(chunk)
        if not data:
            return
        yield data, t
        t += 1.0


def iter_serial(port: str, baud: int, seconds: Optional[float]) -> Iterator[tuple[bytes, float]]:
    try:
        import serial  # type: ignore
    except ImportError:
        print(
            "ERROR: --port needs pyserial.  python3 -m pip install pyserial\n"
            "       (or capture bytes another way and replay with --file)",
            file=sys.stderr,
        )
        raise SystemExit(2)
    # READ-ONLY BY CONSTRUCTION: nothing in this tool ever calls write().
    with serial.Serial(port, baudrate=baud, timeout=0.05) as ser:
        t0 = time.monotonic()
        while True:
            now = time.monotonic()
            if seconds is not None and now - t0 >= seconds:
                return
            data = ser.read(4096)
            if data:
                yield data, (now - t0) * 1000.0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: Optional[list[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        description="Passive CRSF frame sniffer/decoder (read-only; never transmits)."
    )
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--port", help="serial device to tap, e.g. /dev/tty.usbserial-A50285BI")
    src.add_argument("--file", help="replay raw bytes from a capture file")
    src.add_argument("--stdin", action="store_true", help="replay raw bytes from stdin")
    ap.add_argument("--baud", type=int, default=420000,
                    help="420000 for RP1->ESP32, 921600 for PC->ELRS TX module (default: 420000)")
    ap.add_argument("--seconds", type=float, default=None, help="stop after N seconds (--port only)")
    ap.add_argument("--raw-out", help="tee every received byte to this file (evidence)")
    ap.add_argument("--max-frames", type=int, default=None, help="stop after N decoded frames")
    ap.add_argument("--quiet", action="store_true", help="suppress per-frame lines")
    ap.add_argument("--json", action="store_true", help="emit one JSON object per frame")
    ap.add_argument("--summary", action="store_true", help="print a JSON summary at the end")
    args = ap.parse_args(argv)

    if args.port:
        source = iter_serial(args.port, args.baud, args.seconds)
    elif args.file:
        source = iter_file(args.file)
    else:
        source = iter_stdin()

    stats = Stats(real_time=bool(args.port))
    decoder = CrsfStreamDecoder(stats)
    raw_fh = open(args.raw_out, "wb") if args.raw_out else None
    n = 0
    try:
        for chunk, t_ms in source:
            if raw_fh:
                raw_fh.write(chunk)
                raw_fh.flush()
            for frame in decoder.feed(chunk, t_ms):
                n += 1
                if not args.quiet:
                    if args.json:
                        print(json.dumps({
                            "t_ms": round(frame.t_ms, 3),
                            "type": frame.type_name,
                            "crc_ok": frame.crc_ok,
                            **frame.decode(),
                        }))
                    else:
                        print(frame.line())
                if args.max_frames is not None and n >= args.max_frames:
                    raise StopIteration
    except StopIteration:
        pass
    except KeyboardInterrupt:
        pass
    except (OSError, IOError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 3
    finally:
        if raw_fh:
            raw_fh.close()

    if args.summary:
        print(json.dumps(stats.summary(), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
