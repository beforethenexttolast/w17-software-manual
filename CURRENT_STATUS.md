# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes**,
with a single carve-out: physical hardware *arrival / on-hand* status lives in
`HARDWARE_INVENTORY.md` (the parts delivery log, mapped to BOM v2). That file carries no
commit hashes and no gate / software / execution state, so this file stays the sole
workspace-level source for all of those and for project execution status.
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: **2026-08-17 (post-reset execution — five waves merged; the first installer
artifact exists)** — The owner lifted the hold ("Reset is here") and execution ran per packet
§7½/§6. **Merged to mains, each behind an adversarial review** (review → fix → independent
re-verify wherever findings warranted): **soundlight** main = `1c19260` (wave-3 board-2
features; MERGE_CLEAN + an independent 5.2M-check priority sweep). **GS** main advanced
`92cd894 → abaddbd → 7de119a → ca1cb86 → 2c56898`: the giftee trio (low-battery banner with
two review fixes pre-merge, plain-language GRID hints, NSIS CI job), the `--publish never` CI
fix, **video profiles** (DRIVE proven byte-identical at the real seams; two minor review
fixes incl. the split-brain-on-rejected-apply), and **race-day one-action orchestration** —
its review found **2 blockers** (a spawn-failure wedge that lied "running" unrecoverably, and
full-env inheritance that would bind the mapper's log-only 5602 receiver via
`W17_HEADTRACK_INGEST`, bypassing the argv whitelist) — both **fixed and independently
re-verified** (live env-scrub probe; an evasion check proving the behavioral pin catches
class rebuilds that textual bans miss); preload pin deliberately 24→28; GS suite
**1435/1435 (67 files)**. **Workspace** main = `9654d02`: the manual wave (glovebox booklet
as ch14 owner-unreviewed, mapper teaching ch15, rebuild stubs 16–22, STALENESS report — 21
files, 38 claims) and the dated Codex handoff `_handoff/2026-08-17_iphone_side_sync.md`
(mDNS TXT confirm-ask, low-battery parity suggestion, race-day autoBridge semantics —
**owner ferries it to Codex**). **Control-fw** main = `9f00f2e` (MCU line corrected to the
MH-ET decision; staleness find S28). **The §7½ GS push exception is discharged:** run 1
failed on electron-builder's CI auto-publish (fixed with `--publish never`), run 2
**GREEN end-to-end on windows-latest** — suite, boot smoke on the deployment OS, `--dir`,
NSIS build, and the uploaded artifact **`w17-ground-station-nsis-unsigned`
(80,206,698 bytes) — the project's first installable giftee deliverable** (audit defect 10
closed). Further pushes are owner-call again. The macOS smoke saga stands diagnosed (prior
entry): machine-level npm `allow-scripts` policy, not a repo defect. **Awaiting the owner's
personal review** (split-by-risk): control-fw `feat/gimbal-decay-center`, mapper
`w17-audit-wave1`, and the new **link2 v2 pair** — control-fw `feat/link2-v2-voice-volume`
(16-byte frame: version byte, soundProfile with V10 fallback, volume 0–100 default 80;
golden frame pinned in both repos; NVS `sound.*` + console keys; 229→239 native) +
soundlight `feat/link2-v2-consume` (codec re-synced verbatim, drift check exit 0 across
worktrees; wire-selected voice; integer volume at the final gain stage, 0 = true silence,
100 = bit-transparent; failsafe-over-volume proven; 107→118 native) — merge as one unit,
both boards flash together at adoption; the three-way settings-blob-v2 reconciliation
(decay + BT + this) is documented at the constant. U4 stays R-review-gated; BT awaits the
design read (11 OWNER-PENDING tags). **Orchestrator authority note, flagged for owner ack:**
the 2026-08-16 split-by-risk merge rule was extended by the same principle to branches
created after the answers — GS/docs → adversarial review + orchestrator merge; firmware →
owner queue. In flight: showcase-mode design draft, GCS-box + backup-handset docs, manual
wave 2. Giftee-UX note queued: link2-v2 volume/voice are tuning-console-settable only today —
a giftee-friendly setter is an open decision. **No hardware anywhere; nothing flashed or
powered; A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**
Prior pass, **2026-08-17 (conditional waves land: BT + U4 both complete)** — **BT show-off
prototype COMPLETE** on `w17-control-fw` branch **`proto/bt-showoff-flagged`** (5 commits, tip
`138a674`, off `94b3615`): the design doc now lives at its canonical home
`docs/bt_showoff_design.md` (on the branch); pure-logic `lib/btpad`
(PadFrame/IPadSource/PadDecoder → the existing `channels::Controls`, PadLinkMonitor,
BootModeResolver); Settings blob v1→v2 `btpad.*` + console keys (a merge-time v2
reconciliation with `feat/gimbal-decay-center`'s own v2 is expected and documented); Bluepad32
HAL + quarantined `esp32dev_btshowoff` env — **pinned 3.10.2** (the design's 3.10.3 has no
published core artifact; recorded deviation) and it **builds** (flash 740 KB of the 3 MB
huge_app slot, real BT stack linked). Native **229→267/267**;
`esp32dev`/`esp32dev_tuning`/`esp32dev_sim` all build; **ELF evidence: 0 BT symbols in
delivery/sim/tuning** (btshowoff 216 as positive control) — the check is now a D8 Phase 11a
runbook step. All **11 `OWNER-PENDING(BT-n)` decision tags** shipped (51 occurrences); link2
bit-7 stayed DOC-ONLY; the CRSF-path guarantee is structural (btpad not linked in default
builds; the `controlTick` extraction changes default-build code layout, behavior unchanged —
proven by unchanged native suites + green builds). **U4 arbiter COMPLETE** (interrupted by the
session usage limit mid-slice-3, resumed on the owner's "try again", finished same day):
branch **`u4-arbiter` @ `93be341`**, 4 slices — `aee2450` pure core (gate files, fail-closed
calibration, shaping math) / `a032947` state machine + controls seam + tick pipeline /
`48994e7` send-loop seam + gated cmd wiring + Group A proofs + identity trio + race pair /
`93be341` matrix closure + R-review packet. 47 files, **+5375/−0** vs base `432a809`;
existing-file touches limited to the single seam (+7 in `pkg/link/send.go` before
`crsf.PackChannels`), an embedded slot (+2 `controller.go`), a hoist in `main.go`, and a
branch-only FORK-NOTICE §5(a) section. **Byte-untouched, verified by empty diff:**
go.mod/go.sum/go.work, `pkg/proto` (enum still ends `ACTIVE_LOG_ONLY = 8`), `pkg/headintent`
incl. the dead-end test, webapp, `.githooks`. Both build modes green at every slice commit
(default AND `-tags w17_first_active`), `-race` green; **51 branch-new tests**; all 10
identity hex dumps share **one SHA-256** (`docs/u4-evidence/pack_dumps.sha256`); nm evidence
committed (default binary **zero** headarbiter symbols, gated 44). Runtime gate =
`W17_FIRST_ACTIVE_ARM`; 9 recorded deviations in `docs/u4-branch-README.md` (incl. two
signed-calibration schema fields for blend geometry — R12 signs them; safe ranges must
contain 992). The tip is **unpushable by hook construction** (20+ files trip pre-push checks
1/2/4). **FIRST_ACTIVE overall stays NO-GO/BLOCKED — merge, push, and activation remain
gated on R1–R16 + bench evidence**; the bench-residual list is committed verbatim in the
branch README. Scratchpad
drafts rescued to `_handoff/` as dated non-canonical snapshots naming their canonical homes
(BT design, U4 blueprint, glovebox booklet). **The owner announced the reset 2026-08-17 —
hold lifted, execution resumed per packet §7½/§6.** Post-reset, same day: soundlight
`feat/audit-wave3-board2` **MERGED** (main = `1c19260`) on a MERGE_CLEAN adversarial review
(fresh 107/107 + an independent 5.2M-check priority sweep; worktree and branch removed); GS
`feat/audit-wave2a-giftee` reviewed (3 minor findings — the two real ones, a critical→ok
ratchet skip and boolean thresholds silently normalizing to 1 V, **fixed pre-merge in
`abaddbd`**, suite 1257/1257; the third is a stale test count in an old commit message,
recorded not rewritten), **MERGED** (main = `abaddbd`) and **PUSHED to origin under the §7½
GS-only push exception** (`92cd894..abaddbd`) — Windows CI incl. the first NSIS installer
artifact is running; result to be recorded. The macOS `smoke:electron` failures are
diagnosed as a **machine-level npm `allow-scripts` policy** killing electron's postinstall
mid-extraction (partial, signature-broken bundles macOS then SIGKILLs; plus an unidentified
`~/Documents` app-bundle reaper) — NOT a repo defect; Windows CI is the canonical boot
proof. Four builders still in flight (link2-v2 voice+volume, race-day orchestration, video
profiles, manual wave 1). Review packet updated in place (§2/§4/§5/§7½). No hardware
anywhere; A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
Prior pass, **2026-08-16 (vision lock + orchestration pass)** — **The product vision is
LOCKED and canonical** in the new `W17_PRODUCT_VISION.md` (registered in `WORKSPACE_MAP.md`):
18 owner decisions, the v1.0 done bar (items 1–8, incl. active head tracking, functional DRS,
and giftee-operability — the car is a **gift for a non-hobbyist**, "user friendly af"), the
operator model, and the gift kit (giftee's own Windows PC + installer; one-cable 3D-printed
GCS box). Same-day owner policy amendments: **U4 arbiter branch-only implementation approved**
(both FIRST_ACTIVE flags default-off, constants fail-closed, branch never merged/pushed before
R1–R16 pass) and **BT show-off mode** rescoped to basic close-range no-PC driving with design +
default-off flagged branch prototype approved (design draft + U4 blueprint sit in the session
scratchpad pending owner review). **An 18-agent vision audit ran the same day** — full report:
`2026-08-16_vision_audit_report.md` (dated snapshot). Verdict: **all 7 safety boundaries HOLD,
zero drift**; every runnable suite green — control-fw native **229/229** + both builds (at
`3f4f9b7`), soundlight **94/94** + both builds (`5919685`), ground station **1185/1185** +
proto:check (`92cd894`; `smoke:electron` 0/4 is an **agent-shell environment block**, needs one
interactive re-run, not a repo defect), mapper build/vet/test/race green (`432a809`,
`w17-headtrack`). **6 defects CONFIRMED (all medium): 4 in `w17-mapper`** (RESIDUAL A
switch-channel latch on dropout; RESIDUAL C droppable removal alert / no eval heartbeat;
default endpoints 0/1984 cannot arm; `InputRead._Eval` recursion crash) **and 2 in this file +
`WORKSPACE_MAP.md` (push-state truth — fixed in this pass)**; 10 low findings live in the
report. **Push reconciliation (the defect-5 correction):** the owner has pushed everything
previously outstanding — control-fw `main` = `3f4f9b7` **PUSHED, level** (F17/F18 closure
merged; `docs/a2-revision-pass` and `docs/f17-f18-closure` deleted), mapper `w17-headtrack` =
`432a809` **PUSHED, level**, `w17-3d-codex` level, workspace `origin/main` = `ade337e` (only
this pass's own commits are ahead). The "ahead 31 UNPUSHED" / "three pushes remain
outstanding" statements in the entries below are as-of 2026-08-04 — **discharged**. Untracked
`AGENTS.md` files (mtime 2026-08-11) sit in the workspace root, control-fw, soundlight and GS —
not created by any Claude pass; owner commit-or-remove decision queued. **Orchestration pass COMPLETE (same
day): all five workers landed green.** Consolidated review packet:
`2026-08-16_orchestration_review_packet.md` (root). Landed — **control-fw**:
`docs/comment-drift-fixes` MERGED, `main` = **`94b3615`** (defects 7/8 + the unlock-plan
amendment propagation; branch deleted after clean ff), plus branch **`feat/gimbal-decay-center`**
(tip `acce76e`: decision-11 decay-to-center, Settings blob v1→v2 with real migration tests,
native 229→**253**, both builds green, delivery ELF still console-free; supersedes the
2026-07-15 "#3/U8 hold-last stands" record below on the stick path — the driving-readiness
re-review stays OWED). **soundlight**: branch **`feat/audit-wave3-board2`** (ignition halo
animation, green DRS wingtip tell, NeverConnected 5 s grace → hazard, named V10/V6 synth
profiles with V10 default and no unilateral selector, 94→**107**, `lib/link2` + protocol doc
byte-untouched). **GS**: branch **`feat/audit-wave2a-giftee`** (low-battery banner with ⚙
thresholds 7.0/6.6 V via the a04b07c settings pattern, plain-language GRID hints, unsigned NSIS
installer in CI — the CI run itself is pending the next push, 1185→**1255**, preload surface
unchanged at 24 keys). **mapper**: branch **`w17-audit-wave1`** off `w17-headtrack` (all four
confirmed defects fixed — read-cycle load guard, subscriber-independent 25 ms eval heartbeat,
per-direction hat decode, FORK-NOTICE R16 — plus the committed `configs/w17-ds4.json` W17
profile + plausibility lint, 137→**175** tests, proto/headintent/pre-push-hook byte-untouched,
SHARE/OPTIONS/D-pad test-pinned unbound for the Alt-C head-tracking affordances; the committed
profile supersedes the old hand-build stance per the gift-kit decision, owner ack pending).
Drafts in the session scratchpad for owner review: BT show-off design (11 decisions), U4
arbiter blueprint, glovebox booklet (26 bench-TBDs + 3 questions). **Feature branches are NOT
merged — owner review first, per the fixes→main / features→branches policy. Nothing pushed
anywhere.** Owner-decision queue for return (full list in the packet): showcase-mode gating
sentence (decision 2 vs done bar), sound-profile selection mechanism (+ the volume-control gap
the booklet surfaced), AGENTS.md files commit-or-remove, the BT design's 11 decisions, booklet
name/contact + iPhone-section questions, W17-profile stance ack + its two machine-specific
placeholders (pad GUID, COM port — Windows bench), one interactive `smoke:electron` run, and
the NSIS proof run on next push.
**Documents and branches only — no hardware; nothing built, powered, flashed, or connected;
nothing pushed. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**
Prior pass, **2026-08-04 (A2 third closure pass — F17/F18)** — **F17 and F18 are CLOSED;
F19 and F20 recorded.** Branched off `main` in both repos (`docs/f17-f18-closure`; control-fw's
own tree was still checked out on the merged-and-stale `docs/a2-revision-pass`, so this pass
worked in its own worktree per the concurrency rule). **The premise this pass was commissioned
on was wrong, and finding that out is most of its content:** F17's and F18's document edits were
**already applied** — by the F15/F16 pass, in the same edit that recorded them, across the
checklist, plan §A2.5 and the PDB guide (which *does* mention PD1, in §3's "what lives where"
and §5 step 4). What was missing was the register's **closure-table rows**; the register's
finding bodies said "Fix applied", the checklist said "closed here", and only
`CURRENT_STATUS.md` and commit `92f3b0d`'s subject said "recorded, not quietly fixed" — which
reads as *not fixed*. Every prescribed edit was verified line by line against the artifacts,
all present; the rows are now written, with the walk that goes with them. **F19** records that
closure-record defect (the register's own recurring class — a document asserting a state the
artifacts no longer match — this time about the register's bookkeeping, where nothing
downstream could catch it) and adopts the rule that **a finding is closed when it has a
closure-table row**. **F20** is new and **open, recorded not fixed** per the standing
instruction: checklist row S1r's *membership* covers the five actuator signals only, and
**GPIO34 ↔ GPIO35 is measured by no row in the document** — a bridge there passes D1, H1, C10,
C11 and (in beeper mode) S2r, i.e. every check that looks. Severity below F1–F4 — both pins are
input-only, so the cost is corrupted battery telemetry and wheel speed, not a fire or a dead
board — and partially mitigated by §2's every-joint beeper sweep, which is an instruction, not
an auditable §11 row. S1r and the guide's soldering bullet now carry scope statements saying
so; the fix (extend the matrix to 13/14/18/19/23/34/35) is deliberately left for a pass that
can walk the enlarged set, because enlarging a set §3 rule 2 quantifies over is precisely what
produced F13.1, F15 and F17. **Both F12 bench measurements re-checked and still OWED** — the
socket-stack caliper and the MH-ET adjacency list, neither promoted anywhere in either repo;
**the caliper-first precondition to SF's first socket joint is unchanged by this pass**, and
F17 in fact leans on it, since the hard-wired fallback is the variant its exception exists for.
**Documents only — nothing built, powered, flashed, or connected; nothing pushed. A2 stays
NOT-EXECUTED, Phase B stays BLOCKED.**
Prior pass, **2026-08-04 (consolidation pass)** — **five branches across two repos merged to
their `main`s; nothing pushed.** Four sessions had left work split across branches with both
`main`s behind, which is how sessions kept building on stale context. `w17-control-fw`
`dd9a445` → **`d295f70`**, **ahead 8 of `origin/main` (`d102e2f`), UNPUSHED**: absorbed
`docs/a2-revision-pass` (`f48560c` checklist revision, `0caf4e4` closure table, `92f3b0d`
F15/F16 + S0→SF) and `docs/holdlast-premise-correction` (`d295f70`). Workspace `9f1883f` →
**`1b54767`**, **ahead 31 of `origin/main`, UNPUSHED**: absorbed `docs/cb2-gimbal-explainer`
(which already contained `docs/mapper-config-entry` as an ancestor), the hand-entry record,
`docs/a2-revision-pass` rebased on top, and the two loose root prompts. Every merge was
fast-forward or rebase — **history is linear in both repos, no merge commits.** Branches were
deleted only after verifying containment in `main`; `docs/a2-revision-pass` survives in
**both** repos solely because it is checked out in another session's working tree. The
isolated `cfw-holdlast` worktree is removed. **The `§2.3.11.1` coupling is discharged in this
same pass** — the unlock plan's stale "hold-last channel array" premise is now gone from
`w17-control-fw` `main` (verified by grep at `d295f70`: 0 hits), so the 2026-07-30 entry below
no longer repeats it either. **Records moved and reconciled only — no finding, decision, or
gate was resolved. No hardware; nothing built, powered, flashed, connected, or pushed. A2
stays NOT-EXECUTED, Phase B stays BLOCKED. Three pushes remain outstanding and are the owner's
call; the `w17-mapper` one is additionally governed by the push-review rule in
`FORK-NOTICE.md`.**
Prior pass, **2026-08-04 (A2 revision pass, + the later F15/F16 closure pass)** — **the
revision the 2026-08-03 adversarial review made owed is DONE. ⤴ Superseded in part by the
consolidation pass above: these branches have now MERGED, so the "pending owner review/merge"
and "A2 becomes executable only when they merge" wording below is history, not current state.
A2 stays NOT-EXECUTED and Phase B stays BLOCKED regardless — merging a checklist revision does
not open a gate.** All 14 findings
addressed. `w17-control-fw` branch `docs/a2-revision-pass` (off `main` = `dd9a445` — main
moved mid-pass: a concurrent session merged `docs/sim-first-run` and added `dd9a445`): the
checklist is rebuilt — **SF** (PDB frame) opens the sequence and hosts the pre-S6 rail
isolation rows (F8/F2); **S7** is now the whole-harness composite gate (grounds + the
post-S6 batt+→GND / rail→GND screens F1/F2, the mated master-switch pigtail rows incl. the
owner-made XT60 tail joint, the ESC 12 AWG power-feed rows F13.6); **S8 is split S8a/S8b** —
S8a runs at the cut, before insulation, with E0 falsifying the cut itself and E6 covering
red→GND, S8b probes the header +5 position from the accessible side (F4); S7's reference is
harness-side (PDB input XT60 − pin — F5, no battery involved); **§13 now carries a
stop→generating-row map** (every hard stop reachable from a measurement — F1/F3); **§3 rule
4** makes every pre-S6 row single-shot by stated rule (F14); plan §11's A2 section remapped
onto the S-gates (F13.5). Workspace branch `docs/a2-revision-pass`: the PDB guide's §5 build
order now **is** the S-gate order (divider before UBECs — F8), the charger is off the PDB
diagram, pack-side + deferred (owner decisions F9a/F9b), Hall pull-up board-end (F11), the
stale `(opt GPIO26←17)` link2 conductor struck (F13.4), and this file's Hardware-gates
section updated (incl. its own stale battery lines — the F5 class lived here too). **Two new
register entries found during the revision and recorded, not quietly fixed: F15** (F7's own
fix would false-FAIL §3 rule 2 when the pull-downs are fitted) **and F16** (C1's fit moment
was sequenced by neither doc and the F2/F8 rows made it load-bearing) — both the recurring
asserted-over-unchecked-set class. **NOT closed, owed to the bench before SF's first joint:
F12's two measurement halves** — the MH-ET adjacency re-derivation and the socket-height
caliper vs the ZK "S0" ≥ 9.82 mm clearance (the socketing decision stays conditional on it).
**Closure pass, same day, same branches: F15 and F16 are CLOSED, and closing them generated
two more. ⤴ Corrected 2026-08-04 (third closure pass): the wording that stood here — "recorded,
not quietly fixed" — meant *recorded in the register rather than silently patched*, and it read
as *recorded instead of fixed*. F17's and F18's fixes were applied by this same pass, in both
repos, in the same edit that recorded them; what was missing was their closure-table rows. That
gap is now `F19`, and the third pass supplies the rows. F17:** F15's own exceptions list omits the 13↔14 pair,
which reads ≈2× the fitted pull-down through the star node — a resistance-mode false FAIL at
S1r reported as "ESC and steering signals bridged"; the list is now closed-by-construction,
with a standing instruction to extend it whenever a deliberate resistance is added. **F18:**
PD1's pull-downs had no stated location and no fit moment (F16's defect one row over) — now
harness side at the ESP32 #1 socket positions, fitted at S4, with **not populated** recorded
as the expected A2-time state since R04's evidence is the Phase-B B1.4 scope. Also: photo
item 14 (C1's stripe at S6 — no no-power reading distinguishes a reversed 1000 µF), and the
**`S0` name collision settled by renaming the gate to `SF`** rather than annotating it —
reference sweep first (clearance: 7 workspace files incl. a rendered diagram and three
Codex-handoff docs already sent; gate: five files, all unmerged and unpublished), so the gate
was the cheap rename. `S0` now names **only** the ZK cassette clearance. The register's F8/F2/
F12 *finding bodies* keep the original wording as written history; every pointer says SF.
Precedent this sets against R16's annotate-in-place: **rename before publication, annotate
after.** **Both F12 bench measurements re-checked this pass and confirmed still OWED — neither
was promoted anywhere in either repo.** control-fw branch tip after the closure pass:
**`92f3b0d`**, UNPUSHED.
The four 2026-08-03 owner decisions now live under **Hardware gates**, discharging review
doc 14's "move on merge" note (the `docs/a2-adversarial-review` branches merged to both
mains). **No hardware; nothing built, powered, flashed, or connected; nothing pushed.** ⚠
Merge note **— DISCHARGED by the consolidation pass above, kept because the prediction was
right.** It read: the unmerged mapper branch (`docs/mapper-config-entry`) also carries
2026-08-04 entries in this file's header, and whichever branch merged second would stack its
entry above or below the other's, the overlap being this header block only. That is exactly
what happened — one conflict, this block, both edits append-shaped. Resolved by keeping both
entries ordered newest-first by commit time (`23ff346` 01:27 above `16dad6d` 00:53), losing
neither.
Prior pass, **2026-08-04 (hook pass)** — **the 2026-07-30 owed hook item is DISCHARGED.**
`w17-mapper` `9ba6e06` → **`432a809`**, `ahead 10`, UNPUSHED. The gap was **proven before being
fixed**: `const firstActive = false` in a throwaway Go file exited the pre-push hook **0**, on the
same harness that refuses the other three injections — so arbiter code gated that way would have
reached the **public** `origin`. Owner chose **widen + document**: a 4th check,
case-insensitive `first_?active`, over the **same code globs** (scope deliberately not widened to
prose — measured false-positive surface in scope at `9ba6e06`: **zero**). The limit it does **not**
close is now written into both the hook header and `FORK-NOTICE.md`: the hook matches **names, not
the class** of compile-time gates, so `const enableShaping = false` still passes and no grep closes
that. Full 6-case matrix re-run and recorded in the hook header. **Docs/hook only — no Go changed,
no arbiter, proto still ends at `ACTIVE_LOG_ONLY = 8`.** See the 2026-08-04 (hook pass) entry under
**VR-FPV batch status**.
Prior pass, 2026-08-04 — **code pass: the last two open mapper failsafe findings are CLOSED.**
`w17-mapper` `f81ec63` → **`9ba6e06`** (`c60843e` fix + `9ba6e06` fork-notice), then `ahead 9`, UNPUSHED.
**D-partial** — a subtree can lose a channel while its holder still reports healthy
(`EvalOperation`, `and`/`or` and `EvalRelational` all ignore a nan operand), so the neutral is now
resolved **per owner** from a walk that arms each channel node before evaluation, rather than read
back from the mutable `IsNaN` the reviewer's interim patch used. **D-3** — the depth bound goes
32 → 256 **and** truncation is now fail-safe: an incomplete owner set suppresses that port's frames
instead of holding the last value; the bound's false "`read`-cycle backstop" comment is corrected and
`TestReadCycleTerminates` renamed and re-scoped, since it never called `Eval`. **Closed for the shapes
named in the dated entry — "closed for X", not "closed".** **`InputRead._Eval`'s unguarded recursion
stays OPEN**, recorded as its own tracked item: a `read` cycle kills the process by stack overflow, it
is pre-existing upstream at `2b8031a`, and it was deliberately kept out of this commit. RESIDUALS A
and C remain open. Also this pass: the `CURRENT_STATUS.md` record had **split across two branches**
and was merged back onto `main` (owner-approved, conflict-free), and the `FORK-NOTICE.md` §5(a)
table's date ordering was fixed. **No hardware; nothing flashed or powered; nothing pushed. A2 stays
NOT-EXECUTED, Phase B stays BLOCKED.** See the 2026-08-04 entry under **VR-FPV batch status**.
Prior pass, 2026-08-03 (later) — an **adversarial review of the A2 staged checklist**
(documents only, run deliberately before the first solder joint; precedent: the 2026-07-30
FIRST_ACTIVE pass that produced I10/R15). **14 findings — 13 CONFIRMED, 1 PLAUSIBLE; verdict:
A2 must NOT be executed as written, a revision pass is owed first.** Headline defects: §13 hard
stops 1 and 4 have **no generating measurement** in the staged flow (post-S6 nothing ever
measures batt+→GND, rail↔rail, rails↔batt+, or signals↔batt+ — the restructure invalidated the
old whole-harness screens without issuing staged replacements); S8's E1–E3 are **unexecutable as
sequenced** (the red end is heat-shrunk before S8 arrives) and **unfalsifiable as built** (the
connector spec's +5-pin removal makes them pass whether or not the cut was made), and ESC
red→GND is measured nowhere; S7's "battery −" reference **does not exist on hand** (no
XT60-terminated pack; producing one violates the golden rule); A2's gate order **contradicts the
PDB guide §5 build order** (UBECs step 3 vs S6). Full list + minimal fixes:
`w17-control-fw/project-review/14_a2_staged_gates_adversarial_review.md` (branch
`docs/a2-adversarial-review` in both repos — **merged to both `main`s since; the "pending owner
review/merge" this line carried contradicted the header's own "merged to both mains" and is
corrected here**). **No gate moved: A2
stays NOT-EXECUTED, Phase B stays BLOCKED — a review cannot open a gate.** Prior pass, earlier
same day: one **verification** pass over the mapper hold-last defect, no code
and no hardware state change: the 2026-07-30 line calling it "not yet investigated or fixed" was
**stale** and is corrected; the defect was fixed the same day at `w17-mapper` `2dc7c5a` and is now
**verified closed against source** (both 2026-07-30 residuals traced and answered, tests proven to
bite under three injections), with **three residuals of the fix — A, B, C — left explicitly open**;
the `w17-mapper` checkpoint row is corrected `0e11d6b` → **`5a28106`**. See the 2026-08-03 entry
under **VR-FPV batch status**. Nothing committed in `w17-mapper`. Prior pass, 2026-07-30 — two
**gate-definition** changes plus one investigation entry, no
code and no hardware state change in that pass:
(1) **A2 restructured into staged build gates** and its "why not executed" corrected (nothing is
soldered), plus two A2 decisions closed and A2 closure made a two-part gate — see **Hardware gates**;
(2) **FIRST_ACTIVE gained I10 / R15 / an input-provenance rule** after an adversarial review found
gamepad-device-loss uncovered, and a **related pre-existing throttle-freeze defect** on the stick path
recorded as separately tracked (**that defect is now fixed and verified — see the 2026-08-03 entry**);
(3) **mapper channel-node config findings** — no persisted mapper config exists on this Mac, and the
default channel endpoints (0 / 1984) fall outside the firmware plausibility band from `91f830f`, so
**with defaults the car cannot arm**; investigation only, nothing committed in `w17-mapper` — see the
newest 2026-07-30 entry under **VR-FPV batch status**. No checkpoint
hash moved; target repos are `w17-control-fw` docs plus this file. **Also 2026-07-30 (separate,
later): a hardware arrival entry** — the master-switch pigtail set closed the last §E electrical
lines, and a **wrong-size 5200 mAh battery** was received and classed **bench-only**; no gate moved,
see the dated entry. Prior context: the 2026-07-29
hardware **arrival** entry below changed no gate or software state, and `HARDWARE_INVENTORY.md` remains
the carve-out owner for arrival detail. The 2026-07-27 bookkeeping **delta** below is otherwise current
— see that entry and the corrected Checkpoints table. The 2026-07-25 sync ran before three sessions
finished, so the tables were stale again; that pass updated them and did not re-do still-correct work. The dated entries
that follow are preserved as an as-of log — **read the Checkpoints table and the newest entry for
current truth**, and treat any bare present-tense claim inside an older dated entry as as-of that date.

Earlier baseline, 2026-07-17. Control-firmware remediation through R5-b is complete:
validated delivery NVS loading, configurable steering endpoints, console parsing
hardening, a provisional 2-second control-loop Task Watchdog, and RTC-retained
reset diagnostics. Native tests: 224/224; all ESP32 environments build. Live
watchdog-cycle observation and physical reset-path validation remain pending.
A2 remains unexecuted and Phase B remains blocked.

2026-07-14: VR/head-tracking plan-consolidation pass (documentation only, uncommitted)
— see "Head-tracking / VR consolidation" under Pending validations.

2026-07-14: VR-FPV batch CB0 (mapper feasibility) DONE — read-only investigation of
upstream elrs-joystick-control (`_vendor/`, uncommitted); unlock plan §2.3 updated to
verified findings; owner decision #1 (5602 topology + fork ownership/license) now
actionable. No code changed in any W17 repo.

2026-07-15: **Owner decision #1 RESOLVED — topology (a)** (unlock plan §2.3.7). Owned
elrs-joystick-control fork owns UDP 5602; Electron stays viewer/config/log-only with a
read-only head-intent diagnostic snapshot via the mapper's existing gRPC; no Electron
control relay; Electron and mapper receiver modes are mutually exclusive (Electron closes
5602 when mapper ingest is on). `_vendor/` stays untracked, read-only, pinned to upstream
`2b8031a`.

2026-07-15: **CB8 slice 1 (mapper log-only head-intent ingest) IMPLEMENTED** in the new
owned fork **`w17-mapper`** (owner-approved name; branch `w17-headtrack` off upstream
`2b8031a`; GPL-3.0-or-later; registered in `WORKSPACE_MAP.md`; push disabled — **⚠ true only
as of 2026-07-15; the fork has had a PUBLIC `origin` since 2026-07-25, see the Checkpoints
row for `w17-mapper` and the 2026-07-27 entry**; git-ignored in the manual repo). Go toolchain installed here (`brew install go`, go1.26.5). New
self-contained package `pkg/headintent` (validator + state machine + non-blocking UDP
receiver, all with injectable seams); diagnostics **in-process only** this slice (Electron
transport deferred — owner picks gRPC vs localhost-HTTP later per unlock plan item 14).
Evidence: go build/vet green, `go test -count=1` + `-race` all green (299/300/301 boundary,
invalid-preserves-last-valid, seq diagnostics, fault, real-UDP accept, UDP port exclusivity),
`go list -deps` proves no config/link/crossfire/serial/devices dependency, and no existing
file imports the package (existing build/output unchanged). See unlock plan §2.3.8.

2026-07-15: **CB8 slice 2 (cmd wiring behind a disabled-by-default flag) IMPLEMENTED** in
`w17-mapper` (uncommitted). `cmd/elrs-joystick-control/main.go` gains `-headtrack-ingest`
(default from env `W17_HEADTRACK_INGEST`; off by default) + `-headtrack-port` (default 5602);
when on it starts a `headintent.Receiver` and **nothing else** (not wired into grpc/devices/
config/serial/link/server/client), bind failure logged-and-ignored; when off no socket is bound.
New test `pkg/headintent/pack_deadend_test.go` proves the gamepad→CRSF `crsf.PackChannels` output
(12 frames / 312 bytes) is **byte-for-byte identical** flag-off vs flag-on under valid/stale/
invalid UDP traffic (`bytes.Equal` + empty shell `diff` of hex dumps; receiver proven non-vacuous).
`go build`/`vet`/`test -count=1`/`test -race` on `./pkg/headintent/` green; `go list -deps` still
reaches no control/output package (crossfire is test-only); only `cmd` now imports `headintent`.
**New host finding:** `go build ./...` on this macOS + go1.26.5 host now clears SDL and the web-UI
embed but **fails only in third-party `go.bug.st/serial/enumerator` v1.5.0** (go1.26 cgo rule) —
pre-existing, unrelated to this change (fails on pristine `main.go` too); a temporary bump to
`go.bug.st/serial v1.7.1` makes `go build ./...` fully green and was then reverted (that dep is in
the CRSF send path → owner decision). See unlock plan §2.3.9.
**Not committed.** No hardware, no active pan/tilt — log-only ingest only.

2026-07-15: **Owner decision — Electron diagnostics transport RESOLVED (gRPC; item 14)**
(unlock plan §2.3.10). Read-only server-streaming `WatchHeadIntentDiagnostics(Empty) returns
(stream HeadIntentDiagnostics)` on the **existing** :10000 gRPC (no second HTTP API, no new port,
no bind/security change this slice); subscriber-only Electron consumer in the main/preload layer;
snapshot-on-subscribe + immediate state transitions, ~10 Hz value updates, latest-value/bounded
1-item buffer, strictly non-blocking (a slow/dead client cannot affect UDP/eval/mix/CRSF); enum
state, server-computed `receive_age_ms`, full counters/seq/rate/angles, last-valid preserved
when invalid/stale. **Recorded, NOT built** (CB8 slice 3). Blockers before building: proto
toolchain absent here (`protoc`/`protoc-gen-go`/`protoc-gen-go-grpc`/`buf`) — needs install
approval or Windows-host codegen; consumer lands in `w17-ground-station` (separate repo).
**Recorded fact:** gRPC :10000 binds `[::]` (externally reachable, not loopback) — left unchanged
per owner; tightening it is a separate decision.

2026-07-15: **CB8 slice 3A (mapper-side gRPC diagnostics) IMPLEMENTED** in `w17-mapper`
(uncommitted; Electron consumer = slice 3B, `w17-ground-station`, later). Added
`rpc WatchHeadIntentDiagnostics(Empty) returns (stream HeadIntentDiagnostics)` + enum
`HeadIntentState` (explicit `_UNSPECIFIED`; no active-control state) to `pkg/proto/server.proto`;
regenerated Go + grpc-web stubs with a **pinned, drift-checked** toolchain (protoc 23.2,
protoc-gen-go 1.30.0, protoc-gen-go-grpc 1.3.0, protoc-gen-js 3.21.2, protoc-gen-grpc-web 1.4.2)
via the new reproducible `pkg/proto/generate.sh` (unchanged-proto regen = **zero diff**; post-change
regen idempotent; no tool binaries committed). New `headintent.Broadcaster` (read-only consumer of
the receiver snapshot: snapshot-on-subscribe, immediate transition push, ~10 Hz value updates,
per-subscriber bounded latest-value buffer, **4-stream cap**→`ResourceExhausted`, cancel/disconnect
release, nil source→`Unavailable`); wired through `pkg/server` + `cmd` (broadcaster only when
`-headtrack-ingest`, else nil). `go build ./...`/`go test ./...` green, `pkg/headintent`+`pkg/server`
`-race` green, webpack compiles the grpc-web stubs. **CRSF `PackChannels` byte-identical** off vs on
under valid/stale/invalid traffic AND with diagnostics subscribers connected/slow/disconnected.
gRPC :10000 still binds `[::]` (external) — unchanged; fan-out protection is the 4-cap + non-blocking
buffers, not the bind. Full build again needed a temporary `go.bug.st/serial`→v1.7.1 bump (go1.26 cgo),
**reverted** — deps/`go.work` pristine. See unlock plan §2.3.10 / §2.3.10.1. **Not committed.** No
Electron integration, no control path, no hardware.

2026-07-15: **CB8 slice 3B (Electron head-intent subscriber) + slice 3C (cross-process
integration validation + proto-drift guard) DONE — both repos committed.** Mapper slices
1–3A committed in `w17-mapper` @ `59d1739` (was uncommitted). GS slice 3B @ `03f43e2`
(prior); GS slice 3C @ `dce91f8`. Slice 3C adds NO runtime behavior (log-only / display-only).
**Proto-drift guard (GS, hermetic):** `test/protoDrift.test.js` proves
`proto/head_intent_diagnostics.proto` is byte-faithful (package, enum value name→number
pairs, all 22 field number/type/label tuples, `Empty` zero-field, method path + streaming
direction) to a checked-in canonical snapshot generated from the live mapper
(`proto/canonical/head_intent_canonical.descriptor.json` via `scripts/check-canonical-proto.js`;
regen is a **zero-diff**); a non-hermetic `npm run proto:check` verifies the snapshot vs a
local `../w17-mapper`. Guard verified to bite on injected drift. **Live cross-process run**
(evidence: `w17-ground-station/docs/2026-07-15_cb8_slice3c_integration_evidence.md`):
real mapper gRPC :10000 + LOG-ONLY UDP 5602, driven by the `iPhone_rc` fake sender, observed
by the shipping GS transport+consumer — captured every `HeadIntentState` live
(IDLE/INVALID/STALE/INACTIVE/NOT_CENTERED/ACTIVE_LOG_ONLY/FAULT; UNSPECIFIED/DISABLED covered
by unit tests, DISABLED not emitted in this topology by design), ingest-off ⇒ `UNAVAILABLE`,
4-stream cap ⇒ 5th subscriber `RESOURCE_EXHAUSTED`, mapper restart ⇒ bounded-backoff reconnect,
`crsf.PackChannels` byte-identical with receiver + subscribers attached (`go test
./pkg/headintent/` + `./pkg/server/`), and topology-(a) mutual exclusivity live
(`W17_MAPPER_HEADINTENT=1` ⇒ GS W3 does not bind 5602 + consumer on; unset ⇒ GS binds 5602 +
consumer off). Validation binary built with a temporary `go.bug.st/serial`→v1.7.1 bump under
`GOWORK=off`, then reverted — `go.mod`/`go.sum`/`go.work` byte-pristine vs `HEAD`. GS suite
746/746.

2026-07-15: **CB8 slice U4 (head-intent shaping/arbitration) — DESIGN ONLY, SAFETY-GATED,
DONE.** No active output, no runtime-behavior change in any repo. Design written as
`w17-control-fw/project-review/head_tracking_unlock_plan.md §2.3.11`: the shaping/arbitration
model (deadband in deg via the U3 deg↔count table; rate/accel slew; **active freshness gate
≤250 ms** distinct from the **300 ms** log-only diagnostic boundary; center/enable/arm
preconditions; failsafe **decay-to-commanded-992**, reconciled with the firmware radio-loss
hold-vs-center owner decision #3/§5-2/U8 which it de-risks but does not resolve); **arbitration
authority = mapper-only, single post-node-graph choke point** before `crsf.PackChannels`
(supersedes the earlier in-graph-node sketch §2.3.3/§2.3.5); 9 safety invariants (I1–I9); the
exact test matrix (Groups A/B/C) the gated code must prove; the two-part **FIRST_ACTIVE flag**
(compile-tag + runtime, both default off, both required); and the **FIRST_ACTIVE review
checklist **R1–R16** (R15/R16 added 2026-07-30) that must all pass before any arbiter code is committed. **No code
scaffolded** in `w17-mapper` (deliberate — shaping code would bake in unreviewed constants +
a control-path stage): `w17-mapper` clean at `59d1739`, `go test ./pkg/headintent/` green
(the standing `pack_deadend_test.go` PackChannels byte-identity proof unchanged), proto still
ends at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` (**no active enum value**), GS 746/746 +
`npm run proto:check` clean (no proto change). Firmware still iPhone-unaware; no
iPhone→CRSF/servo/gimbal/ESC. Next (GATED): **first U4 implementation slice — only if/after
the §2.3.11.6 FIRST_ACTIVE review is approved.**

2026-07-15 (later): **FIRST_ACTIVE consolidation — owner decisions RECORDED (docs only,
uncommitted).** In `w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.12 +
§3.1 + §4/§5: decision **#2 video loss** resolved (sender-side suppression → ordinary
mapper stale decay; video never directly commands servo/CRSF; operator-facing
degraded-video state required); **#3/U8 radio loss** resolved FOR BENCH ONLY (hold-last
stands; MUST re-review before driving); **#5 driving** resolved (FIRST_ACTIVE bench-only,
wheels off, operator present, e-power removal, ±5 mech deg first travel; separate
driving-readiness milestone with reviewed gate + spotter). Also recorded: invalid-packet
policy (one invalid ⇒ eligibility removed + decay; repeated ⇒ latched fault; recovery =
disarm + valid-data interval + explicit recenter), GLOBAL manual-override (both axes, wins
in active AND decay, latched, no auto-restore), hybrid yaw→pan/pitch→tilt position→rate
mapping (roll ignored, no discontinuity), and the shaping-constants **derivation policy**
(deadband from measured jitter, floor 1°/cap 3°; 10°/s; 20°/s²; takeover = max(noise,
~10% half-range); missing calibration ⇒ fail closed; NO production values signed). Fork
license **GPL-3.0-or-later + provenance recorded (R11 PASS)**; `go.bug.st/serial`→v1.7.1
**approved as a future isolated mapper slice** (not mixed with anything). **Controller
affordances L1+R1 deadman / R3 recenter FAILED the conflict audit** (R1/L1 = gear up/down
in every GS SEAT-FIT preset; R3 perturbs the pan/tilt stick) — NOT adopted. **Owner-choice
RESOLVED 2026-07-15 → Alternative C (bench-only):** short-press SHARE = recenter; hold D-pad
DOWN + OPTIONS 1 s = arm; OPTIONS may then release; D-pad DOWN is the continuous held deadman
(release = disarm); the right thumb stays free for right-stick manual takeover. A and B
rejected (held two-thumb chords impede that takeover). **Live mapper node-graph binding
validation (SHARE/OPTIONS/D-pad DOWN unbound) still required; bench-only, NOT for driving**
(decision #6, §2.3.12.6). iPhone **R10 = PASS (automated only)**: 250 ms send-time gate verified
read-only in `iPhone_rc` (249/250 eligible, 251 stale; cached-active cannot bypass);
uncommitted — real-device lifecycle/axes/mount + canonical commit + mirror still pending.
U4 design addendum completed (states/transitions/guards + required test per behavior) and
the canonical execution order **A–O** recorded (§3.1). **FIRST_ACTIVE overall verdict:
NO-GO / BLOCKED** — R1/R2/R6–R9/R12/R13 remain hardware/evidence class; no missing
hardware evidence was converted to PASS.

2026-07-15 (later still): **Windows ground-station reliability slice — IMPLEMENTED on
macOS, COMMITTED as `e0a5cdc`, in `w17-ground-station` only.** Addresses five real Windows
observations: (2A) production full-screen launch (NOT kiosk; F11 restore; dev override
`W17_FULLSCREEN`); (2B) live WLAN-adapter discovery while the Network page is open
(main-process `adapterMonitor.js` bounded polling → `adapter-state` push); (2C) adapter-
disconnection transitions (join early-aborts `kind:'adapter-missing'`; a live hotspot marked
INTERRUPTED / re-verified when its adapter set changes; vanished selected adapter invalidates
the pick, no auto-switch); (2D) honest hotspot **DHCP/ICS readiness** model
(`hotspotVerify.js`: WinRT tether state + ICS `192.168.137.x` gateway + `SharedAccess`/`icssvc`
service state → `verified`/`degraded`; `idle→verifying→verified/degraded`+`interrupted`; a
start-command success is never shown as client-ready); (2E) auth-error UX (terse wrapped
summary + expandable scrollable redacted detail; no overlap; clears on new op).
`shared/redact.js` scrubs secrets from any surfaced command output. **Evidence:** `npm test`
**798/798** (46 files; +52 reliability tests; the pre-existing WIP had left the suite 5 red —
now repaired by completing the wiring), `npm run smoke:electron` **4/4** (live preload surface
24 methods, console-clean), `npm run proto:check` OK. **No** bridge schema / canonical contract
/ control path / firmware / mapper / iPhone change. **Pixel/hotspot root-cause distinction
(no overstatement):** the **proven code/UI root cause** is that a successful hotspot-start
*command* was treated as client-readiness without verifying ICS/gateway/services/DHCP; the
physical Pixel "Obtaining IP address" failure has a **leading hypothesis** (missing/broken ICS,
no subnet gateway, DHCP service down, driver/AP-mode limits, or adapter/backend behaviour) but
its **actual cause remains UNPROVEN** until the real-Windows validation captures host gateway,
ICS + `SharedAccess`/`icssvc` state, adapter/backend, and the Pixel lease result. The
verified/degraded model correctly stops a false "ready" but does not itself prove end-to-end
DHCP. **Windows/Pixel behaviour UNVALIDATED** on this macOS host (real adapter timing, ICS/DHCP
enablement, and the **Pixel IPv4-lease path** remain the next-session Windows validation).
Durable tracker + runbook: `w17-ground-station/docs/2026-07-15_windows_reliability_slice.md`.
These changes are **committed as `e0a5cdc`** and **Windows CI is GREEN at `e0a5cdc`**
(run `29440396447`).

2026-07-16: **Ground-station Batch F closed + verified (this implementation plan).** The
reliability slice landed as `e0a5cdc`, and the earlier CB8 3B/3C (`03f43e2`/`dce91f8`) plus the
2026-07-15 documentation-sync (`8c5af12`, terse msg "some chages") were pushed — `w17-ground-station`
`main` is **level with `origin/main` (0 ahead / 0 behind)**. The Batch F documentation re-sync
(audit banner/hardware-matrix CI SHA/transfer checkpoints/Batch-F section, bench-checklist baseline
746/43→798/46, reliability-slice CI note, and the README/SETUP hotspot readiness-lifecycle step) was
committed **docs-only** as **`170fd66`**. **Windows CI is GREEN for both:** app HEAD `e0a5cdc` = run
`29440396447`; docs `170fd66` = run `29473220328` — each ran ubuntu `test` + windows-latest
`package-smoke` (`npm test` **798/798, 46 files** + `npm run smoke:electron` **4/4** + `electron-builder
--dir`). Real **Windows/Pixel hardware** validation of the reliability slice is still pending. The separate SEAT-FIT / camera-mode display track named here has since grown into the
full **setup-flow redesign (Batches 0–9) — now SHIPPED, AUDITED, and PUSHED** (`8441adb`; see the
`w17-ground-station` Checkpoints row and the 2026-07-17 entry below). **Batch G not started.**

2026-07-17: **Hardware delivery (partial).** Electronics arrived: **3× ESP32 boards**,
**BL-M8812EU2 USB WiFi module** (the camera's 5.8 GHz video-link module), **ELRS TX**,
**LiPo voltage tester**, **resistor kit**. Mechanical items (MR128ZZ front bearings ×10,
3×32 mm turnbuckle, M4 rod-end linkage balls ×10, M3 tie-rod-end ball caps, steel threaded
rods, aluminium tube) are logged in `w17-3d-codex/GENERAL_PLAN.md` open-questions item 5.
Still awaited (per that item + the RT5370 note below): tyres, shocks, servos, king pins,
belt set, blower, rear 6801 bearings, RT5370 USB Wi-Fi. Delivery changes no software
status: A2 remains unexecuted, Phase B remains blocked, and no unattended
flashing/powering. CB5 (video baseline) remains gated on assembling/verifying the
camera + BL-M8812EU2 pair on a bench.

2026-07-17 (later): **Owner approved a BARE-BOARD USB smoke test** as a scoped exception to
the pre-A2 no-powered-bring-up rule (`w17-control-fw/CLAUDE.md`): one naked DevKit at a
time, USB from the Mac only, **nothing connected to any pin**, attended, no
battery/PSU/ESC/servo; A2 + Phase B stay in force for the car harness. Procedure manual:
`learning-manual/13_bare_board_smoke_test.md` (includes the physical NVS
save→reset→reload evidence steps and a per-board evidence template). All software suites
re-verified green on this machine today: control-fw native 224/224, soundlight native
94/94, ground station 976/976 (52 files — SEAT-FIT WIP has grown the suite past the
recorded 798/46), mapper `pkg/headintent` ok. Smoke test NOT yet executed; results to be
pasted back into a session.

2026-07-17 (later still): **Setup-flow redesign (Batches 0–9) SHIPPED, AUDITED, and PUSHED**
in `w17-ground-station`. The SEAT-FIT/camera-mode display track named above grew into the full
pre-race setup redesign: PIT WALL/SEAT FIT layout fixes, a generic **steering-wheel display
mirror** + assign/calibrate UI, HUD wheel mirroring, flow chrome (step rail, solid backdrop,
GARAGE fast-path card, HUD status stack), step reorder (SEAT FIT before PIT WALL; desktop skips
PIT WALL), and controller-driven UI navigation. All 11 commits `a88692d..9855cc3` are on `main`
and now PUSHED; the final audit is committed docs-only as **`8441adb`**
(`w17-ground-station/docs/audits/2026-07-17_setup_flow_redesign_audit.md`) and also pushed.
Suite **984/984 (52 files)**, smoke 4/4 (apiKeys 24), proto:check OK,
noControlPath/ipcSurface(24)/responsiveLayout green; live CDP-driven sweep at
1280×800/1366×768/1024×640/fullscreen. Audit verdict: history maps 1:1 to plan batches, all 7
invariants PASSED, and **9 findings recorded but NOT fixed at that time (deliberate — follow-up
work):** 1 HIGH (calibrated wheel profile silently dropped by `normalizeSettings`); 1 MED (HUD wheel
mirror can resolve the wrong device when the wheel is absent at START); 4 LOW UX/display defects;
1 docs gap; plus a design-bundle-§10 deviation and a readAxis-dedupe observation. **All 9 have since
been closed — see the 2026-07-25 entry below; do not read this paragraph as a list of open work.**
Windows CI at `8441adb` was not re-verified in that session (green recorded later at `3119180`, run
`29724061397`).

Ground-station pre-ride setup flow, iPhone mDNS proposal, and `w17-3d-codex`
bootstrap status remain as recorded below._

2026-07-22: **Zero-hardware suite re-verification** (read-only session, no source edits).
All green: `w17-control-fw` native **224/224**; `w17-soundlight-fw` native **94/94**
(README corrected from a stale "40" — see repo commit); `w17-ground-station` `npm test`
**1046/1046 (53 files)** — grown further past the `8441adb`-era 984/984 recorded above
(recent SEAT-FIT/wheel-support work), `npm run smoke:electron` **4/4**; `w17-mapper`
`go test ./pkg/headintent/...` all green (full `./...` still blocked only by the
pre-existing go1.26 × `go.bug.st/serial` cgo incompat, not a new failure). The 976/976 →
984/984 progression recorded above (2026-07-17) is left as-is — it's an accurate log of
what was true at each point that day; this entry just adds the next data point.

2026-07-22 (later): **BARE-BOARD USB SMOKE TEST EXECUTED — all 3× ESP32 DevKit PASS**
(attended, owner present for every plug/unplug; procedure `learning-manual/13_bare_board_smoke_test.md`;
scoped 2026-07-17 exception — A2 + Phase B untouched, nothing on any pin, USB-only). Boards are
**USB-C DevKit V1 clones** (manual §2 assumed micro-USB): silkscreen "ESP-32D", flasher-confirmed
**ESP32-D0WD-V3 rev v3.1** (classic ESP32; `ets Jul 29 2019` ROM banner), **CH340C** USB-UART
(VID:PID 1A86:7523), 30-pin. MACs: #2 `b4:bf:e9:05:61:4c`, #3 `b4:bf:e9:06:9f:d4` (#1 not captured).
Each board flashed `esp32dev_tuning` clean (no BOOT hold), booted `reset=POWER_ON boots=1 retained=no`
+ `[tune] loaded settings from flash` (non-virgin from the owner's prior flash — expected; no NOT_FOUND);
console help/status/get/set/save/reset all correct (center=1500, gears=4, channels 0/2/4/5 placeholder
confirmed). **Physical NVS persistence PROVEN on all three:** a fresh distinct write (steer.trim 5→12)
survived an EN power-cycle (`loaded settings from flash`, get=12), then reset→0→save→EN→get=0 (defaults
persisted). No panic / TASK_WDT / BROWNOUT; only mild warmth reported, none flagged hot. All three
returned to compiled defaults and unplugged/labeled 1/2/3. One §12.1 serial-port-lock recurrence during
board-3 flash (stray monitor held the port; cleared, reflashed OK). **NOT done / still open:** optional
reflash-survival + delivery-silent legs (skipped); crash-class reset classification + RTC retained-counter
increment unexercised (only POWER_ON seen, by design); board role assignment deferred to harness assembly;
A2 / Phase B unchanged. Per-board §11 evidence: `learning-manual/13_bare_board_smoke_test_evidence.md`.

2026-07-24: **Batch-1 physical measurement session (no-power) — component envelopes + weights
captured; A2 / Phase B UNCHANGED.** No power/battery/PSU/USB/flashing; harness is still loose
modules so A2 §3–§9 was not executable and was not run. Calipers + gram scale only. Results +
Codex mechanical-register handoff: **`w17-batch1-measurements-for-codex.md`** (workspace root; Claude
does not edit `w17-3d-codex`). Photos in `w17-3d-codex/images_of_parts/batch_1/`.
- **Board decision (owner):** both controllers will be **MH-ET Live D1-Mini ESP32** (frees cassette
  space; USB-C variant being sourced). This makes the ZK "FIRM" 39×31 board premise true by
  procurement — the 39 mm wall-row / `X+3…+42` seat / `S0≥9.82 mm` derivations stand. The on-hand
  USB-C DevKit V1 clones (30-pin) are **TEST/SPARE only**, not the cassette controllers. Real MH-ET
  caliper + weight pending purchase (ZK CAS-03 stays open on the physical board).
- **Two height findings on the #1 blocker (steering clearance, `KO-01 Z22 − PDB top Z19 = 3 mm`,
  5 mm short of policy):** UBEC measured **9.1 mm** (ZK assumed ~18 mm "UBEC-dominated") → PDB height
  can drop → *helps*; QuicRun ESC installed height **34 mm** (fan+heatsink on top) vs documented
  24.2 mm → ESC floor station Z1.5…25.7 too short → *reopens ESC clearance* (CAS-06/ASM-49).
- **BL-M8812EU2 = 32.4×32×7 mm, 11.2 g** → fits the ≤60×32×12 allocation → **D-06b unblocked** (was
  uncalipered/unplaced).
- **DS3235SG side face 40.25×20.2** vs 42×18.5 arch → **~1.7 mm height interference confirmed**
  (fit study predicted ~1.5 mm); physical no-force dry-fit (Track D) + steering sweep/S0/arch
  (Track C) still pending; do not file/force test-grade prints.
- Weights lighten the CG control/RF group (assumed 72.5 g); motor 156.7 g / ESC 100 g / servo 70.3 g
  dominate; four-corner scaling deferred to a rolling assembly. Details in the handoff doc.

2026-07-24 (later): **Electrical BOM FINALIZED + all items ORDERED (owner) — no gate change.** Every
remaining cassette electronic module is chosen and en route; no open sourcing decisions remain. **A2 still
NOT-EXECUTED, Phase B still BLOCKED** — ordering is not powering; the harness must still be built and A2
run before any power. Ordered: 2× MH-ET D1-Mini ESP32 (USB-C), ceramic + electrolytic cap kits (covers
1000 µF servo-rail + LED, 100 nF, opt 1–10 nF), **Amass XT90-S anti-spark master switch** + XT60→XT90
adapter, **IP2326 2S Type-C balancing charger** (18.3×31 mm, confirmed balancing), **ZEEE 1500 mAh 2S
LiPo** (69×35×18, JST-XH; owner will re-terminate to XT60); 1N5819 from office stock. (These ordered/
in-transit rows still owe an entry in `HARDWARE_INVENTORY.md` as ⏳ — left for that file's in-progress
edit; not touched here to avoid clobbering its uncommitted rewrite.) New Claude-side build docs:
**`w17-pdb-build-and-connector-guide.md`** (PDB schematic/topology, connector proposal with genders +
proposed cable lengths, capacitor placement + soldering guide, pins reconciled to `PinMap.hpp`) and the
Codex recalc handoff **`w17-codex-batch1-recalc-prompt.md`** (PDB-height re-derivation, ESC 34 mm station
reopen, Wi-Fi placement close, CG refine, dock/charge routing). Physical caliper of the MH-ET boards + the
actual 1000 µF, and the Track C/D fit-gates, still await parts/printed-part sessions.

2026-07-25: **Workspace bookkeeping sync (docs-only, no hardware) — A2 still NOT-EXECUTED, Phase B
still BLOCKED.** Nothing here touched firmware, gates, or any control path.
- **Pushed finished work.** `w17-soundlight-fw` `4f25856..ec5ddf8` (11 commits) after verifying
  native **94/94**; `w17-design-system` `b301de0..6a59c96` (1 docs commit). Workspace repo: `main`
  fast-forwarded onto the `w17-batch1-measurements` branch tip and pushed (`bb8e7e7..c5d32c7`) —
  the branch was a strict descendant, so the merge was a clean fast-forward; the branch ref is now
  redundant and retained only as a label.
- **Ground-station audit findings — ALL 9 CLOSED** (the checkpoint row and the 2026-07-17 entry are
  corrected accordingly). Finding 1 (HIGH, wheel profile never persisted) fixed in **`a04b07c`**:
  `normalizeSettings` now admits a validated `wheel.profile` subtree via conditional spread
  (`shared/settings.js:191`) with a CJS-local `normalizeWheelProfile` mirror, a parity test against
  the ESM `shared/wheelProfile.mjs`, and a hostile-corpus persistence test
  (`test/wheelProfilePersist.test.js`). Findings 2/3/4 fixed in **`5141912`** (absent wheel yields
  no mirror and an honest `INPUT · WHEEL (NO DEVICE)` tag instead of driving a gamepad through wheel
  calibration; WHEEL mode gains its own device selector; `wheelActive` gating). Findings 5/6/7 fixed
  in **`ec1baef`** (⚙ inert to the pad during the start-lights countdown; fast-path card focused on
  boot only; in-code deferral markers). **`085e1d1`** then fixed a defect that closure-verification
  of `ec1baef` itself surfaced — the BOTH-mode source tags shipped `.barsrc hidden` but `hud.css`
  had no generic `.hidden` rule, so the class was visually inert and the tags leaked into
  GAMEPAD-only and WHEEL-only modes; the jsdom class-only assertions had passed vacuously. The
  design-bundle §10 observation was resolved both ways in **`e57f587`** (Decision B), and the
  `readAxis`/`clampAxis` dedupe observation is explicitly **waived in-code** at
  `shared/wheelProfile.mjs:88`. Verified against live code this session, not taken from commit
  messages. **Consequence: the session prompt `w17-gs-audit-followups-prompt.md` is now wrong where
  it says "Findings 2–7 are still open" — a correction banner was added to it rather than deleting
  the prompt.**
- **`HARDWARE_INVENTORY.md`**: the 2026-07-24 electrical order is now recorded there as a new **§E**
  section, all rows **⏳ in transit** (2× MH-ET D1-Mini ESP32 USB-C, ceramic + electrolytic cap kits,
  Amass XT90-S master switch + XT60→XT90 adapter, IP2326 2S Type-C balancing charger, ZEEE 1500 mAh
  2S LiPo, plus the 1N5819 as 🏠 office stock). The debt that the 2026-07-24 entry recorded is
  discharged. That file still carries arrival status only — no hashes, no gate state.
- **Cross-repo follow-up closed (elsewhere):** the `w17-3d-codex` "stop tracking arrivals" cleanup
  that `HARDWARE_INVENTORY.md` listed as owed has in fact landed there as `59a1634` (2026-07-22) —
  **but that commit is unpushed.** Not edited or pushed from here.
- **Root artifact triage.** Nine spent ground-station artifacts deleted (the `a1` / `a1-a2` /
  `through-d1-d4` patches, their three audit copies, two `git status` snapshots, and the
  planning handoff). Proof before deletion, not assumption: the committed
  `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md` (2592 lines) is a
  strict superset of the 1818-line root copy and names the landing chain itself — `79fa2e0`
  ("a lot of chagnes", 62 files, +10524/−570) → `0564141` → `297ca79` → `8ceb931` → `0e85702`;
  90–96% of every patch's added lines are present verbatim at GS HEAD, and each apparent gap was
  traced with `git log -S` to `79fa2e0` followed by later refactoring in `e0a5cdc` / `8c5af12` /
  `d822c80`. The planning handoff's four changes are exactly GS `3119180` and its "FINAL, SEPARATE"
  design-system item is `6a59c96`; its named intermediate deliverable
  (`w17-ground-station-impl-plan.md`) was never written to disk, so the plan was consumed in-session.
  Live session prompts, the six Codex handoff docs, and the steering-servo fit diagram were committed
  instead. `.claude/` and `.preview-tmp/` are now git-ignored; `.preview-tmp/` was deleted.

2026-07-27: **Workspace bookkeeping delta (docs-only, no hardware) — A2 still NOT-EXECUTED,
Phase B still BLOCKED.** The 2026-07-25 sync (`05157b2`) ran *before* three sessions finished, so
the tables above were stale again. This is a delta, not a re-run: the audit-findings closure, the
CI run list, the test counts and the staleness warning from that pass were re-checked and kept.

- **Live 13" pass (prompt 8) — DONE.** Three items closed, two defects opened.
  - **BATT ordering RESOLVED toward the code** (owner, 2026-07-25): shipped order stands — BATT
    above the merged pill row, `BOOST · OVERTAKE · DRS` within it. The decisive measurement is
    not aesthetic: both stacks occupy an **identical envelope** (y 643→782 at 1280×800), but the
    mockup order terminates the right column's bottom edge — the HUD's strongest horizontal
    alignment line, registering against the bottom-left R-STK panel — with a **99 px chip leaving
    a 184 px notch**, versus a full-width **283 px** block.
  - **`.revwrap` centering CONFIRMED** — offset from viewport centre **0.00 px**, holding under a
    forced 30-char driver name, a 52-char team string, a long clock, and tiny values. `e01eb9f`
    did exactly what it set out to.
  - **`#addrStatus:empty` reserve works as designed** — empty ⇒ height 0; after CHECK ⇒ 33.6 px
    with the hint shifting down by exactly that. The one-time shift is a deliberate, code-commented
    trade.
  - **Viewer-only disclaimer verified genuinely once per session** — visible on boot GARAGE (36 px,
    in normal flow, crossing nothing), hidden on every later screen, still hidden after a full
    CHANGE SETUP → back-to-GARAGE round trip; both homes carry byte-identical copy.
  - Clean at all four sizes × both paths: rail `01..05`, GRID reads 05, solo shows `02 PIT WALL`
    struck through as `SKIPPED · DESKTOP`, zero horizontal overflow, no wrap. Invariants held in
    every screenshot (HEAD TRACKING LOCKED · SAFETY GATE NOT COMPLETE, ACTIVE AUTHORITY NOT
    REPORTED BY MAPPER, violet `STICK INPUT · PAD`, `ARM / FAILSAFE · NOT REPORTED BY CAR`).
- **Prompt 12 phase A — DONE, GS `1a6f9f2`** (CI `30150690390` green, 1090/1090 in 56 files,
  `responsiveLayout` 34 assertions). `17ec1be` rail comments · `2c96eb1` SETUP → one centred
  column · `1a6f9f2` `#gamepadPanel` rhythm.
  - **D1 overflow — record what it actually is, or it reads as a shipped defect.** Stacked SETUP
    exceeds the viewport at three of four sizes (30 / 72 / 95 px at 1280×800 · 1366×768 ·
    1024×640) and **every pixel of it is the `--gate-toast-reserve`** (121.6 px of `.gate` bottom
    padding held for the `position:fixed` `.radioLog`) — **not content**. All content plus
    BACK/NEXT stays visible unscrolled at every size (worst case nav bottom 95.8% of a 640 px
    viewport); an all-elements intersection sweep found **zero** hits against the radio band.
    `.gate` already had `overflow-y:auto` + `justify-content:safe center`. Owner chose scroll.
  - **Two premise corrections, now test-pinned:** the dead left column was **~191 px, not
    ~300 px**; and **SEAT FIT stays split** — a test asserts `.cols.seatcols` never gets `.stack`,
    because its right column is the *taller* one (1.31–1.38 : 1) and the original "SEAT FIT reads
    empty" assumption was **inverted**.
  - **D2** reproduced before fixing (all six row boundaries measured exactly 0 px, then 11.2 px).
    Uses a new `--col-gap` token on `:root` consumed by both `.col` and `#gamepadPanel` so they
    cannot drift. One boundary reads 16.79 px because `.errdetail` has a pre-existing
    `margin-top:.35em`, deliberately left since `.errdetail` is shared with the PIT WALL error panes.
  - **19 injected regressions** (9 for A1, 10 for A2) each proven to fail the intended assertion,
    including the silent-pass modes: `minmax(0,56ch)` vs `min(100%,56ch)`, the gap re-guessed as a
    literal `.7em`, `--col-gap` deleted or zeroed, and the rows wrapped in an inner `<div>`
    (satisfies every CSS assertion while collapsing the gap to 0).
- **Prompts 12 phase B + 13 — DONE, `w17-design-system` `26ec870`**, pushed. §11(f) resolves the
  right-column order toward the code; §14(d) records the single-column SETUP; the twice-superseded
  "Adoption path" entry is gone. The `~300 px` → **`~191 px`** correction landed with the
  41.8% / 71.6% column-end figures beside it **because they derive it**:
  **(0.716 − 0.418) × 640 = 190.7 px** — independent arithmetic corroboration that ~191 is right
  and ~300 was an estimate. `screens/05-hud.html` was **finally rendered** (served over `127.0.0.1`,
  since the browser pane refuses `file://` outside the project folder) and **measured rather than
  eyeballed**: BATT 649→688, pillrow 696→727, ERS 735→786, all **283 px** wide — reproducing
  §11(f)'s own arithmetic, **283 − 99 = 184**, the notch the ruling rests on. The ruling is backed
  by geometry the rendered screen actually has.
- **Prompt 6 (CB1 + CB4) — DONE and PUSHED, GS `92cd894`, CI `30263115532` GREEN.** At report time
  these were unpushed and CI-unverified; both were checked this pass rather than assumed, and CB4
  touches **main-process startup**, so that Windows CI run is the first real check of the surface.
  - **CB1 was already shipped** on 2026-07-16 with the SEAT FIT slice — the `NOT_STARTED` row was
    stale bookkeeping, not open work. `92a0dce` is the closeout only.
  - **`/code-review high` found 7 real defects, two self-introduced**, all fixed: a socket error
    handler missing the identity guard (a dead socket's late error would tear down its live
    replacement); a comment claiming the backwards-pointer rule *alone* prevents DNS decompression
    loops — it does not, the jump cap is load-bearing, and the comment invited deleting it; and a
    plain multicast send following the routing table, which on a deliberately multi-homed bench
    host would never reach the hotspot subnet (now sends on every local IPv4 interface).
    **Mutation-testing the fixes then caught two tests that didn't bite**, one guarding already-dead
    code (`·` is U+00B7, above the printable-ASCII ceiling, so the extra check was unreachable).
- **Control-fw zero-hardware batch + this pass — `main` = `8d0309e`, pushed.** Native **225/225**,
  all three envs build. **CB3 DONE** (anchor had drifted one line). **R05** closed: 4 gears
  canonical; the phantom "6" was `Gearbox::kMaxGears` (array capacity) misread as a count, and the
  only fix needed was the stale mock at `docs/f1_hud.html:286`. **R19** closed: TRAINING/RACE/ERS is
  canonical for display, and the wire enum `TRAINING/GEARBOX/GEARBOX_ERS` **deliberately differs**
  — recorded as a decision, not drift; one stale comment at `Link2Sender.hpp:21`. **R06** closed:
  the link2 copy is **permanent-but-guarded** — `tools/link2_copy_check.sh` (`--strict`; exit 1
  drifted / 2 could-not-check; verified to bite on an injected `kPayloadLen` change and a deleted
  file) plus a hermetic feel-constant pin. R06's conflation of wire format vs feel constants is now
  recorded as **two separate guards**. **R01** decided: armed/failsafe stay **simulated but must be
  labelled** — adding `A1F0` to FLIGHTMODE was rejected because 15 chars exactly fits, R13 is
  unproven, and mid-token truncation could show a *wrong* armed state; the label itself was the
  ground-station follow-up, implemented in `16d3d0a`.
  **The cross-repo link2 guard is now ENFORCED, not advisory** (soundlight `2d22f85`) — that caveat
  is dropped wherever it appeared.
- **`feelConstants` drift guard (GS `9c2d723`) — scope went beyond the brief, correctly.** All
  **four** firmware-derived constants are bound, not the three in `ErsSystem.hpp`: `GEARS`'s
  "matches the firmware gearbox `numGears=4`" was an unguarded claim of exactly the same kind, so it
  binds to `Gearbox.hpp`; `TOP_SPEED_KMH` stays unbound with a test asserting that positively. Exit
  codes **1/2/3** match `link2_copy_check.sh` and **deliberately differ** from `proto:check`'s 2/3 —
  stated in the script header so nobody silently "harmonizes" them. `--strict` /
  `W17_FEEL_CHECK_STRICT=1` makes an absent sibling exit 2, as does a renamed firmware member —
  never a silent pass. Every new assertion was verified to **bite on an injected regression** first
  (16 injections across four test files), and `../w17-control-fw` was verified clean after each.
- **Viewer-only disclaimer restored (GS `769003b`) — the constraint is worth keeping.** It lives in
  the ⚙ settings panel, shown once per app session via a module-level `viewerNoteShown` flag driving
  `updateViewerNote()` from `showStep()`, and deliberately has **no dismiss button**: a focusable in
  GARAGE would enter the document order that finding 6's boot-only focus depends on, and
  `test/viewerOnlyNotice.test.js` asserts `boot()` still focuses `fastPathBtn`. A `settings.json`
  key was rejected because it would have to pass `normalizeSettings` and would break
  `settings.test.js`'s 12-key persisted-shape pins.
- **RETRACTION — the preload surface IS hermetically pinned.** An earlier instruction claimed
  `test/ipcSurface.test.js` asserts only symmetry plus `exposedKeys.length > 15`, leaving the exact
  24 pinned solely by `smoke:electron` (which cannot run on this host). **That was false.**
  `test/ipcSurface.test.js:153` asserts the **exact sorted 24-name key set** — and has since
  `e0a5cdc` (2026-07-15). The `length > 15` at `:90` is a separate vacuity sanity-check, not the
  pin. Verified 2026-07-26 by injecting an extra key (2 failures incl. the exact-set pin) and a
  rename `probeHost → probeHostX` (3 failures), both hermetically, no Windows CI involved.
  **The error's shape matters more than the fact:** the claim entered via a session report that read
  `:90` and missed `:153`, and was accepted without opening the file — because it confirmed a
  suspicion already held. Staleness in this workspace runs toward **over-reporting open work**; this
  one ran toward **inventing** it. The countermeasure is the same either way: **open the file.**
- **Durable backups now exist** (outside any scratchpad).
  **✅ `~/Documents/w17-backups/w17-mapper-allrefs-2026-08-03.bundle` — use this one.** Created
  2026-08-03, caps at **`5a28106`**, `--all` refs. Held to the same bar as its predecessor: `git
  bundle verify` reports a complete history, and it was **clone-tested** (`--branch w17-headtrack`,
  HEAD `5a28106`, `.githooks/pre-push` + `FORK-NOTICE.md` both present, and all three failsafe
  commits — `2dc7c5a`, `630ea96`, `d42a277` — in the log); the test clone was then removed.
  **This closes the gap flagged twice on 2026-07-30 and 2026-08-03:** the previous bundle capped at
  `0e11d6b` and so predated the entire failsafe chain, including the `2dc7c5a` hold-last fix. The
  older `…2026-07-25b.bundle` (caps `0e11d6b`) is retained as a second copy only. The earliest
  `w17-mapper-allrefs-2026-07-25.bundle` caps at `8fc1915` and therefore does
  **not** contain the pre-push guard — i.e. it is missing the very commit that replaced the "no
  remote" safety accident. It is kept only as a second copy. Also
  `~/Documents/w17-backups/spent-gs-artifacts-2026-07-25.tgz` (SHA-256 matches the scratchpad
  original, 15 entries; copied not moved, so the scratchpad copy can expire on its own).
  **Honest limit: same physical disk** — this protects against repo deletion and session cleanup,
  **not** drive failure. GitHub now covers that axis for the mapper.
- **Branch cleanup:** `w17-batch1-measurements` (`c5d32c7`) confirmed fully merged into `main`
  (`git branch --merged` + empty `main..branch`) and deleted local and on origin.
  `w17-control-fw`'s redundant `docs/bom-cassette-electrical` was already gone from both.
- **Codex item — RAISED AND CLOSED 2026-07-27 at `w17-3d-codex` `0386b2f`** (committed by Codex;
  **1 commit unpushed** as of this writing). `2325fd9` had added two *new* rows asserting the ESC
  is **44.2 × 37 × 24.2 mm** as "DOCUMENTED owner physical ground truth" (`DRV-ESC-CURRENT`) and
  that its envelope is "closed" (`OP-01`) — but the 2026-07-24 caliper measured
  **44.2 × 33.7 × 34.0**, and 24.2 is precisely the documented figure that measurement
  *superseded*. The same commit's ZK study carried the correct 34.0, so the repo contradicted
  itself and **the stale half wore the strongest confidence tag.** Handoff:
  `w17-codex-esc-groundtruth-fixup.md` (workspace root, not `_handoff/`).
  **Fixed in `0386b2f`:** envelope corrected to 44.2 × 33.7 × 34.0 tagged VERIFIED, the superseded
  44.2 × 37 × 24.2 retained with the cooling-stack explanation, `OP-01` reworded (measured, but
  station FAIL-STATION pending re-derivation, not "closed"), the placement matrix reconciled to
  **L−60.5…−26.8 / body Z1.5…35.5 / intake plane Z45.5**, validator paths relativised, and the
  cassette + wire-schedule artifacts regenerated. Validation **cassette 57/57, wire schedule
  36/36**, tree clean. **No gate or print-authorization change** — GATE P1 still not passed.
  Its wire validator had gone 35/36 because the pinned `w17-control-fw` PinMap hash moved
  `6afc… → bf6c…`; that drift is **benign and expected** — caused by `37ebe46` (CB3), which is
  **comment-only** (verified by diff: three comment lines, zero pin values; the validator's own
  pin-token checks passed throughout). Re-pinned to `bf6c…` citing `37ebe46`. This is the first
  time any of this project's three cross-repo guards has fired on a live change, and it behaved
  correctly: it refused to accept a changed upstream file silently. Everything else
  cross-checks clean — note that the "2 commits unpushed" half of that same prompt-13 finding
  **had already gone stale by 2026-07-27** (Codex pushed them; verified by `git ls-remote`, not
  by the local tracking ref, which can lag). The inconsistency below is the part that survived.
  Other cross-checks clean (MH-ET board
  decision, DS3235SG side-on, §E ⏳ rows treated as not-in-hand). The DS3235SG **1.5 vs 1.7 mm** is
  **not** a contradiction — the study predicted, the caliper refined, and this file already records
  it as "predicted ~1.5 mm — confirmed".

**Staleness audit for this pass (the rule from `05157b2`, applied explicitly).** Every
`PENDING` / `NOT_STARTED` / `BLOCKED` line kept above was re-checked rather than carried:
A2 unexecuted and Phase B blocked (unchanged, no hardware touched this pass); CB2 `NOT_STARTED`
(optional, genuinely untouched); CB5/CB6/CB7/CB9 `BLOCKED_HARDWARE` and CB10 `BLOCKED_EXTERNAL`
(no parts arrived, no bench network — §E rows still ⏳); CB8 `IN_PROGRESS` (U4 still design-only and
gate-held); the Wokwi observation (re-verified as credential-blocked, not bench-blocked); real-iPhone
W2/W3 and the Windows real-OS matrix (no device, no non-isolated network); CB4's real-device leg (byte
fixtures only). Newly **closed** this pass rather than carried: CB1, CB3, the mDNS "NOT BUILT" line,
the GS "uncommitted WIP" claim, the audit §3 staleness, and the design-system "1 unpushed commit".
**Over-reporting open work is now the documented failure mode of this file — eleven instances:** the
nine audit findings, R05, R19, the `loopTask` watchdog question, this file itself, the design-system
"1 unpushed commit", the "Windows CI not re-verified" claim, the `~300 px` dead-column figure, CB1's
`NOT_STARTED` row, the mDNS "Windows side NOT BUILT" line, and — found *during* this pass —
`w17-3d-codex`'s "2 commits unpushed", which Codex had already pushed. **The `ipcSurface` retraction
above is the one instance that ran the other way** — inventing open work — and it is the more
dangerous direction, because nothing forces a recheck. Several of these were caught by sessions
*refusing to act on a stale instruction* rather than by this file being right. The eleventh is worth
the extra sentence because of **how** it was caught: the recorded hashes were re-checked against the
repos one by one before commit, and the `git ls-remote` disagreed with the local tracking ref. Cheap
mechanical verification beat careful reading of a confident instruction — which is the same lesson as
`ipcSurface`, arriving from the opposite direction.

2026-07-30: **Hardware delivery (owner) — arrival only, NO GATE CHANGE.** Four connector items
(XT90-S female anti-spark → XT60 male 12 AWG; XT90H-M male 12 AWG; XT60 female 12 AWG; JST-XH 2S
3-pin extension) plus a **wrong-size battery**. The connector items **close the last two §E lines** —
the XT90-S master switch and the XT60→XT90 adapter arrived as one two-piece pigtail set rather than
as two discrete parts, so the pack-side master chain is now fully sourced. They implement the
topology already drawn in `w17-pdb-build-and-connector-guide.md`; **no build-spec change is owed.**
The only end not delivered ready-made — an XT60 female on the XT90H tail — the **owner will make up
at the office** from §5 connector stock (2026-07-30), so no supplier line is outstanding.
- ⚠ **Corrected 2026-07-31 — read this before the paragraph below.** The 5200 is **the only battery
  that has ever arrived**. The "ZEEE 1500 mAh 2S LiPo" that the 07-29 entry below lists as delivered
  **never existed**: the owner's word *"one battery"* was mapped to the ordered 1500 line, and the
  order-spec dimensions were then recorded as if measured. **The car has no pack that fits it**, and
  sourcing one is now the top hardware line (`HARDWARE_INVENTORY.md`, which carries the full spec:
  2S, ≤75×45×25 hard / ≤70×40×22 target, soft-case, ≥25C, JST-XH). Quantity ×2 is convenience, not a
  gate — one pack makes the car drivable.
- **The battery is a wrong-size delivery, not a packaging decision to make.** The pack sent is a
  **ZEEE 5200 mAh at 138×47×37 mm** against the **≤75×45×25 mm** envelope of record — over on all
  three axes (+63 / +2 / +12 mm). `w17-3d-codex/BUILD_SHEET.md` had already ruled a *115*×35×24 pack
  won't fit the 2024 body, and the Z3 tub is only 14–40 mm wide where it is ≥45 mm tall. **Owner
  decision (2026-07-30): attempt a replacement, buy an in-envelope pack, and keep the 5200 as a
  BENCH supply only.** It is not a car pack and must not be treated as one in any CG or packaging work.
  (Said "a *second* 1500" as written on 07-30 — corrected 07-31: there is no first.)
- **No status in this file moves.** A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Bench use of the
  5200 is powered activity like any other — **still A2 + Phase B gated**, still no unattended
  powering, and its larger fault energy is a new bench-safety input rather than a cleared one. The
  XT60 female lead that just arrived has **no pack to terminate yet** (07-31 correction) — it waits
  for whichever car pack is sourced, and is only needed if that pack isn't XT60-native.
- Arrival detail and per-line mapping confidence live in `HARDWARE_INVENTORY.md` (the carve-out
  owner) — not duplicated here.

2026-07-29: **Hardware delivery (owner) — arrival only, NO GATE CHANGE.** The 2026-07-24 §E
electrical order landed almost complete, together with the last mechanical/consumable ⏳ lines from
the 2026-07-22 in-transit set. Owner's words: *"new smaller ESPs, 3 servos for gimbal and drs,
thermal paste, XT60 and XT30 connectrs, remaining shock observers, both capasitor packs, USB
charging boards and one battery."* Mapped to: MH-ET D1-Mini ESP32 (**3 on hand** vs ×2 recorded as
ordered), MG90S ×3 (pan/tilt/DRS), thermal paste, XT60/XT30 connector units, rear 68 mm oil shock,
ceramic + electrolytic cap kits, IP2326 charger (**2 on hand** vs ×1 recorded as ordered), and
~~ZEEE 1500 mAh 2S LiPo~~ — ⚠ **that last mapping was wrong and was corrected on 2026-07-31; no
in-envelope pack arrived, then or since. See the 07-30 entry above.** **Still in transit:** neodymium magnets (§7), Amass XT90-S master switch +
XT60→XT90 adapter (§E), Tamiya tyres (§B). Full arrival detail and per-line mapping confidence are
in `HARDWARE_INVENTORY.md` (the carve-out owner) — not duplicated here.
- **No status in this file moves.** **A2 stays NOT-EXECUTED, Phase B stays BLOCKED**; parts arriving
  is not powering, and the harness must still be built and A2 run first. CB5/CB6/CB7 stay
  `BLOCKED_HARDWARE` on their own blockers (camera bench, iPhone + non-isolated network, printed
  dry-fit) — **none of them was waiting on anything in this delivery** — and CB9 stays gated on
  A2 + Phase B. The no-unattended-powering rule stands. (This entry originally ended "the LiPo also
  still needs owner re-termination to XT60" — moot: **that pack never arrived**, per the 2026-07-31
  correction.)
