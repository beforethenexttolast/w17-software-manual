# W17 grand review — RECOVERY CHECKPOINT (2026-09-03, after the second usage-limit stop)

Read-only inventory taken from durable state (journals, worktrees, task outputs), not from the terminal transcript.
Scratchpad root: /private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/9a131be5-75e5-4b91-9d54-0fedf52c1bf8/scratchpad (SP).
Trunks unchanged: workspace main 486cf77 · control-fw 25bf5eb · soundlight 63e8256 · ground-station 3719592 · mapper w17-headtrack 9cb501e · iPhone 862aeb0 · 3d-codex 0386b2f. Nothing merged, nothing pushed, nothing flashed/powered.

## 1. Canonical, immutable review evidence (NEVER rerun)
Five repo review sweeps COMPLETE (v2 topology, 159 agents: 127 Opus / 32 Sonnet, 0 failures; 21 Fable-era results retained via seeds):
- SP/review-seeds/<repo>.v2report.json (Opus synthesis + confirmed/plausible/lows/refuted/coverage/routing) for w17-control-fw, w17-soundlight-fw, w17-ground-station, w17-mapper, iPhone_rc
- SP/review-seeds/<repo>.seed.json / .full.json / .compact.json / .args.json (retained v1 evidence + run args)
- SP/review-seeds/grand.digest.json (175 KB compressed digest fed to the grand review)
- Scripts: w17-repo-review v2 installed over the five session script paths; v1 backup at SP/review-seeds/w17-repo-review.v1.backup.js

## 2. Grand review (wf_1386cd3d-b55) — verified from journal.jsonl (8 entries: 4 started, 3 result, 1 failed)
| Fable agent | journal | status | durable copy |
|---|---|---|---|
| architecture-root-cause | result (agent a3c931ab…) | COMPLETE_AND_PERSISTED | SP/review-seeds/grand.perspectives.json |
| adversarial-challenge | result (agent ac5b1423…) | COMPLETE_AND_PERSISTED | same |
| gift-readiness | result (agent a1735dc1…) | COMPLETE_AND_PERSISTED | same |
| final synthesis (verdict) | started → failed (429) | FAILED_ONLY_DUE_TO_USAGE_LIMIT — never returned | none |
Decision: do NOT resume wf_1386cd3d-b55 (replay could redispatch the three completed Fable calls). Run ONE new bounded workflow `w17-grand-verdict` whose single Fable agent reads grand.perspectives.json + grand.digest.json.

