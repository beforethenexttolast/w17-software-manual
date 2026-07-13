# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes.**
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: 2026-07-13. Control-firmware remediation through R5-b is complete:
validated delivery NVS loading, configurable steering endpoints, console parsing
hardening, a provisional 2-second control-loop Task Watchdog, and RTC-retained
reset diagnostics. Native tests: 224/224; all ESP32 environments build. Live
watchdog-cycle observation and physical reset-path validation remain pending.
A2 remains unexecuted and Phase B remains blocked.

Ground-station pre-ride setup flow, iPhone mDNS proposal, and `w17-3d-codex`
bootstrap status remain as recorded below._

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `72d5347` | R1–R5-b remediation complete; 224/224 native tests; all ESP32 environments build; live watchdog-cycle observation and physical reset-path validation pending |
| `w17-ground-station` | `3c16954` | pre-ride setup flow (`4103db2`…`3c16954`); 217/217 tests; OS paths bench-unvalidated |
| `w17-soundlight-fw` | `4f25856` | clean |
| `w17-3d-codex` | `80e7f74` | bootstrapped 2026-07-10: 210 files classified (37 required staged), docs + gates written; 4 human gates open, nothing printed |
| `iPhone_rc` (Codex) | `b51ebe0` | AGENTS.md added/committed/pushed |
| `w17-rc-print-codex` (Codex) | `75b408c` | has existing untracked reports |

> Checkpoints drift as work continues. Re-verify with `git -C <repo> rev-parse --short HEAD`
> before relying on any hash here.
>
> `CURRENT_STATUS.md` may record hashes for other repos, but should not try to record the
> exact hash of the repo that contains it (that would go stale on every commit that touches
> this file).

## Hardware gates

- **A1.1–A1.6 software / pre-power validation: COMPLETE.**
- **A2 no-power bench checklist: committed but NOT EXECUTED.** No measurements recorded; A2
  is not closed. Canonical checklist:
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`.
- **Phase B (powered) is BLOCKED** until A2 is filled in, pasted back, reviewed, and approved.
- Golden rule: ESC motor power stays disconnected until the failsafe + arm chain is proven
  live (Phase A → B).

## Firmware freeze status

- **CF-1 delivery tuning persistence: RESOLVED.**
  - Delivery `esp32dev` loads the complete validated NVS settings object at boot.
  - Missing, corrupt, outdated, or invalid settings fall back atomically to complete compiled defaults.
  - Tuning console and settings mutation remain available only in `esp32dev_tuning`.
  - Native tests: **153/153 passing**.
  - `esp32dev`, `esp32dev_tuning`, and `esp32dev_sim` build successfully.
  - Physical NVS save → reflash → reload behavior remains a powered-bench verification item.
- CF-2 steering endpoint tuning: RESOLVED.
  - `steer.min` and `steer.max` are available in `esp32dev_tuning`.
  - Endpoint updates are atomically validated and persisted through the existing settings blob.
  - The settings layout and blob version remain unchanged.
  - Delivery `esp32dev` remains console-free.
  - Native tests: 168/168 passing.
  - All ESP32 environments build successfully.
  - Actual endpoint values remain Phase-B hardware calibration evidence.
- Console parsing hardening: COMPLETE.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - Native tests: 195/195 passing.
  - All ESP32 environments build successfully.
  - Delivery and simulation remain console-free.
- **Control-firmware software remediation through R5-b: COMPLETE.**
  - Delivery loads validated NVS tuning while remaining application-console-free.
  - Steering minimum and maximum endpoints are configurable in the tuning build.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - The Arduino `loopTask` is directly subscribed to the global Task Watchdog with a
    provisional 2-second timeout.
  - The watchdog is fed exactly once after each completed 50 Hz actuator-control tick.
  - All watchdog API failures are handled fail-fatally.
  - RTC-retained reset diagnostics classify every reset reason in the pinned ESP-IDF
    version.
  - Tuning and simulation builds print the boot reset reason and retained-session count;
    delivery remains silent.
  - Native tests: 224/224 passing.
  - All ESP32 environments build successfully.
  - Live Wokwi stall → watchdog panic → reboot observation: PENDING.
  - Physical reset reason, RTC retention, panic/reboot-to-safe-output timing,
    GPIO13/GPIO14 reset state, and real ESC signal-loss behavior remain Phase-B evidence.

## Pending validations

- **Real iPhone ↔ Windows bridge validation: PENDING (in progress).**
  - **Windows GS host stood up (2026-07-09):** fresh clone of `w17-ground-station` at
    checkpoint `dab3039`, `npm install` done, `npm test` green (118/118) on Windows —
    identical to macOS. No source/schema/firmware/dependency drift.
  - **Blocker — network client isolation:** the office guest Wi-Fi (`SE-Guest`, Public
    profile) isolates clients — laptop↔laptop ping fails both ways — so direct LAN UDP for
    W2/W3 cannot pass. Real cross-device validation needs a **non-isolated** network; this
    is a network limitation, not a bridge bug.
  - **Approach:** spare-phone (Android) Mobile Hotspot now; **Ralink RT5370 USB Wi-Fi as a
    PC-hosted SoftAP** as the permanent bench network (ordered — AP-mode support on Win
    10/11 to be verified on arrival); FPV **camera AP** for a later field-representative
    pass. Gate every attempt on a peer-to-peer ping before any UDP test.
  - Not yet run end-to-end against a real iPhone (no device on hand yet).
  - **New since 2026-07-10 — in-app setup flow supersedes manual network setup:** the
    ground station (checkpoint `3c16954`) now scans/joins WiFi and hosts a hotspot
    itself (Mobile Hotspot backend preferred; legacy `hostednetwork` fallback targets
    the RT5370, needs elevation), runs the peer ping as a first-class GRID check, and
    can enable W2/W3 from persisted settings (`settings.json` in userData; **set env
    vars always win**). Orchestration logic is unit-tested against canned command
    output (217/217); the **real OS layer is UNVALIDATED** — runbook with evidence
    boxes: `w17-ground-station/docs/setup_flow_bench_checklist.md`. W3 remains
    LOG-ONLY (new: it exposes the last accepted sender's IP as a user-confirmed
    address suggestion — transport metadata only, guard-tested).
- **mDNS discovery of the iPhone HUD: PROPOSED, awaiting iPhone_rc (Codex) adoption.**
  Proposal: `w17-ground-station/docs/proposals/iphone_mdns_discovery.md`; handoff +
  Codex prompt: `_handoff/2026-07-10_ground-station_setup_flow_and_mdns.md`. Windows
  implements nothing until the canonical contract adopts it.
- **Active iPhone-derived pan/tilt: BLOCKED** behind a separate, reviewed safety milestone.
  Until then: no iPhone → CRSF, no iPhone → servo/gimbal, firmware stays iPhone-unaware, and
  the Windows W3 (UDP 5602) receiver is LOG-ONLY.
