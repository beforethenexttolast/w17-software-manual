# W17 OFFLINE READINESS / BENCH PREPARATION — program state (opened 2026-09-05)

Authority for this phase (after workspace `CLAUDE.md` safety boundaries 1–7 and the readiness packet's owner decisions
A1–A12): **this file** > `W17_OWNER_ACTIONS.md` > `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` > `CURRENT_STATUS.md` narrative.
The previous software-readiness program is CLOSED and is the immutable BASELINE; do not re-audit it.

## 0. Mission
Exhaust every useful task that can be completed without final assembly or gated powered bench testing, and leave the
remaining physical sessions short, deterministic, well-instrumented and hard to perform incorrectly.
Phase ends when the frontier is only: purchases · owner measurements/actions · assembly · explicitly gated powered tests.

## 1. Baseline (VERIFIED 2026-09-05 00:00 Kiev — local == origin, CI green at HEAD)
| repo | trunk | SHA | CI |
|---|---|---|---|
| workspace | main | f1fc46e | link checks |
| w17-control-fw | main | 39a4f3c | run 33814317181 green |
| w17-soundlight-fw | main | 7220c08 | run 33814343711 green |
| w17-ground-station | main | 379cf29 | run 33848157522 green |
| iPhone_rc | main | 7aaf2cf | run 33816071199 green |
| w17-mapper | w17-headtrack | b859af1 | release run 33845314514 green |
| w17-3d-codex | main | 5dddedb | render.sh 17/0 |
`u4-arbiter` 4e445c9 parked (FIRST_ACTIVE NO-GO, never push). **PUSH GRANT CLOSED**: no push, no trunk merge without a fresh grant.

## 2. Host facts (OBSERVED 2026-09-05)
macOS 26.3, Apple M4, 16 GB RAM, **~20–22 GB free on a 228 GiB disk** (9.6 GiB at 23:57 included purgeable; 20 GiB at 01:30). No VMware Fusion installed, no Windows ISO on disk,
no `pwsh` on PATH (a 7.7.0-preview.4 binary is staged in the session scratchpad for host-side script checks only).
USB attached now: a generic USB3.2/2.1 hub + Realtek USB GbE (a dock). No gamepad, no ELRS handset, no Wi-Fi adapter.
Tooling present: openscad, gh, go, node/npm, python3, ffmpeg, pio.

