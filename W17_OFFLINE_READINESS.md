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
macOS 26.3, Apple M4, 16 GB RAM, **9.6 GiB free on a 228 GiB disk**. No VMware Fusion installed, no Windows ISO on disk,
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
- 5 GHz AP-capable USB Wi-Fi adapter (BUY, ARM64-driver-gated) → USB passthrough → 30-hotspot → hotspot half of WS3.
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
