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

1. **Branch — and it's worse than a naming problem.** Verified 2026-07-25: `main` is at **`fbf22f0`** and the
   branch is **6 commits ahead and unmerged**, so the electrical BOM content (`78e1e88`, `1834852` — the
   D1-Mini/IMX335/PDB rows and the IP2326 charger) **is not on `main` at all**, alongside the four new
   commits. Anything reading that repo's `main` for BOM facts is reading a pre-BOM tree. Propose the fix —
   merge to `main` (with a rename first, since the name now describes only a third of its contents), or
   rebase — and tell me which you'd pick and why **before** doing it.
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
4. Verify before pushing: `pio test -e native` **225/225**, all three ESP32 envs build. Then push and report
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
   - **Mapper:** `f0a18f3` — `go.bug.st/serial` **v1.5.0 → v1.6.0**, and `go build ./...` is now **fully
     green** on this host; the long-standing go1.26 × cgo blocker is cleared. Update the four places that
     describe it as a temporary-and-reverted v1.7.1 bump only where they describe *current* state; leave the
     historical narrations alone. Push stays disabled; no upstream.
2. **Closed since the last pass — record as done, not pending:** the viewer-only disclaimer (relocated,
   `769003b`), the four unpinned CSS rules (`12896fb`), the audit §3 staleness (`7c29a6b`), R01's
   implementation (`16d3d0a`), the `feelConstants.js:5` guard gap (`9c2d723`), and the `DESIGN_NOTES.md`
   §1/§2/§9/§11/§14 amendment (`w17-design-system` @ **`d53e6c4`**, clean and pushed). On that last one:
   §11(d)'s pill-row merge is **not** a supersede — the mockup always drew one `.pillrow` and the app carried
   two, so the merge brought the *app to the bundle*; record it that way. §11(e) records `.revwrap` as an
   intentional improvement (in the mockup its position is residue of the RUSSELL-plate/clock widths plus
   `.top`'s `right:calc(var(--gap) + 3em)` ⚙ inset, so it *cannot* be top-centre).

3. **Open items to carry forward** (all no-hardware): **HUD BATT ordering + intra-row pill order deferred to
   a live 13" pass** (prompt 8) — code ships BATT-first with `BOOST·OVERTAKE·DRS`, mockup `05-hud.html` says
   BATT-last with `DRS·OVERTAKE·BOOST`; recorded as an open two-row table in `DESIGN_NOTES.md` §11 with
   `screens/05-hud.html` untouched and neither declared canonical. The **soundlight CI `--strict` step**,
   without which the cross-repo link2 guard is advisory only. Soundlight's copy of `docs/link2_protocol.md`
   needing a judgment-based re-sync (byte-identity is the wrong bar — the script reports that tier
   non-fatally and exits 0). Two **stale rail comments** in the ground station (`renderer/index.html:140`
   confirmed still describing `01..04 GRID`; the `setupFlow.js` one may already be gone — verify) — code is
   correct, only the comments lag `42319ad`. And in `w17-design-system`, the **"Adoption path" section**
   still lists "SEAT FIT-before-PIT WALL order" as net-new, twice-superseded (by §2 on 2026-07-20, then by
   the SETUP split).

4. **New host limitation worth recording, because it changes every future GS session's gate list:**
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