## 3. Workstreams and status (WAVE 1 + REVIEW WAVE CLOSED 2026-09-05 ~09:00 Kiev)
Pipeline applied to every owner-executed deliverable: builder → Opus adversarial review → fixer → independent re-verify (Opus for safety-bearing items) → residual fix → re-verify.
Every single deliverable failed its first adversarial review; none of the defects were visible to static reading. The pipeline stays mandatory.
| WS | deliverable | branch (repo) · final tip | chain | state |
|---|---|---|---|---|
| A | VM runbook rewrite for THIS Mac + `scripts/vm/{host-vm.sh,guest-bootstrap.ps1,guest-check.ps1}` (allow-listed `suite`, 43/43 guard self-test, 26/26 guest self-test) | offline/vm-runbook (workspace) · fa73dd5 | A1 → R-A(29) → FIX-A → V-A FAIL (guard bypass) → FIX-A3 → V-A3 PASS (3475 spellings) → FIX-A4 → V-A4 PASS → Director msg fix | VERIFIED · integrated in program branch |
| A | GS Windows-validation harness: DryRun/mock layer (9 fixtures), 05-passthrough, 31-adapter-capability, hot-plug timeline, evidence JSON/RESULT.md, hardware gates advisory by default, MAP-6/MAP-1/MAP-8 narration realigned to shipped code | offline/windows-validation-harness (GS) · a80236e | A2 → R-A2(10) → FIX-A2 → V-A2 PASS → FIX-A5 → V-A5 PASS | VERIFIED · **queued for grant** (GS trunk) |
| A | ARM64 driver feasibility: NO Windows-on-ARM driver for any USB Wi-Fi chipset (VERIFIED; Realtek portal OBSERVED x86-only) → hotspot steps need a real x64 PC; Fusion ≥13.6 no Bluetooth passthrough; ELRS path = FT232RL 0403:6001 | reports/A3.md (no repo change) | A3 | VERIFIED |
| A | mapper DS4 host pre-check tool (`tools/host-precheck/ds4_precheck.sh`, real hot-plug code path) | offline/host-prechecks (mapper) · 1f20de5 | A4 (dry-run SKIP clean) | built · awaiting owner CONNECT NOW · queued for grant (mapper) |
| A | GS race-day timing observability: 5 `W17T` structured lines (press, spawn, link claim, late mirror claim, stop) + stamped WS3 probe log + monotonic `m`; 1693 tests | offline/raceday-timing-logs (GS) · 2f2690a | G3 → R-G(7) → FIX-G → V-G PASS | VERIFIED · **queued for grant** (GS trunk) |
| B | Measurement sitting pack: runbook (81 rows, 6 stations, coordinate/sign block, stop rules), record sheets (254 cells; `param` column), generator | offline/measurement-sitting (3d) · 98e27a7 | B1 → R-B FIX_REQ → FIX-B → V-B PASS → FIX-B2 → V-B2 PASS | VERIFIED · **delivered to owner** · queued for grant (3d trunk) |
| B | CAD prep: `ingest_measurements.py` (26 tests; 35/35 §9 params matched, exit 1 on no-match), C-1.stl exported, COUPON_PRINT_PLAN, FIT_PRINT_LADDER | offline/cad-prep (3d) · 988cf17 | B2 → R-B → FIX-B → V-B → FIX-B2 → V-B2 PASS | VERIFIED · C-1.stl delivered · queued for grant |
| C | 12 gate cards (BG-01..08 firmware/bench, G-01..04 ground) + INDEX/G-INDEX + MISSING_THRESHOLDS.md (27: 7 owner / 20 bench) + tools: CRSF sniffer (21 tests, 300-vector cross-check vs firmware parser), bench_capture, PDB continuity sheet, current-limit table, latency rig, race-day timing parser (negative-leg guard) | offline/bench-gates-fw 38deaf1 + offline/bench-gates-ground 20c8ca6 (workspace) | C1+C2 → R-C (critical: T1 is live-TX gated) → FIX-C → V-C PASS → FIX-C2 → V-C2 PASS | VERIFIED · integrated in program branch · all NOT-EXECUTED |
| D | W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md (BUY NOW 5 / CHECK 14 / OPTIONAL 3 / WAIT 1 + no-purchase actions) | offline/procurement (workspace) · 87c01f1 | D1 → R-D(9) → FIX-D → V-D PASS | VERIFIED · integrated |
| F | Booklet: 1 factual fix (2dae39b, PASS) + BOOKLET_EDITORIAL_PACKET.md (5 tone lines for the owner, 18 markers mapped) | offline/booklet-editorial (workspace) · 63232ae | F1 → R-D → FIX-D → V-D PASS | VERIFIED · integrated |
| — | Doc defects from the gate-card work (7) | offline/docfix-gate-citations (cf) 1d17c6b + offline/docfix-sequence-manual (ws) 30ce591 | DOCFIX-1 → V-DOC 7/7 | VERIFIED · ws half integrated · cf half queued for grant |
| — | Follow-ups running | offline/docfix-manual-lights (ws), offline/gate-card-citations (ws) | DOCFIX-2, CITEFIX (Sonnet) | running |

## 4. Dependency graph (what unlocks what)
- Disk space / external SSD → VMware Fusion + Win11 ARM guest → PowerShell 7 + OpenSSH in guest → snapshot `clean-giftee-pc`
  → 00-inventory · 10-install-gs · 20-mapper-stage · 40-mdns-udp · 50-race-day (no hardware) → **VM-verified (not physical)**.
- 5 GHz AP-capable USB Wi-Fi adapter → **a real x64 Windows PC** (A3 VERIFIED + Director OBSERVED 2026-09-05: no ARM64 Windows driver exists for any candidate USB Wi-Fi chipset, Realtek portal included) → 30-hotspot → hotspot half of WS3. The ARM64 VM can run every other step but NOT the hotspot step.
- ELRS control path is PC → FT232RL USB-serial → CRSF → ES24TX Pro module (A3, from the repo docs); FT232RL has an ARM64 VCP driver (manual .inf). The TX16S is the RF-only backup handset, not a USB link.
- DualShock 4 on USB → (now) mapper `-list-devices` + hot-plug on macOS (partial) → (VM) 60-hid-transition → BENCH-TBD on real Windows.
- ELRS TX handset on USB → COM enumeration in VM; CRSF-on-the-wire needs the TX module + a sniffer → bench.
- Coupon C-1 print → `fit_clearance` → measurement sitting M-00…M-20 → params → coupons C-2..C-4 → cage/tray fit prints → production.
- Owner shopping (car pack, magnets, tyres in transit; OP-49 module decision) → A2 no-power checklist → A2 closure → Phase B (first power) → D8 bring-up → BT1 / coordinated flash → on-car.
- FIRST_ACTIVE stays NO-GO (separate reviewed safety milestone).

## 5. Evidence conventions for this phase
Every physical or VM session writes to `evidence/<date>_<gate>/` (log, JSON, screenshot, photo) with a `RESULT.md` carrying the
label (OBSERVED/VERIFIED/BENCH-TBD/…), the exact command, and PASS/FAIL against the gate card's criteria.

