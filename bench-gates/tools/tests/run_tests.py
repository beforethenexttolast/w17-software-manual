#!/usr/bin/env python3
# W17 OFFLINE READINESS — self-test for the ground-side bench-gate tooling.
#
# Runs BOTH tools against the synthetic fixtures beside this file and asserts
# their numbers AND their exit codes. Pure standard library; no pytest needed.
#
#   python3 bench-gates/tools/tests/run_tests.py
#
# Exit 0 = every case passed. Exit 1 = at least one case failed.
#
# Nothing here touches hardware, a serial port, a network socket, the car, the
# mapper or the firmware. It runs two local scripts over text files.

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
PY = sys.executable or "python3"

RACEDAY = os.path.join(TOOLS, "raceday_timing.py")
LATENCY = os.path.join(TOOLS, "latency_from_frames.py")

failures = []
checks = 0


def check(label, condition, detail=""):
    global checks
    checks += 1
    if condition:
        print("  ok   %s" % label)
    else:
        print("  FAIL %s%s" % (label, ("  -- " + detail) if detail else ""))
        failures.append(label)


def run(argv):
    proc = subprocess.run([PY] + argv, capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def run_json(argv):
    with tempfile.NamedTemporaryFile("r", suffix=".json", delete=False) as fh:
        path = fh.name
    try:
        code, out, err = run(argv + ["--json", path])
        with open(path, "r", encoding="utf-8") as fh:
            blob = json.load(fh)
        return code, out, err, blob
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass


def near(a, b, tol=0.51):
    return a is not None and abs(a - b) <= tol


print("raceday_timing.py")

# --- 1. the happy path: spawn -> port open in 1904 ms, inside the 5000 ms window
code, out, err, blob = run_json([RACEDAY, os.path.join(HERE, "raceday_pass_capture.txt")])
r = blob["result"]
check("pass fixture exits 0", code == 0, "exit=%d stderr=%s" % (code, err.strip()))
check("pass fixture verdict PASS", r["verdict"] == "PASS", r["verdict"])
check("pass fixture spawn->open = 1904 ms", near(r["gate_measurement_ms"], 1904.0),
      str(r["gate_measurement_ms"]))
check("pass fixture headroom = +3096 ms", near(r["headroom_ms"], 3096.0),
      str(r["headroom_ms"]))
press_to_open = [l for l in r["legs"] if l["leg"].startswith("press -> port OPEN")][0]
check("pass fixture press->open = 1984 ms", near(press_to_open["ms"], 1984.0),
      str(press_to_open["ms"]))
check("pass fixture found the send loop",
      any(e["kind"] == "send_loop" for e in r["timeline"]))
check("pass fixture raised no findings", r["findings"] == [], str(r["findings"]))
check("pass fixture prints the window citation",
      "raceDayOrchestrator.js:97" in out)

# --- 2. a slow cold start: 7430 ms, outside the window, and the GS said not-yet
code, out, err, blob = run_json([RACEDAY, os.path.join(HERE, "raceday_fail_slow_capture.txt")])
r = blob["result"]
check("slow fixture exits 1", code == 1, "exit=%d" % code)
check("slow fixture verdict FAIL", r["verdict"] == "FAIL", r["verdict"])
check("slow fixture spawn->open = 7430 ms", near(r["gate_measurement_ms"], 7430.0),
      str(r["gate_measurement_ms"]))
check("slow fixture headroom = -2430 ms", near(r["headroom_ms"], -2430.0),
      str(r["headroom_ms"]))
check("slow fixture calls it a datum about the constant",
      "settles the constant" in r["reason"], r["reason"])
check("slow fixture accepts 'YYYY-MM-DD HH:MM:SS.mmm' stamps",
      blob["stats"]["lines_timestamped"] == 7,
      str(blob["stats"]["lines_timestamped"]))

# --- 3. the port never opens (clock-only timestamps)
code, out, err, blob = run_json([RACEDAY, os.path.join(HERE, "raceday_fail_never_capture.txt")])
r = blob["result"]
check("never fixture exits 1", code == 1, "exit=%d" % code)
check("never fixture has no gate measurement", r["gate_measurement_ms"] is None)
check("never fixture reports the window closed with no claim",
      any("window closed with no claim" in f for f in r["findings"]),
      str(r["findings"]))
check("never fixture accepts clock-only stamps",
      blob["stats"]["lines_timestamped"] == 8,
      str(blob["stats"]["lines_timestamped"]))

# --- 4. bring-up refused the profile (bracketed ISO stamps)
code, out, err, blob = run_json([RACEDAY, os.path.join(HERE, "raceday_refusal_capture.txt")])
r = blob["result"]
check("refusal fixture exits 1", code == 1, "exit=%d" % code)
check("refusal fixture surfaces the refusal",
      any("REFUSED" in f for f in r["findings"]), str(r["findings"]))
check("refusal fixture accepts bracketed stamps",
      blob["stats"]["lines_timestamped"] == 4,
      str(blob["stats"]["lines_timestamped"]))

# --- 5. an unstamped capture is a usage error, not a silent zero
code, out, err = run([RACEDAY, os.path.join(HERE, "raceday_unstamped_capture.txt")])
check("unstamped fixture exits 2", code == 2, "exit=%d" % code)
check("unstamped fixture names the instrumentation gap",
      "main/main.js:62" in err, err.strip()[:200])

# --- 6. a non-default window changes the verdict, and only the verdict
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_fail_slow_capture.txt"), "--window-ms", "8000"])
r = blob["result"]
check("slow fixture PASSes an 8000 ms window", code == 0 and r["verdict"] == "PASS",
      "%d/%s" % (code, r["verdict"]))
check("widening the window does not move the measurement",
      near(r["gate_measurement_ms"], 7430.0), str(r["gate_measurement_ms"]))

# --- 7. a missing file is a usage error
code, out, err = run([RACEDAY, os.path.join(HERE, "does-not-exist_capture.txt")])
check("missing logfile exits 2", code == 2, "exit=%d" % code)

# --- 8. the W17T structured lines the ground station emits on branch
#        offline/raceday-timing-logs (@ 2f2690a). Four fixtures, one per sink
#        and one per failure mode the card cares about.

# 8a. The WS3 sink: RACEDAY_PROBE_RESULT.probeLog[]. NO wrapper timestamp at
#     all, so the tool has to read the payload's own `t` or drop every line.
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_ws3_probelog_capture.txt")])
r = blob["result"]
check("ws3 probelog fixture exits 0", code == 0, "exit=%d stderr=%s" % (code, err.strip()))
check("ws3 probelog fixture is self-stamped, not wrapper-stamped",
      blob["stats"]["lines_timestamped"] == 4,
      str(blob["stats"]["lines_timestamped"]))
check("ws3 probelog gate falls back to the GS-side claim = 2104 ms",
      near(r["gate_measurement_ms"], 2104.0), str(r["gate_measurement_ms"]))
check("ws3 probelog says the gate number is a GS observation",
      "GROUND STATION" in r["gate_source"] or
      any("upper bound" in f for f in r["findings"]),
      str(r["gate_source"]))

# 8b. A Part B capture: wrapper-stamped, and the mapper's OWN port-open line is
#     present, so the real gate measurement wins over the GS-side fallback.
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_partb_merged_capture.txt")])
r = blob["result"]
check("partB merged fixture exits 0", code == 0, "exit=%d" % code)
check("partB merged gate = 2070 ms from the mapper's own line",
      near(r["gate_measurement_ms"], 2070.0), str(r["gate_measurement_ms"]))
gs_leg = [l for l in r["legs"] if l["leg"].startswith("spawn -> GS saw")][0]
check("partB merged shows the GS-side leg alongside it (2106 ms)",
      near(gs_leg["ms"], 2106.0), str(gs_leg["ms"]))

# 8c. The over-window case: the radio comes up AFTER LINK_UP_WAIT_MS closes.
#     Only the link mirror (raceDayOrchestrator.js:234) fires here, and this is
#     the datum G-04 criterion 1's FAIL branch asks for.
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_late_claim_capture.txt")])
r = blob["result"]
check("late-claim fixture exits 1", code == 1, "exit=%d" % code)
late = [l for l in r["legs"] if "radio up LATE" in l["leg"]][0]
check("late-claim reports how far outside the window it was (7840 ms)",
      near(late["ms"], 7840.0), str(late["ms"]))

# 8d. The FINAL shipped shapes: probeLog `[t=... m=...]` prefix AND the
#     monotonic `m` inside every payload.
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_final_shapes_capture.txt")])
r = blob["result"]
check("final-shapes fixture exits 1 (over-window)", code == 1, "exit=%d" % code)
check("final-shapes matched all four W17T markers despite the wrapper prefix",
      len([e for e in r["timeline"]
           if e["kind"] in ("t0", "spawn", "link_claim_late", "stop_press")]) == 4,
      str([e["kind"] for e in r["timeline"]]))
late = [l for l in r["legs"] if "radio up LATE" in l["leg"]][0]
check("final-shapes late leg = 9512 ms", near(late["ms"], 9512.0), str(late["ms"]))
check("final-shapes legs are measured on the monotonic clock",
      all(l.get("clock") == "monotonic" for l in r["legs"] if l["ms"] is not None),
      str([(l["leg"], l.get("clock")) for l in r["legs"] if l["ms"] is not None]))

# 8e. Windows Time resyncs mid-run -- the exact event G-04 Part A invites by
#     rebooting between all five cold runs. The wall clock steps +4000 ms
#     between press and the link claim; the monotonic clock does not. Without
#     `m` this capture reads 6104 ms and FAILS the 5000 ms window on a clock
#     bug rather than on the constant.
code, out, err, blob = run_json(
    [RACEDAY, os.path.join(HERE, "raceday_clock_step_capture.txt")])
r = blob["result"]
check("clock-step fixture exits 0", code == 0, "exit=%d" % code)
check("clock-step gate uses the monotonic delta (2104 ms, not 6104 ms)",
      near(r["gate_measurement_ms"], 2104.0), str(r["gate_measurement_ms"]))
check("clock-step raises a WALL-CLOCK STEP finding",
      any("WALL-CLOCK STEP" in f for f in r["findings"]), str(r["findings"]))
check("clock-step names the size of the disagreement",
      any("4000 ms" in f for f in r["findings"]), str(r["findings"]))
check("clock-step keeps the wall-clock figure visible for the record",
      any(l.get("wall_ms") is not None for l in r["legs"]),
      str([l.get("wall_ms") for l in r["legs"]]))


print("latency_from_frames.py")

pairs = os.path.join(HERE, "latency_pairs_phone.csv")

# --- 8. arithmetic, on the synthetic 240 fps set
code, out, err, blob = run_json(
    [LATENCY, "--fps", "240", "--pairs-file", pairs, "--label", "synthetic phone set"])
check("latency exits 0 with no target", code == 0, "exit=%d stderr=%s" % (code, err))
check("latency read 10 samples", blob["samples"] == 10, str(blob["samples"]))
# deltas: 36,39,34,38,35,41,34,37,36,39 -> sorted 34,34,35,36,36,37,38,39,39,41
# median = (36+37)/2 = 36.5 frames = 152.0833... ms
check("latency median = 152.083 ms", near(blob["median_ms"], 152.0833, 0.01),
      str(blob["median_ms"]))
check("latency min = 141.667 ms", near(blob["min_ms"], 141.6667, 0.01),
      str(blob["min_ms"]))
check("latency max = 170.833 ms", near(blob["max_ms"], 170.8333, 0.01),
      str(blob["max_ms"]))
check("latency random bound = one capture frame (4.1667 ms)",
      near(blob["uncertainty"]["random_bound_ms"], 4.16667, 0.001),
      str(blob["uncertainty"]["random_bound_ms"]))
check("latency verdict says no target was given",
      blob["verdict"].startswith("NO TARGET"), blob["verdict"])
check("latency flags p95 as not meaningful at n=10",
      blob["p95_meaningful"] is False and "NOT MEANINGFUL" in out)
check("latency warns that systematic bias is unaccounted",
      "NOT ACCOUNTED" in out)

# --- 9. targets: median 152.08 > 150 must FAIL, and must exit 1
code, out, err, blob = run_json(
    [LATENCY, "--fps", "240", "--pairs-file", pairs,
     "--median-target-ms", "150", "--p95-target-ms", "200"])
check("latency exits 1 when the median target is missed", code == 1, "exit=%d" % code)
check("latency verdict FAIL", blob["verdict"] == "FAIL", blob["verdict"])
check("latency reports the median check as failed",
      [c for c in blob["checks"] if c["name"] == "median"][0]["pass"] is False)
check("latency reports the p95 check as passed",
      [c for c in blob["checks"] if c["name"] == "p95"][0]["pass"] is True)

# --- 10. a target the set meets exits 0
code, out, err, blob = run_json(
    [LATENCY, "--fps", "240", "--pairs-file", pairs, "--median-target-ms", "160"])
check("latency exits 0 when the target is met", code == 0, "exit=%d" % code)
check("latency verdict PASS", blob["verdict"] == "PASS", blob["verdict"])

# --- 11. systematic bias terms shift the lower bound, never the measurement
code, out, err, blob = run_json(
    [LATENCY, "--fps", "240", "--pairs-file", pairs,
     "--src-refresh-hz", "60", "--camera-fps", "60", "--dst-refresh-hz", "120"])
bias = blob["uncertainty"]["systematic_bias_max_ms"]
check("bias = 16.667 + 16.667 + 8.333 = 41.667 ms", near(bias, 41.6667, 0.01), str(bias))
check("bias does not move the median", near(blob["median_ms"], 152.0833, 0.01))
lo, hi = blob["median_interval_ms"]
check("median interval low = median - random - bias",
      near(lo, 152.0833 - 4.16667 - 41.6667, 0.01), str(lo))
check("median interval high = median + random", near(hi, 152.0833 + 4.16667, 0.01), str(hi))

# --- 12. inline --pair, and a single-sample run
code, out, err, blob = run_json([LATENCY, "--fps", "240", "--pair", "100,124,one"])
check("single --pair exits 0", code == 0, "exit=%d" % code)
check("single --pair median = 100 ms", near(blob["median_ms"], 100.0, 0.01),
      str(blob["median_ms"]))

# --- 13. input errors are exit 2, never a number
code, out, err = run([LATENCY, "--fps", "240"])
check("no samples exits 2", code == 2, "exit=%d" % code)
code, out, err = run([LATENCY, "--fps", "240", "--pair", "500,400"])
check("display-before-source exits 2", code == 2, "exit=%d" % code)
check("display-before-source explains itself", "cannot show a flash BEFORE" in err,
      err.strip()[:120])
code, out, err = run([LATENCY, "--fps", "0", "--pair", "1,2"])
check("fps 0 exits 2", code == 2, "exit=%d" % code)
code, out, err = run([LATENCY, "--fps", "240", "--pair", "abc,2"])
check("non-numeric pair exits 2", code == 2, "exit=%d" % code)

# --- the three optional rig rates get the same guard as --fps (R-C FIX-GND-4).
#     A negative used to produce a negative "bias to SUBTRACT" and an inverted
#     median interval, at exit 0.
for flag in ("--src-refresh-hz", "--dst-refresh-hz", "--camera-fps"):
    code, out, err = run([LATENCY, "--fps", "240", "--pair", "1200,1236", flag, "-60"])
    check("%s -60 exits 2" % flag, code == 2, "exit=%d" % code)
    check("%s -60 says which flag and why" % flag,
          flag in err and "must be positive" in err, err.strip()[:160])
    code, out, err = run([LATENCY, "--fps", "240", "--pair", "1200,1236", flag, "0"])
    check("%s 0 exits 2" % flag, code == 2, "exit=%d" % code)

code, out, err = run([LATENCY, "--fps", "240", "--pair", "1200,1236"])
check("omitting all three rates is still exit 0", code == 0, "exit=%d" % code)
check("omitting all three rates says NOT ACCOUNTED", "NOT ACCOUNTED" in out,
      out.strip()[-160:])

print("")
print("%d checks, %d failures" % (checks, len(failures)))
if failures:
    for f in failures:
        print("  FAILED: %s" % f)
    sys.exit(1)
sys.exit(0)