- **What it does unblock is measurement, not power:** the MH-ET caliper + weight, the actual 1000 µF
  electrolytic, and the MG90S / rear-shock fit checks are now performable. Those are **`w17-3d-codex`
  inputs** and were not touched from here (one repo at a time; that repo is Claude-owned but separate).
- Note for the next bookkeeping pass: the 2026-07-27 staleness-audit paragraph above says
  *"no parts arrived … §E rows still ⏳"*. That was true as of 2026-07-27 and is preserved as an
  as-of statement per this file's header rule — **do not read it as current**.

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `3f4f9b7` (`main`) | **Row corrected 2026-08-16 (audit pass): `main` = `3f4f9b7`, PUSHED, level with `origin/main`; the F17/F18 closure is merged, and `docs/a2-revision-pass` + `docs/f17-f18-closure` are deleted. Native suite 229/229 + both ESP32 builds re-verified at this hash 2026-08-16. Everything after this sentence is as-of its own date.** **Corrected 2026-08-04 (consolidation pass):** local `main` is now **`d295f70`**, **ahead 8 of `origin/main` (`d102e2f`), UNPUSHED** — history linear, no merge commits. It absorbed, in order: the A2 adversarial review (`ac1f518` + owner decisions `fff1ab7`), the fast-forwarded `docs/sim-first-run` (`3eb7a66`, observed Wokwi run), a concurrent session's `dd9a445` (R16 disambiguation in the risk register + unlock plan), then `docs/a2-revision-pass` (`f48560c` checklist revision closing all 14 review findings, `0caf4e4` revision-pass closure table, `92f3b0d` F15/F16 closed + F17/F18 recorded + frame gate S0 → SF) and finally `docs/holdlast-premise-correction` (`d295f70` — the unlock plan's §2.3.11.1 input-provenance rule keeps its rule and loses its stale hold-last premise). **No branch is pending merge here.** `docs/a2-revision-pass` still exists as a ref only because it is checked out in another session's working tree; it is fully contained in `main` and carries nothing `main` lacks. The "level with origin" claim below is as-of 2026-07-30. Earlier state, as-of 2026-07-30: **On `main`, PUSHED, level with `origin/main`** (`8d0309e..d102e2f`, verified 2026-07-30). Three commits this pass: `e5abc20` (A2 restructured into staged build gates + the WS2812/link2-RX decisions + the two-part closure gate), `fa07690` (FIRST_ACTIVE I10 / R15 / input-provenance rule), and `c5c7d6f` (build-tag-only compile gate, R2 waiver removed, R16 promoted). The first three are **docs only in `project-review/`**. The fourth, `91f830f`, is the **first code change to `lib/channels` this pass** — implausible raw channel values now decode as *absent* rather than full deflection (see the 2026-07-30 decoder entry below). **Re-run at `91f830f` 2026-07-30: native `pio test -e native` 229/229** (was 225 — one test replaced by five), `esp32dev` + `esp32dev_tuning` + `esp32dev_sim` all build, `tools/link2_copy_check.sh --strict` exit 0 (its non-fatal doc tier reports `docs/link2_protocol.md` differs from the soundlight copy — **investigated 2026-07-30 and CLOSED as expected, not drift**: the only differences are two repo-local point-of-view prose blocks, exactly what the guard's two-tier design anticipates. **No normative drift** — frame layout, payload table, lengths, CRC, the 500 ms staleness rule, state matrix and worked example all match. The investigation did find a real doc defect, fixed in `d102e2f`: the reader note claimed everything from *Frame layout* onward was **byte-identical**, which is false — one of the POV blocks sits inside that region. Claim narrowed to what is true.) Live watchdog-cycle observation and physical reset-path validation still pending. The `docs/bom-cassette-electrical` branch problem is **resolved and gone**: `main` was fast-forwarded `fbf22f0 → 34eba89` (16 files, no merge commit) on 2026-07-25, so the electrical BOM (`78e1e88`, `1834852`) is on `main`; the redundant branch has been deleted local and on origin (verified absent 2026-07-27). Since then, the 2026-07-25 zero-hardware batch and this pass: CB3 comment fixes, owner decisions R05/R19, the R06 link2 drift guard, honest Wokwi run-status, then `d6395c8` (link2 doc: the cross-repo guard is enforced, not "not built yet"; control-fw-local statements marked for the receiver) and `8d0309e` (unlock plan: serial bump recorded as shipped at **v1.6.0**, and the false "push remains disabled" claim corrected). Firmware behaviour unchanged by any of it — docs + comments only. **Native `pio test -e native` 225/225** (was 224; +1 with the R06 guard), `esp32dev` + `esp32dev_tuning` + `esp32dev_sim` all build, `tools/link2_copy_check.sh --strict` exit 0 — all re-run 2026-07-27. Live watchdog-cycle observation and physical reset-path validation still pending. |
| `w17-ground-station` | `92cd894` | **Windows CI GREEN at this HEAD: run `30263115532` (2026-07-27)**, both the ubuntu `test` job and the windows-latest `package-smoke` job. Suite **1185/1185 across 59 files**; `proto:check` OK, `feel:check` OK; `noControlPath` + `ipcSurface` green at the pinned **24-key** preload surface. `main` level with `origin/main`, nothing unpushed. **The 7-file WIP recorded here previously is long since reviewed, split, and shipped** — do not read this row as carrying uncommitted work. The chain since `3119180`: `42319ad` (SETUP split out of SEAT FIT — five steps, `garage → pitwall → seatfit → setup → grid`, solo `garage → seatfit → setup → grid`, rail `01..05` with GRID = 05) · `e01eb9f` (HUD `.revwrap` viewport-centred, BATT above the merged pill row) · `0950298` (viewer-only footnote overlay removed — isolated deliberately so it was revertable alone) · `e09369b` (GRID `wide`, `#addrStatus:empty` reserve collapse) → CI `30128883953`; then `769003b` (viewer-only disclaimer **restored** in the ⚙ settings panel, once per app session) · `12896fb` (the four unasserted CSS rules pinned, `responsiveLayout` 22 → 26) · `7c29a6b` (audit annotated, 91 insertions / 0 deletions) · `16d3d0a` (**R01 implemented** — armed/failsafe labelled as simulated) · `9c2d723` (**`feelConstants` drift guard made real** — hermetic snapshot + `scripts/check-firmware-feel.js`) → CI `30144513077`, 1082/1082 in 56 files; then `17ec1be` (stale rail comments, own CI `30149835990`, branch deleted) · `2c96eb1` (SETUP → one centred column) · `1a6f9f2` (`#gamepadPanel` rhythm) → CI `30150690390`, 1090/1090 in 56 files, `responsiveLayout` 34; then `92a0dce` (CB1 closeout) · `92cd894` (**CB4** iPhone HUD mDNS discovery) → CI `30263115532`, 1185/1185 in 59 files. **All 9 findings of the 2026-07-17 setup-flow audit are CLOSED, and the audit's own §3 staleness is fixed too** (`7c29a6b`) — that artifact is no longer stale. Real-OS/Windows-hardware paths remain bench-unvalidated. |
| `w17-mapper` | `432a809` | owned fork (`w17-headtrack` off upstream `2b8031a`); CB8 slices 1–3A: LOG-ONLY UDP 5602 head-intent ingest + read-only gRPC diagnostics. **Row corrected 2026-08-03: it read `0e11d6b`, which had been stale since 2026-07-30.** Five commits landed since then, all on the stick/failsafe path, none touching head-intent or arbitration: `2dc7c5a` (**the hold-last fix** — a nan channel is driven to its configured failsafe instead of skipped; `GetInputGamepad` gates on the new `InputGamepad.Attached()` so a detached device stops resolving; transmitter arrays start centered, not zeroed; +294-line regression test file) · `53f4806` (GPL §5(a) modification table) · `d42a277` (embedded-schema guard around the new `failsafe` field) · `630ea96` (**send no channel frame at all when no config resolves**, so the receiver's link-loss failsafe can fire; `EvalNoData` demoted to display-only) · `5a28106` (GPL §5(a) table again). **Verified against source 2026-08-03 — see the dated closure entry: the throttle-freeze defect is CLOSED, with residuals A/B/C recorded there.** **Re-examined 2026-08-03 (later pass), still `5a28106`, nothing committed: RESIDUALS B and D re-derived from source and all four mechanisms REPRODUCED by execution; the pre-merge review's "six asymmetric node types" corrected to a full 27-type enumeration (14 D-1 stranders, 4 D-2, 1 pass-through) and its filing of the comparisons under D-2 corrected to D-1; B's cited seeding path corrected (it is `GetTransmitters()`→`NewTransmitter`, not unmarshal); B's reachability measured as explicit-user-action-only. B and D confirmed to be ONE change in `output_tx.Eval`. **Approach DECIDED 2026-08-03 (owner): option (c) — suppress frames across a config swap, as `630ea96` does for no-config — plus the stateless subtree walk (on the nan/invalid-`ch` path, collect the `InputChannel`s under the holder and drive each to its own `FailsafeValue()`), as ONE commit.** **✅ IMPLEMENTED 2026-08-03: `e452d55` (the fix, one commit) + `f81ec63` (GPL §5(a) table). B and D are both CLOSED with injected-regression evidence; the injections cover a top-level WRAPPER node, which is the shape the previous closure never built. One parameter the ruling did not specify had to be settled: the swap's no-frame window needs a LOWER bound (1 s, against the firmware's 500 ms `linkTimeoutMs`) or no failsafe fires and suppressing achieves nothing — the exact value is a bench item. Expect visible firmware failsafe on every Apply with the link up. `applyConfig` also now evaluates the synthetic transmitters before publishing them, closing an all-992 transient across every channel. RESIDUALS A and C remain open.** See the dated B+D entries.** **Updated 2026-08-04 → `9ba6e06`, closing the two findings the `e452d55` code review left open: `c60843e` (**D-partial** — the neutral is resolved per OWNER, so a channel that stops resolving is railed even when its holder still reports healthy, which `EvalOperation`, `and`/`or` and `EvalRelational` all allow by ignoring a nan operand; **D-3** — `channelOwnerMaxDepth` 32 → 256 *and* truncation made fail-safe via a new per-port `OutputTransmitter.Unresolved` flag the send loop suppresses on; the bound's false "read-cycle backstop" comment corrected and `TestReadCycleTerminates` renamed and re-scoped; 21 new tests, five injections proven to bite) + `9ba6e06` (GPL §5(a) table, and its date ordering fixed). `InputRead._Eval`'s unguarded recursion stays OPEN and out of scope — a pre-existing upstream crash, tracked in the dated entry.** **Updated 2026-08-04 (hook pass) → `432a809`, discharging the 2026-07-30 owed item: the pre-push hook's const-form blind spot was REPRODUCED (`const firstActive = false` exited 0) and then closed with a 4th case-insensitive `first_?active` check over the same code globs; the class-level limit it still cannot close (`const enableShaping = false` passes) is now documented in the hook header and `FORK-NOTICE.md`. Docs/hook only, no Go changed.** Tree clean. **Row corrected 2026-08-16 (audit pass): `origin/w17-headtrack` = `432a809` — PUSHED, level; the ahead-10/unpushed reading was as-of 2026-08-04. The push-review rule in `FORK-NOTICE.md` still governs every future push.** Earlier chain, since `59d1739`: `f0a18f3` (`go.bug.st/serial` v1.5.0 → **v1.6.0** — `go build ./...` now **fully green**, the go1.26 × cgo blocker cleared; **not** the approved v1.7.1, which would have bumped the `go` directive 1.20 → 1.25.0 in both `go.mod` and `go.work` and with it go1.22 loop-var semantics for the whole module — reasoning in `w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.12.9 item 2) · `8fc1915` (fork notice: provenance, GPL-3.0-or-later election, GPL §5(a) modification notice, safety boundary) · `0e11d6b` (tracked `.githooks/pre-push` + the written push-review rule). **⚠ "push disabled" is NO LONGER TRUE — do not rely on it.** The fork has `origin` = `github.com/beforethenexttolast/w17-mapper`, created 2026-07-25T04:11Z, **PUBLIC**, with `origin/w17-headtrack` carrying all of the above (`upstream`'s push URL remains disabled). The accidental "no remote, so push is impossible" protection is **gone** — and it was never a control, only an accident of setup. What replaced it: a tracked **`.githooks/pre-push`** (enable per clone with `git config core.hooksPath .githooks`; refuses a `w17_first_active` build tag, a `FIRST_ACTIVE` identifier in Go/proto, an active head-intent enum, or — since `432a809` — any case-insensitive `first_?active` identifier in code; verified 2026-08-04 to pass a clean HEAD and bite on **four** injections, with the fifth (`const enableShaping = false`) recorded as a documented miss rather than a silent one) as the **accident guard**, plus the push-review rule in `FORK-NOTICE.md` as the **control**. What is published distributes **no control path**: proto still ends at `ACTIVE_LOG_ONLY = 8`, no `FIRST_ACTIVE` in tracked Go or proto source, upstream licence files unmodified — re-verified read-only 2026-07-27. `go vet ./...` is **not** green and that is **not a regression** — see the same §2.3.12.9 item 2. |
| `w17-soundlight-fw` | `5919685` | **PUSHED, level with origin.** Through `ec5ddf8` (`4f25856..ec5ddf8`, 11 commits): audio-decision centralization, graceful audio-startup/runtime-write failure handling, wrap-safe engine effect timers, exact synth-smoothing convergence, signed engine inertia preserved, widened noise multiplication, low-battery period validation, UART0 diagnostics gated by firmware mode, README host-test count corrected 40→94. Then 2026-07-25: **`2d22f85`** (CI enforcement — see below) and **`5919685`** (link2 protocol-doc re-sync). Native **94/94 across 8 suites**, `esp32dev` + `esp32dev_sim` both build, canonical guard re-run exit 0. **`2d22f85` matters beyond bookkeeping:** this repo already had a `link2-drift` job (`74b59f4`) with a hand-rolled inline diff loop that treated `docs/link2_protocol.md` as **fatal** — so a control-fw doc edit turned soundlight's `main` CI **red for a non-bug**. Verified by replaying the old logic (flags the doc and nothing else, exit 1), not assumed. `2d22f85` replaces it with a single source of truth: the job anonymously shallow-clones control-fw into `$RUNNER_TEMP` (outside `GITHUB_WORKSPACE`, so the sibling never enters soundlight's source tree) and runs *control-fw's* `tools/link2_copy_check.sh --strict`. Exit codes fully disambiguated — 0 pass (plus a `::warning` when the doc tier reports, so the non-fatal tier is never invisible), 1 DRIFT, 2 COULD-NOT-CHECK, 3 CI-bug/usage, anything else unexpected. **Trap recorded in-file:** GitHub's default `bash -e` would collapse every exit code into one anonymous red X, so `set +e` is load-bearing and commented as such. Verified by watching it fail — the step's real `run:` body extracted from the YAML and run against throwaway fake siblings across **7 scenarios** (clean, injected `kPayloadLen`, deleted shared file, sibling missing `lib/link2`, checker absent, exit 3, exit 42). The doc re-sync was **one-sided, not three-way** (soundlight's copy was byte-identical with zero local content, so purely additive); upstream prose corrected to receiver POV. |
| `w17-design-system` | `26ec870` | **PUSHED, clean, level with origin** (verified 2026-07-27 — the earlier "1 unpushed commit" reading was itself over-reporting). `6a59c96` synced the shipped setup flow; then `d53e6c4` (§1/§2/§9/§11/§14 amendment — §11(d)'s pill-row merge is **not** a supersede: the mockup always drew one `.pillrow` and the app carried two, so the merge brought the *app to the bundle*; §11(e) records `.revwrap` as an intentional improvement, since in the mockup its position is residue of the RUSSELL-plate/clock widths plus `.top`'s `right:calc(var(--gap) + 3em)` ⚙ inset and so *cannot* be top-centre); then `1415686` (§11's OPEN DECISION → **§11(f)**, right-column order resolved toward the code — BATT → pillrow → ERS, `BOOST · OVERTAKE · DRS` — old table kept as canonical-vs-superseded, the GS test pin's "provisional" note corrected to a guard backed by a ruling; `screens/05-hud.html` reordered; new **§14(d)** single-column SETUP with (a)/(b)/(c) amended in place; the twice-superseded "Adoption path" entry removed with a dated parenthetical); then `26ec870` (the `~300 px` → **`~191 px`** dead-column correction at `DESIGN_NOTES.md:208`). |
| `w17-3d-codex` | `0386b2f` | **Row corrected 2026-08-16 (audit pass): pushed since — level with origin.** Earlier: **1 commit ahead of origin** (`0386b2f`, the 2026-07-27 ESC ground-truth correction — see the Codex item above; `2325fd9` and earlier are pushed). (`git ls-remote` 2026-07-27 shows `refs/heads/main` = `2325fd9`; working tree clean apart from ignored files). Prompt 13 recorded these as *2 commits unpushed* with `origin/main` at `ae42b5f`; Codex has pushed them since, so **that reading is stale — do not re-open it as owed work.** `59a1634` (2026-07-22) is the owed arrival-tracking cleanup (2 files, +48/−26; asserts no new physical facts). `2325fd9` is large (107 files, +20,130): fit studies, wire schedule + connection-joint register, ~7,000 lines of evidence generators, ~30 self-contained HTML visualisations, a 1,135-line manual expansion. **Inspected read-only 2026-07-27; not edited, not pushed** (Codex-owned). It asserts **no unearned hardware facts** — checked specifically: the `*_output_validation` PASS tables validate *generated artifacts* ("HTML exists", "inline-only CSP present", "link resolves"), **not physical parts**, despite commit subjects that read like hardware validation; where it does touch hardware the hedging is disciplined (VERIFIED / DERIVED / DOCUMENTED / ASSUMPTION per row; "Physical scales own the result"; "NO PRINT AUTHORIZATION — GATE P1 NOT PASSED"; MG90S official dimensions "do not prove the purchased clones"). **One real inconsistency, flagged not fixed — see Open Codex items below.** Nothing sensitive blocks a push (no credentials, keys, tokens, prices, order numbers, or binaries); one minor item: `p0_d36_wire_schedule_validation.md` adds three lines carrying the absolute path `/Users/vitaliykhomenko/…`, a small deanonymisation vector against a pseudonymous account — near-zero marginal exposure, since `01_inventory/build_inventory.py` already contains it and is already public, so it blocks nothing but is trivially relativisable. |
| `iPhone_rc` (Codex) | `84532ed` | VR FPV plan consolidation (H1–H11 applied; canonical contract sync revision); Batch 1 VR-calibration work remains uncommitted in its working tree |
| `w17-rc-print-codex` (Codex) | `75b408c` | has existing untracked reports |

