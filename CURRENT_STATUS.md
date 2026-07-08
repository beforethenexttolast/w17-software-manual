# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes.**
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: 2026-07-09 (from the 2026-07-09 instruction-structure audit)._

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `8336caa` | |
| `w17-ground-station` | `dab3039` | |
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

- **Real iPhone ↔ Windows bridge validation: PENDING** (not yet run against the real
  ground-station repo).
- **Active iPhone-derived pan/tilt: BLOCKED** behind a separate, reviewed safety milestone.
  Until then: no iPhone → CRSF, no iPhone → servo/gimbal, firmware stays iPhone-unaware, and
  the Windows W3 (UDP 5602) receiver is LOG-ONLY.
