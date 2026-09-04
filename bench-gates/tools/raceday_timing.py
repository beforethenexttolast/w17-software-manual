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
#   2  usage / parse error: no timestamps, no spawn marker to measure from, or
#      a NEGATIVE-DURATION leg (the capture is not one run — e.g. two different
#      captures, such as G-04's Part A + Part B merged view, sorted together
#      and parsed as a single timeline; see G-04 "Exact commands")
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

    # ---------------------------------------------------------------- W17T
    # Structured lines added by the ground station on branch
    # offline/raceday-timing-logs (GS commit 2f2690a, the branch tip after the
    # R-G review fixes). Shape, verbatim:
    #   W17T {"ev":"<name>","t":"<ISO-8601 UTC>","m":<performance.now() ms>,...}
    # `m` is a process-relative monotonic companion to `t`: Windows Time
    # resyncs at boot, and G-04 Part A reboots between all five cold runs, so
    # the wall clock can step during the very seconds being measured. See the
    # WALL-CLOCK STEP check in analyse().
    # They are matched UNANCHORED on purpose. In the WS3 sink each line arrives
    # inside RACEDAY_PROBE_RESULT.probeLog[] with a wrapper prefix of its own,
    # `[t=<ISO> m=<ms>] `, added at
    # scripts/windows-validation/lib/race-day-probe.js:126; the original text
    # follows it verbatim, so every marker here still matches.
    ("t0", "RACE DAY pressed (the app's own line, not an operator marker)",
     r'W17T \{.*"ev":"raceday_press"',
     "w17-ground-station/main/raceDayOrchestrator.js:309 (branch offline/raceday-timing-logs @ 2f2690a)"),

    ("spawn", "ground station spawned the drive program (structured)",
     r'W17T \{.*"ev":"mapper_spawn".*"pid":(?P<pid>\d+)',
     "w17-ground-station/main/mapperRunner.js:238 (branch offline/raceday-timing-logs @ 2f2690a)"),

    ("link_claim", "ground station SAW the radio come up (its own read-only stream)",
     r'W17T \{.*"ev":"raceday_link_claim".*"kind":"(?P<kind>[^"]*)"',
     "w17-ground-station/main/raceDayOrchestrator.js:537 (branch offline/raceday-timing-logs @ 2f2690a)"),

    ("link_claim_late", "the radio came up AFTER the window closed (self-upgrade mirror)",
     r'W17T \{.*"ev":"raceday_link_late".*"kind":"(?P<kind>[^"]*)"',
     "w17-ground-station/main/raceDayOrchestrator.js:234 (the self-upgrade link mirror; branch offline/raceday-timing-logs @ 2f2690a)"),

    ("stop_press", "STOP RACE DAY pressed",
     r'W17T \{.*"ev":"raceday_stop_press"',
     "w17-ground-station/main/raceDayOrchestrator.js:748 (branch offline/raceday-timing-logs @ 2f2690a)"),
]

# A W17T line carries its OWN timestamp INSIDE the payload. That matters
# because the sink most likely to exist on Windows — the WS3 probe's stderr /
# its RACEDAY_PROBE_RESULT.probeLog[] array — is NOT stamped by any wrapper,
# so without this the parser would count every W17T line as untimestamped and
# drop it. The self-stamp is also strictly better than a wrapper stamp: it is
# taken inside the app at the event, not when the pipeline got round to
# reading the line.
W17T_SELF_TS = re.compile(r'W17T \{.*?"t":"(?P<t>[^"]+)"')

# The monotonic companion. `m` is Math.round(performance.now()) taken in the
# same expression as `t`, so it is process-relative and immune to a wall-clock
# step. G-04 Part A reboots Windows between all five cold runs and Windows Time
# resynchronises at boot: a step of hundreds of ms to seconds during the very
# 1-5 s being measured is a normal event, and without `m` it would land in the
# number with nothing in the capture to reveal it (R-G fix 3).
# Both endpoints of a leg must carry `m` for it to be used; `t` still places
# the line absolutely, which is what lets a GS line merge with the mapper's
# wrapper-stamped stdout in a Part B capture.
W17T_SELF_MONO = re.compile(r'W17T \{.*?"m":(?P<m>-?\d+)')

