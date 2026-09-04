# W17 Hardware Inventory & Delivery Log

Single **workspace-level** log of **physical hardware arrival** for the W17 build: what has
arrived, when, and how confidently each delivery maps to a Bill-of-Materials line. It records
*arrival evidence and mapping confidence only* — never gates, software status, or commit hashes.

_Last updated: 2026-07-29 (recorded the 2026-07-29 delivery: small ESPs, 3 micro servos, thermal
paste, XT60/XT30 connectors, rear shocks, both capacitor kits, USB charging boards, one LiPo. The
2026-07-25 §E rows and the 2026-07-22 correction pass are otherwise unchanged)._

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
| MH-ET Live D1-Mini ESP32 (USB-C) | ×2 ordered | ✅ | 2026-07-29 | the **cassette** controllers #1 + #2 — **3 on hand** (owner-stated count, 2026-07-29); see §E for the count note. Caliper + weight still owed |
| MAX98357A I2S amplifier | ×1 | ✅ | 2026-07-21 | "amplifier interface" — **owner-confirmed** MAX98357A I2S (2026-07-22) |
| Speaker 4 Ω 3 W | ×1 | ✅ | 2026-07-21 | "speaker" — the single speaker line (impedance/power a bench spec-check) |
| WS2812B LED strip (1 m / 30 LED) | ×1 | ✅ | 2026-07-21 | "led strip" — the single LED-strip line (addressable WS2812B type to eyeball at wiring) |

→ **All four sound/light-specific modules are confirmed on hand** (ESP32, MAX98357A amp, speaker,
WS2812B LED), and so are their bench power (UBEC §5 ✅) and LED series resistor (§5 resistor kit
✅). Since 2026-07-29 the **capacitor positions are covered by delivered parts** rather than by stock:
the §E ceramic + electrolytic kits arrived (100 nF decoupling, 1000 µF WS2812 reservoir + servo-rail),
so the only remaining bench dependency is the **§D build-from-stock interconnect**
(Dupont/wire/connectors) — owned from stock but **not individually delivery-verified here**. So: the
sound/light bench is effectively ready **pending confirmation of that stock interconnect**; this file
still does not stamp the subsystem "hardware-complete", and arrival of the caps is not a bench result.

**§5 Power / Telemetry**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| UBEC 5 A (2 pcs) | ×1 | ✅ | 2026-07-21 | "ubec x2"; Rail A (clean) + Rail B (servos) |
| XT connectors (XT30 + XT60) | ×2 lines | ✅ | 2026-07-29 | the **ordered** extra units arrived 2026-07-29 ("XT60 and XT30 connectrs") — both lines. Office/local stock was already available on top of these (owner, 2026-07-22); no per-line count is established here |
| BX100 voltage buzzer | ×1 | ✅ | 2026-07-17 | logged as "LiPo voltage tester" — **owner-confirmed** BX100 low-voltage buzzer (2026-07-22). BOM marks BX100 *"optional"* |
| Resistor kit (600 pcs) | ×1 | ✅ | 2026-07-17 | 330 Ω / 10 kΩ / 27 kΩ for LED + Hall pull-up + divider |

**§6 Servos** — *requirement now fully satisfied on arrival evidence*
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| DS3235SG steering servo (35 kg-class) | ×1 | ✅ | 2026-07-21 | "35kg servo set (servo + thing it rotates)" — the "thing" = 25T horn |
| MG90S micro servos (3 pcs) | ×1 | ✅ | 2026-07-29 | "3 servos for gimbal and drs" — pan / tilt / DRS, the single 3-micro-servo line. Both servo lines are now on hand; *fit* (MG90S mount checks) stays a `w17-3d-codex` item, not an arrival fact |

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

**§10 Suspension** — *requirement now fully satisfied on arrival evidence*
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Front oil shocks 52 mm (4-set) | ×1 | ✅ | 2026-07-21 | "52 mm shock absorbers set" (front measure 51 vs 52 mm is a `w17-3d-codex` fit item) |
| Rear oil shock 68 mm (2 pc) | ×1 | ✅ | 2026-07-29 | "remaining shock observers" [absorbers] — the only outstanding shock line, so the mapping is unambiguous; central rear damper. Length/fit measurement stays a `w17-3d-codex` item |

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
| Thermal paste (15 g) | ×1 | ✅ | 2026-07-29 | "thermal paste" — the single thermal-paste line |

