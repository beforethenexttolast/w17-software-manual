# NEW_SESSION_HANDOFF — W17 OFFLINE READINESS / BENCH PREPARATION (written 2026-09-06 00:30 Kiev; **updated 2026-09-06 ~13:10 after the D-6 grant was executed and CONSUMED** — §0–§2 below are now historical record; current trunks are in `W17_OFFLINE_READINESS.md` §1a and `CURRENT_STATUS.md`)

Boot without chat history. Read in this order: (1) workspace `CLAUDE.md` (safety 1–7, one session per tree); (2) this file; (3) `W17_OFFLINE_READINESS.md`;
(4) `2026-09-05_offline_decision_round_1.md`; (5) `W17_OWNER_ACTIONS.md`, `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`; (6) `bench-gates/INDEX.md` + `G-INDEX.md` +
`MISSING_THRESHOLDS.md`. Everything above is now on workspace **main** (e03f10e, the ff of program/offline-readiness, landed 2026-09-06 under D-6).
Scratchpad of the authoring session (worktrees, briefs, 40+ review/verify reports): `SP = /private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/1eb1e581-426a-4cb0-abab-7295687107d4/scratchpad`
(`SP/briefs/*.md`, `SP/reports/*.md`, `SP/WAVE1_LEDGER.md`). If SP is gone, every deliverable is in the branches below; the reports are only provenance.

## 0. First commands (read-only)
```
for r in . w17-control-fw w17-soundlight-fw w17-ground-station iPhone_rc w17-mapper w17-3d-codex; do git -C /Users/vitaliykhomenko/Documents/projects/$r worktree list; git -C /Users/vitaliykhomenko/Documents/projects/$r status --short | head -3; done
```
Expected AFTER the grant (2026-09-06 13:10): trunks clean at workspace main **e03f10e** · cf **1d17c6b** · sl 7220c08 · GS **809976c** · iPhone 7aaf2cf · mapper w17-headtrack **aa7fb7d** · 3d **8889323** (pre-grant values were f1fc46e · 39a4f3c · 7220c08 · 379cf29 · 7aaf2cf · b859af1 · 5dddedb). Mapper release run 34025673144 green (build-windows-amd64 success; artifact w17-mapper-windows-amd64 17.9 MB uploaded).
Worktrees under SP hold the branches in §1. If a trunk moved, another session landed something: re-read `W17_CURRENT_STATE.md`/`CURRENT_STATUS.md` before anything else.

## 1. Branch state (all reviewed → fixed → independently re-verified; nothing pushed; no trunk touched)
| repo | branch | tip | worktree (SP/) | chain (reports in SP/reports) | content |
|---|---|---|---|---|---|
| workspace | program/offline-readiness | e7b0017 = content tip (one docs-only state-normalization commit sits on top, 2026-09-06; `git rev-parse --short program/offline-readiness` is authoritative) | wt-ws-program | integrates all workspace `offline/*` below | 3 state files, rulings record, bench-gates/ (12 cards, tools, thresholds), VM runbook + scripts/vm, procurement, booklet + packet, manual palette fixes, doc fixes |
| GS | offline/windows-validation-harness | a80236e | wt-gs-winval | A2 → R-A2 → FIX-A2 → V-A2 PASS → FIX-A5 → V-A5 PASS | DryRun/mock layer + 9 fixtures, 05-passthrough, 31-adapter-capability, hot-plug timeline, evidence JSON/RESULT.md, hardware gates advisory by default |
| GS | offline/raceday-timing-logs | 2f2690a | wt-gs-timing | G3 → R-G → FIX-G → V-G PASS | 5 `W17T` structured log lines + stamped WS3 probe log + monotonic `m`; 1693 tests |
| mapper | offline/host-prechecks | 1f20de5 | wt-mapper-host | A4 (dry-run SKIP clean; no production code) | tools/host-precheck/ds4_precheck.sh + dsdump (build tag) |
| 3d-codex | offline/measurement-sitting | 98e27a7 | wt-3d-measure | B1 → R-B → FIX-B → V-B PASS → FIX-B2 → V-B2 PASS | MEASUREMENT_SITTING_RUNBOOK.md, record sheets, generator; delivered to owner |
| 3d-codex | offline/cad-prep | 988cf17 | wt-3d-cadprep | same chain | ingest_measurements.py (26 tests), COUPON_PRINT_PLAN, FIT_PRINT_LADDER, out/C-1.stl |
| control-fw | offline/docfix-gate-citations | 1d17c6b | wt-cf-docfix | DOCFIX-1 → V-DOC 7/7 | 4 citation/wording fixes in docs + project-review |
Workspace sub-branches already merged into program/offline-readiness (do not land separately): offline/vm-runbook fa73dd5, offline/bench-gates-fw 38deaf1,
offline/bench-gates-ground 20c8ca6, offline/procurement 87c01f1, offline/booklet-editorial 63232ae, offline/docfix-sequence-manual 30ce591,
offline/docfix-manual-lights 96a8f7a, offline/gate-card-citations 6ea24c7.

