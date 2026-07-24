# W17 Hardware Inventory & Delivery Log

Single **workspace-level** log of **physical hardware arrival** for the W17 build: what has
arrived, when, and how confidently each delivery maps to a Bill-of-Materials line. It records
*arrival evidence and mapping confidence only* — never gates, software status, or commit hashes.

_Last updated: 2026-07-25 (added the §E cassette-electrical rows ordered 2026-07-24, all ⏳; the
2026-07-22 correction pass + owner arrival/identity confirmations are unchanged)._

## What this file is (and is not) authoritative for

- **IS the single workspace-level log for:** *when* physical parts arrived (the dated delivery
  log) and *whether each delivery's mapping to a BOM line is confirmed*. On-hand /
  not-on-hand / ordered-in-transit / mapping-pending status for physical parts lives here.
- **Is NOT** a software, gate, or purchasing tracker, and carries **no commit hashes**.
  Project execution state, software/firmware status, hardware gates (A2 / Phase B), CI state,
  milestone summaries, and commit hashes stay in **`CURRENT_STATUS.md`**, which states it is
  *"the only workspace-level file that carries volatile state and commit hashes."* That file
  remains canonical for all of those; this file is its physical-parts carve-out (a matching
  pointer was added to `CURRENT_STATUS.md` so its statement stays literally correct now that
  this file exists). This file never asserts that a gate moved or that software state changed.
- **Buy-list source:** `w17-control-fw/docs/bill_of_materials_v2.md` (BOM v2) — a *saved-cart /
  buy-list* (its own header: *"verified against the saved AliExpress cart (40 lines parsed)"*).
  It establishes what each part *is* and *should* be bought; it is **not** evidence that any
  line was ordered, shipped, or is in transit — those states are recorded here only when a
  cited source (the owner, or `CURRENT_STATUS.md`) establishes them. Every row below cites its
  BOM section (§1–§13, B, D). If this file and the BOM disagree on what a part *is*, the BOM
  wins; this file only tracks *arrival + mapping confidence*.
- **Mechanical fit / measure / mount / install / envelope / validation status** (does it fit, is
  it installed, does it clear its envelope) is owned by the 3D/fabrication repo `w17-3d-codex`
  (Claude Code territory, but its own git repo): `w17-3d-codex/GENERAL_PLAN.md` item 5 and
  `w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md` (HAND / TRANSIT /
  CONFIRMED flags). This file records *"it physically arrived on date X and maps to BOM line Y"*;
  those record *"it has been measured / it mounts here."* **Those mechanical documents are not a
  second, independently maintained arrival ledger** — for *arrival* status this file is
  authoritative (a wording cleanup is still owed on the `w17-3d-codex` side; see "Cross-repository
  follow-up"). Edit those in their own repo — not as part of a workspace-doc change (one repo at
  a time).

## Legend — inventory state (arrival evidence only)

These marks describe **arrival evidence and mapping confidence only** — never a claim about
ordering unless a cited source (the owner, or `CURRENT_STATUS.md`) establishes it. "Not on hand"
is **not** a claim that a part was never ordered.

| Mark | Meaning |
|---|---|
| ✅ | **Confirmed on hand** — arrival recorded by an authoritative source (delivery log, `CURRENT_STATUS.md`, or an owner confirmation) *and* the BOM mapping is unambiguous |
| ❓ | **Arrived, BOM mapping pending confirmation** — physically arrived, but the owner's wording does not uniquely identify the BOM line (see "Mapping confirmations"). *No rows are ❓ as of 2026-07-22 — all closed by owner eyeball.* |
| ⬜ | **Not on hand** — no arrival recorded and not (recorded as) ordered. **Not** a claim it can never be obtained |
| 🏠 | **On hand from local stock / already owned** — not tracked as an AliExpress/rcMart delivery line |
| ⏳ | **Ordered / in transit / awaited, per a cited source** — the owner (2026-07-22) or `CURRENT_STATUS.md` explicitly says so; the citation is given in the row |

## Mapping-confidence rule (applied to every row)

