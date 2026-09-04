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

print("")
print("%d checks, %d failures" % (checks, len(failures)))
if failures:
    for f in failures:
        print("  FAILED: %s" % f)
    sys.exit(1)
sys.exit(0)