## 2. The ONE-TIME grant (owner D-6, 2026-09-05) — exact scope and landing sequence — **EXECUTED 2026-09-06, CONSUMED** (record: `W17_OFFLINE_READINESS.md` §1a; the FORK-NOTICE §5(a) row for the mapper is aa7fb7d)
Scope = exactly the seven branches in §1 at the tips listed; the workspace branch's content tip is e7b0017 plus one docs-only state-normalization commit
(2026-09-06) that is the "mechanically necessary" tail — treat anything else added later as out of scope. NOT a general push grant.
Rule from the owner: if approved content changes materially before landing, independently verify the changed portion before push; merge-resolution trees must be
independently verified. **Verify-before-push condition: SATISFIED for the workspace branch.** The only post-review edits are the booklet D-5 voice rulings (f03066f, corrected to verbatim Alternative B at e7b0017) and the thresholds §1 ruling table (fa66bbb). V-HANDOFF (Sonnet, 2026-09-06) = **PASS**: boot test passed on every item; thresholds table matches D-4 exactly; the one booklet defect it found (§9 parenthetical from Alternative A) was fixed and proven by string equality against the packet. Persisted report: `_handoff/2026-09-06_V-HANDOFF_boot_test.md` (copy of SP/reports/V-HANDOFF.md). No further post-review edits exist; the state-normalization commit on top is docs-only.
Order (each step: guarded ff/merge in the MAIN checkout only after `git worktree list` + `git branch --show-current` confirm nobody else is in the tree; re-check HEAD right before merging):
1. control-fw: `git -C w17-control-fw merge --ff-only offline/docfix-gate-citations` → push → observe CI (both jobs incl. link2-drift) green.
2. GS: merge offline/windows-validation-harness then offline/raceday-timing-logs (disjoint file sets; run `npm test` on the merged tree — expect ≥1693) → push → observe CI (contract-mirror, test, package-smoke).
3. mapper: `offline/host-prechecks` adds tools/ only, behind a build tag. FORK-NOTICE push-review rule still applies (pkg/headintent|proto|server untouched → the four checks are trivially unchanged; say so in the FORK-NOTICE §5(a) row the repo law requires for owned additions) → push through `.githooks/pre-push` → observe the release workflow run.
4. 3d-codex: merge offline/measurement-sitting then offline/cad-prep (merge-tree clean, disjoint) → `./render.sh --table` 17/0 → push.
5. workspace: `git merge --ff-only program/offline-readiness` (or --no-ff if main moved) → link checker default mode exit 0 → push. Then re-run the link checker with `--workspace-root` at the real workspace: the gate-card citations into nested repos resolve only once steps 1–4 landed.
6. Record every landing in `W17_OFFLINE_READINESS.md` §1/§3 and `CURRENT_STATUS.md` top entry; then the grant is CONSUMED — say so in both files.
Never push `u4-arbiter`. Nothing in this grant flashes, powers, or connects hardware.

## 3. Owner rulings in force (verbatim file: `2026-09-05_offline_decision_round_1.md`)
D-1 hotspot: validate on a real x64 Win11 PC when available AND re-check on the giftee PC at handover; the 5 GHz AP adapter is GIFT-KIT equipment, one unit.
D-2 OP-49: IP2326 ×2 = adopted candidate; full OP-49 evidence still required before any powered charge test; keep the no-power marking inspection.
D-3 BG-06 T1: live-TX gated bench procedure (car unpowered OR RP1 unbound; no bound RX powered in range; attended; explicit owner go); discharges no gate.
D-4: O-1 150/200 ms · O-2 1000 ms headroom · O-3 2000 ms spread · O-4 five runs · O-5 STOP lag ≤ 250 ms (+record value) · O-6 staircase policy ratified, initial amperage must be derived per powered substep or stay BLOCKED · O-7 maxBrightness cap 180 (227 compile ceiling only).
D-5 booklet voice: applied f03066f. D-6: the grant in §2.

