# W17 PDB build + connector proposal + soldering guide

**Date:** 2026-07-24 · **Owner:** Claude Code (electrical/firmware side; PDB schematic + connector map
is "Claude's side" per the packaging architecture). Physical routing / dock / conduit geometry is
**Codex** (`w17-3d-codex`, CAS-09/10). **NO POWER** — this is a build spec; nothing is energized until
**A2 passes and Phase B is approved**. Pins are transcribed from the authoritative headers
`w17-control-fw/lib/config/include/config/PinMap.hpp` and the soundlight `PinMap.hpp` — **reconcile
against those headers before soldering**, not against this table.

> **Revised 2026-08-04** — closing the A2 adversarial review
> (`w17-control-fw/project-review/14_a2_staged_gates_adversarial_review.md`): §5's build order
> now **is** the A2 S-gate order (divider before UBECs — F8); the IP2326 charger is **not fitted
> during A2 build week** and taps the **pack side** of the XT90-S (owner decisions F9a/F9b); the
> Hall pull-up lives **at the ESP32 #1 end** (F11); the optional link2 RX conductor is struck
> (F13.4, closed decision C4).

---

## 1. Power topology (one picture)

```
2S LiPo (XT60) ──┬──> XT90-S anti-spark (MASTER, body-accessible) ──> PDB input (XT60)
                 │                                                        │
   [PACK side]   └──< IP2326 2S balance charger <── USB-C (hidden)        │
                      (+ JST-XH balance to the pack lead)                 │
                      [charge path — taps the PACK side of the master     │
                       switch (owner decision 2026-08-03/F9b), lives      │
                       OFF the PDB; NOT fitted during A2 build week      │
                       (F9a); owns its own no-power gate]                 │
                                                                          │
        PDB star node splits the switched battery to:
          ├── ESC (12AWG, direct, high current)   [floor, off-cassette]
          ├── UBEC A (5V "clean")  ──> Rail A
          └── UBEC B (5V "servos") ──> Rail B  (+1000µF across B)
```

- **Rail A (clean):** BL-M8812EU2 Wi-Fi + camera 5V, ESP32 #1, ESP32 #2, RP1, WS2812 LEDs,
  MAX98357A, A3144 Hall VCC.
- **Rail B (servos):** DS3235SG steering, MG90S ×3 (DRS/pan/tilt), blower.
- **Charge/run interlock:** pull the XT90-S (car off) = safe to charge over USB-C — real
  **precisely because the charger taps the pack side of the master switch** (decision
  2026-08-03/F9b; a PDB-side tap would have made this interlock a false safety story). Run load
  is dead while charging. (Charging itself is **Phase-B gated**, and the charge path is **not
  built during A2 build week** — F9a.)

---

## 2. Connector proposal (genders, type, length)

**Gender rule (power):** the always-live / source side is **female/socket** (recessed, no exposed live
pins). **Signal connectors** (servo 3-pin, JST-XH) keep their **standard** convention (on-board = male
shrouded header; harness lead = female housing). Every connector: **color-coded + labelled**; red = +,
black = −. **Cable lengths are PROPOSALS** — Codex finalizes them against the cassette CAD + dock.

