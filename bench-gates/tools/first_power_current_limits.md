# First-power current-limit table — what the documents actually fix, and what they do not

**Evidence label at creation: NOT-EXECUTED.** No current below has been measured on this car.
Every value is either a **cited rating** (a part's rating or a compile-time constant) or an
explicit **THRESHOLD MISSING**. Nothing here is a measured draw.

> **Read this first.** A current limit on a bench supply is a *fuse you chose*, and the only
> honest way to choose it is: know the expected draw, set the limit a little above it, and stop
> the moment it trips. **This project's documents do not state an expected draw for any car-side
> 5 V load.** No datasheet current figure for the ESP32 modules, the camera, the Wi-Fi module, the
> RP1, the amplifier, the DS3235SG or the MG90S appears anywhere in the workspace, the firmware
> repos, or `HARDWARE_INVENTORY.md`. So this table cannot end in a number — it ends in a
> **procedure that derives the number at the bench, one subsystem at a time**, and in a list of
> the thresholds that are missing. Inventing them would be worse than leaving them blank.
>
> **The ground side is the counter-example, and it is the template.** `w17-gcs-box-guide.md`:135-139
> does state four cited per-device 5 V figures — ES24TX Pro **~300–500 mA** `[A]`, RT5370 Wi-Fi
> **≤160 mA** (dongle datasheet), FT232RL **~15–50 mA** (FTDI datasheet), hub **~100 mA** `[A]` —
> summing to **≈775–810 mA** worst case, against a 900 mA port budget and a **~700 mA** decision
> threshold (`:141-157`). `w17-control-fw/docs/bill_of_materials_v2.md`:200 likewise fixes the
> IP2326 charge rate at **≤1.5 A**. That is exactly the shape T1–T13 below need: a cited figure,
> an `[A]`/`[I]` evidence tag, and a stated decision threshold. Nothing equivalent exists for the
> car's rails, which is why the rows below are blank.

## The gate this belongs to

Bench-supply work is **Phase B** (`w17-control-fw/docs/PHASE_B_FIRST_POWER.md`), which is
**BLOCKED** until A2 closes and the owner opens it (that doc's own gate line, :3-10). D8 Phase 1
is the first battery connection of the bring-up (`D8_BENCH_BRINGUP.md`:51-57). Nothing in this
file authorises any of it.

## Topology this table applies to

```
  2S LiPo (7.4 V nom / 8.4 V full)         [or bench PSU in its place]
      |
   XT90-S master switch  (body-accessible; pull = everything dead)
      |
   PDB input XT60  --> star node
      |-- ESC 12 AWG direct feed ...... MOTOR LEADS DISCONNECTED for all of Phase B
      |-- UBEC A (5 A) --> Rail A "clean"
      |-- UBEC B (5 A) --> Rail B "servos"  (+ C1 1000 uF)
```
Source: `w17-pdb-build-and-connector-guide.md`:35-58; UBEC rating
`HARDWARE_INVENTORY.md`:113 ("UBEC 5 A (2 pcs)").

## Rail membership — what is on each limit when you set it

| Rail | Loads | Source |
|---|---|---|
| **A (clean)** | BL-M8812EU2 Wi-Fi, camera 5 V, ESP32 #1, ESP32 #2, RP1 receiver, WS2812 strip, MAX98357A amp, A3144 Hall VCC | `w17-pdb-build-and-connector-guide.md`:51-52 |
| **B (servos)** | DS3235SG steering, 3× MG90S (DRS / pan / tilt), blower | `w17-pdb-build-and-connector-guide.md`:53 |
| **batt+ direct** | ESC 12 AWG feed — **motor disconnected through Phase B** | guide:47; `PHASE_B_FIRST_POWER.md`:14-17 |

## The only current numbers the documents fix

| # | Quantity | Value | Where it comes from | Kind |
|---|---|---|---|---|
| L1 | UBEC A rating | **5 A** | `HARDWARE_INVENTORY.md`:113 | part rating |
| L2 | UBEC B rating | **5 A** | `HARDWARE_INVENTORY.md`:113 | part rating |
| L3 | WS2812 strip length | **30 LEDs** | `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11 (`kNumPixels`) | compile-time constant |
| L4 | LED budget ceiling enforced at compile time | **900 mA** | `LightRenderer.hpp`:209 (`kBudgetMilliamps`), checked at `:242` | compile-time constant |
| L5 | LED modelled worst case (all pixels, two full primaries, post-gamma at cap 110) | **180 mA** = 30 × (2 × 20 mA × 40/255) | `LightRenderer.hpp`:226 (`perLedMa`), :214-215 | derived from constants |
| L6 | LED *actual* all-amber hazard draw, post-gamma | **≈ 104 mA** | `LightRenderer.hpp`:215-216 | stated in code comment |
| L7 | Pack voltage span used for the battery calibration | **≈ 6.5 V and ≈ 8.4 V** | `D8_BENCH_BRINGUP.md`:240-241 | procedure |
| L8 | Firmware's battery plausibility band | **4000–9000 mV** (`BatteryConfig::implausibleBelowMv/AboveMv`) | `PHASE_B_FIRST_POWER.md`:114 | firmware constant |
| L9 | ESC | **Hobbywing QuicRun 10BL120** (120 A class, sensored) | `HARDWARE_INVENTORY.md`:90; `00_BUILD_SHEET.md`:38 | part identity |
| L10 | Pack C-rating spec used when sourcing | **≥ 25 C** (1500 mAh × 25 C ≈ 37 A burst) | `HARDWARE_INVENTORY.md`:277 | sourcing spec, not a bench limit |

**L5 and L6 are the only per-subsystem current figures that exist anywhere in this project**, and
they exist only because the LED renderer computes them itself.

## THRESHOLD MISSING — every limit a first-power session actually needs

Each row is a number the owner or the bench must supply. **Do not fill any of these from
memory or from a general-knowledge figure; take it from the part's own datasheet, or measure
it at the bench and record it here as the first evidence.**

| # | Limit needed | Status |
|---|---|---|
| T1 | Rail-A quiescent draw, boards idle, nothing else connected | **THRESHOLD MISSING — owner/bench decides** |
| T2 | Rail-A draw with the camera + Wi-Fi module streaming | **THRESHOLD MISSING — owner/bench decides** |
| T3 | Rail-B draw with the steering servo holding centre (no load) | **THRESHOLD MISSING — owner/bench decides** |
| T4 | Rail-B peak during a full-lock steering sweep (the reason C1 exists) | **THRESHOLD MISSING — owner/bench decides** |
| T5 | Per-MG90S idle and moving draw | **THRESHOLD MISSING — owner/bench decides** |
| T6 | Blower draw (always-on, rail B) | **THRESHOLD MISSING — owner/bench decides** |
| T7 | MAX98357A + speaker draw at the shipped `sound.volume` | **THRESHOLD MISSING — owner/bench decides** |
| T8 | RP1 receiver draw | **THRESHOLD MISSING — owner/bench decides** |
| T9 | ESP32 module draw, Wi-Fi off (both boards) | **THRESHOLD MISSING — owner/bench decides** |
| T10 | ESP32 #1 draw with Bluetooth active (BT show-off build) — BT1 lists "3.3 V rail draw with BT active" as an unmeasured bench item | **THRESHOLD MISSING — BT1 measures it** (`BT1_BENCH_GATE.md`:66) |
| T11 | The bench-PSU current limit to set at each step below | **THRESHOLD MISSING — derived from T1–T9 once they exist** |
| T12 | ESC standby (logic-only) draw on batt+ with motor leads off | **THRESHOLD MISSING — owner/bench decides** |
| T13 | Inrush allowance at the moment the pack is connected (the XT90-S anti-spark exists because it is large, but no number is stated) | **THRESHOLD MISSING — owner/bench decides** |

## How to derive T1–T12 safely — the staircase

This is a procedure, not a threshold table, and that is deliberate. Run it **only** inside
Phase B, with an observer, wheels off the ground, ESC motor leads disconnected.

1. **Start with everything unplugged from both rails.** Bench supply set to the pack voltage you
   intend (start at nominal 7.4 V, not 8.4 V) and its current limit at the lowest setting the
   supply offers.
2. **Bring up the PDB alone.** Raise the limit only until the supply comes out of constant-current
   mode with nothing connected. Record that as the harness's own leakage figure. **A harness that
   cannot come out of CC with nothing on the rails has a fault — stop, do not raise the limit.**
3. **Add one load at a time**, in this order (least authority first): Rail A boards → RP1 →
   LED strip → amp → camera/Wi-Fi → Rail B blower → one MG90S → the remaining MG90S → DS3235SG.
   After each: record the settled draw; that reading *becomes* the T-row above.
4. **Set the working limit** at the recorded total plus a stated margin, and **write the margin
   down** — the margin is a decision, not a fact, so it belongs in the evidence with a name on it.
5. **Never raise a limit to make a trip go away.** A trip during this staircase is the tool
   working. Pull power, find the fault, re-run A2's relevant rows (`13_phase_a_a2_no_power_checklist.md`).
6. **Rail-B peak (T4) is measured last and deliberately**: the DS3235SG stall spike is what C1 is
   for (`00_BUILD_SHEET.md`:36, guide:119). Sweep it slowly, with the linkage **off**, and expect
   the reading to be the largest single number in this table.

## Stop conditions for any first-power session using this table

- The supply sits in constant-current with **nothing** connected to a rail → harness fault.
- Any rail voltage collapses when a load is added → that load, or C1's absence, is the fault.
- A rail reads above 5 V at a 5 V load, or batt+ voltage appears on a rail → **pull power now**;
  this is A2 hard stop 1/4 territory reached with power on, which A2 exists to prevent.
- Any smell, any heat you can feel through a fingertip, any audible tick from a UBEC → power off
  first, diagnose second.

## What this file is not

It is not a permission to power anything, it does not set any limit, and it must not be read as
"the numbers are known". Its one substantive claim is the finding in the report:
**the project has no documented current figures for its 5 V loads**, and the first Phase B
session is where they get created.
