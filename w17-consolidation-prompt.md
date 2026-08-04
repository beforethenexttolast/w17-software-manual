# Session prompt — consolidate five branches, and stop the concurrency hazard

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware, no code.**

> **Opus 5 at `high`.** Mechanical merging, but across two repos with live sessions around it, so
> care over speed. Not a Fable job.

> ⚠ **RUN THIS WHEN NOTHING ELSE IS RUNNING.** It moves branches in shared working trees, which is
> the exact operation that has already destroyed work. **First action: confirm with me that no other
> session is live.** Then `git worktree list` and `git branch --show-current` in both repos, and
> report what you find before touching anything.

---

Work from four sessions is spread across five branches in two repos, plus one worktree and two dirty
files. Nothing is lost, but the records are split and `main` is behind in both places — which is how
the last two days repeatedly produced sessions building on stale context.

## The state to consolidate

**`w17-control-fw`** — `main` at `dd9a445`, 4 unpushed:
- `docs/a2-revision-pass` (`0caf4e4`) — A2 checklist revision, validation plan, closure table, F15/F16
- `docs/holdlast-premise-correction` — **uncommitted work in an isolated worktree**, ~89/27 lines in
  `head_tracking_unlock_plan.md`

**Workspace** — `main` at `9f1883f`, 21 unpushed:
- `docs/a2-revision-pass` (`23ff346`) — PDB guide (`d523983`) + status
- `docs/cb2-gimbal-explainer` (`57b8136`) — CB2 artifact, **currently checked out in the main tree**
- `docs/mapper-config-entry` (`16dad6d`) — config entry + the pre-push hook discharge
- `w17-mapper-config-entry-record.md` — **dirty**, another session's; DEFECT 2 now decided
- Two uncommitted prompt files at the root, deliberately left for this pass

## Do, in this order

1. **Commit the holdlast work first.** It is the only thing not yet in git and therefore the only
   thing that can still be lost. Its own session asked for this. Review the diff before committing.
2. **Commit the dirty config-entry record and the two loose prompt files** onto whichever branch or
   `main` is right for each — the record belongs with `docs/mapper-config-entry`, the prompts on
   `main`.
3. **Merge each branch to its repo's `main`.** Prefer fast-forward; rebase to keep history linear
   where it isn't, matching this workspace's convention. **Verify `--merged` before deleting any
   branch.**
4. **Remove the holdlast worktree** — but only *after* its branch is merged, never before.
5. **Reconcile `CURRENT_STATUS.md`.** Several sessions wrote to it on different branches. After
   merging, read the result end-to-end and check it is coherent — not just conflict-free. Look
   specifically for two entries describing the same thing differently, and for any claim a later
   commit already superseded.

   **One coupling is known and must be handled in the same pass as its merge.** `CURRENT_STATUS.md`
   currently says the unlock plan's §2.3.11.1 "is stale and is corrected." That is **true today** —
   `head_tracking_unlock_plan.md` on `w17-control-fw` `main` still carries the stale
   "hold-last channel array" phrasing in two places. The correction lives only on
   `docs/holdlast-premise-correction` (`499b2b1`). **So: do not touch that status line before the
   branch merges** — doing so asserts a fix that `main` does not yet have. **Do update it in the
   same commit-or-pass that merges `499b2b1`**, or the status file becomes stale in the opposite
   direction. Verify by grepping `main` for the phrasing after merging, not by trusting this note.

## Then fix the cause, not just the symptom

**Two sessions sharing one working tree is what caused this.** `git checkout -b` in session A
silently relocates session B's checkout; a reset in either destroys the other's uncommitted work. It
happened to the holdlast session, and the pre-push hook commit landed on `docs/mapper-config-entry`
rather than `main` for the same reason.

**Add the rule to `/Users/vitaliykhomenko/Documents/projects/CLAUDE.md`.** That file is explicitly for
*stable, workspace-wide* rules and this is one — it is an invariant about how sessions operate, not
status, so it belongs there and not in `CURRENT_STATUS.md`. Draft it for me to approve rather than
writing it in unilaterally; CLAUDE.md changes only when an invariant changes, and I want to see the
wording.

The rule should say roughly: **one session per repo working tree at a time. A session that needs to
work in a repo another session is using creates its own `git worktree` instead of switching branches
in the shared tree.** Include *why* — a bare rule gets ignored, a rule with a destroyed-work story
behind it does not.

## Do not

- Do not push anything. Three pushes are outstanding and all are the owner's call; the `w17-mapper`
  one is additionally governed by the push-review rule in `FORK-NOTICE.md`.
- Do not resolve any open finding, decision, or gate. This pass moves commits and reconciles
  records — nothing more.
- Do not delete a branch you have not verified merged.

## Output

A short map of the final state: what is on each `main`, what was deleted, what is still dirty and
why, and the draft CLAUDE.md wording for approval.

**Safety:** no hardware, no code, nothing flashed or powered. A2 stays NOT-EXECUTED, Phase B stays
BLOCKED. Show diffs before committing.
