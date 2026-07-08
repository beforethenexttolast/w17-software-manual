# W17 RC Project — Shared Workspace Guidance (Claude Code)

This file is loaded by **every** Claude Code session started anywhere under
`/Users/vitaliykhomenko/Documents/projects`, including from inside a nested repo. Keep it
to **stable, workspace-wide** rules only. Volatile state (checkpoints, gate status) lives
in `CURRENT_STATUS.md`; the detailed layout lives in `WORKSPACE_MAP.md`; task/teaching
rules live in each repo's own `CLAUDE.md`.

The W17 project is a 1/10-scale FPV, 3D-printed RC Formula 1 car (Mercedes W17 livery),
driven by two ESP32 boards plus a laptop/Windows ground station, with an iPhone HUD client.

## Repo map (Claude Code territory, this folder)

- `w17-control-fw` — ESP32 #1 control firmware. CRSF in → failsafe/arm/gearbox → servo +
  ESC + gimbal PWM out; one-way `link2` UART to board #2. The main module.
- `w17-soundlight-fw` — ESP32 #2 sound + light firmware. Consumes `link2`; no control authority.
- `w17-ground-station` — Electron viewer app (video + HUD + telemetry). Viewer only; the
  Windows side is the control/integration authority.
- `learning-manual` — the beginner-friendly manual about the whole project.

Each nested repo is its **own git repo** (this folder tracks only the manual + workspace
docs). See `WORKSPACE_MAP.md` for the full picture and canonical-vs-copy registry.

## Ownership split

- **Claude Code owns/maintains:** `w17-control-fw`, `w17-ground-station`,
  `w17-soundlight-fw`, `learning-manual`, and hardware bring-up docs/checklists.
- **ChatGPT Codex owns/maintains:** `iPhone_rc` (lives under `../Codex/iPhone_rc`).
- **Printing/mechanical Codex repo is separate:** `../Codex/w17-rc-print-codex` — do not
  touch unless explicitly asked.

Do not edit Codex-owned repos from a Claude Code session.

## Safety boundaries (non-negotiable, apply to every session)

1. **No active iPhone-derived pan/tilt** until a separate, reviewed safety milestone approves it.
2. **No iPhone → CRSF.**
3. **No iPhone → servo / gimbal / ESC.**
4. **Firmware never parses iPhone JSON or receives iPhone UDP** — firmware stays
   iPhone-unaware. (Gimbal pan/tilt is stick-driven CRSF ch9/10 only, source-agnostic.)
5. **W3 (UDP 5602 head-tracking receiver on Windows) is LOG-ONLY.** It must never reach
   CRSF, servos, or the gimbal.
6. **Firmware is the only producer of final hardware outputs**, and only from
   already-arbitrated inputs.
7. **Windows is the control/integration authority; the iPhone is a thin HUD/client.**

Also: no flashing or powering hardware in an unattended session; do not implement active
pan/tilt; do not create any iPhone-to-control path.

## Commit / review rules

- Show diffs before committing; keep commits small and focused.
- Work **one repo at a time**; each nested repo commits in its own repo.
- **Never modify a sibling repo unless explicitly asked.** Sessions default to read-only on
  any repo other than the one the task names.
- Instruction files (`CLAUDE.md` / `AGENTS.md`) change only when an invariant changes — not
  to record status. Status goes in `CURRENT_STATUS.md`.

## Where to look

- `WORKSPACE_MAP.md` — stable map, ownership, canonical-vs-copy registry, handoff convention.
- `CURRENT_STATUS.md` — checkpoints, hardware gates (A2 / Phase B), pending validations.
  The **only** workspace-level file that carries commit hashes or status.
- `learning-manual/CLAUDE.md` — rules for manual/teaching sessions.
- Each repo's own `CLAUDE.md` — repo-specific architecture, invariants, and gates.
- `_handoff/` — dated transfer snapshots (non-canonical; see its README).
