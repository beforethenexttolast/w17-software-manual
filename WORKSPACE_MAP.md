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
| `w17-design-system` | projects | Claude Code | Visual source of truth for the ground-station setup-flow redesign (Batches 2/3/6): `w17.css` tokens + `foundations/`/`components/` cards + 1280×800 screen mockups. Design reference only (no runtime code); the `w17-ground-station` renderer is the implementation. |
| `w17-mapper` | projects | Claude Code | Owned fork of `elrs-joystick-control` (upstream `github.com/kaack/elrs-joystick-control`, pinned `2b8031a`; branch `w17-headtrack`; **GPL-3.0-or-later**). The production DualShock→CRSF→ELRS mapper and, per owner decision #1 (topology (a), 2026-07-15), the production owner of UDP 5602 head-intent ingest. Read-only reference copy stays at `_vendor/elrs-joystick-control` (never edited). **Public fork** (`github.com/beforethenexttolast/w17-mapper`, since 2026-07-25); every push is governed by the `FORK-NOTICE.md` push-review rule, with the tracked `.githooks/pre-push` guard as the accident backstop. |
| `learning-manual` | projects | Claude Code | Beginner-friendly manual for the whole system. Persistent teaching output. |
| `w17-3d-codex` | projects | Claude Code | 3D printing & fabrication: model inventory, materials, Bambu slicing specs, test prints, finishing/painting/decals, printed-part assembly. **Since 2026-09-02 also the mechanical-design home** (owner decision): electronics placement study, trays/cassette, inner cage / second floor, DRS flap linkage, charge flap, GCS box — parametric OpenSCAD sources + fit-check parts. Raw STLs live untracked in its `unsorted_stl_raw/`. Consults the Codex `w17-rc-print-codex` reports read-only. |
| `iPhone_rc` | projects | Claude Code | Thin iPhone FPV HUD client. Receives telemetry (UDP 5601), sends head-tracking **intent** (UDP 5602). No control path. **Transferred from Codex ownership + relocated into this root 2026-08-17 (owner decision); the pre-transfer VR-calibration WIP is preserved verbatim on branch `codex-wip-vr-calibration`; its disposition lives in the review packet §5 / `CURRENT_STATUS.md`, never here.** |
| `w17-rc-print-codex` | Codex | ChatGPT Codex | STL/SCAD print-decision project (3D-print filtering). Isolated from firmware/bridge/electronics. Read-only reference since 2026-09-02 (mechanical design moved to Claude Code); do not edit. |

## Ownership split (quick reference)

- **Claude Code:** control-fw, soundlight-fw, ground-station, design-system, learning-manual,
  w17-3d-codex (3D printing/fabrication/finishing **+ mechanical design since 2026-09-02**),
  **iPhone_rc (since 2026-08-17)**, and hardware bring-up docs/checklists.
- **ChatGPT Codex:** w17-rc-print-codex (historical print-decision reports; read-only reference).

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
| Setup-flow visual design | `w17-design-system/` (`DESIGN_NOTES.md` + `screens/`) | `w17-ground-station/renderer/` is the **implementation**, not a copy. Per Decision B (`DESIGN_NOTES.md` §10, 2026-07-19) the shipped stacked full-panel BOTH-mode SEAT FIT layout is canonical; `screens/02c-seatfit-both.html` is superseded/historical. |
| Hardware inventory / delivery log | `HARDWARE_INVENTORY.md` (projects root) | — (single **workspace-level** log for physical-part *arrival / on-hand* + BOM-mapping-confidence status, mapped to BOM v2). Carries no gate status, software/execution state, or commit hashes (those stay in `CURRENT_STATUS.md`); mechanical measure/fit/mount status stays in `w17-3d-codex`, whose arrival notes are historical, not a second ledger. |
| Product vision / definition of done | `W17_PRODUCT_VISION.md` (projects root) | — (single source; decision numbers match the owner's 2026-08-16 vision Q&A) |
| Windows-VM validation environment (owner decision A4) | `w17-windows-vm-validation-runbook.md` (projects root) | — (single source for the **one-time owner VM setup** and the **autonomous-drive design**: Fusion/ARM64 guest, PowerShell 7 prerequisite, OpenSSH, snapshots, `vmrun`, the run sequence and its safety preconditions). The **scripts** it drives are `w17-ground-station/scripts/windows-validation/`, whose own `README.md` is canonical for what each script does — this runbook does not duplicate that. Carries no gate status or commit hashes (those stay in `CURRENT_STATUS.md`), and discharges nothing on its own. |

## Handoff convention

- Handoff / transfer docs are **dated** (e.g. `2026-07-09_topic.md`).
- Snapshots are **not canonical** — they are point-in-time context/transfer artifacts.
- Every copy or snapshot must name its canonical source.
- Stale snapshots may be deleted after they are consumed.
- Claude→Codex transfers are delivered into the Codex repo (e.g. `iPhone_rc/docs/`);
  Codex→Claude transfers land in `projects/_handoff/`.