### B. rcMart order (genuine Tamiya tyres)
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Tamiya 54198 F104 front tyres | 1 pack | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) |
| Tamiya 51400 F104 rear tyres | 1 pack | ⏳ | — | **ordered / on the way** (owner, 2026-07-22) |

### D. Local / stock / not-an-AliExpress-line
| Item | Status | Notes |
|---|---|---|
| 2S LiPo ×2 (soft-case, ≤75×45×25 mm, XT60) | ⬜ **none on hand** | ⚠ **corrected 2026-07-31** — this row previously read "partially ✅" on the strength of a 1500 mAh pack that **never arrived** (see §E). **Zero in-envelope packs exist.** The only battery on hand is the out-of-envelope 5200, which is bench-only. **The ×2 is a convenience target, not a gate** ("carry 2 — runtime insurance", `learning-manual/05…:395`): **one** pack makes the car drivable; the second only removes charge-downtime and single-point-of-failure. Buying two *at once* is nonetheless the practical call given how hard the owner is finding it to source a pack in-envelope at all (2026-07-31) |
| RT5370 USB Wi-Fi (GS bench SoftAP) | ✅ | **on hand** (owner-confirmed 2026-07-22); AP-mode support on Win 10/11 still to verify on the bench |
| Build-from-stock, consumables, tools, paint, decals | 🏠 | see BOM §D — not delivery-tracked |

### E. Cassette electrical — ordered 2026-07-24, arrived 2026-07-29 + 2026-07-30

Order source: the owner, via the `CURRENT_STATUS.md` 2026-07-24 (later) entry — *"Electrical BOM
FINALIZED + all items ORDERED"*. Arrival source: the owner's 2026-07-29 and 2026-07-30 delivery
reports (see the delivery log). **The 2026-07-30 drop cleared the last two ⏳ rows** (XT90-S master
switch, XT60→XT90 adapter — delivered together as a pigtail set) — every §E row is now ✅ on
hand. The same drop brought an **out-of-envelope 5200 mAh pack**, logged here as bench-only.
Per the legend these are arrival-evidence marks only — not a claim about fit, function, or any
gate. Part identities and envelopes come from the Claude-side electrical inputs
(`w17-electrical-inputs-for-codex.md`) and the build guide
(`w17-pdb-build-and-connector-guide.md`); if those and this file disagree on what a part *is*, they win.

