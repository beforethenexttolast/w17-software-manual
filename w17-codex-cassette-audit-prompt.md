# PROMPT — audit + visualize the second-layer electronics cassette

Paste into Codex (ChatGPT) working in `w17-3d-codex`.

---

CONTEXT
Mechanical repo w17-3d-codex only. A new packaging architecture was decided (owner + Claude). The
ELECTRICAL design (power-distribution board schematic, connector map) is Claude's side — you audit
the PHYSICAL feasibility, integrate into your registers, and produce a SEPARATE visualization set.
Do NOT emit production STL before a fit gate. Keep your verified-vs-assumed discipline. Change no
existing analysis, values, conclusions, or STLs.

ARCHITECTURE TO AUDIT
- A single lift-out ELECTRONICS CASSETTE on a SECOND DECK under the body's tall centre spine,
  bolted to the floor. PREFER existing floor holes/features; add minimal M3 bosses ONLY if required
  (spec them; verify no conflict with donor floor features / Suspension_Block_10 / belt / battery /
  ESC). Placed FORWARD to help the 35/65 rear bias.
- Two levels (use your D-28 envelopes; PDB + charge module are new — treat as parametric until
  Claude supplies dimensions):
  - Lower bay: 2× UBEC 5 A, 1000 µF cap, the power-distribution board (PDB), MAX98357A amp.
  - Upper deck: 2× ESP32-WROOM-32 DevKit (USB-accessible for reflash), RadioMaster RP1,
    BL-M8812EU2 WiFi module + 28×28×3 heatsink in a vented sub-bay.
- Cassette TOP also carries the CAMERA GIMBAL base (2× MG90S pan/tilt + IMX335 camera) in a COCKPIT
  position (= camera Option A). This RELOCATES the camera from the nose pod — verify airbox/halo
  clearance, FOV, and the pan/tilt sweep envelope; compare to the nose-pod option and recommend.
- Heavy/hot stay on the floor, OFF the cassette: 2S LiPo, QuicRun 10BL120 G2 ESC
  (44.2×37×24.2, placement currently failing), motor, belt.
- One "umbilical": a single multi-connector harness bundle from the cassette/PDB to the fixed
  consumers (steering servo front, ESC/motor rear, WS2812B rear, Hall rear-axle, DRS servo rear).
  Connectorized (XT power, 3-pin servo leads, keyed JST-XH signal); the electrical connector map
  comes from Claude — you place/route/clear it physically.

AUDIT / VERIFY (evidence-backed, same rigor as your fit studies)
1. Propose ONE "everything-inside" layout that CLOSES: cassette + battery + relocated ESC + motor +
   belt together under the real shell sections, since all-electronics-inside is the owner's #1
   priority. Show the cassette footprint fits the two-level stack + gimbal under the spine and
   clears steering sweep, belt loop, suspension bump, and wheels (your keep-outs).
2. Mounting: can the cassette use EXISTING floor holes? If not, spec minimal M3 bosses and verify no
   donor-feature conflict. No production STL yet — spec + fit-gate it.
3. CG: recompute mass/balance with the cassette (forward) + gimbal-on-top (raises Z-CG); report
   front/rear % and Z-CG vs the prior model; flag if it exceeds the owner's "rear bias acceptable,
   no hard weight cap" intent.
4. Umbilical: confirm a routable bundle path along the spine to each fixed consumer; note
   strain-relief/anchor points and body-off unplug access.
5. Service: 4-point lift-out; DevKit USB reflash access (a body-off hatch or reachable port).
6. Extend the CONNECTION/joint register (Z_) with the new PHYSICAL joints (cassette↔floor,
   PDB↔cassette, DevKit standoffs, gimbal base↔cassette, umbilical connector seats), confidence-
   tagged; DEFER in-transit parts (MG90S, 2S pack, charge module).

DELIVERABLES
- A cassette fit study under fit_studies/ (Z-prefixed), mirroring your existing studies.
- Register updates: envelope (B), keep-out (C), placement (J), risk (E), zone/layer (I), connection (Z).
- A SEPARATE visualization set under viz/ (same self-contained / theme-aware / to-scale / ruler
  style as your zone + connection pages):
  (a) plan + side + section of the cassette in the everything-inside layout (cassette + battery +
      ESC + motor + belt) to scale under the real shell section;
  (b) an EXPLODED cassette sheet (floor → bosses → box → lower-bay modules → deck → DevKits/RP1/WiFi
      → gimbal base) with callout balloons + an assembly-order strip;
  (c) the umbilical route + connector seats.
  Embed real STL silhouettes where meshes exist; non-mesh hardware as technical outline;
  ASSUMPTION = dashed/hatched. Link from viz/index.html.
- Prioritized ASM checks + open items for the owner/Claude (e.g., final PDB + charge-module
  dimensions from Claude).

RULES
No production STL/relief before a fit gate. Don't invent — tag ASSUMPTION + add the ASM check. DEFER
in-transit parts. Mechanical repo only. Regenerate via a script and re-run the validators. List
untracked files preserved. Treat PDB, charge module, and connector map dimensions as parametric
placeholders until Claude provides them.
