#!/usr/bin/env python3
# W17 OFFLINE READINESS — bench-gate tooling (card G-04).
#
# Read a TIMESTAMPED capture of the race-day bring-up and report the deltas
#   t0 press -> mapper spawn -> radio-link claim
# with a PASS/FAIL against the ground station's own link window.
#
# ------------------------------------------------------------------ WHY THIS
# NEEDS A WRAPPER TO PRODUCE ITS INPUT (an instrumentation gap, not a design
# choice of this script):
#
#   * the ground station's main-process log is bare `console.log(m)` with NO
#     timestamp of any kind — w17-ground-station/main/main.js:62;
#   * the mapper writes its own lines with bare `fmt.Printf`, also untimestamped
#     — w17-mapper/pkg/link/port.go:47-49, pkg/client/grpc_client.go:298;
#   * under RACE DAY the mapper's stdout is piped ONLY into a bounded in-memory
#     ring (200 lines, 400 chars each) and never echoed or written to a file —
#     w17-ground-station/main/mapperRunner.js:39-40,144-151,167.
#
# So NO artifact the shipped software produces carries the instants this gate
# needs. Card G-04 prescribes a capture wrapper that stamps every line as it
# arrives; this script parses that. See G-04 "Exact commands".
#
# ACCEPTED LINE SHAPES (timestamp first, then the original line verbatim):
#   2026-09-12T14:03:21.417Z  [mapper] started managed (pid 8123): ...
#   2026-09-12 14:03:21.417   (port-loop)(initial) port COM7 opened
#   14:03:21.417              (bring-up) starting the radio link on COM7 ...
#   [2026-09-12T14:03:21.417Z] ...            (brackets are tolerated)
# A wall-clock-only shape (HH:MM:SS.mmm) is handled, including one midnight
# wrap; a date-bearing shape is preferred and is what the card's commands emit.
#
# EXIT CODES
#   0  parsed, and the link was claimed inside the window   (PASS)
#   1  parsed, and it was not                                (FAIL)
#   2  usage / parse error: no timestamps, or no spawn marker to measure from
#
# No dependencies beyond the standard library. Python 3.8+.

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from typing import List, Optional, Sequence, Tuple

EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_USAGE = 2

# --------------------------------------------------------------------------
# The window this gate judges against. NOT invented here:
#   w17-ground-station/main/raceDayOrchestrator.js:97
#     const LINK_UP_WAIT_MS = 5000;
# and the constant is itself recorded as unvalidated:
#   raceDayOrchestrator.js:89-96  "[bench-TBD] — this value is NOT validated"
#   w17-ground-station/README.md:260-264, docs/GIFTEE_FIRST_LAUNCH.md:134-143
# The point of this gate is to SETTLE that number, so a FAIL here is a datum
# about the constant as much as a verdict about the rig.
DEFAULT_WINDOW_MS = 5000
WINDOW_CITATION = "w17-ground-station/main/raceDayOrchestrator.js:97 (LINK_UP_WAIT_MS = 5000, [bench-TBD] at :89-96)"

# --------------------------------------------------------------------------
# Markers. Every one is a literal the code really prints; the citation travels
# with it into the JSON so an evidence file can be audited without this source.
#
# kind: one of  t0 | spawn | bringup | port_open_try | port_open_ok |
#               port_open_err | send_loop | link_not_yet | exit | refusal
MARKERS: List[Tuple[str, str, str, str]] = [
    # (kind, human name, regex, citation)
    ("t0", "RACE DAY pressed (operator marker)",
     r"W17-RACEDAY-T0",
     "emitted by the capture wrapper in card G-04; nothing in the app logs the press"),

    ("spawn", "ground station spawned the drive program",
     r"\[mapper\] started managed \(pid (?P<pid>\d+)\)",
     "w17-ground-station/main/mapperRunner.js:225"),

    ("bringup", "mapper began its own headless radio bring-up",
     r"\(bring-up\) starting the radio link on (?P<port>\S+) at (?P<baud>\d+) baud",
     "w17-mapper/pkg/client/grpc_client.go:298"),

    ("port_open_try", "mapper began opening the transmitter serial port",
     r"\(port-loop\)\(initial\) opening port (?P<port>\S+)",
     "w17-mapper/pkg/link/port.go:47"),

    ("port_open_ok", "transmitter serial port OPEN — the radio claim",
     r"\(port-loop\)\(initial\) port (?P<port>\S+) opened",
     "w17-mapper/pkg/link/port.go:49"),

    ("port_open_err", "transmitter serial port failed to open on the first try",
     r"\(port-loop\)\(initial\) error opening port (?P<port>\S+)",
     "w17-mapper/pkg/link/port.go:54"),

    ("port_open_ok", "transmitter serial port re-opened after backoff",
     r"\(port-loop\)\(backoff\) port (?P<port>\S+) re-opened",
     "w17-mapper/pkg/link/port.go:91"),

    ("send_loop", "CRSF send loop started",
     r"\(send-loop\) starting, refresh rate (?P<rate>\S+)",
     "w17-mapper/pkg/link/send.go:218"),

    ("link_not_yet", "ground station's link window closed with no claim",
     r"\[raceday\] the drive program has not raised the radio yet",
     "w17-ground-station/main/raceDayOrchestrator.js:481"),

    ("exit", "the drive program exited",
     r"\[mapper\] exited \((?P<code>[^)]*)\)",
     "w17-ground-station/main/mapperRunner.js:222"),

    ("refusal", "bring-up refused the saved profile or found no port",
     r"\(bring-up\) the saved profile (?:declares no transmitter"
     r"|declares a transmitter but its serial port"
     r"|declares \d+ transmitters)",
     "w17-mapper/pkg/client/grpc_client.go:279-290"),
]

