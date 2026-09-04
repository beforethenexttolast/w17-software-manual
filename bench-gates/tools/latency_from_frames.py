#!/usr/bin/env python3
# W17 OFFLINE READINESS — bench-gate tooling (card G-02).
#
# Turn pairs of high-speed capture frame indices into a glass-to-glass latency
# with an HONEST uncertainty, and (only if a target is supplied) a PASS/FAIL.
#
# WHAT IT DOES NOT DO. It invents no threshold. The only recorded engineering
# target in the repos is for the CAMERA-TO-DISPLAY path, is explicitly "not a
# promise", and belongs to a different (native RTP) design generation:
#   iPhone_rc/docs/VR_FPV_IMPLEMENTATION_PLAN.md:541
#     "median glass-to-glass latency at or below 150 ms and p95 at or below 200 ms"
# There is NO recorded acceptance number for the phone-vs-laptop DELTA, which is
# the number the shipped design says actually matters:
#   iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:679-680
#     "glass-to-glass latency on the phone AND on the laptop, same event, same
#      run -- the number that matters is the *delta*"
# So targets are opt-in flags. With no target this script reports and exits 0.
#
# EXIT CODES
#   0  computed; and, if a target was given, every given target was met
#   1  computed; at least one given target was NOT met  (a real FAIL)
#   2  usage / input error (bad arguments, no samples, unusable numbers)
#
# No dependencies beyond the standard library. Python 3.8+.

from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from typing import List, Optional, Sequence, Tuple

EXIT_OK = 0
EXIT_FAIL = 1
EXIT_USAGE = 2

# Citation strings carried into the JSON output so a saved evidence file says
# where its numbers came from without needing this source next to it.
CITATIONS = {
    "engineering_target": (
        "iPhone_rc/docs/VR_FPV_IMPLEMENTATION_PLAN.md:541 — median <= 150 ms, "
        "p95 <= 200 ms; 'initial engineering target, not a promise'"
    ),
    "delta_is_the_number": (
        "iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:679-680 — the number that "
        "matters is the phone-vs-laptop delta on the same event, same run"
    ),
    "no_bench_number_yet": (
        "iPhone_rc/README.md:480 — 'No real-iPhone or real-link latency is "
        "proven; the only measurements that exist were taken on the iOS "
        "simulator over loopback'"
    ),
    "showpiece_jitter_buffer": (
        "w17-ground-station/docs/video_profiles.md:48 — SHOWPIECE sets "
        "jitterBufferTargetMs = 300; DRIVE leaves it untouched"
    ),
}


class Sample:
    """One matched flash edge, seen on both screens in the same capture."""

    def __init__(self, n_src: int, n_dst: int, tag: str = ""):
        self.n_src = n_src
        self.n_dst = n_dst
        self.tag = tag

    @property
    def dn(self) -> int:
        return self.n_dst - self.n_src


def die(msg: str) -> "None":
    sys.stderr.write("error: %s\n" % msg)
    raise SystemExit(EXIT_USAGE)


def parse_pair(text: str) -> Sample:
    """'1200,1231' or '1200,1231,label' -> Sample."""
    parts = [p.strip() for p in text.split(",")]
    if len(parts) not in (2, 3):
        die("--pair wants 'n_source,n_display' (optionally ',label'), got %r" % text)
    try:
        n_src = int(parts[0])
        n_dst = int(parts[1])
    except ValueError:
        die("--pair frame indices must be whole numbers, got %r" % text)
    tag = parts[2] if len(parts) == 3 else ""
    return Sample(n_src, n_dst, tag)


