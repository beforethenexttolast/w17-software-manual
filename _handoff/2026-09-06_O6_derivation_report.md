# O-6 derivation — starting current limits for the first-power staircase

**Model: Claude Opus** · Worker report, offline desk work, 2026-09-06.
**Evidence label: NOT-EXECUTED.** Nothing was powered, flashed or measured. Every repository was
read-only; nothing was edited, committed or pushed. This file is the only output.

**Serves:** owner ruling D-4 / **O-6** (2026-09-05), recorded verbatim at
`WP/2026-09-05_offline_decision_round_1.md`:19-23 and `WP/bench-gates/MISSING_THRESHOLDS.md`:35.

---

## 1. Verdict

**Fourteen powered substeps were examined (eleven in BG-03's staircase, three in BG-04 / D8
Phase 1). ZERO can be given a settable starting amperage offline. All fourteen are BLOCKED** —
but not all for the same reason, and the block is much narrower than "no numbers exist". Five
substeps now carry a **fully derived load increment or never-exceed ceiling** that did not exist
before this pass: the WS2812 strip (**560 mA** at the O-7 cap of 180, from the shipped code
model), the BL-M8812EU2 Wi-Fi module (**1800 mA max**, manufacturer datasheet — the largest
single car-side 5 V load in the project and previously undocumented), the MAX98357A
(**3.35 mA** quiescent max, **2.8 A** internal current limit), and the DS3235SG (**5 mA** idle,
**1.9 A** stall, both at 5 V, from the manufacturer datasheet). What blocks every *absolute*
limit is structural, not a missing lookup: (a) **no document names the bench PSU**, so its
minimum settable constant-current value — the literal first number the staircase asks for — is
unknown, and it is not even established that the supply has a settable limit; (b) **the supply
sits on the pack side (7.4 V) while every derivable load figure is a 5 V rail current**, and
converting between them needs the UBEC's efficiency, which cannot be known because **no document
names the UBEC's make or model** — only "UBEC 5 A (2 pcs)"; and (c) the **first** rail-A load in
the staircase order is the pair of MH-ET LIVE D1-mini ESP32 boards, an AliExpress store-brand
product with no manufacturer datasheet, so every later rail-A substep inherits an unquantified
term. Two owner answers (§5 Q1 and Q2) convert the whole staircase from "blocked" to
"self-bootstrapping", because from S1 onward each substep's limit can chain onto a reading taken
minutes earlier in the same session. **I refused four family-level figures that were readily
available and would have looked authoritative** (§7). One of them — a search engine's "DS3235SG
stall current 3.9 A" — is **wrong**: the manufacturer's own datasheet says **1.9 A at 5 V**.

---

## 2. Part identities

Identity is taken **only** from this project's documents. `[WP]` = the workspace program worktree
`/private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/1eb1e581-426a-4cb0-abab-7295687107d4/scratchpad/wt-ws-program`;
`[fw]` = `/Users/vitaliykhomenko/Documents/projects/w17-control-fw`;
`[sl]` = `/Users/vitaliykhomenko/Documents/projects/w17-soundlight-fw`.
All datasheet retrievals: **2026-09-06**.

