# 04 — Beginner Knowledge Map

Everything you'll need to understand this codebase, grouped by domain, with **where in
this project each concept first bites**. The full manual will teach these in place; this
map is the checklist.

Your stated baseline: some RC/electronics basics, strong Linux, **beginner C++**. The
C++ list is therefore the deepest.

## 4.1 C++ concepts (ordered roughly as you'll meet them)

### Tier 1 — needed before reading ANY module
| Concept | First appearance | What you need to know |
|---|---|---|
| Compilation model: headers (`.hpp`) vs sources (`.cpp`), `#include`, `#pragma once` | every module | Why code is split in two files; what the preprocessor does; why headers guard against double inclusion |
| Fixed-width integer types (`uint8_t`, `int16_t`, `uint32_t` from `<cstdint>`) | `PinMap.hpp`, all protocol code | Why embedded code never says plain `int` for wire data; signed vs unsigned; overflow/wraparound |
| `namespace` | `pinmap`, `hal`, every lib | Name scoping; `::` qualification |
| `constexpr` / `const` | `PinMap.hpp`, all config structs | Compile-time constants vs runtime constants |
| `struct` and member functions | every config struct | Data grouping; methods; default member initializers |
| `enum class` | `FailsafeStateMachine` states, `LinkStatus` | Type-safe named states |
| Functions, references (`&`), value vs reference semantics | everywhere | How data moves between modules |
| `bool` logic, ternaries, integer arithmetic/division pitfalls | gearbox/ERS math | Integer division truncation — the reason for "endpoint-exact integer math" claims |

### Tier 2 — needed for the module structure
| Concept | First appearance | What you need to know |
|---|---|---|
| Classes: `public`/`private`, constructors, member initializer lists | `FailsafeStateMachine`, `Gearbox` | Encapsulated state machines |
| **Abstract interfaces: `virtual`, `= 0`, `override`, virtual destructors** | `lib/hal/*.hpp` | THE key pattern here — hardware seams. Why a pure-logic class can call `IPwmOutput` without knowing if it's real hardware or a test mock |
| `static_assert` + `constexpr valid()` | top of `main.cpp`, every config | "Invalid config fails to compile" — how and why |
| Arrays, `std::array`, indexing, bounds discipline | CRSF channels[16], LED pixels | Fixed-size buffers everywhere; no dynamic allocation |
| Byte manipulation: bit shifts, masks, little/big-endian packing | `CrsfParser`, `Link2Codec` | How 16 channels fit in 22 bytes; how flags pack into one byte |
| `#ifdef` / build flags | `main.cpp` sim/tuning blocks | Conditional compilation; how one codebase builds 3 variants |
| Lambdas / function objects (light use) | callbacks, tests | Recognize the syntax |
| Templates (light use — mostly `std::` containers) | assorted | Read-level only; the codebase avoids clever templates by design ("readable over clever", CLAUDE.md §5) |

### Tier 3 — needed for specific corners
| Concept | Where | What you need to know |
|---|---|---|
| `std::atomic`, memory ordering (basic), why ISRs/threads need it | `Esp32HallPulseCounter`, soundlight dual-core param word | Data races; what an atomic 32-bit word buys you; why the cross-core rule exists |
| `volatile` vs atomic distinction | ISR code | Common embedded confusion, worth one focused explanation |
| CRC algorithms (poly 0xD5, MSB-first) | `crsf`, `link2`, `shared/crsf.js` | Not C++ per se, but implemented in it; you'll see the same 20 lines three times |
| Fixed-point / scaled-integer math (micro-permille ERS store, EMA accumulators) | `ErsSystem`, `BatteryMonitor` | How to do fractions without floats |
| Wavetable synthesis loop structure | `EngineSynth` | Phase accumulators, lookup tables, LFSR noise |
| Unity test framework macros (`TEST_ASSERT_*`, `RUN_TEST`) | all `test/` | How to read and run the tests |

## 4.2 Embedded-systems concepts

| Concept | Where it bites | Notes |
|---|---|---|
| What a microcontroller is: flash, RAM, GPIO, why no OS | everywhere | ESP32-WROOM-32: dual-core 240 MHz, the project uses Arduino framework on top of FreeRTOS |
| Arduino programming model: `setup()`/`loop()`, `millis()`, non-blocking design ("no `delay()` in the control path") | both `main.cpp` | Includes the fixed-cadence tick pattern (50 Hz control / 20 Hz link2 / 5 Hz telemetry) |
| **UART / serial**: baud rate, 8N1, TX/RX crossing, logic levels, why common ground | CRSF (420000), link2 (115200), console (115200) | Three different UARTs on board #1 simultaneously |
| **PWM for RC servos**: 50 Hz, 1000–2000 µs pulse widths, center 1500 µs; ESP32's LEDC peripheral | `outputs` + `Esp32LedcPwm` | The universal RC actuator signal — also what the ESC consumes |
| **ADC**: attenuation (11 dB), reference/calibration (eFuse), why readings are noisy, burst averaging | `Esp32BatteryAdc` | Plus GPIO34/35 being input-only pins |
| **Interrupts (ISR)**: edge triggers, `IRAM_ATTR`, keeping ISRs tiny, debounce/lockout | `Esp32HallPulseCounter` | The 2 ms lockout vs EMI story (ROADMAP D5) |
| **I2S digital audio**: BCLK/LRCLK/DATA, sample rate (22050 Hz), DMA | `Esp32I2sAudio` | Only on board #2 |
| **WS2812 addressable LEDs**: single-wire 800 kHz protocol, timing sensitivity, level-shifting problem | `Esp32NeoPixelStrip` + build-sheet fixes | Why the 330 Ω / 1000 µF / 1N5819 fixes exist |
| **FreeRTOS tasks & cores**: task pinning, priorities, why audio gets its own core | soundlight `main.cpp` `audioTask` | Plus the dead-man watchdog pattern |
| **NVS (non-volatile storage)**: flash wear, versioned blobs, corruption guards | `Esp32NvsStore`, `lib/settings` | The "never-brick guard chain" |
| Strapping pins / boot-time GPIO constraints | `CLAUDE.md` §1 pin-map note | Why GPIO 0/2/12/15 and 6–11 are avoided |
| Watchdogs / dead-man patterns | soundlight audio task; both failsafe timeouts | A recurring safety idiom in this project |
| PlatformIO: environments, `lib/` resolution, native vs cross builds, Unity tests | `platformio.ini` ×2 | Your day-to-day build tool |
| Wokwi simulation | `wokwi.toml`, `diagram.json`, `SIMULATION.md` | Run the whole firmware with zero hardware |

