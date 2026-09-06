# First-power current-limit table — what the documents actually fix, and what they do not

**Evidence label at creation: NOT-EXECUTED.** No current below has been measured on this car.
Every value is either a **cited rating** (a part's rating or a compile-time constant) or an
explicit **THRESHOLD MISSING**. Nothing here is a measured draw.

> **Read this first.** A current limit on a bench supply is a *fuse you chose*, and the only
> honest way to choose it is: know the expected draw, set the limit a little above it, and stop
> the moment it trips. **For most of this car's 5 V loads the project's documents still state no
> expected draw.** No datasheet current figure for the ESP32 modules, the camera, the RP1, the
> MG90S or the blower appears anywhere in the workspace, the firmware repos, or
> `HARDWARE_INVENTORY.md`. **Update 2026-09-06 (O-6 derivation v2, after review R-O6,
> `_handoff/2026-09-06_O6_derivation_report.md`):** four parts now do have cited figures — the
> Wi-Fi module (BL-M8812EU2), the amplifier (MAX98357A), the steering servo (DS3235SG) and the
> LED strip — see **L11–L15** below and BG-03's "Starting current limits" subsection. **Every
> figure there is a 5 V rail-side allowance, not a bench-PSU setting**, and no substep has a
> settable starting amperage. So this table still cannot end in a number — it ends in a
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
| L11 | BL-M8812EU2 Wi-Fi module: rated maximum supply current / largest RF-test peak / rated supply capability | **1800 mA (Max)** — §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)", the module's own maximum supply current and therefore the added-load allowance — and **DR2-7 named the shipped mode (5 GHz *station*, joining the laptop's hosted hotspot, `w17-gcs-box-guide.md`:195-197) without moving it**, because the operating point *inside* that mode is still uncaptured (TX power, channel width and encoder bitrate are NOT FOUND in any canonical config, and the manufacturer states TX power is customer-set in the Linux driver's configuration file, §4 — see L16); largest **per-use-case** §3.3 peak **1510 mA** (HT20 MCS8 TX @ 27.5 dBm, 2TX RF test), one test case and **not** an envelope; supply must deliver **≥ 1800 mA peak** (§6.2.1) | B-link *BL-M8812EU2 datasheet* V1.0, §1.3, §3.3 and §6.2.1 (retrieved 2026-09-06) | manufacturer datasheet |
| L12 | DS3235SG steering servo idle / stall current | **5 mA idle** (all columns) / **stall 1.9 A at 5 V, 2.1 A at 6 V, 2.3 A at 7.4 V** — Rail B's documented band is 5–6 V, so **2.1 A** is the applicable figure until BEC#2's output is recorded | DS SERVO datasheet, §4 (retrieved 2026-09-06); band per `D8_BENCH_BRINGUP.md`:55 | manufacturer datasheet |
| L13 | MAX98357A quiescent / standby / spec-point driven figure / internal limit / absolute maximum | **3.35 mA max IDD, at `TA = +25 °C` only** — no max is given over the operating range; **standby `ISTNDBY` 400 µA max** (`SD_MODE` high, **no BCLK**, `TA = +25 °C`) — M-PEAK-clean and the manufacturer maximum for the un-clocked state **only**, never a bound on the driven amp; **gain 8.4 / 9 / 9.6 dB min/typ/max at `GAIN_SLOT` unconnected** — **the shipped 9 dB is a typ**; **≥ 640 mA at the datasheet's own 3.2 W condition** — `ZSPK = 4Ω + 33µH`, `THD+N 10%`, **`gain = 12dB`**, `VDD = 5V` (3.2 W / 5 V, by energy conservation; no efficiency figure needed) — **and 3.2 W is a typ/guidance value, not a guaranteed limit** (*"The parametric values (min and max limits) shown in the Electrical Characteristics table are guaranteed. Other parametric values quoted in this data sheet are provided for guidance."*; the `POUT` rows carry no min/max entry), so **`≥ 640 mA` is REFERENCE ONLY, is NOT M-PEAK-clean, and must not be used as a rail-sizing term**. **This is a spec-point figure, not a prediction for the shipped car:** `GAIN` floating = **9 dB is CONFIRMED (DR3-2)** as the intended shipped configuration (`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24; `bench-gates/BG-04_d8_bench_bringup.md`:143) — before permanent soldering, verify the fitted board's actual pad mapping against the datasheet (the fitted part is a generic AliExpress "MAX98357A I2S amplifier 1PCS" — `HARDWARE_INVENTORY.md`:97, `w17-control-fw/docs/bill_of_materials_v2.md`:69-70 — do not assume the Adafruit pinout); at 9 dB the manufacturer publishes no output-power figure, and the speaker's 4 Ω is unverified (`HARDWARE_INVENTORY.md`:98, "a bench spec-check"). **Table 8 and the Electrical Characteristics gain rows agree exactly with `PinMap.hpp`:20-24** (unconnected = 9 dB, GND = 12 dB, VDD = 6 dB, 100 kΩ to GND = 15 dB, 100 kΩ to VDD = 3 dB), and the pin is read by a comparator against fractions of VDD — **an onboard 100 kΩ pulldown would ship the part at 15 dB**, which is what the pre-solder check (`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11) exists to exclude. **9 dB does NOT reduce the amplifier's worst case (DERIVED):** at 9 dB the full-scale output stays **supply-limited at all three gain band edges (8.4 / 9 / 9.6 dB)** — the binding ceiling is the 5 V rail, the same ceiling the part has at 12 dB. **2.8 A ILIM is a *typ*** and is the part's **output** current limit, not a supply-current maximum — short/fault protection, never a normal-operation bound. **ABSOLUTE MAXIMUM, and it is NOT one of these allowances: ±1.6 A** *"Continuous Current In/Out of VDD/GND/OUT_"*. **It is a damage threshold under the datasheet's AMR caveat** (*"stress ratings only … functional operation … is not implied"*) — **NOT an allowance, NOT a PSU setting, NOT a prediction of draw; nothing may be set or permitted up to it.** It must never be entered in a `P(N)` or `Σ P(k)` cell and never dialled into the bench PSU as the amp branch's limit (T11's policy is the **lowest defensible limit per substep**); its only use is negative — no figure, setting or allowance may permit sustained amp-branch current above it. It belongs in **BG-03 S4's never-exceed column**, not in this Value column's added-load allowances | Maxim Integrated *MAX98357A/MAX98357B* datasheet (retrieved 2026-09-06); condition legs re-read 2026-09-06 evening (O-6 addendum v2) | manufacturer datasheet |
| L14 | WS2812 strip modelled **emitter** draw at the O-7 operating cap 180 | **540 mA** (code's integer form) / **560 mA** (un-truncated). Excludes each pixel's controller quiescent draw — an unquantified adder | `LightRenderer.hpp`:11, :110-111, :152, :209, :226; the model's 20 mA/channel is an **uncited code comment** at `:205` | code |
| L15 | WS2812B per-channel operating current, manufacturer | **16 mA/channel** (RED, GREEN, BLUE) — bounds L14's code model **from below** (448 mA at cap 180) | Worldsemi *WS2812B Specifications*, **Mar-2017** revision, LED Characteristics table (retrieved 2026-09-06). The **Jan-2016 V1.0** revision has no current column | manufacturer datasheet |
| L16 | BL-M8812EU2 **TX power the customer may configure** — a **configuration never-exceed in dBm; NOT a current, NOT a rail limit, and never to be entered in a P(N) or L(N) cell** | §4, verbatim: *"Module TX power of some rates is calibrated, customers can define the target TX power of other rates by modifying configuration file of the Linux driver . Customers must define the TX power same or lower than recommended Target TX Power as below!"* **Recommended Target TX Power** per rate (± 2 dBm): 802.11a @ 6 Mbps **29 dBm**, 802.11n HT20 MCS0 **28 dBm**, HT40 MCS0 **28 dBm**, 802.11ac VHT80 MCS0 **27 dBm**; the **calibrated** rates read 802.11a @ 54 Mbps 23 dBm, HT20 MCS7 23 dBm, HT40 MCS7 22.5 dBm, VHT80 MCS9 21.5 dBm. **Which row applies is not yet knowable** — the rate in use is part of the uncaptured camera config. At camera bring-up, read the configured TX power and compare it against the row for the rate actually in use; anything above it is a manufacturer-limit violation to correct **in configuration**, never something to accommodate by raising a current limit | B-link *BL-M8812EU2 datasheet* V1.0, §4 Transmitter Specifications (retrieved 2026-09-06) | manufacturer datasheet (**dBm, not a current**) |

**L5, L6 and L14 are code-derived; L11–L13 and L15 are manufacturer figures, obtained by the
O-6 derivation on 2026-09-06. L16 is also a manufacturer figure but is NOT a current** — it is a
dBm configuration ceiling for the camera's Wi-Fi driver, added by the O-6 addendum v2 (2026-09-06
evening) and deliberately kept out of the four-parts current grouping. Before that pass L5 and L6 were the only per-subsystem current
figures in this project, and they existed only because the LED renderer computes them itself.
Every other car-side 5 V load still has none — see the T-rows below.

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
| T7 | MAX98357A + speaker draw at the shipped `sound.volume` | **THRESHOLD MISSING — bench measures it; both cited bounds are now labelled with their conditions, and neither is a prediction for the shipped car.** Quiescent **3.35 mA max, at `TA = +25 °C` only**; **standby `ISTNDBY` 400 µA max** (`SD_MODE` high, no BCLK, `TA = +25 °C`) — the manufacturer maximum for the un-clocked state only. The part draws **≥ 640 mA at the datasheet's own 3.2 W condition** (4 Ω + 33 µH, THD+N 10 %, **gain = 12 dB**, VDD 5 V), **but 3.2 W is a typ/guidance value, not a guaranteed limit, so that ≥ 640 mA is REFERENCE ONLY and NOT M-PEAK-clean**; **ILIM 2.8 A is a *typ*** and is the part's **output** current limit. **Never-exceed for this branch (see BG-03 S4): ±1.6 A**, the datasheet's ABSOLUTE MAXIMUM on continuous current in/out of VDD — **a damage threshold, NOT an allowance, NOT a PSU setting, NOT a prediction of draw; nothing may be set or permitted up to it.** **The shipped configuration is a different condition:** GAIN floating = **9 dB is CONFIRMED (DR3-2)** as the intended shipped configuration (`PinMap.hpp`:20-24) — verify the fitted board's actual pad mapping against the datasheet before soldering — speaker impedance unverified (`HARDWARE_INVENTORY.md`:98), and the synth's own theoretical peak sits below full scale (`kHeadroomPeak = 30000` of 32767, `w17-soundlight-fw/lib/soundsynth/include/soundsynth/EngineSynth.hpp`:101-118). **Table 8 and the Electrical Characteristics gain rows agree exactly with `PinMap.hpp`:20-24, and 9 dB is a typ whose guaranteed band is 8.4 … 9.6 dB**; an onboard 100 kΩ pulldown would ship the part at **15 dB**, which the pre-solder check (`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11) exists to exclude. **9 dB does NOT lower the amplifier's ceiling (DERIVED):** the full-scale output stays **supply-limited at all three gain band edges (8.4 / 9 / 9.6 dB)** — the binding ceiling is the 5 V rail, the same one the part has at 12 dB — so 9 dB tightens nothing here. **No upper bound on supply current is derivable, at any gain — CONFIRMED at 9 dB** — it needs a **minimum** efficiency and only a **typ at 8 Ω, 1 W, 12 dB** exists. **Record with the measurement:** `get sound.volume` from the same session, the GAIN strap as actually soldered, the measured speaker impedance, **and the amp's load state — which is the ENGINE STATE, not just the volume byte: record `Ignition` (Off / Cranking / Running) and the throttle percentage** (`synthVolumeFor`, `AudioDecision.hpp`:32-36, is the dominant term, so the same `sound.volume` byte spans more than an order of magnitude across Cranking / idle / full throttle and a volume-only record is uninterpretable). A reading taken with the engine sound silent (`Ignition::Off` ⇒ `synthVolume 0`, `AudioDecision.hpp`:33) is a silent-amp reading, is **not** a bound on the amp, and must not be chained as one; if the amp was silent this row stays THRESHOLD MISSING. **The volume-80 and volume-100 readings are two separate figures and neither can be scaled to the other:** output power scales by (100/80)² = 1.5625 because the operator mapping is linear (`AudioDecision.hpp`:78-82), but supply current does not, and no published figure relates them. Take the reading at the **recorded** volume (acceptance). **The ceiling reading at 100** (`kVolumeMax`, unity gain at Running + full throttle) **is taken only where the card already authorises an armed throttle command — never during the S0–S9 load-addition staircase, whose prerequisites keep the ESC signal disconnected. If that state is not reached, record the acceptance reading alone and leave the ceiling THRESHOLD MISSING.** |
| T8 | RP1 receiver draw | **THRESHOLD MISSING — owner/bench decides** |
| T9 | ESP32 module draw, Wi-Fi off (both boards) | **THRESHOLD MISSING — owner/bench decides** |
| T10 | ESP32 #1 draw with Bluetooth active (BT show-off build) — BT1 lists "3.3 V rail draw with BT active" as an unmeasured bench item | **THRESHOLD MISSING — BT1 measures it** (`BT1_BENCH_GATE.md`:66) |
| T11 | The bench-PSU current limit to set at each step below | **BLOCKED — O-6 derivation done 2026-09-06 (v2, after review R-O6); owner decisions outstanding.** Policy ratified (O-6, 2026-09-05): lowest defensible limit per substep, trip = STOP AND DIAGNOSE, never raise to make a trip go away, never exceed the rail/component limit. Per-substep derivation is on **BG-03 § "Starting current limits (O-6 derivation, 2026-09-06)"**, with named margin **M-PEAK** (**RATIFIED 2026-09-06, DR2-2**: manufacturer-specified MAXIMUM/PEAK values only, 0 % invented margin, never substitute typical/nominal/search-snippet values for peak, unresolved max remains unresolved, manufacturer max is design evidence not measured actual current — real bench measurements remain authoritative) and the chaining rule `L(N) = max(R(N-1), SUM P(k) for k<N) + P(N)` — a settled reading is never a bound on a bursty load. **All figures below are 5 V rail-side added-load allowances, NOT bench-PSU settings.** **DERIVED:** WS2812 strip **560 mA** emitter-model bound at the O-7 cap 180 / **188 mA** at the shipped cap 110, excluding an unquantified per-pixel controller term `[code LightRenderer.hpp:11,:110-111,:152,:209,:226]`; BL-M8812EU2 **1800 mA** — §1.3's own rated maximum supply current, which is the allowance; **DR2-7 named the shipped mode (5 GHz station) and it did not move the number**, because the operating point inside that mode is still uncaptured (§3.3's largest per-use-case peak, 1510 mA, is one RF-test case and not an envelope, and is never to be entered on the bench — see BG-03 S5), with the rail additionally required to deliver **≥ 1800 mA peak** per §6.2.1 `[datasheet, B-link V1.0 §1.3, §3.3, §6.2.1]`; MAX98357A quiescent **3.35 mA max at `TA = +25 °C` only** and standby **`ISTNDBY` 400 µA max** (`SD_MODE` high, no BCLK, `TA = +25 °C`), plus **≥ 640 mA at the datasheet's own 3.2 W condition** (4 Ω + 33 µH, THD+N 10 %, **gain = 12 dB**, VDD 5 V — a condition the project does not ship: GAIN floating = 9 dB is CONFIRMED (DR3-2) as the shipped configuration, pad-mapping verification pending pre-solder) — **but 3.2 W is a typ/guidance value, not a guaranteed limit, so `≥ 640 mA` is REFERENCE ONLY, is NOT M-PEAK-clean, and is not a sizing term**; ILIM **2.8 A is a *typ*** — the part's **output** limit `[datasheet, Maxim]`; the **±1.6 A** absolute maximum on continuous current in/out of VDD is a **damage threshold, NOT an allowance, NOT a PSU setting and NOT a prediction of draw** — it belongs in BG-03 S4's never-exceed column and **never** in a `P(N)`, a `Σ P(k)` or a sizing sum `[datasheet, Maxim]`; DS3235SG idle **5 mA** / stall **2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — Rail B's documented band is 5–6 V, `D8_BENCH_BRINGUP.md`:55) `[datasheet, DS SERVO]`. **STILL BLOCKED, and no absolute limit is settable until these are answered — now on the owner's consolidated photo/label packet (`W17_OWNER_PHOTO_LABEL_INTAKE.md`):** (1) **no document names the bench PSU** (DR2-3, packet item 1), so its minimum settable CC value is unknown and a settable limit is not even established (`13_phase_a_a2_no_power_checklist.md`:116); (2) **the supply is on the pack side (7.4 V) and every derived figure is a 5 V rail current** (BG-03 § Topology (ASCII)) — the pack-side form is `I_pack <= 5 A * V_rail / (V_pack * eta)` and eta needs the UBEC's model, which **no document names** (DR2-4, packet item 2; `HARDWARE_INVENTORY.md`:113 gives only "UBEC 5 A (2 pcs)"); (3) **S1/S2 (DR2-6, packet item 3) and S7/S8 (DR2-10, packet item 5) need a ruled ramp ceiling** — the empty-rail ramp of step 2 below is legitimate because it has one, and a loaded ramp without one is "raise until it works". **RESOLVED:** DR2-5 (PSU-first / ESC separation, RATIFIED 2026-09-06) and DR2-11 (the constant-current duration criterion for a connect, RULED 2026-09-06 at 500 ms — see T13) are no longer open. Do **not** fill this row from a family figure — a search-engine "DS3235SG stall 3.9 A" is uncited and states no test voltage, while the manufacturer gives 1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V. |
| T12 | ESC standby (logic-only) draw on batt+ with motor leads off | **BLOCKED — manufacturer publishes no standby figure; the term is absent from S0–S9 under DR2-5.** Hobbywing's own QuicRun 10BL120 page (Sensored G2, the owner's variant per `w17-batch1-measurements-for-codex.md`:41; fetched 2026-09-06) gives "120A/Peak Current 760A", "2-3S Lipo" and "BEC Output: Switch Mode 6V/7.4V @4A" and no standby current. Note the 4 A BEC is **irrelevant to every rail** — its red wire is cut (`w17-pdb-build-and-connector-guide.md`:80). **DR2-5 RATIFIED 2026-09-06 resolves the resolution question:** the ESC's 12 AWG feed is physically separated at the PDB for the whole S0–S9 staircase, so this term is absent from BG-03 and is **first observed at D8 Phase 1** instead — **but that feed is part of A2 gate S6** (`w17-pdb-build-and-connector-guide.md`:167-168), so separating it is a topology change: re-run A2's batt+ rows **P2 / P4 / P5** (`13_phase_a_a2_no_power_checklist.md`:237-241) **before and after**, and record the change. T12 itself stays **BLOCKED as a figure** — the manufacturer publishes none; only its point of first observation moved. |
| T13 | Inrush allowance at the moment the pack is connected | **The DURATION criterion is RULED 2026-09-06 (DR2-11); the inrush MAGNITUDE stays BLOCKED — do not conflate the two.** The XT90-S anti-spark exists because the inrush is large; no Amass specification giving its pre-charge resistor was located, no document states the ESC's input capacitance or the **UBEC's input capacitance and soft-start** behaviour — which is what a pack-side supply actually sees — and the bench pack (ZEEE 5200, `HARDWARE_INVENTORY.md`:208) has no C-rating in any document (the `≥25 C` at `:277` is the sourcing spec for the *unbought car pack*). **C1 and C2 are 5 V-side capacitors, downstream of the UBECs, and are not this event.** A battery has **no** settable limit, so nothing in this path limits it. Mitigation is procedural: mate the XT90-S deliberately and fully, observe, and treat any spark, heat or tick as a stop. **"Momentarily in constant current" is NOT by itself a discriminator** — at a low starting limit the supply can hold the rail down so a UBEC never completes soft-start, which looks identical to the fault. **The criterion, owner ruling verbatim (DR2-11):** "Continuous PSU constant-current operation lasting more than 500 ms after connection = STOP." Also: smell / abnormal heat / smoke / unexpected sound / visual anomaly = IMMEDIATE STOP; brief inrush alone does not authorize raising current; a CC trip never automatically advances the staircase; diagnose and justify before increasing the limit; record actual observed CC duration. **500 ms is a STOP threshold, not a permission — CC shorter than 500 ms is NOT thereby "allowed" and does not authorize raising the limit.** |