| Link | From → To | Signals | Connector | Gender (source→consumer) | Proposed length |
|---|---|---|---|---|---|
| Battery main | Pack → PDB | +, − | XT60 | pack = **female** → PDB = male | 120–180 mm |
| Master switch | inline on battery + lead | + (switched) | **XT90-S anti-spark** | female faces pack (live) | at pack lead |
| USB-C charge | hidden port → IP2326 **(pack side of the master, off-PDB — F9b; deferred, not built in A2 week — F9a)** | 5V, CC/D± | USB-C receptacle | car = **female** (IP2326 onboard C) | 100–150 mm |
| Pack balance | Pack → IP2326 **(deferred with the charge path — F9a)** | 2S balance | JST-XH 3-pin | pack lead = female | 80–120 mm |
| Rail A branch | PDB → clean loads | 5V(A), GND | XT30 (or keyed 2-pin) | PDB = **female** → load = male | 50–100 mm ea |
| Rail B branch | PDB → servo loads | 5V(B), GND | XT30 | PDB = **female** → load = male | 50–100 mm ea |
| CRSF | RP1 ↔ ESP32 #1 | RP1_TX→GPIO16, GPIO17→RP1_RX, 5V(A), GND | JST-XH 4-pin | board = male hdr → harness = female | 60–80 mm (both in cassette) |
| link2 | ESP32 #1 → #2 | GPIO25→GPIO16(#2), GND — **no RX conductor: GPIO26 stays unwired by design** (closed decision C4; A2 §13 stop 9 — a wire here is a hard stop) | JST-XH 3-pin (RX position left empty) | board = male hdr → harness = female | 60 mm (both in cassette) |
| Steering | ESP32 #1 GPIO13 → DS3235SG | sig, +5V(B), GND | 3-pin servo (JR) | board = male hdr → servo = female | 180–220 mm (front axle) |
| ESC signal | ESP32 #1 GPIO14 → ESC | **sig, GND only** (+5V BEC red CUT) | 3-pin servo, +5V pin removed | board = male hdr → ESC = female | 120–160 mm |
| DRS | ESP32 #1 GPIO18 → MG90S | sig, +5V(B), GND | 3-pin servo | board = male hdr → servo = female | 250–350 mm (rear wing) |
| Gimbal pan / tilt | ESP32 #1 GPIO19 / 23 → 2× MG90S | sig, +5V(B), GND | 2× 3-pin servo | board = male hdr → servo = female | 120–150 mm + 25 mm service loop (via pedestal) |
| Blower | Rail B → blower | +5V(B), GND (always-on) | 2-pin JST | PDB = female → blower = male | 150 mm (via pedestal) |
| I2S audio | ESP32 #2 → MAX98357A | BCLK26, LRCLK25, DIN22, +5V(A), GND | JST-XH 5-pin | board = male hdr → amp = female | 50–80 mm (both in cassette) |
| Speaker | amp → speaker | +, − | JST-PH 2-pin | amp = male hdr → speaker = female | 100–150 mm |
| LEDs | ESP32 #2 GPIO4 → WS2812B | data (via 330Ω), +5V(A), GND | JST-XH 3-pin | board = male hdr → strip = female | 100 mm to strip start |
| Hall | A3144 → ESP32 #1 GPIO35 | sig, +5V(A), GND — **10k pull-up→3V3 at the ESP32 #1 end** (owner decision 2026-08-03/F11: the lead has no 3V3 conductor, so a sensor-side pull-up is unbuildable; A2 rows H1/H1b measure it) | JST-XH 3-pin | board = male hdr → sensor = female | 150–200 mm (rear axle) |
| Camera ↔ Wi-Fi | camera → BL-M8812EU2 | D+, D−, +5V(A), GND | shielded 4-pin / micro-USB (short) | per module | 150 mm (via pedestal) |
| Antennas | Wi-Fi → antennas | RF | U.FL (×2, J0/J1) | module = jack | pigtails as supplied |

**Connectors likely still to source:** JST-XH 3/4/5-pin set (CRSF/link2/balance/LED/Hall/I2S) if not in
stock; XT30 for the rail branches; USB-C access (use the IP2326's onboard Type-C via a hidden port, or a
short panel-mount USB-C extension). XT60 you have; 3-pin servo leads come with the servos; U.FL is on the
Wi-Fi module.

---

## 3. What lives where (don't solder a part on the wrong board)

