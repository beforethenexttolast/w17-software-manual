# W17_CURRENT_STATE — compact durable program state (readiness program, opened 2026-09-02)

Purpose: enough for a fresh context (compaction or usage-limit recovery) to resume WITHOUT chat history.
Authority order: workspace `CLAUDE.md` (safety boundaries 1–7) > `2026-09-02_readiness_program.md`
(owner decisions A1–A10 incl. OD-1…OD-18) > this file > `CURRENT_STATUS.md` narrative. Immutable
completed evidence (never rerun): the five repo review sweeps, the three grand perspectives, the grand
verdict, the cross-repo probe (session scratchpad `review-seeds/`; reports copied to `briefs/reports/`).
Scratchpad root (this session): `/private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/9a131be5-75e5-4b91-9d54-0fedf52c1bf8/scratchpad` ("SP").

## 1. Canonical trunk SHAs (updated 2026-09-04 00:10 after post-compaction reconciliation; wave 4 = relaunch of the 11 agents killed by the 21:00 usage limit — 5 fresh (4 Opus reviews + iPhone fixer), 5 continuations of durable partial work, 1 instr re-verify; pwsh 7.7.0-preview.4 at SP/pwsh-expanded/component.pkg/Payload/usr/local/microsoft/powershell/7-preview/pwsh; ffmpeg at /opt/homebrew/bin/ffmpeg)
| repo | trunk | SHA | pushed | tests at trunk |
|---|---|---|---|---|
| workspace (this repo) | main | see `git log -1` (this commit) | pushed after each landing | link checks |
| w17-control-fw | main | 00c7612 | yes | 330 native, 5 envs (B1 runbooks landed 2026-09-03) |
| w17-soundlight-fw | main | 8b259bf | yes | 137 native, 2 envs |
| w17-ground-station | main | 35e5efc | yes | 1447 / 67 files |
| w17-mapper | w17-headtrack (NOT main) | 21834fe | yes | 180 PASS lines (133 top-level) |
| iPhone_rc | main | 61ad68f | yes | 74 (dev_check.sh) |
| w17-3d-codex | main | 5dddedb | yes | render.sh --table (17 rendered, 0 failed) |
| u4-arbiter (mapper) | parked branch | e4f6ae8 (backup ref backup/u4-arbiter-pre-rebase-20260902 = 93be341) | NEVER | gated + default modes green |

## 2. Landed in the program (all reviewed → fixed → re-verified → guarded ff merge → pushed)
iPhone B5 giftee install docs (61ad68f); mapper B7 release job (21834fe); control-fw B8 plan refresh (7c00668) + B1 readiness runbooks (00c7612);
GS B3 docs refresh (35e5efc); soundlight docs/brief-catches-up (8b259bf); workspace: vision amendments, ownership edit, program packet, checkpoint, owner round 2 + this file, B2 readiness runbooks (e404734).

## 3. Branch ledger (worktrees live under SP; one session per tree)
| branch (repo) | worktree | tip | state |
|---|---|---|---|
| docs/brief-catches-up (sl) | wt-sl-docs | 8b259bf | LANDED on sl main 8b259bf, pushed (2026-09-03) |
| docs/readiness-runbooks (workspace, B2) | wt-ws-runbooks | e404734 | LANDED on workspace main e404734, pushed (re-verify PASS + 2 orchestrator citation fixes) |
| docs/readiness-runbooks (cf, B1) | (worktree removed) | 00c7612 | LANDED on cf main 00c7612, pushed (re-verify PASS + one hash-citation fix) |
| docs/manual-truth-pass (workspace, B6) | wt-manual | 73f9dca + uncommitted ch09 diagram edit | FIXER (Sonnet) CONTINUING from partial work (3 of 10 items committed) |
| feat/windows-validation-scripts (GS, B4) | wt-gs-winval | 7cea58a (rebased onto 35e5efc) + uncommitted common.ps1 edit | FIXER (Opus) CONTINUING; new blocking bug found (Write-W17Result swallows the result line) |
| docs/windows-vm-runbook (workspace, B4) | wt-ws-winval | 63492ec (rebased onto e404734) | same FIXER; rebase onto 0c40b6e+ at the end |
| docs/instruction-file-invariants (cf/sl/GS/iPhone, OD-1 + OD-16) | wt-cf-instr 762f099 / wt-sl-instr 8eb3c98 / wt-gs-instr 9de86ae / wt-iphone-instr 5e19f94 | | all review findings fixed; iPhone carries OD-16 + the resolved-destination gate sentence (orchestrator-authored) → RE-VERIFY (Sonnet) in flight; merge cf/sl/GS after PASS, iPhone only after fix/telemetry-honesty-and-ci lands |
| design/placement-and-cage (3d, B9) | (worktree removed) | 165827c | LANDED on 3d main 5dddedb (+ CLAUDE.md folder-map rows), pushed; owner residue = measurement session M-00… |
| u4-arbiter (mapper) | wt-u4 | 82d8938 + uncommitted README edit | S22 dtClampMs ratified committed; ratification agent (Sonnet) CONTINUING (README, template, FORK-NOTICE rows, both-mode tests); NEVER push |
| docs/r-review-ratifications (cf) | wt-cf-plan | c24fa7c (base 7c00668) | DONE by the interrupted agent (link fix + OD-17/18 section); being cross-checked by the continuing ratification agent → verify → rebase onto 00c7612 → merge |
| fix/telemetry-honesty-and-ci (iPhone) | wt-iphone-fix | 2ce12ee | review FIX_REQUIRED (2 blocking = rulings, 6 minor; report briefs/reports/a376b7a66fb2ee24b.md) → FIXER (Sonnet) in flight (append-only) |
| feat/phone-live-video (iPhone) | wt-iphone-video | c112622 (slice 1) + uncommitted slice-2 files | IMPLEMENTER (Opus) CONTINUING slices 2–3; rebase onto the fix branch's new tip at the end |
| design/phone-live-video (iPhone) | wt-iphone-video-design | 50f25da | design doc; consumed by the implementer |
| fix/sensor-honesty-and-ci (cf) | wt-cf-fix | d8c5f7c | built (351 tests, 5 envs) → REVIEW (Opus) relaunched (first run died at 429) |
| fix/lights-truth-wdt-and-clamp (sl) | wt-sl-fix | 1824228 | built (149 tests) → REVIEW (Opus) relaunched |
| fix/gs-packaging-and-resilience (GS A) | wt-gs-fixA | 1f2598d | built (1505 tests) → REVIEW (Opus) relaunched |
| fix/gs-race-day-truth-and-lifecycle (GS B) | wt-gs-fixB | 1f2598d + uncommitted mapperRunner.js edit | IMPLEMENTER (Opus) CONTINUING |
| fix/headless-bringup-and-link (mapper A) | wt-mapper-fixA | b071a30 | built (219 tests, -race) → REVIEW (Opus) relaunched |
| fix/gamepad-hotplug-and-lint-teeth (mapper B) | — | — | NOT STARTED; depends on mapper A merged |

