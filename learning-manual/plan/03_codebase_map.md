# 03 — Codebase Map

Every folder and important file in the three repos, with roles, sizes, and how they
connect. All file lists below were verified against the actual tree on 2026-07-03.
Line counts are of the `.cpp` implementation files (headers add more).

## 3.1 The shared architectural pattern (understand this once, reuse everywhere)

**[C]** Both firmware repos follow one house style, stated in `w17-control-fw/CLAUDE.md` §5
and `w17-soundlight-fw/CLAUDE.md`, and visible in the tree:

- **`lib/<module>/`** = one PlatformIO "library" per module. Pure logic only — **no
  Arduino/ESP32 headers allowed**. Compiles on your laptop.
  - `include/<module>/*.hpp` — public headers
  - `src/*.cpp` — implementation
  - `library.json` — PlatformIO library metadata
- **`lib/<module>_hal_esp32/`** = the thin hardware-touching twin ("HAL" = Hardware
  Abstraction Layer). Only these may include Arduino/ESP-IDF headers, and only
  `src/main.cpp` references them.
- **`lib/hal/`** (control repo) = the *interfaces* (abstract classes like `IPwmOutput`,
  `IClock`) that pure logic depends on, so tests can substitute fakes.
- **`src/main.cpp`** = the only glue: constructs real HAL objects, wires them into the
  pure modules, runs the loop.
- **`test/test_<module>/test_main.cpp`** = Unity-framework unit tests run on the host
  (`pio test -e native`), using mocks from `test/mocks/`.
- **Config structs** with `constexpr valid()` checked by `static_assert` at the
  definition site — invalid configuration *fails to compile*.
- **Integer math** in control paths (soundlight rule; control repo follows in practice).

## 3.2 `w17-control-fw` — module by module

### Entry point
| File | Lines | Role |
|---|---|---|
| `src/main.cpp` | 403 | **The** entry point: Arduino `setup()` (line ~167) + `loop()` (line ~201). Constructs everything, `static_assert`s all configs, then runs three fixed cadences: always-drain CRSF UART, 50 Hz control tick (failsafe → arm gate → gearbox/ERS → outputs), 20 Hz link2 send, ~5 Hz CRSF telemetry out. `#ifdef` blocks add the sim feeder (`W17_SIM_CRSF_FEEDER`) or tuning console (`W17_TUNING_CONSOLE`). |
| `src/SimCrsfFeeder.{hpp,cpp}` | 192 | Wokwi-only scripted CRSF frame source demonstrating all failsafe/arm/gear/ERS behaviors (see `docs/SIMULATION.md` phase table). Compiled only in `esp32dev_sim`. |