Deliveries are recorded in the owner's own words. A delivery earns a **✅ confirmed** mapping
**only** where the delivery wording, its stated spec, an owner confirmation, or inspected evidence
**uniquely identifies exactly one BOM line**. Where more than one interpretation survives — a
generic label, an odd description, or two BOM lines it could satisfy — it is **❓ mapping-pending**
until a concrete check (model marking, frequency, dimensions, connector type, photo, packaging
label) closes it. Physical arrival never implies successful fit, installation, test, or gate
completion.

---

## On-hand status — by BOM section

### A. AliExpress order

**§1 Video / FPV**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| BL-M8812EU2 USB WiFi module | ×1 | ✅ | 2026-07-17 | camera's 5.8 GHz video-link radio (arrival per `CURRENT_STATUS.md` 07-17) |
| 5.8 GHz U.FL omni antennas (70 mm / 5 pcs) | ×1 | ✅ | 2026-07-21 | "wifi antennas" — **owner-confirmed** 5.8 GHz U.FL omni ~70 mm (2026-07-22); fit to J0/J1 before power |
| Heatsink 28×28×3 mm | ×1 | ✅ | 2026-07-21 | "cooling heatsink for wifi module" — maps to the single §1 heatsink line |
| FT232RL USB-UART | ×1 | ✅ | 2026-07-21 | "ftdi" — the single USB-UART line in the BOM; camera console/flash + PC↔ELRS CRSF (set 3.3 V jumper) |
| Camera — OpenIPC SSC338Q | ×1 | 🏠 | owned | already flashed + tuned |

**§2 Control / Radio**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| RadioMaster RP1 ELRS receiver | ×1 | ✅ | 2026-07-21 | "rp1-v2 rx" — uniquely the RP1; **CRSF input source** for w17-control-fw |
| ES24TX Pro (or nano) ELRS TX module | ×1 | ✅ | 2026-07-17 | "ELRS TX" — the single ELRS TX line (BOM lists Pro/nano as equal picks) |
| Transmitters (DualShock via PC + TX16S) | — | 🏠 | owned | |

**§3 Drive / ESC / Motor**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Hobbywing QuicRun 10BL120 + Rocket 540 combo | ×1 | ✅ | 2026-07-17 | **On hand** — arrived with the 07-17 first partial delivery (owner-confirmed 2026-07-22; not itemized in the `CURRENT_STATUS.md` 07-17 electronics list). Biggest single line (~⅓ of spend). **No gate change:** Phase C powered-drivetrain work stays gated on A2 / Phase B + the no-powering rule. |

**§4 Brains / Audio / Light**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| ESP32-WROOM-32 DevKit V1 (3 pcs) | ×1 | ✅ | 2026-07-17 | on hand; USB-C 30-pin clones (ESP32-D0WD-V3, CH340C). Per the owner's 2026-07-24 board decision these are **TEST/SPARE**, not the cassette controllers — see the MH-ET row in §E |
| MH-ET Live D1-Mini ESP32 (USB-C) | ×2 | ⏳ | — | the **cassette** controllers #1 + #2 — ordered 2026-07-24 (see §E) |
| MAX98357A I2S amplifier | ×1 | ✅ | 2026-07-21 | "amplifier interface" — **owner-confirmed** MAX98357A I2S (2026-07-22) |
| Speaker 4 Ω 3 W | ×1 | ✅ | 2026-07-21 | "speaker" — the single speaker line (impedance/power a bench spec-check) |
| WS2812B LED strip (1 m / 30 LED) | ×1 | ✅ | 2026-07-21 | "led strip" — the single LED-strip line (addressable WS2812B type to eyeball at wiring) |

→ **All four sound/light-specific modules are confirmed on hand** (ESP32, MAX98357A amp, speaker,
WS2812B LED), and so are their bench power (UBEC §5 ✅) and LED series resistor (§5 resistor kit
✅). The only remaining bench dependencies are the **§D build-from-stock passives / interconnect**
(1000 µF WS2812 reservoir + servo-rail decoupling, 100 nF, Dupont/wire/connectors) — owned from
stock but **not individually delivery-verified here**. So: the sound/light bench is effectively
ready **pending confirmation of those stock passives**; this file still does not stamp the
subsystem "hardware-complete" until they are confirmed present.

