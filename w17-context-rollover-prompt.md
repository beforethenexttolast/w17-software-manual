# W17 Context Rollover — Consolidation + Persistence Audit + Successor Prep

Reusable prompt for any context-window boundary in a W17 orchestration session.
Adapted 2026-08-17 from the operator's generic template to this workspace's ACTUAL
persistence architecture. Paste it (or point a session at it) when a boundary nears.

This is NOT an engineering task. Purpose: (1) no important project state exists only in
the conversation; (2) no orchestration rule or operator preference exists only in the
conversation; (3) session decisions are durably represented; (4) completed work will not
be repeated; (5) unresolved work stays explicitly unresolved; (6) a compacted continuation
OR a fresh successor recovers accurately from persistent evidence.

Do NOT assume older handoffs are current. Do NOT assume everything important was already
persisted. Do NOT assume everything discussed deserves persistence. Determine all of it
from evidence. Repo/git/evidence and canonical files outrank conversation summaries.

## 1. Establish the current persistent state (the W17 canonical set)

Verify each of these still exists and still serves its stated role; report drift:
- `CLAUDE.md` (workspace) + each repo's `CLAUDE.md` — invariants, safety, ownership ONLY
  (never status). `AGENTS.md` twins carry the same law for Codex guest sessions.
- `CURRENT_STATUS.md` — the SOLE volatile-state owner. Newest dated entry = truth; older
  entries are an as-of log; checkpoints table near the end; hardware-arrival carve-out =
  `HARDWARE_INVENTORY.md`.
- `WORKSPACE_MAP.md` — stable map, ownership, canonical-vs-copy registry.
- `W17_PRODUCT_VISION.md` — canonical vision: 18 decisions, done-bar 1–8, operator model,
  backlog, reality checks.
- `2026-08-16_orchestration_review_packet.md` — branch ledger (§2), owner-decision queue
  (§4), owner authorities (§7½, items numbered and dated), next-universe map (§6).
- `_handoff/` — dated NON-canonical snapshots (incl. rescued design drafts).
- Auto-memory: `MEMORY.md` (index; one-line hooks) + `w17-orchestration-resume-*.md` (the
  rolling resume brief = the successor checkpoint) + the other memory files.
- Per-repo authorities: `w17-control-fw/project-review/` (gates, unlock plan, A2),
  `w17-mapper/FORK-NOTICE.md` (push-review rule), `iPhone_rc/docs/` (canonical bridge
  contract; GS holds the implementation copy).

MULTI-REPO GIT SWEEP (required): for each of workspace, w17-control-fw, w17-soundlight-fw,
w17-ground-station, w17-mapper, iPhone_rc, w17-design-system, w17-3d-codex:
`rev-parse --show-toplevel` identity, branch, short HEAD, dirty state, ahead/behind origin,
`git worktree list`, open branches. Remember: scratchpad worktrees are SESSION-MORTAL;
branches and commits are durable in each repo's object store; a successor runs
`git worktree prune` and re-creates worktrees as needed (always OUTSIDE the workspace).

## 2. Audit this session's conversation against disk

