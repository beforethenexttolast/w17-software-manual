# Session prompt — 1. Close the ground-station SETUP-step WIP (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-ground-station`.

Run this **first** — prompts 2 and 3 both depend on this commit landing.

---

There is an **uncommitted 7-file change** in this repo that I need reviewed, committed, and pushed.
Nothing here needs hardware. This repo is **viewer-only** — see `w17-ground-station/CLAUDE.md`.

What's on disk (verified 2026-07-25): `renderer/hud.css`, `renderer/index.html`,
`renderer/setupFlow.js`, `shared/setupSteps.mjs`, `test/responsiveLayout.test.js`,
`test/setupFlowDom.test.js`, `test/setupSteps.test.js` — modified, on top of HEAD `3119180`
("feat(setup): reorder PIT WALL before SEAT FIT, add DRIVE MODE, rebalance SEAT FIT, start-lights off").
The change splits a new **`SETUP`** step (drive mode + camera mode) out of SEAT FIT, so the flow becomes
`garage → pitwall → seatfit → setup → grid` (desktop/solo omits `pitwall`). The in-file comment dates it
2026-07-20. Suite was **1046/1046 across 53 files, green** with this WIP applied.

Do this:

1. **Read the full working diff before anything else** and tell me, in plain terms, what it changes —
   step machine, rail/screens, markup, CSS, and which tests were rewritten vs added. Flag anything that
   looks half-finished, orphaned, or inconsistent with the committed `3119180` reorder.
2. **Check it against the design system.** `../w17-design-system/DESIGN_NOTES.md` §2 records the shipped
   flow ordering. If this WIP contradicts what's recorded there, say so — do **not** silently edit the
   design repo (it is its own repo; 1 commit is currently unpushed there).
3. **Re-verify** — `npx vitest run`, `npm run smoke:electron`, `npm run proto:check`, and confirm
   `test/noControlPath.test.js` + `test/ipcSurface.test.js` (exactly 24 preload keys) are green.
4. **Invariant check:** no new IPC or path reaching a control output; HEAD TRACKING card stays
   `LOCKED · SAFETY GATE NOT COMPLETE`; ACTIVE AUTHORITY stays `NOT REPORTED BY MAPPER`; no label may
   imply this app aims the camera or moves hardware.
5. **Show me the diff, then commit** in focused commits (feature + tests together is fine; don't bundle
   unrelated cleanups). Then **push** and report the resulting HEAD.
6. **Windows CI:** CI has not been re-verified past app `e0a5cdc` / docs `170fd66`. After the push,
   watch the `windows-latest` `package-smoke` job (`npm test` + `smoke:electron` + `electron-builder --dir`)
   and give me the run ID and result. This is the one place we get Windows evidence **without hardware** —
   real Windows/Pixel behaviour stays unvalidated either way.

Do **not** update `CURRENT_STATUS.md` here — prompt 2 does the workspace sync in one pass. Just report the
new HEAD and the CI run ID so that session can record them.
