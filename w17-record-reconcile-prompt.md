# Session prompt — 10. Record reconciliation + branch cleanup (docs-only, no hardware)

Paste into a Claude Code session started at `~/Documents/projects`.

Run this **last**, after every other prompt you intend to run. `CURRENT_STATUS.md` was synced on 2026-07-25
(`05157b2`) but that pass ran *before* three sessions finished, so it is stale again. This is a **delta
pass**, not a re-run — do not redo work `05157b2` already did correctly (the audit-findings closure, the CI
run list, the test counts, the staleness warning are all right).

Two phases, in this order. Phase A is in a nested repo, phase B is the workspace — finish A and push before
starting B, so the hashes B records are final.

## Phase A — `w17-control-fw`

Four commits (`37ebe46 → 34eba89`: CB3 comment fixes, R05/R19 decisions, the R06 drift guard, Wokwi
run-status honesty) are **committed but unpushed**, sitting on a branch named
**`docs/bom-cassette-electrical`** whose name no longer describes its contents (it now carries a tools
script and four owner decisions).

1. **Branch — ALREADY DONE 2026-07-25, just verify.** `main` had been at `fbf22f0` with the branch 6 commits
   ahead and unmerged, so the electrical BOM (`78e1e88`, `1834852`) wasn't on `main` at all. It was
   fast-forwarded (`fbf22f0 → 34eba89`, 16 files, no merge commit needed) and pushed. Confirm
   `main == 34eba89` and `origin/main == 34eba89`, then the naming problem is moot — the redundant branch
   `docs/bom-cassette-electrical` can simply be deleted local and on origin.
2. **Amend the serial-version record (owner decision 2026-07-25).** `head_tracking_unlock_plan.md`
   §2.3.12.9 records the approved bump as `go.bug.st/serial` → **v1.7.1**. What shipped in `w17-mapper`
   (`f0a18f3`, 2 files / +3 −1) is **v1.6.0**, and it is **accepted** — record the real reason, which is
   stronger than "smaller delta":
   - **v1.7.1 would raise the module's language version.** It drags `golang.org/x/sys` v0.8.0 → v0.43.0 and
     a go directive bump **1.20 → 1.25.0** in both `go.mod` and `go.work` — including **go1.22 loop-var
     semantics** — i.e. a behavioural change to every range loop in the mapper as a side effect of a serial
     driver bump. v1.6.0's own `go.mod` is byte-identical to v1.5.0's; `go list -m all` differs by exactly
     one line out of ~400 modules; `go.work` / `go.work.sum` byte-identical to `59d1739`.
   - **v1.6.0's delta cannot touch CRSF timing.** `Write`/`Read` are byte-identical v1.5.0 → v1.6.0 in both
     `serial_unix.go` and `serial_windows.go`; the delta is confined to enumeration, `Open` error
     wrapping/cleanup, an added `Drain()` that is never called, and cgo type wrappers.
   - **Preserve the v1.7.1 reachability analysis** — it makes a future bump cheap. v1.7.1 carries two real
     read-path deltas (the CH340 `0xFFFFFFFE` → `0x7FFFFFFE` timeout constant, and a `Read` that loops
     forever when `hasTimeout == false`), both **provably unreachable** because `supervisor.go:52` always
     passes a positive `refreshRate*4`. v1.6.0 predates both.
   - **Evidence to cite:** `go build ./...` green (was 11 cgo errors / 6 packages failed), `go test -count=1
     ./...` green, `-race` on `./pkg/headintent/` + `./pkg/server/` green (39 tests / 29 subtests, 0 races),
     `go mod verify` all modules, proto untouched (still ends at `ACTIVE_LOG_ONLY = 8`, no active enum), and
     `crsf.PackChannels` **byte-identical**: 12 frames / 312 bytes, all four dumps (off / on-valid / on-stale
     / on-invalid) sharing one SHA with subscribers connected / slow / disconnected, and identical to the
     dumps generated at v1.5.0. **Residual unknown:** real Windows enumeration of the ELRS TX, unverifiable
     without hardware on a macOS host.
   Amend §2.3.12.9 to record **v1.5.0 → v1.6.0 as shipped** with the above, the original v1.7.1 approval
   preserved as superseded. Do not rewrite history elsewhere in that document — the four earlier "temporary
   v1.7.1 bump, reverted" narrations are accurate accounts of what happened at the time and stay as they are.
