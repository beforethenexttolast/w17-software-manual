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

## 3. Workstreams and status
| WS | scope | worker(s) / model | branch (worktree in session scratchpad) | status |
|---|---|---|---|---|
| A | Windows/VM: runbook validation, guest software list, one-shot setup/check scripts, pwsh validation, USB passthrough, 5 GHz AP tests, hot-plug, evidence capture | A1 Opus (runbook+host), A2 Sonnet (GS scripts harness), A3 Sonnet (ARM64 driver research), A4 Sonnet (mapper host pre-checks) | offline/vm-runbook (ws), offline/windows-validation-harness (GS), offline/host-prechecks (mapper) | LAUNCHED wave 1 |
| B | No-power mechanical measurement sitting + CAD/coupon prep | B1 Opus (sitting pack), B2 Sonnet (CAD/coupon prep + params ingest) | offline/measurement-sitting, offline/cad-prep (3d) | LAUNCHED wave 1 |
| C | Bench-gate cards (A2, Phase B, D8, BT1, coordinated flash, CRSF-on-wire, halo; FIRST_ACTIVE, phone latency, hot-plug, race-day link) + deterministic tooling | C1 Opus (firmware/bench), C2 Opus (ground side) | offline/bench-gates-fw, offline/bench-gates-ground (ws) | LAUNCHED wave 1 |
| D | Procurement reconciliation | D1 Sonnet (+A3 feed) | offline/procurement (ws) | LAUNCHED wave 1 |
| E | Owner action queue | Director (Fable) | program/offline-readiness (ws) | LIVE — `W17_OWNER_ACTIONS.md` |
| F | Booklet editorial packet (facts fixed by agents; tone lines to owner) | F1 Sonnet | offline/booklet-editorial (ws) | LAUNCHED wave 1 |
Wave 2 (after wave 1): Opus adversarial review of every deliverable that the owner will execute physically; Director integration
into `program/offline-readiness`; queue trunk merge + push for an owner grant.

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
