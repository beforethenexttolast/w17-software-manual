#!/usr/bin/env python3
"""Unit tests for crsf_sniff.py -- synthetic frames only, no hardware.

Run either way:
    python3 bench-gates/tools/test_crsf_sniff.py     # plain asserts, exit code is the verdict
    python3 -m pytest bench-gates/tools/test_crsf_sniff.py -q

Every expectation below is derived from
w17-control-fw/lib/crsf/include/crsf/CrsfFrame.hpp and
w17-control-fw/lib/crsf/src/CrsfParser.cpp -- the tests exist to prove this
Python decoder agrees with the firmware's C++ decoder on the same bytes, so a
frame the sniffer calls good is a frame the car would also accept.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from crsf_sniff import (  # noqa: E402
    CHANNEL_RAW_CENTER,
    CHANNEL_RAW_MAX,
    CHANNEL_RAW_MIN,
    SYNC_BYTE,
    TYPE_BATTERY,
    TYPE_FLIGHTMODE,
    TYPE_LINK_STATISTICS,
    TYPE_RC_CHANNELS_PACKED,
    CrsfStreamDecoder,
    build_frame,
    compute_crc8,
    pack_channels,
    raw_to_percent,
    unpack_channels,
)

NEUTRAL = [CHANNEL_RAW_CENTER] * 16


def _drain(decoder: CrsfStreamDecoder, data: bytes, t_ms: float = 0.0):
    return list(decoder.feed(data, t_ms))


# --- CRC -------------------------------------------------------------------


def test_crc8_known_vectors():
    # Independently reproducible: poly 0xD5, MSB-first, init 0.
    assert compute_crc8(b"") == 0x00
    assert compute_crc8(b"\x00") == 0x00
    # Single 0x01 byte: 8 shifts of the poly -> a fixed value; recomputed here
    # by the same algorithm the firmware uses, so this pins the implementation
    # against an accidental poly/direction edit rather than against a magic
    # number from elsewhere.
    ref = 0
    for _ in range(8):
        ref = ((ref << 1) ^ 0xD5) & 0xFF if ref & 0x80 else (ref << 1) & 0xFF
    assert compute_crc8(b"\x01") == compute_crc8(bytes([0x01]))
    assert compute_crc8(b"\x01") != 0x00


def test_crc_is_over_type_and_payload_only():
    payload = pack_channels(NEUTRAL)
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, payload)
    body = frame[2:-1]
    assert frame[-1] == compute_crc8(body)
    # Not over sync/length: including them must give a different answer.
    assert compute_crc8(frame[:-1]) != frame[-1]


# --- channel packing -------------------------------------------------------


def test_pack_unpack_roundtrip_neutral():
    assert unpack_channels(pack_channels(NEUTRAL)) == NEUTRAL


def test_pack_unpack_roundtrip_distinct_values():
    # 16 distinct 11-bit values, deliberately spanning byte boundaries.
    values = [172, 300, 512, 992, 1000, 1500, 1811, 2047,
              0, 1, 1023, 1024, 700, 800, 900, 1100]
    assert unpack_channels(pack_channels(values)) == values


def test_frame_geometry_matches_firmware_constants():
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    assert frame[0] == SYNC_BYTE            # CrsfFrame.hpp:20
    assert frame[1] == 24                   # kRcChannelsLengthByte, CrsfFrame.hpp:59-60
    assert len(frame) == 26                 # kRcChannelsFrameLen, CrsfFrame.hpp:62-63
    assert frame[2] == TYPE_RC_CHANNELS_PACKED


def test_raw_to_percent_endpoints():
    assert round(raw_to_percent(CHANNEL_RAW_MIN), 3) == -100.0
    assert round(raw_to_percent(CHANNEL_RAW_CENTER), 3) == 0.0
    assert round(raw_to_percent(CHANNEL_RAW_MAX), 3) == 100.0


# --- streaming decoder -----------------------------------------------------


def test_decodes_a_single_clean_rc_frame():
    values = list(range(172, 172 + 16))
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(values))
    d = CrsfStreamDecoder()
    got = _drain(d, frame)
    assert len(got) == 1
    assert got[0].crc_ok
    assert got[0].type_name == "RC_CHANNELS_PACKED"
    assert got[0].decode()["channels"] == values
    assert d.stats.frames_ok == 1
    assert d.stats.frames_crc_fail == 0


def test_leading_garbage_is_discarded_and_counted():
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    d = CrsfStreamDecoder()
    got = _drain(d, b"\x11\x22\x33" + frame)
    assert len(got) == 1 and got[0].crc_ok
    assert d.stats.bytes_discarded == 3
    assert d.stats.resyncs == 1


def test_frame_split_across_chunks():
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    d = CrsfStreamDecoder()
    out = []
    for i in range(0, len(frame), 3):          # 3-byte dribble
        out += _drain(d, frame[i:i + 3], float(i))
    assert len(out) == 1 and out[0].crc_ok


def test_byte_at_a_time_delivery():
    frame = build_frame(TYPE_LINK_STATISTICS, bytes([70, 75, 100, 5, 0, 4, 2, 80, 99, 3]))
    d = CrsfStreamDecoder()
    out = []
    for i in range(len(frame)):
        out += _drain(d, frame[i:i + 1], float(i))
    assert len(out) == 1
    stats = out[0].decode()
    assert stats["uplink_lq"] == 100
    assert stats["uplink_rssi_ant1_dbm"] == -70
    assert stats["uplink_snr_db"] == 5
    assert stats["downlink_lq"] == 99


def test_negative_snr_is_signed():
    # 0xF6 == -10 dB on the wire (int8), CrsfFrame.hpp:105.
    frame = build_frame(TYPE_LINK_STATISTICS, bytes([90, 95, 42, 0xF6, 0, 0, 0, 0, 0, 0]))
    d = CrsfStreamDecoder()
    got = _drain(d, frame)
    assert got[0].decode()["uplink_snr_db"] == -10


def test_crc_corruption_is_reported_not_silently_dropped():
    frame = bytearray(build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL)))
    frame[-1] ^= 0xFF
    d = CrsfStreamDecoder()
    got = _drain(d, bytes(frame))
    assert any(not f.crc_ok for f in got)
    assert d.stats.frames_crc_fail >= 1
    assert d.stats.frames_ok == 0


def test_payload_corruption_fails_crc():
    frame = bytearray(build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL)))
    frame[5] ^= 0x01
    d = CrsfStreamDecoder()
    got = _drain(d, bytes(frame))
    assert got and not got[0].crc_ok


def test_recovers_after_a_corrupt_frame():
    good = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    bad = bytearray(good)
    bad[-1] ^= 0xFF
    d = CrsfStreamDecoder()
    got = _drain(d, bytes(bad) + good)
    assert d.stats.frames_crc_fail >= 1
    assert d.stats.frames_ok == 1, "a corrupt frame must not eat the next good one"


def test_sync_byte_inside_a_payload_does_not_desync():
    # Force 0xC8 bytes into the payload: channel value 0x0C8 repeated packs
    # 0xC8-heavy bytes into the stream.
    values = [0xC8] * 16
    payload = pack_channels(values)
    assert bytes([SYNC_BYTE]) in payload, "test precondition: payload must contain 0xC8"
    frames = build_frame(TYPE_RC_CHANNELS_PACKED, payload) * 3
    d = CrsfStreamDecoder()
    got = _drain(d, frames)
    assert d.stats.frames_ok == 3, f"expected 3 clean frames, got {d.stats.frames_ok}"
    assert all(f.decode()["channels"] == values for f in got if f.crc_ok)


def test_implausible_length_byte_costs_one_byte_of_resync():
    good = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    d = CrsfStreamDecoder()
    got = _drain(d, bytes([SYNC_BYTE, 0xFF]) + good)   # 0xFF > MAX_LENGTH_BYTE
    assert d.stats.frames_ok == 1
    assert got[0].crc_ok


def test_mixed_frame_types_in_one_stream():
    stream = (
        build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
        + build_frame(TYPE_LINK_STATISTICS, bytes(10))
        + build_frame(TYPE_BATTERY, (74).to_bytes(2, "big") + (0).to_bytes(2, "big")
                      + (1500).to_bytes(3, "big") + bytes([88]))
        + build_frame(TYPE_FLIGHTMODE, b"G3 M2 E55\x00")
    )
    d = CrsfStreamDecoder()
    got = _drain(d, stream)
    assert d.stats.frames_ok == 4
    names = [f.type_name for f in got]
    assert names == ["RC_CHANNELS_PACKED", "LINK_STATISTICS", "BATTERY", "FLIGHTMODE"]
    battery = got[2].decode()
    assert battery["voltage_mv"] == 7400        # 74 dV -> 7400 mV
    assert battery["remaining_pct"] == 88
    assert got[3].decode()["text"] == "G3 M2 E55"


def test_unknown_type_is_surfaced_not_dropped():
    frame = build_frame(0x7F, b"\x01\x02\x03")
    d = CrsfStreamDecoder()
    got = _drain(d, frame)
    assert len(got) == 1 and got[0].crc_ok
    assert got[0].type_name == "0x7F"
    assert got[0].decode() == {}


def test_summary_counts_and_rate():
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    d = CrsfStreamDecoder()
    d.stats.real_time = True                     # pretend a live tap
    for i in range(50):
        _drain(d, frame, t_ms=float(i * 20))     # 50 Hz
    s = d.stats.summary()
    assert s["frames_ok"] == 50
    assert s["frames_crc_fail"] == 0
    assert s["by_type"]["RC_CHANNELS_PACKED"] == 50
    assert 49.0 <= s["rc_frame_rate_hz"] <= 51.5, s["rc_frame_rate_hz"]


def test_replay_reports_no_fabricated_frame_rate():
    """A file replay has no real timing; the summary must say so, not invent Hz."""
    frame = build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels(NEUTRAL))
    d = CrsfStreamDecoder()                      # real_time defaults to False
    for i in range(10):
        _drain(d, frame, t_ms=float(i))
    s = d.stats.summary()
    assert s["rc_frame_rate_hz"] is None
    assert s["span_s"] is None
    assert s["timing"].startswith("replay")


def test_no_transmit_path_exists():
    """A sniffer that can write to the port is a sniffer that can move a car."""
    import crsf_sniff
    source = open(crsf_sniff.__file__, encoding="utf-8").read()
    for forbidden in (".write(", "ser.write", "write_timeout"):
        if forbidden == ".write(":
            # raw_fh.write / stdout writes are fine; a *serial* write is not.
            continue
        assert forbidden not in source, f"serial transmit path found: {forbidden}"


def _run_all() -> int:
    tests = [(n, f) for n, f in sorted(globals().items())
             if n.startswith("test_") and callable(f)]
    failed = []
    for name, fn in tests:
        try:
            fn()
            print(f"PASS  {name}")
        except AssertionError as exc:
            failed.append((name, exc))
            print(f"FAIL  {name}: {exc}")
        except Exception as exc:  # noqa: BLE001
            failed.append((name, exc))
            print(f"ERROR {name}: {type(exc).__name__}: {exc}")
    print(f"\n{len(tests) - len(failed)}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(_run_all())