def read_pairs_file(path: str) -> List[Sample]:
    """CSV with a header row: n_source,n_display[,label]. '#' lines ignored."""
    out: List[Sample] = []
    try:
        with open(path, "r", newline="", encoding="utf-8") as fh:
            rows = [r for r in csv.reader(fh) if r and not r[0].lstrip().startswith("#")]
    except OSError as exc:
        die("could not read %s: %s" % (path, exc))
        return out  # unreachable; keeps type checkers quiet
    if not rows:
        die("%s contains no rows" % path)
    header = [c.strip().lower() for c in rows[0]]
    start = 1 if header[:2] == ["n_source", "n_display"] else 0
    if start == 0 and not rows[0][0].strip().lstrip("-").isdigit():
        die("%s: first row is neither the header 'n_source,n_display' nor two numbers" % path)
    for i, row in enumerate(rows[start:], start=start + 1):
        if len(row) < 2:
            die("%s line %d: need at least two columns" % (path, i))
        out.append(parse_pair(",".join(c.strip() for c in row[:3])))
    return out


def percentile(values: Sequence[float], pct: float) -> float:
    """Linear-interpolation percentile (the 'inclusive' convention).

    Written out rather than imported so the result is auditable and identical
    on any Python 3.8+, including one without statistics.quantiles.
    """
    if not values:
        raise ValueError("percentile of an empty sequence")
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    rank = (len(ordered) - 1) * (pct / 100.0)
    low = math.floor(rank)
    high = math.ceil(rank)
    if low == high:
        return ordered[int(rank)]
    frac = rank - low
    return ordered[low] * (1.0 - frac) + ordered[high] * frac


def median(values: Sequence[float]) -> float:
    return percentile(values, 50.0)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="latency_from_frames.py",
        description=(
            "Glass-to-glass latency from high-speed capture frame indices. "
            "Give the capture frame on which a flash edge appears on the SOURCE "
            "screen and the frame on which the SAME edge appears on the DISPLAY "
            "under test (phone or laptop). Repeat for several edges."
        ),
        epilog=(
            "exit 0 = computed (and every supplied target met); "
            "exit 1 = a supplied target was not met; exit 2 = usage error."
        ),
    )
    p.add_argument("--fps", type=float, required=True,
                   help="capture frame rate of the filming camera, e.g. 240")
    p.add_argument("--pair", action="append", default=[], metavar="N_SRC,N_DST[,LABEL]",
                   help="one matched flash edge; repeatable")
    p.add_argument("--pairs-file", metavar="CSV",
                   help="CSV of n_source,n_display[,label] rows (header optional)")
    p.add_argument("--label", default="unlabelled run",
                   help="what this run measured, e.g. 'phone DRIVE profile, 5 m'")

    p.add_argument("--src-refresh-hz", type=float, default=None,
                   help="refresh rate of the SOURCE monitor the camera films "
                        "(systematic bias term; omit to leave it out)")
    p.add_argument("--dst-refresh-hz", type=float, default=None,
                   help="refresh rate of the DISPLAY under test "
                        "(systematic bias term; omit to leave it out)")
    p.add_argument("--camera-fps", type=float, default=None,
                   help="frame rate of the FPV CAMERA in the video path "
                        "(systematic bias term; omit to leave it out)")

    p.add_argument("--median-target-ms", type=float, default=None,
                   help="fail if the median exceeds this (no default: none is recorded)")
    p.add_argument("--p95-target-ms", type=float, default=None,
                   help="fail if p95 exceeds this (no default: none is recorded)")
    p.add_argument("--min-samples", type=int, default=20,
                   help="warn below this many samples; p95 is not reported as "
                        "meaningful under it (default 20)")

    p.add_argument("--json", metavar="PATH",
                   help="also write the full result as JSON (use '-' for stdout)")
    return p


