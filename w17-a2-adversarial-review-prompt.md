# Session prompt — adversarial review of the restructured A2 staged build gates (before any solder)

Paste into a Claude Code session started at `~/Documents/projects`.

> **Run this on Claude Fable 5** if available (or ask the session to spawn a Fable subagent for the
> analysis pass). This is a deep-reasoning, find-what-isn't-there job on a document that is about to
> govern physical, hard-to-unwind work — the case where the most capable model actually pays for
> itself. Use high or max effort.

---

A2 was restructured on 2026-07-30 from a single post-assembly pass into **eight staged gates that
*are* the build order** (S1 divider → S2 Hall → S3 link2 → S4/S4b CRSF + actuator leads and
cross-signal isolation → S5 WS2812 → S6 attach UBECs → S7 whole-harness ground sweep → S8 ESC red-wire
isolation). Nothing is soldered yet, so **this document has never been executed even once.**

I want it torn apart *before* the first joint, not after. Precedent: the last adversarial pass on this
project's gate documents (the FIRST_ACTIVE checklist, 2026-07-30) found a real hole nothing in
R1–R14 / I1–I9 / Groups A–D covered — gamepad *device loss* was never distinguished from value
*release* — and that produced I10, R15, D19–D22 and an input-provenance rule. **Find the A2 equivalent.**

## Read first

- `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` — canonical, the target
- `w17-pdb-build-and-connector-guide.md` — PDB topology, connector genders, capacitor placement
- `w17-control-fw/lib/config/include/config/PinMap.hpp` — the pin truth
- `HARDWARE_INVENTORY.md` §E — what is actually on hand vs assumed
- `CURRENT_STATUS.md` → *Hardware gates*, for what the restructure was meant to fix

## The specific failure mode to hunt

The restructure's stated driver: **several expected values are only valid while a subassembly is
isolated.** The worked case is the divider's `batt+ → GND ≈ 37 kΩ`, which after S6 is measured in
parallel with two UBEC input stages and would **false-FAIL a correctly-built car** against the old §13
hard stops.

That was one instance of a general class. **Systematically find the others.** For every measurement in
every gate, ask:

1. **Is this reading still valid at the stage it is taken?** What else is on that node by then?
2. **Is it still valid at *later* stages** — i.e. if a builder re-checks it after S6, does it now lie?
3. **Does the gate order actually make the subassembly reachable?** A continuity check on a pin that
   is already buried under a mated connector or a heat-shrunk joint is unexecutable as written.
4. **Is each expected value falsifiable?** Two previously-unfalsifiable "per your build" rows were
   fixed (WS2812 = option A / 1N5819; link2 RX GPIO26 = do not wire, now "verify no wire present").
   Are there others left that no reading can fail?
5. **What is measured nowhere?** A joint, a rail, a ground return, or an isolation that no gate covers.
   This is where the FIRST_ACTIVE hole lived — in the gap between checks, not inside one.

## Also check

- **§13 hard stops vs staged reality** — is every hard stop still correct at the stage its measurement
  is taken? A threshold written for a whole harness may be wrong for an isolated subassembly, in
  either direction (false FAIL *or* false PASS — the false PASS is the dangerous one).
- **The §12 two-part gate.** Part 1 is a reviewer check including mandatory direct inspection of the
  §10 photos; Part 2 is owner attestation. Do the §10 photos actually let a reviewer *see* the things
  Part 1 claims they can corroborate — specifically the ESC red-wire cut (S8) and the single star
  ground (S7)? If a photo can't show it, the corroboration is decorative.
- **S8 ESC red-wire isolation is the hard gate before any drivetrain power.** Attack it hardest.
- **Battery reality.** S7's "probe from battery −" reference depends on an XT60-terminated pack.
  Per `HARDWARE_INVENTORY.md`, **no in-envelope pack exists** and the only battery on hand is the
  out-of-envelope 5200 (bench-only). Does S7 as written even have its reference available? Say so
  plainly if not.

## Output

A findings list, most-severe first. For each: the exact section/line, a concrete failure scenario
(what a careful builder does, what reading they get, what they wrongly conclude), and a proposed
minimal fix. **Separate CONFIRMED from PLAUSIBLE** — this project's standing rule.

Then tell me honestly whether A2 is safe to execute as written, or needs a revision pass first.
**Do not soften the verdict to be encouraging.** A false PASS here ends with powered hardware.

**Safety:** documents only. Nothing built, powered, flashed, or connected. A2 stays NOT-EXECUTED and
Phase B stays BLOCKED regardless of what this session concludes — a review cannot open a gate. Show
diffs before committing; target repo is `w17-control-fw` docs plus `CURRENT_STATUS.md`; branch off main.