**§5 Power / Telemetry**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| UBEC 5 A (2 pcs) | ×1 | ✅ | 2026-07-21 | "ubec x2"; Rail A (clean) + Rail B (servos) |
| XT connectors (XT30 + XT60) | ×2 lines | 🏠 | — | **on hand from office/local stock** (owner, 2026-07-22 — can bring them in); additional units were **⏳ ordered to be safe, not yet delivered** |
| BX100 voltage buzzer | ×1 | ✅ | 2026-07-17 | logged as "LiPo voltage tester" — **owner-confirmed** BX100 low-voltage buzzer (2026-07-22). BOM marks BX100 *"optional"* |
| Resistor kit (600 pcs) | ×1 | ✅ | 2026-07-17 | 330 Ω / 10 kΩ / 27 kΩ for LED + Hall pull-up + divider |

**§6 Servos** — *requirement only partially satisfied*
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| DS3235SG steering servo (35 kg-class) | ×1 | ✅ | 2026-07-21 | "35kg servo set (servo + thing it rotates)" — the "thing" = 25T horn |
| MG90S micro servos (3 pcs) | ×1 | ⏳ | — | pan / tilt / DRS — **ordered / on the way** (owner, 2026-07-22). The steering servo above is on hand; the three micro servos are still in transit, so the servo requirement is **partially satisfied**. |

**§7 Speed sensor**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| A3144 Hall sensor (10 pcs) | ×1 | ✅ | 2026-07-21 | "Hall Effect Sensor x10" |
| Neodymium magnets 3×1 mm (20 pcs) | ×1 | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) — the A3144 pickup can't be exercised without its axle magnets |

**§8 Drivetrain**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Belt-drive full set (pulleys + 140 mm belt) | ×1 | ✅ | 2026-07-21 | "belt drive set"; includes the rear output shaft |
| Pinion 48DP 28T | ×1 | ✅ | 2026-07-21 | "alloy metal pinion motor gear" — the single pinion line |
| Spur 3Racing Sakura 48P 75T | ×1 | ✅ | 2026-07-21 | "spur gear" — the single spur line; *fitment* check (bolt holes match belt-set pulley, BOM open confirm #1) is owned by `w17-3d-codex`, not this file |

**§9 Bearings**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| MR128ZZ front bearings (10 pcs) | ×1 | ✅ | 2026-07-17 | "MR128ZZ front bearings ×10" |
| APE 6801 rear bearings 12×21×5 ZZ (5 pcs) | ×1 | ✅ | 2026-07-21 | "bearing 6801 ZZ (metal seal) x5" |

**§10 Suspension** — *requirement only partially satisfied*
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Front oil shocks 52 mm (4-set) | ×1 | ✅ | 2026-07-21 | "52 mm shock absorbers set" (front measure 51 vs 52 mm is a `w17-3d-codex` fit item) |
| Rear oil shock 68 mm (2 pc) | ×1 | ⏳ | — | central rear damper — **ordered / on the way** (owner, 2026-07-22). Front 52 mm set is on hand; the rear is in transit, so the suspension requirement is **partially satisfied**. |

**§11 Steering**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| M4 fully-threaded rod (40 mm / 10 pcs) | ×1 | ✅ | 2026-07-17 | "steel threaded rods" |
| M4 rod-end ball joints (24 mm / 10 pcs) | ×1 | ✅ | 2026-07-17 | "M4 rod-end linkage balls ×10" |
| Turnbuckles 3×32 mm | ×2 | ✅ | 2026-07-17 + 2026-07-21 | **2 on hand total** (owner-confirmed 2026-07-22) — matches the wanted 1 + crash-spare. Delivery wording: a 3×32 mm turnbuckle (07-17) + "Metal 3x32mm Turnbuckle Shaft Link" (07-21). |
| King pins (dowel pin + circlip) M3 / 30 mm (5 pcs) | ×1 | ✅ | 2026-07-21 | "flat head bearing m3 30mm x5" — **owner-confirmed** king pins (dowel + circlip) 2026-07-22 |
| M3 ball studs (10 pcs) | ×1 | ✅ | 2026-07-17 | **owner-confirmed** 2026-07-22: the 07-17 "M3 tie-rod-end ball caps" delivery included the ball studs (one set of each — see tie-rod ends below) |
| M3 tie-rod ends (3Racing set) | ×1 | ✅ | 2026-07-17 | "M3 tie-rod-end ball caps" — **owner-confirmed** 2026-07-22 as the 3Racing tie-rod-end set (arrived alongside the M3 ball studs) |

**§12 Fasteners / hardware**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Countersunk M3 bolt + nut kit (392 pcs) | ×1 | ✅ | 2026-07-21 | "m3 bolt nut set" |
| Heat-set brass inserts M3 × 5 mm (50 pcs) | ×1 | ✅ | 2026-07-21 | "m3 5mm insert nut" |
| Metal sleeves D5 × M3 / 5 mm (20 pcs) | ×1 | ✅ | 2026-07-21 | "flat washer gasket (D5x M3, 20pcs, 5mm)" — **owner-confirmed** tubular front guide-rod sleeves/spacers (2026-07-22), not flat washers |
| Aluminium tube OD16 × ID14 / 300 mm | ×1 | ✅ | 2026-07-17 | cut into rear-axle spacers |

**§13 Cooling (camera)**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Blower fan 5 V 20 mm | ×1 | ✅ | 2026-07-21 | "turbine cooler" — **owner-confirmed** 5 V 20 mm camera blower (2026-07-22) |
| Thermal paste (15 g) | ×1 | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) |

