# 17 — Rebuild: Sourcing & BOM (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

Everything a stranger must *acquire* before building: electronics, RC gear, mechanical
hardware, battery/charging parts, consumables — each with the exact part chosen for
the original build, why it was chosen, acceptable substitutes, and the traps
(look-alike parts, wrong-voltage variants, input-only ESP32 pins driving part choice).
Ends with a priced, dated shopping list a stranger can execute in one pass.

## Prerequisites

None — this is the track's entry point. (Reading chapters 01 and 03 first makes the
part names meaningful.)

## Existing sources to build from (cite, don't copy)

- **[C]** `w17-control-fw/docs/bill_of_materials_v2.md` — the canonical BOM.
- **[C]** `../HARDWARE_INVENTORY.md` — the workspace arrival/on-hand ledger with
  BOM-mapping confidence per line; already resolves several ambiguous listings
  (e.g. "wifi antennas" → 5.8 GHz U.FL omni, not 2.4 GHz ELRS).
- **[C]** Board decision 2026-07-24 (`../CURRENT_STATUS.md`): both controllers are
  **MH-ET Live D1-Mini ESP32 (USB-C)**; the ESP32-WROOM-32 DevKit V1 clones on hand
  are TEST/SPARE only. The rebuild list must carry the MH-ET boards, not the DevKits
  chapters 05/11/13 predate.
- **[C]** Radio pair: ES24TX Pro ELRS TX module + RadioMaster RP1 receiver
  (`../HARDWARE_INVENTORY.md` §2); charging: IP2326 2S USB-C balancing charger.
- **[I]** The gift-kit decision adds ground-side parts to the BOM (hotspot Wi-Fi
  adapter, USB hub, GCS-box materials) — scoped in stub 21 but *sourced* here.

## Written when

After the physical build freezes the part set: every substitution the build actually
made is recorded, quantities are corrected from build experience (spares consumed,
lengths of wire, connector counts from the final harness), and prices/links are
captured once as a dated snapshot. Do not write the final version from the BOM alone —
the inventory ledger already shows the BOM and reality drifting (order counts vs
on-hand counts).
