# W17 Workspace Map

Stable map of the W17 workspace. **No volatile status here** — checkpoints, gate state, and
pending validations live in `CURRENT_STATUS.md`.

## Two workspace roots

- `/Users/vitaliykhomenko/Documents/projects` — **Claude Code** root. Also a git repo
  (`w17-software-manual`) that tracks the manual + these workspace docs; the nested firmware
  and ground-station repos are separate git repos (git-ignored here).
- `/Users/vitaliykhomenko/Documents/Codex` — **ChatGPT Codex** root, physically separate so
  Claude's parent-directory context never reaches Codex repos and vice versa.

## Repos / folders and what each owns

| Repo / folder | Root | Owner | Owns / responsible for |
|---|---|---|---|
| `w17-control-fw` | projects | Claude Code | ESP32 #1 control firmware: CRSF parse, failsafe, arm gate, virtual gearbox, servo/ESC/gimbal PWM, battery ADC, Hall wheel-speed, `link2` TX. The **only** producer of final hardware outputs. |
| `w17-soundlight-fw` | projects | Claude Code | ESP32 #2 sound + light: consumes `link2`, V10 engine synth (I2S/MAX98357A), WS2812 lights. No control authority. |
| `w17-ground-station` | projects | Claude Code | Electron viewer app: video + F1 HUD + telemetry. Windows side is control/integration authority; the app itself is viewer-only. |
| `learning-manual` | projects | Claude Code | Beginner-friendly manual for the whole system. Persistent teaching output. |
| `w17-3d-codex` | projects | Claude Code | 3D printing & fabrication: model inventory, materials, Bambu slicing specs, test prints, finishing/painting/decals, printed-part assembly. Raw STLs live untracked in its `unsorted_stl_raw/`. Consults the Codex `w17-rc-print-codex` reports read-only. |
| `iPhone_rc` | Codex | ChatGPT Codex | Thin iPhone FPV HUD client. Receives telemetry (UDP 5601), sends head-tracking **intent** (UDP 5602). No control path. |
| `w17-rc-print-codex` | Codex | ChatGPT Codex | STL/SCAD print-decision project (3D-print filtering). Isolated from firmware/bridge/electronics. Do not touch unless explicitly asked. |

## Ownership split (quick reference)

- **Claude Code:** control-fw, soundlight-fw, ground-station, learning-manual, w17-3d-codex
  (3D printing/fabrication/finishing), hardware bring-up docs/checklists.
- **ChatGPT Codex:** iPhone_rc (bridge/HUD) and w17-rc-print-codex (printing/mechanical).

## Canonical-vs-copy registry

Every copy must state, in its own header, where the canonical source lives.

| Artifact | Canonical source | Known copies |
|---|---|---|
| iPhone bridge contract | `iPhone_rc/docs/windows_bridge_contract.md` | `w17-ground-station/docs/windows_bridge_contract.md` (Windows **implementation copy**); any file in `_handoff/` is a dated snapshot, not canonical |
| iPhone bridge JSON schemas | `iPhone_rc/schemas/` | consumers reference, do not fork |
| iPhone bridge examples | `iPhone_rc/examples/` | consumers reference, do not fork |
| `link2` protocol | `w17-control-fw/docs/link2_protocol.md` | `w17-soundlight-fw/docs/link2_protocol.md` (copy — do not fork; changes happen in control-fw first) |
| A2 no-power hardware checklist | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` | — (single source) |
| Pan/tilt firmware readiness | `w17-control-fw/project-review/iphone_pan_tilt_firmware_readiness.md` | — (single source; keep no duplicate at projects root) |
| Manual chapters | `learning-manual/` | — |

## Handoff convention

- Handoff / transfer docs are **dated** (e.g. `2026-07-09_topic.md`).
- Snapshots are **not canonical** — they are point-in-time context/transfer artifacts.
- Every copy or snapshot must name its canonical source.
- Stale snapshots may be deleted after they are consumed.
- Claude→Codex transfers are delivered into the Codex repo (e.g. `iPhone_rc/docs/`);
  Codex→Claude transfers land in `projects/_handoff/`.
