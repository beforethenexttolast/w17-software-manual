# 06 — Suggested Learning Order

The order below minimizes "forward references" — at every step you only need concepts
already covered. It also matches the project's own dependency direction: safety core →
inputs → outputs → feel → protocols → consumers.

## Phase A — Orientation (no code yet)

1. **Read the docs in this order:**
   1. `w17-control-fw/CLAUDE.md` — the founding brief (everything else implements it)
   2. `w17-control-fw/docs/w17_wiring_assembly_atlas.html` — open in a browser; Part A only
   3. `w17-control-fw/docs/link2_protocol.md` — your first real protocol spec; short
   4. `w17-control-fw/docs/ROADMAP.md` — skim part A (the bug findings), read part B headers
   5. `w17-soundlight-fw/CLAUDE.md` + `README.md`
   6. `w17-ground-station/README.md` + `docs/TELEMETRY.md`
   7. Defer: BOM, print spec, build sheet (physical build docs — read when parts arrive)
2. **Get the toolchain running** (proves everything without hardware):
   - `pio test -e native` in both firmware repos (expect 147 and 40 passing tests)
   - `npm install && npm test && npm run demo` in the ground station
   - Optional: the Wokwi sim (`docs/SIMULATION.md`) — the single best "see it work" artifact

## Phase B — C++ + embedded primers (parts 1–2 of the manual)

Learn on these exact files, in this order (each teaches the next concept with minimal new
syntax):

| Step | File(s) | Teaches |
|---|---|---|
| B1 | `lib/config/include/config/PinMap.hpp` (38 lines) | headers, namespaces, constexpr, fixed-width ints |
| B2 | `lib/hal/include/hal/IClock.hpp`, `IPwmOutput.hpp` | abstract interfaces — the house pattern |
| B3 | `lib/failsafe/` (header + 42-line cpp) | classes, enum class, a real state machine |
| B4 | `test/test_failsafe/test_main.cpp` | how tests exercise a module; run it, break it, rerun |
| B5 | `lib/outputs/` + `lib/outputs_hal_esp32/Esp32LedcPwm.cpp` | pure logic vs HAL twin; servo PWM concepts |
| B6 | `test/mocks/MockPwmOutput.hpp` + `test_outputs` | mocks close the loop on the seam pattern |

**Line-by-line explanation should begin at B3 (`FailsafeStateMachine`)** — it's the
smallest module with real behavior, it's the safety heart of the car, and its history
(bug A1 in `ROADMAP.md`) makes a perfect case study of *why* the code looks the way it
does.

## Phase C — The control firmware, module by module (part 3)

Order and prerequisites:

| Step | Module | Needs first |
|---|---|---|
| C1 | `crsf` (assembler → parser → receiver) | bits/bytes/CRC primer (manual 1.6); CRSF/ELRS concepts |
| C2 | `channels` (`ChannelDecoder`, `ArmGate`) | C1 (its input) + failsafe (B3) |
| C3 | `gearbox` | integer/expo math primer |
| C4 | `ers` | C3 (it multiplies gearbox output); scaled-integer math |
| C5 | `telemetry` (`BatteryMonitor`, `WheelSpeed`) | ADC + ISR primers (manual 2.4–2.5) |
| C6 | `link2` (codec, sender) | C1's CRC (same algorithm); protocol doc |
| C7 | telemetry uplink (`CrsfFrameBuilder` battery/GPS/flightmode) | C1, C5 |
| C8 | `settings` + `console` | everything above (it tunes them) |
| C9 | **`src/main.cpp` grand tour — the second line-by-line milestone** | C1–C8; this is where all modules meet |
| C10 | Wokwi sim + full test-suite tour + `ci.yml` | C9 |

## Phase D — Sound + light firmware (part 4)

| Step | Module | Needs first |
|---|---|---|
| D1 | `link2` (receiver view) + `link2monitor` | C6 |
| D2 | `enginesim` | state-machine fluency (B3) |
| D3 | `soundsynth` + I2S HAL | D2; DSP primer (the hardest math in the project — budget extra time) |
| D4 | `lights` + NeoPixel HAL | none beyond primers |
| D5 | dual-core `main.cpp` + atomics — third line-by-line milestone | D1–D4; atomics primer |

## Phase E — Ground station (part 5)

JavaScript is more forgiving than C++, and you'll already know the protocols:

| Step | Files | Needs first |
|---|---|---|
| E1 | `shared/crsf.js`, `crsfAssembler.js`, `crsfTelemetry.js`, `telemetry.js` | C1/C7 (it's the same protocol, in JS) |
| E2 | `main/main.js`, `preload.cjs`, `scripts/run.js` | Electron-anatomy primer |
| E3 | `renderer/hud.js` (+ mockup `docs/f1_hud.html` for design intent) | E2 |
| E4 | `main/mediamtx.js`, `renderer/whep.js`, `mediamtx.yml` | video-pipeline primer |
| E5 | `main/CrsfSerialSource.js`, `shared/replaySource.js`, tests | E1–E2 |

## Phase F — Synthesis (part 6)

- The safety architecture end-to-end (all five failsafe layers in one diagram)
- The protocol family tree + golden-vector testing strategy
- The annotated decision history (ROADMAP A1–A13 + Phase-2 design changes)

## Phase G — (when hardware arrives) the bench companion

Work through `docs/D8_BENCH_BRINGUP.md` with the manual's annotated version (part 7).

## Milestone summary

- **First line-by-line target:** `lib/failsafe/FailsafeStateMachine.{hpp,cpp}` (Phase B3)
- **Second:** `w17-control-fw/src/main.cpp` (Phase C9)
- **Third:** `w17-soundlight-fw/src/main.cpp` dual-core (Phase D5)
- **Everything before a milestone is preparation; everything after is reinforcement.**