## 4.3 Electronics concepts

| Concept | Where it bites |
|---|---|
| Voltage dividers (27k/10k → scaling 8.4 V into ADC range), source impedance & the 100 nF cap | battery sense; `D8_BENCH_BRINGUP.md` Phase 0 |
| Pull-up resistors + open-collector outputs (A3144 Hall on 5 V pulled to 3.3 V) | wheel speed |
| Logic levels: 3.3 V vs 5 V domains, level shifting (WS2812 data problem, 1N5819 trick) | LED strip; link2 is 3.3 V↔3.3 V so no shifting |
| BEC/UBEC, power rails, why two rails (noise isolation), decoupling caps (1000 µF servo rail) | `00_BUILD_SHEET.md`, atlas ELEC-02 |
| Common ground — why every signal needs it | atlas note; link2 spec |
| Back-feed hazards (the isolated ESC red wire) | build sheet fix #1 |
| Brushless motors, sensored vs sensorless, what an ESC does, arming | ESC docs refs; `EscOutput` |
| Hall-effect sensors + magnets | wheel speed |
| LiPo batteries: 2S = 7.4 V nominal / 8.4 V full, low-voltage limits, why monitoring | `BatteryMonitor` thresholds 7.0/7.4 V |
| EMI near motors (why the Hall line gets scoped, plausibility clamps) | ROADMAP D5, D8 Phase 8 |
| ADC nonlinearity + calibration | `Esp32BatteryAdc`, D8 Phase 8 |

## 4.4 RC / radio-control concepts

| Concept | Where it bites |
|---|---|
| TX/RX, binding, bind phrase, channels (16), model of "a radio channel" | ELRS setup; `CLAUDE.md` |
| **ExpressLRS (ELRS)**: 2.4 GHz LoRa-based link, packet rates, LQ (link quality), telemetry backchannel, failsafe modes ("No Pulses" vs "Set Position" — finding A8!) | D8 Phase 2; `CrsfReceiver` LQ latch |
| **CRSF protocol**: framing, 0x16 RC channels (172–1811, center 992), 0x14 link stats, telemetry frames 0x08/0x02/0x21 | `lib/crsf`; `shared/crsf.js` |
| elrs-joystick-control (the third-party PC tool) | atlas ELEC-03; D8 Phase 7b |
| Servo semantics: endpoints, trim, expo, deadband | `ServoOutput`, `ChannelDecoder` |
| Failsafe philosophy: link-loss handling, arm gates, re-arm rules | `failsafe`, `ArmGate` — the heart of the project |
| F1 concepts being simulated: DRS, ERS (deploy/harvest), gears, rain light, halo | `ers`, `gearbox`, `lights` |
| FPV: camera → video link → screen; latency; OpenIPC ecosystem (majestic config) | ground station SETUP.md |

## 4.5 Ground-station / desktop-app concepts

| Concept | Where it bites |
|---|---|
| Node.js + npm basics: package.json, scripts, node_modules, optional deps | `w17-ground-station` root |
| **Electron architecture**: main process vs renderer process vs preload, IPC, contextBridge | `main/main.js`, `main/preload.cjs` |
| The renderer is "just a web page": HTML/CSS/JS, canvas/DOM animation | `renderer/hud.*` |
| Gamepad API (browser) | `renderer/hud.js` |
| Video streaming chain: RTSP → mediamtx (media server) → WebRTC → WHEP (HTTP signaling for WebRTC playback) | `main/mediamtx.js`, `renderer/whep.js`, SETUP.md |
| Video codecs: H.264 vs H.265, why Chromium WebRTC can't do H.265 | SETUP.md §1 (the #1 bench risk) |
| Serial ports on the PC: exclusive COM access on Windows, com0com virtual splitters | TELEMETRY.md |
| vitest (JS unit testing) + the golden-vector cross-repo testing idea | `test/*.test.js` |
| electron-builder packaging, code signing / SmartScreen | `electron-builder.yml`, CODESIGNING.md |

## 4.6 What you can safely skip (for now)

- Deep FreeRTOS internals (only task-pinning + one atomic word are used).
- ESP-IDF beyond the legacy I2S driver and NVS Preferences wrappers.
- WebRTC internals (ICE/SDP) — WHEP hides them; treat `whep.js` as a black box first pass.
- 3D-printing/mechanical docs — needed for the build, not for the software.
- The Mermaid/HTML mechanics of the atlas & HUD mockup.