## 6. Change log
- 2026-09-05 00:20 — program opened; baseline verified; wave 1 (10 workers) launched. Host disk/Fusion/ISO gaps recorded.
- 2026-09-05 00:50 — A3 done (reports/A3.md): ARM64 driver gap for USB Wi-Fi is market-wide (VERIFIED; Realtek portal OBSERVED by Director). Fusion ≥13.6 has no Bluetooth passthrough → DS4 on the VM is USB-only. Win11 ARM64 ISO is a direct Microsoft download.
- 2026-09-05 01:35 — wave 1: A1, A4, B1, B2, D1, F1 done; A2, C1, C2 running. Wave 2 launched: R-A (VM runbook+scripts), R-B (measurement pack + ingest chain), R-D (procurement + booklet), all Opus. CONNECT NOW #1 (DS4 wired) issued; C-1.stl delivered to owner.
- 2026-09-05 02:40 — wave 1 complete except A2 (GS harness). Wave-2 adversarial reviews (Opus): R-A VM runbook/scripts FIX_REQUIRED (29 findings; one safety-relevant: the host wrapper could start the live-TX step it claimed never to run; passthrough check broke at 0/1 devices) → FIX-A (Opus) running. R-B measurement pack + ingest chain FIX_REQUIRED (sheet↔scad chain matched 0 params; derived param not recomputed; stock dimensions would have been written into hole/slot params) → FIX-B (Opus) running. R-D: booklet fix PASS; procurement FIX_REQUIRED (9) + editorial packet FIX_REQUIRED (5) → FIX-D (Sonnet) running. C1/C2 gate cards delivered (8 + 4 cards, tooling tests green) → R-C (Opus) running. G3 GS race-day timing log lines delivered (1692 tests green) → R-G (Opus) running. DOCFIX-1 (Sonnet) clearing 7 small doc defects found by C1/C2 in control-fw + workspace.
- Recorded, not acted (R-D): BASELINE CONTRADICTION between closeout/vision-alignment-2026-09-04.md:234-235 and the VM runbook :30-34 on what the Wi-Fi adapter gates in WS3 (runbook: only the hotspot steps).
- Lesson already paying: every owner-executed deliverable found blocking defects only under adversarial review + execution, none under static reading. Keep the review step mandatory for anything the owner performs physically.
- 2026-09-05 04:10 — A2 harness delivered (45 fixture runs on macOS; R-A2 review running). R-G FIX_REQUIRED on the GS timing lines (late mirror claim unlogged; no file sink on Windows → stamp the WS3 probe log; add monotonic `m`) → FIX-G running. R-C FIX_REQUIRED on both gate-card branches; **critical correction: the CRSF-on-the-wire tap (BG-06 T1) is NOT gate-free** — it is a live-TX bench procedure under the VM runbook :370-397 (car unpowered or RP1 unbound, no bound RX powered in range, attended, discharges nothing) and needs explicit owner authorization like every gate; it is un-gated by A2/Phase B only → FIX-C running (also lands the patched race-day timing parser and a consolidated MISSING_THRESHOLDS.md: 27 items, 7 owner-rulable, 20 bench). V-D PASS → procurement + booklet integrated (8553832). DOCFIX-1 done (7/7) → V-DOC running.
- 2026-09-05 05:35 — Mechanical pack FINAL (V-B PASS, FIX-B2, V-B2 PASS): 3d-codex offline/measurement-sitting 98e27a7 + offline/cad-prep 988cf17; delivered to owner. GS offline/raceday-timing-logs 2f2690a VERIFIED (V-G PASS). VM branch: V-A FAIL (guard bypass via PowerShell prefix binding) → FIX-A3 running. GS harness: R-A2 FIX_REQUIRED → FIX-A2 running. Gate cards: FIX-C done → V-C running. Program branch carries: state files, procurement (reviewed), booklet packet (reviewed), workspace doc fixes (verified).
- 2026-09-05 09:00 — WAVE CLOSED. Program branch program/offline-readiness carries 51 commits / 55 files / +10.6k lines over main f1fc46e: state files, procurement, booklet packet, workspace doc fixes, all 12 gate cards + tools, VM runbook + scripts/vm. Trunk-bound branches awaiting a fresh owner grant: GS offline/windows-validation-harness a80236e, GS offline/raceday-timing-logs 2f2690a, mapper offline/host-prechecks 1f20de5, 3d offline/measurement-sitting 98e27a7 + offline/cad-prep 988cf17, cf offline/docfix-gate-citations 1d17c6b, plus workspace program/offline-readiness → main. Nothing pushed, nothing merged into any trunk, nothing powered/flashed/connected.