## How to derive T1–T13 safely — the staircase

**Heading corrected 2026-09-06 (doc nit from `NEW_SESSION_HANDOFF.md` §4 item 4): this is
T1–T13, not T1–T12.** T13 (inrush) is not genuinely outside the staircase — every connect in
steps 2 and 3 below is exactly the event DR2-11's constant-current duration criterion governs,
so the CC-duration observation that constitutes T13's evidence is collected throughout this
same procedure, not in some separate session. Only T13's inrush *magnitude* (how large the
current gets, not how long it stays in CC) remains outside what this staircase can bound —
that stays BLOCKED, uncited in either direction.

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
   After each: record the settled draw **and the load state as actually reached**; that reading
   *becomes* the T-row above. **Exception — the camera/Wi-Fi load.** Its DR3-1 30-minute streaming
   **S5 thermal-soak characterisation** (six sample times **0 · 5 · 10 · 15 · 20 · 30 min**) is
   defined in `bench-gates/BG-03_phase_b_first_power.md` § "Thermal check at S5" **and runs where
   that section places it — at the first camera bring-up session, NOT in this staircase**, because
   streaming is CB5-gated and no step here brings the camera up. Here, record the settled draw and
   the load state as actually reached; the characterisation stays **INCOMPLETE — never PASS, never
   a fault** until that session runs it. Nothing in this step authorises camera bring-up or any
   power beyond what Phase B already opened.
