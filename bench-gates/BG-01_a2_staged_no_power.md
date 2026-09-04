# BG-01 — A2 staged no-power gates (SF → S8b)

*Card for the gate defined by `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`
(cited below as **A2**). The checklist is the authority; this card is the session wrapper around
it — what to have ready, what order, what to save, what stops you. Where this card and A2
disagree, **A2 wins.***

## Prerequisites

1. **Parts on the desk and nothing energised.** No battery in the room's reach, no USB, no bench
   PSU, nothing flashed (A2:105-107).
2. **The two OWED bench measurements, both no-power, both before SF's first joint** — neither may
   be closed on paper (A2:217-222):
   - **OW1** caliper the ESP32 female-header socket stack against the ZK cassette clearance
     **`S0` ≥ 9.82 mm** (A2:220-221). A failure reopens the socketing decision (F12) and turns
     every isolation row into its resistance-mode variant (A2:163-173).
   - **OW2** derive the adjacent-pin list from the **MH-ET Live D1-Mini silkscreen** (A2:140,
     :222). Until it exists, beeper-check **every** header joint, not a favoured subset.
3. **Build order = gate order.** `w17-pdb-build-and-connector-guide.md` §5 steps 2–7 each name
   the A2 gate they close (guide:145-174). Building out of order produces false failures — that
   is finding F8, and it is why the order was rewritten (guide:132-137).
4. **The build boards are MH-ET Live D1-Minis.** The DevKit V1 clones are TEST/SPARE (owner
   decision 2026-07-24, A2:112-113).
5. Read A2 §3's four measurement conventions once, before the first row (A2:153-201). They are
   the difference between a real failure and a manufactured one.

**Not prerequisites, deliberately:** the SP3T boot-mode selector (still on the owner's shopping
list — S4c may close as NOT-ASSEMBLED, A2:418-428) and the owner-made XT60-female pigtail tail
(CP1–CP3 may close as NOT-ASSEMBLED, A2:560-562). Both absences are valid PASSes **with a note**,
and both then become hard preconditions later.

## Required equipment

- Multimeter with **continuity beeper, resistance, and diode mode**. Diode mode is load-bearing
  for S5's W2/W3 and is not optional; if the meter lacks it, **stop and say so** — the substitute
  check has to be written before S5 runs (A2:111, :120-124).
- Fine probes or probe clips for 2.54 mm headers (A2:112).
- Calipers (OW1).
- Strong light + magnifier or phone macro for joints (A2:114).
- Phone for the 15-item photo checklist (A2:614-643).
- Soldering iron, solder, heat-shrink — A2 *is* the build (A2:46-47, guide:195-196).
- **Present but not connected: USB cable and bench PSU.** Both are Phase B (A2:116).
- The pin authority: `w17-control-fw/lib/config/include/config/PinMap.hpp`, soundlight's
  `PinMap.hpp`, `w17-control-fw/docs/00_BUILD_SHEET.md` bench fixes (A2:117).
- The worksheet: `bench-gates/tools/pdb_continuity_sheet.md`.

## Topology (ASCII)

```
                      NOTHING BELOW IS ENERGISED DURING BG-01

  reference points (A2:126-133):
     GND   = star-ground node, probed at PDB input XT60 male  -  pin
     batt+ = switched battery + node, probed at PDB input XT60 male  +  pin

  [pack: ABSENT]                      XT90-S pigtail chain (mated at S7 only,
        x                              pack end left dangling — A2:546-558)
                                              |
                                    PDB input XT60 (male)
                                       +            -
                                       |            |
                                    batt+ ======= star GND  <-- every ground returns here
                                    /   |   \                    (G1..G14 at S7)
                                   /    |    \
                        UBEC A   UBEC B   ESC 12 AWG feed      <-- all three fitted at S6,
                        (S6)      (S6)         (S6)                in ONE sitting (A2:484-489)
                          |         |
                       Rail A    Rail B (+cap C1 1000uF, fitted at S6)
                          |         |
   camera, WiFi, ESP32#1, ESP32#2,  |  steering DS3235SG, MG90S x3, blower
   RP1, WS2812, MAX98357A, Hall VCC |
                                    |
   27k/10k divider on batt+ -> GPIO34 (S1; C3 100nF at the PIN end, fitted at S4)
   A3144 Hall -> GPIO35, 10k pull-up to 3V3 AT THE ESP32 #1 END (S2)
   link2: GPIO25 (#1) -> GPIO16 (#2).  GPIO26 CARRIES NO WIRE (S3 / stop 9)
   CRSF:  RP1 TX -> GPIO16, GPIO17 -> RP1 RX (S4)
   ESC servo lead: signal + GND only, RED CUT and insulated (S8a at the cut, S8b at the end)
   SP3T selector: common -> star GND, SOLO throw -> GPIO27, SHOW throw -> GPIO32,
                  CENTER throw EMPTY, no resistor anywhere (S4c) — or NOT-ASSEMBLED
```