| Item | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| MH-ET Live D1-Mini ESP32 (USB-C) | ×2 ordered | ✅ | 2026-07-29 | cassette controllers #1 (control) + #2 (sound/light); ESP32-WROOM-32, ~39×31 mm. **3 on hand** per the owner (2026-07-29) against ×2 recorded as ordered — the surplus is recorded as delivered; it is the *order quantity* that is unverified here, not the arrival. Also listed in §4 next to the DevKit V1 clones it replaces. **Physical caliper + weight still owed** (`w17-3d-codex` input) |
| Ceramic capacitor kit | ×1 | ✅ | 2026-07-29 | "both capasitor packs" — covers the 100 nF decoupling and the optional 1–10 nF positions |
| Electrolytic capacitor kit | ×1 | ✅ | 2026-07-29 | "both capasitor packs" — covers the 1000 µF servo-rail and WS2812 LED reservoir positions; **the actual 1000 µF part still needs calipering** now that it is on hand |
| Amass XT90-S anti-spark master switch | ×1 | ✅ | 2026-07-30 | **arrived as a two-piece pigtail set, not as a discrete "switch" part**: (a) XT90-S **female** anti-spark → XT60 **male**, 12 AWG, and (b) **XT90H-M male** with a 12 AWG bare tail. Mated, the pair *is* the pull-apart master; the anti-spark (resistor) half is the female, which per the build guide's gender rule is the one that faces the live pack. Assembled chain = pack XT60 f → (a) → (b) → PDB input. **This row and the XT60→XT90 row below are satisfied together by these two items** — that re-mapping is an interpretation, not the owner's words |
| XT60 → XT90 adapter | ×1 | ✅ | 2026-07-30 | see the row above — item (a) **is** the XT60↔XT90 transition, delivered pre-wired rather than as a separate adapter. Nothing is owed against this line. (The 07-29 "XT60 and XT30 connectrs" still maps to the §5 connector line, not here) |
| XT60 **female** + 12 AWG tail | ×1 | ✅ | 2026-07-30 | the **pack re-termination** connector — pack side = female per the build guide's gender rule. **Currently has no pack to terminate** (2026-07-31 correction): keep it for whichever car pack is sourced, if that pack doesn't ship XT60-native |
| JST-XH 2S 3-pin extension (male–female) | ×1 | ✅ | 2026-07-30 | pack balance lead → IP2326 charger. Fits either pack (both ZEEE packs use JST-XH) |
| In-envelope 2S car pack (≤75×45×25) | ×1 minimum | ⬜ | — | **NOT ON HAND — nothing that fits the car has ever arrived.** ⚠ **Corrected 2026-07-31:** this file previously carried a "ZEEE 1500 mAh, 69×35×18, ✅ arrived 2026-07-29" row. **That pack never existed.** The 07-29 owner report said only *"one battery"*; this file mapped those words to the *ordered* 1500 line and then wrote in the **order-spec dimensions as if they were measured**. The pack that actually came is the 5200 below (supplier mix-up, owner 2026-07-31). Nothing is owed *against an order* here — the owner is sourcing a replacement and **may buy to spec rather than to the ZEEE part number**; see the sourcing spec in the delivery-log entry for 2026-07-31 |
| ZEEE 5200 mAh 2S LiPo — **BENCH ONLY, not a car pack** | not ordered as such | ✅ (received) | 2026-07-30 | **The only battery on hand.** **138×47×37 mm — exceeds the ≤75×45×25 mm envelope on all three axes** (+63 / +2 / +12 mm; ≈3.9× the volume). Wrong item (owner: *"some misunderstanding"*, 2026-07-31); a replacement is being sought. Two independent reasons it cannot be the car pack: `w17-3d-codex/BUILD_SHEET.md` already ruled a **115**×35×24 pack won't fit the 2024 body (this one is 23 mm longer still), and the Z3 central tub is only **14–40 mm wide where it is ≥45 mm tall**, so a 47-wide × 37-tall pack does not drop in. **Assumption, not measured:** a 2S 5200 typically weighs ~250–300 g — weigh it before any CG argument cites a number. Bench use stays **A2 + Phase B gated** like every other powered activity, and its higher fault energy is a *new* bench-safety consideration, not a cleared one |
| IP2326 2S Type-C balancing charger | ×1 ordered | ✅ | 2026-07-29 | onboard USB-C charging, 18.3×31 mm; balancing confirmed at selection. **2 on hand** per the owner (2026-07-29) against ×1 recorded as ordered — same reading as the MH-ET row: the arrival count is owner-stated, the order count is what is unverified. **Cross-repo note (2026-09-04):** `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md` OP-49 still marks the 2S balancing-charge module a **BLOCKER**, "still unselected," with the exact SKU/datasheet, full board/connector/heatsink envelope, cell-interface, interlock, and a charge-safety specification all listed as missing. Physical possession here is not the same thing as OP-49's "selected" — see item 4 below |
| 1N5819 Schottky diode | — | 🏠 | — | **from office stock** (owner, 2026-07-24) — not an ordered delivery line; not individually delivery-verified here |

---

## Not on hand yet — what to chase next

Ranked by how much they block downstream work. Status marks per the legend; **⏳ = ordered/in
transit per a cited source**, ⬜ = not on hand / not yet sourced. The 2026-07-29 delivery cleared six
of the eight entries this list previously carried, and **2026-07-30 cleared the master-switch pair**;
what is left:

