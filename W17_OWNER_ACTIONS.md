# W17 OWNER ACTIONS — the human-required queue (maintained by the Director; updated 2026-09-05 09:00, end of wave 1)

Only genuinely human-required actions appear here. Each: action · reason · prerequisite · unlocks · runbook/file.

## DO NOW
1. **Free about 50 GB more on the internal SSD, or put the VM bundle on an external APFS drive.** Reason: `df`/`diskutil` show
   ~20–22 GB free (OBSERVED 2026-09-05 01:30; an earlier 9.6 GiB reading counted purgeable space) against the ~70 GB VM budget the
   A1 worker derived for this Mac (`w17-windows-vm-validation-runbook.md` §1.3 on branch offline/vm-runbook). Prereq: none. Unlocks:
   all of Workstream A beyond static checks. File: runbook §1.0 checklist (under Opus review R-A before you follow it).
2. **Install VMware Fusion (free personal licence) and download the Windows 11 ARM64 ISO.** Reason: neither is on the Mac
   (OBSERVED). Prereq: item 1. Unlocks: guest creation → the one-shot bootstrap script the A1 worker is preparing. File: runbook §1.1–1.2.
3. **Decide OP-49 (2S balancing USB-C charge module): adopt the on-hand IP2326 ×2 or select another.** Reason: `HARDWARE_INVENTORY.md`
   §"Not on hand yet" item 4 says the inventory and OP-49 disagree on whether a module is chosen; it blocks done-bar 4 and the M-16
   measurement row. Prereq: none. Unlocks: charge-flap CAD, charge-safety spec, procurement bucket. File:
   `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md` (OP-49).
4. **Print fit-check coupon C-1 (peg/hole ladder) — the STL was sent to you (out/C-1.stl, 106×28×12 mm): draft PLA/PETG, 0.20 mm, 4 walls, 40 %, no supports, label TP-001; then note the first peg/hole step that fits and stays put when shaken.** Reason: it calibrates `fit_clearance`, which
   every other CAD model depends on (`w17-3d-codex/11_cad/README.md` "Order of operations" step 1). Prereq: none. Unlocks: coupons
   C-2..C-4 and every fit print. File: `w17-3d-codex/11_cad/fit_check_coupons.scad`, `PRINT_SPEC.md`.