## Exact procedure (numbered)

1. **OW1 + OW2 first.** Caliper the socket stack; write the MH-ET adjacent-pin list. Record both
   in the evidence folder. If OW1 breaks `S0` ≥ 9.82 mm, **stop and report** — this is a document
   change before it is a build change (`w17-parts-to-gift-master-sequence.md`:145-147).
2. **SF — PDB frame.** Build the XT60 input, the star node, both ESP32 **female header sockets**
   (boards not seated), the rail A/B output headers, the signal headers, the rail branch looms
   (guide:145-150). Run rows **P1–P7** (A2:234-243). Cap C1 is **not** fitted here (A2:230-232).
3. **S1 — divider.** 27 kΩ from raw batt+ to the tap, 10 kΩ tap → GND, tap wire to GPIO34
   (guide:151-154). Run **D1–D3** (A2:263-267). **The UBECs must not exist on the batt+ node
   yet** — that is the whole reason S1 sits here.
4. **S2 — Hall.** Sensor lead + the **board-end** 10 kΩ pull-up GPIO35 → 3V3 (A2:275-280). Run
   **H1, H1b, H2, H3, H4, H5**. H5 records populated *or* not populated; blank is not a pass.
5. **S3 — link2.** Run **C3** and **C4**. C4 is falsifiable: a beep at GPIO26 means a wire exists
   that must not (A2:300-306, stop 9).
6. **S4 — CRSF pair and each 3-pin actuator lead, one lead at a time.** Two passes per lead:
   continuity **plug seated**, isolation **board unseated** (A2:310-311). Run **rows C1, C2, C5–C11,
   C10b, K1–K4, PD1** (row IDs — not the 1000 µF capacitor, which this card also calls C1; see
   step 11). Fit **C3 (100 nF) at the GPIO34 pin end** here (A2:329-334).
7. **S8a executes inside step 6**, at the ESC lead: cut the red wire, run **E0, E1, E2, E3, E6**
   and take **both photos on the bare ends**, *then* insulate (A2:313-315, :578-595). Do not
   build the ESC lead and defer the cut — after insulation these rows are unrunnable.
8. **S4b — the isolation matrices** with all five actuator leads present and the UBECs still off:
   **S1r, S2r, S3r, S4r, S5r, S6r, S7r** (A2:374-382). Repeat S3r/S4r deliberately (A2:384-385).
9. **S4c — the SP3T selector**, if wired: **MS1–MS13** (A2:435-449), selector at **CENTER** while
   S1r/S2r/S5r run (A2:387-391). If the switch is not in hand, record the whole block
   **NOT-ASSEMBLED** and move on — that is a PASS-with-note, not a skip (A2:418-428).
10. **S5 — WS2812 path** on the soundlight side: **W1–W5** (A2:471-477). W2/W3 are diode-mode and
    single-shot.
11. **S6 — attach the batt+ consumers in ONE sitting:** both UBEC inputs, the ESC 12 AWG feed, and
    cap **C1** (the 1000 µF bulk capacitor, `w17-pdb-build-and-connector-guide.md`:119 — not A2 row
    C1) **across rail B, stripe to GND, laid flat** (A2:484-489). **Photograph cap C1 with the stripe
    visible immediately** (photo 14) — no no-power measurement can distinguish a reversed 1000 µF
    (A2:504-506, :634-639). Re-run the full §2 visual list now that everything is together.
12. **S7 — whole-harness composite.** Grounds **G1–G14**; battery/rail screens **M1, M2, M3**;
    mate the master-switch pigtail chain with the pack end dangling and run **CP1–CP3**; ESC power
    feed **PW1, PW2** (A2:515-558).
13. **S8b — ESC red-wire final:** **E4, E5, E7** (A2:599-607). E7 records "no metal in position"
    with a photo if the pin was clipped — never blank, never "probed empty air and logged OPEN".
14. **Photos**: all 15 items, taken **at the gate where the subassembly is still accessible**, not
    all at the end (A2:614-643).
15. Fill A2 §11's table completely — **row, gate, expected, measured, P/F, photo #** — and paste
    it back with the photo set and the §12 Part 2 attestation line (A2:832-838).

## Exact commands (fenced)

There are no firmware commands in this gate — it is a meter and an iron. The only commands are
evidence bookkeeping, all host-side and hardware-free:

```bash
cd /Users/vitaliykhomenko/Documents/projects

# 1. Open the evidence folder for this gate and stamp the environment.
bench-gates/tools/bench_capture.sh BG-01 --no-serial \
  --note "A2 staged no-power gates, session 1"

# 2. Print the worksheet (or open it next to the checklist).
open bench-gates/tools/pdb_continuity_sheet.md

# 3. The authority, always open beside the worksheet:
open w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md

# 4. Confirm the pin map you are wiring against is the real one, not this card.
#    BOTH boards: 1,70p covers the whole of each file (63 and 30 lines), so nothing
#    this card's steps depend on can be cropped out -- GPIO16/17 (CRSF), 25/26 (link2,
#    the GPIO26 that C4 and hard stop 9 exist for), 13 (steering), 14 (ESC), 35 (Hall):
sed -n '1,70p' w17-control-fw/lib/config/include/config/PinMap.hpp
sed -n '1,70p' w17-soundlight-fw/lib/config/include/config/PinMap.hpp
```

**Commands that must NOT be run during BG-01:** anything containing `pio run`, `-t upload`,
`esptool`, or a serial port. Flashing and USB are Phase B (A2:116, :799-810).

## Expected evidence

- A2 §11's measurement table, **every row filled**, each carrying its gate and photo number.
- The 15 photos of A2 §10, named by item number.
- OW1's caliper reading and OW2's written adjacent-pin list.
- An explicit record — not a blank — for every conditional row: **H5, G11, G14, PD1, MS1–MS13,
  CP1–CP3, E7's no-metal case** (A2:739).
- The §12 Part 2 owner attestation line (A2:751-754). Part 1 is BG-02.

## PASS/FAIL criteria (objective numbers)

| Row(s) | PASS | FAIL |
|---|---|---|
| OW1 | socket stack clears **`S0` ≥ 9.82 mm** | anything below ⇒ socketing decision reopens |
| P1 | beep | no beep |
| P2–P7 | OPEN / no beep | beep or low Ω |
| D1 | **10 kΩ ±5 %** | ≈0 Ω or open |
| D2 | **≈ 27 kΩ** | **≈ 20 kΩ = the old design got built — stop** |
| D3 | **≈ 37 kΩ** | anything ≪ 37 kΩ |
| H1 | **≈ 10 kΩ to 3V3** | ≈10 kΩ to **5 V** instead = stop 8 |
| C4 | **no beep from GPIO26** | any beep = stop 9 |
| W1 | **≈ 330 Ω** | 0 Ω beep = the resistor was bypassed |
| W2 | **0.15–0.35 V forward** (after the 1000 µF settles) | outside the band, or OL both ways |
| W3 | **OL** | a forward reading = the diode is backwards |
| E0 | **OPEN** between the two cut ends | a beep = the cut was never made |
| G1–G14 | **beep / ≤ 1 Ω** to the star node, each | any one not common = stop 5 |
| M1–M3 | a reading that **rises and settles**; value recorded, no numeric expectation | **persistent ≈0 Ω = stop 1** |
| S1r/S2r/S5r | no beep on any pair, except the documented resistance exceptions | any beep = stop 4 or a bridged pair |
| MS6 | **SOLO beep · CENTER OPEN · SHOW OPEN** | any other pattern |
| MS7 | **SOLO OPEN · CENTER OPEN · SHOW beep** | any other pattern |
| MS9/MS10/MS11 | **OPEN in all three positions** | any beep = stop 10 (or stop 4 for batt+) |

Tolerance rule from A2 §12: divider within **±5 %** of 10/27/37 kΩ, Hall pull-up ≈10 kΩ **to
3V3**, W1 ≈330 Ω, W2 within **0.15–0.35 V** (A2:741). Minor deviations (resistor tolerance, an
unpopulated *optional* Hall RC) are PASS-with-note; **anything in §13 is FAIL, full stop**
(A2:761-762).

**A2 does not have a percentage score.** It closes on completeness plus attestation, not on a
proportion of rows passed.

## Stop conditions

The ten hard stops (A2:766-780), each reachable from a named row (A2:786-797):

1. Persistent ≈0 Ω rail↔GND or batt+↔GND — *rising is a capacitor, not a short* (rows P2/P6/P7,
   W5, M1–M3, CP3).
2. ESC BEC red wire not isolated (E0–E3/E6, E4/E5/E7).
3. Divider wrong at S1 — top leg ≈20 kΩ, tap shorted, values far off (D1–D3, C10b).
4. Any GPIO with continuity to batt+ (S5r, MS11).
5. No common ground between any two devices (S4r, G1–G14).
6. Reversed polarity anywhere — XT60, UBEC, ESC power input, cap, diode band (§2 visual, W2–W4,
   CP1/CP2, PW1/PW2, and for cap **C1** (the 1000 µF, not the A2 row of the same name) **the photo
   plus the visual are the only evidence**).
