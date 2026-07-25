# Session prompt — 3a. Ground-station follow-ups from the prompt-1 review (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-ground-station`.

Replaces `w17-gs-audit-followups-prompt.md`, which is **superseded** — all 9 findings of the 2026-07-17
audit are already closed in code (that file is kept as the provenance record and explains why). This prompt
is the real remaining work in this repo, all owner-decided 2026-07-25.

Baseline: HEAD **`e09369b`**, clean tree, level with `origin/main`, CI green (run `30128883953`).
Suite **1046/1046 across 53 files**, `smoke:electron` 4/4 (`apiKeys:24`), `proto:check` OK.
Viewer-only invariants apply throughout — see `w17-ground-station/CLAUDE.md`.

Three items. Do them as three separate commits.

## 1. Relocate the viewer-only disclaimer (owner decision)

Commit `0950298` deleted the pinned `gateFootnote` overlay — "Viewer only — elrs-joystick-control drives
the car; this window mirrors inputs and overlays telemetry." That removed the **only** in-UI statement of
what this app is. The owner does **not** want it restored as the overlay (it wasted vertical space and
transiently crossed content at `scrollTop 0`). Put it back somewhere better:

- **Permanent home: the settings panel.** Always available, never in the way. This is the primary fix.
- **Plus once per session:** surface it once where the user will actually read it — the GARAGE landing is
  the natural spot. It must appear **once per app session**, not on every GARAGE entry: `CHANGE SETUP` and
  BACK-to-garage both re-enter that screen, and re-showing it each time recreates the nuisance the removal
  was meant to fix. A module-level `shown` flag is enough — do **not** persist it to `settings.json`
  (a new run should state what the app is again). Tell me which mechanism you used and why.
- Requirements: no `position: fixed` overlay that can cross content; must not shift the GARAGE fast-path
  card's boot-only focus behaviour (`renderer/setupFlow.js:161`); dismissible or self-limiting, never modal.
- **Add a test asserting the string is present** in both homes, and one asserting the once-per-session
  behaviour. The original had no test, which is how its deletion went unnoticed.
- Propose the exact placement and wording to me **before** writing the markup — this is user-facing copy on
  a safety-adjacent claim, so I want to see it first. Keep the mapper-authority phrasing accurate:
  elrs-joystick-control drives the car, this app mirrors and overlays.

## 2. Pin the four unasserted CSS rules (owner decision)

Commits `e01eb9f` / `e09369b` shipped four layout rules that **no test asserts**. Add assertions to
`test/responsiveLayout.test.js` — that file exists for exactly this:

1. `.revwrap` — absolutely positioned direct child of `.hud`, `left:50%` / `top:var(--gap)` /
   `transform:translateX(-50%)`, i.e. centred on the viewport rather than flexed inside `.top`.
2. Right-column order — BATT above the single merged pill row. (Order is **provisional** — see item 3 —
   so write the assertion so a deliberate flip is a one-line test change, and say so in a comment.)
3. GRID carries `wide`.
4. `#addrStatus:empty { min-height: 0 }` — collapses ~37 px of dead reserve above the PIT WALL note until a
   CHECK result lands.

Why this matters here specifically: this repo has already been bitten once. The Batch-3 defect (`085e1d1`)
shipped BOTH-mode source tags with `.barsrc hidden` while `hud.css` had no generic `.hidden` rule, so the
tags leaked into single-mirror modes **and the jsdom class-only assertions passed vacuously**. Assert the
resolved CSS contract, not just the presence of a class name.

## 3. Annotate the audit document (docs-only)