COMPILED = [(kind, name, re.compile(rx), cite) for kind, name, rx, cite in MARKERS]

# --------------------------------------------------------------------------
# Timestamp shapes, most specific first.
TS_PATTERNS = [
    # 2026-09-12T14:03:21.417Z / 2026-09-12 14:03:21.417 / +00:00 offsets
    (re.compile(
        r"^\[?(?P<ts>\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:[.,]\d{1,9})?"
        r"(?:Z|[+-]\d{2}:?\d{2})?)\]?[ \t]+(?P<rest>.*)$"), "datetime"),
    # 14:03:21.417 / 14:03:21,417 / 14:03:21
    (re.compile(
        r"^\[?(?P<ts>\d{2}:\d{2}:\d{2}(?:[.,]\d{1,9})?)\]?[ \t]+(?P<rest>.*)$"), "clock"),
]


def die(msg: str) -> None:
    sys.stderr.write("error: %s\n" % msg)
    raise SystemExit(EXIT_USAGE)


def _parse_datetime(text: str) -> Optional[dt.datetime]:
    t = text.replace(",", ".")
    if t.endswith("Z"):
        t = t[:-1] + "+00:00"
    t = t.replace(" ", "T", 1)
    # fromisoformat on 3.8 wants exactly 3 or 6 fractional digits.
    m = re.match(r"^(.*\.\d+?)(\d*)(([+-]\d{2}:?\d{2})?)$", t)
    if m:
        frac = m.group(1).split(".")[-1] + m.group(2)
        frac = (frac + "000000")[:6]
        t = m.group(1).split(".")[0] + "." + frac + m.group(3)
    t = re.sub(r"([+-]\d{2})(\d{2})$", r"\1:\2", t)
    try:
        parsed = dt.datetime.fromisoformat(t)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def _parse_clock(text: str) -> Optional[dt.timedelta]:
    t = text.replace(",", ".")
    m = re.match(r"^(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?$", t)
    if not m:
        return None
    frac = (m.group(4) or "0")
    micros = int((frac + "000000")[:6])
    return dt.timedelta(hours=int(m.group(1)), minutes=int(m.group(2)),
                        seconds=int(m.group(3)), microseconds=micros)


class Event:
    def __init__(self, ms: float, kind: str, name: str, cite: str, raw: str, line_no: int,
                 fields: dict):
        self.ms = ms
        self.kind = kind
        self.name = name
        self.cite = cite
        self.raw = raw
        self.line_no = line_no
        self.fields = fields


def parse_log(lines: Sequence[str]) -> Tuple[List[Event], dict]:
    """Return (events, stats). Times are milliseconds from the FIRST stamped line."""
    stamped = 0
    unstamped = 0
    base: Optional[dt.datetime] = None
    base_clock: Optional[dt.timedelta] = None
    clock_day_offset = dt.timedelta(0)
    prev_clock: Optional[dt.timedelta] = None
    events: List[Event] = []

    for line_no, raw in enumerate(lines, start=1):
        line = raw.rstrip("\r\n")
        if not line.strip():
            continue

        ts_ms: Optional[float] = None
        rest = line
        for pattern, kind in TS_PATTERNS:
            m = pattern.match(line)
            if not m:
                continue
            rest = m.group("rest")
            if kind == "datetime":
                when = _parse_datetime(m.group("ts"))
                if when is None:
                    break
                if base is None:
                    base = when
                ts_ms = (when - base).total_seconds() * 1000.0
            else:
                clock = _parse_clock(m.group("ts"))
                if clock is None:
                    break
                # One midnight wrap is tolerated; a log that crosses midnight
                # twice is not a five-second bring-up and is not our problem.
                if prev_clock is not None and clock + clock_day_offset < prev_clock:
                    clock_day_offset += dt.timedelta(days=1)
                absolute = clock + clock_day_offset
                prev_clock = absolute
                if base_clock is None:
                    base_clock = absolute
                ts_ms = (absolute - base_clock).total_seconds() * 1000.0
            break

        if ts_ms is None:
            unstamped += 1
            continue
        stamped += 1

        for kind, name, rx, cite in COMPILED:
            m = rx.search(rest)
            if m:
                events.append(Event(ts_ms, kind, name, cite, rest.strip(), line_no,
                                    {k: v for k, v in (m.groupdict() or {}).items()
                                     if v is not None}))
                break

    stats = {"lines_total": len(lines), "lines_timestamped": stamped,
             "lines_untimestamped": unstamped, "markers_found": len(events)}
    return events, stats