7. A connector orientation you cannot positively identify — trace it; never "probably right".
8. GPIO35 pull-up tied to 5 V instead of 3V3 (H1b).
9. A wire present at GPIO26 (C4).
10. A strap pin (GPIO27/32) continuous to 3V3, to either 5 V rail, or to any other signal, in any
    position (MS9, MS10, MS12, MS13). **Not a stop:** an absent or floating selector — that reads
    as Drive by design.

Plus the session rule: a suspicious reading → **stop, photograph, report**. Never "try again with
power to see" (A2:106-107).

## Rollback

- **A gate fails mid-build:** do not proceed to the next gate. The staged shape exists exactly so
  the fault is localised to the subassembly just built (A2:40-44). Unpick that subassembly, rebuild
  it, re-run **that gate's rows only**.
- **A single-shot row was missed:** P2–P7, D1–D3, W2/W3, S6r/S7r and E0–E3/E6 are valid only at
  their own gate (A2:197-201). A missed one cannot be recovered by re-measuring later — it is
  recovered only by *undoing* the build back to that gate. Record the gap honestly rather than
  measuring a composite and calling it the row.
- **A hard stop fires:** stop the session. Nothing is powered, so there is nothing to power down;
  photograph the exact reading, write it up, and hand it to the owner. Do not "fix and continue"
  in the same sitting on a stop-4 or stop-1 finding without re-running the generating rows.
- **OW1 fails:** the socketing decision reopens — boards go hard-wired and every isolation row in
  A2 becomes its resistance-mode variant. That is a documentation change first (A2:163-173).

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-01/<UTC-stamp>/
  meta.txt                 # written by bench_capture.sh
  MANIFEST.txt             # sha256 of everything in the folder
  a2_measurement_table.md  # A2 §11 filled in: row | gate | expected | measured | P/F | photo #
  owed_OW1_socket_stack.md # the caliper reading vs S0 >= 9.82 mm
  owed_OW2_adjacent_pins.md# the MH-ET silkscreen adjacent-pair list
  photos/01_board1_top.jpg … photos/15_selector.jpg      # A2 §10 items 1-15
  photos/03a_esc_red_severed_preshrink.jpg               # A2 §10 item 3, BOTH shots
  photos/03b_esc_red_insulated.jpg
  photos/14_c1_stripe.jpg                                # the only evidence stop 6 gets for cap C1
  notes_deviations.md      # every PASS-with-note and every NOT-ASSEMBLED block
  attestation.txt          # A2 §12 Part 2, owner-signed
```

## Downstream unlocked by PASS

**Nothing automatically.** A PASS here produces a *record*; **BG-02** turns the record into
A2-CLOSED, and only the owner turns A2-CLOSED into PHASE-B-OPEN (A2:756-759,
`w17-parts-to-gift-master-sequence.md`:190-192). With those two, BG-03 (Phase B first power) and
everything below it become reachable.

## BENCH-TBD residue

- **OW1 and OW2 are OWED** and gate SF's first joint (A2:217-222; guide:141-144, ":still OWED").
- **The SP3T switch is not in hand** — part number, terminal layout and contact resistance are all
  `[bench-TBD]` (A2:118, :406-416). S4c may close NOT-ASSEMBLED.
- **The owner-made XT60-female pigtail tail** may not exist when S7 runs; CP1–CP3 then close
  NOT-ASSEMBLED and become a **hard precondition to the first pack connection** (A2:560-562).
- **F20 stays open**: `GPIO34 ↔ GPIO35` is measured by **no row in A2**. A bridge there passes
  every beeper-mode check; the every-joint visual sweep is the only thing looking (A2:376,
  guide:186-188).
- **There is no in-envelope car pack** (A2:812-815). S7 needs none — its reference point is the
  PDB input XT60 − pin.
- **The IP2326 charge path is out of A2's scope entirely** and owns a no-power gate **that has not
  been written yet** (A2:823-830). Writing it is a tracked prerequisite of building the charge path.
- The **battery ADC volts-per-count calibration** is not this gate's business — the Wokwi run did
  not validate the battery ADC, and calibration is Phase B/C (A2:269-271).

## Evidence label at card creation

**NOT-EXECUTED.** A2 has never been run; no measurement in this card has been taken; Phase B is
BLOCKED (A2:3-8, :94; `W17_CURRENT_STATE.md` §6). This card creates no permission and closes no
gate.
