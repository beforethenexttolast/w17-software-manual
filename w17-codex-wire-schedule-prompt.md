# PROMPT — full wire schedule / harness table (pins → solder points → lengths)

Paste into Codex (ChatGPT) working in `w17-3d-codex`.

---

CONTEXT
Mechanical repo w17-3d-codex only. Build the complete WIRE SCHEDULE for the harness — every
conductor, its two endpoints (module + pin/pad), connector, solder-vs-crimp, physical route, and a
cut length. The ELECTRICAL truth (which GPIO/pad, signal, rail, connector) is AUTHORITATIVE from
Claude's `w17-electrical-inputs-for-codex.md` connector map (and the firmware pin maps it cites) —
DO NOT invent or change pin assignments; pull them verbatim. Your job adds the PHYSICAL half
(endpoint coordinates, routed path, length). No STL; verified-vs-assumed discipline; change no
existing analysis/values/STLs.

PRODUCE a wire schedule (md table + csv), ONE ROW PER CONDUCTOR:
- wire_id
- signal + rail (A clean / B servos / power / RF)
- endpoint A: module . pin/pad (exact GPIO/pad from the connector map, e.g. `ESP32#1.GPIO25`)
- endpoint B: module . pin/pad (e.g. `ESP32#2.GPIO16`)
- connector at A / at B (XT60 / XT30 / JST-XH n-pin / 3-pin servo / U.FL / shielded USB) and whether
  that end is SOLDERED or CRIMPED-into-connector
- from (X,L,Z) → to (X,L,Z) — from the J placement matrix + cassette / pedestal / umbilical geometry
- route: which corridor (R1/R2 edge, pedestal conduit, umbilical dock, on-PDB)
- wire gauge per current: battery main ~16–18 AWG, rails ~20–22 AWG, servo ~22–26 AWG, signal
  ~26–28 AWG (the BOM stocks 28 AWG silicone). State per row.
- length: routed distance + service slack + strain-relief allowance → a CUT LENGTH
- confidence + a "CUT-TO-FIT AT DRY-FIT" flag

RULES / DISCIPLINE
- Lengths depend on placements that are still CONDITIONAL (S0 unpinned, pack + IP2326 charge module
  not sourced, cassette gated). Give ROUTED ESTIMATES + generous slack and mark them
  ASSUMPTION / cut-to-fit — NO false precision. Lengths finalize at the physical dry-fit.
- DEFER conductors whose endpoint hardware is in transit: MG90S ×3, 2S pack, IP2326 charge module.
- Group rows by bundle: on-PDB, on-cassette, pedestal-conduit, and umbilical, so it reads as a build
  sequence.
- Power-connector source side stays shrouded (no live pins); color + label per the connector map.

DELIVERABLES
- `Z_wire_schedule.md` + `Z_wire_schedule.csv` under 10_assembly_architecture/ (or extend the Z
  connection register), cross-linking each row to its Joint ID where one exists.
- A totals summary: total length per gauge (for ordering wire) + connector/pin counts.
- Optionally annotate the umbilical viz page with per-run lengths.
- Prioritized open ASM checks (the dry-fit measurements that firm the lengths).
- Regenerate via a script + re-run validators; list untracked files preserved.