> Checkpoints drift as work continues. Re-verify with `git -C <repo> rev-parse --short HEAD`
> before relying on any hash here.
>
> `CURRENT_STATUS.md` may record hashes for other repos, but should not try to record the
> exact hash of the repo that contains it (that would go stale on every commit that touches
> this file).

## Hardware gates

- **A1.1–A1.6 software / pre-power validation: COMPLETE.**
- **A2 no-power bench checklist: NOT EXECUTED, and RESTRUCTURED 2026-07-30.** No measurements
  recorded; A2 is not closed. Canonical checklist:
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`.
- **Why A2 has not run — corrected 2026-07-30.** Previous revisions of this file left A2
  reading as owner-owed bench work. It is not: **nothing is soldered** (owner-confirmed
  2026-07-30 — the ESP32 boards arrived with pre-soldered pin headers, and the 3D-printed
  parts on hand are test/measurement-quality prints, not build parts). A2 as written assumed a
  finished harness, so there was nothing for it to measure. There is **no untracked assembly
  gate and no A1.7** — the restructure below makes A2 *be* the build order.
- **A2 is now staged, not a single pass** (2026-07-30, revised 2026-08-04). The gates run on
  isolated subassemblies as the harness is built — **SF PDB frame** (XT60 + star + ESP32
  sockets + rail looms, plus the pre-S6 rail isolation rows) → S1 divider → S2 Hall (incl.
  H1b, hard-stop 8's generating row) → S3 link2 → S4/S4b CRSF + actuator leads, isolation
  matrices, boot-float PD1 record (**S8a, the at-the-cut half of the ESC red-wire hard gate,
  executes here — before insulation**) → S5 WS2812 → S6 batt+ consumers (UBECs + ESC 12 AWG
  feed + C1, in one sitting) → **S7 whole-harness composite** (grounds G1–G14 + batt+/rail→GND
  screens + master-switch pigtail + ESC power-feed rows; reference is the PDB input XT60 −
  pin, harness-side, no battery) → S8b ESC red-wire final. **Driver for the change:
  several expected values are only valid while the subassembly is isolated** — the worked case
  is the divider's `batt+ → GND ≈ 37 kΩ`, which after S6 is measured in parallel with two UBEC
  input stages and would false-FAIL a correctly-built car against the old §13 hard stops. The
  2026-08-04 revision makes the single-shot property an explicit rule (checklist §3 rule 4)
  and maps every §13 hard stop to its generating rows.
- **Two A2 decisions taken 2026-07-30** (both previously unfalsifiable "per your build" rows
  that made the old PASS criterion unsatisfiable): **WS2812 supply = option A, the 1N5819
  diode** (on hand; no 74AHCT125 in inventory or BOM v2; 74AHCT125 stays the documented
  fallback — recorded honestly as a ~10 mV nominal V<sub>IH</sub> margin), and **link2 RX
  (GPIO26) = do not wire**, since the firmware hard-disables it (`Serial1.begin(..., rxPin=-1,
  txPin_)`); the row is now falsifiable as "verify no wire present."
- **A2 adversarial review 2026-08-03 — found A2 unsafe to execute as written; the owed
  revision pass is DONE 2026-08-04 and has since MERGED to both `main`s** (consolidation pass,
  2026-08-04 — `w17-control-fw` `d295f70`, workspace `1b54767`). The review (14 findings,
  13 CONFIRMED / 1 PLAUSIBLE, merged to both mains): no post-S6 batt+→GND / rail-isolation
  screens (§13 stops 1 and 4 had no generating rows), S8 E1–E3 unexecutable-as-sequenced and
  unfalsifiable as built (+ ESC red→GND unmeasured), S7 reference point nonexistent on hand,
  gate order contradicting the PDB guide §5, old A2.5 (GPIO13/14 boot-float pull-downs, R04)
  dropped without a record-either-way row. Full findings:
  `w17-control-fw/project-review/14_a2_staged_gates_adversarial_review.md`, which now also
  carries the **revision-pass closure table** (finding → change → where), **two new register
  entries F15/F16** found during the revision, and the deliberate non-closures. The revision
  lived on branches `docs/a2-revision-pass` (control-fw: checklist + plan §A2 + register;
  workspace: PDB guide + this file), **both now merged to `main`.** The "until those branches
  merge, the `main` copies remain do-not-execute" caveat this entry carried is therefore
  spent — **but the checklist and guide are do-not-execute anyway**, for the reason that never
  depended on the merge: **A2 is NOT-EXECUTED and Phase B is BLOCKED.** Still OWED to the bench before SF's first
  joint (F12, deliberately not closed on paper): the MH-ET adjacency re-derivation and the
  socket-height caliper vs the ZK "S0" ≥ 9.82 mm clearance. Neither the review nor the
  revision changes any gate state. The later closure pass closes F15/F16, adds **F17/F18** to
  that register **and applies their fixes in the same edit**, and renames the frame gate
  **S0 → SF** (`S0` = the ZK clearance only). A **third closure pass**, same day, writes the
  F17/F18 closure rows that pass omitted — records the omission as **F19**, since the workspace
  record's "recorded, not quietly fixed" read as *not fixed* and cost a session — and records
  **F20**, open and deliberately not fixed: **S1r's matrix covers the five actuator signals
  only, so a GPIO34 ↔ GPIO35 bridge is caught by no row.** Open in the register at that point:
  F12's two measurements, F20, and the unwritten charge-path gate.
- **Four A2 owner decisions taken 2026-08-03** (recorded in review doc 14, implemented by the
  revision pass; moved here per that doc's note now that its branch has merged):
  **F9a** — the IP2326 charger is **NOT fitted during A2 build week**; the charge path owns
  its own (not-yet-written) no-power gate. **F9b** — the charge tap is **PACK-side of the
  XT90-S master switch** (keeps the pull-the-master charge interlock real); the IP2326 comes
  off the PDB entirely. **F11** — the Hall 10 kΩ pull-up lives **at the ESP32 #1 end**, where
  3V3 exists (checklist row H1b is hard-stop 8's generating measurement). **F12** — the MH-ET
  boards are **SOCKETED** (female headers on the PDB) — ⚠ conditional: the socket-stack
  height has never been calipered against the ZK "S0" ≥ 9.82 mm cassette clearance; if that
  measurement fails, the decision reopens and the boards go hard-wired (checklist §3 rule 2
  states the fallback).
- **A2 closure is a two-part gate (2026-07-30).** Part 1 = reviewer check (completeness, gate
  attribution, tolerance, cross-reference, **plus mandatory direct inspection of the §10
  photos** — the one part that is independent observation rather than trust in transcription).
  Part 2 = owner attestation that the measurements were physically performed. **A2 closed means
  the record is complete, coherent, and photo-corroborated — NOT that the hardware is safe.**
  Opening Phase B is the owner's call, informed by A2, not a reviewer verdict.
- **Phase B (powered) is BLOCKED** until A2 is filled in, pasted back, reviewed, and approved.
  Battery reality (corrected 2026-07-31; the stale lines that stood here were the same F5
  class the checklist carried): **no in-envelope car pack exists** — the recorded 1500 mAh
  ZEEE never arrived, and the only pack on hand is the out-of-envelope 5200, bench-only
  (`HARDWARE_INVENTORY.md` §E). The XT90-S master-switch pigtail set **arrived 2026-07-30**.
  S7's reference is now **harness-side** (PDB input XT60 − pin — revision F5), so A2 itself
  depends on no battery existing at all; the owner-made XT60 tail joint is tested at S7
  (CP1–CP3), a hard precondition to the first pack connection if recorded NOT-ASSEMBLED.
- Golden rule: ESC motor power stays disconnected until the failsafe + arm chain is proven
  live (Phase A → B).

## Firmware freeze status

- **CF-1 delivery tuning persistence: RESOLVED.**
  - Delivery `esp32dev` loads the complete validated NVS settings object at boot.
  - Missing, corrupt, outdated, or invalid settings fall back atomically to complete compiled defaults.
  - Tuning console and settings mutation remain available only in `esp32dev_tuning`.
  - Native tests: **153/153 passing**.
  - `esp32dev`, `esp32dev_tuning`, and `esp32dev_sim` build successfully.
  - Physical NVS save → power-cycle → reload: **VALIDATED 2026-07-22** on 3× ESP32-D0WD-V3 DevKit
    (bare-board smoke test) — a fresh distinct write survived an EN reset and reloaded through the
    guard chain on every board. The **reflash-survival** leg (save → application reflash → reload)
    remains an optional powered-bench item (not yet exercised).
- CF-2 steering endpoint tuning: RESOLVED.
  - `steer.min` and `steer.max` are available in `esp32dev_tuning`.
  - Endpoint updates are atomically validated and persisted through the existing settings blob.
  - The settings layout and blob version remain unchanged.
  - Delivery `esp32dev` remains console-free.
  - Native tests: 168/168 passing.
  - All ESP32 environments build successfully.
  - Actual endpoint values remain Phase-B hardware calibration evidence.
- Console parsing hardening: COMPLETE.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - Native tests: 195/195 passing.
  - All ESP32 environments build successfully.
  - Delivery and simulation remain console-free.
- **Control-firmware software remediation through R5-b: COMPLETE.**
  - Delivery loads validated NVS tuning while remaining application-console-free.
  - Steering minimum and maximum endpoints are configurable in the tuning build.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - The Arduino `loopTask` is directly subscribed to the global Task Watchdog with a
    provisional 2-second timeout.
  - The watchdog is fed exactly once after each completed 50 Hz actuator-control tick.
  - All watchdog API failures are handled fail-fatally.
  - RTC-retained reset diagnostics classify every reset reason in the pinned ESP-IDF
    version.
  - Tuning and simulation builds print the boot reset reason and retained-session count;
    delivery remains silent.
  - Native tests: **225/225 passing** (was 224; +1 with the R06 link2 drift guard). Re-run 2026-07-27.
  - All ESP32 environments build successfully.
  - **Live Wokwi stall → watchdog panic → reboot observation: PENDING — `[OWNER/tooling]`,
    NOT hardware-blocked.** Retagged from `[HW]` 2026-07-25, and the distinction is the point:
    `esp32dev_sim` **builds but has never been run**, and what blocks the run is a **Wokwi
    credential** (`wokwi-cli` absent, `WOKWI_CLI_TOKEN` unset), not the bench. Every route
    uploads the firmware to Wokwi's servers, so it is an owner decision, not an A2/Phase-B gate.
    The stall injector already existed (`W17_SIM_WDT_STALL`; marker present once in the stall
    ELF, absent from all three shipping envs) — nothing was owed there.
    `w17-control-fw/SIMULATION.md` leads with a run-status table, **every box unchecked**.
    **Nothing has been promoted to PASS; the 2 s TWDT timeout stays provisional.**
  - Physical reset reason, RTC retention, panic/reboot-to-safe-output timing,
    GPIO13/GPIO14 reset state, and real ESC signal-loss behavior remain Phase-B evidence.
    (POWER_ON reset-reason path + `retained=no` fresh-session behavior confirmed on real
    hardware 2026-07-22 across 3 boards; crash-class classification, RTC counter increment,
    reboot timing, GPIO state, and ESC behavior remain.)

## VR-FPV batch status (Claude side)

Batch definitions + session prompts: `VR_FPV_MASTER_PLAN.md` (stable). Update this table
at the end of every VR-FPV session; one-line evidence only.

| Batch | Name | Status | Evidence / blocker |
|---|---|---|---|
| CB0 | Mapper feasibility investigation | `DONE` | 2026-07-14: upstream `elrs-joystick-control` (`2b8031a`) read read-only in `_vendor/`; unlock plan §2.3 = verified findings (no UDP/plugin/virtual-axis ingest — fork needed; diagnostics republish already exists over gRPC; minimal-fork shape + dual GPL/Fair-Source license documented); decision package + options (a)/(b)/(c) presented → **owner decision #1 now actionable** (topology + fork ownership + fork license) |
| CB1 | GS right-stick indicator | `DONE` | 2026-07-25: this row was STALE — the batch actually shipped **2026-07-16** with the SEAT FIT slice (`renderer/padPreview.js` draws both stick wells with live `data-stick` dots fed by `setupFlow.js` seatfitTick; captions `RIGHT STICK · PAN / TILT` + `CAMERA · STICK INPUT`; `test/padPreview.test.js` rewritten to pin the relaxed boundary; recorded in `docs/camera_aim_display_semantics.md` §5). Closed out at GS `92a0dce`: invariant recorded in the repo `CLAUDE.md` guardrails + stale `inputPresets.mjs` comment corrected. Display-only; `noControlPath` unchanged |
| CB2 | Gimbal explainer artifact | `DONE` | 2026-08-04: `w17-camera-aim-explainer.html` at the workspace root (owner picked root over `w17-control-fw/project-review/` or `w17-ground-station/docs/` — it spans three repos, and it sits beside the only precedent, `w17-steering-servo-fit-diagram.html`). Self-contained, inline CSS/JS, **zero external references** (grep-confirmed); W17 colour vocabulary + corner-cut shapes per `w17-design-system/DESIGN_NOTES.md` §6. Draws both paths (iPhone → UDP 5602 → `pkg/headintent` → `WatchHeadIntentDiagnostics` → GS chip, vs sticks → CRSF ch9/10 → `ChannelDecoder` 8/9 → `ServoOutput` → GPIO19/23) with the **gap between them drawn as a gap**, carrying the `pack_deadend_test.go` byte-identity proof; all 9 enum states with the `ACTIVE_LOG_ONLY = 8` wall (`server.proto:527`); 300 ms log-only vs the design-only ≤250 ms active gate incl. the 251–300 divergence band (marked `[I]` — derived, not quoted); the two-part FIRST_ACTIVE flag and R1–R16 at **NO-GO / BLOCKED**. Verified 375 / 691 / 1280 px in both themes: no page-level horizontal scroll, wide blocks scroll in their own containers. **Display-only — changes no gate, no status, no code path**; A2 still NOT-EXECUTED, Phase B still BLOCKED, W3 still LOG-ONLY |
| CB3 | Firmware comment hygiene | `DONE` | 2026-07-25 in `w17-control-fw`: the anchor had **drifted one line** — the real target was `ChannelDecoder.hpp:58`, not 57-58. Also retired a vacuous `PinMap.hpp` comment by naming the real declared-but-unwired `kBoard2UartRxPin` (`Serial1.begin(..., rxPin=-1, ...)`). Comments only; no behaviour change |
| CB4 | Windows mDNS discovery | `DONE (real-device validation PENDING)` | 2026-07-25 at GS `92cd894`: `_w17hud._udp.local.` discovery — `shared/dnsWire.js` (wire codec) + `shared/hudDiscovery.js` (contract policy) + `main/HudDiscovery.js` (node:dgram transport); **no new dependency**, **no new IPC/preload key** (rides `setup:addr-hint`; preload still 24). Advisory hints only: offered on the PIT WALL chip, filled only on an explicit click, GRID ping still ground truth; demand-driven (queries only while PIT WALL is active, never under `W17_WIFI_SIM`). Hardened against hostile multicast (bounded name decompression, capped counts/labels, sender/address match, TTL-0 goodbye retires the entry); query sent out every local IPv4 interface (multi-homed bench host). 1185/1185 in 59 files; proto:check + feel:check exit 0. **PENDING: no iPhone observed — byte fixtures only**; `smoke:electron` unverified locally (macOS Gatekeeper), relies on Windows CI. Residual limits in `docs/proposals/iphone_mdns_discovery.md` "As built" |
| CB5 | Video baseline verification (Windows) | `BLOCKED_HARDWARE` | needs camera; pairs with Codex Batch 0 |
| CB6 | Real-device W2/W3 validation | `BLOCKED_HARDWARE` | needs iPhone + non-isolated bench network |
| CB7 | Placement decision support | `BLOCKED_HARDWARE` | needs printed halo/body dry-fit; owner decision #4 |
| CB8 | Mapper implementation | `IN_PROGRESS` | decision #1 RESOLVED (topology (a), §2.3.7). **Slice 1 DONE 2026-07-15:** `w17-mapper` fork (`w17-headtrack` @ `2b8031a`, GPL-3.0) — new pure-Go `pkg/headintent` log-only UDP 5602 ingest + in-process diagnostics; go build/vet/test/-race all green; `go list -deps` proves no config/link/crossfire/serial dep; no existing file imports it (output unchanged); 299/300/301 + port-exclusivity proven. **Slice 2 DONE 2026-07-15:** `cmd` wired behind disabled-by-default `-headtrack-ingest`/`W17_HEADTRACK_INGEST` (+`-headtrack-port`) — starts receiver and nothing else; `pack_deadend_test.go` proves `crsf.PackChannels` byte-identical flag-off vs on (valid/stale/invalid); host `go build ./...` blocked only by pre-existing go1.26×`go.bug.st/serial` cgo incompat (temp `v1.7.1` bump builds green, reverted — send-path dep = owner decision). **Slice 3A DONE 2026-07-15:** mapper-side gRPC diagnostics — read-only `WatchHeadIntentDiagnostics` stream (enum state, server-computed age, 4-stream cap→ResourceExhausted, nil→Unavailable, bounded latest-value buffers); stubs regenerated with pinned drift-checked toolchain via `pkg/proto/generate.sh`; `go build`/`test ./...` green, webpack compiles; CRSF byte-identical with subscribers connected/slow/disconnected; :10000 still `[::]` (unchanged). **Slices 1–3A COMMITTED 2026-07-15** in `w17-mapper` @ `59d1739`. **Slice 3B DONE** (GS Electron subscriber @ `03f43e2`). **Slice 3C DONE 2026-07-15** (GS @ `dce91f8`): hermetic proto-drift guard (`test/protoDrift.test.js` vs a live-mapper-generated canonical snapshot, regen zero-diff, bites on drift) + real cross-process run vs live mapper gRPC :10000 (every HeadIntentState, ingest-off→UNAVAILABLE, 4-cap→RESOURCE_EXHAUSTED, restart→bounded reconnect, byte-identical CRSF, topology-(a) mutual exclusivity); GS 746/746; validation-only serial bump reverted (modules pristine). Evidence: `w17-ground-station/docs/2026-07-15_cb8_slice3c_integration_evidence.md`. **Slice U4 DONE 2026-07-15 (DESIGN ONLY, SAFETY-GATED):** shaping/arbitration model + 9 safety invariants + Group A/B/C test matrix + two-part FIRST_ACTIVE flag + FIRST_ACTIVE review checklist R1–R14 written to `head_tracking_unlock_plan.md §2.3.11`; **no code** (deliberate — gated behind the review), `w17-mapper` clean at `59d1739`, no active enum value, PackChannels byte-identity + GS 746/746 + proto:check unchanged. Next (GATED): **first U4 implementation slice — only if/after FIRST_ACTIVE review approved** |
| CB9 | Gimbal endpoints + console | `BLOCKED_HARDWARE` | HARD GATE: A2 + Phase B; needs CB7 mount |
| CB10 | Integration + bench milestone | `BLOCKED_EXTERNAL` | needs CB8, CB9, Codex Batches 5–7, FIRST_ACTIVE review |

**2026-07-30 — FIRST_ACTIVE gate strengthened: I10 + R15 + an input-provenance rule** (adversarial
review of the §2.3.11.6 checklist; documentation only, no code). The gate had a hole: **nothing in
R1–R14, I1–I9, or Groups A/B/C/D covered the *gamepad itself disappearing*.** D15 tests deadman
*release* (a value transition); the Group D "Disconnect/reconnect" row is about the **iPhone/UDP
5602** stream. Device *disappearance* was never distinguished from value *release*.

**The defect that made it matter was confirmed present in the fork**, traced 2026-07-30 — **and
has since been FIXED; the paragraph below is kept in the past tense as the record of why the
rule exists, not as current behaviour** (premise corrected 2026-08-04, consolidation pass, in
step with `w17-control-fw` `d295f70`):
`pkg/config/input_button.go:77` returns `nan=true` when the gamepad is absent from the device
registry, and `pkg/config/output_tx.go:43` does `if nan || ch < 1 || ch > 16 { continue }` over a
**persistent `*[16]util.CRSFValue` struct field that is never reset to neutral at the top of a
tick** — so `continue` means the channel **retains its previous tick's value indefinitely**. Hold-last
semantics at the channel level. Failure it would produce: deadman held in `ACTIVE`, gamepad drops,
the deadman channel **latches**, head intent still fresh/centered/enabled ⇒ arbiter reads
`armed == true` and stays ACTIVE; the C1 right-stick override is dead too (same frozen array). Added:
**I10** (device loss ⇒ disarm, identical to release), **R15** (demonstrated by physically unplugging,
from `ARMING`/`ACTIVE`/`OVERRIDDEN`, reconnect proves no restore), **Group D rows D19–D22**, and an
**input-provenance rule in §2.3.11.1** — the arbiter must source arm/deadman/override from a signal
carrying explicit validity, never from the channel array, **which carries no validity of its own**.
R15 is hardware-*procedure* class, **not** Phase-B class. Overall FIRST_ACTIVE verdict unchanged:
**NO-GO / BLOCKED**.

**⤴ Premise corrected 2026-08-04 (consolidation pass), matching `w17-control-fw` `d295f70`.** This
line read "never from the **hold-last** channel array" until now. The rule is unchanged and still
binds; only its justification moved. Hold-last in the mapper's channel assembler is **gone** —
`2dc7c5a` drives a `nan` channel to its configured failsafe instead of skipping it, `e452d55`
resolves the neutral per owning channel node and suppresses frames across a config swap, and
`c60843e` makes neutralization per-owner with a fail-safe truncated walk. The rule survives on a
premise the fix does not touch: **the array carries no validity channel**, so a stale slot now reads
as its configured failsafe — by default **992**, exactly what a live centred control reads. Neutral
is not valid. Two consequences stay open and are **not** closed by the fix: switch channels still
latch downstream (992 normalizes to 0, inside the firmware's ±250 dead band, so `decodeSwitch`
holds — **RESIDUAL A**, config-class), and the mapper still transmits at full rate on input loss
(fail-to-neutral, not fail-silent), so the firmware's radio-loss failsafe still does not fire on a
gamepad dropout. **R15 remains NO-GO** — it demonstrates device-loss disarm against the real SDL/OS
removal path, which no unit test covers and which this fix was never claimed to establish.

**⚠ Related pre-existing defect, outside CB8's scope — RAISED HERE 2026-07-30, FIXED the same day at
`w17-mapper` `2dc7c5a`, and INDEPENDENTLY VERIFIED AGAINST SOURCE 2026-08-03 (see the closure entry
below).** The same hold-last behaviour affected **every** gamepad-driven channel, **including throttle
and steering**, with no head tracking involved. A USB gamepad dropout while driving through the mapper
froze the last throttle command, and **the firmware's failsafe did not fire** — this is not radio loss,
the mapper kept transmitting well-formed CRSF at full rate with stale payload (link up, CRC valid,
throttle frozen). Sits directly under the "failsafe first" priority in `w17-control-fw/CLAUDE.md`.
The two residuals this entry deliberately recorded as untraced are both now **traced and answered** —
`AlertDeviceChan` does *not* invalidate the config or zero the array, and `EvalNoData` no longer
reaches the wire at all. **The end-to-end outcome is no longer PLAUSIBLE: it is CONFIRMED, and the
throttle/steering half is CLOSED.** Three residuals of the *fix* remain open — see the closure entry.

**2026-07-30 (same pass) — two more FIRST_ACTIVE gate corrections, checklist now R1–R16.**

- **§2.3.11.4's compile-time "or" RESOLVED to the Go build tag, exclusively; the `const`
  alternative DELETED rather than kept as a fallback.** It was not a stylistic fork — the
  const branch **silently disarms the shipped accident guard.**
  `w17-mapper/.githooks/pre-push` (enabled here, `core.hooksPath = .githooks`) scans code for
  exactly two literals: lowercase `w17_first_active`, and the uppercase word `FIRST_ACTIVE`.
  The doc's own suggested `const firstActive = false` matches **neither**, so arbiter code
  gated that way would pass both checks and reach a **public** remote. Also recorded: a build
  tag makes the branch *absent* (assertable by symbol absence, and A3 now requires that); a
  const makes it *eliminated* and flippable by one character, so I3's "physically cannot" was
  only true of the tag. **Naming contract:** the tag must be lowercase `w17_first_active`
  exactly, because that is the literal the hook greps. **✅ DISCHARGED 2026-08-04 in `w17-mapper`
  `432a809`** — the miss was reproduced first (`const firstActive = false` exited 0), then the
  hook was widened with a 4th case-insensitive `first_?active` check and the residual class-level
  limit documented. See the 2026-08-04 (hook pass) entry below.
- **R2's blanket "or explicitly deferred with recorded owner sign-off" DELETED.** It was a
  waiver route around items carrying no waiver of their own — six of the seven
  `iphone_pan_tilt_firmware_readiness.md §8` blockers are independently mandated elsewhere
  (1→R7, 2→R12+R13, 3→design §2.3.11.2 item 6 + R4, 4→C1/C2, 5→R9, 6→R8), so deferring one
  under R2 could read as overriding the R-item that requires it. R2 is now cross-references
  with **no independent evidence obligation and no waiver**. Blocker 7 — the bench-only servo
  sweep, wheels off, observer present — had **no** backstop and is promoted to **R16**, no
  waiver clause, gated behind R6 (Phase B). New **precedence rule**: a deferral under any
  R-item cannot waive an obligation another R-item states independently; where two overlap,
  the stricter governs.

Overall FIRST_ACTIVE verdict still **NO-GO / BLOCKED**; open items are now R1/R2/R6–R9, R12,
R13, R15, R16.

**2026-07-30 — `lib/channels` decoder fix at `91f830f` (CODE, not docs): implausible raw channel
values decode as ABSENT, not full deflection.** The receiving half of the mapper hold-last defect
above, found by tracing `EvalNoData = {0,…,0}` into the firmware. `normalizeRaw(0)` computed
`(0−992)×1000/820 = −1209` → clamped to **−1000**, so an all-zeros payload made **every analog
control read full negative deflection** inside a well-formed, CRC-valid frame: **steering to full
lock**, pan/tilt driving both gimbal servos to their endpoints — and **failsafe never fired**,
because the link was up and the frames were valid. Only the **arm gate** saved the drivetrain (arm
decoded −1000 → below `switchOffBelow` → OFF → throttle neutral). **Steering had no such
protection.** Fixed by splitting two cases that the single clamp conflated: inside 172–1811
normalize; outside but within a plausibility band (`kChannelRawPlausibleMin/Max` = 100/1900) clamp
to the endpoint, since an expanded-endpoint TX really did mean full deflection; outside that band
decode as **absent** (analog 0 / switch OFF / tri-state 1), reusing semantics the decoder already
had for an out-of-range channel *index* but which no bad *value* could reach. The switch path
**forces OFF rather than falling through to hysteresis** — load-bearing, since a neutral 0 sits
inside the dead band and would HOLD the previous state, meaning a garbage payload could not disarm.
Frame-level rejection deliberately **not** used: one bad channel must not escalate into a link
dropout. **The 100/1900 thresholds are PROVISIONAL** — the mechanism is the fix, the values are not
yet bench evidence; confirm against the real TX during Phase B endpoint calibration. Evidence:
native **229/229** (was 225; the old `test_normalization_clamps_out_of_range_raw` asserted the
superseded behaviour — its own comment named the zero-initialized frame case — and is replaced by
five tests), all three ESP32 envs build, link2 guard exit 0. **Does not close the mapper-side
defect**, which is separately tracked.

**2026-07-30 — mapper channel-node config findings (INVESTIGATION ONLY; no code, nothing
committed in `w17-mapper`, whose tree stays clean at its then-current `5a28106` head).** A session tasked with
setting `failsafe: 172` on the switch-like channels of the live mapper config found first that
**no persisted mapper config exists on this Mac in any form**, and then two defects that bite
*before* failsafe ever matters.

- **There is no config to edit.** The webapp keeps the live graph in **browser localStorage**
  only (`webapp/src/components/misc/storage.jsx`); it becomes a file only on an explicit
  save-to-file (`config-access-base.jsx:63`, `<key>-<UTC>.json`), and the Go side reads a file
  only under `-config-file-path`. Searched and came up empty: `~` by name glob and by content
  (`crsf_max`, `inputs_config`); **Chrome localStorage enumerated — 37 origins, no `localhost`
  or `127.0.0.1` at all**, so the webapp has never been opened in Chrome here; Safari/WebKit
  nil; no Firefox profile; `w17-ground-station` + `Electron` localStorage empty; no mapper
  launch in shell history. The repo carries only `default-config.json` (the Home/telemetry
  graph) and `mock-device-fields.json`. **Owner decision: the graph will be built in the UI by
  hand and NOT committed** — the `read` nodes bind to a gamepad device id not visible from this
  Mac, so a committed config would be guesswork, and `630ea96` already made "no config" the safe
  state (no frames → the receiver's own link-loss failsafe fires). An unverified tracked config
  would replace that safe state with a wrong one.
- **DEFECT 1 — default channel endpoints fall outside the firmware's plausibility band, so full
  deflection decodes as ABSENT.** `ChannelT.UnmarshalJSON` defaults `crsf_min`/`crsf_max` to
  `util.CRSFMinValue`/`CRSFMaxValue` = **0 / 1984**, and `util.MapRange` clamps to exactly those.
  A full-scale input therefore emits raw **0 or 1984** — both outside
  `kChannelRawPlausibleMin/Max` = **100 / 1900** established by `91f830f` above — so the decoder
  reads the channel as absent (analog 0 / switch OFF). A button's ON value is
  `DefaultTruthyRawValue` = `MaxRaw` = 32767 → 1984 → **implausible → arm forced OFF: with
  default endpoints the car can never arm**, and analog extremes read *centered* rather than full.
  The two halves were written against each other's assumptions: `91f830f`'s band was sized to
  catch "the degenerate 11-bit extremes (0 and 2047)" and did not anticipate the mapper's own
  default endpoints landing there. **Config fix: `crsf_min` = 172, `crsf_max` = 1811 on every
  channel node** (then full deflection lands on the CRSF anchors and normalizes to exactly
  ±1000). Firmware needs no change; the band stays PROVISIONAL pending Phase B calibration.
- **DEFECT 2 — a button-fed switch channel sits at CENTER when OFF, i.e. hold-last on the LIVE
  path.** With the default `raw_min`/`raw_max` = −32768/32767, a button's OFF value
  (`DefaultFalsyRawValue` = 0) is mid-range and maps to ≈**991** — inside the decoder's
  ±250 dead band, so `decodeSwitch` **holds the previous state**. Same failure class as the
  `2dc7c5a` failsafe gap but reachable with the gamepad fully connected. **Config fix: make OFF
  reach the channel's `raw_min`** — either `raw_min` = 0 on the channel node, or
  `inactive_value` = −32768 on the button node.
- **Per-channel failsafe values** (the original task): **172** on the six `decodeSwitch`
  channels — **ch5 arm, ch6 DRS, ch7 gear-up, ch8 gear-down, ch11 boost, ch12 overtake**; leave
  the **992** default on the analog channels — **ch1 steering, ch3 throttle** (note: throttle is
  `throttleIndex = 2` → ch**3**, not ch2), **ch9 pan, ch10 tilt**. **ch13 drive mode keeps 992**
  even though it is switch-like: it decodes through `decodeTriState`, not `decodeSwitch`, and
  center → `1` = RACE, which that code calls the safe middle; 172 would instead force TRAINING
  on a dropout. The failsafe value bypasses `MapRange` (`output_tx.go:92` writes it straight
  into `Values`), so 172 goes on the wire as raw 172 regardless of the endpoint fix above.
- **PREREQUISITE (added 2026-07-30) — the firmware channel map is itself unverified, so every
  ch-number above is conditional.** `ChannelMapConfig`'s indices are labelled placeholders in
  `w17-control-fw/lib/channels/include/channels/ChannelDecoder.hpp:10-12` ("DEFAULTS ARE
  PLACEHOLDERS … verify every assignment at the bench and remap HERE only"). The table above is
  correct *relative to the firmware's current map*; confirm the TX assignments at the bench
  **first**, or the 172s land on the wrong channels. Two supporting checks done the same pass:
  raw **172 → −1000** (`normalizeRaw` is exact at the anchors 172/992/1811), well below
  `switchOffBelow` = −250, so 172 is unambiguously OFF and not a dead-band value; and there is
  **no per-switch inversion** in the firmware — the header calls it a deliberately deferred
  extension point, and `invert*` applies only to `normalizedAnalog` — so nothing on either side
  can flip 172 into ON.
- **UI trap:** the `crsf` autocomplete offers only **0 / 992 / 1984** — **172 is not in the
  list**, and the nearest offered value, "CRSF Min (0)", is the one the schema explicitly warns
  against. The field is `freeSolo` (`GenericForm.jsx:135`) and `visitIntegerField` `parseInt`s
  it, so **172 must be typed by hand** and does persist. `onAutoChange` debounces 250 ms, so
  type, pause, then save.

Entry spec for bench use handed to the owner separately. **No hardware powered, nothing flashed,
no head-intent / FIRST_ACTIVE path touched.**

**2026-08-03 — mapper hold-last throttle-freeze defect: VERIFIED CLOSED IN CODE, with three named
residuals of the fix (A, B, C below). Verification read the source at HEAD, not the commit message
or `git log`**
(the RETRACTION rule, applied deliberately: this claim confirmed a suspicion already held).
Nothing committed in `w17-mapper`; its tree is clean at **`5a28106`** and this pass added no code.

- **Pre-fix mechanism re-confirmed at `0e11d6b`, all three hops, from the files.**
  `input_button.go:77` returns `nan=true` when `GetInputGamepad` misses; `output_tx.go:43` is
  `if nan || ch < 1 || ch > 16 { continue }` over a persistent `*[16]util.CRSFValue` never reset at
  the top of a tick. The 2026-07-30 description was exact, line numbers included.
- **The fix is real for the reported defect, in the config shape the tests cover.** At HEAD
  `output_tx.go:91-94` drives a nan channel to `failsafeFor(ic)` instead of skipping it, and
  `input_channel.go:107,112,115` returns the channel number on **every** path including both nan
  returns — which is what makes neutralization possible at all. **For a transmitter whose `channels`
  are all `channel` nodes, no surviving `continue` can strand a written slot:** the only remaining
  skips are a nil holder and `ch < 1 || ch > 16`, and `InputChannel` reports its number on both paths.

  ⚠ **NARROWED 2026-08-03 (pre-merge review) — the original wording was a universal claim and it is
  false.** It read: *"Non-channel node types return `ch = -1` on the healthy path too, so they never
  write a slot and cannot hold one."* Many node types do the opposite — they **propagate the child's
  `ch` on the healthy path and return `-1` on the nan path**, which is exactly the asymmetry that
  strands a slot. Verified directly: `input_linear.go:67` returns `nil, out, ch, false`, `:48`
  returns `nil, 0, -1, true`. The proof generalized over ~30 node types after checking two.
  ⚠ **The "six" named by the pre-merge review is itself incomplete and partly misclassified — see the
  full 27-type enumeration in the 2026-08-03 B+D entry below.** **See RESIDUAL D.**
- **`Attached()` gates every resolution path, not just the one the commit exercised.** All three
  config-side resolvers — `input_axis.go:87`, `input_button.go:77`, `input_hat.go:52` — go through
  `Config.GetInputGamepad`, which is where the gate sits. `devices.Controller.Gamepad()` and
  `server_grpc.go:44` reach the registry ungated, but both are diagnostics/UI surfaces with no path
  to `Values`.
- **Residual 1 CLOSED — `AlertDeviceChan` does nothing of the kind.** It increments a counter and does
  a **non-blocking send on an unbuffered channel**; it neither invalidates the config nor zeroes the
  array. `eval.go:104-111` — the consumer — re-runs `tx.Eval(holder.Config)` on the **same** array.
  So the neutral can only come from `Eval` itself, which is exactly what the fix changed.
- **Residual 2 CLOSED, and it is now moot on the wire.** `EvalNoData` is still `{0,…,0}` but
  `630ea96` made it **display-only** (`controller.go:23-35`, feeding `GetTransmitterChannels`); the
  send loop writes **no channel frame at all** when no config resolves (`send.go:182-192`), so the
  receiver's own link-loss failsafe fires. **The two halves compose belt-and-braces:** if an
  all-zeros payload ever did arrive, `91f830f` decodes 0 as implausible ⇒ absent ⇒ arm forced OFF.
- **Tests bite — verified injected-regression style, three injections, tree restored after each.**
  (a) neutralizing branch removed ⇒ 3 failures, all reproducing the documented frozen **1984**;
  (b) `Attached()` gate removed ⇒ 2 failures, the switch channel landing on **992** — which is the
  DEFECT 2 arithmetic, so the gate is load-bearing for switches specifically; (c) `centeredValues()`
  zeroed ⇒ `TestUnmappedChannelsStartCentered` fails on all 15 unmapped channels. No vacuous pass.
- **Toolchain, this host, 2026-08-03:** `go build ./...` exit 0 · `go test ./... -count=1` all green
  (`config`, `headintent`, `link`, `server`) · `-race` green on `pkg/config` + `pkg/link` ·
  `crsf.PackChannels` byte-identity still holds (`TestPackChannelsUnchangedByReceiver` +
  `…BySubscribers`) · `.githooks/pre-push` exit 0, proto still ends at `ACTIVE_LOG_ONLY = 8`, no
  `FIRST_ACTIVE` / `w17_first_active` in tracked source. `go vet ./...` reports exactly one finding,
  `cmd/elrs-joystick-control/main.go:130` (unbuffered `os.Signal` channel) — **confirmed pre-existing
  upstream**, present at `2b8031a`; not a regression, per unlock plan §2.3.12.9 item 2.

**RESIDUAL A (open, by design, and it is a config obligation not a code bug).** `ChannelT.Failsafe`
defaults to `util.CRSFCenterValue` = **992**, and 992 decodes to normalized **0**, which sits inside
the firmware's ±250 hysteresis dead band ⇒ `decodeSwitch` **HOLDS the previous state**. So on a
gamepad dropout **throttle and steering do go neutral — the reported defect — but arm, DRS, gear
up/down, boost and overtake stay latched wherever they were.** The car stops but stays *armed*, and
resumes the moment the gamepad reconnects, with no re-arm. The code says so itself
(`input_channel.go:24-28`) and the tests pin it with an explicit 172. **The prescription already
exists** — `failsafe: 172` on the six `decodeSwitch` channels, in the 2026-07-30 config findings
above — **but no mapper config exists on this Mac to carry it.** Until that config is built by hand,
the shipped default leaves switch channels latching on a dropout.

**RESIDUAL B — ✅ CLOSED 2026-08-03 in `e452d55` (option (c), frame suppression across the swap); the
mechanism below is retained because it is what the fix keys off, and it is unchanged in the config
layer by design — see the closing entry at the end of this section.** A **mid-session config swap**
re-seeds the array to 992 over a switch that is currently ON. **Conclusion re-derived from source and
REPRODUCED 2026-08-03; the mechanism holds, but the cited path was backwards and is corrected here.**

- `SetConfig` (`server_grpc.go:102`) schema-validates and unmarshals a wholly new `Config`, then calls
  `ConfigCtl.SetConfig` (`:125`) → `alertConfigChan` → `ConfigEventChan`.
- `eval.go:78-92` rebuilds `EvalDataMap` on that event. **The corrected hop:** it does *not* publish
  the unmarshalled transmitters' arrays. `eval.go:85` calls `config.GetTransmitters()`, which for
  every port builds a **fresh synthetic** `OutputTransmitter` via `NewTransmitter` (`config.go:39-48`)
  — `Values: centeredValues()`, all 16 slots at 992 — and copies only the *channel-node lists* across
  (`config.go:63,:69-73`). `eval.go:90` publishes **that synthetic array**. So `config.go:41` *is* the
  seeding path, but via `GetTransmitters()`, not via unmarshal; and the earlier note that
  `output_tx.go:71`'s nil-guard "is not the path here" is right, for the wrong reason.
- A channel the new config no longer maps therefore goes `1811 → 992` on the wire **and stays there
  permanently** — nothing re-evaluates a slot no node writes. Since `firstDecodeDone_` is already
  true, 992 normalizes to 0, lands inside the firmware's ±250 dead band
  (`ChannelDecoder.hpp:38-39`, `ChannelDecoder.cpp:78-82`), and `decodeSwitch` **HOLDS ON**.
- `630ea96` covers the *cleared*-config case by suppressing frames (`send.go:76-89,182-192`); the
  *replaced*-config case is not covered — `resolveChannels` gets a live map hit and returns the
  all-992 array.
- **Second-order finding, new this pass and worth recording separately:** `EvalAll` (`eval.go:45-58`)
  walks `config.IOMap` — the **originals** — so the `ConfigEventChan` branch never evaluates the
  synthetic transmitters it just published. Only the `DeviceEventChan` branch (`eval.go:103-110`)
  does. So immediately after any apply, **every** channel reads 992, not just dropped ones. With a
  live gamepad this window is sub-millisecond (`devices/controller.go:136-138` alerts on every SDL
  poll event), so it is a brief transient, **not** a standing state — do not inflate it. The
  permanent part remains the dropped channel.
- **Reachability (measured, not assumed): explicit user action only.** Go-side callers of
  `ConfigCtl.SetConfig` are exactly two — the gRPC handler (`server_grpc.go:125`) and the one-shot
  `-config <file>` client (`client/grpc_client.go:61`). The webapp's only non-generated call site is
  `InputControls.jsx:119`, bound to `onApplyConfig` on a **button click** (`:140`), *not* autosave —
  the 250 ms `onAutoChange` debounce noted in the 2026-07-30 entry updates local React state, not the
  server. Nothing re-applies on reconnect, on link start, or on a timer. **But the trigger is exactly
  the activity now planned:** hand-entering the config (`w17-mapper-config-entry-record.md`) means
  pressing Apply repeatedly, and if the link is running during that, B fires on every press.

**RESIDUAL C (open, timing).** Neutralization needs at least one `Eval` tick after the removal.
`AlertDeviceChan`'s send is non-blocking on an **unbuffered** channel with **two competing consumers**
(`eval.go:104` and the gamepad stream at `server_grpc.go:201` — **corrected: my own `:233` here was
wrong, that line consumes `EvalEventChan`, not `DeviceEventChan`; the count "two" was right, the
second citation was not**), so the `JOYDEVICEREMOVED` alert
can be dropped, or taken by a stream handler instead of the eval loop; the device is gone, so no
further SDL event follows and `Eval` never re-runs on the stale array. Not observed; identified by
reading the loop.

⚠ **Corrected 2026-08-03 — the closure session got C's mitigation wrong, in the direction of
overstating C.** The entry as first written read: "`AlertStreamChan` is **defined but never called**,
so `StreamEventChan` never fires." Both halves are false, and the same paragraph then credited a 25 ms
synthetic-alert mitigation which *is that very mechanism* — an internal contradiction that should have
caught it. Verified against source: there are **three** 25 ms tickers, one per streaming RPC —
`server_grpc.go:195` and `:222` poke `AlertDeviceChan`, and `:246` pokes **`AlertStreamChan`** at
`:256` — and `StreamEventChan` is consumed at `eval.go:95`, whose branch re-evaluates **every**
top-level holder in `config.IOMap`, transmitters included. It is a second, independent route to the
neutralizing tick, not a dead one.

**What survives the correction is the sharper claim.** All three synthetic tick sources live *inside
streaming RPCs*, so **with no gRPC subscriber there is no periodic eval tick at all**, and
neutralization rests entirely on one droppable alert landing on an unbuffered channel. The mitigation
is not merely "UI-state-dependent" — the entire re-evaluation heartbeat is coupled to something
watching, which is precisely the condition that does *not* hold while driving. C stands, restated.

**RESIDUAL D — ✅ CLOSED 2026-08-03 in `e452d55` (neutral resolved from the owning `channel` node,
stateless subtree walk on the unusable-result path). Arm-safety; added 2026-08-03 by the pre-merge
review; two mechanisms, both executed against HEAD `5a28106`, both now covered by injected-regression
tests — see the closing entry at the end of this section.** This is the one that broke the flat CLOSED
verdict.

- **D-1, stranding.** A **wrapper node at the top level** of a transmitter's `channels` array —
  `linear`, `map`, `case`, `if`, `trim`, `switch` **and eight more the review missed: `and`, `or`,
  `eq`, `neq`, `gt`, `gte`, `lt`, `lte`** (full enumeration in the 2026-08-03 B+D entry) —
  propagates its child's `ch` on the healthy path
  and returns `-1` on the nan path (`input_linear.go:67` vs `:48`). The healthy tick writes the slot;
  the nan tick hits `ch < 1` and `continue`s, so **the slot keeps its last value**. Executed: a
  `linear` over an axis channel held `ch1 = 1984` across five detached ticks instead of neutralizing
  to 992. **That is the original reported defect — full-deflection throttle frozen across a dropout —
  unmitigated at HEAD.**
- **D-2, configured failsafe silently discarded.** The `EvalOperation` family — `add`, `subtract`,
  `min`, `max` **only; the review's inclusion of "the comparisons" here is wrong, they are D-1
  stranders (`util.go:222` drops `ch` to `-1` on nan), confirmed by execution below** — propagates
  `ch` on **both** paths (`util.go:277`), so it does write the slot — but
  `failsafeFor(ic)` (`output_tx.go:49-54`) type-asserts `FailsafeValuer` on the **top-level holder**,
  which a wrapper is not, and falls back to center. Executed: an arm channel with a correctly
  configured `failsafe: 172` emitted **992** on dropout → inside the ±250 dead band → **arm stays
  latched ON**.
- **This is schema-valid, not a contrived config.** `schema.yaml:314` types `channels` as
  `$ref: '#/definitions/input'` — the full node union. The `expected: channel` at `:311` is `$meta`
  UI metadata and is enforced nowhere in Go.
- **Reachability: PLAUSIBLE-but-unlikely in the config we plan today** (the UI steers toward `channel`
  nodes at top level, and the test harness only ever builds that shape) — **but not hypothetical.**
  `w17-mapper-config-entry-record.md` already plans a `switch`/`case` construct for ch13 drive mode,
  which is one of the six asymmetric types. What is **CONFIRMED** is that the closure's proof was
  invalid as written and that a schema-valid config still freezes throttle.
- **Structural fix — EVALUATED 2026-08-03, and the review's version does not fully hold.** Its first
  half (resolve the failsafe from the node that *owns* the channel number, not the top-level holder)
  is sound and fixes D-2. Its second half (treat a valid-`ch`-when-healthy → `-1`-when-nan transition
  as a nan for that channel) requires **new per-holder state** and breaks on two real shapes: a
  subtree may contain **several** `channel` nodes, and `switch` legitimately changes which channel it
  reports between ticks, so a `ch` change is not evidence of nan. It also cannot help when the very
  first tick is already nan. A stateless subtree-walk alternative is set out in the B+D entry below.
  **The subsumption claim is CONFIRMED** — B and D are one change in `output_tx.Eval`, not two.
  Tracked jointly in `w17-mapper-eval-failsafe-bd-prompt.md`.

**Verdict (as it stood at `5a28106`, superseded by the closing entry below): the defect as reported —
a USB gamepad dropout freezing throttle — is CLOSED for transmitters whose `channels` are all
`channel` nodes, which is every config the tests cover and the shape the UI steers toward. It is NOT
closed in general: RESIDUAL D re-opens throttle freeze through a top-level wrapper node, in a
schema-valid config.** The earlier flat "CLOSED" was CLOSED-shaped — correct for the covered shape,
over-generalized to all configs. A, B and C remain residuals of the fix rather than the original
defect; **D is the original defect, on a path the fix does not reach.**

⚠ **NARROWED 2026-08-03 by `e452d55` — and the first wording of this supersede was FALSE.** It read:
*"D is closed for ALL node types at the top level, so the verdict is now general rather than
shape-limited."* **It is not general.** Corrected by the `e452d55` code review, which reproduced the
counter-example by execution:

- **What `e452d55` DOES close:** every top-level node type whose result becomes **unusable** when its
  subtree fails — which is every type when the whole device drops. That is the reported defect and it
  is genuinely fixed.
- **What it does NOT close — PARTIAL subtree failure.** ✅ **CLOSED 2026-08-04 at `c60843e`; see the
  dated entry at the end of this section.** `EvalOperation` (`util.go:295-303`),
  `InputAnd`/`InputOr._Eval` (`input_and.go:63-77`) and `EvalRelational` (`util.go:247-252`) all
  **ignore a nan operand** and return `nan=false` with a valid channel number. The holder therefore
  reports healthy, the `output_tx.go:165` healthy branch is taken, and `channelOwners` is never
  called. Reproduced: `add{ch1←number, ch2←axis on a DETACHED gamepad}` at top level transmits
  **ch2 = 1984 — full deflection — indefinitely** on a healthy link, with its configured 172 rail
  never applied; the `and` variant leaves a detached arm channel at **992**, the exact value the
  change exists to avoid. **Not a regression** — byte-identical pre- and post-fix. The fix does not
  reach it. **D stays OPEN for this shape.**
- **Why all 22 tests missed it:** every one detaches the *whole* device, so the left operand goes nan
  first and the top-level result is genuinely unusable. No test builds a subtree where one channel
  survives and another dies. Single-device configs are safe (`allNan` ⇒ `nan=true`); a constant-fed
  channel or a second gamepad is enough to reach it.
- **The generalization that failed is one level up from the last one.** The 27-type classification is
  complete and correct (independently re-enumerated; the 14/4/7/1/1 split holds exactly). Nobody asked
  whether **every way a subtree can fail** makes the holder's result unusable. It does not. This is the
  fifth error in the chain and the fifth instance of the same shape.

**RESIDUAL D-3 (CLOSED 2026-08-04 at `c60843e` — see the dated entry at the end of this section):
the depth bound reintroduces hold-last, and guards a case it
cannot reach.** `channelOwnerMaxDepth = 32` (`output_tx.go:63`) truncates a legitimately deep tree to
**zero owners**, so `ch` is `-1`, the `ch >= 1` guard writes nothing, and the slot keeps its last
value — the original defect, silently. Reproduced with a 40-deep `linear` chain: `ch1 = 1984` after
five detached ticks. Its comment claims it is a `read`-cycle backstop, but `InputRead._Eval`
(`input_read.go:44`) recurses unguarded and **fatally overflows the stack before the walk is ever
reached** (pre-existing upstream, not introduced here); `TestReadCycleTerminates` passes only because
it calls `channelOwners` directly and never `Eval`, so it does not test what its name says.

**Also recorded (safe direction, undocumented):** the seven opaque types (`invert`, `seq`, `number`,
`axis`, `button`, `hat`, `gamepad`) return `ch = -1` on **both** paths, so a healthy top-level
`invert` is now pinned to its failsafe rail every tick. Pre-fix it sat at 992 forever; neither carries
live data and 172 is the safer of the two, so this is an improvement — but no test covers it and the
test file's justification for excluding these seven ("neither can strand a slot") is a statement about
the *old* defect.

**A remains open (a config obligation), C remains open (timing).**

**✅ TWO OWNER DECISIONS TAKEN 2026-08-03, both downstream of RESIDUAL D.**

- **B+D fix approach: option (c) + the stateless subtree walk, as ONE commit. Not yet implemented** —
  tracked in `w17-mapper-eval-failsafe-bd-prompt.md`, which now carries the ruling so the implementing
  session does not re-litigate it. **(c)** suppresses frames across a config swap the way `630ea96`
  already does for no-config: during a swap the mapper genuinely does not know what the channel values
  should be, and (a)/(b) both keep transmitting a guess — (a) *is* hold-last, the exact semantic
  `2dc7c5a` removed. **The subtree walk** drives every `InputChannel` under a nan/invalid-`ch` holder
  to its own `FailsafeValue()`; it is viable precisely because `channel` is the sole originator of a
  channel number and the sole `FailsafeValuer`. The review's second half — "treat healthy-`ch` →
  nan-`-1` as a nan for that channel" — is **rejected**: it needs per-holder state, breaks where a
  subtree holds several channels, and misfires because `switch` legitimately changes which channel it
  reports between ticks. Two implementation notes recorded with the ruling: **the no-frame window must
  NOT be bounded** (permanent suppression on a config that never resolves is the safe outcome, per
  `630ea96`), and **each Apply will visibly trip firmware failsafe** at the bench with the link up —
  correct behaviour, but alarming if unannounced.
- **ch13 drive mode: enter ch1–ch12 now as plain `channel` nodes; HOLD ch13 until B+D lands.**
  `switch`/`case` at top level is D-1, so rejected. `channel`-wrapping the construct *should* be safe
  — `channel` reports its number on every path — but that is a "should," and this chain has already
  punished three unverified ones, so it is rejected **as a load-bearing assumption**, not on the
  merits. `hat` is genuinely clean (always-`-1` class) and remains available if three D-pad positions
  are ergonomically acceptable. Holding costs nothing: `decodeTriState` returns `1` = RACE at center,
  so an **unmapped ch13 already sits in its safe middle**, and drive mode is not needed for first
  arming. Recorded in `w17-mapper-config-entry-record.md`.

**2026-08-03 (later pass) — RESIDUALS B + D: independently re-derived from source, all four
mechanisms REPRODUCED by execution against HEAD `5a28106`, node-type enumeration completed and the
review's list corrected. NO CODE COMMITTED — `w17-mapper` tree clean at `5a28106`.**

- **Full node-type enumeration, done from the files, not inherited.** `pkg/config/` has 28
  `input_*.go`; `input_holder.go` carries no `Eval`, leaving **27 node types**. Every `Eval` is a
  thin wrapper delegating to a per-type `_Eval` or to `EvalOperation`/`EvalRelational` (`util.go:266`
  / `:212`). Classified by what `ch` does on the healthy vs the nan path:
  - **Always `-1`, cannot ever write a slot (7):** `axis`, `button`, `hat`, `gamepad`, `invert`,
    `number`, `seq`.
  - **Originates its own number on every path (1):** `channel`. `input_channel.go:107,112,115` —
    and `:8` deliberately *discards* the child's `ch`.
  - **ASYMMETRIC ⇒ D-1 stranding (14):** `linear`, `map`, `case`, `if`, `trim`, `switch` (the
    review's six) **plus `and`, `or`** (`input_and.go:13,51` vs `:5,21,47`) **and the six relational
    types `eq`, `neq`, `gt`, `gte`, `lt`, `lte`** via `EvalRelational` (healthy `:229/234/237/256/261`
    propagate `ch`; nan `:215/:222` return `-1`).
  - **Transparent on BOTH paths ⇒ D-2 failsafe misresolution (4):** `add`, `subtract`, `min`, `max`
    via `EvalOperation` — `util.go:277` returns `ch` *with* `nan=true`.
  - **Pure pass-through, inherits its target's class (1):** `read` (`input_read.go:14`).
  - **The review's list of six is therefore incomplete (14, not 6) and partly misclassified** — it
    filed the comparisons under the `EvalOperation`/D-2 family; they are D-1 stranders. This is the
    same over-generalization the RETRACTION rule exists to catch, one level down.
- **The structural key, which makes the fix tractable:** `channel` is the **sole originator** of a
  channel number (`git grep util.ChannelNumber(` → `input_channel.go` only) and the **sole**
  `FailsafeValuer` (`:89`). Every other node either returns `-1` always or propagates a number that
  came from a `channel` node below it. So the node that "owns" a channel is *always* an
  `InputChannel`, reachable from the top-level holder via the existing `Children()` traversal.
- **Also found, not previously recorded:** `and`, `or`, `case`, `if` and `EvalOperation` **reassign
  `ch` from each right-hand/condition operand in turn**, so the number they propagate is whichever
  operand was evaluated last — often `-1`. `EvalRelational` does not (`util.go:247` discards it).
  This makes wrapper behaviour operand-order-dependent, and it is why the `and` reproduction below
  needed the `channel` node in the last right slot.
- **Executed evidence (scratch file `pkg/config/zz_repro_bd_test.go`, run at `5a28106`, then removed
  — tree verified clean):** all five fail at HEAD, each printing the defect value.
  · D-1 `linear` over `channel`: `ch1 = 1984` held across **five** detached ticks (reproduces the
  review exactly — full-deflection throttle frozen). · D-1 `gt`: `ch1 = 1984` stranded — **proves the
  comparisons are D-1, not D-2**. · D-1 `and`: `ch1 = 1984` stranded — **a type absent from the
  review's list**. · D-2 `add` over `channel` with `failsafe: 172`: emitted **992**, the configured
  rail discarded → inside the ±250 dead band → arm latched ON. · B swap: dropped `ch5` read **992**
  after apply, over a switch latched hard ON. Harness preserved outside the repo.
- **Baseline at HEAD, this host:** `go build ./...` exit 0 · `go test ./... -count=1` all green
  (`config`, `headintent`, `link`, `server`) · `-race` green on `pkg/config` + `pkg/link` ·
  `TestPackChannelsUnchangedByReceiver` and `…ByDiagnosticsSubscribers` both PASS (CRSF byte-identity
  holds) · `.githooks/pre-push` exit 0 · proto still ends at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8`
  · no `FIRST_ACTIVE` / `w17_first_active` in tracked Go or proto · `go vet ./...` reports **exactly
  one** finding, `cmd/elrs-joystick-control/main.go:130`, pre-existing at upstream `2b8031a` — not a
  regression, deliberately not "fixed".
- **B and D are ONE change, confirmed.** Both land in `output_tx.Eval`: D needs the failsafe resolved
  from the owning `InputChannel` and the nan path to reach channels a wrapper hides; B needs the
  same per-channel failsafe applied to channels a *new* config no longer maps. A subtree walk that
  collects `InputChannel`s under a holder serves both. Fixing them separately would touch that
  function twice with two sets of injections.
- **Options put to the owner (not chosen here — control path):** (a) carry forward previous `Values`
  for still-mapped channels + emit each dropped channel's failsafe; (b) seed from configured failsafe
  instead of uniform 992 — **but note it composes badly with RESIDUAL A: while `ChannelT.Failsafe`
  still defaults to 992 and no config sets 172, (b) changes nothing for exactly the switch channels
  that matter**; (c) suppress frames across the swap the way `630ea96` does for no-config, until the
  new config has produced one full `Eval` — reuses an already-accepted shape, costs a brief no-frame
  window the receiver's link-loss failsafe covers; (d) firmware side — **considered and rejected**:
  the firmware cannot see a config discontinuity, so it cannot distinguish "992 because swap" from
  "992 because centred". Preferred on the evidence: **(c) for B + stateless subtree walk for D**, as
  one commit — but this is the owner's call.
- **No hardware powered, nothing flashed, no head-intent / FIRST_ACTIVE / arbitration path touched.
  A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**

**2026-08-03 (implementation pass) — ✅ RESIDUALS B + D CLOSED IN CODE. `w17-mapper` `5a28106` →
`f81ec63`, two commits: `e452d55` (the fix, one commit as decided) + `f81ec63` (GPL §5(a) table).
Tree clean, `ahead 7` of `origin/w17-headtrack`, UNPUSHED.**

- **Everything below was re-derived from the files before any code was written**, per the RETRACTION
  rule. **Every claim in the brief held**, including the prior pass's own corrections: the 27-type
  enumeration, the comparisons being D-1 rather than D-2, and B's seeding path running through
  `GetTransmitters()`→`NewTransmitter` rather than through unmarshal. **Two things the brief did not
  contain were found by implementing it** — the swap window needs a lower bound (below), and a `read`
  node at the top level is a D-2 case nobody had named.
- **D — fixed by resolving the neutral from the node that OWNS the channel number**
  (`output_tx.go`, `channelOwners` + the rewritten write path). On an unusable result — `nan` **or**
  an out-of-range `ch` — every `InputChannel` under the holder is driven to its own
  `FailsafeValue()`. Viable because `channel` is the sole originator of a channel number and the sole
  `FailsafeValuer`. Two traversal rules earned their place: the walk **stops at** a channel node (an
  `InputChannel` discards its child's number, so a nested channel is not that holder's to drive) and
  **follows `read`** through `IOMap` (its `Children()` is nil, yet its `Eval` returns its target's
  number — a `read` at top level was a D-2 case nobody had named, found this pass).
- **A refinement was considered and REJECTED on evidence, and it is worth recording because it looks
  correct.** Keying the neutral off the number the holder reported (rather than walking) would avoid
  writing several slots. But `EvalOperation` reports the **last right operand's** number while healthy
  and the **left** one on the nan path, so that version would neutralize ch1 and strand ch2 — the same
  defect, moved one operand over. The owner's uniform walk-all rule is correct as written. Pinned by
  `TestSubtreeWithSeveralChannelsNeutralizesAll`.
- **B — fixed with option (c), frame suppression across the swap** (`send.go`, `configSwapGate`),
  reusing `630ea96`'s shape. ⚠ **One parameter the decision did not specify, and it is load-bearing:
  the window needs a LOWER bound.** "Suppress until the new config has produced one full `Eval`" is
  sub-millisecond in practice, and a gap that short is invisible to the receiver — no failsafe fires,
  and the dropped switch stays latched exactly as before. The window is therefore sized at **1 s**
  against the control firmware's **500 ms** `failsafe::Config::linkTimeoutMs`, with margin for the
  **unmeasured** TX-module/RX hold on top. This is not a departure from the ruling: the ruling's own
  note 2 (*"each Apply briefly drops frames → firmware failsafe → servos to neutral, arm drops"*) is
  only true if the window outlasts that timeout. **The exact 1 s is a bench item — no hardware has run
  this path.** The upper bound is still absent as instructed: a config that never resolves stays
  suppressed forever.
- **Also fixed in passing, and it was a real transient:** `EvalLoop` published the synthetic
  transmitter arrays *before* anything evaluated them, so immediately after every Apply **all 16
  channels** read 992, not just dropped ones. Now `applyConfig` evaluates first and publishes second.
- **B's fix and D's fix do NOT conflict, and under the chosen options they are not the same change.**
  They would have been under option (b): "seed from the configured failsafe" and "resolve the failsafe
  from the owning node" are one idea seen twice. But (b) cannot work for B at all, and for a sharper
  reason than the RESIDUAL A composition already recorded — **a dropped channel has no node left in
  the new config to ask for a neutral.** They are two disjoint edits (`output_tx.go` vs
  `send.go`/`eval.go`) that compose cleanly, delivered as one commit as decided.
- **Evidence, this host.** `go build ./...` exit 0 · `go test ./... -count=1` green (`config`,
  `headintent`, `link`, `server`) · `-race` green on `pkg/config` + `pkg/link` ·
  `TestPackChannelsUnchangedByReceiver` and `…ByDiagnosticsSubscribers` both PASS (CRSF byte identity
  holds) · `gofmt` clean on every touched file · `.githooks/pre-push` exit 0 · proto still ends at
  `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` · no `FIRST_ACTIVE` / `w17_first_active` in tracked Go or
  proto · `go vet ./...` reports **exactly one** finding, `cmd/elrs-joystick-control/main.go:130`,
  pre-existing at upstream `2b8031a` — deliberately not "fixed".
- **Tests proven non-vacuous — four injections, tree restored and re-verified after each.** The
  injections deliberately cover the shape the previous closure did not: **a top-level wrapper node**,
  not only `channel` nodes at top level. (a) pre-fix `Eval` body ⇒ **7 failures** (⚠ corrected
  2026-08-03 by the code review, which re-ran it: this entry and `e452d55`'s commit message both said
  **6**, while their own prose enumerates 7; all 7 reproduce for the intended reasons), each printing the
  defect value — `1984` stranded through `linear`, `gt`, `and` and `switch`-fallthrough, `992` emitted
  where `172` was configured, `3968` stranded on a subtree's second channel, and the `read` target's
  rail lost. (b) walk descending past channel nodes ⇒ the nested-channel test bites. (c) swap window
  set to 0 ⇒ **3 failures**. (d) publish-before-evaluate ⇒ **3 failures**. **22 new tests** in three
  files (12 + 3 in `pkg/config`, 7 in `pkg/link`); the `switch` case is the one that shows `nan` is the wrong thing to key off — it strands a
  slot with **no nan at all**.
- ⚠ **EXPECT VISIBLE FAILSAFE DURING CONFIG ENTRY.** With the link up, every Apply now drops frames
  for ≥1 s, so the firmware trips failsafe: **servos to neutral, arm drops, each time**. That is
  correct behaviour, not a fault — but it will look alarming at the bench, so it is stated here, in
  the commit message, and it is the reason ch13 entry can now proceed.
- **Consequence for the held ch13 decision:** the reason for holding it (a `switch`/`case` construct
  at top level is D-1) is now closed in code. The hold can be lifted whenever the owner wants; nothing
  in this pass forces it.
- **Durable backup re-bundled:** `~/Documents/w17-backups/w17-mapper-allrefs-2026-08-03b.bundle`,
  `git bundle verify` reports a complete history, caps at `f81ec63`. The earlier
  `…2026-08-03.bundle` capped at `5a28106` and the `…2026-07-25b.bundle` at `0e11d6b`; both are now
  superseded.
- **No hardware powered, nothing flashed, no head-intent / FIRST_ACTIVE / arbitration path touched.
  A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Nothing pushed — the push-review rule in
  `FORK-NOTICE.md` governs, and `origin` is public.**

**2026-08-04 — ✅ D-PARTIAL and D-3 CLOSED IN CODE. `w17-mapper` `f81ec63` → `9ba6e06`, two commits:
`c60843e` (the fix) + `9ba6e06` (GPL §5(a) table + its date ordering). Tree clean, `ahead 9` of
`origin/w17-headtrack`, UNPUSHED.**

**State the closure precisely, because an over-broad claim is what this whole chain has been
correcting.** What is now closed, and the shapes it is closed for:

- **D-partial — CLOSED for every shape in which a top-level entry's subtree stops resolving, whether
  or not the entry's own result stays usable.** That is the general statement the earlier supersede
  claimed falsely and `e452d55` did not earn. It now holds because the neutral no longer depends on
  the entry's result at all: the walk enumerates the owners, and each owner that did not resolve is
  driven to its own failsafe independently of what the holder reported.
- **D-3 — CLOSED for the depth bound specifically**, both halves: the bound no longer fires in
  practice, and if it ever does, the port stops transmitting instead of holding.
- **STILL OPEN, and named rather than folded in:** `InputRead._Eval`'s unguarded recursion (below).
  It is not a shape of D; it is a separate pre-existing defect on the same file.

**The fix, and the one design constraint that shaped it.**

- **D-partial.** `EvalOperation` (`util.go:295-303`), the `InputAnd`/`InputOr` right-operand loops
  (`input_and.go:63-77`) and `EvalRelational` (`util.go:247-252`) all **ignore a nan operand and carry
  on**, so a holder fed by two sources reports healthy on a valid channel number while one of its
  channels has died — and `channelOwners` was never reached. The walk now runs **before** the
  evaluation, arming every `channel` node the entry can drive; the evaluation clears the arm on the
  ones it reaches; afterwards any owner that did not resolve is driven to its own `FailsafeValue()`,
  **even when the holder reported healthy**. The unusable-result path is unchanged and still drives
  ALL owners — `switch` fallthrough strands with every case resolving perfectly well, so per-owner
  state must not be applied there.
- **The reviewer's interim patch was NOT shipped, and the decision is now evidenced rather than
  argued.** It read `InputChannel.IsNaN`, a field written as a side effect of `Eval` and never
  cleared, so it is only ever about the last time that node happened to be evaluated. Injecting it
  (`resolvedThisPass` → `!IsNaN`) fails `TestEarlyExitOperandIsNeutralized` with exactly the predicted
  message — *"an operand the evaluation never reached reported itself resolved"*, slot left at 992
  where 172 was configured. The arming walk is what makes the state a fact about **this** pass.
- **A design that looked right and was rejected on evidence, worth recording:** having the walk
  **evaluate** each owner it finds would also derive the state from the traversal — and it would
  double-advance `InputSeq`, whose `NextValue()` mutates `currentOutputIndex` on every evaluation
  (`input_seq.go`). A `seq` under a `channel` node is an ordinary config. Arming costs one pointer
  traversal and evaluates nothing.
- **D-3.** `channelOwnerMaxDepth` **32 → 256**, and truncation is fail-safe in itself: an incomplete
  owner set means the entry's channels are unknown, so the new `OutputTransmitter.Unresolved` flag
  (an `atomic.Bool` published per port alongside the channel array, read through the same stable
  pointer every tick so the map is never rebuilt — rebuilding it is what `configSwapGate` reads as a
  swap) makes `SendLoop` suppress that port. **Distinguished from "legitimately no owners"**, which
  stays a no-op: a top-level `axis` drives no slot, so there is nothing to neutralize and nothing to
  suppress.
- **Truncation suppression is treated as ANY truncation, not only zero-owners.** A partially truncated
  walk returns *some* owners, and acting on a partial set is acting on unknown state just the same.
- **The bound's comment is corrected.** It claimed to be a `read`-cycle backstop; it cannot be, since
  `InputRead._Eval` overflows the stack first. It now says what the bound does. `TestReadCycleTerminates`
  is renamed to `TestChannelOwnersWalkTerminatesOnAReadCycle` and re-scoped — it never called `Eval`,
  so it never tested what its name said — with a **two-node mutual cycle** added alongside the
  self-reference.
- **The seven opaque types are now pinned, not assumed.** `invert`/`seq`/`number`/`axis`/`button`/
  `hat`/`gamepad` report `ch = -1` on both paths, so a healthy top-level `invert` sits on its
  failsafe rail every tick (verified: `ch7 = 172`). Safe, and an improvement on the 992 it held
  before. The wrapper test file's justification for excluding them ("neither can strand a slot") is
  annotated in place as a statement about the **old** defect.

**Evidence, this host.** `go build ./...` exit 0 · `go test ./... -count=1` green (`config`,
`headintent`, `link`, `server`) · `-race` green on `pkg/config` + `pkg/link` ·
`TestPackChannelsUnchangedByReceiver` and `…ByDiagnosticsSubscribers` both PASS (CRSF byte-identity
holds) · `gofmt` clean on every touched file (the two files `gofmt -l` does report,
`pkg/client/grpc_client.go` and `pkg/proto/gen.go`, are **pre-existing at HEAD and untouched** —
confirmed by stashing) · `.githooks/pre-push` exit 0, **and re-verified to still bite**: a commit
object carrying a `FIRST_ACTIVE` identifier was built out-of-band and refused, worktree and index
untouched · proto still ends at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` · no `FIRST_ACTIVE` /
`w17_first_active` in the pushed tip tree · upstream licence files unmodified since `2b8031a` ·
`go vet ./...` reports **exactly one** finding, `cmd/elrs-joystick-control/main.go:130`, pre-existing
upstream — deliberately not "fixed".

- **Four defects REPRODUCED at `f81ec63` before any code was written**, each printing its value:
  `add` → **ch2 = 1984** held indefinitely with its 172 rail discarded (the review's case exactly) ·
  `and` → detached arm channel at **992** · `gt` → ch2 stranded, 172 never applied ·
  40-deep `linear` chain → **ch1 = 1984** after five detached ticks. All four pass after the fix, at
  172 / 172 / 172 / 992.
- **21 new tests in three files** (11 in `output_tx_partial_test.go`, 5 + 1 benchmark in
  `output_tx_depth_test.go`, 6 in `send_unresolved_test.go`). **Every partial-failure test builds a
  subtree where one channel SURVIVES and another dies** — the trap that let this through five passes,
  since all 22 of `e452d55`'s tests detached the whole device.
- ⚠ **One honest limit on those tests.** The survivor is a constant-fed `number` channel, not a second
  gamepad: `devices.InputGamepad.Attached()` requires a live `*sdl.Joystick`, so a unit test can build
  a DETACHED device but never an attached one. The brief allowed either. What a second real device
  would have added — proof that neutralizing a dead operand does not sweep live channels with it — is
  covered by `TestLiveChannelsSurviveWhileAnotherDies` (two live channels + one dead, under one
  holder).
- **Five injections bite, each for the intended reason; tree restored and verified BYTE-IDENTICAL
  after every one** (per-file `shasum` plus a full-diff comparison against the pre-injection
  baseline). (a) per-owner neutralization removed ⇒ **6 failures**, printing 1984 and 992 ·
  (b) `resolvedThisPass` → `!IsNaN`, i.e. the rejected interim patch ⇒ **2 failures**, the early-exit
  one and the mechanism pin · (c) bound back to 32 ⇒ **2 failures** · (d) truncation fail-safe removed
  ⇒ **3 failures** (the first attempt at this injection did not compile, which is not evidence; it was
  redone as a compiling variant) · (e) walk no longer arms ⇒ **1 failure**.
- **Per-tick cost bounded by measurement, not assurance.** The walk now runs on every tick rather than
  only on the failing path. `BenchmarkEvalWalkCost`: **381 ns** per `Eval` of a 16-channel config,
  ≈0.01% of a ~4 ms CRSF frame interval. It is a pointer traversal that evaluates no nodes.
- **OUT OF SCOPE, RECORDED SO IT IS NOT LOST — `InputRead._Eval` unguarded recursion (OPEN,
  pre-existing upstream at `2b8031a`).** `input_read.go:44` resolves through `Config.IOMap` with no
  depth bound, so a `read` cycle (self-reference or mutual) exhausts the stack and **kills the process
  outright** — an unrecoverable crash, not a failsafe. It is reached during `Eval`, i.e. before the
  channel-owner walk, which is why `channelOwnerMaxDepth` never was and never could be the "read-cycle
  backstop" its comment claimed. Deliberately not fixed in `c60843e`: it is an upstream defect on a
  different mechanism, and folding it into a failsafe commit would have mixed two changes. **No test
  in `w17-mapper` may evaluate a cyclic config** — the walk-termination test calls `channelOwners`
  directly, and says so.
- **Durable backup re-bundled:** `~/Documents/w17-backups/w17-mapper-allrefs-2026-08-04.bundle`,
  `git bundle verify` reports a complete history, caps at `9ba6e06`. It supersedes
  `…2026-08-03b.bundle` (`f81ec63`), `…2026-08-03.bundle` (`5a28106`) and `…2026-07-25b.bundle`
  (`0e11d6b`).
- **Workspace bookkeeping, done in the same pass.** The `CURRENT_STATUS.md` record had split across
  two branches: `main` carried only the two session prompts while `docs/a2-adversarial-review` carried
  the A2 review entry, the B+D closure and the D retraction — so the file the workspace declares its
  single source of truth was two sessions stale on `main`. Merged (owner-approved, conflict-free: the
  branch touched only `CURRENT_STATUS.md`, `main` only the prompt files).
- **The `FORK-NOTICE.md` §5(a) table's date ordering is fixed** — the `e452d55` (2026-08-03) row had
  been inserted **above** `630ea96` (2026-07-30); it now sits after it, with `c60843e` (2026-08-04)
  appended.
- ⚠ **The bench consequence from the previous entry still stands and is unchanged:** every Apply with
  the link up drops frames for ≥1 s, so the firmware trips failsafe — servos to neutral, arm drops,
  each time. Correct behaviour, alarming if unannounced.
- **No hardware powered, nothing flashed, no head-intent / FIRST_ACTIVE / arbitration path touched.
  A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Nothing pushed — verified that what WOULD be pushed
  (9 commits) distributes no control path.**

**2026-08-04 (hook pass) — ✅ THE 2026-07-30 OWED HOOK ITEM IS DISCHARGED. `w17-mapper` `9ba6e06` →
`432a809`, one commit, docs/hook only.**

- **The gap was PROVEN before anything was changed, which was the point of the owed item.** A
  throwaway Go file containing `const firstActive = false` was committed on a scratch worktree branch
  and fed to `.githooks/pre-push` exactly as git feeds it (one stdin line of
  `<local_ref> <local_sha> <remote_ref> <remote_sha>`). **It exited 0 — allowed.** The same harness
  refused all three existing injections in the same run, so the pass is a real miss and not a
  measurement artifact. Arbiter code gated that way would have reached the **public** `origin`.
- **Owner decision: widen AND document (option b), not document-only (option a).**
- **False-positive surface, measured before the choice, not asserted after it.** Pattern
  `-iE 'first_?active'` over the hook's existing code globs at `9ba6e06` (120 `.go`, 2 `.proto`, 3
  `.sh`, 8 `.yaml`, **no `vendor/`**): **zero hits**. Tree-wide only `FORK-NOTICE.md` and the hook
  itself match, and **neither is in scope** — the globs are code-only, `.md` is not among them and
  `pre-push` is not `*.sh`. The prose false-positive risk therefore only materialises if the *file
  scope* widens, which this change does not do. No adjacency collision exists in the tree either:
  `first` appears 51× (`firstFieldEntry` ×10) and the `active` family is the head-intent enum plus
  upstream's `ActiveAntenna` / `SupervisorActive`, never adjacent. Residual risk is forward-looking
  only (a future upstream merge adding e.g. `firstActiveIndex`) and is **fail-closed** — it would
  refuse a good push, never allow a bad one.
- **What was changed:** a 4th check, `git grep -I -l -iE 'first_?active'` over the same globs, placed
  **last** so the three specific checks keep their specific refusal messages (verified — each
  injection is refused by its intended check, not by the new catch-all).
- ⚠ **The limit this does NOT close, now written into both the hook header and `FORK-NOTICE.md`:**
  the hook matches **names, not the class of compile-time gates**. `const enableShaping = false` or
  `const gateOpen = false` still passes clean, and **no grep can close that**. This is exactly why
  §2.3.11.4 is resolved to the build tag **exclusively** and why the naming contract is lowercase
  `w17_first_active` exactly. The hook remains the **accident guard**; the push-review rule in
  `FORK-NOTICE.md` and R1–R16 remain the **control**.
- **Full matrix re-run against the shipped tree** (candidate commit + injections on top of it, so the
  scanned tree contains the new hook and its new documentation), and recorded verbatim in the hook
  header so the next reader does not have to re-derive it: **clean HEAD allowed** (no self-trip on its
  own documentation — the failure mode a widened guard most plausibly has) · I1 `//go:build
  w17_first_active` refused by check 1 · I2 `const FIRST_ACTIVE = false` refused by check 2 · I3
  `HEAD_INTENT_STATE_ACTIVE = 9` refused by check 3 · I4 `const firstActive = false` **refused by
  check 4, having been allowed before this commit** · I5 `const enableShaping = false` **allowed**,
  recorded as the documented limit rather than quietly omitted.
- **All injection commits were destroyed with the scratch worktree and branch.** `w17-mapper` tree is
  clean at `432a809`; the only surviving artifacts are the hook, the notice, and this record.
- **Safety verification before commit:** `sh -n` clean on the hook; the diff touches **two files, no
  Go**; proto still ends at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8`; no `first_?active` match of any
  case in tracked Go or proto. **No hardware powered, nothing flashed, no arbiter, no active enum
  value. A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Nothing pushed** — `ahead 10`, and the
  push-review rule governs.

**No hardware powered, nothing flashed, no head-intent / FIRST_ACTIVE / arbitration path touched.**

Open owner decisions: #1 UDP 5602 topology + fork ownership/license — **RESOLVED 2026-07-15
(topology (a); fork = `w17-mapper` @ GPL-3.0-or-later, §2.3.12.9)** · #2 video-loss —
**RESOLVED 2026-07-15 (sender suppression → stale decay, §2.3.12.1)** · #3 failsafe
hold-vs-center — **RESOLVED FOR BENCH ONLY 2026-07-15 (hold-last; driving re-review
required, §2.3.12.2)** · #4 camera placement (in CB7) — **still open** · #5 driving
protocol/spotter — **RESOLVED 2026-07-15 (bench-only; separate driving milestone,
§2.3.12.3)** · **#6 FIRST_ACTIVE arm/recenter affordances — owner-choice RESOLVED 2026-07-15
(Alternative C, bench-only: SHARE=recenter; hold D-pad DOWN+OPTIONS 1 s=arm; D-pad DOWN=held
deadman; right thumb free); live mapper-binding validation still required; NOT for driving
(§2.3.12.6).** ~~(superseded interim: L1+R1/R3 failed the conflict audit; A/B were the earlier options)~~

## Pending validations

- **Real iPhone ↔ Windows bridge validation: PENDING (in progress).**
  - **Windows GS host stood up (2026-07-09):** fresh clone of `w17-ground-station` at
    checkpoint `dab3039`, `npm install` done, `npm test` green (118/118) on Windows —
    identical to macOS. No source/schema/firmware/dependency drift.
  - **Blocker — network client isolation:** the office guest Wi-Fi (`SE-Guest`, Public
    profile) isolates clients — laptop↔laptop ping fails both ways — so direct LAN UDP for
    W2/W3 cannot pass. Real cross-device validation needs a **non-isolated** network; this
    is a network limitation, not a bridge bug.
  - **Approach:** spare-phone (Android) Mobile Hotspot now; **Ralink RT5370 USB Wi-Fi as a
    PC-hosted SoftAP** as the permanent bench network (ordered — AP-mode support on Win
    10/11 to be verified on arrival); FPV **camera AP** for a later field-representative
    pass. Gate every attempt on a peer-to-peer ping before any UDP test.
  - Not yet run end-to-end against a real iPhone (no device on hand yet).
  - **In-app setup flow (hardened through the pre-hardware pass):** the ground station
    (now at `e0a5cdc`) scans/joins WiFi and hosts a hotspot itself (Mobile Hotspot backend
    preferred; legacy `hostednetwork` fallback targets the RT5370, needs elevation), runs
    the peer ping as a first-class GRID check, and can enable W2/W3 from persisted settings
    (`settings.json` in userData; **set env vars always win**). W3 remains **LOG-ONLY** (it
    exposes the last accepted sender's IP as a user-confirmed address suggestion — transport
    metadata only, guard-tested). Status classification:
    - **Software: COMPLETE through Batch E1** (hardening batches A1–E1: hotspot
      lifecycle/STOP + quit-ownership, adapter-pinned status/join, Wi-Fi security scope
      [open/WPA2/WPA3-transition join; WPA3-only/enterprise/unknown rejected], locale-neutral
      errors, ping classification, video-state lock, credential DPAPI-at-rest via
      safeStorage) **plus CB8 slices 3B/3C** (read-only, display-only mapper head-intent
      diagnostics subscriber — no control path) **and the `e0a5cdc` Windows reliability slice**
      (adapter live-push, hotspot readiness/interrupted, full-screen/F11, join-error UX, secret
      redaction). Suite **798/798 (46 files)**.
    - **Host verification: COMPLETE** — full suite + `npm run smoke:electron` (4/4 real
      boot scenarios) green on macOS; E1 accepted on live macOS Keychain.
    - **Windows CI: GREEN at `e0a5cdc`** (run `29440396447`: suite + Electron smoke + package
      build on windows-latest) and at the Batch F docs commit `170fd66` (run `29473220328`).
      Everything through `e0a5cdc` — CB8 3B/3C, the doc-sync `8c5af12`, and the reliability
      slice — is pushed and CI-covered.
    - **Real hardware evidence: PENDING** — the real OS layer (netsh/WinRT/ping/localized
      Windows, camera→mediamtx→WHEP, real iPhone W2/Local-Network, ELRS, Windows DPAPI) is
      **UNVALIDATED**. Runbook with evidence boxes:
      `w17-ground-station/docs/setup_flow_bench_checklist.md`; the authoritative evidence
      ledger is the matrix in `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md`.
- **ELRS TX enumeration on real Windows (`go.bug.st/serial` v1.6.0): UNVALIDATED.**
  The v1.6.0 bump (`w17-mapper` `f0a18f3`) was cleared on timing grounds on this macOS
  host — `Write`/`Read` byte-identical v1.5.0 → v1.6.0 in both `serial_unix.go` and
  `serial_windows.go`, delta confined to enumeration / `Open` error wrapping / an
  uncalled `Drain()` / cgo wrappers, and `crsf.PackChannels` byte-identical (12 frames /
  312 bytes, one SHA across off / on-valid / on-stale / on-invalid). The one residual is
  **real Windows enumeration of the ELRS TX**, which no macOS host can exercise. Runs
  with the other Windows-hardware unknowns above (netsh/WinRT, camera→mediamtx→WHEP,
  real iPhone W2/W3, Windows DPAPI). Evidence ledgers, not duplicated here:
  `w17-ground-station/docs/setup_flow_bench_checklist.md` + the matrix in
  `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md`;
  `w17-control-fw/project-review/11_hardware_validation_plan.md`.
- **`npm run smoke:electron` CANNOT RUN on this macOS host — machine limitation, not a code
  gap.** Gatekeeper denies the `node_modules` Electron binary ("library load denied by system
  policy"). Reproduced at a clean `e09369b` **before** any change, which is what makes it the
  machine and not the code. **Windows CI covers it and passes** (the `package-smoke` job).
  Recorded so no future session reports a failed local smoke as a regression, or treats its
  absence as an untested surface.
  - Also for test authors: **vitest scans an entire test file for the environment docblock
    token, including inside prose.** Writing it in a comment silently switched
    `responsiveLayout.test.js` to jsdom and broke its `import.meta.url` file reads. There is
    now a warning note in that file.
- **mDNS discovery of the iPhone HUD: BUILT 2026-07-25 (CB4) — real-device validation PENDING.**
  The canonical contract carries a Discovery section (`_w17hud._udp.local.`, advisory
  user-confirmed hints only; canonical 2026-07-10, mirrored at rev `84532ed`
  2026-07-14) and the iPhone advertises since `1e332ef`. **The Windows side is no longer
  unbuilt** — it shipped at GS `92cd894` with no new dependency and no 25th preload key
  (hand-rolled `node:dgram`: `shared/dnsWire.js` wire codec + `shared/hudDiscovery.js`
  contract policy + `main/HudDiscovery.js` transport; discovered HUDs ride the **existing**
  `setup:addr-hint` channel, which already answers "what could the iPhone's address be?",
  so the surface stays at 24). Queries only while PIT WALL is active, **never** under
  `W17_WIFI_SIM`; advisory user-confirmed hints only; **W3 stays LOG-ONLY**.
  **Still PENDING: real-device verification.** Every test is a byte fixture — no advertising
  iPhone has ever been seen by this code. Residual limits recorded in
  `w17-ground-station/docs/proposals/iphone_mdns_discovery.md`: subnet-broadcast addresses,
  wall-clock timing, the QU-bit assumption. That proposal's "nothing is implemented on either
  side" header was itself the real contract drift and is corrected; the service definition
  matched the mirrored section exactly, and contract §1–§7 + Discovery were **not** touched.
- **Active iPhone-derived pan/tilt: BLOCKED** behind a separate, reviewed safety milestone.
  Until then: no iPhone → CRSF, no iPhone → servo/gimbal, firmware stays iPhone-unaware, and
  the Windows W3 (UDP 5602) receiver is LOG-ONLY.
- **Head-tracking / VR consolidation (2026-07-14, documentation only, uncommitted):**
  - New docs: `w17-control-fw/project-review/head_tracking_unlock_plan.md` (unlock
    sequencing + mapper process boundary; proposed mapper host = elrs-joystick-control),
    `w17-3d-codex/CAMERA_GIMBAL_PLACEMENT.md` (placement source of truth),
    `w17-ground-station/docs/camera_aim_display_semantics.md`,
    `w17-ground-station/docs/video_topology_baseline.md` (approved H.264 720p60
    dual-consumer baseline). Stale-timeout canon ratified at **300 ms** (supersession
    notes added to both 400 ms readiness references).
  - **CB0 investigation COMPLETE (2026-07-14, read-only):** upstream `elrs-joystick-control`
    (`github.com/kaack/elrs-joystick-control`, HEAD `2b8031a`) cloned read-only into
    `_vendor/elrs-joystick-control` and read. Findings (unlock plan §2.3, now verified): the
    app is an SDL-gamepad node-graph mixer with **no UDP / plugin / virtual-axis ingest** (only
    gRPC:10000 + HTTP:3000) — head-intent ingest needs a **source-code fork** (new UDP source
    package + head-intent/arbitration nodes; send path untouched); a one-way read-only
    diagnostics republish to Electron **already exists** via the gRPC streaming RPCs; upstream
    is dual-licensed **GPL-3.0-or-later OR Fair Source 0.9** (1-user limit on the FS option).
    UDP 5602 remains an exclusive bind. Topology options (a)/(b)/(c) mapped with evidence;
    evidence leans (a) (smallest surface) but topology + fork ownership + fork license are
    **open owner decision #1** — not chosen here.
  - **Codex handoff DELIVERED and APPLIED:**
    `_handoff/2026-07-14_codex_handoff_vr_fpv_cross_review.md` (11 items, H1–H11)
    applied by Codex in canonical commit
    `84532ed870ee9dc4563217a78ae112ccd0f1c8f6` ("Consolidate VR FPV integration
    plans") across the VR plan, both safety docs, and the canonical contract.
    Codex outcomes: video baseline ratified (H.264 720p60, simultaneous iPhone
    RTP + Windows RTSP/WHEP); mapper host = owned/forked elrs-joystick-control;
    992 = commanded center; stale boundary 299/300 fresh, 301 stale; future
    active motion-sample freshness ≤ 250 ms (current 500 ms is log-only-grade);
    camera_yaw/pitch = commanded mirrors; near-limit = coarse `warning` text
    only in v1 (no new schema field).
  - **Contract mirror COMPLETE and ACCEPTED (2026-07-14):** canonical revision
    `84532ed` mirrored into `w17-ground-station/docs/windows_bridge_contract.md`
    (sections 1–7 + Discovery byte-identical to canonical; Windows appendix
    retained, stale mDNS-proposal note corrected). Both sides record `84532ed`
    as the sync revision; **Codex confirmed acceptance of the mirror 2026-07-14**.
    No further contract changes requested; Codex continues iPhone Batch 1
    optical/HUD calibration without schema or control-path changes. UDP 5602
    mapper/diagnostic topology and active video-loss response remain explicitly
    open owner decisions.