| Component | Board / location |
|---|---|
| 2× UBEC, 1000 µF (Rail B), 27k/10k divider, star ground, XT60 in, rail/signal output headers, ESP32 female header sockets | **PDB** (cassette lower bay) |
| IP2326 charger + hidden USB-C + balance extension | **pack side of the XT90-S master switch, OFF the PDB** (owner decision 2026-08-03/F9b) — **not fitted during A2 build week** (F9a); the charge path owns its own no-power gate |
| 100 nF battery-sense filter | **at ESP32 #1 GPIO34 pin** (see §4; A2 F13.3 — this placement wins, fitted at A2 gate S4) |
| A3144 Hall (rear axle) + optional 1–10 nF at the pin; **10k pull-up (to 3V3) at the ESP32 #1 end** (owner decision 2026-08-03/F11) | **sensor at the rear axle; pull-up at ESP32 #1** |
| 330 Ω LED series + **1000 µF (LED)** + **1N5819** | **soundlight side**, at the WS2812 strip input |
| MAX98357A, speaker | soundlight audio |
| ESC red +5V wire **cut + insulated** | **at the ESC servo lead** |

---

## 4. Capacitor placement — where each one goes and why (your specific question)

Electrolytics are **polarized** (stripe = the **negative** lead → goes to GND). Ceramics are not.

| Cap | Value | Solder location | Polarity | Purpose |
|---|---|---|---|---|
| **C1** | 1000 µF ≥16 V | **PDB**, across **Rail B (+5V ↔ GND)**, close to the servo output headers / UBEC-B out. **Lay flat** (8–10 mm profile) | stripe → GND | absorbs DS3235SG stall spikes (rail sag on steering) |
| **C2** | 1000 µF ≥16 V | **Soundlight**, across the **WS2812 strip 5V ↔ GND at the first LED** (strip input) | stripe → GND | LED inrush reservoir; steadies the strip rail |
| **C3** | 100 nF ceramic | **At ESP32 #1 GPIO34 ↔ GND**, as close to the pin as possible (the divider is on the PDB; run the tap wire to GPIO34 and put C3 right at the pin) | none | filters the high-impedance (~7.3 kΩ) divider so battery ADC reads aren't noisy |
| **C4** (optional, ×2) | 100 nF ceramic | Across each **ESP32 5V ↔ GND** near the module | none | general decoupling — good practice, cheap insurance |
| **C5** (optional) | 1–10 nF ceramic | **ESP32 #1 GPIO35 ↔ GND** (Hall output), near the pin | none | **only if** the bench scope shows wheel-pulse double-counts (R18) — leave off otherwise |

Also on the LED line (not a cap): **1N5819** in series on the strip **VDD** (5V → strip VDD), **band
toward the strip** — drops ~0.3 V so the ESP32's 3.3 V data reads as a valid logic-high at the strip.

---

## 5. PDB build order + soldering notes

