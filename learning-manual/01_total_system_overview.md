# 01 — Total System Overview

This chapter gives you the whole system in one pass: what exists physically, what
software runs where, and how everything talks to everything else. Later chapters zoom
into each box.

## 1. The project in three sentences

A 1/10-scale radio-controlled Formula 1 car, 3D-printed on the OpenRC "RC-01" belt-drive
chassis, painted as the Mercedes W17 (#63 Russell), and driven **FPV** — "first person
view," meaning you drive by watching live video from a camera on the car, not by looking
at the car. Two ESP32 microcontroller boards ride on the car: one drives it, one makes
engine sound and light effects. A laptop shows the video with a Formula 1 style dashboard
overlay. **[C]** Source: `w17-control-fw/CLAUDE.md` §0, `docs/00_BUILD_SHEET.md`.

## 2. The five "computers" involved

| # | Device | What it runs | Role |
|---|---|---|---|
| 1 | **ESP32 #1 — control board** | `w17-control-fw` (C++) | The car's brain. The only thing allowed to move the car. |
| 2 | **ESP32 #2 — sound/light board** | `w17-soundlight-fw` (C++) | Cosmetics: engine sound + LED effects. Can't affect driving. |
| 3 | **OpenIPC camera** (SSC338Q chip) | OpenIPC firmware (pre-flashed, external project) | Streams live video over its own WiFi. |
| 4 | **Laptop (ground)** | `w17-ground-station` (Electron/JavaScript) + **elrs-joystick-control** (external tool) | Video + HUD viewer; the external tool converts the DualShock gamepad into radio commands. |
| 5 | **Your dev machine** | The same C++ logic compiled natively + all test suites | The "lab": most of the firmware logic runs and is tested here with **zero hardware**. |

An "ESP32" is a small, cheap microcontroller board (a complete tiny computer on one
chip: two 240 MHz CPU cores, ~520 KB RAM, 4 MB flash storage, WiFi, and lots of
general-purpose pins). It runs one program you write, directly on the metal — no
operating system with apps, no files in the desktop sense. Chapter 04 covers what
programming one is like.

## 3. The whole system in one diagram

```mermaid
flowchart LR
  subgraph GROUND["GROUND (you)"]
    DS["DualShock gamepad"] -->|USB| PC["PC: elrs-joystick-control"]
    PC -->|USB serial, CRSF| FT["FT232 USB-UART adapter"]
    FT -->|CRSF| TXM["ELRS TX module<br/>(ES24TX Pro)"]
    GS["Ground station app<br/>(Electron HUD)"]
    LAPVID["mediamtx server"] -->|WebRTC/WHEP| GS
    FT -.->|telemetry back<br/>(shared serial)| GS
  end

  subgraph CAR["CAR"]
    RX["ELRS receiver<br/>(RadioMaster RP1)"]
    E1["ESP32 #1<br/>CONTROL"]
    E2["ESP32 #2<br/>SOUND + LIGHT"]
    CAM["OpenIPC camera"] --- WIFI["5.8 GHz WiFi module"]
    RX -->|CRSF UART 420000 baud| E1
    E1 -->|CRSF telemetry UART| RX
    E1 -->|link2 UART 115200, 20 Hz| E2
    E1 -->|PWM| ACT["steering servo · ESC/motor<br/>DRS servo · pan/tilt servos"]
    SENS["battery divider · Hall sensor"] --> E1
    E2 -->|I2S| AMP["MAX98357A amp + speaker"]
    E2 -->|1-wire data| LED["WS2812 strip, 30 LEDs"]
  end

  TXM ==>|2.4 GHz ELRS radio| RX
  RX ==>|2.4 GHz telemetry downlink| TXM
  WIFI ==>|5.8 GHz WiFi video| LAPVID
```

**[C]** Topology per `w17-control-fw/docs/w17_wiring_assembly_atlas.html` (ELEC-01…06),
pins per `w17-control-fw/lib/config/include/config/PinMap.hpp` and
`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`.

Two facts worth internalizing immediately:

1. **Two completely separate radio links.** Control (2.4 GHz ExpressLRS) and video
   (5.8 GHz WiFi) share nothing but the battery. Video can die and you can still stop
   the car; control can die and you'll watch it stop itself (failsafe).
2. **Authority flows one way.** Gamepad → car is the only command path. The sound/light
   board and the ground station are consumers of state; neither can command anything.

## 4. Following one stick movement end to end

You push the DualShock's throttle. What happens, in order:

1. **elrs-joystick-control** (PC) reads the gamepad and encodes stick positions as
   **CRSF** — the standard serial protocol RC gear speaks (chapter 09). It sends CRSF
   frames out the **FT232** (a USB-to-serial adapter) into the **ELRS TX module**.
2. The TX module radios the channel values to the **RP1 receiver** on the car over
   **ExpressLRS (ELRS)** — an open-source, low-latency 2.4 GHz RC radio system.
3. The RP1 outputs the same CRSF frames on a wire into **ESP32 #1** (UART2, pin GPIO16,
   420,000 baud) — 16 channels, each an 11-bit number between 172 and 1811.
4. `w17-control-fw` assembles and CRC-checks the frame (`lib/crsf`), maps channel 3 to
   "throttle" and normalizes it to −1000…+1000 (`lib/channels/ChannelDecoder`),
   and runs the safety gates: the **failsafe state machine** (is the link healthy?) and
   the **ArmGate** (is the arm switch on, and was the stick seen at neutral?).