### Pure-logic libraries (host-testable)
| Library | Key files | Lines | What it does |
|---|---|---|---|
| `lib/config` | `include/config/PinMap.hpp` | header-only | All GPIO assignments as `constexpr` constants, one per signal. |
| `lib/hal` | `IByteSink` `ICharIO` `IClock` `IPwmOutput` `ISettingsStore` `IVoltageSensor` `IWheelPulseSensor` (headers only) | — | The hardware-interface seams. Each is a tiny abstract class; real impls live in `*_hal_esp32`, fakes in `test/mocks/`. |
| `lib/crsf` | `CrsfParser` (88), `CrsfFrameAssembler` (59), `CrsfReceiver` (43), `CrsfFrame.hpp`, `CrsfFrameBuilder.hpp` | ~190 | **Radio input.** Assembler finds/validates frames (sync 0xC8, CRC8 0xD5) in the byte stream; parser decodes RC_CHANNELS_PACKED 0x16 (16×11-bit) and LINK_STATISTICS 0x14; receiver facade owns channel copies, `linkUp()`, and the **latched LQ=0 failsafe flag**; builder constructs frames (tests, sim feeder, and telemetry-out battery/GPS/flightmode frames). |
| `lib/channels` | `ChannelDecoder` (+hpp), `ArmGate` | ~2 files | **Raw→named controls.** Config-table mapping (steering ch1, throttle ch3, arm ch5, DRS ch6, gear ch7/8, pan/tilt ch9/10, boost ch11, overtake ch12, mode ch13), ±1000 normalization, invert flags, switch hysteresis ±250, edge detection. `ArmGate`: the safety rule *armed ⇔ switch ON ∧ throttle seen neutral since last disarm*. |
| `lib/failsafe` | `FailsafeStateMachine` | 42 | **The safety core.** Pure state machine: (frame-arrived events, RX failsafe flag, time) → Safe/Active. Contains the `everReceivedFrame_` latch that fixed critical bug A1 (boot-time full-lock steering). Smallest real module — ideal first read. |
| `lib/gearbox` | `Gearbox` | 74 | Virtual gearbox: `shapeThrottle(throttle, gear)` = expo curve blend + scale to per-gear max (default table 400/50, 600/35, 800/20, 1000/0). Braking passes through unshaped. Gear survives failsafe. |
| `lib/ers` | `ErsSystem` | 68 | F1-style energy store in micro-permille units: boost +18% / overtake +25% multipliers, deploy 26%/s, brake-harvest 11%/s, harvest requires wheel rpm > 0, frozen outside ERS mode. |
| `lib/outputs` | `ServoOutput` (33), `EscOutput` (47), `DrsOutput` (11) | ~91 | Convert normalized commands → pulse-width microseconds through `IPwmOutput`. Steering endpoints/trim; ESC neutral 1500 µs + 2 s boot arm hold; DRS two positions. |
| `lib/telemetry` | `BatteryMonitor` (65), `WheelSpeed` (57) | 122 | Battery: divider mV → pack volts, EMA smoothing, low-voltage warn latched after 3 s sustained <7.0 V, cleared >7.4 V. WheelSpeed: pulse period → rpm, EMI plausibility clamp (5000 rpm), decay-to-zero on silence. |
| `lib/link2` | `Link2Codec` (117), `Link2Sender` (52), `Link2Frame.hpp` | 169 | The board#1→#2 protocol: frame struct, encode/decode + CRC8, assembler (receiver side), sender (20 Hz shaping incl. brake-flag hysteresis). Spec: `docs/link2_protocol.md`. |
| `lib/settings` | `Settings` | 49 | Tunables aggregate (steering center/trim, battery cal, gear table) + versioned-CRC blob (de)serialization with the never-brick guard chain (any failure → defaults). |
| `lib/console` | `Console` (169), `ConsoleRunner` (76) | 245 | Bench tuning console: dotted-key `get/set/save/load/reset/status/help`, mutations gated on DISARMED, every `set` re-validated. Pure — talks through `hal::ICharIO`/`ISettingsStore`. |

### ESP32-only HAL libraries (each wraps one hardware facility)
| Library | Wraps | Notes |
|---|---|---|
| `lib/crsf_hal_esp32` (`Esp32CrsfUart`, 27) | UART2 @ 420000 baud | RX from RP1 (GPIO16), TX telemetry back (GPIO17). |
| `lib/outputs_hal_esp32` (`Esp32LedcPwm`, 20) | LEDC 50 Hz PWM | One channel per servo/ESC; `begin(initialPulseMicros)` writes the safe position immediately (fix A4). |
| `lib/telemetry_hal_esp32` (`Esp32BatteryAdc` 21, `Esp32HallPulseCounter` 39) | ADC1 (calibrated mV, 11 dB atten) + GPIO35 rising-edge ISR | ISR uses `IRAM_ATTR`, `std::atomic` counters, 2 ms edge lockout. |
| `lib/link2_hal_esp32` (`Esp32Link2Uart`, 17) | UART1 TX-only on GPIO25 | Remap mandatory — UART1 defaults are flash pins. |
| `lib/settings_hal_esp32` (`Esp32NvsStore` 32, `Esp32SerialConsole` 15) | NVS flash (Preferences) + UART0 | Tuning build only. |