4. **Set the working limit** at the recorded total plus a stated margin, and **write the margin
   down** — the margin is a decision, not a fact, so it belongs in the evidence with a name on it.
   **RULED 2026-09-05 (D-4 O-6):** the limit for each substep is the **lowest defensible limit**
   for that substep — never a round-number guess.
5. **Never raise a limit to make a trip go away.** A trip during this staircase is the tool
   working. Pull power, find the fault, re-run A2's relevant rows (`13_phase_a_a2_no_power_checklist.md`).
   **RULED 2026-09-05 (D-4 O-6):** a current-limit trip means **STOP AND DIAGNOSE** — never simply
   increase the limit until it works; raise it only after the trip is understood and the next
   setting is justified; never exceed the applicable rail/component safety limits. **RULED
   2026-09-06 (DR2-11): a CC trip never automatically advances the staircase** — diagnose and
   justify before increasing the limit, and record the actual observed CC duration at every
   connect (STOP above 500 ms; a shorter duration does not itself authorize the next step).
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
- **DR2-11 RULED 2026-09-06:** continuous PSU constant-current operation lasting more than
  **500 ms** after any connect → STOP (500 ms is a threshold, not a permission — a shorter
  duration does not authorize raising the limit or skipping the next diagnosis).
- **DR2-11 RULED 2026-09-06:** record the actual observed constant-current duration at every
  connect, whether or not it trips the 500 ms STOP.

## What this file is not

It is not a permission to power anything, it does not set any limit, and it must not be read as
"the numbers are known". Its substantive claim, as updated by the O-6 derivation of 2026-09-06:
**four car-side parts now have cited current figures (L11–L15) and every other car-side 5 V
load has none**; **no substep has a settable starting amperage**, every figure in L11–L15 is a
**5 V rail-side** allowance rather than a bench-PSU setting, and the first Phase B session is
where the missing numbers get created. (The ground-side 5 V loads in the GCS box do have cited
figures: `w17-gcs-box-guide.md:135-139`.)