def compute(args: argparse.Namespace, samples: List[Sample]) -> dict:
    fps = args.fps
    ms_per_frame = 1000.0 / fps

    per_sample = []
    for s in samples:
        per_sample.append({
            "n_source": s.n_src,
            "n_display": s.n_dst,
            "delta_frames": s.dn,
            "latency_ms": s.dn * ms_per_frame,
            "label": s.tag,
        })

    lat = [r["latency_ms"] for r in per_sample]

    # Random term. Each index is only known to within the frame it was read on,
    # so each end carries +/- 0.5 frame. Linear addition is the conservative
    # bound; quadrature is reported beside it and is NOT used for the verdict.
    random_bound_ms = 1.0 * ms_per_frame
    random_quadrature_ms = math.sqrt(0.5 ** 2 + 0.5 ** 2) * ms_per_frame

    # Systematic terms. Each is a delay that IS inside the measured number but
    # is NOT the video pipeline's: the source monitor has to paint the flash
    # before the camera can see it, the camera samples on its own frame clock,
    # and the display under test has to paint what it decoded. Each contributes
    # somewhere in [0, one period]. They are reported as a one-sided bias to
    # subtract, never as an error bar around the measurement.
    bias_terms = []
    if args.src_refresh_hz:
        bias_terms.append(("source monitor scan-out", 1000.0 / args.src_refresh_hz))
    if args.camera_fps:
        bias_terms.append(("FPV camera frame quantisation", 1000.0 / args.camera_fps))
    if args.dst_refresh_hz:
        bias_terms.append(("display-under-test scan-out", 1000.0 / args.dst_refresh_hz))
    bias_max_ms = sum(v for _, v in bias_terms)

    n = len(lat)
    med = median(lat)
    p95_meaningful = n >= args.min_samples
    p95 = percentile(lat, 95.0)

    result = {
        "label": args.label,
        "samples": n,
        "capture_fps": fps,
        "ms_per_capture_frame": ms_per_frame,
        "per_sample": per_sample,
        "min_ms": min(lat),
        "median_ms": med,
        "p95_ms": p95,
        "p95_meaningful": p95_meaningful,
        "max_ms": max(lat),
        "uncertainty": {
            "random_bound_ms": random_bound_ms,
            "random_quadrature_ms": random_quadrature_ms,
            "systematic_bias_terms_ms": [
                {"term": name, "max_ms": val} for name, val in bias_terms
            ],
            "systematic_bias_max_ms": bias_max_ms,
            "note": (
                "Each latency is (n_display - n_source) / fps. Each index is "
                "known to +/- 0.5 capture frame, so the random bound is +/- one "
                "capture frame. The systematic terms are delays inside the "
                "measured number that belong to the two screens and the camera "
                "clock, not to the video pipeline: the pipeline-only latency "
                "lies in [measured - systematic_bias_max_ms, measured]."
            ),
        },
        "median_interval_ms": [med - random_bound_ms - bias_max_ms, med + random_bound_ms],
        "citations": CITATIONS,
        "evidence_label": "OBSERVED only when this run really happened on the bench; "
                          "NOT-EXECUTED otherwise. This script cannot tell the difference.",
    }

    checks = []
    if args.median_target_ms is not None:
        checks.append({
            "name": "median",
            "value_ms": med,
            "target_ms": args.median_target_ms,
            "pass": med <= args.median_target_ms,
        })
    if args.p95_target_ms is not None:
        checks.append({
            "name": "p95",
            "value_ms": p95,
            "target_ms": args.p95_target_ms,
            "pass": p95 <= args.p95_target_ms,
            "meaningful": p95_meaningful,
        })
    result["checks"] = checks
    result["verdict"] = (
        "NO TARGET GIVEN — reported, not judged" if not checks
        else ("PASS" if all(c["pass"] for c in checks) else "FAIL")
    )
    return result