def first(events: Sequence[Event], kind: str) -> Optional[Event]:
    for e in events:
        if e.kind == kind:
            return e
    return None


def analyse(events: List[Event], window_ms: float) -> dict:
    t0 = first(events, "t0")
    spawn = first(events, "spawn")
    bringup = first(events, "bringup")
    try_open = first(events, "port_open_try")
    opened = first(events, "port_open_ok")
    send = first(events, "send_loop")
    not_yet = first(events, "link_not_yet")
    exited = first(events, "exit")
    refusal = first(events, "refusal")

    findings: List[str] = []
    if t0 is None:
        findings.append(
            "no W17-RACEDAY-T0 marker: the press instant is unknown, so only the "
            "spawn-to-claim delta below is measured. Nothing in the ground station "
            "logs the button press (main/appWiring.js:338 calls raceDay.start() "
            "and start() logs nothing) — the marker has to come from the wrapper.")
    if spawn is None:
        findings.append(
            "no '[mapper] started managed' line: either race day did not spawn the "
            "drive program (already running externally, or a failed step before it) "
            "or the ground station's stdout was not in this capture.")
    if refusal is not None:
        findings.append("bring-up REFUSED the profile or found no usable port: %r"
                        % refusal.raw)
    if opened is None and not_yet is not None:
        findings.append(
            "the ground station's link window closed with no claim — expected step "
            "kind 'link-not-yet' on a FIRST bring-up (raceDayOrchestrator.js:480-483).")
    if exited is not None and opened is None:
        findings.append("the drive program exited before the port ever opened (%s)"
                        % exited.raw)
    if opened is not None and send is None:
        findings.append(
            "the port opened but no '(send-loop) starting' line followed: an open "
            "port is not yet CRSF on the wire. Frames on the wire stay bench "
            "evidence and are not established by this log.")

    legs = []

    def leg(name: str, a: Optional[Event], b: Optional[Event], note: str = "") -> None:
        if a is None or b is None:
            legs.append({"leg": name, "ms": None, "note": note or "endpoint marker missing"})
            return
        legs.append({"leg": name, "ms": b.ms - a.ms, "note": note})

    leg("press -> spawn", t0, spawn)
    leg("spawn -> headless bring-up begins", spawn, bringup)
    leg("bring-up -> port open attempted", bringup, try_open)
    leg("port open attempted -> port OPEN", try_open, opened)
    leg("port OPEN -> send loop running", opened, send)
    leg("spawn -> port OPEN  (THE GATE MEASUREMENT)", spawn, opened,
        "compared against LINK_UP_WAIT_MS")
    leg("press -> port OPEN  (what the operator experiences)", t0, opened)

    gate = next(l for l in legs if l["leg"].startswith("spawn -> port OPEN"))
    measured = gate["ms"]

    if measured is None:
        verdict = "FAIL"
        reason = ("the radio claim was never observed in this capture, so the "
                  "window cannot be said to have been met")
    elif measured <= window_ms:
        verdict = "PASS"
        reason = ("the transmitter port opened %.0f ms after spawn, inside the "
                  "%.0f ms window" % (measured, window_ms))
    else:
        verdict = "FAIL"
        reason = ("the transmitter port opened %.0f ms after spawn, OUTSIDE the "
                  "%.0f ms window — this is the datum that settles the constant, "
                  "not only a red mark" % (measured, window_ms))

    headroom = None if measured is None else window_ms - measured

    return {
        "window_ms": window_ms,
        "window_citation": WINDOW_CITATION,
        "timeline": [
            {"t_ms": e.ms, "kind": e.kind, "what": e.name, "line": e.line_no,
             "citation": e.cite, "fields": e.fields, "raw": e.raw}
            for e in events
        ],
        "legs": legs,
        "gate_measurement_ms": measured,
        "headroom_ms": headroom,
        "verdict": verdict,
        "reason": reason,
        "findings": findings,
        "evidence_label": ("OBSERVED only if this log came from a real run on the "
                           "target machine; NOT-EXECUTED otherwise. This script "
                           "cannot tell the difference."),
        "does_not_establish": [
            "CRSF frames reaching the receiver over RF — an open COM port is not "
            "a bound link (w17-windows-vm-validation-runbook.md:437-438).",
            "anything about FIRST_ACTIVE / R15, which stay NO-GO "
            "(W17_CURRENT_STATE.md:61, CURRENT_STATUS.md:1384-1385).",
        ],
    }