### Tests (Unity, `pio test -e native` — 147 tests per ROADMAP)
`test/test_{crsf,channels,failsafe,gearbox,ers,outputs,telemetry,link2,settings,console}/test_main.cpp`
plus `test/mocks/` (FakeClock, MockPwmOutput, FakeVoltageSensor, FakeWheelPulseSensor,
MockByteSink, MockCharIO, MockSettingsStore). **[C]** Golden-frame tests pin the link2 and
CRSF-telemetry wire formats byte-exactly (`test_link2/test_main.cpp` `test_golden_frame_bytes`;
`test_crsf` `test_build_*_frame*`) — the same vectors are reused in the ground station's tests.

## 3.3 `w17-soundlight-fw` — module by module

### Entry point
| File | Lines | Role |
|---|---|---|
| `src/main.cpp` | 142 | `setup()`/`loop()` on core 1 (link2 RX → monitor → enginesim → lights → pack params into one `std::atomic<uint32_t>`), plus `audioTask()` pinned to core 0 (unpack params → `EngineSynth` → I2S). The dead-man: params stale ~500 ms → volume ramps to 0. |
| `src/SimLink2Feeder.{hpp,cpp}` | 106 | Bench-demo scripted link2 stream (14 s loop incl. the dropout→local-failsafe phase). `esp32dev_sim` only. |

### Libraries
| Library | Key files | Lines | What it does |
|---|---|---|---|
| `lib/config` | `PinMap.hpp` | header | Board #2 pins: link2 RX 16, I2S BCLK 26 / LRCLK 25 / DATA 22, WS2812 4. Documents MAX98357A GAIN/SD_MODE strapping. |
| `lib/link2` | `Link2Codec` (117), `Link2Frame.hpp` | 117 | **Verbatim copy** from control repo (protocol owner). Receiver side: assembler with hard length rejection. |
| `lib/link2monitor` | `Link2Monitor` | 57 | The 500 ms staleness watchdog → per-field effective state (throttle forced 0, failsafe flag forced on…) + `LinkStatus` (NeverConnected/Up/Lost). |
| `lib/enginesim` | `EngineSim` | 138 | Virtual engine: rpm inertia toward a throttle target, ignition state machine (Off/Cranking/Running), rev limiter, gear-shift blips, overrun-crackle window. Feeds both sound and (indirectly) light logic. |
| `lib/soundsynth` | `EngineSynth` (152), `ISampleSource.hpp` | 152 | The DSP: wavetable partial stack at the engine firing frequency (5 firings/rev = V10 flavor), per-rev amplitude modulation, throttle-correlated noise (seeded LFSR — deterministic), pitch-tracking ERS whine, parameter smoothing. All integer math. `ISampleSource` seam allows a future PCM sample player. |
| `lib/lights` | `LightRenderer` | 150 | Pure pixel compositor over 30 LEDs: base/halo → brake bar → indicators → rain light (ERS harvest) → low-battery pulse → **failsafe hazard overrides all** → gamma LUT → brightness/power cap enforced in `valid()`. |
| `lib/audio_hal_esp32` | `Esp32I2sAudio` (50) | 50 | ESP-IDF legacy I2S driver, 22050 Hz, mono duplicated to stereo. |
| `lib/lights_hal_esp32` | `Esp32NeoPixelStrip` (20) | 20 | Adafruit NeoPixel behind an `ILedStrip` interface. |

### Tests (40 native per README)
`test/test_{link2,link2monitor,enginesim,soundsynth,lights,integration}/test_main.cpp` —
note `test_integration`: a pure end-to-end frames→audio test.

## 3.4 `w17-ground-station` — file by file

**[C — roles from `README.md` + `docs/TELEMETRY.md`; code itself not yet read line-by-line.]**

