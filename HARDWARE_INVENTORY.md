# W17 Hardware Inventory & Delivery Log

Canonical record of **physical hardware** for the W17 build: what has arrived, when, and
what is still outstanding — mapped line-by-line to the Bill of Materials.

_Last updated: 2026-07-21._

## What this file is (and is not) authoritative for

- **IS canonical for:** which physical parts are on hand vs. in transit vs. not yet ordered,
  and the dated log of what arrived in each delivery.
- **Is NOT** a software/gate tracker and carries **no commit hashes**. Software status,
  hardware gates (A2 / Phase B), and CI state stay in **`CURRENT_STATUS.md`** — the only
  workspace-level file that carries volatile software state.
- **Buy-list source of truth:** `w17-control-fw/docs/bill_of_materials_v2.md` (BOM v2). Every
  row below cites its BOM section (§1–§13, B, D). If this file and the BOM disagree on what a
  part *is*, the BOM wins; this file only tracks *arrival*.
- **Mechanical mount/measure/confirm status** (does it fit, is it installed) is owned by the
  3D/fabrication repo `w17-3d-codex` (Claude Code territory, but its own git repo):
  `w17-3d-codex/GENERAL_PLAN.md` item 5 and
  `w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md`
  (HAND / TRANSIT / CONFIRMED flags). This file records *"it physically arrived on date X"*;
  those record *"it has been measured / it mounts here."* Edit those in their own repo — not as
  part of a workspace-doc change (one repo at a time).

## Legend

| Mark | Meaning |
|---|---|
| ✅ | On hand (arrived) |
| ⏳ | Ordered / in transit / awaited |
| 🏠 | Local stock / owned (not an AliExpress line) |
| ❓ | Arrived, but BOM mapping needs a physical confirm (see "Mappings to confirm") |
| ⬜ | Not yet ordered / TBD |

---

## On-hand status — by BOM section

### A. AliExpress order

**§1 Video / FPV**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| BL-M8812EU2 USB WiFi module | ×1 | ✅ | 2026-07-17 | camera's 5.8 GHz video-link radio |
| 5.8 GHz U.FL omni antennas (70 mm / 5 pcs) | ×1 | ✅ | 2026-07-21 | "wifi antennas"; fit to J0/J1 before power |
| Heatsink 28×28×3 mm | ×1 | ✅ | 2026-07-21 | "cooling heatsink for wifi module" |
| FT232RL USB-UART | ×1 | ✅ | 2026-07-21 | "ftdi"; camera console/flash + PC↔ELRS CRSF (set 3.3 V jumper) |
| Camera — OpenIPC SSC338Q | ×1 | 🏠 | owned | already flashed + tuned |

**§2 Control / Radio**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| RadioMaster RP1 ELRS receiver | ×1 | ✅ | 2026-07-21 | "rp1-v2 rx"; **CRSF input source** for w17-control-fw |
| ES24TX Pro (or nano) ELRS TX module | ×1 | ✅ | 2026-07-17 | "ELRS TX" |
| Transmitters (DualShock via PC + TX16S) | — | 🏠 | owned | |

**§3 Drive / ESC / Motor**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Hobbywing QuicRun 10BL120 + Rocket 540 combo | ×1 | ⏳ | — | **Not in any delivery yet.** Biggest single line (~⅓ of spend) and the gate for Phase C motor work. |

**§4 Brains / Audio / Light**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| ESP32-WROOM-32 DevKit V1 (3 pcs) | ×1 | ✅ | 2026-07-17 | #1 control + #2 sound/light + 1 spare |
| MAX98357A I2S amplifier | ×1 | ✅ | 2026-07-21 | "amplifier interface" |
| Speaker 4 Ω 3 W | ×1 | ✅ | 2026-07-21 | "speaker" |
| WS2812B LED strip (1 m / 30 LED) | ×1 | ✅ | 2026-07-21 | "led strip" |

→ **Soundlight-fw bench hardware is now complete** (ESP32 + I2S amp + speaker + WS2812B).

**§5 Power / Telemetry**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| UBEC 5 A (2 pcs) | ×1 | ✅ | 2026-07-21 | "ubec x2"; Rail A (clean) + Rail B (servos) |
| XT connectors (XT30 + XT60) | ×2 lines | ⬜ | — | not mentioned; may be local stock |
| BX100 voltage buzzer | ×1 | ❓ | 2026-07-17 | logged as "LiPo voltage tester" — confirm whether that = BX100 or a separate cell checker |
| Resistor kit (600 pcs) | ×1 | ✅ | 2026-07-17 | 330 Ω / 10 kΩ / 27 kΩ for LED + Hall pull-up + divider |

**§6 Servos**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| DS3235SG steering servo (35 kg-class) | ×1 | ✅ | 2026-07-21 | "35kg servo set (servo + thing it rotates)" — the "thing" = 25T horn |
| MG90S micro servos (3 pcs) | ×1 | ⏳ | — | pan / tilt / DRS — **not in this drop** |

