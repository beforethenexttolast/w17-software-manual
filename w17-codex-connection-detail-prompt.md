# PROMPT — project-wide assembly CONNECTION detail (joint level)

Paste into Codex (ChatGPT) working in the mechanical repo `w17-3d-codex`.

---

CONTEXT
Mechanical repo w17-3d-codex only. Your fit/clearance analysis and zone visualizations are done
and good — do NOT add more fit analysis or re-render for its own sake. This is a DIFFERENT kind of
detail: how every part physically CONNECTS to its neighbour — the practical "build it" level.
Extend the assembly master manual and add exploded connection diagrams, project-wide, at exactly
the detail level of the steering example below, and MAINTAIN that level everywhere. Keep your
verified-vs-assumed discipline and the existing self-contained HTML viz style. Change no source
analysis, values, conclusions, or STLs.

TARGET DETAIL LEVEL (the bar to hit for EVERY joint) — the steering output chain:
DS3235SG 25T shaft → 25T metal horn (press onto the spline, retained by the servo's own horn
screw) → horn outer hole (19.5 or 23.5 mm radius) takes a ball stud / rod-end → M4 tie rod ≈22 mm
→ rod-end at the far end → ball stud on servosaverv7's side-input arm → servosaverv7 pivots on a
vertical M3 boss (dowel/king-pin + circlip, or M3 screw). For EACH link state: hole Ø + thread,
which BOM fastener, how it is retained (clip / nut / press / circlip / threadlock), the assembly
step + what must be built first, the tool, and a confidence tag. Every joint in the car gets this.

SCOPE — every mechanical joint, all zones
Steering (formalize the example), front suspension (king pins, arms, shocks, uprights, bearings,
tie rods), rear drivetrain (motor mount, pinion↔spur mesh, belt, pulleys, output shaft, rear
bearings, axle spacers, rear shock), servo + holder mount, camera pod + blower, battery tray +
USB-C charge module + port + charge/run interlock, electronics trays (2× ESP32, RP1, WiFi module,
2× UBEC, cap), audio (amp + speaker), lighting (WS2812B segments + lenses), sensor (Hall + magnet),
body/shell fasteners (heat-set inserts, body bosses, shell landing points).

PER-JOINT CONTENT (one row each, in a NEW connection register)
- Joint ID + the two parts joined
- Connector hardware, mapped to the BOM list below
- Interface feature: hole Ø / bore / thread / spline — VERIFIED from the STL where possible, else
  DOCUMENTED / ASSUMPTION
- Fastening + retention: screw / nut / ball-stud+rod-end / press / bearing / insert / circlip / threadlock
- Assembly step number + order dependency
- Tool + torque/threadlock note
- Confidence tag + any ASM physical check; DEFER joints whose hardware is still in transit

BOM HARDWARE to map joints to (use these; do not invent):
M3 ball studs; M3 tie-rod ends (3Racing); M4 40 mm threaded rod (cut to ~22 mm tie rods); M4 24 mm
rod-ends; M3 king pins (dowel + circlip) 30 mm; heat-set M3×5 brass inserts; M3 bolts 8/10/12/20/30
+ nuts; front bearings 8×12×3.5, rear 12×21×5; metal sleeves D5×M3; turnbuckles 3×32; belt-drive
set + 75T spur / 28T pinion; DS3235SG 25T metal horn; onboard USB-C 2S balancing charge module (SKU TBD).

DELIVERABLES
1. A CONNECTION/JOINT register (new md + csv under 10_assembly_architecture/), sortable by zone and
   by assembly order.
2. Extend P_assembly_master_manual.md into a step-by-step, joint-by-joint build sequence that cites
   each Joint ID.
3. Exploded CONNECTION diagrams (HTML, same self-contained / theme-aware / to-scale / ruler style as
   the zone pages): per assembly, show the parts separated along their assembly axis with callout
   balloons naming part + hardware + size, plus a short "assembles in this order" strip. Embed real
   STL silhouettes where a mesh exists; draw non-mesh hardware as a technical outline. Solid = VERIFIED,
   dashed/hatched = ASSUMPTION.
4. Link the connection diagrams from viz/index.html.

RULES
Do not invent hardware specs — tag every unmeasured value ASSUMPTION and add the ASM check. Defer
joints whose parts are still in transit (MG90S, rear 68 mm shock, magnets, 2S pack, charge module).
Change no existing analysis/values/conclusions/STLs. Mechanical repo only. Regenerate via a script and
re-run the validator. List any untracked files preserved. Keep this joint-level detail as the standard
for all future assembly work.
