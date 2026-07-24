# W17 batch-1 physical measurements — Claude → Codex handoff

**Date:** 2026-07-24 · **Session:** no-power physical bench (hardware R&D)
**Scope:** MEASURED component envelopes + module weights for on-hand batch-1 parts. This is the
measured follow-up to `w17-electrical-inputs-for-codex.md` (which carried TARGET/ASSUMPTION
values). It is a **handoff for the Codex mechanical registers** — Claude does not edit the
`w17-3d-codex` repo. Photos: `w17-3d-codex/images_of_parts/batch_1/`.

**Method / conventions**
- Every row is **MEASURED** with digital calipers / gram scale unless tagged otherwise.
- Envelope = **L × W × H** in the part's own frame; installed-orientation notes are called out.
- Comparisons are against the ZK cassette study (`10_assembly_architecture/fit_studies/ZK_electronics_cassette_fit_study.md`) §3/§6 allocations.
- **No power** was applied. **A2 remains NOT-EXECUTED; Phase B remains BLOCKED.** Nothing here
  changes a gate — it feeds mechanical fit only.
- **Fit-gates (Track C: S0 / steering sweep / tyre arch) and the physical servo dry-fit (Track D)
  were NOT performed this session** — only component calipers (Track A) + weights (Track B).

---

## 0. Board decision — resolves the ESP32 identity flag

**DECISION (owner, 2026-07-24): both controllers will be MH-ET Live D1-Mini ESP32, to free
cassette space.** Owner is sourcing a **USB-C** variant.

- This **makes the ZK "FIRM" input true by procurement** (39 × 31 mm class, WROOM-32), rather
  than by the on-hand boards. The 39 mm single-board wall-row, the `X+3…+42` seat, and the
  `S0 ≥ 9.82 mm` derivation all stand on the MH-ET premise — they remain valid.
- **The on-hand USB-C DevKit V1 clones (30-pin "ESP-32D") are TEST / SPARE boards only** — they
  are what passed the 2026-07-22 bare-board smoke test. They are **not** the cassette controllers.
- **Still pending:** caliper the actual MH-ET boards (bare + with-headers height + USB-C plug
  protrusion + which short edge carries USB) and weigh them, once purchased. ZK CAS-03 stays open
  until then; the identity/envelope premise is confirmed but the *physical* board is not yet on hand.

---

## 1. Measured envelopes + weights

| Part | MEASURED L × W × H (mm) | Weight (g) | ZK assumption / doc | Δ / flag |
|---|---|---|---|---|
| **BL-M8812EU2** Wi-Fi (with heatsink) | 32.4 × 32.0 × 7.0 | 11.2 (w/ antennas) | alloc ≤ 60 × 32 × 12, **uncalipered/unplaced** | ✅ fits; **width 32 = at the ≤32 limit** (no margin on that axis), huge length/height margin. Antenna length not yet measured. Height-with-heatsink worth a re-check vs the photo's tall fins. |
| **QuicRun 10BL120 G2 ESC** | 44.2 × 33.7 × **34.0** | 100 | 44.2 × 37 × **24.2** (documented) | ⚠️ **+~10 mm taller** — the 34 mm is the **top fan + finned heatsink** stack; also needs intake air above. Width 33.7 < 37 (ok). **ESC station Z1.5…25.7 is too short.** |
| **RocketRC V3 17.5T motor** ("540") | 55 body / 70 incl. shaft × Ø35.8 (can) ; shaft Ø3.3 | 156.7 | not in ZK envelope table | Heaviest single item; rear mass. + solder tabs. |
| **DS3235SG servo** (no horn) | 40.25 (54.5 w/ lugs) × 37.8 × 20.2 | 70.3 (w/ horn) | ~40 × 20 side face (fit study) | See §3 — confirms the arch interference. |
| **DS3235SG + 25T horn** | 40.25 (54.5 w/ lugs) × 44.8 × ~37.5 | (as above) | horn radii doc 19.5 / 23.5 | horn adds width to 44.8, height to ~37.5. |
| **UBEC 5V/5A** (each, ×2) | 44.3 × 22.1 × **9.1** | 10 (w/ resistor) | PDB height "**UBEC dominates**" → 18 mm | ⚠️ **UBEC is 9.1 mm, not ~18 mm** — PDB height over-estimated. See §2. |
| **MAX98357A** amp | 18.7 × 17.9 × 3.0 (+ pins) | 10.4 (amp + speaker) | amp body ASSUMPTION | ✅ tiny; service-deck cell easily fits. |
| **Speaker** | 35.3 × 25.1 × 6.1 | (incl. above) | — | — |
| **RP1 receiver** | 13.4 × 11.4 × 4.05 (w/ ant. conn.) | 1.6 (w/ antenna) | DOCUMENTED | ✅ tiny/light; measured w/o antenna body. |
| **WS2812B strip** (1 m / 30) | — × — × 9.5 (strip width) | 17 (per 1 m) | in audio/light group | length used = harness-defined. |
| **BX100** buzzer (optional) | 40.1 × 28.6 × 13.0 | 13.4 | optional | not a cassette occupant. |
| **FT232 UART→USB-C** (bench tool) | — | 3.4 | — | bench-only, not in car. |

*Connectors (XT60/XT30/JST-XH/servo/U.FL): owner uses standard commodity parts — use the ZK
default connector-body allocations (§7); no per-part caliper needed for these.*

---

## 2. Two design-consequential findings (both hit the #1 blocker: steering clearance)

The ZK limiting result is **steering, not shell**: `KO-01 bottom Z22 − PDB top Z19 = 3 mm`, which
is **5 mm short of the 8 mm moving policy** (ZK §4). Both height findings below act on that margin.

