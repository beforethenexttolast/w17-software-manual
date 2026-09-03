# 18 — Rebuild: Printed Parts (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

The car's body and mechanical structure: which STLs to print (base platform: OpenRC
"RC-01" belt-drive F1, chapter 01 §1, plus W17-specific parts), materials and print
profiles, print order, test-fit gates, finishing/painting/decals for the Mercedes W17
livery, and printed-part assembly up to (not including) electronics installation.
This chapter is **pointer-heavy by design**: printing/mechanical decisions are made
and recorded outside this manual's authority.

## Prerequisites

Stub 17 (parts on hand: fasteners, bearings, belt, servo, inserts). A calibrated
printer; the profiles chapter will state the printer assumptions honestly.

## Existing sources to build from (cite, don't copy)

- **[C]** `w17-3d-codex/` — the Claude-side printing & fabrication repo: model
  inventory (`01_inventory`), ready-to-slice sets, Bambu print profiles, test-print
  results, printed-parts log, finishing notes, assembly notes. This is the primary
  source; the rebuild chapter narrates it for a stranger.
- **[C]** `w17-rc-print-codex` (sibling `Codex/` folder, outside this workspace —
  `../../Codex/w17-rc-print-codex` from this file) — ChatGPT Codex's print-decision project.
  **Codex territory: consult read-only, never edit** (`../CLAUDE.md` ownership split).
- **[C]** Fit authority examples the chapter must respect rather than restate:
  steering-servo side-mount fit study, `servosaverv7` front-pivot finding (Codex fit
  study is authoritative — recorded in workspace memory and `../CURRENT_STATUS.md`).
- **[C]** Vision constraints that shape printing: shell preserved unmodified,
  electronics inside, hidden USB-C flap, lift-out cassette second deck
  (`../W17_PRODUCT_VISION.md`; packaging architecture record).

## Written when

After the project's own car is printed and assembled: the real print log (what failed,
what warped, what got reprinted in which material) becomes the chapter's spine. The
DRS flap mechanism and charge-flap placement are open Codex dependencies (vision
decisions 13/14) — the chapter cannot close until those parts exist and fit.
