# Session prompt — 3. Ground-station audit follow-ups (no hardware)

> ## ⚠️ SUPERSEDED 2026-07-25 — DO NOT RUN AS WRITTEN
>
> This prompt's premise is false. It says "Findings 2–7 are still open." **They are not — all 9
> findings of the 2026-07-17 audit are closed**, verified against live code on 2026-07-25:
>
> | Finding | Fixed in | Evidence at HEAD `3119180` |
> |---|---|---|
> | 1 HIGH — wheel profile never persists | `a04b07c` | `shared/settings.js:191` conditional-spread admit + `test/wheelProfilePersist.test.js` |
> | 2 MED — wrong device when no wheel at START | `5141912` | `renderer/hud.js:143` honest `INPUT · WHEEL (NO DEVICE)` tag |
> | 3 LOW — WHEEL mode follows first pad slot | `5141912` | WHEEL mode has its own device selector |
> | 4 LOW — keyboard mirror dead with no pads | `5141912` | `wheelActive` gating; mirror no longer zeroed |
> | 5 LOW — ⚙ reachable during start-lights | `ec1baef` | `renderer/setupFlow.js:1799-1802` `lightsRunning` guards |
> | 6 LOW — fast-path card steals focus | `ec1baef` | `renderer/setupFlow.js:161` boot-only focus |
> | 7 LOW (docs) — Batch 9 deferrals unrecorded | `ec1baef` | in-code markers in `renderer/uiNav.js` |
> | obs — design bundle §10 vs BOTH mode | `e57f587` | Decision B, resolved both ways |
> | obs — `readAxis`/`clampAxis` dedupe | — | explicitly **waived** in-code, `shared/wheelProfile.mjs:88` |
>
> A follow-on defect that closure-verification of `ec1baef` surfaced is also fixed (`085e1d1`: the
> BOTH-mode source tags shipped `.barsrc hidden` but `hud.css` had no generic `.hidden` rule, so the
> tags leaked into single-mirror modes and the jsdom class-only assertions passed vacuously).
>
> **What is actually stale is the audit document**, whose §3 still reads "fixes are follow-up work,
> none applied". If you want a session here, the real remaining job is to annotate
> `docs/audits/2026-07-17_setup_flow_redesign_audit.md` §3 with the per-finding resolutions above —
> not to re-fix working code. Kept for that purpose and as the provenance record.


Paste into a Claude Code session started at `~/Documents/projects/w17-ground-station`.

Run **after** prompt 1. Viewer-only invariants apply throughout (`w17-ground-station/CLAUDE.md`).

---

The setup-flow redesign audit (`docs/audits/2026-07-17_setup_flow_redesign_audit.md` §3) recorded 9
findings and deliberately fixed none. **Finding 1 (HIGH) has since been fixed** — `normalizeSettings`
now admits a validated `wheel.profile` subtree (`shared/settings.js:191`) with a hostile-corpus test.
Findings 2–7 are still open. Fix them, no hardware needed.

Work in this order — verify each anchor against live code first, the line numbers are from 2026-07-17 and
have drifted:

1. **MED — wheel mirror resolves the wrong device when no wheel is present at START.**
   `applyInputSource` (`renderer/setupFlow.js:~892`) falls back to `wheelKey ''` when `resolveWheelPad`
   returns null; `wheelPad()` (`renderer/hud.js:~139`) then resolves the **first** pad — the gamepad —
   through the wheel calibration, so an idle centred axis reads THR≈50% under an `INPUT · WHEEL` tag.
   Display-only but actively misleading. Fix so an absent wheel yields **no** wheel mirror rather than a
   mislabeled gamepad one. Note the audit's related observation: in a wheel-only session `pad()` falls back
   to the wheel and the violet camera dot mirrors the wheel's axes 2/3 as `STICK INPUT · PAD` — that one is
   pinned by the `hudWheel` test and is **intended**; don't break it.
2. **LOW — ⚙ reachable via pad during the start-lights countdown** (`renderer/setupFlow.js:~1724`):
   `settingsOnly()` is false while the gate is visible and only `back()` carries the `lightsRunning` guard,
   so button 9 (or d-pad + confirm on ⚙) opens settings over the lights.
3. **LOW — fast-path card steals focus on every GARAGE entry** (`renderer/setupFlow.js:~166`): CHANGE SETUP
   and BACK-to-garage also focus STRAIGHT TO THE GRID, so a stray Enter bounces back to GRID. The approved
   deviation covered the **boot landing only** — scope the focus to that.
4. **LOW — keyboard driving mirror dead in a WHEEL/BOTH session with no pads** (`renderer/hud.js:~261` +
   wheel override): keyboard STR/THR/BRK are overwritten with neutral and the button block is skipped;
   the pre-wheel HUD mirrored keys in that state.
5. **LOW — WHEEL (non-BOTH) mode always follows the first pad slot** (`renderer/setupFlow.js:~872`): with a
   gamepad in slot 0, ASSIGN / SET REST / SET FULL listen to the gamepad. This is *plan-conformant* (the
   selector was promised for BOTH only) — so **propose** the fix and let me decide before you widen scope.
6. **LOW (docs) — Batch 9 deferrals live only in the external plan file.** Add the durable in-code marker
   the audit recommends at `renderer/uiNav.js:~38` and `~203`.

Then:

- **Close the audit doc honestly:** mark finding 1 fixed (cite the commit that fixed it), record 2–6 as
  fixed with their commits, and leave anything I deferred marked deferred with the reason. Do not
  retroactively rewrite the audit's original verdicts.
- **Regression gates:** `npx vitest run` (baseline **1046/1046, 53 files** before prompt 1's WIP; expect the
  WIP's count), `npm run smoke:electron` 4/4 (`apiKeys:24`), `npm run proto:check`, plus
  `noControlPath` / `ipcSurface` / `responsiveLayout` green. Add a real test per behavioural fix — several
  of these findings survived because `setupFlowDom` mocks `gs.setSettings`, so prefer tests that go through
  the real path where you can.
- **Out of scope, do not touch:** head tracking / any enable path for it (safety-gated, lives in
  `w17-mapper`), and the audit's known perf observations (`uiNav.pollOnce` per-frame allocation,
  `dedupeGamepads` 2×/frame, `snapPad` ≈ `snapshotPad`) unless I ask.
- Show diffs before committing; small focused commits; push and report HEAD + CI.