### 2a. UBEC is 9.1 mm, not ~18 mm → PDB can likely be much shorter (HELPS)
The 55 × 45 × **18** mm PDB target set its 18 mm height because "UBEC height dominates". Measured
UBEC height is **9.1 mm**. With both UBECs lying flat (44.3 × 22.1 each → ~44 × 44 footprint, fits
the 55 × 45 plan), the tallest PDB part is now **whichever of the 1000 µF cap / XT60 / loop key is
tallest — not the UBEC.**
- **Action for Codex:** re-derive PDB height from `max(cap height, XT60 body, loop-key body)` on a
  9.1 mm UBEC floor, not from an 18 mm UBEC. If the real stack is ~12–14 mm, PDB-top drops from Z19
  toward ~Z13–15, **recovering several mm of the 5 mm steering deficit.**
- **Still needed to close it:** measured **1000 µF cap height**, XT60 and loop-key body heights
  (not captured this session). These now govern PDB height.

### 2b. ESC installed height is 34 mm, not 24.2 mm (HURTS — but ESC is a floor item, not cassette)
The top-mounted cooling fan + finned heatsink make the installed ESC **34 mm** tall (photo
`QuicRun ESC.jpg`), ~10 mm over the documented 24.2 mm. The ZK ESC floor station is **Z1.5…25.7**.
- **Action for Codex (CAS-06 / ASM-49):** the ESC station Z-envelope is ~8 mm short and must be
  re-measured with the fan on; **add fan intake-air clearance above** the heatsink; re-check the
  ESC body against KO-01 and the shell shoulder at its floor L-band.
- Note: this is the ESC on the **floor**, not in the cassette — it does not touch the PDB height
  logic in 2a, but it does reopen the ESC clearance gate.

---

## 3. DS3235SG side-on fit — caliper confirms the predicted interference

Fit study (`p0_d09_d26_steering_servo_fit.md`) arch opening: **42.0 long × 18.5 high**. Measured
servo cross-section presented to the arch (side-on, shaft horizontal): **40.25 × 20.2**.
- Length: 40.25 < 42.0 → **1.75 mm clearance** ✅
- Height: 20.2 vs 18.5 → **~1.7 mm interference** ⚠️ (fit study predicted ~1.5 mm — **confirmed**)
- Body with mounting lugs = 54.5 mm vs the 58 mm holder pitch → ~1.75 mm each side.

**The physical no-force dry-fit (Track D) was NOT done this session.** The caliper confirms the
interference is real, so Track D must establish whether the printed holder flexes to accept it or
truly binds. **Do not file/force** — a test-grade print can bind from layer swell alone; production
tolerance or a small holder-arch relief on the CAD side (Codex) is the resolution, not a knife.
Shaft-centre orientation (boss-forward X−46.76 vs reversed X−66.76) also still to be pinned.

---

## 4. Weights → CG ledger (ZK §6)

The ledger runs on ASSUMPTIONS: PDB **~50 g** (incl. both UBECs + cap), control/RF group **72.5 g**.
Measured so far:
- **PDB contributors:** 2 × UBEC = **20 g** (+ cap + board + XT60 + loop-key + charge module, TBD).
- **Control/RF group:** Wi-Fi+antennas 11.2 + RP1 1.6 + **2 × MH-ET ESP32 (TBD, ~9–10 g each)** ≈
  **~33 g** + wiring — likely **well under the assumed 72.5 g** (the assumption used DevKit-class
  masses). Group will lighten.
- **Heavy floor items:** motor **156.7 g**, ESC **100 g**, servo **70.3 g** dominate the ledger.
- **Audio/light:** amp+speaker 10.4, LED 1 m 17.
- **Pending:** MH-ET ESP32 mass (on purchase); 1000 µF cap / XT60 / loop-key / charge-module mass.
- **Four-corner scaling** needs a rolling test assembly — deferred (ZK CAS-11 / ASM-58).

---

## 5. Codex gate mapping

| ZK / ASM gate | Fed by this batch | State |
|---|---|---|
| **CAS-03** (caliper both boards) | §0 board decision | premise confirmed; **real MH-ET caliper still pending purchase** |
| **D-06b** (Wi-Fi body/heatsink placement) | §1 BL-M8812EU2 32.4×32×7 | ✅ **unblocked** — fits ≤60×32×12; can be placed |
| **CAS-04 / ASM-22** (PDB refine) | §2a UBEC 9.1 mm | **re-derive PDB height**; needs cap/XT60/loop-key heights |
| **CAS-06 / ASM-49** (ESC station) | §2b ESC 34 mm + fan air | ⚠️ **Z-envelope too short — reopen** |
| **ASM-08 / CAS-01** (steering sweep) | §2a helps, §3 servo | still needs the physical sweep (Track C2) |
| **CAS-02 / D-04** (S0) | — | **not measured** (Track C1 pending) |
| **CAS-11 / ASM-58** (weights + 4-corner) | §4 module weights | module weights in; four-corner deferred |
| **CAS-10 / D-10** (dock) | §1 note | standard commodity connectors → ZK default allocations OK |

---

## 6. Still open / not measured this session
- Real **MH-ET D1-Mini** board caliper + weight (on purchase); USB-C variant TBD.
- **1000 µF cap, XT60, loop-key, charge-module** heights — now govern PDB height (§2a).
- Wi-Fi **antenna length**; ESC **fan intake-air** requirement.
- **Track C** fit-gates: S0 (≥4 pts), steering sweep, tyre arch (tyres in transit).
- **Track D** physical servo no-force dry-fit + shaft-centre orientation.
- Tyres (Tamiya, in transit) block the arch-clearance gate.
