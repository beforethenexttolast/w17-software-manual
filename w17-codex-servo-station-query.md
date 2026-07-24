# Query for Codex — re-check the steering servo station (X registration)

Context: your steering fit study
`w17-3d-codex/10_assembly_architecture/Y_steering_servo_fit_study.md` concludes the
DS3235SG mounts **side-on** and drives `servosaverv7` through a long fore/aft rod, with the
servo shaft station **ASSUMED** at X≈−46.76 (holder centre X≈−56.76) and the saver input at
X≈+78. You flagged that registration as unresolved (ASM-08).

New primary-source evidence that contradicts a long rod
--------------------------------------------------------
The designer's own parts list —
`w17-3d-codex/unsorted_stl_raw/Ryans Creations Open RC F1 Car/Parts List.txt` — specifies:

> "M4 Tie Rods for steering (6pcs, x4 for steering arms, x2 for servo) — 22mm"

i.e. the **servo→steering link is two 22 mm M4 tie rods**, a *short* link — not a ~125 mm
drag rod. That implies the servo bay sits **near the front steering**, not ~130 mm behind it.

Possible cause of the mismatch
------------------------------
- The holder registration keys off a repeated **58 mm floor feature**, but `springblock.stl`
  (35 × 10 × 58) shares the **58 × 10** footprint with `Servoholder` (22.89 × 10 × 58) — so the
  58 mm feature you registered the servo bay to may actually be the spring block (front), or vice
  versa. A ~130 mm servo→saver span is hard to reconcile with a 22 mm servo tie rod.

Please re-check
---------------
1. Re-derive the `Servoholder` X/L station without assuming which 58 mm floor feature is the
   servo bay — distinguish `Servoholder` vs `springblock` by their non-shared axis (22.89 vs 35)
   and by matched mounting-hole patterns, the way you did for `Suspension Block_10`.
2. Confirm whether the servo bay is near the front (consistent with a 22 mm servo tie rod) or
   genuinely ~130 mm back (which would need a long rod not in the BOM/parts list).
3. If the servo is near the front, update the study's linkage description and the KO-01 /
   rod-height results accordingly; the side-on height conclusion itself should still hold, but the
   fore/aft geometry, rod length, and the ceiling station (you quoted ceilings at X=−47) would change.

Scope: mechanical repo only. This is a registration/geometry re-check, not a request to cut STLs.
The W17 BOM already has the M4 40 mm rod + M4 24 mm rod-ends to make the 22 mm servo tie rods, so
no new hardware is implied either way.