5. If allowed, the throttle passes through the **virtual gearbox** (per-gear power cap +
   curve shaping, `lib/gearbox`) and **ERS boost** (`lib/ers`), then `lib/outputs`
   converts it to a pulse width in microseconds, and `Esp32LedcPwm` emits a 50 Hz PWM
   signal on GPIO14 to the **ESC** (electronic speed controller), which drives the motor.
6. Twenty times a second, ESP32 #1 packs its whole state (commanded throttle, steering,
   gear, flags, rpm, battery…) into a 14-byte **link2** frame and sends it to ESP32 #2,
   which adjusts the engine sound pitch and the LEDs (brake bar, indicators…).
7. About five times a second, ESP32 #1 also sends standard CRSF **telemetry** frames
   (battery, speed, gear/mode/ERS) back through the RP1 → over the ELRS downlink → to
   the TX module on your desk → onto the same FT232 serial — where the **ground station**
   reads them and overlays real values on the HUD.
8. Meanwhile the camera streams video over its own WiFi to the laptop, where **mediamtx**
   converts it to WebRTC and the HUD renders it as the full-screen background.

Total stick-to-wheel latency is dominated by the radio link (a few ms at ELRS rates) and
the 50 Hz control tick (up to 20 ms). **[I]** — no measured figure exists in the docs;
this is the design expectation from the components used.

## 5. What each repository contributes

- **`w17-control-fw`** — everything in step 3–7 on the car side except sound/light.
  Also *owns the protocols*: the link2 spec (`docs/link2_protocol.md`) and the golden
  test vectors the other repos reuse. Its `docs/` folder is the project's documentation
  home (chapter 05).
- **`w17-soundlight-fw`** — step 6's consumer: a virtual engine model + sound synthesizer
  (I2S → amp → speaker) and a light compositor (WS2812). Has its own local failsafe: if
  link2 goes silent 500 ms it silences the engine and blinks amber hazards.
- **`w17-ground-station`** — steps 7–8 on the laptop: video + HUD + telemetry overlay.
  Deliberately **viewer-only** so a bug in it can never affect the car
  (`w17-ground-station/README.md`).

## 6. The physical parts list (abridged)

**[C]** Full list with prices/links: `w17-control-fw/docs/bill_of_materials_v2.md`.

- **Power:** 2S LiPo battery (7.4 V nominal, 8.4 V full) → XT60 Y-split → ESC + two
  5 A UBECs ("battery eliminator circuits" = voltage regulators) making two 5 V rails:
  Rail A (clean — computers, camera, radio) and Rail B (noisy — servos, blower fan).
- **Drive:** Hobbywing QuicRun 10BL120 ESC + Rocket 540 17.5T *sensored* brushless motor,
  belt drive to the rear axle.
- **Steering:** DS3235SG high-torque servo. **Aero:** DRS wing flap on an MG90S micro
  servo. **Camera aim:** pan/tilt gimbal on two more MG90S.
- **Sensors:** battery voltage via a 27 kΩ/10 kΩ divider into an ADC pin; wheel speed via
  an A3144 Hall-effect sensor + a magnet on the axle.
- **Sound/light:** MAX98357A I2S amplifier + 4 Ω 3 W speaker; 30-LED WS2812B strip.
- **Radio:** RadioMaster RP1 (receiver), HappyModel ES24TX Pro (TX module), RadioMaster
  TX16S handset as backup transmitter (same bind phrase).
- **Video:** OpenIPC camera (already owned and flashed) + BL-M8812EU2 USB WiFi module.

## 7. Design philosophy you'll see everywhere

1. **Safety first, and layered.** Failsafe was built and tested before any feature
   (`CLAUDE.md` §6). There are at least five independent safety layers (chapter 10).
2. **Pure logic, thin hardware.** Almost all code has no idea hardware exists; tiny
   "HAL" wrappers touch the chip. That's why 187 unit tests run on a laptop (chapter 02).
3. **Invalid configuration fails to compile.** Config structs carry a `valid()` check
   enforced at compile time via `static_assert` (chapter 04).
4. **Protocols are pinned by golden tests.** The exact bytes of every frame are asserted
   in tests in *both* the sender's and receiver's repos, so they can't drift apart
   (chapter 09).
5. **The gift must work even if the fancy parts fail.** Zero-code fallback: drive with
   elrs-joystick-control and watch video in VLC (`w17-ground-station/docs/SETUP.md`).

## Confirmed vs inferred in this chapter

**Confirmed [C]:** everything in §1–§3, §5–§6 cites its source doc/file directly; the
step-by-step in §4 matches `CLAUDE.md` §2, `docs/link2_protocol.md`,
`w17-ground-station/docs/TELEMETRY.md`, and the module list verified in the repo trees.

**Inferred [I]:** the latency remark (§4); "authority flows one way" as a *stated design
goal* is confirmed, but its enforcement on the ground side depends on elrs-joystick-control
being the only serial-port writer — see `docs/TELEMETRY.md` "The one obstacle".

**Assumed [A]:** that the physical car will be wired exactly per the atlas + PinMap —
nothing is soldered yet, so every pin claim is "as designed," not "as built."

## Questions to check your understanding

1. Which radio link carries your steering commands, and which carries the video? What is
   the *only* thing the two links share?
2. The sound/light board wants to know the throttle. Why does it receive "what the ESC is
   actually commanded" rather than "where the stick is"? (Hint: think about failsafe.)
3. List the order of transformations between "you push the stick" and "the motor spins."
   Which single board makes every safety decision?
4. Why can most of the firmware be tested on your laptop even though it was written for
   an ESP32?
5. If the ground station app crashes mid-drive, what happens to the car — and why is
   that answer a deliberate design decision?
