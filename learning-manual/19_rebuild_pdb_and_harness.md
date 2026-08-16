# 19 — Rebuild: PDB & Harness Build (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

The electrical build: the power distribution board (PDB), the connectorized harness,
the charge/run interlock, and the lift-out cassette packaging that carries the two
ESP32 boards, ESC wiring, gimbal, sound and light hardware. Ends with a fully wired,
continuity-checked, **never-yet-powered** cassette ready for stub 20's flashing and
stub 22's gated power-up.

## Prerequisites

Stubs 17 (parts) and 18 (printed cassette/deck parts to mount onto). Soldering and
crimping skills; the chapter will state which connector tooling is assumed.

## Existing sources to build from (cite, don't copy)

- **[C]** **`../w17-pdb-build-and-connector-guide.md` — the anchor document.** The
  PDB build and connector scheme (including the charge/run interlock design the
  charging UX rides on, vision decision 13) already exists as that loose workspace
  guide. This chapter pulls it in **by reference** and adds only the
  stranger-narrative around it; duplicating it would create a second drifting copy,
  exactly what the canonical-vs-copy registry forbids.
- **[C]** `w17-control-fw/docs/w17_wiring_assembly_atlas.html` — the wiring atlas;
  pin truth lives in `w17-control-fw/lib/config/include/config/PinMap.hpp` (GPIO 34/35
  input-only, strapping-pin cautions — per that repo's `CLAUDE.md`).
- **[C]** Packaging architecture record (2026-07-24, `../CURRENT_STATUS.md` + workspace
  memory): lift-out cassette on a second deck, gimbal on top, PDB keystone,
  connectorized throughout, MH-ET D1-Mini boards, batch-1 measured envelopes.
- **[C]** `../HARDWARE_INVENTORY.md` for the actual connector/wire stock on hand.

## Written when

After the harness is physically built. Two classes of fact are bench-only: measured
lengths/routing that survive the real cassette (batch-1 envelopes are measured, but
the harness itself has not been), and the interlock's *proven* behavior (design ≠
evidence — the same rule chapter 12 taught). Photos of the real build are part of the
chapter's definition of done; a stranger wires from pictures, not prose.
