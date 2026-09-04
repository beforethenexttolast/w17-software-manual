# PDB / harness continuity check sheet — multimeter only, NO POWER

**Evidence label at creation: NOT-EXECUTED.** No row below has been measured.

> **This sheet is a worksheet, not the gate.** The authority for every row, its
> expected value and its gate attribution is
> `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` (call it **A2**).
> If this sheet and A2 ever disagree, **A2 wins** and this sheet is wrong. Row IDs here are
> A2's own row IDs so the two can be diffed line by line.
>
> **Golden rules (A2:105-107):** battery disconnected and out of reach. No USB, no bench PSU,
> nothing flashed. Multimeter only. A suspicious reading → **stop, photograph, report** — never
> "try again with power to see."

## Before the first joint — two OWED measurements that gate SF

Neither may be closed on paper (A2:217-222, `w17-pdb-build-and-connector-guide.md`:141-144).

| # | Measurement | Expected | Result | Status |
|---|---|---|---|---|
| OW1 | Caliper the ESP32 female-header socket stack against the ZK cassette clearance | **`S0` ≥ 9.82 mm** (A2:220-221) | | ☐ OWED |
| OW2 | Derive the adjacent-pin list from the **MH-ET Live D1-Mini silkscreen** | a written pair list (A2:140, :222) | | ☐ OWED |

If OW1 fails: the socketing decision (owner 2026-08-03 / F12) **reopens**, boards go hard-wired,
and every isolation row falls back to resistance mode (A2:163-173). Stop; do not solder.

## Meter setup, once

- Continuity beeper, resistance, **and diode mode** — diode mode is load-bearing for W2/W3
  and is not optional (A2:111, :120-124).
- Fine probes; the headers are 2.54 mm (A2:112-113).
- **Isolation rows are measured with the ESP32 unseated** (A2:163-173). If a board ends up
  hard-wired, use resistance mode, do not use the beeper for that row, record the value.
- **Continuity rows are measured with the plug seated**, at the connector (A2:194-196).
- Reference points (A2:126-133): **GND** = star-ground node at the PDB input XT60 male **−**
  pin; **batt+** = PDB input XT60 male **+** pin.

## Documented resistance exceptions — a finite reading here is CORRECT, not a fault

Closed by construction, not by memory (A2:174-193). Everything not on this list should read
≫ 10 kΩ in resistance mode.

| Pair | Expected finite value | Source |
|---|---|---|
| GPIO34 → GND | **≈ 10 kΩ** (divider bottom leg) | A2:176 (F13.1) |
| GPIO34 → batt+ | **≈ 27 kΩ** (divider top leg) | A2:176-177 (F3) |
| GPIO35 → 3V3 | **≈ 10 kΩ** (Hall pull-up) | A2:177 (H1) |
| GPIO13 / GPIO14 → GND | **= the fitted pull-down value**, only if PD1 records them populated | A2:177-178 (F15) |
| GPIO13 ↔ GPIO14 | **≈ 2 × the fitted pull-down**, same condition | A2:178-181 (F17) |
| GPIO27 → GND in SOLO · GPIO32 → GND in SHOW | **beep (≈0 Ω)** — a dry contact, never a finite value | A2:185-193 |

## The rows, in build order

Tick each only when the reading is written down. **Blank is not a pass** for any conditional
row (A2:739).

### SF — PDB frame (A2:234-243)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| P1 | star node ↔ XT60 input − pin | beep | | |
| P2 | batt+ ↔ GND | **OPEN** (beep/low Ω = §13 stop 1) | | |
| P3 | rail-A wiring ↔ rail-B wiring | no beep | | |
| P4 | rail-A wiring ↔ batt+ | no beep | | |
| P5 | rail-B wiring ↔ batt+ | no beep | | |
| P6 | rail-A wiring ↔ GND | no beep | | |
| P7 | rail-B wiring ↔ GND | no beep (C1 absent by construction) | | |

P2–P7 are **single-shot** (A2:245-246): after S6 none of these pairs is cleanly measurable again.

### S1 — battery divider, isolated (A2:263-267)

Valid **only** here — after S6 the reading is a composite through two UBEC input stages
(A2:250-255).

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| D1 | divider tap (GPIO34) → GND | **≈ 10 kΩ ±5 %** | | |
| D2 | tap → battery+ input lead | **≈ 27 kΩ** (≈20 kΩ ⇒ the old design got built — **stop**) | | |
| D3 | battery+ input lead → GND | **≈ 37 kΩ** | | |