1. **An in-envelope 2S car pack (§D/§E)** — ⬜ **not on hand, not ordered; the owner is having
   trouble sourcing one** (2026-07-31). **Promoted to the top of this list on 2026-07-31**, when it
   emerged that the 1500 mAh pack this file had recorded as arrived **never arrived at all**. The car
   currently has **no battery that fits it**. Not a *gate* — A2 and Phase B block on their own terms
   and the bench 5200 covers bench work — but it is the only line here that blocks the car ever moving
   under its own power. Shop to the **dimensions**, not to a capacity number: hard fail above
   75×45×25 mm; recommended target ≤70×40×22 mm; 2S / soft-case / ≥25C / JST-XH; XT60 preferred.
2. **Neodymium magnets 3×1 mm (§7)** — ⏳ ordered/in transit (owner, 2026-07-22); the A3144 Hall
   sensor + ESC are on hand, but the wheel-speed pickup can't be exercised without its axle magnets.
3. **Tamiya tyres (§B)** — ⏳ ordered/on the way (owner, 2026-07-22); the rcMart order has not landed.
4. **2S balancing USB-C charge module — formal selection (OP-49, added 2026-09-04)** — ⬜ **not
   selected in the sense `w17-3d-codex` requires**, even though a candidate part (§E's IP2326, 2
   on hand) already sits in this file. `w17-3d-codex/10_assembly_architecture/
   OPEN_PROBLEMS_AND_QUESTIONS.md:81` (OP-49) is a **BLOCKER** for done-bar item 4 (onboard USB-C
   charging) and lists as missing: the exact SKU/datasheet on record, the complete board +
   connector + heatsink envelope, cell-interface details, the charge/run interlock implementation,
   charge-state access, reverse/backfeed isolation, thermal/fault evidence, and a **separate
   charge-safety specification that must close before any powered charge test**. Owner action:
   either formally adopt the on-hand IP2326 as the selected module and work through OP-49's
   remaining list against it, or select a different module and update both this file and OP-49
   together so they stop disagreeing about whether a module has been chosen.

> **Cleared by the 2026-07-29 delivery:** MH-ET D1-Mini ESP32 (§4/§E), MG90S micro servos ×3 (§6),
> rear 68 mm oil shock (§10), thermal paste (§13), ceramic + electrolytic cap kits (§E), IP2326
> charger (§E), and the ordered XT60/XT30 connector units (§5). ⚠ **"ZEEE 2S LiPo" was struck from
> this list on 2026-07-31** — see the corrected 07-29 log row; no in-envelope pack arrived.
>
> The ESC + motor combo (§3) has been **on hand** since 2026-07-17, so it no longer blocks parts
> availability for Phase C — but powered drivetrain work remains gated on A2 / Phase B regardless.
> **Arrival is not a gate:** with almost the whole electrical set now physically present, A2 still
> stays unexecuted, Phase B stays blocked, and the no-unattended-powering rule stands. What the
> delivery does unblock is *measurement* work (MH-ET caliper + weight, the actual 1000 µF part,
> MG90S and rear-shock fit checks) — and that is owned by `w17-3d-codex`, not by this file.

---

## Delivery log (newest first)

### 2026-07-31 — correction + car-pack sourcing spec (no delivery)

Not a delivery. Two things: a **correction** (the 1500 mAh pack recorded as arrived on 07-29 never
arrived — see that entry), and the **shopping spec** for the pack that must now be found, recorded
here because the owner reports difficulty sourcing one and the reasoning should not have to be
re-derived.

**Shop by dimensions, not by capacity.** Capacity is the free variable; the envelope is the constraint.
Any 2S pack that fits is acceptable — 1300, 1500, 1800 mAh are all fine. "1500 mAh" was never a
requirement, only the capacity of the pack that happened to be picked.