## 4. Failed / review-required
No work lost. Usage-limit stops: four (2026-09-02/03 ×3, 2026-09-03 21:00 killed 11 wave-3 agents; reset 00:00 2026-09-04) — every one recovered from durable state (worktree commits + briefs/reports). Rule: after any 429 wave, inspect each worktree's `git log <old tip>..HEAD` + `git status` before relaunching; continue partial work, never duplicate.

## 5. Owner decisions
A1–A9 (OD-1…OD-15) and A10 (OD-16 phone video (a) WHEP-in-WKWebView + rule amendment, latency [bench-TBD], (b) fallback only if unacceptable; OD-17 dtClampMs 50 ms ratified + R12 widened to the full calib schema; OD-18 R15 build travels as a git bundle, never a push) — full text in `2026-09-02_readiness_program.md` §1. Orchestrator adjudications of builder questions are listed in A10.

## 6. Unresolved blockers (to "assembly-only")
Tier A from the verdict, all in flight: MAP-1/MAP-2/SYN-2 (mapper A built), telemetry source + demo seed (GS B / iPhone fix), NSIS without mediamtx (GS A built), SYN-1 zombie + hotspot wedge (GS B), red CI on three trunks (OD-14: cf/sl/GS/iPhone/mapper branches each add CI teeth; mapper release job must be dispatched once after mapper A lands). Windows behaviour is unproven until the WS3 VM session (owner installs VMware Fusion + Windows 11 ARM; pwsh 7 required on the guest). Hardware gates unchanged: A2 NOT-EXECUTED ⇒ Phase B BLOCKED; BT1; FIRST_ACTIVE NO-GO; nothing flashed/powered.

## 7. Exact next dependency graph
1. sl: fix/lights (review → fix → verify → merge) → docs/instruction-file-invariants (after instr fixer) → re-sync link2 owned copy from cf via `tools/link2_copy_check.sh` after cf fix lands → push; CI green check.
2. cf: fix/sensor-honesty-and-ci (review → fix incl. rebase + owed B4.3/B4.4 rows + D8 save sentence → verify → merge) → docs/r-review-ratifications (verify → merge) → instr branch → push; trigger nothing on hardware.
3. GS: A (review → fix → verify → merge) → B (built on A; review → fix → verify → merge) → instr branch (GS-1 wording) → B4 scripts (fixer → verify → merge) → contract re-mirror after iPhone lands → push; first windows-latest run → record windows_amd64 digest → `--require-pin`.
4. mapper: A (review → fix → verify → guarded merge onto w17-headtrack → push after FORK-NOTICE checks) → dispatch the release workflow once → mapper B (Opus, incl. the `make(chan os.Signal)` vet fix) → review → merge → push. u4-arbiter never.
5. iPhone: fix branch (review → fix → verify → merge) → instr amendment (merge) → feat/phone-live-video (review → fix → verify → merge; latency evidence) → push; CI run observed.
6. workspace: B6 manual (fixer → verify → merge) → B4 runbook (fixer → verify → merge) → CURRENT_STATUS + this file after each wave → push.
7. 3d-codex: DONE for this program (B9 landed 5dddedb); measurement session M-00… is owner residue; production prints wait on fit-check coupons.
8. Close-out: full baseline re-run on every trunk; CI green everywhere (OD-14); dated vision-alignment audit; memory + CURRENT_STATUS; close the push grant.

## 8. Model-routing policy (A8)
Fable 5.1 = orchestrator only (adjudication, synthesis, guarded merges). Opus 5 = difficult implementation + every independent adversarial review. Sonnet 5 = workforce (docs fixers, re-verifies, ratification edits, bounded research). Haiku 4.5 = optional mechanical work only. Every Agent/Workflow call names its model; reviewer ≠ implementer ≠ verifier contexts.