## 4. Next autonomous actions (in order; none needs the owner; none is powered)
1. ~~Execute §2 (the grant).~~ DONE 2026-09-06 (§1a of the readiness file). Grant CONSUMED; nothing further may be pushed without a fresh grant.
2. Apply D-4 into the card criteria: G-02 (O-1 target), G-04 (O-2/O-3/O-4/O-5 as accepted, STOP lag ≤ 250 ms + record value), BG-08 (operating cap 180; 227 ceiling note), BG-03 + `bench-gates/tools/first_power_current_limits.md` T11 (staircase policy text; initial value derivation task, see 3). Scoped Sonnet verify, then land under a FRESH grant (this is new content).
3. O-6 derivation (Opus, offline): for BG-03/BG-04's first powered substeps, derive the lowest defensible starting current limit from cited component/rail limits (UBEC 5 A ×2, LED renderer ≤900 mA at cap 227 / recompute at 180, servo stall, ESC BEC, board datasheets). Any substep with no defensible number → BLOCKED with the smallest owner question. Output: a table on BG-03 + T11 row.
4. Apply O-7 = 180 as the shipped `maxBrightness` value? NO — that is a firmware change on a trunk (soundlight `LightRenderer.hpp:152` = 110 today); it needs its own reviewed branch + fresh grant. Record it as a queued cf/sl change; do not touch trunks.
5. VM track when the owner reports disk/Fusion/ISO ready: runbook §1.0 checklist → `scripts/vm/host-vm.sh doctor` → bootstrap → snapshot → stage → suite (hardware gates off) → evidence to `evidence/`.
6. Measurement track when the owner returns the CSV: `w17-3d-codex/11_cad/tools/ingest_measurements.py --dry-run <csv>` → review → `--apply` → render → C-2/C-3 exports per COUPON_PRINT_PLAN → fit ladder.
7. Windows x64 session when the owner provides the PC + FT232RL + DS4: `run-all.ps1 -HardwareExpected -ElrsVidPid 0403:6001`, 31 under Windows PowerShell 5.1, capture `netsh wlan show hostednetwork`; G-03; G-04 Part A only after the owner's explicit go per D-3.
8. Keep `W17_OWNER_ACTIONS.md` current; surface the queue only when something becomes newly actionable.

## 5. Remaining dependency graph
disk (~50 GB) → Fusion → Win11 ARM64 ISO → guest bootstrap → snapshot → VM suite (all steps except hotspot) → VM-verified (never physical).
adapter (BUY, gift kit) + x64 PC → 30-hotspot / 40 hotspot half → and again on the giftee PC at handover (D-1).
DS4 on the Mac → ds4_precheck (macOS evidence) → DS4 + x64 PC → G-03 (Windows hot-plug) → giftee PC re-check.
FT232RL + x64 PC + owner go (D-3) → BG-06 T1 (CRSF frames observed leaving the mapper) and G-04 Part A (link timing).
coupon C-1 → fit_clearance → measurement sitting (Station 0 first) → CSV → ingest → params → C-2..C-4 → tray/cage fit prints → production prints.
shopping (battery, hub, selector, magnets/tyres in transit) + OP-49 evidence (D-2) → A2 no-power checklist (BG-01) → A2 closure (BG-02) → Phase B first power (BG-03, needs O-6 derivation) → D8 (BG-04) → coordinated flash (BG-05) → BT1 (BG-07) → halo (BG-08, cap 180) → phone latency (G-02) → race-day link (G-04). FIRST_ACTIVE (G-01) stays NO-GO.

## 6. Physical gates — all NOT-EXECUTED; each needs the owner's explicit go
BG-01 A2 staged (no power; runnable now except parts-gated rows) · BG-02 A2 closure · BG-03 Phase B first power (BLOCKED on O-6 derivation + A2) · BG-04 D8 · BG-05 coordinated flash ·
BG-06 CRSF on the wire (live-TX gated, D-3) · BG-07 BT1 · BG-08 halo (cap 180) · G-01 FIRST_ACTIVE (NO-GO) · G-02 phone latency (150/200 ms) · G-03 Windows hot-plug (x64 PC + DS4) · G-04 race-day link (x64 PC + FT232RL; D-3).

## 7. Model policy (unchanged)
Fable = Director/adjudication only. Opus = adversarial review, safety-bearing verification, difficult implementation. Sonnet = workforce. Every agent names its model.
Rule proven this program: every owner-executed artifact failed its first adversarial review; defects were found only by executing. Keep review + independent re-verify mandatory.
