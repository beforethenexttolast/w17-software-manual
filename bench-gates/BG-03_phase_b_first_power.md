# BG-03 — Phase B first power (logic only, ESC motor power disconnected)

*Card for `w17-control-fw/docs/PHASE_B_FIRST_POWER.md` (cited as **PB**), whose source ordering
is `w17-control-fw/project-review/11_hardware_validation_plan.md` §Phase B (cited as **plan**),
with the checkbox detail in `w17-control-fw/docs/D8_BENCH_BRINGUP.md` (cited as **D8**).*

> **Gate line, verbatim in force:** Phase B is **BLOCKED** until A2 is filled in with real bench
> readings, its §12 two-part PASS is recorded, **and** the result is reviewed and approved
> (PB:3-10). As of this card, A2 is NOT-EXECUTED and Phase B is BLOCKED.

## Prerequisites

1. **`A2-CLOSED` recorded** (BG-02) **and `PHASE-B-OPEN` recorded** — two separate states, the
   second owner-only, both dated in `CURRENT_STATUS.md`
   (`w17-parts-to-gift-master-sequence.md`:188-192, :204).
2. **Wheels off the ground**, car on a stand or fixture that cannot roll (PB:28).
3. **An observer present** — not a solo unattended session; this is the workspace rule against
   unattended flashing/powering (PB:29-30).
4. **The battery lead must be pullable at the master switch / XT60 split without reaching past
   any moving or hot part.** Know where your hand goes before you need it there (PB:31-32).
5. **ESC signal and both servo/actuator leads physically disconnected** until B3 reconnects them
   one at a time (PB:33-34).
6. **ESC motor leads disconnected for the whole of this card.** The motor does not turn in
   Phase B; that is Phase C (PB:14-17).
7. RP1 bound to the TX **with failsafe mode "No Pulses"** — "Set Position" would keep sending hold
   frames and defeat the frame-timeout failsafe entirely (D8:63-64).
8. **CP1–CP3 are not optional here.** If A2 recorded them NOT-ASSEMBLED, they are a **hard
   precondition to the first pack connection** — run them before any pack meets this harness
   (A2:560-562, :816-821).

## Required equipment

- Multimeter.
- **Oscilloscope or logic analyser** — B1.3 and B1.4 are scope rows and cannot be done with a
  meter (PB:44-45).
- Serial monitor at **115200** (PB:35-36).
- `elrs-joystick-control` on the PC (PB:36), and the RP1 + TX bound at the same ELRS
  major.minor + bind phrase (D8:61-62).
- A way to spin the rear axle by hand (PB:36).
- **A contact temperature probe, or a multimeter with a K-type thermocouple input — only if one
  exists (DR3-3; `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` row 14, still an OPEN owner CHECK).**
  If none exists, temperature is not recorded and is **never** estimated from touch, and the
  quantitative heatsink-temperature evidence stays BLOCKED.
- **A bench PSU for the S0–S9 staircase — RATIFIED 2026-09-06 (DR2-5, PSU-first / ESC
  separation).** The earlier "bench PSU or the battery" wording is superseded: initial
  logic/rail characterization uses **bench-PSU-first** operation, with the propulsion/ESC
  12 AWG feed **physically separated at the PDB** for the S0–S9 substeps below. Owner ruling,
  verbatim: "**Do not energize propulsion merely because logic-side first-power work is
  active. No execution is authorized yet.**" **Consequence (unchanged from the O-6 derivation
  and T12):** that feed is part of A2 gate S6, so separating it is a topology change —
  **re-run A2's batt+ rows P2 / P4 / P5 before and after, and record the change.** This does
  not contradict `D8_BENCH_BRINGUP.md`:55's first battery connection: D8 Phase 1 is the first
  **battery** connection and **follows** this PSU staircase, it does not replace it. See
  `bench-gates/tools/first_power_current_limits.md` before choosing a limit, and read its
  finding: **the project documents no expected current for any car-side 5 V load** (the
  ground-side GCS box loads do have cited figures — `w17-gcs-box-guide.md:135-139`).
  **Current-limit policy RULED 2026-09-05 (D-4 O-6, staircase policy ratified):** set the
  lowest defensible limit for the substep being powered; a current-limit trip means **STOP
  AND DIAGNOSE**, never simply increase the limit until it works; raise the limit only after
  the trip is understood and the next setting is justified; never exceed applicable
  rail/component safety limits. **Starting limit per substep: derived offline 2026-09-06
  (v2, after review R-O6) — see the subsection below; still BLOCKED** on the owner's
  consolidated photo/label packet (`W17_OWNER_PHOTO_LABEL_INTAKE.md`): bench PSU identity and
  minimum settable limit (DR2-3, packet item 1); UBEC make/model and BEC#2's set voltage
  (DR2-4, packet item 2); the S1/S2 ramp ceiling (DR2-6, packet item 3) and S7/S8 ramp
  ceiling (DR2-10, packet item 5). **The constant-current duration criterion is RULED
  2026-09-06 (DR2-11):** see "Starting current limits" below. No amperage is stated on this
  card, and **no figure in the subsection below is a bench-PSU setting** — they are 5 V
  rail-side allowances.

### Starting current limits (O-6 derivation, 2026-09-06)

**Evidence label: NOT-EXECUTED.** Nothing below has been measured. O-6 (owner, 2026-09-05)
ratified the staircase policy and forbade inventing an initial amperage; this subsection is
the offline derivation that ruling required, and it ends in BLOCKED rows on purpose.

**The policy, in force:** lowest defensible limit for the substep · a current-limit trip is
**STOP AND DIAGNOSE** · never simply increase until it works · increase only after the trip
is understood and the next setting is justified · never exceed the applicable rail/component
limit.

> **DOMAIN WARNING — read before using any number here.** Every figure in the P(N) and
> NEVER-EXCEED columns below is a **5 V rail-side** current. **None of them is a bench-PSU
> setting.** The supply sits on the **pack side (7.4 V)**; the pack-side never-exceed that
> corresponds to a 5 A rail is `I_pack <= 5 A * V_rail / (V_pack * eta)`, where `eta` is the
> UBEC's conversion efficiency — **unknown, because no document names the UBEC**. Dialling a
> 5 A rail figure into a pack-side supply would permit roughly 7 A of rail current at a high
> efficiency: 40 % above the rating it is meant to protect.

