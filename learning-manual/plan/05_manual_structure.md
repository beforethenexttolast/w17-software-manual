# 05 — Proposed learning-manual/ Structure

The full manual will be written into this folder as the numbered parts below. Each
chapter follows the same recipe: **(1) concepts primer → (2) architecture of the module →
(3) guided code walkthrough (line-by-line where it earns it) → (4) "prove it to yourself"
exercises using the existing tests/sim → (5) confirmed-vs-assumed notes.**

```
learning-manual/
├── README.md                        # index + status (exists)
├── 01..07_*.md                      # this plan phase (exists)
│
├── part0-orientation/
│   ├── 0.1-what-is-this-project.md          # the car, the gift, the three repos
│   ├── 0.2-hardware-tour.md                 # every physical part, with photos/links from BOM
│   ├── 0.3-signal-tour.md                   # follow one stick movement end-to-end (gamepad→wheel→sound→HUD)
│   └── 0.4-toolchain-setup.md               # PlatformIO, running the 147+40 tests, npm, Wokwi
│
├── part1-cpp-primer/                        # taught ON this codebase, not abstractly
│   ├── 1.1-files-headers-compilation.md     # .hpp/.cpp, preprocessor, using PinMap.hpp as the specimen
│   ├── 1.2-types-structs-enums.md           # fixed-width ints, struct configs, enum class states
│   ├── 1.3-classes-and-state.md             # FailsafeStateMachine as the teaching example
│   ├── 1.4-interfaces-and-testability.md    # lib/hal seams, virtual/override, mocks — THE house pattern
│   ├── 1.5-constexpr-static_assert.md       # "invalid config can't compile"
│   ├── 1.6-bytes-bits-endianness.md         # shifts/masks, packing — prep for protocol chapters
│   └── 1.7-reading-unity-tests.md           # how test_main.cpp files work; running one test suite
│
├── part2-embedded-primer/
│   ├── 2.1-esp32-and-arduino-model.md       # the chip, setup/loop, millis, non-blocking cadences
│   ├── 2.2-uart.md                          # serial fundamentals; the three UARTs on board #1
│   ├── 2.3-servo-pwm-and-ledc.md            # 50 Hz / 1000–2000 µs; Esp32LedcPwm walkthrough
│   ├── 2.4-adc-and-the-battery-divider.md   # electronics + Esp32BatteryAdc together
│   ├── 2.5-interrupts-and-the-hall-sensor.md# ISR, IRAM_ATTR, atomics, debounce/lockout
│   └── 2.6-power-rails-and-grounds.md       # BECs, caps, common ground, the bench fixes explained
│
├── part3-control-firmware/                  # the core of the manual; one chapter per lib
│   ├── 3.1-crsf-link.md                     # ELRS+CRSF concepts → assembler → parser → receiver facade (incl. the LQ latch / A8 story)
│   ├── 3.2-channels-and-armgate.md          # mapping, normalization, hysteresis, edges; the arm-gate safety contract
│   ├── 3.3-failsafe.md                      # the state machine, bug A1 as a case study in safety design
│   ├── 3.4-outputs.md                       # ServoOutput/EscOutput/DrsOutput; boot arm hold; trim rules (A11)
│   ├── 3.5-gearbox.md                       # expo math, scale-vs-clip, the feel table
│   ├── 3.6-ers.md                           # the energy model, micro-permille integer math, mode selector
│   ├── 3.7-telemetry-sensors.md             # BatteryMonitor (EMA, hysteresis latch) + WheelSpeed (period→rpm)
│   ├── 3.8-link2-protocol.md                # the wire format byte-by-byte, golden frame decoded by hand
│   ├── 3.9-telemetry-uplink.md              # CrsfFrameBuilder battery/GPS/flightmode frames to the HUD
│   ├── 3.10-settings-and-console.md         # tunables, NVS blob, never-brick chain, the console grammar
│   ├── 3.11-main-cpp-grand-tour.md          # the 403-line line-by-line: wiring + the three cadences
│   └── 3.12-simulation-and-tests.md         # Wokwi walkthrough phase-by-phase; test-suite tour; CI
│
├── part4-soundlight-firmware/
│   ├── 4.1-link2-receiver-and-monitor.md    # assembler reuse, staleness watchdog, per-field failsafe
│   ├── 4.2-enginesim.md                     # the virtual engine model
│   ├── 4.3-soundsynth.md                    # DSP for beginners: wavetables, partials, LFSR noise, ERS whine
│   ├── 4.4-i2s-and-the-amp.md               # I2S + MAX98357A + straps
│   ├── 4.5-lights.md                        # compositor layers, gamma, power budget
│   ├── 4.6-dual-core-main.md                # main.cpp: cores, the atomic param word, the dead-man
│   └── 4.7-bench-demo-and-tests.md          # SimLink2Feeder, the 14 s loop, 40 tests
│
├── part5-ground-station/
│   ├── 5.1-electron-anatomy.md              # main/preload/renderer, IPC, run scripts
│   ├── 5.2-video-pipeline.md                # RTSP→mediamtx→WebRTC/WHEP; the H.265 risk
│   ├── 5.3-hud.md                           # gamepad mirroring + simulation + overlay precedence
│   ├── 5.4-telemetry-path.md                # crsf.js port, serial source, merging, the COM-port problem
│   └── 5.5-tests-packaging.md               # vitest golden vectors; electron-builder; code signing
│
├── part6-cross-cutting/
│   ├── 6.1-safety-architecture.md           # every failsafe layer in one picture (RX→FSM→ArmGate→ESC hold→link2 staleness→audio dead-man)
│   ├── 6.2-protocol-family-tree.md          # CRSF vs link2 vs telemetry frames; shared CRC8; golden-vector strategy
│   ├── 6.3-testing-philosophy.md            # pure-logic seams, mocks, golden frames, 3-stage validation
│   └── 6.4-decision-history.md              # annotated tour of ROADMAP findings A1–A13 + design changes
│
└── part7-bench-companion/                   # (optional, written when hardware arrives)
    └── 7.1-d8-runbook-annotated.md          # D8_BENCH_BRINGUP.md with explanations of WHY each step exists
```

## Sizing and pacing

- Parts 0–2 are prerequisites: ~10 sessions of light reading + running tests.
- Part 3 is the heart: each chapter is one study session (read primer → walk code →
  run that module's test suite and break a test on purpose to see it fail).
- Parts 4–5 reuse concepts from parts 1–3, so they go faster.
- Part 6 is synthesis — best saved for after parts 3–5.
- Part 7 waits for hardware; it annotates rather than duplicates `D8_BENCH_BRINGUP.md`.

## Conventions the manual will keep

- Every code excerpt cites `repo/path:line`.
- Every claim tagged [C]/[I]/[A] as in this plan.
- Each chapter ends with a **glossary delta** (new terms) and **exercises** that only use
  existing project tooling (run a test, tweak a Wokwi input, decode a hex frame by hand).
- No source-repo file is ever modified; exercises that suggest edits are "try and revert"
  and clearly marked, deferred until you explicitly allow write access.