| Part (staircase role) | Exact model **as the project's docs name it** | path:line | Manufacturer datasheet found? |
|---|---|---|---|
| Bench PSU (S0 limit source) | **NOT NAMED ANYWHERE.** A2's tool list says only *"USB cable and bench PSU: **have them, do not connect them** — both are Phase B"*; the procurement sheet's status column reads *"unknown — no current-limit spec … is named in any gate doc"* | `[fw]/project-review/13_phase_a_a2_no_power_checklist.md`:116 ; `[WP]/W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`:82 | **none found — no model to look up** |
| UBEC A / UBEC B (rail sources) | **"UBEC 5 A (2 pcs)"** / BOM `UBEC 5 A  2PCS 5A`. No brand, no model. Type is doc-stated as **switching** (*"two switching UBEC outputs hard-paralleled"*) | `[WP]/HARDWARE_INVENTORY.md`:113 ; `[fw]/docs/bill_of_materials_v2.md`:77 ; `[fw]/project-review/13_phase_a_a2_no_power_checklist.md`:238 | **none found — no model to look up** |
| ESP32 #1 / #2 (S1) | **MH-ET Live D1-Mini ESP32 (USB-C)** / BOM: *"2× 'D1 Mini ESP32' / MH-ET Live MiniKit (ESP32-**WROOM-32**, ~39×31 mm, micro-USB)"*. ⚠ the two docs disagree on USB-C vs micro-USB | `[WP]/HARDWARE_INVENTORY.md`:96, :200 ; `[fw]/docs/bill_of_materials_v2.md`:66 | **none found.** MH-ET LIVE is a marketplace store brand; it publishes no datasheet. Espressif's ESP32-WROOM-32 datasheet covers the *module*, not this *board* (LDO + USB-UART bridge + power LED are outside it) → **not usable** |
| RP1 receiver (S2) | **RadioMaster RP1 ELRS receiver** ("rp1-v2 rx") | `[WP]/HARDWARE_INVENTORY.md`:83 ; `[fw]/docs/bill_of_materials_v2.md`:33 | **manufacturer page fetched — NO CURRENT FIGURE.** radiomasterrc.com/products/rp1-expresslrs-2-4ghz-nano-receiver lists *"Working voltage: 5v"*, MCU, RF chip, weight, dimensions and refresh rates, and no mA/A anywhere |
| WS2812B strip (S3) | **WS2812B addressable LED strip, `Black PCB / 1m / 30 LED / IP30`**. ⚠ inventory qualifies it: *"(addressable WS2812B type to eyeball at wiring)"* — the type is to be confirmed at build time | `[fw]/docs/bill_of_materials_v2.md`:73 ; `[WP]/HARDWARE_INVENTORY.md`:99 | **fetched (Worldsemi WS2812B V1.0, Jan 2016) — contains NO supply-current figure.** Its Electrical Characteristics table gives only *"Input current II  VI=VDD/VSS … ±1 µA"*. The current model therefore comes from the firmware, not the datasheet |
| MAX98357A + speaker (S4) | **MAX98357A I2S amplifier** (owner-confirmed 2026-07-22); speaker **4 Ω 3 W** (*"impedance/power a bench spec-check"* — i.e. unverified) | `[WP]/HARDWARE_INVENTORY.md`:97, :98 ; `[fw]/docs/bill_of_materials_v2.md`:69, :71 | **YES** — Maxim Integrated, *MAX98357A/MAX98357B PCM Input Class D Audio Power Amplifiers*, fetched from `https://cdn-shop.adafruit.com/product-files/3006/MAX98357A-MAX98357B.pdf` (Maxim-branded document; analog.com's own copy timed out twice) |
| Camera (S5) | **Camera — OpenIPC SSC338Q (MC800S-V3, IMX335 sensor)**, owned + already flashed; fed *"5 V→VDD5.0 from clean BEC Rail A"* | `[WP]/HARDWARE_INVENTORY.md`:78 ; `[fw]/docs/bill_of_materials_v2.md`:30, :202 | **none found** for MC800S-V3 + IMX335 at 5 V. (Search surfaced only IMX415 variants quoted at 12 V — a different sensor and a different rail; **refused**) |
| Wi-Fi module (S5) | **BL-M8812EU2 USB WiFi module `High-Power`** — the camera's video-link radio | `[WP]/HARDWARE_INVENTORY.md`:74 ; `[fw]/docs/bill_of_materials_v2.md`:22 | **YES** — B-link (`b-link.net.cn`), *BL-M8812EU2 datasheet V1.0.1.0*, official release 2023-10-27, fetched from `https://jkrorwxhkqmllp5m-static.micyjz.com/BL-M8812EU2_datasheet_V1.0.1.0_231113-aidlrBpoKqpljSRnkmnkjqpjm.pdf?dp=GvUApKfKKUAU`; corroborated by the LB-LINK product page `https://www.lb-link.com/M8812EU2-2T2R-802-11a-n-ac-WiFi-Module-pd548696668.html` |
| Blower (S6) | **Blower fan 5 V 20 mm** / BOM: *"Blower fan 5 V 20 mm (**ACP2006-class**)"* — a **class**, not a part number | `[WP]/HARDWARE_INVENTORY.md`:170 ; `[fw]/docs/bill_of_materials_v2.md`:145 | **not attempted — identity is explicitly a class.** Looking one up would be the family guess the rule forbids |
| MG90S ×3 (S7, S8) | **MG90S micro servos (3 pcs)** / BOM: `MG90S micro servos  90-180° / 3PCS`. **No manufacturer named** | `[WP]/HARDWARE_INVENTORY.md`:122 ; `[fw]/docs/bill_of_materials_v2.md`:91 | **doubly negative.** Identity is generic, *and* TowerPro's own MG90S page (towerpro.com.tw/product/mg90s-3/, fetched) lists weight, dimensions, stall torque, speed, voltage, temperature, deadband, wire and plug — and **NO CURRENT FIGURE**. TowerPro's page itself warns of counterfeits, so even the brand cannot be assumed |
| Steering servo (S9) | **DSServo DS3235SG steering servo `180°`** (35 kg-class, 25T horn) | `[WP]/HARDWARE_INVENTORY.md`:121 ; `[fw]/docs/bill_of_materials_v2.md`:89 | **YES, with one caveat** — DS SERVO (Dongguan City Dsservo Technology Co., Ltd.) datasheet whose model line reads *"DS3235 / DS3235-180 / DS3235-270"*, fetched from `https://hajim.rochester.edu/me/sites/kelley/me240/DS3235-270_datasheet.pdf`. **Caveat:** the manufacturer's own download index (`https://www.dsservo.com/en/download.asp`) lists DS3225/DS3218/DS3115/RDS-series and **no DS3235 file at all**, and the fetched document's model line does **not** carry the "SG" suffix the project uses. The document is DS SERVO-branded and covers the 180° variant the BOM specifies |
| ESC (D8 Phase 1) | **Hobbywing QuicRun 10BL120 + Rocket 540 V3 sensored combo `17.5T`**, product number **HW30125002** | `[WP]/HARDWARE_INVENTORY.md`:90 ; `[fw]/docs/bill_of_materials_v2.md`:62 ; `[fw]/docs/00_BUILD_SHEET.md`:45 | **manufacturer page fetched** (`https://www.hobbywing.com/en/products/quicrun10bl120`): *"BEC Output: Switch Mode 6V/7.4V @4A"*, *"2-3S Lipo"*, *"120A/Peak Current 760A"* — and **NO STANDBY CURRENT FIGURE** |
| Master switch (D8 Phase 1 inrush) | **Amass XT90-S anti-spark**, arrived as a two-piece pigtail set; the anti-spark (resistor) half is the female, facing the pack | `[WP]/HARDWARE_INVENTORY.md`:203, :305 | **no manufacturer specification located** giving the pre-charge resistor value |
| Bench pack (D8 Phase 1) | **ZEEE 5200 mAh 2S LiPo — BENCH ONLY, not a car pack.** The only battery on hand; no in-envelope car pack exists | `[WP]/HARDWARE_INVENTORY.md`:208, :182 | n/a — and **its C-rating is nowhere in the docs**. The `≥25 C` figure at `HARDWARE_INVENTORY.md`:277 is the *sourcing spec for the unbought car pack*, not this pack |

### Topology facts that constrain every row below

- Rails: **A (clean)** = BL-M8812EU2 Wi-Fi, camera 5 V, ESP32 #1, ESP32 #2, RP1, WS2812 strip,
  MAX98357A, A3144 Hall VCC. **B (servos)** = DS3235SG, 3× MG90S, blower.
  (`[WP]/w17-pdb-build-and-connector-guide.md`:51-53; `[fw]/docs/D8_BENCH_BRINGUP.md`:47)
- **The ESC's +5 V BEC red wire is CUT and insulated** — signal + GND only. The ESC's 4 A BEC
  therefore feeds **nothing**; it is not a rail source and cannot be a rail limit.
  (`[WP]/w17-pdb-build-and-connector-guide.md`:80 *"sig, GND only (+5V BEC red CUT)"*;
  `[fw]/docs/bill_of_materials_v2.md`:195; `[fw]/docs/00_BUILD_SHEET.md`:32;
  `[fw]/docs/D8_BENCH_BRINGUP.md`:38)
- **The supply is on the pack side.** `BG-03`:55 draws it as
  `bench PSU / pack --[XT90-S master]-- PDB --+-- UBEC A --> Rail A`. Any PSU current limit is a
  **7.4 V-side** limit; every load figure derived below is a **5 V rail** current.
- Bulk capacitance that will draw inrush at each connect: **C1 1000 µF across Rail B** and
  **C2 1000 µF at the WS2812 strip input**
  (`[WP]/w17-pdb-build-and-connector-guide.md`:119-120; `[fw]/docs/00_BUILD_SHEET.md`:36).
- Pack-side resistive load present from S0 onward: the **27 kΩ / 10 kΩ** battery divider
  (`[fw]/docs/D8_BENCH_BRINGUP.md`:40).

---

## 3. The derivation

### 3.0 The margin, stated as a decision

> **Margin M-PEAK (proposed decision, not a fact).** For each load, take the **manufacturer's
> Max / peak column, never its Typ column**, and for the LED strip take the firmware model's
> **stated upper bound, never its actual draw**. Add **no further percentage**.
>
> **Rationale.** A percentage margin would be an invented number, which O-6 forbids. The
> typ→max gap is the manufacturer's own worst case and is itself cited, so using it *is* the
> margin and it carries a source. Where a load has no cited figure at all, no margin can rescue
> the row — the substep is BLOCKED, and that is the correct outcome rather than a smaller-looking
> one. Inrush is deliberately **not** covered by M-PEAK: C1/C2 charging will momentarily engage
> constant-current at every connect. That is expected and is **not** the fault the stop condition
> describes — the existing wording is *"the supply **sits** in constant-current"*
> (`[WP]/bench-gates/tools/first_power_current_limits.md`:119), and "momentarily enters, then
> leaves" is the healthy signature.

### 3.1 The chaining rule (what makes the staircase self-bootstrapping)

The supply's limit applies to **everything present**, not to the load just added. So:

```
  L(N)  =  R(N-1)  +  P(N)
```

where **R(N−1)** is the *settled total recorded minutes earlier in the same session* after
substep N−1, and **P(N)** is the cited peak of the load added at substep N. Only **L(0)** and
**L(1)** need a number that no measurement can supply. P(N) is what this pass could derive
offline; R(N−1) is what the staircase itself creates. Consequently the table below reports
**P(N) as DERIVED or BLOCKED**, and reports **L(N) as BLOCKED for every N** — because L(N)
additionally needs the pack-side conversion (Q2) and, from S1 on, the ESP32 board term.

### 3.2 BG-03 staircase (order per `tools/first_power_current_limits.md`:106-107)

Every row is **NOT-EXECUTED**. `[code]` = compile-time constant/model in this project.
`[doc]` = rating already cited in this project with a path:line. `[datasheet]` = manufacturer
document fetched 2026-09-06, quoted.

| # | Substep | Loads present (Rail A / Rail B / batt+) | Admissible cited figure(s) for the load being **added** | **P(N)** — added-load allowance under M-PEAK | Absolute starting limit **L(N)** | NEVER-EXCEED ceiling | Status |
|---|---|---|---|---|---|---|---|
| **S0** | Bench PSU + PDB alone, nothing on the rails | A: — · B: — · batt+: 2× UBEC input, 27k/10k divider, **and the ESC unless its 12 AWG feed is separated** | Divider: **27 kΩ + 10 kΩ = 37 kΩ** `[doc `D8`:40]` → at 7.4 V, **0.20 mA**; at 8.4 V, **0.23 mA** (Ohm's law on cited resistors). UBEC quiescent: **none — no model**. ESC standby: **none — Hobbywing publishes no standby figure** | **BLOCKED** — divider term derived, UBEC and ESC terms absent | **BLOCKED.** The staircase's own answer is *"the lowest setting the supply offers"* (`first_power_current_limits.md`:100-102), which is a **procedure that still needs the PSU's minimum settable CC value** — and no document names the PSU | PSU's own limits — **unknown**. XT60/XT90/12 AWG are not the binding limit | **BLOCKED** → Q1, Q3 |
| **S1** | + Rail A: ESP32 #1 and #2, idle | A: 2× MH-ET D1-mini · B: — · batt+: as S0 | **NONE.** MH-ET LIVE publishes no datasheet. The Espressif ESP32-WROOM-32 datasheet covers the module, not the board's LDO / USB-UART bridge / power LED — **refused as a family figure** | **BLOCKED** | **BLOCKED** (and this block propagates to S2–S5 and S9, all of which keep the boards powered) | Rail A **5 A** `[doc `HARDWARE_INVENTORY.md`:113]` | **BLOCKED** → Q4 |
| **S2** | + RP1 receiver | A: + RP1 · B: — | **NONE.** RadioMaster's own product page lists working voltage 5 V and no current figure at all (fetched 2026-09-06) | **BLOCKED** | **BLOCKED** (inherits S1) | Rail A **5 A** `[doc :113]` | **BLOCKED** → Q4 |
| **S3a** | + WS2812 strip, **at the O-7 operating cap 180** | A: + 30-pixel strip (+ C2 1000 µF) · B: — | `kNumPixels = 30` `[code `[sl]/lib/lights/include/lights/LightRenderer.hpp`:11]`; model `perLedMa = (2·20·renderedDuty(255, cap))/255` `[code :226]`; γ-LUT `[code :90-102, :110-111]`. Worldsemi's datasheet supplies **nothing** here | **DERIVED = 560 mA** (un-truncated model upper bound; the code's integer form gives **540 mA**). Arithmetic in §4 | **BLOCKED** (inherits S1/S2) | Compile budget **900 mA** `[code :209, checked :242]`; rail ceiling **5 A** `[doc :113]` | **P(N) DERIVED**, L(N) **BLOCKED** |
| **S3b** | + WS2812 strip, **at the shipped value** | as S3a | Shipped `maxBrightness = **110**` **verified in code** `[code :152]` — this matches the handoff's claim | **DERIVED = 188 mA** (un-truncated; code integer form **180 mA**, which is exactly row L5 of the existing table) | **BLOCKED** (inherits S1/S2) | as S3a | **P(N) DERIVED**, L(N) **BLOCKED** |
| **S4** | + MAX98357A amp (+ speaker) | A: + amp + 4 Ω speaker · B: — | `[datasheet]` Maxim MAX98357A/B: *"Quiescent Current IDD … TA = +25°C … 2.75 [typ] 3.35 [max] mA"*; *"Standby Current ISTNDBY  SD_MODE = 1.8V, no BCLK, TA = +25°C  340  400  µA"*; *"Shutdown Current ISHDN … 0.6  2  µA"*; *"Output Power … ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB … 3.2 [W]"*; *"Efficiency ε  ZSPK = **8Ω** + 68µH, THD+N = 10%, f = 1kHz, gain = 12dB  92 %"*; *"Current Limit ILIM  2.8 A"* | **PARTIAL.** Quiescent **DERIVED = 3.35 mA**. **Output-driven draw BLOCKED**: the shipped `sound.volume` is not yet recorded (it is created at D8 Phase 11a, `[fw]/docs/D8_BENCH_BRINGUP.md`:301-383; the link2 wire default is `kDefaultVolume = 80` `[code `[sl]/lib/link2/include/link2/Link2Frame.hpp`:93]`, which is a protocol default, **not** the shipped tune), and the only cited efficiency is at **8 Ω**, not the 4 Ω speaker the BOM specifies — extrapolating it would be an invention | **BLOCKED** | Amp's own **ILIM = 2.8 A** `[datasheet]`; rail **5 A** `[doc :113]` | **BLOCKED** → Q6 |
| **S5** | + camera / Wi-Fi module | A: + camera 5 V + BL-M8812EU2 · B: — | `[datasheet]` B-link BL-M8812EU2 V1.0.1.0, §1.3: *"Power Supply  DC 5.0V±0.25V @1800mA (Max)"*; §3.3 Current Consumption (VDD5.0 = DC 5.0 V, Ta 25 °C), Typ (IRMS) / Max (IPeak): *"WLAN Unassociated … 113 / 123 mA"*; *"WLAN TX/RX TCP throughput 300Mbps … 732 / 928 mA"*; *"HT20 MCS8 TX @ 27.5 dBm (2TX RF test) … 927 / **1510** mA"*. **Camera: no figure** | **PARTIAL.** Wi-Fi module **DERIVED = 1800 mA** (manufacturer's own headline max; the worst single measured row is 1510 mA peak, so 1800 mA is the conservative choice under M-PEAK). **Camera BLOCKED** | **BLOCKED** | Rail A **5 A** `[doc :113]` | **BLOCKED** → Q5 |
| **S6** | + Rail B blower (always-on) | A: as S5 · B: + blower (+ C1 1000 µF) | **NONE.** The BOM names an *"ACP2006-**class**"* part, not a part number | **BLOCKED** | **BLOCKED** | Rail B **5 A** `[doc :113]` | **BLOCKED** → Q7 |
| **S7** | + one MG90S | B: + 1 servo | **NONE.** Generic MG90S; and TowerPro's own page publishes no current figure | **BLOCKED** | **BLOCKED** | Rail B **5 A** `[doc :113]` | **BLOCKED** → Q8 |
| **S8** | + remaining two MG90S | B: + 2 servos | **NONE** (as S7) | **BLOCKED** | **BLOCKED** | Rail B **5 A** `[doc :113]` | **BLOCKED** → Q8 |
| **S9a** | + DS3235SG, **holding centre, no load** (**T3**) | B: + steering servo | `[datasheet]` DS SERVO *"DS3235 / DS3235-180 / DS3235-270"*, §4 Electrical Specification, at **Operating Voltage 5 V**: *"3-1 Idle current (at stopped) … **5mA**"*; §1-3 *"Operating Voltage Range 5-7.4V"* | **DERIVED = 5 mA** at 5 V (subject to the "SG"-suffix caveat in §2 and §7) | **BLOCKED** | Servo **stall 1.9 A at 5 V** `[datasheet]`; rail **5 A** `[doc :113]` | **P(N) DERIVED**, L(N) **BLOCKED** |
| **S9b** | + DS3235SG, **deliberate full-lock sweep, linkage OFF** (**T4**) | B: as S9a | `[datasheet]` *"3-4 Stall current (at locked)"*: **1.9A** @ 5 V, 2.1 A @ 6 V, 2.3 A @ 7.4 V. **The datasheet gives no running / no-load current** — only idle-at-stopped and stall | **BLOCKED for the expected draw** (a linkage-off sweep is neither idle nor stall, and no cited figure covers it). **Ceiling DERIVED = 1.9 A** | **BLOCKED** | **1.9 A at 5 V** — this is the number C1 exists for (`00_BUILD_SHEET.md`:36, PDB guide:119); rail **5 A** `[doc :113]` | **ceiling DERIVED**, expected draw **BLOCKED** |

### 3.3 BG-04 / D8 Phase 1 — the substeps that precede or differ from BG-03's

D8 Phase 1 is *"the first battery connection of this bring-up"* (`[fw]/docs/D8_BENCH_BRINGUP.md`:51-57).
It differs from BG-03's staircase in one decisive way: **it is written around the battery, and a
battery has no settable current limit at all.**

| # | Substep (D8 Phase 1) | What is present | Admissible figures | Starting limit | NEVER-EXCEED | Status |
|---|---|---|---|---|---|---|
| **D8-1a** | The moment the pack is mated at the XT90-S (**T13, inrush**) | Pack → XT90-S → PDB → ESC + UBEC A + UBEC B | **None.** No document states the ESC's input capacitance; no Amass specification for the XT90-S pre-charge resistor was located; the bench pack (ZEEE 5200, `HARDWARE_INVENTORY.md`:208) has **no C-rating in any document** — the `≥25 C` at `:277` is the sourcing spec for the *unbought car pack*, not this one | **BLOCKED — and there is no limiting device in the path.** A pack does not current-limit. The only thing bounding this event is the XT90-S's own pre-charge resistor, whose value is unstated | **Not derivable.** Honestly: the anti-spark part exists precisely *because* the inrush is large, and the documents let me bound it **not at all** — neither above nor below | **BLOCKED** → Q9 |
| **D8-1b** | ESC standby on batt+, motor leads off (**T12**) | ESC logic energised; motor disconnected | **None.** Hobbywing's own product page gives 120 A/760 A, 2-3S, *"BEC Output: Switch Mode 6V/7.4V @4A"* and **no standby figure** | **BLOCKED** | ESC BEC 4 A is **irrelevant** — the red wire is cut (`PDB guide`:80), so the BEC feeds nothing | **BLOCKED** → Q3 |
| **D8-1c** | *"Confirm BEC#1 ≈ 5 V, BEC#2 ≈ 5–6 V **under a light load**, before connecting the ESP32s"* (`D8`:55) | Both UBECs, no ESP32s | **None.** *"a light load"* is undefined in every document, and no UBEC model exists to say what load makes its regulation valid | **BLOCKED** | Rail **5 A** each `[doc :113]` | **BLOCKED** → Q2 |

> **A doc conflict worth surfacing while it is cheap.** `BG-03`:40 permits *"A bench PSU **or** the
> battery via the XT60 split"*; `D8`:55 writes Phase 1 as battery-only. Choosing the PSU for the
> first energisation is the only option that has a current limit at all — see Q3.

---

## 4. The LED recompute at the O-7 cap of 180 — full arithmetic

**Inputs, all compile-time, all in `[sl]/lib/lights/include/lights/LightRenderer.hpp`:**

- `kNumPixels = 30` — `:11`
- shipped `maxBrightness = 110` — `:152` (**verified in code this session**; the handoff's "110" is correct)
- `kBudgetMilliamps = 900` — `:209`, enforced by `(perLedMa * kNumPixels) <= kBudgetMilliamps` at `:242`
- `renderedDuty(ch, cap) = kGamma.v[ch·cap/255]` — `:110-111` (**cap applied before gamma**)
- `kGamma.v[i] = (int)(255·(i/255)^2.2 + 0.5)`, clamped 0..255 — `:90-102`
- model: `perLedMa = (2u * 20u * renderedDuty(255, maxBrightness)) / 255u` — `:226` (**integer** division)
- hazard colour `kAmber{255, 90, 0}` — `[sl]/lib/lights/src/LightRenderer.cpp`:21

**Method note.** I did not do this by hand. I copied the header's own `gamma_detail` block
(`:40-105`) verbatim into a standalone C++17 program in the session scratchpad and compiled it, so
the LUT below is the project's own constexpr pipeline, not a re-implementation of it.

**At the ruled operating cap 180 (O-7):**

```
  index      = 255 · 180 / 255                     = 180
  (180/255)                                        = 0.70588235
  0.70588235 ^ 2.2                                 = 0.4647424
  255 · 0.4647424                                  = 118.509
  kGamma[180] = (int)(118.509 + 0.5)               = 119        <- renderedDuty(255, 180)

  perLedMa    = (2 · 20 · 119) / 255 = 4760/255 = 18.667 -> 18   (integer division, as in code)
  strip       = 18 mA x 30 px                      = 540 mA      <- the code's modelled worst case
  strip (un-truncated)  = 18.667 mA x 30           = 560.0 mA    <- the honest real-number bound

  valid() check: 540 <= 900  ->  PASSES
```

**At the shipped value 110 (verified `:152`):**

```
  kGamma[110] = 40   (= renderedDuty(255,110), and the comment at :119 says exactly this)
  perLedMa    = (2 · 20 · 40)/255 = 1600/255 = 6.275 -> 6
  strip       = 6 mA x 30 = 180 mA        <- reproduces row L5 exactly
  strip (un-truncated) = 6.275 x 30 = 188.2 mA
```

**Actual all-amber hazard draw (not the model — the palette's real worst state):**

| cap | duties R/G/B for `kAmber{255,90,0}` | actual mA/LED = 20·(R+G+B)/255 | × 30 px |
|---|---|---|---|
| **110 (shipped)** | 40 / 4 / 0 | 3.451 | **103.5 mA** — reproduces row L6's *"≈ 104 mA"* |
| **180 (O-7)** | 119 / 12 / 0 | 10.275 | **308.2 mA** |
| 227 (compile ceiling) | 197 / 20 / 0 | 17.020 | 510.6 mA — reproduces the code comment's *"510 mA"* at `:220-222` |

**Cost of the O-7 ruling, stated plainly:** raising the cap 110 → 180 costs **+360 mA** on the
model (180 → 540 mA) and **+205 mA** on the real all-amber state (103.5 → 308.2 mA), on Rail A.
`BG-08`:217-224 already tabulates 180 → 540 mA; this pass reproduces it independently and adds
the actual-draw column, which BG-08 does not have.

**What that does to Rail A's budget — floor, not total.** Summing **only** the loads that now have
an admissible figure:

```
  BL-M8812EU2   1800 mA  [datasheet, manufacturer headline max]
  WS2812 @ 180   560 mA  [code model, un-truncated upper bound]
  MAX98357A        3 mA  [datasheet, IDD max 3.35 mA]
  -----------------------
                2363 mA  =  ~47 % of UBEC A's 5 A rating
```

with **ESP32 #1, ESP32 #2, RP1, the camera and the A3144 Hall still unquantified**. This is a
**floor on the rail total, not the rail total**. It is the first time this project has had any
number at all for Rail A, and it says the headroom is real but not generous — which is exactly
the *"check the **UBEC headroom** before raising the cap"* instruction at `BG-08`:110 and
`[sl]/docs/SIMULATION.md`:49-53, now with one side of the comparison filled in.

---

## 5. Owner questions — smallest and cheapest first

Each is one sentence and names what it unblocks. **Q1 and Q2 are the two that convert the whole
staircase from blocked to runnable**; everything after them narrows individual rows.

1. **Q1 — Which bench power supply do you have, and what is the smallest current limit it can be
   set to (and does it have a settable limit at all)?** *Unblocks: S0, and with it the first
   number the entire staircase asks for; no document anywhere names the PSU.*
2. **Q2 — Which UBEC is it (make/model, or a photo of the label)?** *Unblocks: the pack-side ↔
   rail-side conversion that every one of S1–S9 needs, plus D8-1c's undefined "light load";
   without an efficiency figure a 5 V rail draw cannot be turned into a 7.4 V supply limit.*
3. **Q3 — For the first energisation, do you accept using the bench PSU rather than the battery
   (BG-03:40 already permits it, D8:55 says battery), and can the ESC's 12 AWG feed be physically
   separated at the PDB so it is absent for S0–S9?** *Unblocks: S0 (removes the unquantified ESC
   standby term), D8-1a and D8-1b (a supply has a limit; a pack does not).*
4. **Q4 — Do you accept that S1 and S2 are characterised rather than pre-limited, i.e. the boards
   and the RP1 are brought up at the supply's minimum settable limit and the limit raised in the
   supply's smallest increments until it leaves constant-current, that reading becoming T9/T8?**
   *Unblocks: S1 and S2, the only two rows where no datasheet will ever exist (MH-ET publishes
   none; RadioMaster publishes no current figure) — and it is the ruling's own "increase only
   after the trip is understood" applied to a first measurement rather than a fault.*
5. **Q5 — At what RF power / mode will the BL-M8812EU2 actually run on the car, so the right row
   of its datasheet applies (unassociated 123 mA peak, TX/RX 300 Mbps 928 mA peak, or 2TX
   1510 mA peak / 1800 mA headline max)?** *Unblocks: S5's Wi-Fi term, and tells you whether
   Rail A is comfortable or tight.*
6. **Q6 — What `sound.volume` will ship, and is the speaker confirmed 4 Ω (the inventory calls
   its impedance "a bench spec-check")?** *Unblocks: S4's output-driven term; the quiescent
   3.35 mA is already derived.*
7. **Q7 — What is the blower's actual part number (a photo of the fan label)?** *Unblocks: S6 —
   the BOM only names an "ACP2006-class" part, which is a class, not a part.*
8. **Q8 — Are the MG90S servos a branded part with a label, and if not, do you accept that S7/S8
   are characterised the same way as Q4?** *Unblocks: S7 and S8 — TowerPro's own page publishes
   no current figure, so even a genuine part would not close this.*
9. **Q9 — Do you accept that inrush (T13) is bounded by nothing we can cite, and that the
   mitigation is procedural (mate the XT90-S deliberately and fully, observe, and treat any spark
   or heat as a stop) rather than numeric?** *Unblocks: D8-1a — as a documented acceptance, not
   as a number.*
10. **Q10 — Confirm the steering servo's exact marking on the case (DS3235 / DS3235-180 /
    DS3235SG)?** *Unblocks: removes the one caveat on S9's otherwise-clean datasheet figures —
    DS Servo's own download index has no DS3235 file, and the document that exists does not carry
    the "SG" suffix your BOM uses.*

---

## 6. Proposed verbatim text

### 6.1 New subsection for `bench-gates/BG-03_phase_b_first_power.md`

*Suggested placement: immediately after "Required equipment", before "Topology (ASCII)".*

```markdown
## Starting current limits (O-6 derivation, 2026-09-06)

**Evidence label: NOT-EXECUTED.** Nothing below has been measured. O-6 (owner, 2026-09-05)
ratified the staircase policy and forbade inventing an initial amperage; this subsection is
the offline derivation that ruling required, and it ends in BLOCKED rows on purpose.

**The policy, in force:** lowest defensible limit for the substep · a current-limit trip is
**STOP AND DIAGNOSE** · never simply increase until it works · increase only after the trip
is understood and the next setting is justified · never exceed the applicable rail/component
limit.

**The margin, named:** *M-PEAK* — take each load's manufacturer **Max/peak** figure (never
Typ) and the LED model's **stated upper bound** (never its actual draw); add no percentage.
A percentage would be an invented number; the typ→max gap is the manufacturer's own worst
case and it carries a citation. **M-PEAK does not cover inrush**: C1 and C2 will momentarily
pull the supply into constant-current at each connect, and the stop condition is deliberately
worded "the supply **sits** in constant-current" — momentarily entering and then leaving is
the healthy signature, not the fault.

**The chaining rule:** the limit applies to everything present, so
`L(N) = R(N-1) + P(N)`, where `R(N-1)` is the settled total recorded minutes earlier in this
same session and `P(N)` is the cited peak of the load being added. Only L(0) and L(1) need a
number no measurement can supply.

**Two facts that block every absolute value, and are not lookups:**
1. **No document names the bench PSU** (A2:116 says only "have them, do not connect them"),
   so its minimum settable constant-current value — the literal first number step 1 asks for
   — is unknown, and it is not established that it has a settable limit at all.
2. **The supply is on the pack side (7.4 V) and every derived load figure is a 5 V rail
   current** (this card's own topology, :55). Converting between them needs the UBEC's
   efficiency, and **no document names the UBEC's make or model** — only "UBEC 5 A (2 pcs)"
   (`HARDWARE_INVENTORY.md`:113).

| Substep | Added-load allowance P(N) | Absolute limit L(N) | Never-exceed | Status |
|---|---|---|---|---|
| S0 PDB alone | divider 37 kΩ → **0.20 mA @7.4 V** derived; UBEC quiescent and ESC standby absent | — | PSU's own limits (unknown) | **BLOCKED** — needs the PSU's minimum settable limit |
| S1 + ESP32 #1/#2 idle | — | — | Rail A **5 A** | **BLOCKED** — MH-ET LIVE publishes no datasheet; the WROOM-32 module datasheet is not the board |
| S2 + RP1 | — | — | Rail A **5 A** | **BLOCKED** — RadioMaster's own page gives 5 V and no current figure |
| S3 + WS2812 strip @ cap **180** | **560 mA** (model upper bound; code's integer form 540 mA) | — | budget **900 mA**; Rail A **5 A** | **P(N) DERIVED**, L(N) **BLOCKED** |
| S3 + WS2812 strip @ shipped **110** | **188 mA** (code's integer form 180 mA) | — | as above | **P(N) DERIVED**, L(N) **BLOCKED** |
| S4 + MAX98357A + speaker | quiescent **3.35 mA max** derived; output-driven term absent | — | amp **ILIM 2.8 A**; Rail A **5 A** | **BLOCKED** — shipped `sound.volume` unrecorded; the only cited efficiency is at 8 Ω, not the 4 Ω speaker |
| S5 + camera / Wi-Fi | Wi-Fi **1800 mA max** derived; camera term absent | — | Rail A **5 A** | **BLOCKED** — no figure for the OpenIPC SSC338Q at 5 V |
| S6 + blower | — | — | Rail B **5 A** | **BLOCKED** — the BOM names an "ACP2006-class" part, not a part number |
| S7 + one MG90S | — | — | Rail B **5 A** | **BLOCKED** — generic part, and TowerPro's own page publishes no current figure |
| S8 + remaining MG90S | — | — | Rail B **5 A** | **BLOCKED** — as S7 |
| S9 DS3235SG holding centre (T3) | **5 mA @5 V** (datasheet idle-at-stopped) | — | servo **stall 1.9 A @5 V**; Rail B **5 A** | **P(N) DERIVED**, L(N) **BLOCKED** |
| S9 DS3235SG full-lock sweep (T4) | — (no running-current figure exists; the datasheet gives only idle and stall) | — | **1.9 A @5 V** — the number C1 exists for | **ceiling DERIVED**, expected draw **BLOCKED** |

**Cited figures used above, with sources (all retrieved 2026-09-06):**

- WS2812 strip: `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11 (`kNumPixels`
  = 30), :110-111 (`renderedDuty`), :152 (shipped `maxBrightness` = 110), :209
  (`kBudgetMilliamps` = 900), :226 (`perLedMa`), :242 (the check). At cap 180,
  `renderedDuty(255,180)` = 119 and the model gives 540 mA (integer) / 560 mA (un-truncated).
- MAX98357A: Maxim Integrated *MAX98357A/MAX98357B* datasheet, Electrical Characteristics —
  "Quiescent Current IDD … 2.75 [typ] 3.35 [max] mA", "Current Limit ILIM 2.8 A", "Output
  Power … ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB … 3.2 W", "Efficiency ε … ZSPK = 8Ω +
  68µH … 92 %".
- BL-M8812EU2: B-link *BL-M8812EU2 datasheet V1.0.1.0* (official release 2023-10-27), §1.3
  "Power Supply DC 5.0V±0.25V @1800mA (Max)"; §3.3 "WLAN Unassociated 113/123 mA", "WLAN TX/RX
  TCP throughput 300Mbps 732/928 mA", "HT20 MCS8 TX @ 27.5 dBm (2TX RF test) 927/1510 mA".
- DS3235SG: DS SERVO datasheet, model line "DS3235 / DS3235-180 / DS3235-270", §4 Electrical
  Specification — "Idle current (at stopped) 5mA" and "Stall current (at locked) 1.9A" at
  5 V; "Operating Voltage Range 5-7.4V". **Caveat:** DS Servo's own download index lists no
  DS3235 file, and this document does not carry the "SG" suffix the BOM uses.
- Rail ratings: `HARDWARE_INVENTORY.md`:113 ("UBEC 5 A (2 pcs)").
- The ESC's BEC is **not** a rail source and imposes no rail limit — its red +5 V wire is cut
  (`w17-pdb-build-and-connector-guide.md`:80; `bill_of_materials_v2.md`:195;
  `00_BUILD_SHEET.md`:32).

**Explicitly NOT used, and why:** a general-knowledge "typical ESP32 draws ~X"; a third-party
"80 mA" figure for the MH-ET board; a third-party "MG90S stall 400 mA"; a search result
claiming the DS3235SG stalls at 3.9 A — the manufacturer's own datasheet says **1.9 A at 5 V**,
which is why family figures are refused rather than merely discounted.

**Owner decisions this subsection is waiting on:** the bench PSU's identity and minimum
settable limit; the UBEC's make/model; whether the first energisation uses the PSU rather
than the pack and whether the ESC feed can be separated for S0–S9. See
`bench-gates/tools/first_power_current_limits.md` row T11.
```

### 6.2 Replacement row T11 for `bench-gates/tools/first_power_current_limits.md`

*Replaces, verbatim, line 91:*

```markdown
| T11 | The bench-PSU current limit to set at each step below | **BLOCKED — O-6 derivation done 2026-09-06; two owner decisions outstanding.** Policy ratified (O-6, 2026-09-05): lowest defensible limit per substep, trip = STOP AND DIAGNOSE, never raise to make a trip go away, never exceed the rail/component limit. Per-substep derivation is on **BG-03 § "Starting current limits (O-6 derivation, 2026-09-06)"**, with named margin **M-PEAK** and the chaining rule `L(N) = R(N-1) + P(N)`. **DERIVED added-load allowances:** WS2812 strip **560 mA** at the O-7 cap 180 / **188 mA** at the shipped cap 110 `[code LightRenderer.hpp:11,:110-111,:152,:209,:226]`; BL-M8812EU2 **1800 mA max** `[datasheet, B-link V1.0.1.0]`; MAX98357A quiescent **3.35 mA max**, ILIM **2.8 A** `[datasheet, Maxim]`; DS3235SG idle **5 mA** / stall **1.9 A** at 5 V `[datasheet, DS SERVO]`. **STILL BLOCKED, and no absolute limit is settable until both are answered:** (1) **no document names the bench PSU**, so its minimum settable CC value is unknown and a settable limit is not even established (`13_phase_a_a2_no_power_checklist.md`:116); (2) **the supply is on the pack side (7.4 V) and every derived figure is a 5 V rail current** (`BG-03`:55), and the conversion needs the UBEC's efficiency, which cannot be known because **no document names the UBEC's make or model** (`HARDWARE_INVENTORY.md`:113 gives only "UBEC 5 A (2 pcs)"). Do **not** fill this row from a family figure — a search-engine "DS3235SG stall 3.9 A" was checked against the manufacturer's own datasheet and is wrong by 2×. |
```

*And a corresponding one-line amendment for the T12/T13 rows, offered as verbatim replacements:*

```markdown
| T12 | ESC standby (logic-only) draw on batt+ with motor leads off | **BLOCKED — manufacturer publishes no standby figure.** Hobbywing's own QuicRun 10BL120 page (fetched 2026-09-06) gives "120A/Peak Current 760A", "2-3S Lipo" and "BEC Output: Switch Mode 6V/7.4V @4A" and no standby current. Note the 4 A BEC is **irrelevant to every rail** — its red wire is cut (`w17-pdb-build-and-connector-guide.md`:80). Cheapest resolution: separate the ESC's 12 AWG feed for the whole staircase so this term is absent until D8 Phase 1. |
| T13 | Inrush allowance at the moment the pack is connected | **BLOCKED — bounded by nothing citable, in either direction.** The XT90-S anti-spark exists because the inrush is large; no Amass specification giving its pre-charge resistor was located, no document states the ESC's input capacitance, and the bench pack (ZEEE 5200, `HARDWARE_INVENTORY.md`:208) has no C-rating in any document — the `≥25 C` at `:277` is the sourcing spec for the *unbought car pack*. A battery has **no** settable limit, so nothing in this path limits this event. Mitigation is procedural, not numeric: mate the XT90-S deliberately and fully, observe, and treat any spark, heat or tick as a stop. |
```

---

## 7. Limitations — what I could not get, and what I refused

**Could not fetch:**

- **analog.com's own copy** of the MAX98357A datasheet timed out twice (60 s), as did the ADI
  product page. I used the **Maxim-branded** PDF hosted at
  `cdn-shop.adafruit.com/product-files/3006/MAX98357A-MAX98357B.pdf` — the document itself is
  Maxim's ("Maxim Integrated" footer, *PCM Input Class D Audio Power Amplifiers*), the host is a
  mirror. If mirror-hosting is not acceptable, the MAX98357A figures should be re-fetched from
  analog.com before the row is used.
- The **DS SERVO** datasheet likewise came from a mirror (`hajim.rochester.edu`). The document is
  DS SERVO-branded and its model line reads "DS3235 / DS3235-180 / DS3235-270", but **the
  manufacturer's own download index lists no DS3235 file at all**, so there is no primary URL to
  offer. It is also the source of the one identity caveat below.
- **Bash had no outbound network** in this session (curl returned exit 92), and the machine has no
  `pdftoppm`/`pdftotext`/`mutool`/`gs`. Image-only and CID-font PDFs were read by rendering /
  extracting through the system `swift` + PDFKit in the scratchpad. Nothing was installed.

**Identity caveats I am carrying forward rather than papering over:**

- **DS3235**"**SG**": the project says DS3235SG; the manufacturer document says
  DS3235 / DS3235-180 / DS3235-270. If "SG" denotes a different electrical build, the 1.9 A
  ceiling could be non-conservative — hence owner question Q10.
- **WS2812B**: the inventory qualifies the strip as *"addressable WS2812B **type to eyeball at
  wiring**"*, i.e. the type is provisional. It does not matter for the numbers above, because the
  Worldsemi datasheet supplies **no** current figure and the model is entirely from this
  project's own code.
- **MH-ET board**: the inventory says USB-C, the BOM says micro-USB. Unresolved, and it hints the
  two documents describe different board revisions — another reason not to reach for any
  third-party board figure.

**Family-level figures that were available and that I REFUSED to use:**

1. **"DS3235SG stall current 3.9 A"** — a search-engine summary. The manufacturer's own datasheet
   says **1.9 A at 5 V / 2.1 A at 6 V / 2.3 A at 7.4 V**. Using the search figure would have
   overstated the servo ceiling by more than 2×. This is the concrete case for the rule.
2. **"MH-ET LIVE D1 mini ESP32 … 80 mA active"** — third-party board-catalogue site
   (`espboards.dev`), not a manufacturer document. MH-ET LIVE publishes nothing. Refused; S1 stays
   BLOCKED, which is the honest state.
3. **"MG90S … ~2.7 mA idle, ~70 mA no-load, ~400 mA stall"** — third-party reseller/aggregator
   figures. TowerPro's own MG90S page publishes **no current figure at all**, and the project's
   servos are unbranded AliExpress parts that TowerPro's own site warns are widely counterfeited.
   Refused; S7/S8 stay BLOCKED.
4. **"MC800S … 12 V @ 170 mA"** — an Alibaba listing for an **IMX415** variant. The project's
   camera is the **IMX335** MC800S-V3 fed at **5 V** from Rail A. Different sensor, different
   rail, third-party source. Refused; the camera term in S5 stays BLOCKED.
5. **An XT90-S pre-charge resistor value** — commonly repeated in hobby forums, published by
   Amass nowhere I could find. Refused; T13 stays unbounded, and I have said so rather than
   producing a comfortable-looking number.

**One thing I did not do:** I did not attempt the A3144 Hall sensor's supply current. It is on
Rail A but is not a substep in BG-03's staircase order, so it never becomes the added load in any
row above; it remains an unquantified term in the Rail-A floor in §4.

**Every table in this file is NOT-EXECUTED.** Nothing here authorises powering, flashing or
connecting anything, and Phase B remains BLOCKED on A2 by its own gate line (`BG-03`:7-9).