### B. rcMart order (genuine Tamiya tyres)
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Tamiya 54198 F104 front tyres | 1 pack | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) |
| Tamiya 51400 F104 rear tyres | 1 pack | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) |

### D. Local / stock / not-an-AliExpress-line
| Item | Status | Notes |
|---|---|---|
| 2S LiPo ×2 (soft-case, ≤75×45×25 mm, XT60) | ⏳ | **superseded in part** by the §E ZEEE order of 2026-07-24 (69×35×18 mm — inside the ≤75×45×25 mm envelope). This row's **quantity is no longer established here**: the §E entry records one ZEEE pack as ordered; whether a second pack is still wanted is a packaging/purchasing question, not an arrival fact, so it is left open rather than guessed |
| RT5370 USB Wi-Fi (GS bench SoftAP) | ✅ | **on hand** (owner-confirmed 2026-07-22); AP-mode support on Win 10/11 still to verify on the bench |
| Build-from-stock, consumables, tools, paint, decals | 🏠 | see BOM §D — not delivery-tracked |

### E. Cassette electrical — ordered 2026-07-24 (all ⏳ / in transit)

Cited source: the owner, via the `CURRENT_STATUS.md` 2026-07-24 (later) entry — *"Electrical BOM
FINALIZED + all items ORDERED"*. Every row here is **⏳ ordered / in transit**; none has arrived, and
per the legend ⏳ is an arrival-evidence mark, not a claim about fit, function, or any gate. Part
identities and envelopes come from the Claude-side electrical inputs
(`w17-electrical-inputs-for-codex.md`) and the build guide
(`w17-pdb-build-and-connector-guide.md`); if those and this file disagree on what a part *is*, they win.

| Item | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| MH-ET Live D1-Mini ESP32 (USB-C) | ×2 | ⏳ | — | cassette controllers #1 (control) + #2 (sound/light); ESP32-WROOM-32, ~39×31 mm. Also listed in §4 next to the on-hand DevKit V1 clones it replaces. Physical caliper + weight still owed once on hand |
| Ceramic capacitor kit | ×1 | ⏳ | — | covers the 100 nF decoupling and the optional 1–10 nF positions |
| Electrolytic capacitor kit | ×1 | ⏳ | — | covers the 1000 µF servo-rail and WS2812 LED reservoir positions; the actual 1000 µF part still needs calipering on arrival |
| Amass XT90-S anti-spark master switch | ×1 | ⏳ | — | pack-side master disconnect (anti-spark) |
| XT60 → XT90 adapter | ×1 | ⏳ | — | mates the XT60 harness side to the XT90-S switch |
| IP2326 2S Type-C balancing charger | ×1 | ⏳ | — | onboard USB-C charging, 18.3×31 mm; balancing confirmed at selection |
| ZEEE 1500 mAh 2S LiPo | ×1 | ⏳ | — | 69×35×18 mm, JST-XH balance lead; **the owner will re-terminate the main lead to XT60**. Supersedes part of the §D "2S LiPo ×2" row |
| 1N5819 Schottky diode | — | 🏠 | — | **from office stock** (owner, 2026-07-24) — not an ordered delivery line; not individually delivery-verified here |

