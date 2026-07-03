# Source Code Explanation — Progress

Status values: `not started` → `explained` → `needs review` (you flagged questions) →
`reviewed` (you confirmed understanding). Priority = batch order from
`source_code_explanation_plan.md`. Updated after every batch.

**Last updated: 2026-07-03 — C2 explained (tests run + passing). Next: C3.**

Batch log:
- **C1** → `code_explained/control_fw/01_foundations_pins_hal_failsafe.md`. Ran
  `pio test -e native -f test_failsafe` → 8/8 PASSED. No new open questions; two
  PROVISIONAL curiosities noted (settings_hal_esp32 deps; FakeClock usage) for C9/C2.
- **C1 review (2026-07-03):** audited against the C1 sources. Two minimal fixes applied:
  (1) library.json count corrected 19→17 (scan was w17-control-fw only; soundlight's 8
  come in S-batches); (2) flagged that `IByteSink.hpp`'s "12 bytes" comment is stale —
  the real v1 frame is 14 bytes (`Link2Frame.hpp`), matching the 9→11 payload growth in
  ROADMAP B2.2. Rest of the doc verified accurate (syntax, line refs, VERIFIED/INFERRED/
  PROVISIONAL labels, failsafe walkthrough, test readings). Status: reviewed.
- **C2** → `code_explained/control_fw/02_outputs_commands_to_microseconds.md`. Ran
  `pio test -e native -f test_outputs` → 10/10 PASSED. Covered the two-sided µs scaler
  (endpoints/centre exact), ESC boot-arm hold (A5, first-call anchor, inclusive `>=`),
  DRS binary output, and the LEDC µs→duty math (`µs·65535/20000`, verified by hand;
  file excluded from native tests). No new open questions; noted only ServoConfig has a
  valid() (A11); ESC brake-not-reverse mapping is hardware-dependent (open q #29, D8-7).

## w17-control-fw

| File | Batch | Status | Notes |
|---|---|---|---|
| `lib/config/include/config/PinMap.hpp` | C1 | reviewed | §1 |
| `lib/hal/include/hal/IClock.hpp` | C1 | reviewed | §3.1 (specimen interface) |
| `lib/hal/include/hal/IPwmOutput.hpp` | C1 | reviewed | §3.2 |
| `lib/hal/include/hal/IByteSink.hpp` | C1 | reviewed | §3.2 |
| `lib/hal/include/hal/ICharIO.hpp` | C1 | reviewed | §3.2 |
| `lib/hal/include/hal/IVoltageSensor.hpp` | C1 | reviewed | §3.2 (seam-placement note) |
| `lib/hal/include/hal/IWheelPulseSensor.hpp` | C1 | reviewed | §3.2 (WheelPulseSnapshot struct) |
| `lib/hal/include/hal/ISettingsStore.hpp` | C1 | reviewed | §3.2 |
| `lib/*/library.json` (control repo, all 17 scanned) | C1 | reviewed | §2 (exemplar + 2-shape comparison table); soundlight library.json still pending in S-batches |
| `lib/failsafe/include/failsafe/FailsafeStateMachine.hpp` | C1 | reviewed | §4 |
| `lib/failsafe/src/FailsafeStateMachine.cpp` | C1 | reviewed | §5 |
| `test/mocks/FakeClock.hpp` | C1 | reviewed | §6 |
| `test/test_failsafe/test_main.cpp` | C1 | reviewed | §7 — ran, 8/8 PASSED |
| `lib/outputs/include/outputs/ServoOutput.hpp` + `src/ServoOutput.cpp` | C2 | explained | |
| `lib/outputs/include/outputs/EscOutput.hpp` + `src/EscOutput.cpp` | C2 | explained | |
| `lib/outputs/include/outputs/DrsOutput.hpp` + `src/DrsOutput.cpp` | C2 | explained | |
| `lib/outputs_hal_esp32/include/.../Esp32LedcPwm.hpp` + `src/Esp32LedcPwm.cpp` | C2 | explained | |
| `test/mocks/MockPwmOutput.hpp` | C2 | explained | |
| `test/test_outputs/test_main.cpp` | C2 | explained | |
| `lib/crsf/include/crsf/CrsfFrame.hpp` | C3 | not started | header read during ch09 |
| `lib/crsf/include/crsf/CrsfFrameAssembler.hpp` + `src/CrsfFrameAssembler.cpp` | C3 | not started | |
| `lib/crsf/include/crsf/CrsfParser.hpp` + `src/CrsfParser.cpp` | C3 | not started | 11-bit unpacking |
| `lib/crsf/include/crsf/CrsfReceiver.hpp` + `src/CrsfReceiver.cpp` | C4 | not started | LQ latch |
| `lib/crsf/include/crsf/CrsfFrameBuilder.hpp` | C4 | not started | header-only |
| `lib/crsf_hal_esp32/include/.../Esp32CrsfUart.hpp` + `src/Esp32CrsfUart.cpp` | C4 | not started | |
| `test/test_crsf/test_main.cpp` | C4 | not started | 541 lines; key tests deep, rest catalogued |
| `lib/channels/include/channels/ChannelDecoder.hpp` + `src/ChannelDecoder.cpp` | C5 | not started | |
| `lib/channels/include/channels/ArmGate.hpp` + `src/ArmGate.cpp` | C5 | not started | header read during ch10 |
| `test/test_channels/test_main.cpp` | C5 | not started | |
| `lib/gearbox/include/gearbox/Gearbox.hpp` + `src/Gearbox.cpp` | C6 | not started | header read during ch10 |
| `lib/ers/include/ers/ErsSystem.hpp` + `src/ErsSystem.cpp` | C6 | not started | header read during ch10 |
| `test/test_gearbox/test_main.cpp` | C6 | not started | |
| `test/test_ers/test_main.cpp` | C6 | not started | |
| `lib/telemetry/include/telemetry/BatteryMonitor.hpp` + `src/BatteryMonitor.cpp` | C7 | not started | |
| `lib/telemetry/include/telemetry/WheelSpeed.hpp` + `src/WheelSpeed.cpp` | C7 | not started | |
| `lib/telemetry_hal_esp32/include/.../Esp32BatteryAdc.hpp` + `src/Esp32BatteryAdc.cpp` | C7 | not started | |
| `lib/telemetry_hal_esp32/include/.../Esp32HallPulseCounter.hpp` + `src/Esp32HallPulseCounter.cpp` | C7 | not started | ISR + atomics |
| `test/mocks/FakeVoltageSensor.hpp`, `FakeWheelPulseSensor.hpp` | C7 | not started | |
| `test/test_telemetry/test_main.cpp` | C7 | not started | |
| `lib/link2/include/link2/Link2Frame.hpp` | C8 | not started | header read during ch09 |
| `lib/link2/include/link2/Link2Codec.hpp` + `src/Link2Codec.cpp` | C8 | not started | |
| `lib/link2/include/link2/Link2Sender.hpp` + `src/Link2Sender.cpp` | C8 | not started | |
| `lib/link2_hal_esp32/include/.../Esp32Link2Uart.hpp` + `src/Esp32Link2Uart.cpp` | C8 | not started | |
| `test/mocks/MockByteSink.hpp` | C8 | not started | |
| `test/test_link2/test_main.cpp` | C8 | not started | golden frame |
| `lib/settings/include/settings/Settings.hpp` + `src/Settings.cpp` | C9 | not started | |
| `lib/console/include/console/Console.hpp` + `src/Console.cpp` | C9 | not started | largest pure lib |
| `lib/console/include/console/ConsoleRunner.hpp` + `src/ConsoleRunner.cpp` | C9 | not started | |
| `lib/settings_hal_esp32/include/.../Esp32NvsStore.hpp` + `src/Esp32NvsStore.cpp` | C9 | not started | |
| `lib/settings_hal_esp32/include/.../Esp32SerialConsole.hpp` + `src/Esp32SerialConsole.cpp` | C9 | not started | |
| `test/mocks/MockCharIO.hpp`, `MockSettingsStore.hpp` | C9 | not started | |
| `test/test_settings/test_main.cpp` | C9 | not started | |
| `test/test_console/test_main.cpp` | C9 | not started | |
| `src/main.cpp` | C10 | not started | the conductor, 403 lines |
| `src/SimCrsfFeeder.hpp` + `src/SimCrsfFeeder.cpp` | C10 | not started | answers open question #48 |
| `platformio.ini` | C10 | not started | context already in ch11 §1 |
| `.github/workflows/ci.yml` | C10 | not started | answers open question #46 |
| `wokwi.toml` | — | explained | ch05 §9 (line-level: 6 lines, fully covered) |
| `diagram.json` | — | explained | ch05 §9 (part-by-part + netlist) |
| `docs/f1_hud.html` | — | summarize only | historical mockup; ch05 §10 |

## w17-soundlight-fw

| File | Batch | Status | Notes |
|---|---|---|---|
| `lib/config/include/config/PinMap.hpp` | S1 | not started | |
| `lib/link2/include/link2/Link2Frame.hpp`, `Link2Codec.hpp` + `src/Link2Codec.cpp` | S1 | not started | diff-verify vs control copy, then reference C8 |
| `lib/link2monitor/include/.../Link2Monitor.hpp` + `src/Link2Monitor.cpp` | S1 | not started | header read during ch07 |
| `test/test_link2monitor/test_main.cpp` | S1 | not started | |
| `test/test_link2/test_main.cpp` | S1 | not started | diff-check vs control's |
| `lib/enginesim/include/.../EngineSim.hpp` + `src/EngineSim.cpp` | S2 | not started | header read during ch07 |
| `test/test_enginesim/test_main.cpp` | S2 | not started | |
| `lib/soundsynth/include/.../ISampleSource.hpp` | S3 | not started | |
| `lib/soundsynth/include/.../EngineSynth.hpp` + `src/EngineSynth.cpp` | S3 | not started | hardest math in project |
| `test/test_soundsynth/test_main.cpp` | S3 | not started | |
| `lib/lights/include/.../LightRenderer.hpp` + `src/LightRenderer.cpp` | S4 | not started | |
| `lib/lights_hal_esp32/include/.../Esp32NeoPixelStrip.hpp` + `src/Esp32NeoPixelStrip.cpp` | S4 | not started | |
| `test/test_lights/test_main.cpp` | S4 | not started | |
| `lib/audio_hal_esp32/include/.../Esp32I2sAudio.hpp` + `src/Esp32I2sAudio.cpp` | S5 | not started | |
| `src/main.cpp` | S5 | not started | dual-core; answers open question #43 |
| `src/SimLink2Feeder.hpp` + `src/SimLink2Feeder.cpp` | S5 | not started | |
| `test/test_integration/test_main.cpp` | S5 | not started | frames→audio end-to-end |
| `platformio.ini` | S5 | not started | |
| `.github/workflows/ci.yml` | S5 | not started | diff vs control's |

## w17-ground-station

| File | Batch | Status | Notes |
|---|---|---|---|
| `shared/telemetry.js` | G1 | not started | |
| `shared/feelConstants.js` | G1 | not started | |
| `shared/crsf.js` | G1 | not started | JS port of firmware decoder |
| `shared/crsfAssembler.js` | G1 | not started | |
| `shared/crsfTelemetry.js` | G1 | not started | |
| `test/crsf.test.js` | G1 | not started | golden vectors |
| `test/crsfTelemetry.test.js` | G1 | not started | |
| `main/main.js` | G2 | not started | |
| `main/preload.cjs` | G2 | not started | |
| `main/mediamtx.js` | G2 | not started | |
| `main/CrsfSerialSource.js` | G2 | not started | |
| `shared/replaySource.js` | G2 | not started | |
| `test/replay.test.js` | G2 | not started | |
| `renderer/index.html` | G3 | not started | |
| `renderer/hud.css` | G3 | not started | |
| `renderer/hud.js` | G3 | not started | answers open question #47 |
| `renderer/whep.js` | G3 | not started | |
| `scripts/run.js` | G4 | not started | |
| `scripts/ensure-electron.js` | G4 | not started | |
| `scripts/fetch-mediamtx.js` | G4 | not started | |
| `package.json` | G4 | not started | |
| `electron-builder.yml` | G4 | not started | |
| `mediamtx/mediamtx.yml` | G4 | not started | |
| `package-lock.json` | — | skip | generated lockfile; concept noted in G4 |
| `mediamtx/mediamtx` (binary) | — | skip | fetched third-party binary |