> **Order revised 2026-08-04 (A2 review F8).** The previous list built the UBECs at step 3 and
> the divider at step 5 — following it lands the builder at A2 gate S1 with both UBECs already
> on the batt+ node, where the divider's 37 kΩ row reads an unpredictable composite: a
> **false FAIL on a correctly built board**. The order below **is** the A2 gate order
> (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`); each step names its
> gate — run the gate before starting the next step.

1. **Plan the board flat** first (paper/CAD): UBECs side-by-side (each 44.3 × 22.1, 9.1 tall), 1000 µF
   C1 flat, XT60 in, divider corner, star-ground node central, output headers along the service edge.
   **Before the first joint, two owed bench measurements** (A2 §2/§3): caliper the ESP32
   female-header socket stack against the ZK cassette clearance "S0" ≥ 9.82 mm (the socketing
   decision is conditional on it), and derive the adjacent-pin list from the **MH-ET silkscreen**.
2. **PDB frame — A2 gate S0:** solder the XT60 input; establish **one** common-ground **star** node —
   battery −, both UBEC GND, ESC GND, and every output-connector GND meet **here, at one point** (a
   floating/split ground is the worst UART failure mode — link2 + CRSF both depend on it). Solder both
   ESP32 **female header sockets** (boards out), the Rail A / Rail B output headers (XT30, source =
   female sockets), the signal headers (servo 3-pin, JST-XH per §2), and the rail branch looms.
   Colour + label everything. **Run S0.**
3. **Divider — A2 gate S1:** 27 kΩ from **raw battery +** (pre-UBEC) to the tap node; 10 kΩ tap → GND;
   tap → a wire out to ESP32 #1 **GPIO34**. **C3 (100 nF) goes at the GPIO34 pin end and is fitted
   with the board-end wiring at S4-time, not here** (A2 F13.3). **Run S1 — the UBECs must not exist
   on the batt+ node yet.**
4. **Harness leads — A2 gates S2 / S3 / S4 / S4b, one lead at a time:** Hall (with the board-end 10k
   pull-up GPIO35→3V3 — F11), link2, CRSF, the five actuator leads, C3 at the pin. **The ESC lead fix
   (HARD GATE) happens here:** on the ESC's 3-wire servo lead, **cut the RED (+5 V BEC) wire, run A2
   gate S8a on the bare ends — rows and photos BEFORE insulating — then insulate both ends
   individually.** Only **signal (→GPIO14)** and **GND** connect. (A ~6 V BEC back-feeding the UBEC
   rail damages the ESC / over-volts the rail.)
5. **WS2812 path — A2 gate S5** (soundlight side: 330 Ω series, 1N5819, C2 per §4).
6. **batt+ consumers — A2 gate S6, in one sitting:** both UBEC inputs parallel to battery+ (switched
   side); UBEC-A out = Rail A, UBEC-B out = Rail B; the **ESC 12 AWG direct feed**; and **C1
   (1000 µF) across Rail B**, stripe → GND, laid flat — **C1 waits until this step** so every earlier
   rail reading is a clean OPEN (A2 F16).
7. **Whole-harness gates S7 and S8b** close the build: grounds, the batt+/rail composite screens, the
   mated master-switch pigtail rows, and the ESC-header +5-position check.
8. ~~**Charger:** wire IP2326 — USB-C in (hidden port), output to pack, **JST-XH balance** to the
   pack's balance lead; set the **2S jumper** and charge current ≤ 1.5 A.~~ **STRUCK 2026-08-04
   (owner decision F9a):** the IP2326 is **not fitted during A2 build week**. The charge path is
   deferred behind its own no-power gate and taps the **pack side** of the XT90-S (F9b — see §1).
   The 2S jumper + ≤ 1.5 A settings move to that gate's checklist when it is written.

**Soldering technique / safety**
- Tin pads and wire tips first; keep joints shiny, not blobby; no bridges between adjacent header pins.
  ⚠ The old call-out "16/17, 25/26, 18/19 are close" was derived from the **DevKit V1** layout; the
  build boards are **MH-ET Live D1-Minis** and the true adjacent-pair list is **owed from the MH-ET
  silkscreen** (A2 review F12) — until it exists, beeper-check **every** header joint.
- **Heat-shrink every power joint**; the cut ESC red end must be individually insulated (not folded
  bare) — **but only after A2 gate S8a's rows and photos are taken on the bare ends**.
- **Electrolytic polarity** matters (C1/C2): stripe = negative → GND. Reversed = it vents/pops.
- **Battery re-termination to XT60:** one lead at a time, never both bare at once; heat-shrink each;
  keep the iron away from the other lead. (Applies to whichever in-envelope car pack is eventually
  sourced — **none exists on hand as of 2026-07-31**, `HARDWARE_INVENTORY.md` §E.)
- **A2 is not a gate after this build — it IS this build:** the S-gates run interleaved with steps
  2–7 above, and **nothing gets powered until A2 passes and Phase B is approved.**

---

## 6. Pin reference (authoritative source: PinMap.hpp — verify there)

**ESP32 #1 (control):** CRSF RX 16 / TX 17 · link2 TX 25 / RX 26 · steering 13 · ESC 14 · DRS 18 ·
pan 19 · tilt 23 · battery ADC 34 (input-only) · Hall 35 (input-only, 10k→3V3).
**ESP32 #2 (soundlight):** link2 RX 16 (TX 17 reserved) · I2S BCLK 26 / LRCLK 25 / DIN 22 · WS2812 4.

GPIO 34/35 are **input-only** (no pull-ups, no output). Avoid strapping pins 0/2/12/15 and flash 6–11.