## 3. Sweep-2 builders and reviews (durable git state in SP worktrees)
| Item | Branch / tip / base | Committed work | Uncommitted | Test evidence | Review | Status | Model | Next |
|---|---|---|---|---|---|---|---|---|
| B1 cf runbooks | docs/readiness-runbooks 75d4267 (5 ahead of cf 25bf5eb) | A2 SP3T rows; D8 re-arm+gate banner+boot-mode phase; COORDINATED_FLASH.md; BT1_BENCH_GATE.md; PHASE_B_FIRST_POWER.md | docs/ROADMAP.md (+11/−3, D3 annotation in progress) | none yet | none | STARTED_INTERRUPTED (429) | sonnet | resume from branch: commit ROADMAP, remaining review doc items, link check, `pio test -e native`, report |
| B2 workspace runbooks | docs/readiness-runbooks ccdd918 (8 ahead of ws 31af550) | master sequence; giftee-PC install guide; handover checklist; handset re-arm fix + backlinks; gcs §5 pointer; A2 prompt SP3T rows; link checker | w17-giftee-pc-install-guide.md (+2/−1) | link checker committed; result not reported | none | STARTED_INTERRUPTED (429) | sonnet | resume: commit, run link checker, final sanity, report |
| B3 GS docs refresh | docs/readiness-refresh ae2aa83 (6 ahead of GS 3719592) | README truth pass; SETUP; bench checklist; CODESIGNING; mdns proposal 24→28; GIFTEE_FIRST_LAUNCH.md | none (untracked node_modules symlink, expected) | `npm test` not yet reported | none | STARTED_INTERRUPTED (429) | sonnet | resume: verify remaining docs-truth items, `npm test`, link check, report |
| B4 Windows VM validation | GS feat/windows-validation-scripts d412d12 (8 ahead); workspace worktree wt-ws-winval NOT created | lib helpers; hotspot + mDNS probes reusing app code; scripts 00,10,20,30,40 | none | pwsh check not reported | none | STARTED_INTERRUPTED (429) | sonnet | resume: scripts 50, 60, run-all, README; then the workspace runbook (new worktree); `npm test`; report |
| B5 iPhone giftee install | docs/giftee-install adddd53 (10 ahead of 862aeb0) | 9 doc commits + gitignore | none (clean) | dev_check.sh 74/74 (builder-run) | review agent 429'd at start | COMPLETE_BUT_REVIEW_PENDING | sonnet (built) | independent review (opus) |
| B6 manual truth pass | docs/manual-truth-pass 6706300 (2 ahead of ws 31af550) | ch09 link2 v2 17-byte; ch07 voice selector/showcase/test count | ch05 (+6) and ch10 (+39/−9) partial edits | none | none | STARTED_INTERRUPTED (429) | sonnet | resume: commit ch05/ch10, ch11/13 env tables, stub 21, booklet surgical edits, sweep + tracker, report |
| B7 mapper W17 release job | ci/w17-release 2ff41aa (3 ahead of 9cb501e) | workflow yaml; FORK-NOTICE row; configs/README section | none (clean) | go test 180 + -race clean, yaml parsed, hook greps clean (builder-run) | review agent 429'd at start | COMPLETE_BUT_REVIEW_PENDING | sonnet (built) | independent review (opus) |
| B8 u4 desk work | u4-arbiter 4c11c10 (6 ahead of 9cb501e; backup/u4-arbiter-pre-rebase-20260902 = 93be341 intact) | S5 reconciliation (hat decode fold, layout note); S6 evidence re-run | docs/u4-evidence/calibration_record_TEMPLATE.md (283 lines, untracked) | matrix both modes per S6 commit (verify in resume) | none | STARTED_INTERRUPTED (429) | opus | resume: commit template (STEP 6), README section (7), hook greps (8), control-fw unlock-plan branch (9), report |
| B9 mechanical study + CAD | design/placement-and-cage 9eff64b (1 ahead of 0386b2f) | AA_electronics_placement_study.md (692 lines) | study corrections (+30/−14; the §5.4 rib/PDB clash fix) | n/a | none | STARTED_INTERRUPTED (429) | opus | resume: commit corrections, 11_cad/ OpenSCAD + render.sh + previews, measurement session prompt, GENERAL_PLAN/PRINT_LOG notes, report |
| Cross-repo probe | n/a (read-only) | none durable (no cross-repo-probe.md; 107 tool calls, 13 short text notes salvaged) | — | — | — | FAILED_ONLY_DUE_TO_USAGE_LIMIT | sonnet | rerun (sonnet) from PROBE.md |
| Review of B5 | — | — | — | — | — | FAILED_ONLY_DUE_TO_USAGE_LIMIT (at start) | opus | rerun (opus) |
| Review of B7 | — | — | — | — | — | FAILED_ONLY_DUE_TO_USAGE_LIMIT (at start) | opus | rerun (opus) |
No builder FAILED_FOR_REAL. Every interrupted agent's last transcript line is the 429 message.

## 4. Housekeeping done at checkpoint time
- Four detached scratch worktrees left by cut-off verifier agents (mapper wt-verify-boundaries-2-repro with an untracked repro test; iPhone wt-verify-boundaries-3/-4 clean; soundlight wt-verify-safety-3 with a probe .cpp) — artifacts copied to SP/review-seeds/salvage/verify-artifacts/, worktrees removed and pruned. Verdicts for those findings are already in the seeds/reports.
- Salvaged assistant notes of every interrupted agent: SP/review-seeds/salvage/<name>.assistant_text.md.
- iPhone main checkout: only the pre-existing untracked scripts/__pycache__/ (gitignored on the B5 branch).

## 5. Replay-safety rule applied
No `resumeFromRunId` on any workflow. All continuation = new bounded work seeded from files above.
