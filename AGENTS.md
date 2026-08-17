# W17 RC Project — Shared Workspace Guidance (Codex)

This file is loaded by **every** Codex session started anywhere under
`/Users/vitaliykhomenko/Documents/projects`, including from inside a nested repo. Keep it
to **stable, workspace-wide** rules only. Volatile state (checkpoints, gate status) lives
in `CURRENT_STATUS.md`; the detailed layout lives in `WORKSPACE_MAP.md`; task/teaching
rules live in each repo's own `AGENTS.md`.

The W17 project is a 1/10-scale FPV, 3D-printed RC Formula 1 car (Mercedes W17 livery),
driven by two ESP32 boards plus a laptop/Windows ground station, with an iPhone HUD client.

## Repo map (Codex territory, this folder)

- `w17-control-fw` — ESP32 #1 control firmware. CRSF in → failsafe/arm/gearbox → servo +
  ESC + gimbal PWM out; one-way `link2` UART to board #2. The main module.
- `w17-soundlight-fw` — ESP32 #2 sound + light firmware. Consumes `link2`; no control authority.
- `w17-ground-station` — Electron viewer app (video + HUD + telemetry). Viewer only; the
  Windows side is the control/integration authority.
- `learning-manual` — the beginner-friendly manual about the whole project.

Each nested repo is its **own git repo** (this folder tracks only the manual + workspace
docs). See `WORKSPACE_MAP.md` for the full picture and canonical-vs-copy registry.

## Ownership split (corrected 2026-08-17 — the 2026-08-11 port had inverted this section)

- **Claude Code owns/maintains:** `w17-control-fw`, `w17-ground-station`,
  `w17-soundlight-fw`, `learning-manual`, `w17-mapper`, `w17-design-system`,
  `w17-3d-codex`, and the hardware bring-up docs/checklists. **A Codex session in this
  workspace is a GUEST in these repos: read-only unless the owner's task explicitly names
  one.** All safety boundaries, gates, and commit rules below bind Codex sessions
  identically.
- **ChatGPT Codex owns/maintains:** `../Codex/w17-rc-print-codex` (printing/mechanical)
  only. (`iPhone_rc` transferred to Claude Code and relocated into this workspace on
  2026-08-17 — a Codex session is a guest there too.)

Do not edit Claude-owned repos from a Codex session unless the task explicitly names one.

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

## Concurrent sessions (one session per working tree)

**One session per repo working tree at a time.** A session that needs a repo another session
already has open does **not** `git checkout` in that tree — it creates its own worktree, somewhere
**outside** `~/Documents/projects` (the session scratchpad is ideal; a sibling path like
`../wt-topic` is **not** — from a nested repo that lands inside the workspace repo itself):

```
git worktree add /path/outside/the/workspace/wt-<topic> -b docs/<topic>
```

Remove it only once its branch has merged. Before touching any repo, run `git worktree list` and
`git branch --show-current`; if the tree is on a branch that is not yours, treat it as **occupied**
and say so in your first report. Re-check HEAD immediately before committing — it can move under you
mid-session.

**Why.** `git checkout -b` in session A silently relocates session B's checkout, and a `git reset`
or `git checkout --` in either destroys the other's uncommitted work — no warning, no reflog to
recover from. This bit the workspace twice on 2026-08-03/04: the hold-last correction had to be
rescued mid-session, and the pre-push hook commit landed on `docs/mapper-config-entry` instead of
`main` because the shared tree was on someone else's branch. Both were recoverable; the failure is
silent, so the next one may not be.

**The corollary that makes this cheap: commit early.** Uncommitted work is the only work a
concurrent session can destroy. Once it is in git, the worst another session can do is move a branch
pointer, which is always recoverable.

## Commit / review rules

- Show diffs before committing; keep commits small and focused.
- Work **one repo at a time**; each nested repo commits in its own repo.
- **Never modify a sibling repo unless explicitly asked.** Sessions default to read-only on
  any repo other than the one the task names.
- Instruction files (`AGENTS.md` / `AGENTS.md`) change only when an invariant changes — not
  to record status. Status goes in `CURRENT_STATUS.md`.

## Where to look

- `WORKSPACE_MAP.md` — stable map, ownership, canonical-vs-copy registry, handoff convention.
- `CURRENT_STATUS.md` — checkpoints, hardware gates (A2 / Phase B), pending validations.
  The **only** workspace-level file that carries commit hashes or status.
- `learning-manual/AGENTS.md` — rules for manual/teaching sessions.
- Each repo's own `AGENTS.md` — repo-specific architecture, invariants, and gates.
- `_handoff/` — dated transfer snapshots (non-canonical; see its README).