**§7 Speed sensor**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| A3144 Hall sensor (10 pcs) | ×1 | ✅ | 2026-07-21 | "Hall Effect Sensor x10" |
| Neodymium magnets 3×1 mm (20 pcs) | ×1 | ⏳ | — | **not arrived** — the Hall pickup needs these to be exercised |

**§8 Drivetrain**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Belt-drive full set (pulleys + 140 mm belt) | ×1 | ✅ | 2026-07-21 | "belt drive set"; includes the rear output shaft |
| Pinion 48DP 28T | ×1 | ✅ | 2026-07-21 | "alloy metal pinion motor gear" |
| Spur 3Racing Sakura 48P 75T | ×1 | ✅ | 2026-07-21 | "spur gear" — confirm bolt holes match belt-set pulley (BOM open confirm #1) |

**§9 Bearings**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| MR128ZZ front bearings (10 pcs) | ×1 | ✅ | 2026-07-17 | |
| APE 6801 rear bearings 12×21×5 ZZ (5 pcs) | ×1 | ✅ | 2026-07-21 | "bearing 6801 ZZ (metal seal) x5" |

**§10 Suspension**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Front oil shocks 52 mm (4-set) | ×1 | ✅ | 2026-07-21 | "52 mm shock absorbers set" |
| Rear oil shock 68 mm (2 pc) | ×1 | ⏳ | — | central rear damper — **not mentioned; likely still outstanding** |

**§11 Steering**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| M4 fully-threaded rod (40 mm / 10 pcs) | ×1 | ✅ | 2026-07-17 | "steel threaded rods" |
| M4 rod-end ball joints (24 mm / 10 pcs) | ×1 | ✅ | 2026-07-17 | "M4 rod-end linkage balls ×10" |
| Turnbuckles 3×32 mm | ×2? | ✅ | 2026-07-17 + 2026-07-21 | one on the 17th + one on the 21st ("Metal 3x32mm Turnbuckle Shaft Link") = the wanted 1 + crash-spare |
| King pins (dowel pin + circlip) M3 / 30 mm (5 pcs) | ×1 | ❓ | 2026-07-21 | assumed = "flat head bearing m3 30mm x5" (exact spec match) — **confirm** |
| M3 ball studs (10 pcs) | ×1 | ⬜ | — | not clearly identified in either delivery |
| M3 tie-rod ends (3Racing set) | ×1 | ❓ | 2026-07-17 | assumed = "M3 tie-rod-end ball caps" — confirm |

**§12 Fasteners / hardware**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Countersunk M3 bolt + nut kit (392 pcs) | ×1 | ✅ | 2026-07-21 | "m3 bolt nut set" |
| Heat-set brass inserts M3 × 5 mm (50 pcs) | ×1 | ✅ | 2026-07-21 | "m3 5mm insert nut" |
| Metal sleeves D5 × M3 / 5 mm (20 pcs) | ×1 | ❓ | 2026-07-21 | logged as "flat washer gasket (D5x M3, 20pcs, 5mm)" — spec matches the BOM sleeves; confirm washer vs sleeve |
| Aluminium tube OD16 × ID14 / 300 mm | ×1 | ✅ | 2026-07-17 | cut into rear-axle spacers |

**§13 Cooling (camera)**
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Blower fan 5 V 20 mm | ×1 | ✅ | 2026-07-21 | "turbine cooler" |
| Thermal paste (15 g) | ×1 | ⏳ | — | not mentioned |

### B. rcMart order (genuine Tamiya tyres)
| Item (BOM) | Exp. qty | Status | Arrived | Notes |
|---|---|---|---|---|
| Tamiya 54198 F104 front tyres | 1 pack | ⏳ | — | |
| Tamiya 51400 F104 rear tyres | 1 pack | ⏳ | — | |

### D. Local / stock / not-an-AliExpress-line
| Item | Status | Notes |
|---|---|---|
| 2S LiPo ×2 (soft-case, ≤75×45×25 mm, XT60) | ⬜ | sourced locally; on-hand status not confirmed here |
| RT5370 USB Wi-Fi (GS bench SoftAP) | ⏳ | tracked in `CURRENT_STATUS.md`; AP-mode support to verify on arrival |
| Build-from-stock, consumables, tools, paint, decals | 🏠 | see BOM §D — not delivery-tracked |

---

## Notable gaps — what to chase next

Ranked by how much they block downstream work:

1. **ESC + motor combo (§3)** — ⏳ not arrived. Blocks all Phase C (powered drivetrain) work; biggest-ticket line.
2. **MG90S micro servos ×3 (§6)** — ⏳ pan / tilt / DRS actuators absent (steering servo did arrive).
3. **Neodymium magnets (§7)** — ⏳ the A3144 Hall sensor arrived but can't be exercised without its axle magnets.
4. **Rear oil shock 68 mm (§10)** — ⏳ only the front 52 mm set arrived.
5. **Tamiya tyres (§B)** — ⏳ full rcMart order still out.
6. **RT5370 USB Wi-Fi** — ⏳ bench SoftAP for the ground-station network validation.
7. Minor / confirm: thermal paste (§13), XT connectors (§5), M3 ball studs (§11).

---

## Delivery log (newest first)

### 2026-07-21 — major mechanical + electronics drop
Owner's arrival list (verbatim), with BOM mapping:

| As delivered (owner's words) | BOM line | § |
|---|---|---|
| spur gear | Spur 3Racing Sakura 48P 75T | §8 |
| speaker | Speaker 4 Ω 3 W | §4 |
| wifi antennas | 5.8 GHz U.FL omni antennas 70 mm | §1 |
| alloy metal pinion motor gear | Pinion 48DP 28T | §8 |
| belt drive set | Belt-drive full set | §8 |
| ftdi | FT232RL USB-UART | §1 |
| ubec x2 | UBEC 5 A (2 pcs) | §5 |
| flat washer gasket (D5x M3, 20pcs, 5mm) | Metal sleeves D5×M3 5 mm ❓ | §12 |
| 52 mm shock absorbers set | Front oil shocks 52 mm 4-set | §10 |
| cooling heatsink for wifi module | Heatsink 28×28×3 mm | §1 |
| rp1-v2 rx | RadioMaster RP1 ELRS receiver | §2 |
| bearing 6801 ZZ (metal seal) x5 | APE 6801 rear bearings ZZ | §9 |
| m3 5mm insert nut | Heat-set brass inserts M3×5 mm | §12 |
| Hall Effect Sensor x10 | A3144 Hall sensor (10 pcs) | §7 |
| Metal 3x32mm Turnbuckle Shaft Link | Turnbuckle 3×32 mm (2nd of 2) | §11 |
| led strip | WS2812B LED strip | §4 |
| turbine cooler | Blower fan 5 V 20 mm | §13 |
| amplifier interface | MAX98357A I2S amplifier | §4 |
| 35kg servo set (servo + thing it rotates) | DS3235SG steering servo (+ 25T horn) | §6 |
| m3 bolt nut set | Countersunk M3 bolt + nut kit | §12 |
| flat head bearing m3 30mm x5 | King pins M3 / 30 mm (5 pcs) ❓ | §11 |

This drop **cleared 5 of the 7 mechanical items** that were "still awaited" as of 2026-07-17
(shocks, servos [steering], belt set, rear 6801 bearings, blower) and landed the core control +
sound/light electronics (RP1 rx, FTDI, UBEC ×2, Hall sensor, amp, speaker, LED strip).

### 2026-07-17 — first partial delivery
(Recorded in `CURRENT_STATUS.md`, 2026-07-17 entry; mechanical items also in
`w17-3d-codex/GENERAL_PLAN.md` item 5.)

- **Electronics:** 3× ESP32 DevKit (§4) · BL-M8812EU2 WiFi module (§1) · ELRS TX (§2) ·
  LiPo voltage tester (≈ BX100? §5 ❓) · resistor kit (§5).
- **Mechanical:** MR128ZZ front bearings ×10 (§9) · 3×32 mm turnbuckle (§11) · M4 rod-end
  balls ×10 (§11) · M3 tie-rod-end ball caps (§11 ❓) · steel threaded rods (§11) ·
  aluminium tube (§12).

---

## Mappings to confirm (owner: a quick eyeball closes these)

These arrived but the owner's description didn't 1:1 match a BOM name; the spec matched, so
they're logged as ❓ pending a physical check:

1. **"flat head bearing m3 30mm x5" → King pins (§11)?** Spec (M3 / 30 mm / 5 pcs) is a dead-on
   match to the BOM king-pin line. If instead these are a distinct M3×30 shoulder/flat-head
   bolt, the king pins are still outstanding.
2. **"flat washer gasket (D5x M3, 20pcs, 5mm)" → Metal sleeves D5×M3 (§12)?** Spec matches the
   BOM's front guide-rod sleeves; "washer" vs "sleeve" wording differs.
3. **"LiPo voltage tester" (07-17) → BX100 buzzer (§5)?** Could be the BX100 low-voltage alarm
   or a separate cell checker.
4. **"M3 tie-rod-end ball caps" (07-17) → M3 tie-rod ends 3Racing set (§11)?** vs. the separate
   M3 ball studs line, which may still be outstanding.

---

## Cross-references

- Buy-list / part identities: `w17-control-fw/docs/bill_of_materials_v2.md`
- Software / gate / CI status: `CURRENT_STATUS.md` (2026-07-17 delivery entries; A2 / Phase B gates)
- Mechanical mount/measure status (in `w17-3d-codex`, its own repo):
  `w17-3d-codex/GENERAL_PLAN.md` item 5 · `w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md`
- Bring-up procedures: `learning-manual/13_bare_board_smoke_test.md` ·
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` ·
  `w17-control-fw/docs/D8_BENCH_BRINGUP.md`

> **No hardware gate changes from this delivery.** A2 remains unexecuted, Phase B remains
> blocked, and the no-unattended-powering rule stands. Only the owner-approved bare-board USB
> smoke test (naked DevKit, nothing on pins, attended) is permitted. Parts *availability* is
> recorded here; *execution* status stays in `CURRENT_STATUS.md`.
