# W17 OWNER ACTIONS — the human-required queue (maintained by the Director; updated 2026-09-05 09:00, end of wave 1)

Only genuinely human-required actions appear here. Each: action · reason · prerequisite · unlocks · runbook/file.

## DO NOW (unchanged by Decision Round 1; nothing here is a powered/gated test)
1. **Free about 50 GB more on the internal SSD, or put the VM bundle on an external APFS drive.** Reason: `df`/`diskutil` show
   ~20–22 GB free (OBSERVED 2026-09-05 01:30; an earlier 9.6 GiB reading counted purgeable space) against the ~70 GB VM budget the
   A1 worker derived for this Mac (`w17-windows-vm-validation-runbook.md` §1.3 on branch offline/vm-runbook). Prereq: none. Unlocks:
   all of Workstream A beyond static checks. File: runbook §1.0 checklist (under Opus review R-A before you follow it).
2. **Install VMware Fusion (free personal licence) and download the Windows 11 ARM64 ISO.** Reason: neither is on the Mac
   (OBSERVED). Prereq: item 1. Unlocks: guest creation → the one-shot bootstrap script the A1 worker is preparing. File: runbook §1.1–1.2.
3. **OP-49 — no-power marking/identification inspection of the two IP2326 boards, then OP-49 evidence closure.** D-2 (RULED 2026-09-05):
   IP2326 ×2 is the ADOPTED candidate; the decision is closed. What remains is work, not a choice: visually identify/mark both boards (no power),
   then close OP-49's list — exact SKU/datasheet on record, board+connector+heatsink envelope, cell interface, charge/run interlock, charge-state
   access, reverse/backfeed isolation, thermal/fault evidence, and the separate charge-safety specification — **before any powered charge test**.
   Prereq: none. Unlocks: charge-flap CAD (M-16), charge-safety spec, procurement of charge-path parts. File:
   `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md` (OP-49); `2026-09-05_offline_decision_round_1.md` D-2.
4. **Print fit-check coupon C-1 (peg/hole ladder) — the STL was sent to you (out/C-1.stl, 106×28×12 mm): draft PLA/PETG, 0.20 mm, 4 walls, 40 %, no supports, label TP-001; then note the first peg/hole step that fits and stays put when shaken.** Reason: it calibrates `fit_clearance`, which
   every other CAD model depends on (`w17-3d-codex/11_cad/README.md` "Order of operations" step 1). Prereq: none. Unlocks: coupons
   C-2..C-4 and every fit print. File: `w17-3d-codex/11_cad/fit_check_coupons.scad`, `PRINT_SPEC.md`.