**The margin, named:** *M-PEAK* — **RATIFIED 2026-09-06 (DR2-2).** As this card defined it: "for
each load take the manufacturer's **Max/peak** figure (never Typ) and the LED model's **stated
upper bound** (never its actual draw); add no percentage" — **owner's clauses, verbatim:** use explicitly
manufacturer-specified **MAXIMUM / PEAK** values; add **0 % invented percentage margin**; never
substitute typical/nominal/search-snippet values for peak; an **unresolved max remains
unresolved** (it is not filled in from a family figure); the manufacturer max is **design
evidence, NOT measured actual current** — real bench measurements remain authoritative once
taken. A percentage would be an invented number; the typ→max gap is the manufacturer's own worst
case and it carries a citation. **Direction:** a limit is a fuse, so *lower* is more
protective; M-PEAK exists so the limit is not set below a healthy draw, and a datasheet
figure that is a **requirement on the supply** (the Wi-Fi module's "Peak current ≥1800mA",
its §6.2.1) belongs in never-exceed, never in P(N) — while a figure that **is** the part's own
rated maximum draw (the same module's §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)") belongs
in P(N), however large it looks.

**Inrush is NOT covered by M-PEAK, and the duration criterion is RULED 2026-09-06 (DR2-11);
the inrush MAGNITUDE stays uncited/BLOCKED — do not conflate the two.** Every connect pulls the
supply into constant current briefly. On the **7.4 V** side that is the **UBEC's input
capacitance and soft-start** — **C1 (Rail B) and C2 (strip input) are 5 V-side capacitors,
downstream of the UBECs, and are not what the supply sees**. "Momentarily" is not by itself a
discriminator: at a low starting limit the supply can hold the rail down so the UBEC never
completes soft-start, which presents exactly as the "the supply **sits** in constant-current"
fault. **The duration criterion, owner ruling verbatim (DR2-11):** "Continuous PSU
constant-current operation lasting more than 500 ms after connection = STOP." Also, verbatim:
"smell / abnormal heat / smoke / unexpected sound / visual anomaly = IMMEDIATE STOP; brief
inrush alone does not authorize raising current; CC trip never automatically advances the
staircase; diagnose and justify before increasing the limit; record actual observed CC
duration." **Important: 500 ms is a STOP threshold, not a permission — CC shorter than 500 ms
is NOT thereby "allowed" and does not authorize raising the limit.** Record the actual
observed CC duration at every connect. An unexplained constant-current event is a STOP
regardless of its duration — 500 ms bounds how long an *explained* inrush may last, not how
much of an unexplained one is tolerable.

**The chaining rule:** the limit applies to everything present, so
`L(N) = max( R(N-1), SUM of P(k) for k < N ) + P(N)`, where `R(N-1)` is the settled total
recorded minutes earlier in this same session and `P(k)` is the cited peak of the load added
at substep k. **A settled reading is never a bound on a bursty load** — a settled reading may
stand in for a load only where no cited peak exists for it (the Wi-Fi module alone spans
113 mA unassociated to 1510 mA peak). Only L(0) and L(1) need a number no measurement can
supply.

**Two facts that block every absolute value, and are not lookups:**
1. **No document names the bench PSU** (`13_phase_a_a2_no_power_checklist.md`:116 says only
   "have them, do not connect them"), so its minimum settable constant-current value — the
   literal first number the staircase's step 1 asks for
   (`bench-gates/tools/first_power_current_limits.md`:123-125) — is unknown, and it is not
   established that it has a settable limit at all.
2. **The supply is on the pack side (7.4 V) and every derived load figure is a 5 V rail
   current** (this card's own *Topology (ASCII)* section). Converting between them needs the
   UBEC's efficiency, and **no document names the UBEC's make or model** — only "UBEC 5 A
   (2 pcs)" (`HARDWARE_INVENTORY.md`:113).

**Bench pre-step for every Rail-B row:** at D8 Phase 1, **record BEC#2's actual output
voltage** before S6–S9 and B3.1, and select the servo stall column from it. Rail B's
documented band is **5–6 V** (`D8_BENCH_BRINGUP.md`:55; this card's sibling
`BG-04_d8_bench_bringup.md` PASS row for Phase 1), not 5 V.

| Substep | Added-load allowance P(N) — **5 V side** | Absolute limit L(N) — **pack side** | Never-exceed — **5 V side, NOT a PSU setting** | Status |
|---|---|---|---|---|
| S0 PDB alone | divider 37 kΩ → **0.20 mA at 7.4 V** (0.23 mA at 8.4 V) — **this one row is genuinely pack-side**; UBEC quiescent absent, **ESC standby absent by DR2-5 separation** | — | PSU's own limits (unknown) | **BLOCKED — DR2-3, photo packet item 1** — needs the PSU's minimum settable limit |
| S1 + ESP32 #1/#2 idle | — | — | Rail A output **5 A** — and the rail's rating is **not** a ramp ceiling for two D1-mini boards | **BLOCKED — DR2-6, photo packet item 3** — MH-ET LIVE publishes no datasheet; the WROOM-32 module datasheet is not the board. Once the onboard regulator marking is read, derive the ceiling from the actual regulator manufacturer's data |
| S2 + RP1 | — | — | Rail A output **5 A** — same objection as S1 | **BLOCKED — DR2-6, photo packet item 3** — RadioMaster's own page gives 5 V and no current figure; no regulator to read on RP1 itself. Derivation after item 3's MH-ET identification will say what, if anything, bounds S2 — no number is ruled |
| S3 + WS2812 strip @ ceiling **180** — **DR2-13 RULED 2026-09-06: 180 is the owner-approved upper operating *ceiling* only — it bounds this allowance row; it is NOT the shipped value and nothing here authorizes running at it. Raising the shipped cap requires physical halo/visibility/current/rail evidence from BG-08 that 110 is inadequate, plus a reviewed `w17-soundlight-fw` firmware change on its own branch and a fresh push grant (`maxBrightness` is compile-time, `LightRenderer.hpp`:152)** | **560 mA** — **emitter-model** upper bound (code's integer form 540 mA); **excludes each pixel's controller quiescent draw, which Worldsemi does not publish** — carry it as an unquantified adder | — | compile budget **900 mA**; Rail A output **5 A** | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S3 + WS2812 strip @ shipped **110** — **DR2-13 RULED 2026-09-06: this is the operating row — KEEP shipped `maxBrightness = 110`; no firmware-change branch now** | **188 mA** — same emitter-model caveat (code's integer form 180 mA) | — | as above | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S4 + MAX98357A + speaker | quiescent **3.35 mA max — a manufacturer MAXIMUM valid at `TA = +25 °C` only**; the datasheet gives no max over the operating range. **Also M-PEAK-clean and directly applicable to this substep: standby current `ISTNDBY` 400 µA max** (`SD_MODE` high, **no BCLK**, `TA = +25 °C`) — if the amp is added to the rail with the I²S clocks not running, that is the manufacturer maximum **for that state only**; it is not a bound on the driven amp. **Driven: BLOCKED for the shipped configuration.** The part draws **≥ 640 mA at the datasheet's own 3.2 W condition** — `ZSPK = 4Ω + 33µH`, `THD+N 10%`, **`gain = 12dB`**, `VDD = 5V` (energy conservation, 3.2 W / 5 V; no efficiency figure needed) — but **3.2 W is a typ/guidance value, not a guaranteed limit**: the datasheet's own closing statement is *"The parametric values (min and max limits) shown in the Electrical Characteristics table are guaranteed. Other parametric values quoted in this data sheet are provided for guidance."*, and the `POUT` rows carry no min/max entry. **So ≥ 640 mA is a labelled REFERENCE-ONLY figure, is NOT M-PEAK-clean, and must not be used as a rail-sizing term.** **The car ships at a different gain:** `GAIN` floating = **9 dB is CONFIRMED (DR3-2)** as the intended shipped configuration (`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24; `bench-gates/BG-04_d8_bench_bringup.md`:143; Phase 9 has not run) — **before permanent soldering, the actual board's GAIN implementation/pad mapping must be verified against the exact article and the manufacturer datasheet** (the fitted part is a generic AliExpress "MAX98357A I2S amplifier 1PCS" — `HARDWARE_INVENTORY.md`:97, `w17-control-fw/docs/bill_of_materials_v2.md`:69-70 — do not assume the Adafruit pinout), and the speaker's 4 Ω traces to one BOM line the inventory itself calls "a bench spec-check" (`HARDWARE_INVENTORY.md`:98). **The datasheet's 12 dB specification point is NOT the shipped configuration** and must not be presented as it: at 9 dB the manufacturer publishes no output-power figure, so the shipped driven draw is **not** bounded below by 640 mA. **DR3-2 gain-table agreement — DERIVED:** the datasheet's **Table 8** (`GAIN_SLOT` unconnected = 9 dB, GND = 12 dB, VDD = 6 dB, 100 kΩ to GND = 15 dB, 100 kΩ to VDD = 3 dB) and the Electrical Characteristics gain rows agree **exactly** with `PinMap.hpp`:20-24; **9 dB is a typ whose guaranteed band is 8.4 … 9.6 dB**. The pin is read by a comparator against fractions of VDD, so **an onboard 100 kΩ pulldown would ship the part at 15 dB** — which is why the strap stays BLOCKED until the pre-solder check (`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` "Physical actions that need no purchase", item 11). **Do NOT read 9 dB as "quieter than the 12 dB spec point" — DERIVED:** at 9 dB the full-scale output remains **SUPPLY-LIMITED at every one of the three gain band edges (8.4 / 9 / 9.6 dB)**, exactly as it is at 12 dB, because the binding ceiling is the 5 V rail and not the gain. **9 dB therefore does not reduce the amplifier's worst case, and nothing here is tightened by it** | — | amp **±1.6 A** — the datasheet's **ABSOLUTE MAXIMUM RATING** on *"Continuous Current In/Out of VDD/GND/OUT_"*. **This is a damage threshold under the datasheet's AMR caveat** (*"These are stress ratings only, and functional operation of the device at these or any other conditions beyond those indicated in the operational sections of the specifications is not implied"*) — **NOT an allowance, NOT a PSU setting, NOT a prediction of draw; nothing may be set or permitted up to it.** It must never be entered in a `P(N)` or `Σ P(k)` cell and never dialled into the bench PSU as this branch's current limit — T11's ratified policy is the **lowest defensible limit per substep**. Its only use is negative: **no figure, setting or allowance on this card may permit sustained amp-branch current above it.** **ILIM 2.8 A is a *typ*** and is the part's **output** current limit, not a supply-current maximum; it is short/fault protection, not a normal-operation bound. Rail A output **5 A** | **BLOCKED — on two separable data, both named.** **(i) No manufacturer MINIMUM efficiency is published**, so no **upper** bound on supply current is derivable at **any** gain — the only cited efficiency is a **typ at 8 Ω, 1 W, gain 12 dB** (92 %), which DR2-2 forbids substituting. **This is a datasheet gap, not an owner question: no photograph can close it**; it closes by bench measurement or not at all. **(ii) Speaker impedance — DR2-8, photo/label packet item 6.** (The fitted board's GAIN implementation is separately unverified until the pre-solder check, `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11.) **This row must state its load state, and the load state is the ENGINE STATE — not just the volume byte.** Record `Ignition` (**Off / Cranking / Running**) **and the throttle percentage** with the reading: `synthVolumeFor` (`AudioDecision.hpp`:32-36) is the dominant term, so the same `sound.volume` byte spans more than an order of magnitude across Cranking / idle / full throttle and a volume-only record is uninterpretable. **There is no derivable expected value for this reading:** no reading at this substep is a PASS, and a low reading is not by itself evidence that the amp was silent — only the recorded engine state and `get sound.volume` say what the amp was doing. Record whether the engine sound was **silent** (`Ignition::Off` ⇒ `synthVolume 0`, `w17-soundlight-fw/lib/audiodecision/include/audiodecision/AudioDecision.hpp`:33 — bit-exact silence) or actually rendering, and at what `sound.volume`. **A silent-amp reading is not a bound on the amp and must not be chained as one** — if the amp was silent, T7 stays THRESHOLD MISSING and the amp keeps no cited peak in `Σ P(k)`. Acceptance load = the `sound.volume` **recorded at D8 Phase 11a** (compiled default **80**, `Link2Frame.hpp`:93, applies only if the NVS blob was never saved or fails validation); **ceiling = 100** (`kVolumeMax`), at which Running + full throttle gives unity gain (`AudioDecision.hpp`:32-36,:78-82; `EngineSynth.cpp`:155). **Record `get sound.volume` with the reading, or the reading cannot be interpreted.** If the speaker proves **8 Ω**, every figure here is slack, not tight (P ∝ V²/Z) |
| S5 + camera / Wi-Fi | Wi-Fi **1800 mA** — the module's own §1.3 rated maximum supply current ("Power Supply DC 5.0V±0.25V @1800mA (Max)"). **DR2-7 resolved the shipped RF mode and it does NOT move this number:** the shipped role is **5 GHz STATION**, joining the laptop's hosted hotspot (`w17-gcs-box-guide.md`:195-197, a 2026-09-03 correction that supersedes the AP wording still standing in `w17-control-fw/docs/w17_wiring_assembly_atlas.html`:170), with **both** U.FL ports populated (`w17-pdb-build-and-connector-guide.md`:89). **No §3.3 row may be assigned to it:** TX power, channel width and encoder bitrate are NOT FOUND in any canonical config; no camera-side config is checked in anywhere (capturing it is an open bring-up task, `w17-ground-station/docs/video_topology_baseline.md`:45-49); the manufacturer states TX power is **customer-set in the Linux driver's configuration file** (§4) and that file is uncaptured; and every §3.3 row is a manufacturer bench condition at `VDD5.0 = 5.0 V`, `Ta 25 °C` — four Linux-driver rows (unassociated 113/123 mA; TCP-throughput up to 732/928 mA) and fifteen fixed-MCS, fixed-dBm `(RF test)` rows. **STRESS / WORST CASE, on paper only:** `HT20 MCS8 TX @ 27.5 dBm (2TX RF test) — 927 mA IRMS / 1510 mA IPeak`, the largest IPeak in the table. **No bench step may deliberately enter it** — it needs a vendor RF test mode, it is a live-TX action, DR2-7 forbids redefining shipped behaviour around stress mode, and the datasheet already publishes the number. Camera term absent | — | module requires the rail to **deliver ≥ 1800 mA peak** (§6.2.1) — a supply-capability requirement, not a limit to set; Rail A output **5 A**. **Camera-side CONFIGURATION never-exceed, in dBm and NOT a current:** §4 — *"Customers must define the TX power same or lower than recommended Target TX Power"* — 802.11a 6 Mbps **29 dBm**, HT20 MCS0 **28 dBm**, HT40 MCS0 **28 dBm**, VHT80 MCS0 **27 dBm** (± 2 dBm). It constrains the camera's driver config, never a rail limit (see `bench-gates/tools/first_power_current_limits.md` **L16**) | **BLOCKED** — no figure for the OpenIPC SSC338Q at 5 V, and the RF operating point is unresolved, so under DR2-2 it **stays** unresolved. **This row must also state its load state** (powered-but-unassociated ≠ streaming): a settled reading taken unassociated cannot stand in for T2, "Rail-A draw with the camera + Wi-Fi module **streaming**" — **if the module was not streaming, T2 stays THRESHOLD MISSING** (streaming is CB5-gated, `w17-ground-station/docs/video_profiles.md`:102) |
| S6 + blower | — | — | Rail B output **5 A** | **BLOCKED — DR2-9, photo packet item 4** — the BOM names an "ACP2006-class" part, not a part number |
| S7 + one MG90S | — | — | Rail B output **5 A** — not a ramp ceiling for one micro servo | **BLOCKED — DR2-10, photo packet item 5** — generic part; TowerPro's own page publishes no current figure and quotes 4.8 V operating, below Rail B's band. Do not use a generic internet MG90S value as if it describes the fitted servo — the smallest specific question is the branding/label on the fitted servos' cases and, if kept, the listing/packaging they came from |
| S8 + remaining MG90S | — | — | Rail B output **5 A** | **BLOCKED — as S7 (DR2-10, photo packet item 5)** |
| S9 DS3235SG holding centre (T3) | **5 mA** (datasheet idle-at-stopped; identical in all three voltage columns) | — | servo **stall 2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — select from the recorded BEC#2 voltage); Rail B output **5 A** | **P(N) DERIVED**, L(N) **BLOCKED** |
| S9 DS3235SG full-lock sweep, linkage OFF (T4) | — (no running-current figure exists; the datasheet gives only idle and stall) | — | **2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — select from the recorded BEC#2 voltage) — this is the number C1 exists for | **ceiling DERIVED**, expected draw **BLOCKED** |
| **B3.1** full L/R sweep **with the linkage fitted** | — (a loaded sweep is neither idle nor stall) | — | **inherits the S9 sweep ceiling at the rail's set voltage** — a bind drives the servo toward stall under real mechanical load | **ceiling INHERITED**, expected draw **BLOCKED** |

**Thermal check at S5 — evidence recording, not a pass/fail (DR2-14 RULED 2026-09-06).** The module's datasheet requires
customer-added cooling — §3.1: *"This module built-in high-power FEMs will generate more heat … additional heat dissipation
devices must be added by customers. Ensure that the junction temperature of module chipset is within rated value:
Tj<125℃"* — and §6.4 recommends a heat sink *"≧ 32*32mm"* against the fitted 28×28×3 mm. The project rule *"heatsink fitted
before first power-on"* (`learning-manual/05_control_firmware_documentation_explained.md`:365-366) is unchanged and is a
**precondition of this card**, not this step. **Nothing in this paragraph authorises powering anything**; it says what to
record if and when the S5 substep is reached under an already-open Phase B.

**A surface-temperature PASS limit is NOT derivable and must not be invented.** The datasheet publishes **no thermal
resistance, no case-temperature limit and no dissipation figure**, so `Tj < 125 ℃` cannot be converted into a heatsink
temperature. Any surface number — 60, 70, 80 °C — would be invented, and in the *dangerous* direction: a fabricated PASS
temperature reads as safety evidence while proving nothing. What IS derivable:

1. **Ambient — DERIVED, and it is a criterion.** Rated ambient operating range **−20 … +70 °C** (§1.3, §3.1). **Ambient
   above +70 °C is outside the module's rated operating conditions: stop, improve bay ventilation, and re-run — a reading
   taken above it characterises nothing.** Measure the **air** near the module with a probe (an IR instrument reads
   surfaces, not air). Its second job is to make the surface reading interpretable: **ΔT above ambient carries the
   information**, not the surface reading alone.
2. **Proof-of-violation — DERIVED, one-directional.** Heat flows chip → shield can → heatsink → air and §3.1 names the
   chipset as the source, so a heatsink surface reading **≥ 125 °C proves Tj > 125 °C = STOP**. The converse does **not**
   hold: a low reading proves nothing about Tj, so this creates **no PASS**.
3. **The protective stop is already ruled and is not numeric:** DR2-11 — *smell / abnormal heat / smoke / unexpected sound /
   visual anomaly = IMMEDIATE STOP*. This step cites it; it does not compete with it.

**STOP (thermal):** DR2-11's sensory rule — or a heatsink surface reading **≥ 125 °C**, which proves the datasheet's
`Tj < 125 ℃` is already violated. **No other numeric thermal STOP is derivable**, and "still rising" is an inconclusive
result, not a fault.

**Duration and sample cadence — RULED 2026-09-06 night (DR3-1).** The owner's ruled step is **the S5 thermal-soak
characterisation**: **30 minutes continuous streaming in the actual shipped/production Wi-Fi mode** — 5 GHz STATION
joining the GCS-box hosted hotspot, **streaming**. That is a load state this card previously only required to be
**recorded** (S5 row, :155 — *"powered-but-unassociated ≠ streaming"*), and which DR3-1 now makes a **condition of
the characterisation**. (The soaks at `bench-gates/G-02_phone_video_glass_to_glass_latency.md`:87, :102 and :274
belong to the phone glass-to-glass latency gate and are not this window; they are cited here only to keep the two
apart.) Sample at exactly **0 · 5 · 10 · 15 · 20 · 30 min** — there is no 25-minute sample; this is the owner's own
list, copied verbatim (`2026-09-06_offline_decision_round_3.md` DR3-1). **This is NOT a claim that 30 minutes proves
thermal equilibrium** (owner's words). The existing sensory STOP (DR2-11: abnormal smell / abnormal heat / smoke /
unexpected sound / visible anomaly / any other abnormal behaviour → IMMEDIATE STOP) stays active throughout the
window, and **the PSU limit set for S5 stays unchanged for the whole 30 minutes**. **DR3-1 authorises no powered
execution** (owner's words).

**Where this window runs — NOT inside the S0–S9 staircase.** No step of this card brings the camera up: this card's
numbered procedure is **B1.1–B4.4** (links/signals, safety chain, actuators + board #2, sensors), the camera-config
capture block below is explicitly *"at the first camera bring-up"* and *"authorises nothing"*, and streaming itself
is **CB5-gated** (`w17-ground-station/docs/video_profiles.md`:102 — *"the camera hardware is CB5-gated — there is
nothing to configure or verify yet"*; `CURRENT_STATUS.md`:1358 lists CB5 as `BLOCKED_HARDWARE`). The **S5 thermal-soak
characterisation** therefore runs at the **first camera bring-up session** — the first session in which streaming in
the shipped mode is actually reachable — carrying the **S5 load definition and the S5 PSU limit unchanged** for the
whole window, exactly as ruled. **Nothing in this paragraph opens that session, opens S5, or authorises any power**;
camera bring-up stays CB5-gated and needs its own explicit fresh owner authorisation.

**What the staircase's own S5 substep records — and what it does not settle.** When S5 is reached inside an
already-open Phase B, record what is actually reachable there: the **load state as actually reached**
(powered-but-unassociated / associated / streaming), the **time**, the **sensory observation**, and — **only if a
suitable contact temperature instrument exists (DR3-3)** — temperature, with the instrument named and the spot on
the part where it was read. **That substep does not satisfy DR3-1.** Until the streaming session runs the window,
**the S5 thermal-soak characterisation row stays INCOMPLETE — never PASS, and never a fault.** A non-streaming S5
reading is evidence of what the module was doing, not evidence for the characterisation.

**Recording rule at each of the six sample times, wherever the window runs:** the load state at that sample; **and,
only if a suitable contact temperature instrument exists (DR3-3):** ambient and heatsink surface temperature, with
the instrument and where on the part it was read. **If no suitable instrument exists, temperature is NOT estimated
from touch** — each sample row then carries the load state, the time, and the sensory observation only, and the
quantitative heatsink-temperature evidence stays BLOCKED (DR3-3). **With no suitable instrument the +70 °C ambient
criterion above cannot be evaluated at all — it is not thereby satisfied**; the window then yields load-state, time
and sensory evidence only.

**If the temperature is still rising when the observation ends, that is NOT a stop** — it means steady state was not
demonstrated, so the recorded value is a **lower bound** on the eventual temperature. Write it down as a lower bound and
call the result inconclusive. Do not convert "still rising" into a fault, and do not change anything to make it stop
rising.

**Capture at the first camera bring-up so S5's acceptance row can be assigned from evidence.** These are **best-knowledge
suggestions for an OpenIPC/BusyBox target and are NOT verified against this camera's firmware** — no camera-side config is
checked in anywhere. Every command below is read-only. If a binary or file is absent, **record that as the finding**.
**Redact the PSK** before pasting anything from `wpa_supplicant.conf` into any repo file. **This list authorises nothing**;
it runs when camera bring-up is gated open (the camera hardware is CB5-gated).

```sh
cat /etc/os-release ; fw_printenv 2>/dev/null      # firmware build identity
iw dev                                              # interface, type (managed/AP/monitor), channel + width
iw dev wlan0 info                                   # type, txpower, channel/width as configured
iw dev wlan0 link                                   # BSSID, frequency, negotiated bitrate, signal (RSSI)
iw dev wlan0 get txpower ; iw dev wlan0 get power_save
iw phy                                              # bands, TX-power range, "Available/Configured Antennas"
iwconfig wlan0 ; iwpriv wlan0 2>/dev/null           # fallback if `iw` is absent
lsmod ; dmesg | grep -i 8812                        # which driver, and its module parameters
ls /sys/module/*8812*/parameters/ ; cat /etc/modprobe.d/* 2>/dev/null   # TX-power-limit / by-rate params
cat /etc/wpa_supplicant.conf                        # REDACT psk= BEFORE PASTING
cat /etc/majestic.yaml                              # encoder: codec, resolution, fps, bitrate, GOP
cli -g .video0.bitrate 2>/dev/null                  # majestic's own getter, if present
grep -rn 'bitrate_max\|dbm_threshold' /etc /usr/share 2>/dev/null
      # locate where the BOM's `bitrate_max=12, bitrate_min=2, dbm_threshold=-52`
      # (bill_of_materials_v2.md:203) actually lives, and RECORD THE UNITS
cat /proc/net/dev                                   # bytes/packets, for a real throughput figure
```

**What each unblocks:** interface type + channel width + TX power + antenna count decide whether any §3.3 row can ever
apply; the encoder bitrate decides whether the "300 Mbps TCP throughput" rows are anywhere near the real load. **Check the
configured TX power against datasheet §4** (`first_power_current_limits.md` **L16**): the manufacturer states the target TX
power for the non-calibrated rates is customer-set in the Linux driver's configuration file and **must not exceed** the
recommended Target TX Power for that rate. **A configured value above the §4 row for the rate in use is a
manufacturer-limit violation — correct it in configuration; it is never a reason to raise a current limit.**

**Cited figures used above, with sources (all retrieved 2026-09-06):**

- WS2812 strip: `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11 (`kNumPixels`
  = 30), :110-111 (`renderedDuty`), :152 (shipped `maxBrightness` = 110), :209
  (`kBudgetMilliamps` = 900), :226 (`perLedMa`), :242 (the check). At cap 180,
  `renderedDuty(255,180)` = 119 and the model gives 540 mA (integer) / 560 mA (un-truncated).
  **The model's 20 mA/channel is an uncited code comment** (`:205`), not a manufacturer
  figure; Worldsemi's **Mar-2017** *LED Characteristics* table gives **16 mA/channel**, which
  bounds the code model from below (448 mA at cap 180). The **Jan-2016 V1.0** revision has no
  current column. **Neither revision publishes the per-pixel controller's quiescent supply
  current**, so the strip figures bound emitter current only.
- MAX98357A: Maxim Integrated *MAX98357A/MAX98357B* datasheet, Electrical Characteristics —
  "Quiescent Current IDD … 2.75 [typ] 3.35 [max] mA", "Current Limit ILIM 2.8 A", "Output
  Power … ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB … 3.2 W", "Efficiency ε … ZSPK = 8Ω +
  68µH … 92 %". The ≥ 640 mA driven bound is 3.2 W / 5 V — conservation of energy, which
  needs no efficiency figure.
- BL-M8812EU2: B-link *BL-M8812EU2 datasheet*, document revision **V1.0** (official release
  2023-10-27), §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)"; §6.2.1 "Peak current
  ≥1800mA"; §3.3 "WLAN Unassociated 113/123 mA", "WLAN TX/RX TCP throughput 300Mbps
  732/928 mA", "HT20 MCS8 TX @ 27.5 dBm (2TX RF test) 927/1510 mA". Its §6.4 recommends a
  heat sink "≧ 32*32mm" against the project's fitted 28×28×3 mm — an open owner question,
  not an O-6 figure.
- DS3235SG: DS SERVO datasheet, model line "DS3235 / DS3235-180 / DS3235-270" (page 1's
  product photo shows a case marked "DS3235SG"), §4 Electrical Specification — "Idle current
  (at stopped) 5mA" in all three columns, and "Stall current (at locked) 1.9A / 2.1 A / 2.3A"
  at 5 V / 6 V / 7.4 V; "Operating Voltage Range 5-7.4V". **Caveat:** DS Servo's own download
  index lists no DS3235 file; confirm the case marking at build week.
- Rail ratings: `HARDWARE_INVENTORY.md`:113 ("UBEC 5 A (2 pcs)"). Rail B's voltage band:
  `D8_BENCH_BRINGUP.md`:55.
- The ESC's BEC is **not** a rail source and imposes no rail limit — its red +5 V wire is cut
  (`w17-pdb-build-and-connector-guide.md`:80; `bill_of_materials_v2.md`:195;
  `00_BUILD_SHEET.md`:32).

**Explicitly NOT used, and why:** a general-knowledge "typical ESP32 draws ~X"; a third-party
"80 mA" figure for the MH-ET board; a third-party "MG90S stall 400 mA"; a search result
claiming the DS3235SG stalls at 3.9 A — that figure is **uncited and states no test voltage**,
while the manufacturer's own datasheet gives 1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V. Family
figures are refused, not discounted.

**Owner decisions this subsection was waiting on — status as of Decision Round 2, 2026-09-06
evening** (Q1–Q9 and Q10′ of the derivation report's §5; none may be filled in from a family
figure):

1. **Q1 — DR2-3 BLOCKED, photo/label packet item 1.** The bench PSU's identity and its minimum
   settable current limit. Do not infer PSU model/current capability.
2. **Q2 — DR2-4 BLOCKED, photo/label packet item 2.** The UBEC's make/model **and BEC#2's set
   output voltage** (5 V or 6 V). Do not infer from product family.
3. **Q3 — DR2-5 RATIFIED 2026-09-06.** First energisation is **bench-PSU-first**, with the
   ESC feed **physically separated for S0–S9** (an A2 gate S6 topology change — re-run A2 rows
   P2/P4/P5 before and after, and record it). "Do not energize propulsion merely because
   logic-side first-power work is active. No execution is authorized yet."
4. **Q4 — DR2-6 BLOCKED, photo/label packet item 3.** The S1/S2 ramp ceiling. Do not infer the
   regulator from board family — once the MH-ET board's onboard regulator marking is
   identified, derive the ceiling from the actual regulator manufacturer's data and exact
   topology. S2 (RP1) has no regulator to read; derivation after item 3 will say what, if
   anything, bounds it — no number is ruled for S2 either.
5. **Q5 — DR2-7 DERIVED 2026-09-06 evening (O-6 addendum v2); the number did not move.**
   The RF power/mode the BL-M8812EU2 will actually run at. **Shipped mode: 5 GHz STATION**,
   joining the laptop's hosted 5 GHz Mobile Hotspot (`w17-gcs-box-guide.md`:195-197 and its
   2026-08-17 Addendum, :281-291) — not an AP. **P(5) = 1800 mA stands** (§1.3's own rated
   maximum supply current): **no §3.3 row is assignable**, because TX power, channel width and
   encoder bitrate are NOT FOUND in any canonical config, no camera-side config is checked in
   anywhere, and the manufacturer states TX power is customer-set in the Linux driver's
   configuration file (§4). **A §3.3 row becomes assignable only from a captured camera
   config** — see the capture list in "Starting current limits" above. **Stress / worst case,
   as DR2-7 asks: `HT20 MCS8 TX @ 27.5 dBm (2TX RF test) — 927 mA IRMS / 1510 mA IPeak`, the
   largest IPeak in the table — characterised on paper and NEVER RUN** (it needs a vendor RF
   test mode, it is a live-TX action, and the datasheet already publishes the number). What
   remains open is the operating point *inside* the shipped mode, which is a camera bring-up
   capture, not an owner decision.
6. **Q6 — DR2-8 PARTIALLY DERIVED 2026-09-06 evening (O-6 addendum v2).** The shipped
   `sound.volume`, and whether the speaker is confirmed 4 Ω. **Compiled default = 80**
   (`w17-soundlight-fw/lib/link2/include/link2/Link2Frame.hpp`:93), which applies **only** if
   the NVS blob was never saved or fails the loader's length/CRC/version/`valid()` check
   (`D8_BENCH_BRINGUP.md`:302-306). **Acceptance = the NVS value actually recorded at D8 Phase
   11a** (`D8_BENCH_BRINGUP.md`:315, :327-328), read back in the same session with the tuning
   console's **`get sound.volume`** (`w17-control-fw/lib/console/src/Console.cpp`:123 help
   line, :277-285 handler) — a limit derived at 80 is uninterpretable without that reading.
   **Ceiling = 100** = `kVolumeMax` (`Link2Frame.hpp`:92), where Running + full throttle gives
   unity gain. **Amplifier gain: 9 dB is CONFIRMED (DR3-2)** as the intended shipped
   configuration — `GAIN` floating
   (`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24); before permanent soldering,
   verify the fitted board's actual pad mapping against the exact article and the manufacturer
   datasheet (the fitted part is a generic AliExpress "MAX98357A I2S amplifier 1PCS" —
   `HARDWARE_INVENTORY.md`:97, `w17-control-fw/docs/bill_of_materials_v2.md`:69-70 — do not assume
   the Adafruit pinout). **Table 8 and the Electrical Characteristics gain rows agree exactly with
   `PinMap.hpp`:20-24 on the three legs that header documents (unconnected 9 dB · GND 12 dB · VDD 6 dB); Table 8 adds the two 100 kΩ legs (to GND 15 dB · to VDD 3 dB) the header does not mention — and 9 dB is a typ whose guaranteed band is 8.4 … 9.6 dB** (DERIVED, DR3-2);
   an onboard 100 kΩ pulldown would ship the part at **15 dB**, which is what the pre-solder check
   (`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11) exists to exclude. The datasheet's 3.2 W
   figure is published at **12 dB**, which is **NOT** the shipped configuration, so it is a
   spec-point figure and not a prediction for this car — **and it is a typ/guidance value, not a
   guaranteed limit**, so the `≥ 640 mA` derived from it is reference-only and not M-PEAK-clean.
   **9 dB is not "quieter":** at 9 dB the full-scale output stays **supply-limited at all three
   gain band edges (8.4 / 9 / 9.6 dB)**, the same 5 V rail ceiling the part has at 12 dB, so 9 dB
   tightens nothing (DERIVED).
   **Speaker impedance stays BLOCKED on photo/label packet item 6** (speaker label), per
   DR2-8's own fallback; if it proves 8 Ω every current figure here is slacker, never tighter.
7. **Q7 — DR2-9 BLOCKED, photo/label packet item 4.** The blower's actual part number (the
   BOM names a class, not a part).
8. **Q8 — DR2-10 BLOCKED, photo/label packet item 5.** The S7/S8 ramp ceiling. Do not use a
   generic internet MG90S value as if it describes the fitted servo; the smallest specific
   question is the branding/label on the fitted servos' cases and, if kept, the
   listing/packaging they came from.
9. **Q9 — DR2-11 RULED 2026-09-06.** The constant-current duration criterion for a connect:
   "continuous PSU constant-current operation lasting more than 500 ms after connection =
   STOP." See "Starting current limits" above; 500 ms is a STOP threshold, not a permission —
   CC shorter than 500 ms does not thereby authorize raising the limit.
10. **Q10′ — DR2-14 RULED 2026-09-06 — the Wi-Fi heatsink decision**, which gates **this very card**: the fitted heatsink
    is 28×28×3 mm against the module datasheet's *"≧ 32*32mm"* recommendation, and the
    project's own rule is *"heatsink **fitted before first power-on**"*
    (`learning-manual/05_control_firmware_documentation_explained.md`:365-366), which is what this
    card is. Owner ruling, verbatim: "do not deliberately ship below the module manufacturer's
    recommendation. Plan to source a ≥ 32×32 mm heatsink if mechanical clearance permits. A
    somewhat larger part is acceptable/preferred if it fits without creating mechanical, RF or
    serviceability problems. Still perform the planned thermal validation at first power."
    Procurement state update is the Director's, not this card's.

See `bench-gates/tools/first_power_current_limits.md` row T11 and
`_handoff/2026-09-06_O6_derivation_report.md` §5.

- Car on a stand. Battery pullable. Observer.

## Topology (ASCII)

```
   PC (elrs-joystick-control)          <-- ground side; BG-06 covers the wire out of here
        |  USB
   ELRS TX module  ) ) )  2.4 GHz  ) ) )  RP1 receiver
                                            |  CRSF 420000 8N1 NOT inverted
                                            |  RP1_TX -> GPIO16 ,  GPIO17 -> RP1_RX
                                            v
   bench PSU / pack --[XT90-S master]-- PDB --+-- UBEC A --> Rail A --> ESP32 #1  ---- link2 ---->  ESP32 #2
        (pullable, known hand path)           |                            |     GPIO25 -> GPIO16
                                              +-- UBEC B --> Rail B        |     115200 8N1
                                              |                            |
                                              +-- ESC 12 AWG feed          +--> GPIO13 steer   ) DISCONNECTED
                                                     |                     +--> GPIO14 ESC sig ) until B3
                                                     X                     +--> GPIO18 DRS     )
                                              MOTOR LEADS OFF              +--> GPIO19/23 gimbal)
                                              for ALL of Phase B

   scope points for B1.3 / B1.4:  GPIO13, GPIO14, GPIO18  (before any actuator is attached)
```

## Exact procedure (numbered)

**B1 — Links & signals** (PB:38-56; D8 Phases 2–3):

1. **B1.1** Confirm the RP1's CRSF output is **420000 baud, 8N1, NOT inverted**; `NewRcFrame`
   decodes; channels move with the TX. If nothing arrives, suspect RP1 binding and baud/inversion
   **before** suspecting firmware (PB:53-54). BG-06 is the frame-level version of this row.
2. **B1.2** Antenna-off / RX-down drives `uplinkLinkQuality → 0` and **latches**
   `rxSignalsFailsafe`.
3. **B1.3** **Scope GPIO13/14/18** pulse widths (**1000 / 1500 / 2000 µs**) and the **50 Hz**
   period on the real ESP32 **before** connecting the ESC or servos — this confirms LEDC did not
   silently reduce 16-bit resolution.
4. **B1.4** **Scope GPIO14 + GPIO13 from power-on through the first `setup()` write** — confirm no
   ESC arm/twitch or servo kick in the pre-`ledcAttachPin` float window. This is the firmware-timing
   side of the exposure A2's PD1 row records the harness side of. **Actuators stay disconnected
   until B1.4 passes** (PB:55-56).

**B2 — The safety chain** (PB:58-81; D8 Phase 5 — **THE GATE**). Do not skip; do not proceed on a
partial pass:

5. **B2.1** Power up with **no CRSF** → ESC neutral, DRS closed, steering centred.
6. **B2.2** Bring the link up **with the throttle stick forward** → motor command stays off until
   the stick returns to neutral (ArmGate) and the arm conditions are met.
7. **B2.3** Confirm the ESC arms every boot with the neutral-hold sequence (motor still
   disconnected); reconcile **`bootArmHoldMs = 2000`** against the ESC's own manual; confirm
   **forward/brake** mode, not forward/reverse.
8. **B2.4** Confirm worst-case failsafe detection at the chosen RP1 packet rate + an LQ=0 burst
   stays within **~540 ms worst case against the 500 ms budget**.
9. **B2.5 — the re-arm invariant** (2026-08-20, owner-ratified): a failsafe episode **latches** a
   disarm. Recovery with the arm switch left ON through the episode **must stay disarmed**; only an
   **OFF→ON toggle with the stick centred** re-arms; a boot with the switch already ON needs the
   same toggle. Contract: `lib/channels/include/channels/ArmGate.hpp`. **A fresh neutral appearing
   to re-arm is a regression, not a bench quirk** (PB:69-74).

**B3 — Actuators (bench, unloaded) & board #2** (PB:83-106; **D8 Phases 6, 7b and 9 — NOT Phase 7,
which is ESC + motor (`D8_BENCH_BRINGUP.md`:210) and therefore Phase C.** `PHASE_B_FIRST_POWER.md`:83
cites the range as "6–7b"; that range includes the motor phase and contradicts this card's own
precondition 6 — ESC motor leads disconnected for the whole of this card. The source defect is
recorded for a control-fw session.) Only after B2
passes **completely**; reconnect actuators **one at a time**:

10. **B3.1** Narrow steering endpoints to the linkage's mechanical travel; sweep full L/R with the
    linkage fitted — no bind, no stall.
11. **B3.2** Confirm **DRS 1000 µs = wing closed** (the failsafe-safe position); swap in config if
    reversed.
12. **B3.3** **link2 on the wire**: capture GPIO25 → board #2 GPIO16 at **115200 8N1**; board #2's
    `Link2Monitor` reports **`FrameReady`**, not `BadVersion`/`FrameInvalid`. If it does not, go to
    **BG-05** — this is the coordinated-flash symptom.
13. **B3.4** Decode a live link2 frame on board #2 identical to sender intent (throttle %, brake
    bit, ERS-deploy bit, gear, driveMode).
14. **B3.5** I2S audio through the legacy driver on the pinned core; check `i2s.begin()` return
    codes; confirm no fail-silent/block.
15. **B3.6** WS2812 `show()` does not glitch while audio DMA runs.
16. **B3.7** Board #2 with link2 RX disconnected at boot → the calm never-connected idle is
    acceptable; then cut the wire mid-run → **Lost → hazard within 500 ms**.
17. **B3.8** Board #2 mid-frame power-on with board #1 already transmitting → boots
    NeverConnected, syncs on the next start byte.
18. **B3.9** Camera gimbal (right stick, ch9/ch10): servos centre when disarmed; axes track and are
    not inverted; on a link drop, a **smooth ~2 s glide to centre** (`gimbal.decay`) — **not a snap
    and not a hold**; it glides back on recovery.

**B4 — Sensors (bench)** (PB:108-126):

19. **B4.1** ADC divider extremes — open/disconnected divider and full 8.4 V → sane `batteryMv`,
    no spurious low-voltage latch; log the eFuse cal type; check the 8.4 V point is not compressed
    by the 11 dB attenuation ceiling.
20. **B4.2** Hall (GPIO35) counts on a rolling bench test with a single magnet; baseline **before**
    any motor EMI exists.
21. **B4.3 — battery-sense plausibility (OD-10)**: with the pack at a known voltage, lift the
    divider's **lower** leg, then the **upper** leg, one at a time. Expect **no CRSF battery frame
    at all**, **no newly latched** low-battery warning, and `batteryMv` **0** on link2 — not a
    fabricated number, not a 100 %-full reading. An **already-latched** warning is held for
    `warnDelayMs` (**3 s**) of continuous implausibility and only then dropped. Restore each leg →
    the reading returns exact on the next sample. Record the converted mV each fault produces and
    confirm it lands **outside 4000–9000 mV**.
22. **B4.4 — Hall interrupt-rate margin, motor-free half (OD-11)**: hand-spin the rear axle, log
    `hallSensor.isrEntries()`, `lastWindowEntries()` and `guardFaults()` over a **~10 s** roll (the
    console `status` line prints all three), then repeat with the GPIO35 10 kΩ pull-up lifted
    (scope the pin). Record **entries per 100 ms** for both, and whether `guardFaults()` ever
    increments. The guard's bound is **180 entries / 100 ms** (20× the 5000 rpm maximum); the
    hand-spun roll must sit far below it. The full-throttle half is D8 Phase 8, **not this card**.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# 0. GATE CHECK, every session, before anything is plugged in.
#    STOP if any line says "Phase B stays BLOCKED", or no dated "PHASE-B-OPEN" line
#    appears: the rest of this card is not runnable.
grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN" CURRENT_STATUS.md | head

# 1. Evidence folder + environment stamp.
bench-gates/tools/bench_capture.sh BG-03 --no-serial --note "Phase B first power, B1"

# 2. The bench firmware, flashed ONLY once Phase B is open (D8:79):
cd w17-control-fw
pio run -e esp32dev_tuning -t upload

# 3. Console capture with real per-line timestamps (read-only; opening the port
#    resets the board, which is why this is Phase-B work):
cd /Users/vitaliykhomenko/Documents/projects
ls /dev/tty.*                       # identify the bridge
bench-gates/tools/bench_capture.sh BG-03 \
  --port /dev/tty.usbserial-XXXX --baud 115200 --seconds 600 \
  --note "B2 safety chain: arm gate, failsafe latch, re-arm invariant"

# 4. Console rows that produce B4.4's numbers (type into the tuning console):
#      status            -> prints isrEntries / lastWindowEntries / guardFaults
#      get batt.ppt      -> the calibration in force

# 5. Frame-level proof of B1.1, from a passive tap on the RP1 -> GPIO16 line
#    (see BG-06 for the tap and its rules):
bench-gates/tools/crsf_sniff.py --port /dev/tty.usbserial-YYYY --baud 420000 \
  --seconds 30 --raw-out bench-gates/evidence/BG-03/<stamp>/rp1_tap.bin --summary
```

## Expected evidence

- **B1.3**: scope captures of GPIO13/14/18 showing **1000 / 1500 / 2000 µs** at **50 Hz**, clean.
- **B1.4**: a scope capture spanning power-on → first `setup()` write on GPIO13 and GPIO14, with
  **no pulse or transient** in the pre-`ledcAttachPin` window (PB:49-51).
- **B2**: a timestamped console log showing every B2 row, including the **re-arm invariant**
  sequence — episode → recovery with switch ON → *still disarmed* → OFF→ON toggle → armed.
- **B2.4**: a measured detection latency figure with the packet rate it was measured at.
- **B3.3/B3.4**: board #2 reporting `FrameReady` plus a decoded frame matching sender intent.
- **B4.3**: the recorded mV each divider fault actually produced, and where it sat relative to the
  4000–9000 mV band.
- **B4.4**: entries per 100 ms for the plain roll and for the lifted-pull-up roll, plus the
  `guardFaults()` count.
- The `bench_capture.sh` `meta.txt` naming the **exact firmware commit** each observation was made
  against — an observation that cannot name its code is not evidence.
- **DR2-11 RULED 2026-09-06:** the actual observed constant-current duration at **every**
  connect, recorded even when it is well under the 500 ms STOP threshold.
- **S4 and S5 load states (O-6 addendum v2, 2026-09-06):** for S4, whether the engine sound was
  silent or rendering and at what `sound.volume` (with the `get sound.volume` read-back); for
  S5, whether the module was powered-but-unassociated, associated, or streaming. **A reading
  whose load state is not recorded is not evidence for T2 or T7** — a silent-amp or
  unassociated reading is not a bound on a bursty load and must not be chained as one.
- **DR2-14 / DR3-1 thermal (S5) — the S5 thermal-soak characterisation:** the six DR3-1 sample
  times (**0 · 5 · 10 · 15 · 20 · 30 min**, no 25-min sample) and the load state at each
  (**streaming** in the shipped mode is the ruled condition of the characterisation). **This
  window does not run inside the S0–S9 staircase** — no step of this card brings the camera up and
  streaming is CB5-gated, so it runs at the **first camera bring-up session**, with the S5 load
  definition and the S5 PSU limit unchanged (see § "Thermal check at S5"). **Until that session
  runs it the characterisation stays INCOMPLETE — never PASS, never a fault.** From the staircase's
  own S5 substep, record instead: the load state as actually reached, the time, and the sensory
  observation. **If a suitable instrument exists (DR3-3):** the instrument used, where on the part
  it was read, ambient at each sample, heatsink surface temperature at each sample, and whether the
  temperature had stopped rising — a still-rising final reading is recorded as a **lower bound** and
  the result called inconclusive, not a fault; **if no instrument exists:** each sample row carries
  load state + time + sensory observation only, quantitative heatsink-temperature evidence stays
  BLOCKED (DR3-3), and the +70 °C ambient criterion cannot be evaluated at all — it is not thereby
  satisfied.

## PASS/FAIL criteria (objective numbers)

| Row | PASS | FAIL |
|---|---|---|
| B1.1 | CRSF decodes at **420000 8N1, not inverted**; channels track the TX | no frames, or frames only after an inversion change (that would contradict the firmware, which has no inversion path — plan:66) |
| B1.3 | **1000 / 1500 / 2000 µs** at **50 Hz**, measured | widths that scale wrong ⇒ LEDC resolution silently reduced |
| B1.4 | **zero** pulses/twitches on GPIO13 and GPIO14 before `setup()` finishes attaching LEDC | any pulse — do not reconnect actuators |
| B2.1 | ESC neutral, DRS **closed**, steering centred, with **no** CRSF | any actuator not in its safe position |
| B2.2 | throttle command stays off until the stick returns to neutral | arm-into-throttle, ever |
| B2.3 | ESC arms every boot after **`bootArmHoldMs = 2000`**; mode is **forward/brake** | arms before the hold elapses; forward/reverse mode |
| B2.4 | detection within **~540 ms worst case** against the **500 ms** budget | anything beyond |
| B2.5 | recovery with the switch left ON → **stays disarmed**; only OFF→ON + centred stick re-arms | a fresh neutral alone re-arms ⇒ **regression** |
| B3.2 | **1000 µs = DRS closed** | reversed (fix in config, re-verify) |
| B3.3 | `Link2Monitor` = **`FrameReady`** in steady state | `BadVersion` / `FrameInvalid` ⇒ go to BG-05 |
| B3.7 | board #2 reaches hazard **within 500 ms** of the cut | slower, or no hazard |
| B3.9 | gimbal glides to centre over **~2 s** (`gimbal.decay` default **2000 ms**) | a snap, or a frozen hold |
| B4.3 | **no** battery frame; **no** newly latched warning; `batteryMv` **0** on link2; fault mV **outside 4000–9000 mV**; an already-latched warning drops only after **3 s** | a fabricated number, a 100 %-full reading, or a warning raised by an implausible sample |
| B4.4 | hand-spun roll **far below 180 entries / 100 ms**; `guardFaults()` behaviour recorded | approaching the bound without the fault path behaving as the native tests describe |

**There is no "mostly passes" state for B2** (PB:71-74).

## Stop conditions

- **B1**: no CRSF frames at all (check RP1 binding + baud/inversion before suspecting firmware);
  **any pulse or twitch on GPIO13/14 before the boot-float window closes** with actuators
  connected — do not proceed to B2 with actuators attached until B1.4 traces clean (PB:53-56).
- **B2** — any one of these is a hard stop: the ESC arms or accepts throttle before the boot-arm
  hold elapses; the arm gate ever allows arm-into-full-throttle; a failsafe episode fails to latch
  a disarm; recovery re-arms without the required switch toggle; detection exceeds ~540 ms.
  **Pull the battery lead, do not power-cycle-and-retry, report the exact reading first**
  (PB:76-81).
- **B3**: any servo binds or stalls audibly — back off immediately, that is a mechanical limit and
  not a tuning target; `Link2Monitor` reporting anything but `FrameReady` in steady state; a gimbal
  snap or hold instead of a glide (PB:103-106).
- **B4**: a divider reading that suggests a **wiring** fault rather than a calibration offset — for
  example one that does not move at all as voltage changes. Stop and re-check the harness against
  A2's divider rows before trusting any calibration built on top of it (PB:124-126).
- **Any time:** the supply sits in constant-current, anything is warm to the touch, or a UBEC
  ticks — power off first, diagnose second
  (`bench-gates/tools/first_power_current_limits.md`).
- **Thermal at S5 — DR2-14 (O-6 addendum v2) / DR3-1 (2026-09-06 night):** DR2-11's sensory rule
  governs (smell / abnormal heat / smoke / unexpected sound / visual anomaly = IMMEDIATE STOP) —
  **or** a heatsink surface reading **≥ 125 °C**, which proves the module datasheet's
  `Tj < 125 ℃` is already violated. **This governs throughout DR3-1's 30-minute streaming
  S5 thermal-soak characterisation window, during which the S5 PSU limit stays unchanged — and
  that window does NOT run inside the S0–S9 staircase:** streaming is CB5-gated and no step of
  this card brings the camera up, so it runs at the first camera bring-up session (see
  § "Thermal check at S5"). It stays **INCOMPLETE — never PASS, never a fault** until that session
  runs it, and nothing here authorises that session or any power. The same sensory rule governs
  the staircase's own S5 substep, which records the load state as actually reached, the time and
  the sensory observation.
  **No other numeric thermal STOP is derivable**, and no surface PASS temperature exists: the
  datasheet publishes no thermal resistance, no case-temperature limit and no dissipation
  figure, so one must not be invented. **Ambient above +70 °C** is outside the module's rated
  operating conditions (§1.3, §3.1) — stop, improve bay ventilation, re-run. **"Still rising" is
  an inconclusive result, not a fault**, and nothing may be changed merely to make it stop
  rising.
- **Any connect — DR2-11 RULED 2026-09-06:** continuous PSU constant-current operation lasting
  more than **500 ms** after connection = STOP. Also: smell / abnormal heat / smoke /
  unexpected sound / visual anomaly = **IMMEDIATE STOP**. Brief inrush alone does not
  authorize raising current. A CC trip **never automatically advances the staircase** —
  diagnose and justify before increasing the limit. Record the actual observed CC duration at
  every connect.

## Rollback

- **Power down at the master switch / XT60 split** — that is the designed rollback, and the reason
  precondition 4 exists (PB:31-32).
- **B1.4 fails** → actuators stay disconnected; the fix is firmware timing or the PD1 pull-downs
  (whose expected A2-time state was *not populated*, A2:362-366). Fitting them later invalidates no
  A2 row but moves 13/14 into A2 §3 rule 2's exceptions list.
- **B2 fails** → Phase B stops here. Do not proceed to B3, and under no circumstance to Phase C
  (motor power). Nothing in this card authorises connecting the ESC's motor leads (PB:130-134).
- **B3.3 fails** → do not proceed to B4 with a link2 mismatch unresolved; run BG-05's checks, then
  re-flash both boards in order.
- **Firmware rollback** is re-flashing a known-good image; there is no other undo, and NVS may need
  `reset` + `save` (`COORDINATED_FLASH.md`:153-159).
- **A calibration was lost** (a version bump discarded the blob): redo D8 Phase 11a steps 1–6; the
  loader never produces a partial mix, so the car is never half-tuned (`COORDINATED_FLASH.md`:113-118).

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-03/<UTC-stamp>/
  meta.txt                       # host, dates, repo HEADs — the code each row was measured against
  MANIFEST.txt
  console.log / console.raw      # timestamped serial capture (bench_capture.sh)
  scope/B1.3_gpio13.png  scope/B1.3_gpio14.png  scope/B1.3_gpio18.png
  scope/B1.4_boot_float_gpio13_gpio14.png
  rp1_tap.bin                    # raw CRSF bytes from the passive tap (BG-06 tooling)
  rp1_tap_summary.json           # crsf_sniff.py --summary output
  B2_safety_chain.md             # each row, observed result, timestamps from console.log
  B2.4_latency.md                # measured detection latency + the packet rate used
  B3_actuators.md                # per-actuator results, reconnect order as executed
  B4.3_battery_plausibility.md   # mV produced by each fault, vs the 4000-9000 mV band
  B4.4_hall_rates.md             # entries/100 ms plain and pull-up-lifted, guardFaults()
  cc_duration_log.md             # DR2-11: observed CC duration at every connect, vs the 500 ms STOP
  S4_S5_load_states.md           # what the amp and the Wi-Fi module were actually doing at each reading
  S5_wifi_thermal.md             # DR2-14/DR3-1 S5 thermal-soak characterisation: load state + time
                                 # at 0/5/10/15/20/30 min, streaming in the shipped mode. NOT run
                                 # inside the S0-S9 staircase (streaming is CB5-gated) - it runs at
                                 # the first camera bring-up session, S5 load state and S5 PSU limit
                                 # unchanged; INCOMPLETE until then, never PASS, never a fault. From
                                 # the staircase's own S5 substep record instead: load state as
                                 # actually reached, time, sensory observation. If an instrument
                                 # exists (DR3-3): instrument + spot, ambient/surface per sample, and
                                 # whether it had stopped rising (lower bound if not); if none,
                                 # sensory observation only
  deviations.md
```

## Downstream unlocked by PASS

- **D8 Phases 7 onward** — but Phase 7 is **motor connected**, which is **Phase C**, and is gated
  on B2 having passed in full (PB:130-134). Passing BG-03 does not itself authorise motor power;
  it removes the *only* thing that was blocking the owner from considering it.
- **BG-04** (the rest of D8's bench bring-up) and **BG-05** (coordinated flash) become runnable.
- **BG-07 (BT1)** becomes *eligible* — it additionally needs the owner to open BT1 explicitly
  (`BT1_BENCH_GATE.md`:3-11).
- D8 Phase 8's full-throttle half of OD-11, and Phase 8's battery two-point calibration, inherit
  B4.3/B4.4's baselines.

## BENCH-TBD residue

- **B4.3 and B4.4 are the two rows whose numbers nothing has measured yet** — the firmware's
  plausibility band and interrupt-rate bound are derived from circuit reasoning and native tests
  only. What is recorded here is the **first real evidence either way** (PB:119-122).
- **`bootArmHoldMs = 2000` has never been reconciled against the QuicRun 10BL120's own manual**
  (B2.3) — that reconciliation is bench work, not a document fact.
- **`save`-during-run behaviour is unmeasured**: the NVS commit runs inline on the control tick and
  the CRSF UART ISR was never confirmed IRAM-resident, so RX may go deaf for the write; a dropped
  frame around `saved` is expected, a failsafe blip is the *safe* direction. **Nothing has measured
  this** — D8:89-97 is the only place the observation gets made.
- **The full-throttle Hall/EMI half of OD-11 is D8 Phase 8**, `[bench-TBD]`, and needs motor power.
- **Car-side 5 V current figures now exist for four parts, and for no more than that** — see
  `bench-gates/tools/first_power_current_limits.md`, rows **L11–L15** (Wi-Fi module,
  steering servo, amplifier, LED strip) and the **13 T-rows, none of which has a settable
  number**: T1–T10 are **THRESHOLD MISSING** and T11–T13 are **BLOCKED with reasons**.
  (Ground-side 5 V loads are documented — `w17-gcs-box-guide.md:135-139`.) **The staircase
  POLICY itself is RULED (2026-09-05, D-4 O-6)** — see Required equipment, above. The
  per-substep starting amperage was **derived offline (2026-09-06, v2 after review R-O6)** —
  see "Starting current limits (O-6 derivation, 2026-09-06)" above and
  `_handoff/2026-09-06_O6_derivation_report.md` — and **every substep remains BLOCKED**, now
  on the owner's consolidated photo/label packet (`W17_OWNER_PHOTO_LABEL_INTAKE.md`): bench PSU
  identity and minimum settable limit (DR2-3, packet item 1); UBEC make/model and BEC#2's set
  voltage (DR2-4, packet item 2); the S1/S2 ramp ceiling (DR2-6, packet item 3) and the S7/S8
  ramp ceiling (DR2-10, packet item 5). **DR2-5 (PSU-first / ESC separation) and DR2-11
  (constant-current duration criterion, RULED at 500 ms) are no longer open** — see Required
  equipment and "Starting current limits", above.
- The **ESC's own neutral/range calibration** is its manual's business, not the firmware's
  (D8:215-216).

## Evidence label at card creation

**NOT-EXECUTED.** Phase B is BLOCKED; A2 is NOT-EXECUTED; nothing has been powered or flashed
(PB:3-10; `W17_CURRENT_STATE.md` §6). Every number in this card is a *target* transcribed from the
runbooks, never a measurement.