| Spec | Hard limit | Recommended target | Why — and what breaks if violated |
|---|---|---|---|
| **Cell count** | **2S, exactly** | — | Not negotiable and not a preference. The firmware reads pack voltage through a fixed divider on ADC 34 (`PinMap.hpp:35`) and warns at **7.0 V** (`glossary.md:398`). 3S would read as "always full" *and* over-volt every 5 V rail's input assumption; 1S can't run the ESC |
| **Length** | **≤75 mm** | **≤70 mm** | The binding dimension, and the origin of the whole envelope — see the note below. The 5 mm margin is for the **lead exit**, which sticks out past the case by 10–20 mm and is *not* counted in a listing's dimensions |
| **Width** | ≤45 mm | ≤40 mm | Clears with margin per the shell probe; the target leaves room for the retention strap and for not fighting the loom |
| **Height** | ≤25 mm | ≤22 mm | Strap, velcro and floor tape eat 2–3 mm that the listing never mentions |
| **Case** | **soft-case** | — | A hardcase spends 2–3 mm per axis on shell you have not got |
| **C rating** | **≥25C** | 30C+ | Gentle use ≠ gentle *peaks*. A punch into a stalled motor through a 120 A ESC will sag a 10C pack and brown out the receiver. 1500 mAh × 25C ≈ 37 A burst = ample |
| **Balance lead** | **JST-XH** (2S = 3-pin) | — | Matches the IP2326 charger and the 07-30 extension. Anything else means an adapter in the charge path |
| **Main lead** | any | **XT60 already fitted** | Otherwise it is a re-termination job. The 07-30 XT60 female lead exists for exactly that job if needed |

**Where the ≤75 mm actually comes from — it is *not* the added electronics.** Ryan's original
`Parts List.txt` specifies **115×35×24**, and that number is **stale, not wrong-for-another-reason**:
it belongs to the *older* body. The **2024 body's own READ ME** sets the ≤75 mm limit, and
`w17-3d-codex/BUILD_SHEET.md` records the conflict and resolves it — *"that battery will not fit the
2024 body … Buy to 75 mm."* The cassette/deck-2 electronics **do** contest the same Z3 zone, but that
is a second, independent reason not to push length, not the source of the number.

**Honest caveat:** ≤75 mm is the **designer's stated limit, not a verified measurement**. The 2026-07-10
probe was a ray-cast of the shell STLs only — it confirms width and height clear with margin but
**cannot measure usable bay length** (bulkheads, bosses, connector clearance, removal path), and
nothing has been printed. Final battery choice stays formally blocked on the slicer-assembly measure
plus a printed dry-fit (`FIRST_PRINT_DECISION.md` §7). Buying to ≤70 mm is buying inside an
unverified limit — which is the right side to be wrong on.

**Quantity:** **one** makes the car drivable. The BOM's ×2 is runtime insurance, not a gate. The real
argument for two is not runtime — it is that a pack this constrained is evidently hard to source, so
buying a matched pair *while a fitting one is in front of you* avoids repeating the search.

### 2026-07-30 — master-switch pigtail set + a wrong-size battery
Owner's arrival list recorded **verbatim** in the first column. This drop closes the last two §E
electrical lines and adds one item that was **not ordered as delivered**.

