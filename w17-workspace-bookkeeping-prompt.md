# Session prompt — 2. Workspace bookkeeping sync (no hardware)

Paste into a Claude Code session started at `~/Documents/projects`.

Run **after** prompt 1 (needs the new `w17-ground-station` HEAD + CI run ID).

---

The workspace docs have drifted behind the actual repos and several finished commits are unpushed.
Nothing here needs hardware and **no gate changes** — A2 stays NOT-EXECUTED, Phase B stays BLOCKED.

State verified 2026-07-25:

| Repo | Actual | Recorded in `CURRENT_STATUS.md` |
|---|---|---|
| `w17-ground-station` | `3119180` + WIP (see prompt 1) | `8441adb` |
| `w17-control-fw` | `1834852` | `8ed0a6c` |
| `w17-soundlight-fw` | `ec5ddf8` — **11 commits unpushed** | `4f25856` |
| `w17-design-system` | `6a59c96` — **1 commit unpushed** | (not carried) |
| workspace repo | on branch `w17-batch1-measurements`; `main` is **3 ahead of `origin/main`** | — |

Do this, in order:

1. **Push the finished work.** In `w17-soundlight-fw`, show me `git log --oneline @{u}..HEAD` (11 commits:
   `5747d95..ec5ddf8` — audio-task failure handling, wrap-safe engine timers, synth convergence, UART0
   diagnostics gating, README count fix). Confirm native tests are green (**expect 94/94**) *before*
   pushing, then push. Same for the single unpushed `w17-design-system` commit. Push only — no edits.
2. **Branch decision — ask me, don't assume.** I'm on `w17-batch1-measurements` and `main` is 3 ahead of
   origin. Lay out the options (merge the branch to main and push; keep the branch and push both; PR) with
   what each implies for the other repos' hashes, and let me pick.
3. **`HARDWARE_INVENTORY.md`** has an uncommitted 337-line rewrite. Read it, then finish the job
   `CURRENT_STATUS.md` (2026-07-24 entry) says it still owes: the **ordered / in-transit electrical rows as
   ⏳** — 2× MH-ET D1-Mini ESP32 (USB-C), ceramic + electrolytic cap kits, Amass XT90-S anti-spark master
   switch + XT60→XT90 adapter, IP2326 2S Type-C balancing charger (18.3×31 mm), ZEEE 1500 mAh 2S LiPo
   (69×35×18, JST-XH, to be re-terminated to XT60), 1N5819 from office stock. Preserve the existing rewrite;
   don't clobber it. That file carries **arrival status only** — no hashes, no gate state.
4. **Sync `CURRENT_STATUS.md`** in one pass: correct the checkpoint table to real hashes (including the new
   GS HEAD + CI run ID from prompt 1), and fix the stale claim that the setup-flow audit's **HIGH finding
   is unfixed** — it is fixed: `shared/settings.js:191` now admits a validated `wheel.profile` subtree
   through `normalizeSettings`, with a hostile-corpus persistence test. Record which of the audit's other
   findings remain open (prompt 3 handles them). Overwrite in place; do not append history.
5. **Triage the 12 untracked root files.** For each, tell me whether it is a live handoff or a spent
   artifact, then commit or delete on my say-so:
   - Codex handoffs: `w17-codex-cassette-audit-prompt.md`, `w17-codex-cassette-reaudit-prompt.md`,
     `w17-codex-connection-detail-prompt.md`, `w17-codex-servo-station-query.md`,
     `w17-codex-wire-schedule-prompt.md`, `w17-electrical-inputs-for-codex.md`
   - Apparently-spent GS artifacts: `w17-ground-station-a1.patch`, `w17-ground-station-a1-audit.md`,
     `w17-ground-station-a1-a2.patch`, `w17-ground-station-a1-a2-audit.md`,
     `w17-ground-station-a1-a2-status.txt`, `w17-ground-station-through-d1-d4.patch`,
     `w17-ground-station-through-d1-d4-audit.md`, `w17-ground-station-through-d1-d4-status.txt`,
     `w17-ground-station-fable-handoff.md` (its deliverable `w17-ground-station-impl-plan.md` does not
     exist — check whether that work landed anyway before discarding), `w17-steering-servo-fit-diagram.html`,
     `w17-new-session-physical-start-prompt.md`
   - Also decide `.preview-tmp/` and whether `.claude/` should be committed or git-ignored.
   Verify a patch's content is actually in history before calling it spent — quote the commit.
6. Show all diffs before committing. Keep commits docs-only and focused. Do not edit any Codex-owned repo
   (`w17-3d-codex`, `../Codex/*`).