---

## Not on hand yet — what to chase next

Ranked by how much they block downstream work. Status marks per the legend; **⏳ = ordered/in
transit per the owner (2026-07-22)**, ⬜ = not on hand / not yet sourced.

1. **Neodymium magnets (§7)** — ⏳ ordered/in transit; the A3144 Hall sensor + ESC are on hand, but the wheel-speed pickup can't be exercised without its axle magnets.
2. **MG90S micro servos ×3 (§6)** — ⏳ ordered/in transit (pan / tilt / DRS). Steering servo is on hand, so the servo requirement is only **partially** satisfied.
3. **Rear oil shock 68 mm (§10)** — ⏳ ordered/in transit; only the front 52 mm set is on hand (suspension **partially** satisfied).
4. **MH-ET D1-Mini ESP32 ×2 (§E)** — ⏳ ordered/in transit. These are the *cassette* controllers; the
   on-hand DevKit V1 clones are TEST/SPARE only, so the cassette-controller requirement is **not**
   satisfied by them. Their real caliper + weight is also an open mechanical input.
5. **ZEEE 1500 mAh 2S LiPo (§E)** — ⏳ ordered/in transit; needs owner re-termination to XT60 before use.
6. **Tamiya tyres (§B)** — ⏳ ordered/on the way; full rcMart order not yet on hand.
7. **Cassette electrical remainder (§E)** — ⏳ cap kits, XT90-S master switch + XT60→XT90 adapter,
   IP2326 charger. No sourcing decisions remain open on any of them; only delivery.
8. **Thermal paste (§13)** — ⏳ ordered/in transit (camera-cooling consumable).

> The ESC + motor combo (§3) is now **on hand** (arrived 2026-07-17), so it no longer blocks parts
> availability for Phase C — but powered drivetrain work remains gated on A2 / Phase B regardless.
> XT connectors (§5) are covered by office stock (extra units ordered). The §E cassette-electrical
> order of 2026-07-24 closes the last **sourcing** questions for the electronics, but **ordering is
> not arrival and arrival is not a gate**: A2 stays unexecuted and Phase B stays blocked.

---

## Delivery log (newest first)

### 2026-07-21 — major mechanical + electronics drop
The owner's arrival list is recorded **verbatim** in the first column; interpretation and mapping
confidence are kept in separate columns so the raw user-reported evidence is not rewritten.
Mapping column reflects the owner confirmations of 2026-07-22.

