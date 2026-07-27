# Codex handoff — ESC "ground truth" rows contradict the caliper (2026-07-27)

**For:** ChatGPT Codex, working in `w17-3d-codex` (Codex-owned; Claude Code did not and will not edit it).
**Found by:** read-only inspection of the two unpushed commits, 2026-07-27.
**Severity:** not dangerous — the blocking gates are still correctly closed — but the wrong number carries the
strongest-sounding confidence tag in the repo, which is exactly how a stale figure gets trusted.

## The contradiction

Commit `2325fd9` ("assembly: add fit studies and validation evidence") is **internally inconsistent about the
QuicRun ESC**. Two rows it adds as *new* text assert the pre-caliper figures as physical ground truth:

| Location | Asserts | Tag it carries |
|---|---|---|
| `B_component_envelope_register.md` — new `DRV-ESC-CURRENT` row | **44.2 × 37 × 24.2 mm** | "DOCUMENTED owner physical ground truth" |
| `OPEN_PROBLEMS_AND_QUESTIONS.md` — new `OP-01` | ESC "physical identity, base envelope and loose-unit mass are **closed**" | — |

The measured values, from the 2026-07-24 no-power caliper session
(`../w17-batch1-measurements-for-codex.md`, owner present, calipers + gram scale):

- **44.2 × 33.7 × 34.0 mm** — width **33.7**, not 37; **installed height 34.0**, not 24.2.
- 24.2 mm is the *documented* figure that the caliper **superseded** — it omits the fan + heatsink on top.
- That 34.0 mm is precisely what reopened **CAS-06 / ASM-49** (ESC floor station Z1.5…25.7 is too short).

The same commit's ZK cassette study (dated 2026-07-24) **already carries the correct 34.0** and correctly
regresses the station to FAIL-STATION. So the repo contradicts itself: the study is right, the register and
OP-01 are stale, and the stale half is the one labelled "ground truth".

## Asked of Codex

1. Correct the `DRV-ESC-CURRENT` row to **44.2 × 33.7 × 34.0 mm**, cite the 2026-07-24 caliper session, and
   retag it — it is measured, so whatever your vocabulary's term for that is (VERIFIED, not DOCUMENTED).
   Keep 24.2 visible as the superseded documented figure with a note that it excludes the fan/heatsink stack,
   rather than deleting it — the delta is the whole reason the station reopened.
2. Reword **OP-01**: the ESC base envelope is **not** "closed". It is measured but its *station* is
   FAIL-STATION pending re-derivation. OP-01 already marks itself BLOCKER, so this is a wording fix, not a
   gate change.
3. Sweep for any other consumer of 37 mm or 24.2 mm downstream of those two rows and reconcile them the same
   way. The ZK study is already correct; the question is what else read the register.

## Second, minor item — your call, not a blocker

`p0_d36_wire_schedule_validation.md` adds three lines containing the absolute path
`/Users/vitaliykhomenko/…`. The GitHub account is a pseudonym, so filesystem paths carrying the owner's real
name are a small deanonymisation vector. Marginal exposure is near zero — `01_inventory/build_inventory.py`
already contains the same path and is already public — so this blocks nothing, but the three rows are
trivially relativisable if you'd rather not extend it.

## Context Codex should have

- Everything else in both commits cross-checks **clean** against the workspace record: the MH-ET D1-Mini
  board decision (CTL-E1/E2, 39×31×~13 FIRM, "not C3/S2/S3 SuperMini"), DS3235SG side-on with `servosaverv7`
  as an M3 pivot rather than a spline part, and `HARDWARE_INVENTORY.md`'s §E ⏳ rows treated as not-yet-in-hand.
- The DS3235SG **1.5 mm vs 1.7 mm** difference is **not** a contradiction — the fit study is the source of the
  1.5 mm prediction and the caliper refined it to ~1.7 mm. The workspace already records it as "predicted
  ~1.5 mm — confirmed".
- The hedging discipline in `2325fd9` is good and should be preserved: the VERIFIED / DERIVED / DOCUMENTED /
  ASSUMPTION vocabulary, the mass table's "Physical scales own the result", the "NO PRINT AUTHORIZATION —
  GATE P1 NOT PASSED" banner, and the MG90S note that official TowerPro dimensions "do not prove the
  purchased clones". Only the two ESC rows break it.
- One naming note, no action needed: the `*_output_validation` PASS tables validate **generated artifacts**
  ("HTML exists", "inline-only CSP present", "link resolves"), not physical parts. The commit subject
  "validation evidence" reads as hardware validation to a skimmer. Worth keeping in mind for future subjects.
