# PROMPT — re-audit the electronics cassette (after the NO-GO), both-mini ESP config

Paste into Codex (ChatGPT) working in `w17-3d-codex`.

---

CONTEXT
Mechanical repo w17-3d-codex only. Re-audit the electronics-cassette NO-GO (ZK study) with two
changes that address both fail causes. Electrical design (PDB, connector map, ESP board choice) is
Claude's; you verify physical fit, update registers, refresh the cassette visualization. No
production STL before a fit gate. Verified-vs-assumed discipline. Change no existing analysis/STLs.

CHANGES SINCE THE NO-GO

1. ESP boards (VERIFIED — this is what shrinks the footprint that busted KO-01):
   BOTH ESP32 #1 (control) and #2 (sound/light) become small WROOM-32 MINI boards — the
   MH-ET Live ESP32 MiniKit / "D1 Mini ESP32" (ESP32-WROOM-32, ~39×31 mm, onboard micro-USB,
   24 GPIO broken out). Confirmed that all 11 control pins are exposed, including input-only
   34 (battery ADC1) and 35 (Hall), plus soundlight's 5 (link2 RX 16, I2S 22/25/26, WS2812 4) →
   firmware + pin map UNCHANGED on both, no remap. MUST be the dual-core WROOM-32 D1-Mini-ESP32
   form; NOT an ESP32-C3/S2/S3 "SuperMini" (different chip → firmware port).
   Two minis (~39×31 mm) replace the 2× DevKit V1 (~52×28) that overran KO-01.
   MOUNT BOTH VERTICALLY ON THE CASSETTE INTERIOR SIDE WALLS, micro-USB to an access edge; this
   frees the deck. Treat ~39×31×~13 mm (with headers) as the envelope until Claude confirms the
   calipered board.

2. Camera/gimbal: DECOUPLE from the cassette. Add a HOLLOW "cut-through" COCKPIT PEDESTAL that
   (a) holds the pan/tilt gimbal + IMX335 at cockpit/airbox height with verified FOV, halo/airbox
   clearance, and pan/tilt sweep envelope; (b) routes the camera USB + 2× MG90S leads DOWN through
   its hollow core to the cassette/PDB; (c) mounts to the floor/front structure, NOT on the
   electronics stack. Confirm this resolves the prior Z98-vs-~Z42 roof bust.

KEEP (validated last round)
PDB in the lower bay; single ganged umbilical routed via the R1/R2 EDGE corridors (not centre
spine); lift-out cassette; forward mass placement (CG was improving to ~38/62).

RE-AUDIT / VERIFY
1. Does the everything-inside layout NOW CLOSE — cassette (two wall-mounted ~39×31 mm minis) +
   battery + relocated ESC (44.2×37×24.2) + motor + belt + the decoupled cockpit pedestal —
   under the real shell sections and all keep-outs? Show it.
2. Re-examine mounting: with the shrunk cassette footprint, do EXISTING floor holes now give a
   clean retention pattern, or does the earlier 4-point boss/battery/ESC conflict now clear?
   Prefer existing holes; spec minimal bosses only if still required (no STL — spec + fit-gate).
3. Recompute CG with wall-mounted boards + decoupled pedestal; report front/rear % and Z-CG.
4. Extend the Z connection register: the two wall-mount ESP seats, pedestal↔floor joint, pedestal
   wiring conduit, gimbal↔pedestal, and the umbilical dock — confidence-tagged; DEFER in-transit
   parts.

DELIVERABLES
- Update the ZK cassette fit study (GO / conditional-GO / NO-GO with the new layout).
- Register updates: B, C, E, I, J, Z.
- Refresh the cassette visualization set under viz/cassette/ (same self-contained / theme-aware /
  to-scale / ruler style): everything-inside plan+side+section; exploded cassette (two wall-mounted
  minis); the cockpit pedestal + its cut-through wiring path; umbilical edge route.
- Prioritized ASM checks + open items for Claude (PDB, charge module, ESP SKU, connector map).

RULES
No production STL/relief before a fit gate. Don't invent — tag ASSUMPTION + ASM check. DEFER
in-transit parts. Mechanical repo only. Regenerate via script + re-run validators. List untracked
files preserved.