## CONNECT / PROVIDE WHEN ASKED
- **A real x64 Windows 11 PC** (borrowed or the giftee's at handover) with the GCS box's FT232RL and a USB DualShock 4 — unlocks the first real `run-all.ps1 -HardwareExpected -ElrsVidPid 0403:6001`, the WinRT adapter probe under Windows PowerShell 5.1, a captured `netsh wlan show hostednetwork`, G-03 (gamepad hot-plug) and G-04 Part A (race-day link timing; needs D-3 first). This is the single connection that unlocks the most.
- **DualShock 4 via USB to the Mac — CONNECT NOW issued 2026-09-05 01:00** (run `wt-mapper-host/tools/host-precheck/ds4_precheck.sh` in your Terminal, ~2 min with the pad in hand). Unlocks: OBSERVED SDL indices 4/6/9/10 + hot-plug id persistence on macOS (Windows stays BENCH-TBD).
- **ELRS TX handset via USB (TX16S)** — later; only for serial enumeration, with the car unpowered and no receiver in reach.

## WHEN EQUIPMENT ARRIVES
- 5 GHz AP-capable USB Wi-Fi adapter → pass through to the guest → `30-hotspot.ps1` (runbook §1.8, §3).
- Neodymium 3×1 mm magnets, Tamiya tyres (both ⏳ in transit per `HARDWARE_INVENTORY.md`) → A2 no-power rows that need them.
- In-envelope 2S car pack (⬜ not sourced; shop to dimensions ≤70×40×22 mm, hard fail 75×45×25) → Phase B on-car power, later.

## AT THE CAR — NO POWER
- **Measurement sitting — READY (verified 2026-09-05 05:30: Opus review → fix → Opus re-verify → residual fix → re-verify PASS).** Files delivered to you: MEASUREMENT_SITTING_RUNBOOK.md, MEASUREMENT_RECORD_SHEET.md/.csv (canonical copy on 3d-codex branch offline/measurement-sitting 98e27a7). Do Station 0 (M-00, 10 min) first: it decides whether 24 shell-gated rows exist at all. 43 rows run today with nothing printed or assembled; 12 are BLOCKED on parts (PDB, SP3T, magnets, tyres, hub, adapter) and say so. One number per cell; "could not — why" is a first-class answer. Calipers (0.1 mm), scale (1 g), feeler gauges; no power, no battery in the car.
- A2 no-power checklist (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`) — after the C1 gate card is reconciled.

## AT THE BENCH — POWERED / GATED (each needs your explicit go, one at a time)
- A2 closure → Phase B first power → D8 bring-up → BT1 → coordinated flash → race-day link/CRSF on the wire → phone latency → halo.
- FIRST_ACTIVE: NO-GO until a separate reviewed safety milestone.

## DECISION ROUND 1 (consolidated at end of wave 1 — one sitting, no hardware)
- **D-1 Hotspot validation host + adapter scope.** No ARM64 Windows driver exists for any USB Wi-Fi adapter (VERIFIED), so the ARM64 VM can run every WS3 step EXCEPT 30-hotspot and 40's hotspot half. Options: (a) borrow/identify an x64 Windows 11 PC for one session; (b) defer hotspot validation to the giftee-PC handover (readiness decision A4: real PC only at handover); (c) both. And: is the adapter part of the GIFT KIT or only a validation tool? The BUY NOW row waits on this.
- **D-2 OP-49 charge module.** Adopt the on-hand IP2326 ×2 (two canonical lines call it balancing) or select another; then OP-49's list is worked against it. Blocks charge-flap CAD (M-16) and the charge-safety spec.
- **D-3 Ratify the BG-06 T1 classification.** The CRSF-on-the-wire tap (mapper → FT232RL → module) is INFERRED to be a live-TX bench procedure under the VM runbook §3.1 (car UNPOWERED or RP1 UNBOUND, no bound RX powered in range, attended, discharges nothing) — un-gated by A2/Phase B only, but needing your explicit go like every gate. Ratify or overturn; it is load-bearing and nobody has ruled it.
- **D-4 Seven owner-rulable thresholds** (`bench-gates/MISSING_THRESHOLDS.md` §1): O-1 does the 150/200 ms phone-video latency target survive OD-16's WHEP relay (yes/no/new number); O-2 headroom vs LINK_UP_WAIT_MS=5000 (G-04 proposes 1000 ms); O-3 spread across cold runs (proposes 2000 ms); O-4 number of cold runs (proposes 5); O-5 acceptable STOP-button lag (no number anywhere); O-6 bench-PSU current-limit staircase policy (start value + raise rule) — the one that unblocks first power; O-7 maxBrightness taste value in 1…227 (227 = compile ceiling, DERIVED and recompiled).
- **D-5 Booklet tone lines.** `learning-manual/BOOKLET_EDITORIAL_PACKET.md` §2: five lines, two alternatives each, 15-minute review. Facts are already fixed.
- **D-6 Merge/push grant.** Requested for: workspace program/offline-readiness → main; GS offline/windows-validation-harness a80236e and offline/raceday-timing-logs 2f2690a; mapper offline/host-prechecks 1f20de5 (FORK-NOTICE push-review rule applies); 3d-codex offline/measurement-sitting 98e27a7 + offline/cad-prep 988cf17; control-fw offline/docfix-gate-citations 1d17c6b. All reviewed → fixed → independently re-verified. Until granted, everything stays on branches (and the measurement sitting can be executed from the delivered files).

## DECISIONS QUEUED (superseded — folded into Decision Round 1 above)
- **Hotspot validation host.** The ARM64 VM cannot drive any USB Wi-Fi adapter (no ARM64 drivers exist, A3 VERIFIED). Options: (a) borrow/identify an x64 Windows 11 PC for one hotspot session; (b) defer the hotspot half to the giftee-PC handover session (readiness decision A4 already says real PC only at handover); (c) both. Also: is the adapter part of the GIFT KIT (giftee PC lacks AP-capable Wi-Fi?) or only a validation tool? The purchase spec depends on this.

## LATER / POLISH
- Booklet tone/style lines (the F1 worker will hand you a focused packet; facts are fixed by agents).
- Push/merge grant for `program/offline-readiness` and the `offline/*` branches once wave 2 review passes (queued, not urgent).