## CONNECT / PROVIDE WHEN ASKED
- **A real x64 Windows 11 PC** (borrowed or the giftee's at handover) with the GCS box's FT232RL and a USB DualShock 4 — unlocks the first real `run-all.ps1 -HardwareExpected -ElrsVidPid 0403:6001`, the WinRT adapter probe under Windows PowerShell 5.1, a captured `netsh wlan show hostednetwork`, G-03 (gamepad hot-plug) and G-04 Part A (race-day link timing; needs D-3 first). This is the single connection that unlocks the most.
- **DualShock 4 via USB to the Mac — CONNECT NOW issued 2026-09-05 01:00** (run `wt-mapper-host/tools/host-precheck/ds4_precheck.sh` in your Terminal, ~2 min with the pad in hand). Unlocks: OBSERVED SDL indices 4/6/9/10 + hot-plug id persistence on macOS (Windows stays BENCH-TBD).
- **ELRS TX handset via USB (TX16S)** — later; only for serial enumeration, with the car unpowered and no receiver in reach.

## WHEN EQUIPMENT ARRIVES
- 5 GHz AP-capable USB Wi-Fi adapter (GIFT-KIT unit, D-1; one adapter, no ARM-VM duplicate) → hotspot validation on a **real x64 Windows 11 PC** (`30-hotspot.ps1` + the hotspot half of `40-mdns-udp.ps1`), then the same acceptance check again on the giftee PC at handover. Never into the ARM64 guest: no Windows-on-ARM driver exists for any candidate chipset (VERIFIED).
- Neodymium 3×1 mm magnets, Tamiya tyres (both ⏳ in transit per `HARDWARE_INVENTORY.md`) → A2 no-power rows that need them.
- In-envelope 2S car pack (⬜ not sourced; shop to dimensions ≤70×40×22 mm, hard fail 75×45×25) → Phase B on-car power, later.

## AT THE CAR — NO POWER
- **Measurement sitting — READY (verified 2026-09-05 05:30: Opus review → fix → Opus re-verify → residual fix → re-verify PASS).** Files delivered to you: MEASUREMENT_SITTING_RUNBOOK.md, MEASUREMENT_RECORD_SHEET.md/.csv (canonical copy on 3d-codex branch offline/measurement-sitting 98e27a7). Do Station 0 (M-00, 10 min) first: it decides whether 24 shell-gated rows exist at all. 43 rows run today with nothing printed or assembled; 12 are BLOCKED on parts (PDB, SP3T, magnets, tyres, hub, adapter) and say so. One number per cell; "could not — why" is a first-class answer. Calipers (0.1 mm), scale (1 g), feeler gauges; no power, no battery in the car.
- A2 no-power checklist (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`) — after the C1 gate card is reconciled.

## AT THE BENCH — POWERED / GATED (each needs your explicit go, one at a time)
- A2 closure → Phase B first power → D8 bring-up → BT1 → coordinated flash → race-day link/CRSF on the wire → phone latency → halo.
- FIRST_ACTIVE: NO-GO until a separate reviewed safety milestone.

## DECISION ROUND 1 — **RULED 2026-09-05, all six closed** (verbatim: `2026-09-05_offline_decision_round_1.md`; summary in W17_OFFLINE_READINESS.md §4a)
- **D-1 RULED:** validate hotspot on a real x64 Windows 11 PC when available AND re-check on the giftee PC at handover; the 5 GHz AP adapter is gift-kit/production equipment, one unit, no ARM-VM duplicate.
- **D-2 RULED:** IP2326 ×2 adopted as the charge-module candidate; all remaining OP-49 evidence/safety work still required before any powered charge test; no-power board-marking inspection kept (DO NOW item 3).
- **D-3 RULED:** BG-06 T1 (CRSF tap) is a live-TX gated bench procedure — car unpowered OR RP1 unbound; no bound receiver powered in range; attended; explicit owner go — and discharges no A2 / Phase B / FIRST_ACTIVE gate.
- **D-4 RULED:** O-1 150/200 ms · O-2 1000 ms headroom · O-3 2000 ms spread · O-4 five runs · O-5 STOP lag ≤ 250 ms (record value + PASS/FAIL) · O-6 staircase policy ratified, initial amperage must be derived per powered substep or stay BLOCKED · O-7 maxBrightness operating cap 180 (227 = compile ceiling only). Recorded in `bench-gates/MISSING_THRESHOLDS.md` §1.
- **D-5 RULED and APPLIED** in the booklet (f03066f, corrected to verbatim Alternative B at e7b0017): §1 A, §4 B (+ section-9 row), §6 B, §9 B, §3 unchanged.
- **D-6 GRANTED (one-time, exact scope):** the seven branches in `NEW_SESSION_HANDOFF.md` §1, landing order §2. Not yet executed — the successor's first action. Not a general push grant.

## MUST-NOT-LOSE QUEUE (owner instruction 2026-09-05)
5 GHz AP-capable USB Wi-Fi adapter (gift kit, one unit — BUY NOW) · in-envelope 2S car battery (BUY NOW) · GCS-box USB 3.x hub (BUY NOW) · boot-mode selector (BUY NOW) ·
OP-49/IP2326 closure + charge-path parts (WAIT→WORK: evidence list before any powered charge test) · TX16S internal-RF check → backup-handset decision · coupon C-1 (print) ·
Windows ARM VM (disk → Fusion → ISO → bootstrap) · no-power measurement sitting (pack delivered).

## LATER / POLISH
- (done) Booklet tone lines — ruled D-5 and applied; packet §2 marks the choices.
- (done) Merge/push grant — D-6 granted one-time, exact scope; execution is the successor's first action (`NEW_SESSION_HANDOFF.md` §2).
