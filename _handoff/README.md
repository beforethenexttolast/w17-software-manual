# `_handoff/` — Transfer Snapshots

Files in this folder are **transfer snapshots**: point-in-time context handed between
sessions, repos, or tools (Claude ↔ Codex).

Rules:

- **Snapshots are not canonical.** They capture what was true when written and go stale.
- **Every snapshot must name its canonical source** — where the live version of that content
  lives (e.g. a repo doc, `WORKSPACE_MAP.md`, or `CURRENT_STATUS.md`).
- Snapshots are **dated** in their filename (e.g. `2026-07-09_topic.md`).
- **Stale snapshots may be deleted after use.** Nothing here is required reading for a normal
  session.

Current truth lives in: `../CLAUDE.md`, `../WORKSPACE_MAP.md`, `../CURRENT_STATUS.md`, and the
repo-local `CLAUDE.md` / `AGENTS.md` files.