| As delivered (owner's words, verbatim) | Mapped BOM line | § | Mapping |
|---|---|---|---|
| spur gear | Spur 3Racing Sakura 48P 75T | §8 | ✅ |
| speaker | Speaker 4 Ω 3 W | §4 | ✅ |
| wifi antennas | 5.8 GHz U.FL omni antennas 70 mm | §1 | ✅ (owner-confirmed) |
| alloy metal pinion motor gear | Pinion 48DP 28T | §8 | ✅ |
| belt drive set | Belt-drive full set | §8 | ✅ |
| ftdi | FT232RL USB-UART | §1 | ✅ |
| ubec x2 | UBEC 5 A (2 pcs) | §5 | ✅ |
| flat washer gasket (D5x M3, 20pcs, 5mm) | Metal sleeves D5×M3 5 mm | §12 | ✅ (owner-confirmed sleeves) |
| 52 mm shock absorbers set | Front oil shocks 52 mm 4-set | §10 | ✅ |
| cooling heatsink for wifi module | Heatsink 28×28×3 mm | §1 | ✅ |
| rp1-v2 rx | RadioMaster RP1 ELRS receiver | §2 | ✅ |
| bearing 6801 ZZ (metal seal) x5 | APE 6801 rear bearings ZZ | §9 | ✅ |
| m3 5mm insert nut | Heat-set brass inserts M3×5 mm | §12 | ✅ |
| Hall Effect Sensor x10 | A3144 Hall sensor (10 pcs) | §7 | ✅ |
| Metal 3x32mm Turnbuckle Shaft Link | Turnbuckle 3×32 mm | §11 | ✅ (2 on hand total) |
| led strip | WS2812B LED strip | §4 | ✅ |
| turbine cooler | Blower fan 5 V 20 mm | §13 | ✅ (owner-confirmed camera blower) |
| amplifier interface | MAX98357A I2S amplifier | §4 | ✅ (owner-confirmed) |
| 35kg servo set (servo + thing it rotates) | DS3235SG steering servo (+ 25T horn) | §6 | ✅ |
| m3 bolt nut set | Countersunk M3 bolt + nut kit | §12 | ✅ |
| flat head bearing m3 30mm x5 | King pins M3 / 30 mm (5 pcs) | §11 | ✅ (owner-confirmed king pins) |

**Effect on the 07-17 "still awaited" list** (`CURRENT_STATUS.md` 07-17 named: tyres, shocks,
servos, king pins, belt set, blower, rear 6801 bearings, RT5370). After the 07-21 drop and the
2026-07-22 owner confirmations:

- **Now on hand:** belt set (§8), rear 6801 bearings (§9), blower (§13), king pins (§11), RT5370
  (§D).
- **Partially satisfied:** shocks — front 52 mm on hand (§10), rear 68 mm ⏳ in transit; servos —
  DS3235SG steering on hand (§6), 3× MG90S ⏳ in transit.
- **Still ⏳ ordered / on the way:** Tamiya tyres (§B).

Alongside the mechanical items, core electronics landed and are now all mapping-confirmed: RP1 rx
(§2), FTDI (§1), UBEC ×2 (§5), Hall sensor (§7), and the sound/light modules — amplifier (§4),
speaker (§4), LED strip (§4), wifi antennas (§1) — all ✅ after the 2026-07-22 confirmations.

### 2026-07-17 — first recorded batch in `CURRENT_STATUS.md` (partial)
(Recorded in `CURRENT_STATUS.md`, 2026-07-17 entry; the mechanical items are also noted in
`w17-3d-codex/GENERAL_PLAN.md` item 5 — a historical note there, **not** a second arrival ledger;
see Cross-repository follow-up.) Owner's wording preserved; mapping confidence per 2026-07-22.

- **Electronics:** 3× ESP32 DevKit (§4 ✅) · "BL-M8812EU2 WiFi module" (§1 ✅) · "ELRS TX"
  (§2 ✅) · "LiPo voltage tester" (§5 ✅ = BX100, owner-confirmed) · resistor kit (§5 ✅) ·
  **ESC + motor combo** (§3 ✅ — owner-confirmed 2026-07-22 as part of this batch; **not**
  itemized in the `CURRENT_STATUS.md` 07-17 electronics list).
- **Mechanical:** "MR128ZZ front bearings ×10" (§9 ✅) · "3×32 mm turnbuckle" (§11 ✅) ·
  "M4 rod-end linkage balls ×10" (§11 ✅) · "M3 tie-rod-end ball caps" (§11 ✅ = **both** the
  3Racing tie-rod ends **and** the M3 ball studs, owner-confirmed) · "steel threaded rods"
  (§11 ✅) · "aluminium tube" (§12 ✅).

---

## Mapping confirmations — all closed 2026-07-22 (owner eyeball)

Every delivery whose wording did not 1:1 match a BOM name has been resolved by the owner. Kept as
a provenance record (the raw evidence in the delivery log is unchanged):

1. **"wifi antennas" → 5.8 GHz U.FL omni antennas (§1)** — confirmed (not 2.4 GHz ELRS). ✅
2. **"amplifier interface" → MAX98357A I2S amplifier (§4)** — confirmed. ✅
3. **"turbine cooler" → Blower fan 5 V 20 mm (§13)** — confirmed as the **camera** blower (not a
   Wi-Fi-module cooling fan). ✅
4. **"flat head bearing m3 30mm x5" → King pins M3 / 30 mm (§11)** — confirmed king pins
   (dowel + circlip). ✅
5. **"flat washer gasket (D5x M3, …)" → Metal sleeves D5×M3 (§12)** — confirmed tubular
   sleeves/spacers, not flat washers. ✅
6. **"M3 tie-rod-end ball caps" (07-17) → §11** — confirmed as **both** the 3Racing tie-rod ends
   **and** the M3 ball studs (one set of each). ✅✅
7. **"LiPo voltage tester" (07-17) → BX100 buzzer (§5)** — confirmed BX100. ✅

---

## Cross-repository follow-up — LANDED in `w17-3d-codex` 2026-07-22

**Resolved.** The cleanup described below has been made in `w17-3d-codex` itself (commit
*"docs: stop this repo tracking arrivals; point to HARDWARE_INVENTORY.md"*, 2026-07-22 — hash
recorded in `CURRENT_STATUS.md`, since this file carries none). Verified read-only from a
workspace session: it rewrites `GENERAL_PLAN.md` item 5 so *arrival* status points here and only
mechanical residuals remain (front-shock 51 vs 52 mm, spur↔pulley bolt pattern, DS3235SG + MG90S
fit-checks, king-pin 3 mm knuckle bore, rear-axle spacer cut length), reframes the turnbuckle
wording as "2 on hand total" rather than an independent count claim, and annotates
`B_component_envelope_register.md` so HAND/TRANSIT read as *measurement-readiness*. **Caveat: that
commit is not yet pushed to its remote**, so the fix exists only in the local clone.

The original description is kept below as the record of what was owed:

- **`w17-3d-codex/GENERAL_PLAN.md` item 5** currently reads as an active delivery tracker
  (*"Hardware partially delivered 2026-07-17 … **Still in transit:** tyres, 52/68 mm shocks,
  servos …, king pins, belt set, rear 6801 bearings, blower"*). That "still in transit" list is
  **now substantially stale** — belt set, rear 6801 bearings, front shocks, steering servo, king
  pins, and blower are all on hand (owner-confirmed 2026-07-22). When that repo is next edited it
  should point *arrival* status at this file and keep only the mechanical **measure / fit**
  residuals (e.g. "measure front shocks 51 vs 52 mm, spur↔pulley bolt pattern, servo fit-checks").
  Its turnbuckle "×2 as of 07-17" is consistent with the **2-on-hand total** confirmed here; the
  only residual is the per-delivery date attribution (this file logs 1 on 07-17 + 1 on 07-21),
  not a count conflict.
- **`w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md`** uses HAND / TRANSIT
  flags and marks e.g. VID-WIFI on-hand *"UNCONFIRMED"* and the ESC / servos as TRANSIT. Those
  flags should be read as **measurement-readiness**, not an authoritative arrival ledger — several
  are now on hand (ESC + WiFi module per the 07-17 first partial delivery; steering servo
  07-21). For arrival status this file is authoritative.

That cleanup has since landed (see the heading above), so the duplication is now **eliminated in the
local clones** — the only residual is that the `w17-3d-codex` commit carrying it is unpushed.

---

## Cross-references

- Buy-list / part identities (saved-cart source): `w17-control-fw/docs/bill_of_materials_v2.md`
- Cassette-electrical part identities + envelopes (§E): `w17-electrical-inputs-for-codex.md` ·
  `w17-pdb-build-and-connector-guide.md` (both projects root)
- Project execution / gate / CI status + commit hashes: `CURRENT_STATUS.md` (canonical; its
  physical-parts carve-out points back to this file)
- Mechanical measure / fit / mount / envelope status (in `w17-3d-codex`, its own repo):
  `w17-3d-codex/GENERAL_PLAN.md` item 5 · `w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md`
  (see Cross-repository follow-up)
- Bring-up procedures: `learning-manual/13_bare_board_smoke_test.md` ·
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` ·
  `w17-control-fw/docs/D8_BENCH_BRINGUP.md`

> **No hardware gate changes from any delivery recorded here** — including the ESC + motor combo
> now being on hand. A2 remains unexecuted, Phase B remains blocked, and the no-unattended-powering
> rule stands. Only the owner-approved bare-board USB smoke test (naked DevKit, nothing on pins,
> attended) is permitted. Parts *availability* is recorded here; *execution* status stays in
> `CURRENT_STATUS.md`.