def render(result: dict) -> str:
    lines = []
    a = lines.append
    a("W17 glass-to-glass latency — %s" % result["label"])
    a("  capture %.6g fps  (%.4f ms per frame)   samples: %d"
      % (result["capture_fps"], result["ms_per_capture_frame"], result["samples"]))
    a("")
    a("  %-8s %-10s %-12s %-10s  %s" % ("n_src", "n_display", "delta_frames", "latency", "label"))
    for r in result["per_sample"]:
        a("  %-8d %-10d %-12d %8.2f ms  %s"
          % (r["n_source"], r["n_display"], r["delta_frames"], r["latency_ms"], r["label"]))
    a("")
    a("  min     %8.2f ms" % result["min_ms"])
    a("  median  %8.2f ms" % result["median_ms"])
    if result["p95_meaningful"]:
        a("  p95     %8.2f ms" % result["p95_ms"])
    else:
        a("  p95     %8.2f ms   *** NOT MEANINGFUL: %d samples ***"
          % (result["p95_ms"], result["samples"]))
    a("  max     %8.2f ms" % result["max_ms"])
    a("")
    u = result["uncertainty"]
    a("  random bound        +/- %.2f ms (one capture frame; quadrature %.2f ms)"
      % (u["random_bound_ms"], u["random_quadrature_ms"]))
    if u["systematic_bias_terms_ms"]:
        a("  systematic bias, to SUBTRACT (each term is [0, max]):")
        for t in u["systematic_bias_terms_ms"]:
            a("    - %-32s up to %.2f ms" % (t["term"], t["max_ms"]))
        a("    total up to %.2f ms" % u["systematic_bias_max_ms"])
    else:
        a("  systematic bias      NOT ACCOUNTED — pass --src-refresh-hz / "
          "--camera-fps / --dst-refresh-hz to bound it")
    lo, hi = result["median_interval_ms"]
    a("  median lies in      [%.2f, %.2f] ms" % (lo, hi))
    a("")
    if result["checks"]:
        for c in result["checks"]:
            mark = "PASS" if c["pass"] else "FAIL"
            extra = ""
            if c["name"] == "p95" and not c.get("meaningful", True):
                extra = "  (sample count too small for p95 to mean anything)"
            a("  %-6s %-6s %8.2f ms  vs target %8.2f ms%s"
              % (mark, c["name"], c["value_ms"], c["target_ms"], extra))
    a("  VERDICT: %s" % result["verdict"])
    a("")
    a("  Reminder: a simulator/loopback figure is NOT a bench figure "
      "(iPhone_rc/README.md:480).")
    return "\n".join(lines)


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.fps <= 0:
        die("--fps must be positive")

    # The three optional rig rates get the SAME guard as --fps. Without it a
    # negative value produced a negative "bias to SUBTRACT" and an interval
    # whose low bound exceeded its high bound -- a malformed result presented
    # as a valid one, on the tool whose entire job is honest uncertainty
    # (R-C FIX-GND-4). Zero already read as "not given" and printed
    # NOT ACCOUNTED, which is safe; this makes it explicit rather than
    # incidental, so a typo is a usage error instead of a silent omission.
    for flag, value in (("--src-refresh-hz", args.src_refresh_hz),
                        ("--dst-refresh-hz", args.dst_refresh_hz),
                        ("--camera-fps", args.camera_fps)):
        if value is not None and value <= 0:
            die("%s must be positive when given (got %g); omit the flag "
                "entirely if you did not measure it -- the tool then says "
                "NOT ACCOUNTED instead of inventing a bound" % (flag, value))

    samples: List[Sample] = [parse_pair(p) for p in args.pair]
    if args.pairs_file:
        samples.extend(read_pairs_file(args.pairs_file))
    if not samples:
        die("no samples: give at least one --pair or a --pairs-file")

    bad = [s for s in samples if s.dn < 0]
    if bad:
        die("the display cannot show a flash BEFORE the source does; "
            "check which column is which (offending pair: %d,%d)"
            % (bad[0].n_src, bad[0].n_dst))

    result = compute(args, samples)
    sys.stdout.write(render(result) + "\n")

    if args.json:
        blob = json.dumps(result, indent=2, sort_keys=True)
        if args.json == "-":
            sys.stdout.write(blob + "\n")
        else:
            try:
                with open(args.json, "w", encoding="utf-8") as fh:
                    fh.write(blob + "\n")
            except OSError as exc:
                die("could not write %s: %s" % (args.json, exc))

    if result["checks"] and result["verdict"] == "FAIL":
        return EXIT_FAIL
    return EXIT_OK


if __name__ == "__main__":
    raise SystemExit(main())