Classify important session information:
A. ALREADY PERSISTED — point to the authoritative file; do not duplicate.
B. PERSISTED BUT STALE/INCOMPLETE — choose: update the mutable state file, add a dated
   supersession note, or leave history and point to newer truth. NEVER silently rewrite
   dated entries (this file's own convention: amend with dated notes, newest entry wins).
C. IMPORTANT BUT CONVERSATION-ONLY — highest priority. Typical W17 leaks: review
   observations queued informally, in-flight agent state, owner answers not yet stamped
   into packet §7½, micro-backlog items named only in chat.
D. TRANSIENT — do not persist (back-and-forth, superseded brainstorming, reproducible tool
   output, phrasing).

## 3. Audit the orchestration rules (record the FINAL CURRENT form)

The W17 rule set to verify/refresh (packet §7½ + CLAUDE.md are the record):
- Orchestrator = architect + delegator; Claude Code owns ALL software repos incl.
  iPhone_rc (transfer 2026-08-17); Codex = w17-rc-print-codex only.
- Pipeline: builder → adversarial reviewer (with plain-language OWNER DIGEST) →
  fix-before-merge → scoped re-verify for blocker-class findings → orchestrator merge.
  Firmware reviews fully delegated (owner, 2026-08-17).
- Git discipline: fixes→main, features→branches; ff-only merges behind repo-identity +
  branch + HEAD guards; absolute `git -C` paths ALWAYS (a cwd reset once aimed a merge at
  the wrong repo); commit early; one session per working tree; agent worktrees in the
  scratchpad; `Co-Authored-By: Claude ... <noreply@anthropic.com>` trailers.
- Push authority: owner-call by default. Named exceptions only, each single-purpose (the
  GS CI-proof push and the iPhone_rc main push were granted and are EXECUTED/closed).
  Mapper pushes additionally governed by FORK-NOTICE; `u4-arbiter` is unpushable by hook
  design and must stay so.
- Safety absolutes — VERIFY PRESENCE, never re-derive or relax: boundaries 1–7
  (workspace CLAUDE.md); A2 NOT-EXECUTED → Phase B BLOCKED; nothing flashed or powered,
  ever, without the gate opening explicitly; FIRST_ACTIVE = NO-GO until R1–R16 + bench
  evidence; BT bench gate BT1; instruction files change only when an invariant changes.
- Owner interaction: options-with-recommendation questions; every answer stamped same-day
  into packet §7½ and CURRENT_STATUS; max-thoroughness is a standing scope rule; the car
  is a gift — "user friendly af" is a product requirement.
- In-flight background agents at a boundary: record task purpose, worktree path, branch,
  and last reported state in the checkpoint. SendMessage-resume works only in the SAME
  session; a successor recovers from disk (worktrees + branches + task output files).

## 4. Audit the project state (the W17 frontier)

Reconstruct from files + git + this session: vision done-bar items 1–8 status; gate
states; branch ledger (merged / open-for-review / parked-gated); owner-decision residue;
bench/hardware ledger; Codex-side dependencies; the NEXT bounded task. Use UNKNOWN /
UNRESOLVED honestly; never invent.

## 5. Classify before writing

DURABLE RULE → CLAUDE.md/AGENTS.md (only if an invariant changed) or packet §7½.
CURRENT STATE → CURRENT_STATUS.md newest entry + the memory resume brief.
HISTORICAL DECISION → dated entry/ADR-style note; immutable, supersede don't rewrite.
REUSABLE PROCEDURE → a workspace doc (like this one) or a skill.
TRANSIENT → nothing.
Do not turn state into rules or rules into dated summaries future sessions might miss.

## 6. Claude-specific persistence check

Auto-loaded at session start here: workspace CLAUDE.md (+ repo CLAUDE.md on entry) and
MEMORY.md (index only — memory files load on recall). Verify: no safety-critical rule
relies SOLELY on auto-memory or conversation; MEMORY.md hooks stay one-line; the resume
brief is an INDEX + delta, not an archive.

## 7. Persist the minimum delta

Make the smallest set of changes for reliable continuation, in the conventional
destinations. This workspace's cadence is consolidation commits with diffs shown in the
report — proceed, then show. Never modify dated historical entries except by dated
amendment.

## 8. The checkpoint (use existing conventions — do NOT invent a new file)

Update BOTH: (a) `CURRENT_STATUS.md` — a new dated entry (demote the previous to "Prior
pass"); (b) the auto-memory resume brief — canonical-docs list, trunk hashes, branch
ledger, in-flight agents + worktrees, authorities pointer, next bounded task, owner
residue. References over copies.

## 9. Prepare both continuation paths

PATH A — same session after automatic summarization: produce a compact nucleus of only
what must survive a summary and does not auto-reload: current role, active pipeline step,
exact in-flight branch/worktree/agent state, unpersisted decisions, stop conditions,
where canonical truth lives.
PATH B — fresh successor session: produce a bootstrap prompt that has the successor
(1) note that CLAUDE.md + MEMORY.md auto-loaded; (2) read the resume brief, then
CURRENT_STATUS newest entry, then packet §7½/§2/§4/§6, then the vision doc; (3) run the
multi-repo git sweep itself; (4) reconstruct state independently and COMPARE with the
checkpoint, reporting contradictions; (5) state goal, frontier, next task, authorities;
(6) then CONTINUE the recorded in-flight pipeline under the recorded standing authorities
— stopping only for work outside them (new scope, new pushes, gate changes, anything
touching hardware). A successor must not accept the outgoing session's summary on
authority; it verifies.

## 10. Verify persistence

All changed files committed (workspace repo identity-guarded); no engineering files
touched by the continuity task; historical entries unmodified; the resume brief and
CURRENT_STATUS agree; the successor path is unambiguous.

## 11. Final return

Report: PERSISTENCE_AUDIT_STATUS, CURRENT_STATE_RECOVERED_FROM, ALREADY_PERSISTED,
STALE_OR_INCOMPLETE, NEWLY_PERSISTED_DELTA, NOT_PERSISTED_TRANSIENT,
CURRENT_ORCHESTRATION_RULES (pointer), CURRENT_PROJECT_GOAL, CURRENT_FRONTIER,
CURRENT_NEXT_TASK, IMPORTANT_UNRESOLVED, WHAT_IS_NOT_FINALIZED, FILES_CREATED/UPDATED,
HISTORICAL_UNTOUCHED, GIT_STATE, VERIFICATION, COMPACTION_INSTRUCTIONS (Path A text),
SUCCESSOR_BOOTSTRAP_PROMPT (Path B text), RECOMMENDATION (CONTINUE_WITH_COMPACTION /
ROLLOVER_TO_FRESH_SESSION / EITHER_IS_SAFE) + REASON. Do not start new engineering waves
from within the continuity task; already-running agents continue and are recorded.