`docs/audits/2026-07-17_setup_flow_redesign_audit.md` §3 still reads "fixes are follow-up work, none
applied". All nine are closed. Annotate each finding in place with its resolution commit — 1 HIGH `a04b07c`
(`shared/settings.js:191` conditional-spread admit + `test/wheelProfilePersist.test.js`) · 2 MED, 3, 4
`5141912` (honest `INPUT · WHEEL (NO DEVICE)` tag at `renderer/hud.js:143`; WHEEL-mode device selector;
`wheelActive` gating) · 5, 6, 7 `ec1baef` (`lightsRunning` guards at `renderer/setupFlow.js:1799-1802`;
boot-only focus at `:161`; `uiNav.js` in-code markers) · §10 observation `e57f587` (Decision B, resolved
both ways) · `readAxis`/`clampAxis` dedupe **waived** in-code at `shared/wheelProfile.mjs:88`. Also record
`085e1d1` as the follow-on defect that closure-verification surfaced.

**Do not rewrite the audit's original verdicts or its 2026-07-17 findings text** — annotate. The value of
that document is that it recorded what was true when written.

## 4. R01 — label the simulated armed/failsafe indicators (owner decision 2026-07-25)

Owner decision: the HUD's `armed` / `failsafe` indicators **stay simulated but must say so**. Option "add
A/F to the FLIGHTMODE string" was rejected — `"G4 M2 E100 A1F0"` is 15 chars and *exactly* fits the budget,
R13 (does a real ELRS/handset relay a custom FLIGHTMODE status string at all?) is unproven, and
`parseFlightMode`'s per-field fallback is tested only on the clean-ASCII path, so a mid-token truncation
could surface a **wrong** armed state. An honestly-labelled simulated indicator beats a possibly-wrong real
one. Revisit only after R13 is proven on hardware.

The car has no ground-bound carrier for these today: `link2` carries `armed` + `failsafe` but only to
board #2, and the handset only ever sees `M%u` (a number).

- Label the indicators in `renderer/hud.js` (and wherever else they render) so it is unambiguous that the
  values are **simulated**, not from the car. Today a real link loss silently reverts them to sim values and
  the "LINK LOST" alarm fires only in demo mode — that is the defect being closed.
- Propose the exact treatment to me before implementing — a `SIMULATED` tag, a muted style, the
  `NOT REPORTED BY MAPPER` pattern already used for ACTIVE AUTHORITY, or something else. Consistency with
  that existing muted-unreported convention is probably the right instinct, but I want to see it.
- Add a test. This is the same class of gap as the deleted viewer-only footnote: an honesty claim with
  nothing asserting it.

## 5. Fix the `feelConstants.js` guard that only guards itself

`shared/feelConstants.js:5` claims "A test guards these against drift," but `test/replay.test.js:77` only
asserts the JS constants against **hardcoded literals** (26/11/1.18) — it never reads the firmware's
`ErsSystem.hpp`. It proves the constants haven't drifted from *themselves*. This is the live instance of the
`crsf.js` overstatement pattern, found during the 2026-07-25 control-fw session (which confirmed its own
repo is clean: `Link2Codec.hpp`'s cross-check claim is real, `ErsSystem.hpp`'s HUD-values claim checks out).

It is also the one place a firmware feel change would silently desync the HUD.

Build it like `proto:check`, the pattern this repo already trusts: a **hermetic** test against a checked-in
canonical snapshot of the firmware values, plus a **non-hermetic** `npm run` check that parses
`../w17-control-fw/lib/ers/include/ers/ErsSystem.hpp` (verify the path) and reports drift. Control-fw now
has the twin of this: `tools/link2_copy_check.sh` with `--strict`, exit 1 = drifted, exit 2 =
could-not-check. Match those semantics — a missing sibling must not silently pass in CI.

Either fix the comment's claim or make it true; do not leave it as-is. And verify your guard **bites** on an
injected change, the way the control-fw session verified its own (injected `260→250` fails).

## Gates before anything ships

`npx vitest run` · `npm run smoke:electron` 4/4 · `npm run proto:check` · `noControlPath` + `ipcSurface`
(exactly 24 preload keys) green · `git diff --check` clean. Show diffs before committing. Push and report
HEAD + the CI run ID. **Do not touch `CURRENT_STATUS.md`** — the bookkeeping session (prompt 2) is the
single writer; hand your results back as text. Do not edit `w17-design-system` — prompt 7 owns that.