3. **Record the `go vet` situation so nobody misreads it as a regression.** `go vet ./...` is **not green**
   in the fork — but the bump did not break it, it **revealed** it: before v1.6.0, `cmd` never compiled, so
   vet never reached it. What surfaces is one pre-existing **upstream** diagnostic
   (`cmd/elrs-joystick-control/main.go:130`, unbuffered `os.Signal` channel, upstream `db01a677`, 2023) plus
   two gofmt-dirty upstream files (`pkg/client/grpc_client.go` and one other). Left as-is per "no unrelated
   churn" and noted in the commit message — correct call, because fixing upstream files adds rebase friction
   to a fork we intend to track. Record the consequence: **if mapper CI is ever added, scope vet to the owned
   packages** (`go vet ./pkg/headintent/ ./pkg/server/`) rather than `./...`, or it will fail on upstream
   code we deliberately did not touch.
4. **Fix a claim in this repo's `docs/link2_protocol.md` that is now false.** Its ownership section closes by
   saying cross-repo CI enforcement is **"not built yet"**. It exists as of 2026-07-25: `w17-soundlight-fw`
   `2d22f85` adds a `link2-drift` job that anonymously shallow-clones this repo into `$RUNNER_TEMP` and runs
   `tools/link2_copy_check.sh --strict`. Correct the line and cite where the enforcement lives. While there,
   re-read that section from a **receiver's** point of view — the soundlight re-sync found it names
   `tools/link2_copy_check.sh` as though local to whichever repo holds the doc (it lives only here) and cites
   `test_crc_matches_crsf_implementation` against `lib/crsf` (which board #2 does not have). Those are fine in
   *this* repo; the fix is to mark clearly which statements are control-fw-local so the next copy doesn't
   inherit false claims.

5. Verify before pushing: `pio test -e native` **225/225**, all three ESP32 envs build. Then push and report
   the final branch name + HEAD.

## Phase B — workspace docs

1. **`CURRENT_STATUS.md` delta.** Four things are now wrong or missing:
   - **Ground station row** still says HEAD `3119180` with "an uncommitted 7-file WIP … not reviewed, not
     committed, and NOT covered by the CI run above." That WIP is reviewed, split into four commits, and
     pushed: `42319ad` (SETUP step split out of SEAT FIT — the flow is now five steps,
     `garage → pitwall → seatfit → setup → grid`, solo `garage → seatfit → setup → grid`, rail `01..05` with
     GRID = 05) · `e01eb9f` (HUD `.revwrap` viewport-centred, BATT above the merged pill row) · `0950298`
     (viewer-only footnote overlay removed — **isolated deliberately**, revertable alone) · `e09369b`
     (GRID `wide`, `#addrStatus:empty` reserve collapse). HEAD **`e09369b`**, level with origin,
     **CI run `30128883953` GREEN** (ubuntu `test` + windows-latest `package-smoke`, 1046/1046 across 53
     files, `smoke:electron` 4/4 `apiKeys:24`, `electron-builder --dir`).
   - **Ground station moved again — HEAD is now `9c2d723`**, pushed, **CI run `30144513077` GREEN** (both
     jobs), suite **1082/1082 across 56 files** (from 1046/53), `proto:check` OK, **`feel:check` OK** (new),
     `noControlPath` 16/16 + `ipcSurface` 16/16 at the 24-key surface. Five commits:
     `769003b` viewer-only disclaimer **restored** (⚙ settings panel + once per app session via a
     module-level `viewerNoteShown` flag driving `updateViewerNote()` from `showStep()`; deliberately **no
     dismiss button** — a focusable in GARAGE would enter the document order that finding 6's boot-only focus
     depends on, and `test/viewerOnlyNotice.test.js` asserts `boot()` still focuses `fastPathBtn`; a
     `settings.json` key was rejected because it would have to pass `normalizeSettings` and would break
     `settings.test.js`'s 12-key persisted-shape pins) · `12896fb` the four unasserted CSS rules **pinned**
     (`responsiveLayout` 22 → 26; the BATT-above-pills assertion is **provisional** by design — a deliberate
     flip is one `<` → `>` on a commented line) · `7c29a6b` audit **annotated** (91 insertions, 0 deletions —
     so §3's "none applied" is no longer stale) · `16d3d0a` **R01 implemented** (armed/failsafe labelled as
     simulated) · `9c2d723` the **`feelConstants` drift guard made real** (hermetic snapshot +
     `scripts/check-firmware-feel.js`, exit codes **1/2/3** matching `link2_copy_check.sh` and deliberately
     differing from `proto:check`'s 2/3 — stated in the script header so nobody silently "harmonizes" them;
     `--strict` / `W17_FEEL_CHECK_STRICT=1` makes an absent sibling exit 2, as does a renamed firmware
     member — never a silent pass). Scope went **beyond** the brief, correctly: all **four**
     firmware-derived constants are bound, not the three in `ErsSystem.hpp` — `GEARS`'s "matches the
     firmware gearbox `numGears=4`" was an unguarded claim of exactly the same kind, so it binds to
     `Gearbox.hpp`; `TOP_SPEED_KMH` stays unbound with a test asserting that positively. Every new assertion
     was verified to **bite on an injected regression** first (16 injections across four test files), and
     `../w17-control-fw` was verified clean after each.
   - **Control-fw:** the 2026-07-25 zero-hardware batch is absent entirely. Record native **225/225** (+1
     test), all envs building, phase A's final branch/HEAD, and: **CB3 DONE** (`ChannelDecoder.hpp:58` —
     anchor had drifted one line; also retired a vacuous `PinMap.hpp` comment by naming the real
     declared-but-unwired `kBoard2UartRxPin`, `Serial1.begin(..., rxPin=-1, ...)`) — update the VR-FPV batch
     table row, which still says `NOT_STARTED`, and `VR_FPV_MASTER_PLAN.md` if it carries its own CB3 status.
     **R05** closed: 4 gears canonical, the phantom "6" was `Gearbox::kMaxGears` (array capacity) misread as
     a count, only fix was the stale mock at `docs/f1_hud.html:286`. **R19** closed: TRAINING/RACE/ERS is
     canonical for display, wire enum `TRAINING/GEARBOX/GEARBOX_ERS` deliberately differs (recorded, not
     drift); one stale comment at `Link2Sender.hpp:21`. **R06** closed: the link2 copy is
     **permanent-but-guarded** — `tools/link2_copy_check.sh` (`--strict`, exit 1 drifted / 2 could-not-check,
     verified to bite on an injected `kPayloadLen` change and a deleted file) plus a hermetic feel-constant
     pin; R06's conflation of wire format vs feel constants is now recorded as two separate guards.
     **R01** decided: armed/failsafe stay **simulated but must be labelled** (adding `A1F0` to FLIGHTMODE
     rejected — 15 chars exactly fits, R13 unproven, and mid-token truncation could show a *wrong* armed
     state); the label itself is a ground-station follow-up.
   - **Wokwi:** retagged `[HW]` → **`[OWNER/tooling]`**. `esp32dev_sim` **builds but has never been run** —
     blocked on a Wokwi credential (`wokwi-cli` absent, `WOKWI_CLI_TOKEN` unset; every route uploads the
     firmware to Wokwi's servers), **not** on the bench. The stall injector already existed
     (`W17_SIM_WDT_STALL`, marker present once in the stall ELF, absent from all three shipping envs).
     `SIMULATION.md` leads with a run-status table, **every box unchecked**. Nothing promoted to PASS; the
     2 s TWDT stays **provisional**. Do not let this line read as hardware-blocked.
   - **Mapper — three corrections, one of them safety-relevant.** HEAD is **`0e11d6b`**, not `59d1739`:
     `f0a18f3` (`go.bug.st/serial` v1.5.0 → v1.6.0; `go build ./...` now **fully green**, the go1.26 × cgo
     blocker cleared), `8fc1915` (fork notice: provenance, GPL-3.0-or-later election, GPL §5(a) modification
     notice, safety boundary), `0e11d6b` (the pre-push guard tracked at `.githooks/pre-push` + the written
     push-review rule). Update the four places describing a temporary-and-reverted v1.7.1 bump **only** where
     they describe *current* state; leave the historical narrations alone.
     **`CURRENT_STATUS.md` line ~39 and the checkpoint row at line ~380 both still say "push disabled" — both
     are now wrong, and that is safety-relevant drift.** The fork has a remote: `origin` =
     `github.com/beforethenexttolast/w17-mapper`, created 2026-07-25T04:11Z, **PUBLIC**, and
     `origin/w17-headtrack` carries all of the above. `upstream`'s push URL remains disabled. Record that the
     accidental "no remote" protection is gone and what replaced it: a tracked `.githooks/pre-push`
     (enable per clone with `git config core.hooksPath .githooks`; refuses a `w17_first_active` build tag, a
     `FIRST_ACTIVE` identifier in Go/proto, or an active head-intent enum; verified to pass clean HEAD and
     bite on all three injections) **plus** the push-review rule in `FORK-NOTICE.md` — the hook is the
     accident guard, the rule is the control. What is published distributes **no control path**: proto still
     ends at `ACTIVE_LOG_ONLY = 8`, no `FIRST_ACTIVE` in tracked source, upstream licence files unmodified.
   - **Durable backups now exist** (2026-07-25, outside any scratchpad):
     `~/Documents/w17-backups/w17-mapper-allrefs-2026-07-25.bundle` (5.2 MB, `git bundle verify` = complete
     history, 10 refs; clone-tested with `go test ./pkg/headintent/` green) and
     `~/Documents/w17-backups/spent-gs-artifacts-2026-07-25.tgz` (SHA-256 matches the scratchpad original,
     15 entries; copied not moved, so the scratchpad copy can expire on its own). Honest limit: same physical
     disk — protects against repo deletion and session cleanup, not drive failure; GitHub now covers that axis.
2. **Closed since the last pass — record as done, not pending:** the viewer-only disclaimer (relocated,
   `769003b`), the four unpinned CSS rules (`12896fb`), the audit §3 staleness (`7c29a6b`), R01's
   implementation (`16d3d0a`), the `feelConstants.js:5` guard gap (`9c2d723`), and the `DESIGN_NOTES.md`
   §1/§2/§9/§11/§14 amendment (`w17-design-system` @ **`d53e6c4`**, clean and pushed). On that last one:
   §11(d)'s pill-row merge is **not** a supersede — the mockup always drew one `.pillrow` and the app carried
   two, so the merge brought the *app to the bundle*; record it that way. §11(e) records `.revwrap` as an
   intentional improvement (in the mockup its position is residue of the RUSSELL-plate/clock widths plus
   `.top`'s `right:calc(var(--gap) + 3em)` ⚙ inset, so it *cannot* be top-centre).

3. **Soundlight (2026-07-25, prompt 9) — record it; `ec5ddf8` is no longer that repo's HEAD.** Two commits:
   `2d22f85` CI enforcement and `5919685` the protocol-doc re-sync. Native **94/94**, `esp32dev` +
   `esp32dev_sim` both build, canonical guard re-run exit 0.
   - **The "two drift-checkers" joke had already landed before we got there.** That repo already had a
     `link2-drift` job (from `74b59f4`) with a hand-rolled inline diff loop — and that loop treated
     `docs/link2_protocol.md` as **fatal**, so control-fw's doc edit turned soundlight's `main` **CI red for a
     non-bug**. Verified by replaying the old logic (flags the doc and nothing else, exit 1), not assumed.
     `2d22f85` replaces it with a single source of truth.
   - **Design: fetch, don't fork.** The job anonymously shallow-clones control-fw into `$RUNNER_TEMP` (outside
     `GITHUB_WORKSPACE`, so the sibling never enters soundlight's source tree) and runs *this* repo's
     `tools/link2_copy_check.sh --strict`. Cost: a build-time dependency on control-fw's `main` — which fails
     **loudly** (exit 2) rather than quietly, exactly what `--strict` is for. Anonymous clone avoids the
     cross-repo token-scope question.
   - Exit codes fully disambiguated: 0 pass (plus a `::warning` when the doc tier reports, so the non-fatal
     tier is never invisible), 1 DRIFT, 2 COULD-NOT-CHECK (neither pass nor drift), 3 CI-bug/usage, anything
     else unexpected — all non-zero fail with distinct text. **Trap recorded:** GitHub's default shell is
     `bash -e`, which would collapse every exit code into one anonymous red X; `set +e` is load-bearing and
     commented as such.
   - **Verified by watching it fail:** the step's real `run:` body extracted from the YAML (not paraphrased)
     and run against throwaway fake siblings across **7 scenarios** — clean, injected `kPayloadLen`, deleted
     shared file, sibling missing `lib/link2`, checker absent, exit 3, exit 42.
   - Doc re-sync was **one-sided**, not three-way: soundlight's copy was byte-identical with zero local
     content, so the diff was purely additive. Upstream prose was corrected to receiver POV (see phase A item
     4), and stripping the two adapted blocks leaves the normative content — frame layout, payload table,
     state matrix, timing rule, worked example — **byte-identical across both repos**. No drift against the
     recorded decisions: the copy already read 1-based display gear, 1…4, TRAINING / RACE / ERS.
   - Consequence for the R06 record: once these are pushed the cross-repo guard is **enforced, not advisory** —
     drop that caveat.

4. **Live 13" pass DONE (prompt 8) — record it; three items it closed and two it opened.**
   - **BATT ordering RESOLVED toward the code** (owner, 2026-07-25): shipped order stands — BATT above the
     merged pill row, `BOOST·OVERTAKE·DRS` within it. Decisive measurement: both stacks occupy an identical
     envelope (y 643→782 at 1280×800), but the mockup order terminates the right column's bottom edge — the
     HUD's strongest horizontal alignment line, registering against the bottom-left R-STK panel — with a
     **99 px chip leaving a 184 px notch**, versus a full-width 283 px block. Bundle amendment (incl.
     `screens/05-hud.html`) is prompt 12 phase B, not an open question any more.
   - **`.revwrap` centering CONFIRMED** — offset from viewport centre **0.00 px**, and it stays 0.00 under a
     forced 30-char driver name, a 52-char team string, a long clock, and tiny values. `e01eb9f` achieved
     exactly what it set out to.
   - **`#addrStatus:empty` reserve works as designed** — empty ⇒ height 0; after CHECK ⇒ 33.6 px with the hint
     shifting down by exactly that. The one-time shift is a deliberate, code-commented trade.
   - **Viewer-only disclaimer verified genuinely once per session** — visible on boot GARAGE (36 px, in normal
     flow, crossing nothing), hidden on every later screen, still hidden after a full CHANGE SETUP →
     back-to-GARAGE round trip; both homes carry byte-identical copy.
   - Clean at all four sizes × both paths: rail `01..05`, GRID reads 05, solo shows `02 PIT WALL` struck
     through as `SKIPPED · DESKTOP`, zero horizontal overflow, no wrap. Invariants held in every screenshot
     (HEAD TRACKING LOCKED · SAFETY GATE NOT COMPLETE, ACTIVE AUTHORITY NOT REPORTED BY MAPPER, violet
     `STICK INPUT · PAD`, `ARM / FAILSAFE · NOT REPORTED BY CAR`).
   - **Two defects opened, both assigned to prompt 12 phase A:** **D1** — SETUP is **3.0–3.2 : 1** lopsided
     with ~300 px of dead left column at 1024×640; the split relocated §14(b)'s imbalance rather than solving
     it. Owner decision: **SETUP becomes a single centred column**; SEAT FIT is deliberately left alone
     because its right column is the *taller* one (1.31–1.38 : 1) — the earlier "SEAT FIT reads empty"
     premise was **inverted**. **D2** — `#gamepadPanel` is `display:block` with no gap inside a `gap:11.2px`
     column, so its six rows butt at 0 px and `NO CONTROLLER · KEYBOARD FALLBACK` collides with `LAYOUT`
     (measured: no true overlap). Pre-existing, one-line fix, approved.
   - **Stale rail comments fixed** in comment-only commit **`17ec1be`** (anchors had drifted to
     `renderer/index.html:131` / `renderer/setupFlow.js:129`); prompt 3a had **not** swept them. Landing onto
     `main` is prompt 12 item A0.

5. **Prompt 12 phase A DONE 2026-07-25 — ground station HEAD is `1a6f9f2`**, pushed, CI **`30150690390`**
   green (both jobs), suite **1090/1090 in 56 files**, `responsiveLayout` now **34** assertions.
   `17ec1be` (rail comments, own CI `30149835990` green, branch deleted) · `2c96eb1` (SETUP → one centred
   column) · `1a6f9f2` (`#gamepadPanel` rhythm).
   - **D1 overflow — record what it actually is, or it reads as a shipped defect.** Stacked SETUP exceeds the
     viewport at three of four sizes (30 / 72 / 95 px at 1280×800 · 1366×768 · 1024×640), and **every pixel is
     the `--gate-toast-reserve`** (121.6 px of `.gate` bottom padding held for the `position:fixed`
     `.radioLog`), **not content**. All content plus BACK/NEXT stays visible unscrolled at every size (worst
     case nav bottom 95.8% of a 640 px viewport); an all-elements intersection sweep found **zero** hits
     against the radio band. `.gate` already had `overflow-y:auto` + `justify-content:safe center`. Owner
     chose scroll.
   - **Two premise corrections, now test-pinned:** the dead left column was **~191 px, not ~300 px** (the
     41.8% / 71.6% figures reproduced exactly); and **SEAT FIT stays split** — a test asserts
     `.cols.seatcols` never gets `.stack`, because its right column is the *taller* one and the original
     assumption was inverted.
   - **D2:** defect reproduced before fixing (all six row boundaries measured exactly 0 px, then 11.2 px).
     Uses a new `--col-gap` token on `:root` consumed by both `.col` and `#gamepadPanel` so they cannot drift.
     One boundary reads 16.79 px because `.errdetail` has a pre-existing `margin-top:.35em` — deliberately
     left, since `.errdetail` is shared with the PIT WALL error panes.
   - **19 injected regressions** (9 for A1, 10 for A2) each proven to fail the intended assertion, including
     the silent-pass modes: `minmax(0,56ch)` vs `min(100%,56ch)`, the gap re-guessed as a literal `.7em`,
     `--col-gap` deleted or zeroed, and the rows wrapped in an inner `<div>` (satisfies every CSS assertion
     while collapsing the gap to 0).

6. **Correct a claim this file and every prompt in the series has been making:** the preload surface is
   **not** hermetically pinned at 24 keys. `test/ipcSurface.test.js` asserts symmetry plus
   `exposedKeys.length > 15`; the exact count is asserted only by `smoke:electron` (`apiKeys: 24`), which
   **cannot run on this macOS host**. So locally there is no tripwire — the pin exists in Windows CI only.
   Record it as an open item; the hard pin is assigned to prompt 6, to land **before** CB4 (the batch most
   likely to want a 25th key).

7. **Open items to carry forward** (all no-hardware). Everything else previously listed here is now closed —
   verify each before you keep it:
   - **Prompt 12 phase B** (`w17-design-system`): §11 + `screens/05-hud.html` amended to the shipped BATT and
     pill-row order, §14/§2 updated for the single-column SETUP, and the twice-superseded **"Adoption path"**
     entry ("SEAT FIT-before-PIT WALL order" as net-new) finally fixed.
   - **Prompt 6** (`w17-ground-station`, optional): CB1 right-stick indicator, CB4 Windows mDNS.
   - **Prompt 4b** (`w17-control-fw`, gated): the Wokwi run, blocked only on the owner deciding whether to
     upload firmware to Wokwi's servers.
   - `w17-3d-codex` has **2 unpushed commits** (`59a1634`, `2325fd9`) — Codex-owned; record, don't act.

8. **Add this hardware-class unknown to Pending validations** — drafted 2026-07-25, ready to paste as a
   sibling to the bullet ending ~line 522. It belongs with the Windows-hardware items, not buried in a
   dependency-bump record:

   > - **ELRS TX enumeration on real Windows (`go.bug.st/serial` v1.6.0): UNVALIDATED.**
   >   The v1.6.0 bump (`w17-mapper` `f0a18f3`) was cleared on timing grounds on this macOS
   >   host — `Write`/`Read` byte-identical v1.5.0 → v1.6.0 in both `serial_unix.go` and
   >   `serial_windows.go`, delta confined to enumeration / `Open` error wrapping / an
   >   uncalled `Drain()` / cgo wrappers, and `crsf.PackChannels` byte-identical (12 frames /
   >   312 bytes, one SHA across off / on-valid / on-stale / on-invalid). The one residual is
   >   **real Windows enumeration of the ELRS TX**, which no macOS host can exercise. Runs
   >   with the other Windows-hardware unknowns above (netsh/WinRT, camera→mediamtx→WHEP,
   >   real iPhone W2/W3, Windows DPAPI). Evidence ledgers, not duplicated here:
   >   `w17-ground-station/docs/setup_flow_bench_checklist.md` + the matrix in
   >   `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md`;
   >   `w17-control-fw/project-review/11_hardware_validation_plan.md`.

9. **New host limitation worth recording, because it changes every future GS session's gate list:**
   `npm run smoke:electron` **cannot run on this macOS host** — Gatekeeper denies the `node_modules` Electron
   binary ("library load denied by system policy"). Reproduced at a clean `e09369b` before any change, so it
   is the **machine, not the code**. Windows CI covers it and passes. Record it so no future session reports
   a failed local smoke as a regression, or treats its absence as an untested surface. Also worth noting for
   test authors: **vitest scans an entire test file for the environment docblock token, including inside
   prose** — writing it in a comment silently switched `responsiveLayout.test.js` to jsdom and broke its
   `import.meta.url` file reads. There is now a warning note in that file.
3. **Branch cleanup:** `w17-batch1-measurements` (`c5d32c7`) is fully merged into `main` — confirm that, then
   delete it local and on origin.
4. **Commit the prompt files:** the session-prompt set has uncommitted edits and five new files
   (`w17-gs-followups-prompt.md`, `w17-design-system-sync-prompt.md`, `w17-gs-live-13in-pass-prompt.md`,
   `w17-soundlight-guard-prompt.md`, `w17-wokwi-run-prompt.md`, plus edits to
   `w17-workspace-bookkeeping-prompt.md`). `w17-gs-audit-followups-prompt.md` is **superseded** and carries a
   banner saying so — keep it as the provenance record, don't delete it.
5. Apply `05157b2`'s own rule to this pass: for every `PENDING` / `NOT_STARTED` line you keep, say whether
   you verified it still holds. Staleness here runs toward **over-reporting open work** — five instances so
   far (the nine audit findings, R05, R19, the `loopTask` watchdog question, and this file itself).

Show all diffs before committing. Docs-only. Do not edit any Codex-owned repo (`w17-3d-codex`,
`../Codex/*`). No gate changes: **A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**
