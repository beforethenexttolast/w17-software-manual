# Learning-Manual Session Rules (Claude Code)

These rules apply when a session's task is the **learning manual**. Workspace-wide rules
(repo map, ownership, safety boundaries) live in `../CLAUDE.md`; this file only adds the
manual-specific ones.

- `learning-manual/` is the manual/teaching project — a **complete, beginner-friendly
  learning manual** for the whole W17 system, aimed at a beginner C++ programmer who is
  strong on electronics/Linux.
- **The source repos are read-only during manual sessions** unless a change is explicitly
  approved. Do not modify `w17-control-fw`, `w17-ground-station`, `w17-soundlight-fw`,
  the iPhone repo, or the print repo from a manual session.
- **Write only inside `learning-manual/`** — that is the persistent output of this work.
- Start from `README.md`, then `00_START_HERE.md`. Current per-chapter/batch status lives
  in `source_code_progress.md`; inventory/order in `source_code_explanation_plan.md`.
- **Tag claims `[C]` / `[I]` / `[A]`** (confirmed / inferred / assumption) and cite the
  evidence for inferences — this is the manual's standing convention.
- Keep explanations detailed and beginner-friendly; never skip a C++, electronics,
  embedded, RC, protocol, or desktop-app detail because it seems "obvious to a programmer."
- Always reference exact files, functions, classes, structs, constants, configs, or docs
  (e.g. `w17-control-fw/lib/failsafe/src/FailsafeStateMachine.cpp`).
- Prefer many structured markdown documents over one huge answer.
- Ignore build-output/dependency folders (`.pio/`, `node_modules/`) unless needed.