### S2 — Hall, isolated (A2:282-289)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| H1 | GPIO35 → **3V3 pin** | ≈ 10 kΩ | | |
| H1b | GPIO35 → rail-A / 5 V wiring | no beep (≫ 10 kΩ) — **§13 stop 8's generating row** | | |
| H2 | GPIO35 → GND | not a short | | |
| H3 | A3144 VCC lead → rail-A harness node | beep | | |
| H4 | A3144 VCC lead → 3V3 | no beep | | |
| H5 | optional 1–10 nF Hall RC | present **or** recorded not populated — never blank | | |

### S3 — link2 (A2:295-298)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| C3 | GPIO25 (#1) → board #2 GPIO16 | beep; no beep to 26 | | |
| C4 | GPIO26 → anything on board #2 | **NO beep — the wire must not exist** (§13 stop 9) | | |

### S4 — CRSF pair + each actuator lead (A2:317-334, :341-346, :368-370)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| C1 | GPIO16 → RP1 TX pad | beep; no beep to 17 | | |
| C2 | GPIO17 → RP1 RX pad | beep; no beep to 16 | | |
| C5 | GPIO13 → steering signal | beep | | |
| C6 | GPIO14 → ESC signal (white) | beep | | |
| C7 | GPIO18 → DRS signal | beep; no beep to 19 | | |
| C8 | GPIO19 → pan signal | beep; no beep to 18/23 | | |
| C9 | GPIO23 → tilt signal | beep | | |
| C10 | GPIO34 → divider tap | beep | | |
| C10b | tap at the GPIO34 pin end → GND | ≈ 10 kΩ after settle | | |
| C11 | GPIO35 → A3144 output | beep | | |
| K1 | GPIO16 ↔ CRSF lead 5 V pin | no beep | | |
| K2 | GPIO17 ↔ CRSF lead 5 V pin | no beep | | |
| K3 | GPIO16 ↔ CRSF lead GND pin | no beep | | |
| K4 | GPIO17 ↔ CRSF lead GND pin | no beep | | |
| PD1 | GPIO13/14 boot-float pull-downs | value **+ placement**, or explicitly **not populated** | | |

