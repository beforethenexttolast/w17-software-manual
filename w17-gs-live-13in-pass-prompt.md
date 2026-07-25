# Session prompt — 8. Live 13" pass: settle BATT order + review the 5-step flow (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-ground-station`.

Run **after** prompts 3a and 7. This is the "decide after seeing it" session the owner asked for — the point
is **screenshots to look at**, not code changes.

Baseline: HEAD **`9c2d723`** (prompt 3a landed 5 commits; suite 1082/1082 across 56 files, CI run
`30144513077` green). macOS Electron, live CDP-driven, no hardware, no car.

**Host limitation you will hit:** `npm run smoke:electron` **cannot run on this macOS host** — Gatekeeper
denies the `node_modules` Electron binary ("library load denied by system policy"), reproduced at a clean
`e09369b` before any change. It is the machine, not the code; Windows CI covers that surface. Do **not**
report it as a regression, and do not treat it as a blocker for this pass. If CDP-driven launching hits the
same wall, say so plainly and fall back to whatever you *can* drive — a partial screenshot set honestly
labelled beats none.

## 1. The deferred decision: HUD right-column order

Code ships **BATT above** the merged pill row; `../w17-design-system/screens/05-hud.html` puts **BATT last**.
The intra-row order also differs — code `BOOST·OVERTAKE·DRS`, mockup `DRS·OVERTAKE·BOOST`.

Produce a **side-by-side screenshot pair** of the real HUD in both orders (flip the CSS locally for the
second shot — do not commit the flip), at the sizes below, with representative telemetry so the values are
readable rather than empty. Then give me your recommendation with the reasoning, and I'll pick. Include the
intra-row order in the same comparison.

## 2. Review the 5-step flow live

The SETUP split (`42319ad`) has never been seen running at small sizes. Walk both paths —
`garage → pitwall → seatfit → setup → grid` (iphone-hud) and `garage → seatfit → setup → grid` (solo) —
and screenshot every screen at **1280×800 · 1366×768 · 1024×640 · fullscreen** (the sweep sizes the
2026-07-17 audit used, so results are comparable).

Look specifically for:
- **SEAT FIT's now-single-column-ish balance.** CAMERA MODE was originally placed in its right column
  explicitly "to balance the columns" (`DESIGN_NOTES.md` §14(b)); that balancing is undone and the right
  column is now just the LIVE MIRROR. Does it read as empty or lopsided at 1024×640?
- **The new SETUP screen's two columns** — does `wide` hold at the narrow sizes, or does it wrap badly?
- **`.revwrap` centering** — confirm the rev strip is now optically centred on the viewport and no longer
  drifts with the RUSSELL-plate/clock widths or the ⚙ inset. This is the change's whole purpose.
- **The `#addrStatus:empty` reserve collapse** on PIT WALL — before and after a CHECK result lands.
- **The relocated viewer-only disclaimer** from prompt 3a, in both homes: legible, not crossing content, and
  genuinely once-per-session across a `CHANGE SETUP` → back-to-GARAGE round trip.
- **Rail numbering** `01..05` at every size, and that GRID reads 05.

## 3. Two stale rail comments (only if prompt 3a didn't already take them)

Found by the 2026-07-25 design-system session, which correctly left them alone as out of its repo:
`renderer/index.html:129-130` and `renderer/setupFlow.js:128` both still describe the rail as
`01 GARAGE · 02 PIT WALL · 03 SEAT FIT · 04 GRID`. **The code is correct** — only the comments lag the SETUP
split (`42319ad`), which made it `01..05` with SETUP at 04 and GRID at 05. Verify the anchors, fix the
comments, one commit. Check first whether prompt 3a already swept them; if so, skip and say so.

## 4. Ground rules

- **Read-only on behaviour.** Fix only what the pass proves broken, and tell me before you do; a layout
  defect found here is a separate reviewed commit, not a drive-by.
- Any CSS you flip for comparison purposes gets reverted — end the session with a clean tree unless a fix
  was explicitly approved.
- Keep the invariants in view while screenshotting: HEAD TRACKING `LOCKED · SAFETY GATE NOT COMPLETE`,
  ACTIVE AUTHORITY `NOT REPORTED BY MAPPER`, camera dot violet `STICK INPUT · PAD`, no label implying this
  app aims the camera or moves hardware. If a screenshot shows otherwise, that's the finding of the session.
- **Do not touch `CURRENT_STATUS.md`** (prompt 2 is the single writer) or `w17-design-system` (prompt 7).
  Once I pick the BATT order, the bundle amendment is a follow-up in that repo.
- Report: the screenshot set, your BATT recommendation, and any defect list — as text.
