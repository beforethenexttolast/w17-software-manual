# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes.**
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: 2026-07-10 (ground-station pre-ride setup flow landed: pit-wall UI,
in-app WiFi join/hotspot, controller presets, settings persistence, launch-only elrs
integration, mDNS discovery proposal for iPhone_rc; bench validation pending)._

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `8336caa` | |
| `w17-ground-station` | `3c16954` | pre-ride setup flow (`4103db2`…`3c16954`); 217/217 tests; OS paths bench-unvalidated |
| `w17-soundlight-fw` | `4f25856` | clean |
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