| As delivered (owner's words, verbatim) | Mapped BOM line | § | Mapping |
|---|---|---|---|
| XT90-S female anti-spark → XT60 male, 12 AWG cable | Amass XT90-S anti-spark master switch + XT60→XT90 adapter (**jointly**, with the item below) | §E | ✅ part-identity certain; **the two-rows-one-set reading is an interpretation.** The anti-spark half is the female, which is the half that should face the live pack |
| XT90H-M male with 12 AWG cable | same pair as above — the pull-apart key half | §E | ✅ as above. Its bare tail takes an **XT60 female** to reach the PDB input; **the owner will make up that end at the office** from §5 stock (2026-07-30) — 🏠, not a chase line |
| XT60 female with 12 AWG cable | pack re-termination lead | §E (new row) | ✅ unambiguous; matches the pack-side-female gender rule in `w17-pdb-build-and-connector-guide.md` |
| JST-XH 2S 3-pin male–female extension | pack balance → IP2326 charge path | §E (new row) | ✅ unambiguous |
| ZEEE 5200 mAh battery, 138×47×37 mm | **no BOM line** — wrong size for the ordered pack | §E (new row) | ⚠ **received but not accepted as a car part.** Out of the ≤75×45×25 envelope on all three axes; owner is attempting a replacement. Recorded as **bench-only** hardware. ⚠ **2026-07-31:** this is the **only** battery on hand — the "second 1500" wording here was written on the false premise that a first one existed |

**Consequence for the build spec:** none of the four connector items changes
`w17-pdb-build-and-connector-guide.md` — they *implement* the topology already drawn there. The one
open detail — terminating the XT90H tail into the PDB input with an XT60 female — is **owner-made at
the office from §5 stock** (2026-07-30), so nothing is owed from a supplier. Making it is not doing
it: the joint is still unbuilt, and building it is still A2 / Phase-B gated like the rest of the harness.

**Still ⏳ after this drop:** neodymium magnets (§7), Tamiya tyres (§B).

### 2026-07-29 — cassette-electrical + remaining-mechanical drop
Owner's arrival list recorded **verbatim** in the first column (typos preserved); interpretation and
mapping confidence kept in separate columns. This drop is mostly the 2026-07-24 §E electrical order
plus the last three ⏳ mechanical/consumable lines from the 2026-07-22 in-transit set.

| As delivered (owner's words, verbatim) | Mapped BOM line | § | Mapping |
|---|---|---|---|
| new smaller ESPs | MH-ET Live D1-Mini ESP32 (USB-C) | §4 / §E | ✅ — "smaller" vs the on-hand DevKit V1 uniquely identifies the MH-ET line; **3 on hand** (owner-stated) vs ×2 recorded as ordered |
| 3 servos for gimbal and drs | MG90S micro servos (3 pcs) | §6 | ✅ — the only 3-micro-servo line; pan / tilt / DRS named by the owner |
| thermal paste | Thermal paste (15 g) | §13 | ✅ — single line |
| XT60 and XT30 connectrs | XT connectors (XT30 + XT60) | §5 | ✅ — the ordered extra units; **not** the §E XT60→XT90 adapter, which is a separate line and did not arrive |
| remaining shock observers | Rear oil shock 68 mm (2 pc) | §10 | ✅ — "observers" reads as *absorbers*; the rear damper was the only outstanding shock line |
| both capasitor packs | Ceramic capacitor kit + Electrolytic capacitor kit | §E | ✅ — "both" maps 1:1 onto the two §E kit lines |
| USB charging boards | IP2326 2S Type-C balancing charger | §E | ✅ — the only USB-charging line; **2 on hand** (owner-stated) vs ×1 recorded as ordered |
| one battery | ~~ZEEE 1500 mAh 2S LiPo~~ | §E / §D | ❌ **MIS-MAPPED — corrected 2026-07-31.** "One battery" was matched to the *ordered* 1500 line and the order's 69×35×18 dimensions were then written into §E as though observed. No 1500 mAh pack ever arrived. The battery in this delivery was the **5200 mAh** pack (owner: supplier mix-up), whose real dimensions only surfaced on 2026-07-30. **The lesson is the standing one for this file: an owner's word for a part ("one battery") is arrival evidence for *a* part, never for the part the BOM expected** |

**Not in this drop** (still ⏳, and deliberately not inferred from "and one battery" or from the
electrical order landing as a whole): neodymium magnets (§7), Amass XT90-S master switch + XT60→XT90
adapter (§E), Tamiya tyres (§B).

**Two counts exceed the recorded order** — 3 MH-ET boards against ×2, and 2 IP2326 chargers against
×1. Both arrival counts are the owner's own statement (2026-07-29) and are recorded as given; the
uncertainty is in the *order* quantity recorded on 2026-07-24, not in the arrival. No BOM line is
changed here — the BOM stays the authority on what each part is.

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
  DS3235SG steering on hand (§6), 3× MG90S ⏳ in transit. *(As of 2026-07-21 — both were
  **superseded by the 2026-07-29 drop**, which closed the rear shock and the MG90S ×3.)*
- **Still ⏳ ordered / on the way:** Tamiya tyres (§B). *(Still true as of 2026-07-29.)*

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
