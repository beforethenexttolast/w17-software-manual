# 01 — System Overview

> **Evidence convention used throughout:**
> **[C]** = Confirmed — stated directly in a repo document or visible in code, source cited.
> **[I]** = Inferred — deduced from evidence, chain explained.
> **[A]** = Assumption — plausible but must be verified with you or on the bench.

## 1. What the project is

**[C]** A **1/10-scale FPV (first-person-view) 3D-printed RC Formula 1 car** in Mercedes
W17 livery (#63 Russell), built on a belt-drive OpenRC F1 chassis ("RC-01"), intended as a
gift with a hard deadline of **21 July 2026**.
Source: `w17-control-fw/CLAUDE.md` §0; `docs/00_BUILD_SHEET.md`; `docs/bill_of_materials_v2.md`.

**[C]** The electronics architecture is: **two ESP32-WROOM-32 DevKit V1 boards on the car**
plus a **laptop-side ground station**. Board #1 ("control") is the authority for everything
safety- and motion-related; board #2 ("sound + light") is a purely cosmetic consumer of
board #1's state; the ground station is deliberately **viewer-only** and cannot command the
car. Sources: `w17-control-fw/CLAUDE.md` §0, `w17-soundlight-fw/CLAUDE.md`,
`w17-ground-station/README.md` ("Viewer only — it does NOT drive the car").

**[C]** As of `docs/ROADMAP.md` (status date 2026-07-02, entries through 2026-07-03), **all
planned firmware and ground-station software is written and unit-tested** (147 native tests
in control-fw, 40 in soundlight-fw, 20 vitest in ground-station), but **hardware bring-up
(bench phase D8) has not happened yet** — the BOM says "Nothing printed yet" and D8 is
"gated on parts." So today the project is in the "software done, hardware pending" state.

## 2. What each repository does

### 2.1 `w17-control-fw` — ESP32 #1 "Control board" (the main module)

**[C]** (all from `w17-control-fw/CLAUDE.md` and confirmed in `src/main.cpp` includes/loop):

- Receives the radio control stream: **CRSF protocol** frames from a RadioMaster RP1
  ExpressLRS (ELRS) receiver over UART2 at 420,000 baud.
- Decodes 16 RC channels, maps them to named controls (steering, throttle, arm switch,
  DRS, gear up/down, boost, overtake, drive mode, pan, tilt).
- Runs the **safety logic**: failsafe state machine (link loss → outputs safe) and the
  arm gate (throttle stays neutral until armed AND stick seen at neutral).
- Runs the **"feel" logic**: a virtual gearbox (per-gear throttle caps + expo curves)
  and an ERS energy system (boost/overtake deploy, brake/coast harvest).
- Drives the actuators with 50 Hz servo PWM: steering servo, ESC (motor controller),
  DRS wing servo, camera gimbal pan/tilt servos.
- Reads sensors: battery voltage (ADC + resistor divider) and wheel speed (Hall sensor
  pulses via interrupt).
- Reports state **downstream** to board #2 over the one-way **link2 UART protocol**
  (20 Hz, 14-byte frames) and **upstream** to the ground over the ELRS telemetry
  backchannel (CRSF battery/GPS/flight-mode frames at ~5 Hz).
- Optional bench-only serial tuning console with settings persisted to flash (NVS).

**[C]** It also *owns the shared artifacts*: the link2 protocol spec
(`docs/link2_protocol.md` — "the control repo owns it" per `w17-soundlight-fw/README.md`)
and the golden CRSF test vectors reused by the ground station
(`w17-ground-station/docs/TELEMETRY.md` last paragraph).

### 2.2 `w17-soundlight-fw` — ESP32 #2 "Sound + light board"

**[C]** (from `w17-soundlight-fw/CLAUDE.md` and `README.md`):

- Consumes the one-way link2 UART stream from board #1 (its GPIO16 RX).
- **Engine sound**: a virtual engine model (`enginesim`: RPM inertia, ignition state
  machine Off/Cranking/Running, rev limiter, gear-shift blips, overrun crackle) feeding a
  procedural **V10-flavored synthesizer** (`soundsynth`: wavetable harmonic stack, noise,
  ERS whine), output via **I2S** to a MAX98357A amplifier and a 4 Ω 3 W speaker.
- **Lights**: a 30-LED WS2812 strip compositor (`lights`): brake bar, turn indicators from
  steering, halo color, F1 rain light flashing while ERS *harvests*, low-battery pulse,
  and an all-amber **failsafe hazard blink that overrides everything**.
- Its own local failsafe: no valid link2 frame for 500 ms → engine silent + hazard blink
  (mandatory receiver rule from `docs/link2_protocol.md`).
- Runs **dual-core**: control loop on ESP32 core 1, audio rendering task on core 0,
  communicating through a single packed `std::atomic<uint32_t>` parameter word plus a
  heartbeat atomic (cross-core rule in its `CLAUDE.md`).

### 2.3 `w17-ground-station` — the laptop app

**[C]** (from `w17-ground-station/README.md`, `docs/SETUP.md`, `docs/TELEMETRY.md`):

- An **Electron** desktop app (JavaScript, not C++) that shows the FPV video full-screen
  with a Mercedes-style **F1 HUD** overlay.
- **Video path**: OpenIPC camera → RTSP → bundled **mediamtx** media server →
  **WebRTC/WHEP** → the app's renderer. (Chosen for low latency; H.265-vs-H.264 codec is
  flagged as the #1 bench risk because Chromium WebRTC can't decode H.265.)
- **HUD**: mirrors the DualShock gamepad live (throttle/brake/steering/DRS/boost/
  overtake/gear) via the browser Gamepad API, and *simulates* speed/RPM/ERS when no
  telemetry is present.
- **Telemetry overlay**: real battery voltage, link quality, wheel speed, gear, drive
  mode, ERS% from the car replace simulated values when the CRSF serial telemetry source
  is connected (`main/CrsfSerialSource.js` + `shared/crsfTelemetry.js`).
- **It does not transmit anything to the car.** Control stays with the third-party
  program **elrs-joystick-control** running alongside — a deliberate gift-day safety
  decision so a ground-station bug can never stop the car.

## 3. Physical hardware involved

**[C]** All from `docs/bill_of_materials_v2.md` and `docs/00_BUILD_SHEET.md` unless noted.

### On the car
| Part | Role |
|---|---|
| 2× ESP32-WROOM-32 DevKit V1 (+1 spare) | Board #1 control, board #2 sound/light |
| RadioMaster RP1 | ELRS 2.4 GHz radio **receiver** → CRSF out to board #1 |
| Hobbywing QuicRun 10BL120 ESC + Rocket 540 17.5T sensored motor | Drive; ESC set to sensored mode, forward/brake |
| DSServo DS3235SG (35 kg·cm) | Steering servo |
| 3× MG90S micro servos | DRS wing flap, camera gimbal pan, gimbal tilt |
| A3144 Hall sensor + neodymium axle magnet | Wheel-speed sensor (1 pulse/rev) |
| 27 kΩ / 10 kΩ resistor divider | Battery voltage sense into ESP32 ADC |
| MAX98357A I2S amp + 4 Ω 3 W speaker | Engine sound output |
| WS2812B strip (30 LEDs) | Brake / indicators / halo / rain light / hazard |
| OpenIPC camera (SSC338Q + IMX415, already flashed) + BL-M8812EU2 USB WiFi module | FPV video; WiFi module creates a 5.8 GHz AP |
| 2S LiPo (7.4 V, ≤75×45×25 mm) ×2 | Power |
| 2× 5 A UBEC | Rail A (clean: electronics) and Rail B (servos + blower) |
| XT60 Y-split, 1000 µF caps, 330 Ω, 1N5819, blower fan | Power distribution + the documented "bench fixes" |
| Belt-drive kit, 48DP pinion/spur, bearings, oil shocks, printed chassis/body | Mechanics (covered by print/BOM docs, not by firmware) |

### On the ground
| Part | Role |
|---|---|
| PC/laptop | Runs elrs-joystick-control + the ground-station app |
| Sony DualShock gamepad | The actual steering wheel (gift-day) |
| FT232RL USB-UART | Carries CRSF between PC and the ELRS TX module (and doubles as camera console) |
| HappyModel ES24TX Pro | ELRS 2.4 GHz **transmitter** module |
| RadioMaster TX16S | Backup handset (same bind phrase), also bench transmitter |
| VLC | Zero-code video fallback |

## 4. What communicates with what (the full data-flow picture)

**[C]** Assembled from `docs/w17_wiring_assembly_atlas.html` ELEC-01…06,
`docs/link2_protocol.md`, `docs/TELEMETRY.md` (ground repo), and the pin maps
(`w17-control-fw/lib/config/include/config/PinMap.hpp`,
`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`).

```
GROUND                                          CAR
======                                          ===
DualShock --USB--> PC (elrs-joystick-control)
                    |
                    | USB serial (CRSF)
                    v
                  FT232 --CRSF--> ELRS TX module ==2.4 GHz ELRS==> RP1 receiver
                    ^                                               |
                    | CRSF telemetry back                           | CRSF 420000 baud UART
                    | (battery 0x08, GPS 0x02,                      v
                    |  flightmode 0x21, LQ 0x14)            ESP32 #1 CONTROL
                    |                                        | | | | | |
   Ground-station <-+ (reads the same serial,                | | | | | +--UART1 TX GPIO25, 115200
   Electron app       via com0com splitter or                | | | | |     "link2" 14-byte frames, 20 Hz
        ^             a forward flag - unresolved)           | | | | |          |
        |                                                    | | | | |          v
        | WebRTC/WHEP (localhost)                            | | | | |    ESP32 #2 SOUND+LIGHT
        |                                                    | | | | |     |          |
   mediamtx <--RTSP-- WiFi 5.8 GHz AP <--USB-- OpenIPC cam   | | | | |    I2S       GPIO4 data
                                                             | | | | |     v          v
                                                             | | | | |  MAX98357A   WS2812 strip
                                                             | | | | |   + speaker   (30 LEDs)
                     steering servo PWM  <-- GPIO13 ---------+ | | | |
                     ESC throttle PWM    <-- GPIO14 -----------+ | | |
                     DRS servo PWM       <-- GPIO18 -------------+ | |
                     gimbal pan/tilt PWM <-- GPIO19/23 ------------+ |
                     battery divider --> GPIO34 (ADC), Hall --> GPIO35 (ISR)
```

Key properties of the links:

- **[C] Control link (2.4 GHz ELRS)** and **video link (5.8 GHz WiFi)** are completely
  separate radios sharing only the battery (`w17_wiring_assembly_atlas.html` ELEC-01).
- **[C] CRSF** is the serial protocol used on *both ends* of the ELRS link (PC→TX module,
  and RX→ESP32). 420,000 baud, 8N1, not inverted; RC channels frame type 0x16 packs
  16 channels × 11 bits, values 172–1811 with center 992; CRC8 poly 0xD5
  (`w17-control-fw/CLAUDE.md` §1–2).
- **[C] link2** is this project's own one-way protocol, board #1 → board #2: UART
  115200 8N1, 14-byte frame `0xA5, length, 11-byte payload, CRC8`, 20 Hz, receiver must
  fail safe after 500 ms of silence (`docs/link2_protocol.md`).
- **[C] Telemetry backchannel** reuses standard CRSF sensor frames relayed by ELRS:
  battery 0x08, GPS 0x02 (groundspeed field carries wheel speed), FLIGHTMODE 0x21
  (status string `"G3 M2 E55"` = gear/mode/ERS%), LINK_STATISTICS 0x14 generated by the
  ground TX module itself (`w17-ground-station/docs/TELEMETRY.md`).
- **[I] The FT232 serial port is the one contended resource on the ground**: elrs-joystick-
  control must hold it to fly, so the ground station reads telemetry via a com0com virtual
  splitter or a forwarding feature — evidence: `docs/TELEMETRY.md` "The one obstacle"
  section marks this unresolved until the bench.

## 5. What software runs where

| Location | Software | Language / framework |
|---|---|---|
| ESP32 #1 | `w17-control-fw` (`esp32dev` env; `esp32dev_tuning` for bench; `esp32dev_sim` for Wokwi) | C++17, Arduino-ESP32 via PlatformIO |
| ESP32 #2 | `w17-soundlight-fw` (`esp32dev`; `esp32dev_sim` bench demo) | C++17, Arduino-ESP32 via PlatformIO (+ ESP-IDF legacy I2S driver) |
| Laptop | `w17-ground-station` Electron app + bundled mediamtx binary | JavaScript (Node.js main process + Chromium renderer) |
| Laptop | **elrs-joystick-control** (third-party, not in these repos) | external tool — turns DualShock into CRSF |
| Camera | OpenIPC firmware "APFPV greg10.2" with `majestic_fpv.yaml` tuning | external, already flashed (`bill_of_materials_v2.md` §A.1) |
| Your dev machine | PlatformIO `native` env — the same pure-logic C++ compiled for the host to run 147/40 unit tests without hardware | C++17 + Unity test framework |

**[I]** The "most of the code runs on your laptop too" property is the project's central
design idea: every `lib/` module except the `*_hal_esp32` ones compiles on the host with
no ESP32 attached. Evidence: `platformio.ini [env:native]` with `lib_ignore` of the five
HAL libs, and the architecture rule "no ESP32/Arduino headers in pure-logic files"
(`CLAUDE.md` §5). This matters for you: **you can study and run most of the system
without any hardware.**
