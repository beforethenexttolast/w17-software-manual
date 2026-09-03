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
| w17-control-fw | main | 58581ff | yes | 330 native, 5 envs (B1 runbooks 00c7612; plan ratifications 9d3f635; OD-1 instruction files 58581ff) |
| w17-soundlight-fw | main | 1ad8ea5 | yes | 150 native, 2 envs (docs 8b259bf; instruction files bc09875; fix/lights-truth-wdt-and-clamp 1ad8ea5 — **CI GREEN** run 33809791015 (build-and-test + link2-drift); link2 re-copy from cf owed when cf lands) |
| w17-ground-station | main | b632409 | yes | 1525 / 72 files. Orchestrator hotfixes after GS A: 0fd950a (mirror digest normalizes CRLF), 698ebda (Windows-portable tests), 933aff6 (**ROOT CAUSE of boundaries-1: package.json's `build` field shadowed electron-builder.yml — electron-builder logged 'loaded configuration file=package.json' and ignored extraResources/files** → field removed, icon moved into the yml, test pins package.json build-less; windows_amd64 mediamtx digest eb10ff6c… recorded TOFU from run 33810293868 + `--require-pin` in CI), b632409 (pin record shape — 933aff6 had 2 red pin tests; lesson: check the vitest EXIT CODE, never grep-filtered output). CI history: 22ce2e5 RED (CRLF), 0fd950a RED (test portability), 698ebda RED at assert-packaged (empty resources/mediamtx = the shadowed config), 933aff6 RED (pin tests) → **b632409 GREEN (run 33810816391: test, contract-mirror, package-smoke incl. fetch --require-pin, electron-builder --dir, assert-packaged OK for mediamtx.exe + mediamtx.yml + proto, NSIS built + uploaded as w17-ground-station-nsis-unsigned)** — first green windows-latest run ever; boundaries-1 closed with evidence; OD-14 met for GS. Known residual gap: the NSIS installer is built from the asserted --dir output but not separately inspected |
| w17-mapper | w17-headtrack (NOT main) | 6e99d51 | yes (through .githooks/pre-push) | 240 pass ./pkg/... (-race clean); mapper A landed 2026-09-04 (re-verify PASS, reports/a0e0f583f0dc7c3f1.md); one pre-existing flaky test (TestKeepaliveStaysQuietWhileTelemetryFlows, wall-clock) is mapper B's first item; release workflow dispatch deferred until mapper B lands |
| iPhone_rc | main | 85ce486 | yes | 84 (dev_check.sh; resolved simulator destination) — fix/telemetry-honesty-and-ci 1a1ea61 + OD-16 instruction amendment landed 2026-09-04; **CI GREEN** (iOS Validation run 33808159886, Build And Test: success — first green on this repo; OD-14 met for iPhone) |
| w17-3d-codex | main | 5dddedb | yes | render.sh --table (17 rendered, 0 failed) |
| u4-arbiter (mapper) | parked branch | 4e445c9 (S22–S25: OD-17/18 ratified; backup ref backup/u4-arbiter-pre-rebase-20260902 = 93be341) | NEVER | gated + default modes green, inert-build 0/46 symbols, hook exits 1 |

## 2. Landed in the program (all reviewed → fixed → re-verified → guarded ff merge → pushed)
iPhone B5 giftee install docs (61ad68f); mapper B7 release job (21834fe); control-fw B8 plan refresh (7c00668) + B1 readiness runbooks (00c7612);
GS B3 docs refresh (35e5efc); soundlight docs/brief-catches-up (8b259bf); workspace: vision amendments, ownership edit, program packet, checkpoint, owner round 2 + this file, B2 readiness runbooks (e404734).

## 3. Branch ledger (worktrees live under SP; one session per tree)
| branch (repo) | worktree | tip | state |
|---|---|---|---|
| docs/brief-catches-up (sl) | wt-sl-docs | 8b259bf | LANDED on sl main 8b259bf, pushed (2026-09-03) |
| docs/readiness-runbooks (workspace, B2) | wt-ws-runbooks | e404734 | LANDED on workspace main e404734, pushed (re-verify PASS + 2 orchestrator citation fixes) |
| docs/readiness-runbooks (cf, B1) | (worktree removed) | 00c7612 | LANDED on cf main 00c7612, pushed (re-verify PASS + one hash-citation fix) |
| docs/manual-truth-pass (workspace, B6) | (worktree removed) | bc36589 | LANDED on workspace main (re-verify PASS, reports/a3ab6f1c75670213c.md, + 3 orchestrator residual edits), pushed |
| feat/windows-validation-scripts (GS, B4) | wt-gs-winval | afaec4f (28 commits on 698ebda; 1524 tests) | fixed incl. 4 extra blocking bugs found with pwsh (reports/a7e7c6d31cd472035.md) → RE-VERIFY (Sonnet + pwsh) in flight → rebase → merge together with the runbook |
| docs/windows-vm-runbook (workspace, B4) | wt-ws-winval | 6fdc6cc (3 commits on d3b71a1) | fixed (W1/W2 + WORKSPACE_MAP registration) → same RE-VERIFY → merge together with the GS scripts branch (link checker cross-reference) |
| docs/instruction-file-invariants (cf/sl/GS, OD-1) | (worktrees removed) | cf 58581ff / sl bc09875 / GS 9de86ae | LANDED + pushed 2026-09-04 (re-verify PASS ×4) |
| docs/instruction-file-invariants (iPhone, OD-16 + resolved-destination gate) | (worktree removed) | 85ce486 | LANDED after the fix branch, pushed |
| design/placement-and-cage (3d, B9) | (worktree removed) | 165827c | LANDED on 3d main 5dddedb (+ CLAUDE.md folder-map rows), pushed; owner residue = measurement session M-00… |
| u4-arbiter (mapper) | wt-u4 | 4e445c9 | OD-17/18 ratification DONE (S22 gate.go, S23 README, S24 template, S25 FORK-NOTICE rows); parked until R-review + bench; NEVER push |
| docs/r-review-ratifications (cf) | (worktree removed) | 9d3f635 | LANDED on cf main 9d3f635, pushed (cross-checked field-by-field against calib.go by a fresh context) |
| fix/telemetry-honesty-and-ci (iPhone) | wt-iphone-fix (kept until phone-video rebases) | 1a1ea61 | LANDED on iPhone main (re-verify PASS, reports/a78e86ed65eebb2c6.md), pushed; GS contract re-mirror owed (canonical sentence 3e78118) after GS A/B land |
| feat/phone-live-video (iPhone) | wt-iphone-video | 46fc2ff (on main 85ce486; 146 tests; latency 98–136 ms simulator [bench-TBD]) | slices 1–3 built (reports/a55f6d417f7d89750.md) → ADVERSARIAL REVIEW (Opus, REV-phone-video.md) in flight → fix → verify → merge → push; slice 4 (booklet + GS mirror) and slice 5 (bench) outside the branch |
| design/phone-live-video (iPhone) | wt-iphone-video-design | 50f25da | design doc; consumed by the implementer |
| fix/sensor-honesty-and-ci (cf) | wt-cf-fix | 88182e2 (21 commits on 58581ff; 356 tests, 5 envs) | round-1 fixes done (reports/a0247ea4fa971b25f.md) → Opus re-verify FAIL on R1 (owed row B4.4 told the operator to run the motor inside the motor-disconnected Phase-B doc — gate softening) + R2–R6 (reports/ae6f0f9378e7cadb2.md) → ROUND-2 FIXER (Sonnet, FIX-cf-fix2.md) in flight → re-verify → ff merge → soundlight lib/link2 re-copy (Link2Frame.hpp comment + library.json dep) in the same wave → push both → observe cf CI |
| fix/lights-truth-wdt-and-clamp (sl) | (worktree removed) | 1ad8ea5 | LANDED on sl main (re-verify PASS, reports/ac7625a48e9ad971b.md), pushed |
| fix/gs-packaging-and-resilience (GS A) | wt-gs-fixA (kept until GS B rebases) | 22ce2e5 | LANDED on GS main (re-verify PASS, reports/ac3b799d08de39530.md), pushed 2026-09-04 |
| fix/gs-race-day-truth-and-lifecycle (GS B) | wt-gs-fixB | 549b192 (11 commits on 698ebda; 1650 tests / 73 files) | built (reports/a9b4f5add6b3d4a91.md; 5 open questions for the reviewer) → ADVERSARIAL REVIEW (Opus, REV-gsB.md) in flight → fix → verify → rebase onto main → merge (+ noControlPath citation refresh to :125-170) → push |
| fix/headless-bringup-and-link (mapper A) | (worktree removed) | 6e99d51 | LANDED on w17-headtrack, pushed |
| fix/gamepad-hotplug-and-lint-teeth (mapper B) | wt-mapper-fixB (being created) | base 6e99d51 | IMPLEMENTER (Opus) in flight: keepalive-test flake fix first, then MAP-6/9/12/13/14/15/16, lifecycle-concurrency-7, vet chan, CORS origin restriction (FW-mapperB.md) |

## 4. Failed / review-required
No work lost. Usage-limit stops: four (2026-09-02/03 ×3, 2026-09-03 21:00 killed 11 wave-3 agents; reset 00:00 2026-09-04) — every one recovered from durable state (worktree commits + briefs/reports). Rule: after any 429 wave, inspect each worktree's `git log <old tip>..HEAD` + `git status` before relaunching; continue partial work, never duplicate.

## 5. Owner decisions
A1–A9 (OD-1…OD-15) and A10 (OD-16 phone video (a) WHEP-in-WKWebView + rule amendment, latency [bench-TBD], (b) fallback only if unacceptable; OD-17 dtClampMs 50 ms ratified + R12 widened to the full calib schema; OD-18 R15 build travels as a git bundle, never a push) — full text in `2026-09-02_readiness_program.md` §1. Orchestrator adjudications of builder questions are listed in A10.

## 6. Unresolved blockers (to "assembly-only")
Tier A from the verdict: MAP-1/MAP-2 LANDED (mapper 6e99d51; CRSF-on-the-wire proof stays bench); demo seed LANDED (iPhone 85ce486); NSIS without mediamtx CLOSED WITH EVIDENCE (GS b632409, green windows-latest run); SYN-2 link truth + telemetry source + SYN-1 zombie + hotspot wedge BUILT on GS B (549b192, under review); red CI: iPhone GREEN, soundlight GREEN, GS GREEN, control-fw pending its fix branch, mapper pending the release-workflow dispatch after mapper B. Windows behaviour is unproven until the WS3 VM session (owner installs VMware Fusion + Windows 11 ARM; pwsh 7 required on the guest). Hardware gates unchanged: A2 NOT-EXECUTED ⇒ Phase B BLOCKED; BT1; FIRST_ACTIVE NO-GO; nothing flashed/powered.

## 7. Exact next dependency graph
1. sl: DONE except the link2 owned-copy re-sync from cf (same wave as the cf landing; verify with `tools/link2_copy_check.sh --strict --sibling`) → push; CI green check.
2. cf: fix/sensor-honesty-and-ci (review → fix incl. rebase + owed B4.3/B4.4 rows + D8 save sentence → verify → merge) → instr branch → push; trigger nothing on hardware.
3. GS: A DONE (22ce2e5) → B (rebase onto main; review → fix → verify → merge) → instr branch (GS-1 wording) → B4 scripts (fixer → verify → merge) → contract re-mirror after iPhone lands → push; first windows-latest run → record windows_amd64 digest → `--require-pin`.
4. mapper: A DONE (6e99d51) → mapper B (Opus, in flight: flake fix, MAP-6/9/12/13/14/15/16, vet chan, CORS) → review → verify → merge → push → dispatch the release workflow once → observe. u4-arbiter never.
5. iPhone: DONE for the fix branch + instr (85ce486, CI green); feat/phone-live-video (rebase onto main → review → fix → verify → merge → push → observe CI).
6. workspace: B6 manual DONE → B4 runbook (fixer → verify → merge) → CURRENT_STATUS + this file after each wave → push.
7. 3d-codex: DONE for this program (B9 landed 5dddedb); measurement session M-00… is owner residue; production prints wait on fit-check coupons.
8. Close-out: full baseline re-run on every trunk; CI green everywhere (OD-14); dated vision-alignment audit; memory + CURRENT_STATUS; close the push grant.

## 8. Model-routing policy (A8)
Fable 5.1 = orchestrator only (adjudication, synthesis, guarded merges). Opus 5 = difficult implementation + every independent adversarial review. Sonnet 5 = workforce (docs fixers, re-verifies, ratification edits, bounded research). Haiku 4.5 = optional mechanical work only. Every Agent/Workflow call names its model; reviewer ≠ implementer ≠ verifier contexts.