| Path | Lines | Role |
|---|---|---|
| `package.json` | — | npm manifest; entry `main/main.js`; scripts `start`/`demo`/`test`/`build`/`setup`; `serialport` is *optional* (app runs without telemetry if absent). |
| `main/main.js` | 106 | **Electron main process**: creates the window, supervises mediamtx, selects the telemetry source from `W17_TELEMETRY_SOURCE`/`W17_TELEMETRY_PORT` env vars, pushes telemetry to the renderer over IPC. |
| `main/mediamtx.js` | 54 | Child-process supervisor for the bundled mediamtx binary. |
| `main/CrsfSerialSource.js` | 96 | Opens the CRSF serial port, feeds bytes to the assembler, merges decoded frames into one running Telemetry snapshot (accumulate, don't replace). |
| `main/preload.cjs` | — | The context bridge exposing safe IPC to the renderer. |
| `renderer/index.html` + `hud.css` + `hud.js` (246) | ~246 | The HUD page: gamepad mirroring (Gamepad API), simulated speed/rpm/ERS animation, telemetry overlay that prefers live data. |
| `renderer/whep.js` | 89 | WebRTC/WHEP client that plays the mediamtx stream as the video background. |
| `shared/crsf.js` | 165 | **Port of the firmware CRSF decoder** (CRC-8/DVB-S2 0xD5, same layouts): decodeBattery/decodeGps/decodeFlightMode/parseFlightMode/LINK_STATISTICS. |
| `shared/crsfAssembler.js` | 45 | Byte-stream → frame assembler (mirror of the firmware's). |
| `shared/crsfTelemetry.js` | 45 | CRSF frames → normalized `Telemetry` fields mapping. |
| `shared/telemetry.js` | 43 | The normalized `Telemetry` object (contract in `docs/TELEMETRY.md`); >1 s stale → HUD falls back to simulation. |
| `shared/replaySource.js` | 93 | The `npm run demo` fake telemetry source. |
| `shared/feelConstants.js` | 13 | ERS feel numbers shared with the firmware (numbers only — logic deliberately not shared). |
| `scripts/run.js`, `ensure-electron.js`, `fetch-mediamtx.js` | — | Launcher (strips `ELECTRON_RUN_AS_NODE`), Electron postinstall repair, mediamtx downloader (pins v1.9.3). |
| `mediamtx/mediamtx.yml` | — | Pinned server config; `paths.cam.source` = camera RTSP URL (bench task). |
| `test/*.test.js` | — | 20 vitest specs reusing the firmware's golden CRSF vectors. |

## 3.5 Where the key mechanisms live (quick lookup)

| Mechanism | Files |
|---|---|
| **State machines** | `lib/failsafe/FailsafeStateMachine` (Safe/Active + latches); `lib/channels/ArmGate`; `lib/enginesim/EngineSim` (ignition Off/Cranking/Running); `lib/link2monitor/Link2Monitor` (NeverConnected/Up/Lost); CRSF + link2 assemblers (byte-level framing FSMs) |
| **Protocol encode/decode** | `lib/crsf/*` (both repos' ground truth for CRSF); `lib/link2/Link2Codec` (both fw repos); `shared/crsf*.js` (ground) |
| **Control algorithms** | `Gearbox::shapeThrottle` (expo + scaling), `ErsSystem` (energy integrator), `BatteryMonitor` (EMA + hysteresis latch), `WheelSpeed` (period→rpm + clamps) |
| **DSP** | `soundsynth/EngineSynth` (wavetable synthesis), `enginesim/EngineSim` (the physical model driving it) |
| **Interrupts/concurrency** | `Esp32HallPulseCounter` (ISR + atomics); soundlight `main.cpp` dual-core split + atomic param word |
| **Persistence** | `lib/settings` + `Esp32NvsStore` (NVS flash) |
| **Configuration** | `lib/config/PinMap.hpp` (both fw repos); config structs at the top of each module header; `platformio.ini` build flags; `mediamtx.yml`; env vars `W17_TELEMETRY_*` |
| **Build systems** | PlatformIO (`platformio.ini` ×2: envs esp32dev / esp32dev_sim / esp32dev_tuning / native); npm + electron-builder (`package.json`, `electron-builder.yml`); Wokwi (`wokwi.toml` + `diagram.json`); GitHub Actions (`.github/workflows/ci.yml` ×2) |
