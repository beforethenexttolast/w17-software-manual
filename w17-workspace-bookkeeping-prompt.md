# Session prompt — 2. Workspace bookkeeping sync (no hardware)

Paste into a Claude Code session started at `~/Documents/projects`.

Run **after** prompt 1 (needs the new `w17-ground-station` HEAD + CI run ID).

---

The workspace docs have drifted behind the actual repos and several finished commits are unpushed.
Nothing here needs hardware and **no gate changes** — A2 stays NOT-EXECUTED, Phase B stays BLOCKED.

State verified 2026-07-25:

| Repo | Actual | Recorded in `CURRENT_STATUS.md` |
|---|---|---|
| `w17-ground-station` | **`e09369b`** (prompt 1 done: `42319ad` SETUP split · `e01eb9f` HUD rev-strip/BATT · `0950298` footnote removal · `e09369b` GRID wide + `:empty` reserve; pushed, level with origin) | `8441adb` |
| `w17-control-fw` | 4 commits on `1834852` (2026-07-25 zero-hardware batch; **225/225** native, +1 test; all three ESP32 envs build) — on the mis-named branch `docs/bom-cassette-electrical` | `8ed0a6c` |
| `w17-soundlight-fw` | `ec5ddf8` — **11 commits unpushed** | `4f25856` |
| `w17-design-system` | `6a59c96` — **1 commit unpushed** | (not carried) |
| workspace repo | on branch `w17-batch1-measurements`; `main` is **3 ahead of `origin/main`** | — |

Do this, in order:

1. **Push the finished work.** In `w17-soundlight-fw`, show me `git log --oneline @{u}..HEAD` (11 commits:
   `5747d95..ec5ddf8` — audio-task failure handling, wrap-safe engine timers, synth convergence, UART0
   diagnostics gating, README count fix). Confirm native tests are green (**expect 94/94**) *before*
   pushing, then push. Same for the single unpushed `w17-design-system` commit. Push only — no edits.
2. **Branch decisions — ask me, don't assume.** Two repos have branch problems:
   - Here: I'm on `w17-batch1-measurements` and `main` is 3 ahead of origin. Lay out the options (merge the
     branch to main and push; keep the branch and push both; PR) with what each implies for the other
     repos' hashes, and let me pick.
   - `w17-control-fw`: the 2026-07-25 zero-hardware batch (Wokwi run-status docs, CB3 comment fixes,
     `tools/link2_copy_check.sh`, the four recorded owner decisions) sits on a branch named
     **`docs/bom-cassette-electrical`**, whose name no longer describes its contents. Propose a rename or a
     move to a correctly-named branch, and whether it should merge to that repo's main now.
3. **`HARDWARE_INVENTORY.md`** has an uncommitted 337-line rewrite. Read it, then finish the job
   `CURRENT_STATUS.md` (2026-07-24 entry) says it still owes: the **ordered / in-transit electrical rows as
   ⏳** — 2× MH-ET D1-Mini ESP32 (USB-C), ceramic + electrolytic cap kits, Amass XT90-S anti-spark master
   switch + XT60→XT90 adapter, IP2326 2S Type-C balancing charger (18.3×31 mm), ZEEE 1500 mAh 2S LiPo
   (69×35×18, JST-XH, to be re-terminated to XT60), 1N5819 from office stock. Preserve the existing rewrite;
   don't clobber it. That file carries **arrival status only** — no hashes, no gate state.
4. **Sync `CURRENT_STATUS.md`** in one pass. Overwrite in place; do not append history. Four things there
   are provably wrong (all verified 2026-07-25):
   - **Checkpoint hashes** — see the table above.
   - **"Windows CI not re-verified at `8441adb`" is false.** CI has gone green repeatedly since:
     `8441adb` = run `29604865474` · `e57f587` = `29682909672` · `3119180` = `29724061397` ·
     `e09369b` = `30128883953` (ubuntu `test` + windows-latest `package-smoke`: `npm test` 53 files,
     `smoke:electron` 4/4 `apiKeys:24`, `electron-builder --dir`). Record the current one and drop the
     stale claim. Real Windows/Pixel **hardware** validation is still pending — that part stands.
   - **The setup-flow audit's 9 findings are ALL closed**, not "9 findings NOT fixed (follow-up)":
     1 HIGH `a04b07c` · 2/3/4 `5141912` · 5/6/7 `ec1baef` · §10 observation `e57f587` (Decision B) ·
     `readAxis` dedupe explicitly waived in-code (`shared/wheelProfile.mjs:88`). Plus the follow-on
     `085e1d1` (BOTH-mode source tags leaked into single-mirror modes — `.barsrc hidden` with no generic
     `.hidden` rule in `hud.css`, so jsdom class-only assertions passed vacuously).
   - **Test counts** — the recorded 984/984 (52 files) is stale; current is **1046/1046 (53 files)**.
   Also record the 2026-07-25 control-fw batch, which is **not** in `CURRENT_STATUS.md` at all:
   native **225/225** (was 224); **CB3 DONE** (also update the VR-FPV batch table row, and
   `VR_FPV_MASTER_PLAN.md` if it carries its own CB3 status); the four owner decisions R01/R05/R19/R06
   resolved (R05 and R19 closed as **documentation artefacts**, not real divergences — capacity misread as
   gear count, plus a stale mock at `docs/f1_hud.html:286`); `tools/link2_copy_check.sh` landed with the
   link2 copy declared **permanent-but-guarded**; and the Wokwi question **retagged `[HW]` →
   `[OWNER/tooling]`** — `esp32dev_sim` builds but has **never been run**, blocked on a Wokwi credential,
   not on the bench. Do not let that read as hardware-blocked. Nothing was promoted to PASS; the 2 s TWDT
   stays provisional.

   Then record the new open items owner-decided today: the viewer-only disclaimer is being **relocated**
   (settings panel + once-per-session, not restored as the deleted overlay); `w17-design-system`
   `DESIGN_NOTES.md` is being amended to match the shipped 5-step flow; and **HUD BATT ordering is
   deferred to a live 13" pass** (code ships BATT-first, mockup `05-hud.html` says BATT-last).
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
6. **Standing lesson to bake in — verify before acting.** Four items recorded as open have turned out to be
   already closed or misread: all 9 setup-flow audit findings (closed in `a04b07c`/`5141912`/`ec1baef`),
   R05 (array capacity misread as a gear count + a stale mock), R19 (a single stale comment), and the
   `loopTask` watchdog question (settled by R5-a months ago). Staleness in this workspace runs in the
   direction of **over-reporting open work**, not under-reporting it. Add a short note at the top of
   `CURRENT_STATUS.md` telling future sessions to re-verify any open item against live code before acting on
   it — the control-fw risk register now carries the same warning. Then apply that rule to this pass: for
   every remaining "PENDING"/"NOT STARTED" line you keep, say whether you verified it still holds.

7. Show all diffs before committing. Keep commits docs-only and focused. Do not edit any Codex-owned repo
   (`w17-3d-codex`, `../Codex/*`).