# How far the two clocks may disagree across one leg before the capture is
# suspect rather than the machine. Chosen as an ORDER OF MAGNITUDE below the
# thing being measured (LINK_UP_WAIT_MS = 5000) and well above scheduler noise
# on the two Date/performance.now() reads, which are microseconds apart in the
# same expression. It is a DETECTOR THRESHOLD for a corrupted capture, not a
# PASS/FAIL threshold for the gate -- no gate verdict depends on it.
WALL_CLOCK_STEP_TOLERANCE_MS = 250.0

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
                 fields: dict, mono: Optional[float] = None):
        self.ms = ms
        self.mono = mono
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

        # A W17T line stamps itself; prefer that over any wrapper stamp on the
        # same line (the wrapper stamp is a read time, the payload stamp is the
        # event time), and accept it when there is no wrapper stamp at all.
        self_m = W17T_SELF_TS.search(line)
        if self_m:
            when = _parse_datetime(self_m.group("t"))
            if when is not None:
                if base is None:
                    base = when
                ts_ms = (when - base).total_seconds() * 1000.0
                for pattern, _k in TS_PATTERNS:
                    mm = pattern.match(line)
                    if mm:
                        rest = mm.group("rest")
                        break
                stamped += 1
                mono_m = W17T_SELF_MONO.search(line)
                mono = float(mono_m.group("m")) if mono_m else None
                for kind, name, rx, cite in COMPILED:
                    m = rx.search(rest)
                    if m:
                        events.append(Event(ts_ms, kind, name, cite, rest.strip(), line_no,
                                            {k: v for k, v in (m.groupdict() or {}).items()
                                             if v is not None},
                                            mono))
                        break
                continue

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
    claim = first(events, "link_claim")
    claim_late = first(events, "link_claim_late")
    stop_press = first(events, "stop_press")
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
        wall = b.ms - a.ms
        # Prefer the monotonic delta whenever BOTH endpoints carry `m`. They
        # are only comparable within one process run, which is exactly what a
        # leg is here (raceDayOrchestrator and MapperRunner share the main
        # process and the same `log` seam).
        if a.mono is not None and b.mono is not None:
            mono = b.mono - a.mono
            drift = abs(wall - mono)
            if drift > WALL_CLOCK_STEP_TOLERANCE_MS:
                findings.append(
                    "WALL-CLOCK STEP during %r: the wall clock says %.0f ms and the "
                    "monotonic clock says %.0f ms, a disagreement of %.0f ms (tolerance "
                    "%.0f ms). Windows Time almost certainly resynchronised mid-run. The "
                    "monotonic figure is the one reported; treat the wall-clock number in "
                    "this capture as unusable and say so in the evidence."
                    % (name, wall, mono, drift, WALL_CLOCK_STEP_TOLERANCE_MS))
                clock_note = ("monotonic (`m`); the wall clock disagreed by %.0f ms and "
                              "was discarded" % drift)
            else:
                clock_note = ("monotonic (`m`); wall clock agreed to within %.0f ms"
                              % drift)
            note = (note + "; " + clock_note) if note else clock_note
            legs.append({"leg": name, "ms": mono, "clock": "monotonic",
                         "wall_ms": wall, "note": note})
            return
        note_wall = "wall clock only (no `m` on both endpoints)"
        note = (note + "; " + note_wall) if note else note_wall
        legs.append({"leg": name, "ms": wall, "clock": "wall", "note": note})

    leg("press -> spawn", t0, spawn)
    leg("spawn -> headless bring-up begins", spawn, bringup)
    leg("bring-up -> port open attempted", bringup, try_open)
    leg("port open attempted -> port OPEN", try_open, opened)
    leg("port OPEN -> send loop running", opened, send)
    leg("spawn -> port OPEN  (THE GATE MEASUREMENT)", spawn, opened,
        "compared against LINK_UP_WAIT_MS")
    leg("press -> port OPEN  (what the operator experiences)", t0, opened)
    leg("press -> GS saw the radio up (W17T)", t0, claim,
        "GS-side observation; +0..100 ms poll quantisation (_awaitLink stepMs=100)")
    leg("spawn -> GS saw the radio up (W17T)", spawn, claim,
        "GS-side fallback gate when the mapper's own stdout is not in this capture")
    leg("press -> radio up LATE, after the window (W17T)", t0, claim_late,
        "the over-window datum G-04 criterion 1 asks for (raceDayOrchestrator.js:234)")
    leg("STOP pressed -> drive program exited", stop_press, exited,
        "G-04 criterion 10; the checklist asks for this lag and states no threshold")

    # A negative-duration leg means this capture is not one run: two different
    # captures (most commonly G-04's Part A cold-run file merged with its
    # Part B GS-side file, `sort -m`'d together per the card's "Exact
    # commands") were parsed as if they were a single timeline, so an event
    # that really happened later ends up stamped earlier than one it should
    # follow. Nothing else in this script can detect that on its own — the
    # parser has no notion of "which file did this line come from" once the
    # lines are merged — so any leg computed below zero is refused outright,
    # the same way an unstamped capture is refused, rather than reported as a
    # PASS with implausible headroom.
    negative_legs = [l for l in legs if l["ms"] is not None and l["ms"] < 0]

    gate = next(l for l in legs if l["leg"].startswith("spawn -> port OPEN"))
    measured = gate["ms"]
    gate_source = "mapper's own '(port-loop)(initial) port ... opened' line"
    gate_is_fallback = False
    if measured is None and not negative_legs:
        fallback = next(l for l in legs if l["leg"].startswith("spawn -> GS saw"))
        if fallback["ms"] is not None:
            measured = fallback["ms"]
            gate_is_fallback = True
            gate_source = ("ground station's own W17T raceday_link_claim (the mapper's "
                           "stdout is not in this capture); includes 0..100 ms of poll "
                           "quantisation and is the GS's OBSERVATION of the claim, not "
                           "the port-open instant")
            findings.append(
                "the gate number below is the GROUND STATION's observation of the link "
                "claim, not the mapper's own port-open line. It is late by 0..100 ms "
                "(raceDayOrchestrator.js:512 _awaitLink polls every 100 ms) and is an "
                "upper bound on the true port-open latency.")
    if measured is None and not negative_legs and claim_late is not None:
        findings.append(
            "the radio came up AFTER the window closed; see the 'radio up LATE' leg for "
            "how far outside it was. That number is the datum G-04 criterion 1 asks for.")

    if negative_legs:
        bad = ", ".join(repr(l["leg"]) for l in negative_legs)
        findings.append(
            "NEGATIVE LEG DURATION on %s: an end-event is timestamped BEFORE its "
            "start-event, so this capture is not one run. This is what a merged "
            "side-by-side view (e.g. G-04's Part A cold-run file sorted together "
            "with its Part B GS-side file) looks like when it is fed to this parser "
            "as if it were a single timeline — the two files come from different "
            "runs, minutes or hours apart, and their events interleave without "
            "regard for which run they belong to. Such a merged view is a reading "
            "aid only, never a gate measurement: the gate always comes from a "
            "single Part A capture on its own (see G-04 'Exact commands')." % bad)
        verdict = "UNUSABLE"
        reason = ("this capture contains %d negative-duration leg(s) (%s) and cannot "
                  "be scored as a gate measurement — it is not one run" % (len(negative_legs), bad))
        measured = None
        gate_source = None
    elif measured is None:
        verdict = "FAIL"
        reason = ("the radio claim was never observed in this capture, so the "
                  "window cannot be said to have been met")
    elif measured <= window_ms:
        verdict = "PASS"
        if gate_is_fallback:
            reason = ("the ground station OBSERVED the radio link up %.0f ms after spawn "
                      "(an upper bound — see FINDINGS; the mapper's own port-open line is "
                      "not in this capture), inside the %.0f ms window" % (measured, window_ms))
        else:
            reason = ("the transmitter port opened %.0f ms after spawn, inside the "
                      "%.0f ms window" % (measured, window_ms))
    else:
        verdict = "FAIL"
        if gate_is_fallback:
            reason = ("the ground station OBSERVED the radio link up %.0f ms after spawn "
                      "(an upper bound — see FINDINGS; the mapper's own port-open line is "
                      "not in this capture), OUTSIDE the %.0f ms window — this is the datum "
                      "that settles the constant, not only a red mark" % (measured, window_ms))
        else:
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
        "gate_source": gate_source,
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
        "unusable": bool(negative_legs),
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
    if (first(events, "spawn") is None and first(events, "port_open_ok") is None
            and first(events, "t0") is None):
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

    if result.get("unusable"):
        return EXIT_USAGE
    return EXIT_PASS if result["verdict"] == "PASS" else EXIT_FAIL


if __name__ == "__main__":
    raise SystemExit(main())
