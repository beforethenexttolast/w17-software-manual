# W17 OWNER ACTIONS — the human-required queue (maintained by the Director; updated 2026-09-05)

Only genuinely human-required actions appear here. Each: action · reason · prerequisite · unlocks · runbook/file.

## DO NOW
1. **Free ≥ 100 GB of disk (or attach an external SSD for the VM).** Reason: the Mac has 9.6 GiB free (OBSERVED); the VM
   runbook sizes the guest at 80–100 GB (`w17-windows-vm-validation-runbook.md` §1.3). Prereq: none. Unlocks: all of Workstream A
   beyond static checks. File: runbook §1.1–1.3.
2. **Install VMware Fusion (free personal licence) and download the Windows 11 ARM64 ISO.** Reason: neither is on the Mac
   (OBSERVED). Prereq: item 1. Unlocks: guest creation → the one-shot bootstrap script the A1 worker is preparing. File: runbook §1.1–1.2.
3. **Decide OP-49 (2S balancing USB-C charge module): adopt the on-hand IP2326 ×2 or select another.** Reason: `HARDWARE_INVENTORY.md`
   §"Not on hand yet" item 4 says the inventory and OP-49 disagree on whether a module is chosen; it blocks done-bar 4 and the M-16
   measurement row. Prereq: none. Unlocks: charge-flap CAD, charge-safety spec, procurement bucket. File:
   `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md` (OP-49).
4. **Print fit-check coupon C-1 (peg/hole ladder) at draft settings, labelled TP.** Reason: it calibrates `fit_clearance`, which
   every other CAD model depends on (`w17-3d-codex/11_cad/README.md` "Order of operations" step 1). Prereq: none. Unlocks: coupons
   C-2..C-4 and every fit print. File: `w17-3d-codex/11_cad/fit_check_coupons.scad`, `PRINT_SPEC.md`.

## CONNECT / PROVIDE WHEN ASKED
- **DualShock 4 via USB to the Mac** — will be requested as CONNECT NOW once the A4 worker's host pre-check script exists.
  Unlocks: mapper device enumeration + hot-plug behaviour on macOS (partial evidence; Windows stays BENCH-TBD).
- **ELRS TX handset via USB (TX16S)** — later; only for serial enumeration, with the car unpowered and no receiver in reach.

## WHEN EQUIPMENT ARRIVES
- 5 GHz AP-capable USB Wi-Fi adapter → pass through to the guest → `30-hotspot.ps1` (runbook §1.8, §3).
- Neodymium 3×1 mm magnets, Tamiya tyres (both ⏳ in transit per `HARDWARE_INVENTORY.md`) → A2 no-power rows that need them.
- In-envelope 2S car pack (⬜ not sourced; shop to dimensions ≤70×40×22 mm, hard fail 75×45×25) → Phase B on-car power, later.

## AT THE CAR — NO POWER
- Measurement sitting M-00…M-20 in ONE batch — wait for the B1 worker's reconciled recording sheet (this wave). Calipers + scale.
- A2 no-power checklist (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`) — after the C1 gate card is reconciled.

## AT THE BENCH — POWERED / GATED (each needs your explicit go, one at a time)
- A2 closure → Phase B first power → D8 bring-up → BT1 → coordinated flash → race-day link/CRSF on the wire → phone latency → halo.
- FIRST_ACTIVE: NO-GO until a separate reviewed safety milestone.

## LATER / POLISH
- Booklet tone/style lines (the F1 worker will hand you a focused packet; facts are fixed by agents).
- Push/merge grant for `program/offline-readiness` and the `offline/*` branches once wave 2 review passes (queued, not urgent).