def render(result: dict, stats: dict) -> str:
    out = []
    a = out.append
    a("W17 RACE DAY bring-up timing")
    a("  capture: %d lines, %d timestamped, %d without a timestamp, %d markers matched"
      % (stats["lines_total"], stats["lines_timestamped"],
         stats["lines_untimestamped"], stats["markers_found"]))
    a("  window:  %.0f ms   (%s)" % (result["window_ms"], result["window_citation"]))
    a("")
    a("  TIMELINE (ms from the first timestamped line)")
    if not result["timeline"]:
        a("    (no markers matched — see findings)")
    for e in result["timeline"]:
        a("    %10.1f  %-14s %s" % (e["t_ms"], e["kind"], e["what"]))
        a("                %s   [%s]" % (e["raw"][:100], e["citation"]))
    a("")
    a("  LEGS")
    for l in result["legs"]:
        if l["ms"] is None:
            a("    %-46s     ----   (%s)" % (l["leg"], l["note"]))
        else:
            a("    %-46s %8.1f ms %s" % (l["leg"], l["ms"], l["note"]))
    a("")
    if result["findings"]:
        a("  FINDINGS")
        for f in result["findings"]:
            a("    - %s" % f)
        a("")
    a("  VERDICT: %s" % result["verdict"])
    a("    %s" % result["reason"])
    if result["headroom_ms"] is not None:
        a("    headroom against the window: %+.0f ms" % result["headroom_ms"])
    a("")
    a("  THIS DOES NOT ESTABLISH")
    for d in result["does_not_establish"]:
        a("    - %s" % d)
    return "\n".join(out)


def main(argv: Optional[Sequence[str]] = None) -> int:
    p = argparse.ArgumentParser(
        prog="raceday_timing.py",
        description="Parse a TIMESTAMPED race-day bring-up capture into "
                    "press -> spawn -> radio-claim deltas, with PASS/FAIL "
                    "against the ground station's link window.",
        epilog="exit 0 = PASS, 1 = FAIL, 2 = usage/parse error.")
    p.add_argument("logfile", nargs="?", default="-",
                   help="timestamped capture; '-' or omitted reads stdin")
    p.add_argument("--window-ms", type=float, default=DEFAULT_WINDOW_MS,
                   help="link window to judge against (default %d, from %s)"
                        % (DEFAULT_WINDOW_MS, WINDOW_CITATION))
    p.add_argument("--json", metavar="PATH",
                   help="also write the full result as JSON ('-' for stdout)")
    args = p.parse_args(argv)

    if args.window_ms <= 0:
        die("--window-ms must be positive")

    try:
        if args.logfile == "-":
            lines = sys.stdin.read().splitlines()
        else:
            with open(args.logfile, "r", encoding="utf-8", errors="replace") as fh:
                lines = fh.read().splitlines()
    except OSError as exc:
        die("could not read %s: %s" % (args.logfile, exc))
        return EXIT_USAGE  # unreachable

    events, stats = parse_log(lines)

    if stats["lines_timestamped"] == 0:
        die("no line in this capture carries a timestamp. The ground station "
            "(main/main.js:62) and the mapper (fmt.Printf) both log without one, "
            "so the capture MUST be stamped by the wrapper — see card G-04, "
            "'Exact commands'.")
    if first(events, "spawn") is None and first(events, "port_open_ok") is None:
        die("neither a spawn marker nor a port-open marker is present: there is "
            "nothing to measure. Check that BOTH the ground station's stdout and "
            "the drive program's stdout are in this capture.")

    result = analyse(events, args.window_ms)
    sys.stdout.write(render(result, stats) + "\n")

    if args.json:
        blob = json.dumps({"stats": stats, "result": result}, indent=2, sort_keys=True)
        if args.json == "-":
            sys.stdout.write(blob + "\n")
        else:
            try:
                with open(args.json, "w", encoding="utf-8") as fh:
                    fh.write(blob + "\n")
            except OSError as exc:
                die("could not write %s: %s" % (args.json, exc))

    return EXIT_PASS if result["verdict"] == "PASS" else EXIT_FAIL


if __name__ == "__main__":
    raise SystemExit(main())
