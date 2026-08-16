# 16 — The Rebuild Track: Overview (SKELETON)

> **SKELETON — scope stubs, not chapters.** Files 16–22 map the *stranger-rebuild*
> journey required by vision decision 17 ("publishable, stranger-could-rebuild **and**
> full teaching depth") and the v1.0 "ideally" clause (`../W17_PRODUCT_VISION.md`,
> done-bar section). Each stub records its scope, prerequisites, existing sources, and
> an honest **"written when"** note — most of these chapters *cannot* be written yet,
> because their content is evidence the physical build has not produced. The stubs
> exist so the gap is mapped, owned, and impossible to forget, per the 2026-08-16
> vision audit (decision-17 row: "no rebuild-track chapters").

## Who this track is for

Chapters 01–15 teach **how the system works** to someone studying it. The rebuild
track will teach **how to make another one** to a competent stranger: a person with a
3D printer, a soldering iron, basic Linux/Windows skills, and no access to the owner.
The bar is concrete — at the end of this track, that stranger holds a driving W17.
It is *deliberately* a different voice from the glovebox booklet (chapter 14): the
booklet's reader operates a finished car; this track's reader builds one.

## The journey, in build order

| Stage | Stub | One-line scope |
|---|---|---|
| 1. Source the parts | [17_rebuild_sourcing_and_bom.md](17_rebuild_sourcing_and_bom.md) | every part, where it came from, what substitutes |
| 2. Print the car | [18_rebuild_printed_parts.md](18_rebuild_printed_parts.md) | STLs, materials, slicing, finishing — pointer-heavy (Codex territory) |
| 3. Build the electronics | [19_rebuild_pdb_and_harness.md](19_rebuild_pdb_and_harness.md) | PDB, connectors, harness, cassette packaging — anchored on the existing PDB guide |
| 4. Flash the boards | [20_rebuild_firmware_flashing.md](20_rebuild_firmware_flashing.md) | both firmwares, delivery vs tuning builds, verification |
| 5. Install the ground side | [21_rebuild_ground_side_install.md](21_rebuild_ground_side_install.md) | mapper + profile, ground station installer, GCS box |
| 6. First power-up | [22_rebuild_first_power_up.md](22_rebuild_first_power_up.md) | the A2 / Phase-B gate discipline, applied by a stranger |

Stages 1–5 can be *drafted* progressively as the project's own build proceeds; stage 6
can only ever be finalized from executed-gate evidence.

## Ground rules inherited by every stub

- **Gates are absolute.** Nothing in this track ever instructs powering or flashing
  hardware outside the discipline in stub 22 — the same A2 → Phase B ladder the
  project itself obeys (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`).
- **Cite, don't copy.** Where a canonical doc exists (the PDB guide, the BOM, the
  wiring atlas), the rebuild chapter references it and adds only the connective
  narrative — per the workspace's canonical-vs-copy registry (`../WORKSPACE_MAP.md`).
- **Codex territory stays Codex's.** Print files, shell mechanics, and the iPhone app
  are owned by the Codex side (`../CLAUDE.md` ownership split); the rebuild track
  points at their *outputs* (STL inventory, print decisions) and never re-derives them.
- **[C]/[I]/[A] discipline** applies as everywhere in the manual; a rebuild
  instruction that has not been performed on real hardware is at best **[I]** and must
  say so.

## Written when (for this overview itself)

This overview graduates from SKELETON to chapter when at least stages 1–4 have real
content, at which point it gains: the full tool list, a time/cost envelope from the
actual build log, and the "what order actually worked" narrative.
