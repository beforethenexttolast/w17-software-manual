# Session prompt — 12. SETUP rebalance + HUD bundle amendment (no hardware)

Two phases in two different repos. Finish phase A and report before starting phase B.
All owner-decided 2026-07-25 off the back of the live 13" pass (prompt 8).

---

## PHASE A — `w17-ground-station` (start the session in that directory)

Baseline: `main` at **`9c2d723`**, suite **1082/1082 across 56 files**. Viewer-only invariants apply —
see `w17-ground-station/CLAUDE.md`.

### A0. Land the rail-comment sweep that's stranded on a branch

Commit **`17ec1be`** ("comment-only rail sweep") sits on branch `docs/rail-comment-sweep`, unpushed. It fixes
the stale `01..04 GRID` prose at `renderer/index.html:131` and `renderer/setupFlow.js:129` (anchors had
drifted from the 129/130/128 in the earlier prompt). `main` hasn't moved, so it should fast-forward. Rebase
or merge it onto `main`, push, then delete the branch. Verify 1082/1082 first.

### A1. SETUP becomes a single centred column (owner decision)

The live pass measured SETUP at **3.0–3.2 : 1** (DRIVE MODE left vs CAMERA MODE right) at every size — at
1024×640 the left column ends ~40% down while the right runs to ~70%, leaving **~300 px of dead left
column**. `DESIGN_NOTES.md` §14(b) originally put CAMERA MODE in SEAT FIT's right column to balance *that*
screen; the split (`42319ad`) relocated the same problem one screen later. Note the earlier premise was
**inverted**: SEAT FIT's right column is not empty — LIVE MIRROR fills it and it is the *taller* column
(1.31–1.38 : 1). Do **not** "fix" SEAT FIT.

Decision: **drop the two-column split on SETUP.** Stack DRIVE MODE, then CAMERA MODE, in one centred column;
remove `wide` from that section if it no longer earns it.

**Measure before you commit — this is the one real risk.** The right column already runs to ~70% at
1024×640, so stacking may overflow vertically. Report actual heights at **1280×800 · 1366×768 · 1024×640 ·
1470×956** (the audit's sizes, for comparability). If it overflows at 1024×640, **stop and tell me** with the
numbers and your recommendation — allow the screen to scroll, or compress (tighter gaps, smaller note type,
side-by-side pill row). Do not silently pick one.

Preserve: the DRIVE MODE click handler is delegated on `#driveModeRow` and bound once at module load, and
`renderCameraMode()` resolves `#camModes`/`#camAuthority` by id — so moving markup between sections must not
orphan either. `enterSetup()` announces `radio('SETUP: DRIVE & CAMERA MODE')`; keep it. `shared/cameraMode.mjs`
stays untouched.

### A2. Give `#gamepadPanel` vertical rhythm (owner-approved one-liner)

`#gamepadPanel` is `display:block` with **no gap**, nested in a `.col` that has `gap:11.2px`. Its six rows
(DEVICE → padList → ctlStatus → LAYOUT → presetRow → keyboardHint) butt together at exactly 0 px, so
`NO CONTROLLER · KEYBOARD FALLBACK` and `LAYOUT` visually collide while everything else in the column
breathes. Measured: no true overlap, just zero spacing. **Pre-existing** — not caused by `42319ad`. Fix with
the column's own gap token rather than a magic number. Separate commit.

### A3. Testing, given this host cannot launch Electron

`npm run smoke:electron` and all CDP-driven launching are **impossible on this Mac** — the binary aborts at
the dynamic linker (`Library not loaded: @rpath/Electron Framework.framework/Electron Framework … library
load denied by system policy`). Gatekeeper vs the `node_modules` Electron, before any app code runs. **Not a
regression; do not report it as one.** Windows CI covers that surface.

Reuse the harness the 2026-07-25 pass built, which worked: copy `renderer/` + `shared/` into the scratchpad,
inject a stub matching the real `window.groundStation` surface (**20 methods**, shapes taken from
`test/setupFlowDom.test.js` and `normalizeSettings`), and serve it to Chromium. Real HTML/CSS/JS, real
modules, real telemetry through the real `onTelemetry` path. **Never touch the repo tree for a visual
experiment** — copy to scratchpad instead, so there is nothing to revert.

**Time-saver worth knowing:** the pane reports `visibilityState: "hidden"`, so `requestAnimationFrame` is
frozen during JS probes and resumes only on screenshot capture. Early HUD readings of `--` are the probe, not
the app. Don't chase it.

Add real vitest coverage for A1 and A2 — `test/responsiveLayout.test.js` is where the CSS contracts live
(now 26 assertions). Verify each new assertion **bites** on an injected regression before committing; this
repo has shipped three guards that passed without proving anything (`085e1d1`, `feelConstants.js:5`, and a
pre-push hook whose `\b` pattern silently matched nothing).

Gates: `npx vitest run` · `npm run proto:check` · `npm run feel:check` · `noControlPath` + `ipcSurface`
(exactly 24 preload keys) + `responsiveLayout` green · `git diff --check` clean. Push and report HEAD + the
CI run ID. **Do not touch `CURRENT_STATUS.md`** (prompt 10 is the single writer) or `w17-design-system`.

---

## PHASE B — `w17-design-system` (restart the session in that directory)

Baseline `d53e6c4`, clean and pushed. Docs/mockup only.

### B1. HUD right-column order — resolve the open decision toward the code

§11 currently records BATT ordering as an **open** two-row table pending this pass. It's decided:
**keep the shipped order** — BATT above the merged pill row, and `BOOST·OVERTAKE·DRS` within the row. Amend
§11 and **`screens/05-hud.html`** to match, and record the reasoning, because it's the substance of the
decision:

- Both stacks occupy an identical envelope (y 643→782 at 1280×800). The decisive difference is the **bottom
  edge**: the right column's lower boundary is the HUD's strongest horizontal alignment line, registering
  against the bottom-left R-STK panel. The shipped order terminates it with a full-width 283 px block; the
  mockup order terminates it with a **99 px chip, leaving a 184 px notch** in the bottom-right corner, and the
  chip reads as detached from the panel above. Visible at 1280×800, worse at 1024×640.
- BATT is a slow, always-relevant value: at the top of the stack it sits adjacent to the speed/gear scan
  zone rather than in the least-scanned corner.
- The narrow element at the *entry* to the stack means the stack resolves into full-width blocks instead of
  decaying into a chip.
- Intra-row: the row is `justify-content:flex-end`, so it reads right-to-left off the screen edge, and DRS —
  the most transient, most glanceable indicator — belongs nearest that edge. This is a **weaker** preference
  than the BATT call; record it as such.

### B2. Record the SETUP single-column decision

§14 (and §2 if it describes SETUP's layout) must reflect phase A: SETUP is a **single centred column**, not
two. Record *why* — the split relocated §14(b)'s column-imbalance problem rather than solving it (3.0–3.2 : 1,
~300 px dead left column at 1024×640) — and that SEAT FIT is deliberately left alone because its right column
is the taller one (1.31–1.38 : 1), inverting the original assumption. Follow the §10/Decision-B pattern:
state what supersedes what and on whose decision, keeping the superseded intent legible.

### B3. Fix the stale "Adoption path" entry

It still lists "SEAT FIT-before-PIT WALL order" among net-new items — twice superseded (by §2 on 2026-07-20,
then by the SETUP split). The 2026-07-25 session flagged it and left it; fold it in now.

Show diffs before committing. Push and report HEAD. **Do not touch `CURRENT_STATUS.md`** or
`w17-ground-station`.
