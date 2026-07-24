# W17 electrical inputs for Codex (PDB, charge module, ESP SKU, connector map)

These are the Claude-side inputs the ZK cassette study is waiting on. Firm values are marked
[FIRM]; targets to pocket-and-refine are [TARGET]; not-yet-selected are [TBD].

## 1. ESP boards — SKU [FIRM]
Both ESP32 #1 (control) and #2 (sound/light) = **MH-ET Live ESP32 MiniKit / "D1 Mini ESP32"**
(ESP32-**WROOM-32**, dual-core; ~**39 × 31 mm**; onboard micro-USB serial; 24 GPIO, all usable
incl. input-only 34/35). Firmware + pin map unchanged. Envelope for pocketing: **39 × 31 × ~13 mm**
(with headers); micro-USB on one short edge → face it to a service edge. NOT a C3/S2/S3 SuperMini.

## 2. Power-distribution board (PDB) — [TARGET envelope, FIRM contents]
One board in the cassette lower bay. Contents:
- Battery in: **XT60**. Master **loop key / switch**.
- **2× UBEC 5 A**: Rail A (clean) + Rail B (servos). **1000 µF** cap across Rail B.
- **27 k / 10 k divider**: battery → tap to ESP32 #1 GPIO34 (monitoring only).
- **USB-C charge in → 2S balance charge module** (see §3) with a **charge/run interlock**
  (run load isolated while charging — simplest: loop key OFF position feeds charger only).
- **Common-ground STAR** node; keyed output headers per consumer (see §4).
- Envelope [TARGET]: **~55 × 45 mm board, ~18 mm tall** (UBEC height dominates), **~50 g** with the
  two UBECs + cap. Refine after component placement — treat as a parametric pocket for now.
- Mounting: 4× M3 to the cassette lower-bay floor; keep UBEC/cap tall parts to one side for airflow.

## 3. Battery + onboard charge module — [charger PICKED; battery class FIRM, SKU = local buy]

**Battery** [class FIRM]: 2S LiPo, **soft-case, ≤75 × 45 × 25 mm**, XT60 main + **JST-XH 2S balance
lead** (required by the balancing charger), ~1300–1500 mAh, ~25–35C (gentle use needs no high C).
Charge conservatively at ~0.5C (≈0.7–0.75 A). Exact pack is a local buy — keep the envelope + the
balance connector.

**Charge module** [PICKED]: a **Type-C 2S charge/boost module with cell balancing**, charging the
pack from **plain 5 V / Type-C** (internal boost) and balancing the two cells — **no PD trigger**.
- UA-sourceable primary: **IP2326** module (Type-C, 8.4 V, ≤1.5 A, automatic cell balancing + OV
  protection; commodity on AliExpress → Ukraine). Many are fixed ~1.5 A (≈1C for a 1500 mAh pack —
  acceptable); pick an adjustable one for ~0.5C if available.
- Premium reference: **BQ25887 / MikroE Balancer 5 Click** (~28.6 × 25.4 mm; PSEL/ILIM current set,
  optional I2C telemetry to an ESP32).
Envelope for pocketing: **~29 × 26 × ~6 mm**. Needs: 5 V
from the USB-C receptacle, the pack's XT60 + JST-XH balance lead, and the **charge/run interlock**
(loop key OFF = charger-only path; run load isolated while charging).
- **Verify** the board is genuinely BQ25887 (balancing). Many cheap "2S USB" boards only boost + CV
  with NO balancing — do not use those.
- A 5 V / ≥2 A USB-C source covers 0.5C charging; charging is powered work → gated by A2/Phase-B.

## 4. Connector map — [FIRM] (rails: A = clean, B = servos; all grounds common)
| Link | From → To | Signals | Connector |
|---|---|---|---|
| Battery main | Pack → PDB | +, − | XT60 |
| USB-C charge | port → PDB | 5 V, D±/CC | USB-C receptacle (hidden/reversible port) |
| Pack balance | Pack → charge module | 2S balance | JST-XH 3-pin |
| Rail A bus | PDB → clean loads | 5 V, GND | XT30 (or keyed 2-pin) per branch |
| Rail B bus | PDB → servo loads | 5 V, GND | XT30 |
| CRSF | RP1 ↔ ESP32 #1 | RP1_TX→GPIO16, GPIO17→RP1_RX, 5 V, GND | JST-XH 4-pin |
| link2 | ESP32 #1 → #2 | GPIO25→GPIO16(#2), (opt) GPIO26←GPIO17(#2), GND | JST-XH 3-pin |
| Steering servo | ESP32 #1 GPIO13 | sig, +5 V(B), GND | 3-pin servo (JR) |
| ESC signal | ESP32 #1 GPIO14 → ESC | sig, GND only (**ESC BEC +5 V isolated**) | 3-pin servo, +5 V pin removed |
| DRS servo | ESP32 #1 GPIO18 | sig, +5 V(B), GND | 3-pin servo |
| Gimbal pan / tilt | ESP32 #1 GPIO19 / 23 | sig, +5 V(B), GND | 2× 3-pin servo (through the pedestal conduit) |
| Blower | Rail B | +5 V, GND (always-on) | 2-pin (JST) |
| I2S audio | ESP32 #2 → MAX98357A | BCLK26, LRCLK25, DIN22, +5 V(A), GND | JST-XH 5-pin |
| Speaker | amp → speaker | +, − | JST-PH 2-pin |
| LEDs | ESP32 #2 GPIO4 → WS2812B | data, +5 V(A), GND | JST-XH 3-pin |
| Hall | sensor → ESP32 #1 GPIO35 | sig, +5 V(A), GND (10 k pull-up to 3V3 on board) | JST-XH 3-pin |
| Camera ↔ WiFi | camera → BL-M8812EU2 | D+→DP, D−→DM, +5 V(A), GND | shielded 4-pin / micro-USB (short) |
| Antennas | WiFi module → antennas | RF | U.FL (×J0/J1) |

Rules: power connectors polarized + visually distinct from signal; **source side = shrouded/socket**
(no exposed live pins); color-code + label every connector. The **umbilical** gangs the fixed-consumer
leads (steering, ESC, DRS, LED, Hall + the pedestal's pan/tilt + camera USB) into one dock at the
cassette, routed via the R1/R2 edge corridors.

## Notes for the fit dummy
- The camera↔WiFi USB and the pan/tilt leads run up through the hollow pedestal conduit — size the
  conduit for a 4-pin shielded USB + 2× 3-pin servo bundle + service slack.
- Charge/run interlock is electrical, but Codex should leave finger access to the loop key body-on
  or via the hidden port.
