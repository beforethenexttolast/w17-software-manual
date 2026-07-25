# Session prompt — 7. Amend DESIGN_NOTES to match the shipped flow (docs-only, no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-design-system`.

Owner decision 2026-07-25: **the code is authoritative, the bundle gets amended.** The SETUP split is a
genuine improvement — SEAT FIT becomes purely controller/input instead of the mixed screen the bundle
describes — so `DESIGN_NOTES.md` moves, not `w17-ground-station`.

Baseline: this repo is at `6a59c96` ("docs: sync DESIGN_NOTES with shipped setup flow"), clean tree, with
**1 commit unpushed**. `w17-ground-station` is at `e09369b`. **Edit this repo only** — the ground station is
correct as shipped and must not be touched.

Read the shipped code before writing a word of doc: `../w17-ground-station/shared/setupSteps.mjs`,
`renderer/setupFlow.js` (`RAIL_STEPS`, `enterSetup`), `renderer/index.html` (the
`<section class="setup-screen wide" data-step="setup">`), and `renderer/hud.css`. Where my summary below
disagrees with the code, **the code wins and you tell me**.

## What shipped (commits `42319ad`, `e01eb9f`, `0950298`, `e09369b`)

- New **SETUP** step: `garage → pitwall → seatfit → setup → grid`; solo/desktop `garage → seatfit → setup → grid`.
- Rail is now `01 GARAGE · 02 PIT WALL · 03 SEAT FIT · 04 SETUP · 05 GRID` — GRID renumbered 04 → 05.
- DRIVE MODE (pill row + `#driveModeNote`) and the CAMERA MODE block **moved off SEAT FIT** into the new
  two-column SETUP screen, stepname `SETUP · MODE & CAMERA`. `shared/cameraMode.mjs` untouched.
- SEAT FIT's right column is now just the LIVE MIRROR.
- SEAT FIT entry now announces `radio('SEAT FIT: CONTROLLER MAPPING')`.
- HUD: `.revwrap` moved out of the `.top` flex row to an absolutely-positioned direct child of `.hud`
  (`left:50%; top:var(--gap); transform:translateX(-50%)`) so it centres on the viewport instead of drifting
  with the RUSSELL-plate/clock widths and the ⚙ inset. BATT moved to the top of the right column and
  BOOST/OVERTAKE/DRS collapsed from two `.pillrow`s into one.
- The pinned `gateFootnote` overlay was deleted; GRID gained `wide`; `#addrStatus:empty` collapses its
  reserve.

## Amend these sections

| § | Currently records | Amend to |
|---|---|---|
| §1 | rail `01..04 GRID`, "extends naturally to a future 05 step (e.g. a head-tracking gate)" | five steps, GRID = 05; the reserved future-gate slot becomes **06** |
| §2 | "Screen count is unchanged; only the order differs." Desktop = `GARAGE → SEAT FIT → GRID` | screen count **+1**; both paths as shipped above |
| §14(a) | DRIVE MODE is "a pill row … under [INPUT TYPE]" on SEAT FIT | DRIVE MODE lives on SETUP |
| §14(b) | "CAMERA MODE moves to the right column, under the LIVE MIRROR … This balances the columns" | CAMERA MODE lives on SETUP; the column-balancing rationale is **superseded** — record why (SEAT FIT is now single-concern), don't just delete it |
| §9 + §14(b) | both reason about "the nav and footnote clear" / "clears the pinned radio/footnote overlays" | the footnote no longer exists; the disclaimer is being **relocated** to the settings panel + once-per-session (prompt 3a) — reference that, and leave the exact wording open until 3a lands |
| §11 | `05-hud.html` right column = pillrow → ERS → BATT (BATT last); pill row `DRS·OVERTAKE·BOOST` | record the **pill-row merge** as shipped and canonical (it matches §11); record **BATT ordering as an OPEN deferred decision** — see below |

Follow the precedent already in this repo: §10 was amended exactly this way on 2026-07-19 (Decision B),
where the shipped stacked-full-panel BOTH-mode layout superseded the `02c` mockup. Match that tone — state
what supersedes what and on whose decision, and keep the superseded intent legible rather than erasing it.

## BATT ordering — do NOT resolve

Owner deferred it: **"decide after seeing it."** Code ships BATT-**first**; `screens/05-hud.html` says
BATT-**last**; the intra-row order also differs (code `BOOST·OVERTAKE·DRS` vs mockup `DRS·OVERTAKE·BOOST`).
Record it as an **open decision pending a live 13" pass** (prompt 8) with both candidates and the argument
for each — battery-first because it's the value that ends a session and belongs where the eye lands, versus
mockup-order for bundle fidelity. Do **not** edit `screens/05-hud.html` yet, and do not declare either
canonical. `test/responsiveLayout.test.js` in the GS repo will pin the current order with a comment marking
it provisional.

Also note the `.revwrap` deviation honestly: the mockup keeps it inside `.top` as a flex child, the code
absolutely-positions it on `.hud`. It serves §13's "top-centre" semantics **better** than the mockup does —
record it as an intentional improvement, not an accidental drift.

## Finish

Show diffs before committing. Docs-only, focused commits. Push — including the pre-existing unpushed commit
(check whether it should go separately or ride along; tell me which). **Do not touch `CURRENT_STATUS.md`**
(prompt 2 is the single writer) and do not touch `w17-ground-station`. Report the new HEAD as text.
