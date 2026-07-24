# Codex prompt — recalculate the electronics cassette with batch-1 measured data + finalized BOM

**For:** a `w17-3d-codex` session. **From:** Claude Code (firmware/electrical side).
**Date:** 2026-07-24. **Do not** treat this as authorization for production STL/relief — the ZK
verdict stays CONDITIONAL-GO. This asks you to **recompute the open gates** with real numbers.

## Read first
- Measured data + gate map: **`w17-batch1-measurements-for-codex.md`** (workspace root).
- Connector proposal + PDB build spec: **`w17-pdb-build-and-connector-guide.md`** (workspace root).
- Your prior study: `10_assembly_architecture/fit_studies/ZK_electronics_cassette_fit_study.md`.

All electrical items are now **chosen and ordered** (nothing powered — A2/Phase B unchanged). So the
cassette inputs are firm enough to recompute; only the *physical* board caliper + fit-gates await arrival.

## Recompute these (each cites the ZK gate it closes/moves)

1. **PDB height — re-derive (CAS-04 / ASM-22).** The ZK 18 mm PDB height assumed "UBEC-dominated."
   **Measured:** UBEC = **9.1 mm** (44.3 × 22.1 each; two lie flat in the 55×45 plan). New tallest
   candidates on the board: **1000 µF cap laid flat ≈ 8–10 mm**, **XT60 ≈ 8 mm**. Master switch and
   charger are **off the PDB** (see items 5–6). So take **PDB body height ≈ max(10, 8) + ~1.6 PCB ≈
   ~11–12 mm**, PDB-top dropping from Z19 toward **~Z13–14**. Recompute **steering clearance =
   KO-01 Z22 − new PDB-top**; report whether it now meets the **8 mm moving policy** (was 3 mm / 5 short).
   ASM-08 (physical powered sweep) still gates final closure — this only removes the height deficit.

2. **ESC floor station — reopen (CAS-06 / ASM-49).** Measured QuicRun = 44.2 × 33.7 × **34.0**
   incl. the **top fan + finned heatsink** (photo `images_of_parts/batch_1/QuicRun ESC.jpg`), vs the
   documented 24.2 mm. The ZK station **Z1.5…25.7** is ~8 mm too short. Re-place the ESC with the
   34 mm body **plus intake-air clearance above the fan**; re-check vs KO-01 and the shell shoulder at
   its L-band. Report the new Z-top and any shell conflict.

3. **Wi-Fi placement — close (D-06b).** Measured BL-M8812EU2 = **32.4 × 32 × 7** (11.2 g), well inside
   the ≤60×32×12 allocation (width 32 = at the limit, huge length/height margin). It can now be
   **placed** — assign its seat + the 2× U.FL antenna roots + heatsink airflow.

4. **CG ledger — refine (CAS-11 / ASM-58).** Use measured masses (handoff doc §4): motor 156.7,
   ESC 100, servo 70.3, Wi-Fi+ant 11.2, RP1 1.6, UBEC 10 ea, amp+spk 10.4, LED/m 17, battery 88.
   Control/RF group is **lighter** than the assumed 72.5 g. Re-run front/rear % and Z-CG. (MH-ET board
   mass still pending arrival — hold that cell as ~9–10 g provisional.)

5. **MH-ET board seats — confirm premise (CAS-03).** Boards are now **MH-ET D1-Mini (39×31), ordered,
   USB-C** (not micro-USB). Keep the 39 mm single-board wall-row / `X+3…+42` seat / `S0≥9.82 mm`
   derivation — but the service-edge cutout must clear a **USB-C** plug, not micro-USB. Physical caliper
   pending arrival.

## New items to place
- **Master switch = Amass XT90-S anti-spark**, mounted **body/inline, OFF the PDB** — reserve a small
  **pull/access pocket** reachable body-on (also the "safe to charge" action). Does not affect PDB height.
- **Charger = IP2326 module, 18.3 × 31 mm** (Type-C, 2S balancing) — its **own cell** (≈ the ZK
  30×25×10 charge target, ASM-59), with **hidden USB-C port access** to its onboard Type-C receptacle.
- **Battery = 2S LiPo 69 × 35 × 18 mm** (ZEEE 1500), XT60 (re-terminated), JST-XH balance — fits the
  ZK floor pack station (≤75×45×25) with margin; confirm strap + lead exit + removal sweep.

## New connections / the dock (CAS-09 / CAS-10)
Incorporate the **finalized connector set** from `w17-pdb-build-and-connector-guide.md` into the ganged
service dock and pedestal conduit:
- add the **USB-C charge lead** (port → IP2326) and the **pack JST-XH balance lead** to the routing;
- the master-switch (XT90-S) sits on the main battery lead **before** the PDB — route it to its access pocket;
- keep the straight front-face dock **rejected** (overlaps pedestal) — the stepped/wrapped dummy stands.
- Re-confirm the 10×18 conduit still carries camera USB + 2× pan/tilt servo leads with the finalized
  connector bodies.

## Deliver back
- New PDB-top Z + steering clearance verdict (item 1); ESC new Z-top + conflict (item 2); Wi-Fi seat (3);
  refreshed CG table (4); updated dock/conduit occupancy (new items).
- **Flag any regression**: if the recomputed steering clearance still fails, or the 34 mm ESC breaks its
  station, say so plainly. Keep the production-stop conditions from ZK §9 in force.