**S8a executes inside this gate**, at the moment the ESC red wire is cut, before insulation
(A2:313-315, :582-592):

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| E0 | ESC-side red end ↔ connector-side stub | **OPEN** (an intact wire beeps) | | |
| E1 | ESC-side red end → rail-A wiring | OPEN | | |
| E2 | ESC-side red end → GPIO14 signal | OPEN | | |
| E3 | ESC-side red end → rail-B wiring | OPEN | | |
| E6 | ESC-side red end → GND (star + the lead's own GND) | OPEN | | |
| — | **two photos: severed conductor before shrink, insulated result after** | both taken | | |

### S4b — cross-signal isolation (A2:374-382)

| # | Check | Expected | Measured | P/F |
|---|---|---|---|---|
| S1r | matrix 13/14/18/19/23 against each other | no beep any pair (13↔14 exception if PD1 populated) | | |
| S2r | 13/14/16/17/18/19/23/25/34/35 → rails and → GND | no beep (documented exceptions above) | | |
| S3r | per lead: signal ↔ +5 V at the connector | no beep | | |
| S4r | per lead: GND pin → harness ground | beep | | |
| S5r | 13/14/16/17/18/19/23/25/35 → batt+ wiring | no beep — **§13 stop 4's generating row** | | |
| S6r | rail-A ↔ rail-B wiring | no beep (single-shot) | | |
| S7r | each rail ↔ batt+ wiring | no beep (single-shot) | | |

> **Open finding F20 (A2:376, guide:186-188): `GPIO34 ↔ GPIO35` is measured by no row.**
> A bridge there passes every beeper-mode check. The every-joint beeper sweep in the §2 visual
> is the only thing looking for it. Do that sweep properly; do not read a clean S1r as
> "no signals are bridged."

### S4c — boot-mode selector, SP3T on GPIO27/GPIO32 (A2:435-449)

**Recording the whole block as NOT-ASSEMBLED is a valid PASS** while the switch is still on the
shopping list (A2:418-428). Put the selector at **CENTER** before running S1r/S2r/S5r
(A2:387-391).

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| MS1 | switch alone: common ↔ each throw, in each of 3 positions | exactly one beep per position, OPEN to the other two; record the Ω | | |
| MS2 | GPIO27 socket position → SOLO throw | beep | | |
| MS3 | GPIO32 socket position → SHOW throw | beep | | |
| MS4 | switch common → star GND | beep | | |
| MS5 | CENTER throw → GPIO27, → GPIO32 | OPEN every position + **no wire on the terminal** (photo 15) | | |
| MS6 | GPIO27 → GND | **SOLO beep · CENTER OPEN · SHOW OPEN** | | |
| MS7 | GPIO32 → GND | **SOLO OPEN · CENTER OPEN · SHOW beep** | | |
| MS8 | GPIO27 ↔ GPIO32 | OPEN, all positions | | |
| MS9 | GPIO27/32 → 3V3 | OPEN, all positions — no external pull-up exists | | |
| MS10 | GPIO27/32 → rail-A and rail-B wiring | OPEN — **§13 stop 10's generating row** | | |
| MS11 | GPIO27/32 → batt+ wiring | OPEN — **§13 stop 4 for the strap pins** | | |
| MS12 | GPIO27/32 ↔ each other signal, selector CENTER | OPEN every pair | | |
| MS13 | at SOLO then SHOW: each signal → GND | OPEN (34 reads ≈10 kΩ; PD1 exception on 13/14) | | |

### S5 — WS2812 path (A2:471-477)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| W1 | ESP32 #2 GPIO4 → strip DIN | **≈ 330 Ω** (a 0 Ω beep = the resistor got bypassed) | | |
| W2 | **diode mode**, red on rail-A 5 V node, black on strip VDD | **0.15–0.35 V** after the 1000 µF settles | | |
| W3 | same, probes reversed | **OL** | | |
| W4 | 1N5819 band orientation | **toward strip VDD** (visual) | | |
| W5 | 1000 µF across strip 5V/GND | charging (rising R), not a persistent ≈0 Ω | | |

### S7 — whole-harness composite (A2:515-558)

Grounds — beep / ≤ 1 Ω to the star node, each:

☐ G1 ESP32 #1 · ☐ G2 ESP32 #2 · ☐ G3 ESC servo-lead · ☐ G4 steering · ☐ G5 DRS · ☐ G6 pan ·
☐ G7 tilt · ☐ G8 RP1 · ☐ G9 UBEC-A out · ☐ G10 UBEC-B out · ☐ G11 camera/WiFi *(or "not yet
wired")* · ☐ G12 WS2812 · ☐ G13 MAX98357A · ☐ G14 blower *(or "not yet wired")*

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| M1 | batt+ → GND, ohms | rises and settles; **record the settled value, no numeric expectation**; persistent ≈0 Ω = stop 1 | | |
| M2 | rail A → GND, ohms | settles to a recorded value; persistent ≈0 Ω = stop 1 | | |
| M3 | rail B → GND, ohms | **a rising reading is expected** (C1); persistent ≈0 Ω = stop 1 | | |
| CP1 | pack-facing XT60 **+** → PDB batt+ | beep (or NOT-ASSEMBLED) | | |
| CP2 | pack-facing XT60 **−** → star GND | beep (or NOT-ASSEMBLED) | | |
| CP3 | pack-facing XT60 **+** → star GND, ohms | no beep; settles ≈ M1 | | |
| PW1 | ESC **+** power input (12 AWG) → PDB batt+ | beep | | |
| PW2 | ESC **−** power input → star GND | beep | | |

### S8b — ESC red-wire final (A2:599-607)

| # | Measure | Expected | Measured | P/F |
|---|---|---|---|---|
| E4 | ESC servo-lead GND → common ground | beep | | |
| E5 | cut red end insulated | visual pass | | |
| E7 | ESC header +5 position → rail A / rail B / GPIO14 / GND | **all OPEN**, or record **"no metal in position"** with a photo | | |

## The ten hard stops — memorise the shape, not the list (A2:766-780)

1. persistent ≈0 Ω rail↔GND or batt+↔GND · 2. ESC BEC red not isolated · 3. divider wrong at S1 ·
4. any GPIO continuous to batt+ · 5. no common ground · 6. reversed polarity anywhere ·
7. uncertain connector orientation · 8. GPIO35 pull-up on 5 V · 9. a wire at GPIO26 ·
10. a strap pin (27/32) continuous to 3V3, either 5 V rail, or another signal.

**Any hard stop = FAIL, full stop. Do not power. Photograph and report.**
