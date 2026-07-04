# Source Code Explanation — Progress

Status values: `not started` → `explained` → `needs review` (you flagged questions) →
`reviewed` (you confirmed understanding). Priority = batch order from
`source_code_explanation_plan.md`. Updated after every batch.

**Last updated: 2026-07-03 — C9b explained (tests run + passing). Next: C10.**

C9 split (APPROVED; C9a done, C9b pending):
- **C9a — Settings persistence** → `09a_settings_persistence.md`. **DONE.** Files: `lib/settings/
  Settings.{hpp,cpp}` + `test/test_settings/test_main.cpp`. **`MockSettingsStore.hpp` confirmed
  NOT used by test_settings → moved to C9b.** Test: `pio test -e native -f test_settings`.
  Risk findings resolved: checksum IS the same 0xD5 CRC-8 as crsf/link2 (a THIRD self-contained
  copy — source-identical + cross-check test on "123456789", so proven not assumed); blob =
  [version][RAW struct memcpy][crc8], CRC over [version+struct]; guard chain length→CRC→version→
  valid(), out untouched on failure; kDefaults constexpr + static_assert(kDefaults.valid()).
- **C9b — Console + tuning HAL** → `09b_console_and_tuning_hal.md`. Files: `lib/console/
  Console.{hpp,cpp}` + `ConsoleRunner.{hpp,cpp}` + `lib/settings_hal_esp32/*` (Esp32NvsStore
  + Esp32SerialConsole) + `MockCharIO.hpp` (+ MockSettingsStore if not in C9a) +
  `test/test_console/test_main.cpp`. Test: `pio test -e native -f test_console`. Risks: C++
  string parsing (cstdio/cstdlib/cstring); DISARMED gating + per-set valid(); set=RAM-only vs
  save=NVS; both HAL files excluded from native tests (PROVISIONAL); resolves the C1
  settings_hal_esp32 library.json-deps curiosity. Depends on C9a (console → settings).

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
- **C3** → `code_explained/control_fw/03_crsf_framing_and_channel_decoding.md`. Explained
  CrsfFrame constants, the 3-state assembler (framing+CRC, type-agnostic A7, resync A9),
  and CrsfParser (bit-by-bit CRC-8/0xD5, the 11-bit little-endian channel unpacker, frame
  decode, link-stats copy). Full worked bit example: all-992 payload = E0 03 1F F8…,
  channels 0 and 1 decoded by hand → 992. Ran `pio test -e native -f test_crsf` → 29/29
  PASSED (the 15 C3-relevant cases directly back the VERIFIED labels; CRC correctness
  rests on the known-answer test, not the hand trace). `test_crsf` line-by-line is C4.
  No new open questions.
- **C3 review (2026-07-03):** audited against the C3 sources; spot-checked cited tests in
  test_crsf (allowed for verification only). Re-derived all critical arithmetic — CRC span
  (`length−1`=23), buffer indexes (`buffer_[25]` CRC, `buffer_+3` payload, 64-byte bound),
  little-endian bit order, and the all-992 unpack worked example (channels 0/1 → 992):
  ALL correct, no off-by-one / index / endianness / unpacking errors. VERIFIED-vs-protocol
  separation sound (CRC correctness rests on the known-answer test `"123456789"`→0xBC,
  confirmed present in test_crsf:155). One minimal fix: the CRC hand-example showed
  `(0xB0<<1)=0x60` (post-truncation), mildly contradicting the doc's own `<<1`-is-9-bit
  lesson; corrected to show `0x160 → ^0xD5 → 0x1B5 → cast → 0xB5`. Status: reviewed.
- **C4** → `code_explained/control_fw/04_crsf_receiver_facade_and_frame_building.md`. Ran
  `pio test -e native -f test_crsf` → 29/29 PASSED. Walked the full 541-line test file
  (C3 tests summarized, C4 receiver+builder tests detailed with byte math). Explained the
  CrsfReceiver facade (owned copies A6, per-type length check A7, `lastRcFrameMs_` only on
  RC frames), the LQ-failsafe latch (mechanism = persistence of `linkStats_`; no timer;
  clears only on LQ>0 stats — A8), `linkUp()` as reporting-not-authority, the frame
  builders (big-endian battery/GPS — RESOLVES the C3 PROVISIONAL; flight-mode NUL string),
  and Esp32CrsfUart (no hal:: interface, unlike Esp32LedcPwm). No new open questions;
  forward-links to C10 (rxSignalsFailsafe→FSM wiring; available()-guarded read()).
- **C4 review (2026-07-03):** audited against the C4 sources. Independently re-verified all
  frame-builder byte math (battery 79→00 4F, cap 0x0004D2→00 04 D2 at frame[7..9], GPS
  speed 0x0169 at frame[11..12], altitude 0x03E8 at frame[15..16], flightmode NUL/trunc):
  all correct, big-endian claims sound. LQ-latch explanation accurate (persistence of
  linkStats_, no timer, clears only on LQ>0); reporting-vs-authority separation correct
  (FSM wiring properly marked C10). One minimal fix: the Esp32CrsfUart `begin()` bullet
  over-claimed "VERIFIED (matches PinMap.hpp)" for GPIO16/17 — but the file takes rxPin_/
  txPin_ as constructor args and never references PinMap; only baud + 8N1 are hardcoded.
  Softened to: baud/8N1 VERIFIED here, pins injected by main.cpp (PROVISIONAL until C10).
  Status: reviewed.
- **C5** → `code_explained/control_fw/05_channels_mapping_and_arm_gate.md`. Ran
  `pio test -e native -f test_channels` → 21/21 PASSED. Covered ChannelDecoder
  (piecewise-linear 820/819 normalization exact at 172/992/1811, ±250 switch hysteresis,
  first-decode seeding, OFF→ON gear edges consume-on-read, tri-state drive mode w/ strict
  ±333, valid() polices safety indices but not optional ones = safe-degrade) and ArmGate
  (disarm-priority, |throttle|≤60 arms, once-armed-stays, fresh-neutral after any disarm
  incl. failsafe A3). KEY SAFETY FRAMING: neither class commands outputs — decode()→Controls,
  update()→bool; all "blocks throttle / steering live disarmed / forceDisarm=Safe" wiring is
  PROVISIONAL until C10. Default channel indices PROVISIONAL (open q #5, D8-4); brake meaning
  of negative throttle is C2/ESC (open q #29). No new open questions.
- **C5 review (2026-07-03):** audited against the C5 sources. Verified ArmGate polarity
  (`!armSwitchOn || forceDisarm`→disarm; `|thr|≤60` inclusive arms; once-armed-stays), the
  valid() policed-index list (steering/throttle/arm/DRS/gearUp/gearDown + threshold order;
  pan/tilt/boost/overtake/driveMode unpoliced = safe-degrade), Controls defaults
  (driveMode=1, rest 0/false), tri-state strict ±333, and all test line-ranges — all
  correct. No throttle/brake, polarity, or default-value errors; C5-commands-no-output
  framing sound. One minimal fix: the A3 bullet said "so throttle can't 'snap on' mid-drive"
  as a VERIFIED motor outcome, but the gate only reports disarmed — reworded to make the
  motor-side outcome conditional on C10 (PROVISIONAL), keeping VERIFIED on the gate's bool.
  Status: reviewed.
- **C6** → `code_explained/control_fw/06_feel_gearbox_and_ers.md`. Ran
  `pio test -e native -f test_gearbox -f test_ers` → 28/28 PASSED (14+14). Covered Gearbox
  (expo blend endpoint-exact then scale-to-maxOutput; brake/reverse x≤0 passes through
  unshaped in EVERY gear — safe only if ESC is forward/brake, open q #29; saturating shifts
  bounded by numGears; gear survives failsafe at module level; monotonicity guard in valid())
  and ERS (micro-permille store so drain/harvest = rate×dtMs exactly; freeze+clock-reseed
  when !ersActive; 100ms stall clamp; deploy needs held-switch AND +throttle AND energy>0,
  overtake wins; harvest needs motion + brake/coast band; applyBoost multiplies +bonus,
  clamps 1000, HARD INVARIANT applyBoost(0)==0 / negatives pass — can't move a disarmed car).
  KEY: neither module reads driveMode; the 3 modes are realized by C10 wiring (PROVISIONAL,
  ROADMAP B2.2). Clarified the confusing "failsafe is Active" naming (FSM Active = link
  healthy = NOT failsafe). No new open questions.
- **C6 review (2026-07-03):** audited against the C6 sources. Independently re-derived all
  math — gearbox expo blend + scale-to-maxOutput (endpoint-exact, x3=125 at half-cubic),
  brake x≤0 passthrough, saturating shifts; ERS energyPercent (÷10000), micro-permille
  "two 1000s cancel", deploy 26%/s→74%, overtake 40%→60%, coast 6%→54% (vs 53% truncated),
  stall clamp→97%, freeze reactivation→73%, full applyBoost table (472/944/1000, overtake
  800→1000, applyBoost(0)=0, applyBoost(−600)=−600): ALL correct, no math errors.
  "Gear survives failsafe" properly hedged (module-level VERIFIED, C10 PROVISIONAL);
  drive-mode PROVISIONAL framing and the "failsafe is Active" naming note both sound. One
  minimal fix (same pattern as C5): §4 stated "a disarmed car has shaped throttle 0" as a
  bare fact in a VERIFIED bullet — but that premise needs C10 to gate throttle when disarmed
  (§3 already hedges it). Reworded to scope VERIFIED to the applyBoost invariant and mark the
  disarmed⇒0 step PROVISIONAL. Status: reviewed.
- **C7** → `code_explained/control_fw/07_telemetry_sensors.md`. Ran
  `pio test -e native -f test_telemetry` → 16/16 PASSED. Covered BatteryMonitor (divider
  ×37/10 + ppt trim in one round-half-up division → 8399mV @ 2270 pin; scaled-accumulator
  EMA seeded from 1st sample, converges EXACTLY upward unlike naive form; warning latch =
  3s-sustained-below-7000 + hysteresis-clear-above-7400; overflow-guarded valid();
  MONITORING ONLY, never cuts) and WheelSpeed (rpm = 60,000,000/periodµs — period-based not
  count; mm/s = rpm×circ/60; plausibility clamp 5000; graceful-decay ceiling 60,000/elapsedMs
  — NOTE the µs vs ms constant difference; 1500ms hard-zero). Hall HAL = the concurrency
  deep-end: std::atomic<uint32_t> relaxed for ISR↔loop count/period (NOT volatile — explained
  why), IRAM_ATTR, trampoline+this, 2ms debounce (9× margin). ADC = analogReadMilliVolts
  (eFuse-cal, below the seam) 11dB + 4-read burst avg. Both HAL files excluded from native
  tests → all electrical/timing behavior PROVISIONAL (open q #30 ADC cal, #31 Hall EMI, D8-8).
  No current sensor (CRSF current field = 0). No new open questions.
- **C7 review (2026-07-03):** audited against the C7 sources. Re-verified ADC/battery math
  (2270→8399, trim→8483, EMA seed/converge, warn latch 3s + hysteresis 7400), WheelSpeed
  (rpm=60,000,000/periodµs, decay=60,000/elapsedMs — µs-vs-ms constants correct; clamp,
  timeout, decay table), and the concurrency section. ATOMIC/RELAXED explanation is careful
  and correct — explicitly says the count/period PAIR "may rarely be torn" and needs no
  cross-variable ordering, so it does NOT falsely imply snapshot consistency; volatile-vs-
  atomic (no atomicity, data race = UB) is accurate. No current-sensor implication (denied
  twice). One factual fix: §3 misread the maxPlausibleRpm comment — it said "~55 rev/s is
  PAST the car's top speed," but the source puts ~55 rev/s AT top speed (≈3300 rpm) with the
  clamp set higher at 5000 rpm (≈83 rev/s). Corrected. Status: reviewed.
- **C7 narrow correction (2026-07-03):** per user request, added an explicit note in §4
  (Hall lockout) tying the two thresholds together: 5000 rpm = ~83.3 rev/s = 12 ms period;
  ~55 rev/s ≈ 3300 rpm ≈ 18 ms (top-speed estimate ≠ clamp value); the 2 ms ISR lockout only
  hard-rejects edges > 30,000 rpm-equiv, so it is much looser than the 5000 rpm clamp — an EMI
  edge 2–12 ms after a real one slips through the lockout and is counted (only reported rpm is
  capped). Marked PROVISIONAL / hardware-validation (open q #31, D8 Phase 8). Verified present
  in 07 doc lines 223 + 394–406.
- **C8** → `code_explained/control_fw/08_link2_outbound_protocol.md`. Ran
  `pio test -e native -f test_link2` → 13/13 PASSED. Covered the 14-byte frame (A5 · len=11 ·
  11-byte payload · crc8), LITTLE-endian rpm/battery (contrast C4's big-endian CRSF telemetry),
  the golden frame (A5 0B 01 2A E7 4C 03 DC 05 DC 1E 3C 02 CE — same as docs + ch09), CRC =
  crsf's (duplicated for lib-portability, cross-checked by test), decode validation order
  start→length→CRC→version (so BadVersion = well-formed newer frame), assembler hard-rejects
  non-11 length immediately + resyncs (incl. 0xA5-in-payload via throttle −91), and Link2Sender
  (±1000→±100 /10 clamp; brake-light hysteresis −40 on/−20 off latched; always sends in
  failsafe; output == golden). Esp32Link2Uart implements IByteSink (unlike Esp32CrsfUart — seam
  needed because sender combines build+write); TX-only rx=-1; pin injected (PROVISIONAL C10);
  excluded from native tests. KEY: cross-repo compatibility with soundlight is PROVISIONAL until
  S1 diff-verifies the verbatim lib/link2 copy (only control-repo files read here). Re-flagged
  the stale "12-byte" comment (real frame = 14, B2.2 payload growth). No new open questions.
- **C8 review (2026-07-03):** audited against the C8 sources. Verified the 14-byte frame /
  11-byte payload / CRC-over-[1..12] span, the frame-absolute vs payload-relative index table,
  little-endian rpm/battery (DC 05 = 1500), CRC-before-version order, 0xA5-in-payload resync
  (throttle −91 = 0xA5), and consistent PROVISIONAL framing for cross-repo soundlight
  compatibility (no VERIFIED-before-S1 leak). One minimal fix: §2 claimed CRC correctness was
  "VERIFIED transitively... pinned by the `"123456789"→0xBC` known-answer test" — but the
  cross-check test uses the golden payload, a DIFFERENT input from the known-answer, so it
  doesn't literally transfer. Reworded to rest VERIFIED on three legs: identical source code +
  golden-frame test pinning link2's own CRC (0xCE) + the cross-check, with the known-answer
  noted as a separate-input crsf check. Status: reviewed.
- **C9a** → `code_explained/control_fw/09a_settings_persistence.md`. Ran
  `pio test -e native -f test_settings` → 7/7 PASSED. First half of the approved C9 split
  (persistence FORMAT only; console/NVS/serial are C9b). Covered the `Settings` struct
  (aggregates C2 ServoConfig + C6 GearboxConfig + C7 BatteryConfig; composed valid() = && of
  sub-valid()s), `kDefaults` constexpr + `static_assert(kDefaults.valid())`, blob layout
  `[version][RAW struct memcpy][crc8]` with CRC over `[version+struct]`, and the never-brick
  guard chain length→CRC→version→valid() (out untouched on failure). KEY FINDINGS: (1) the
  checksum is the SAME 0xD5 CRC-8 as crsf/link2 — a third self-contained copy, PROVEN by
  identical source + the `"123456789"` cross-check test, not assumed; (2) blob uses a RAW
  struct memcpy (deterministic same-build only; NOT portable like link2 — so no golden-blob,
  and I claim no numeric sizeof(Settings)); (3) valid() (guard 4) catches CRC-valid-but-out-of-
  range blobs — integrity ≠ correctness. "Never-brick" carefully bounded (means: never applies
  invalid settings → defaults; does NOT mean flash/lifecycle proven — that's C9b/C10/hardware).
  MockSettingsStore confirmed unused by test_settings → deferred to C9b. No new open questions
  (C1 settings_hal_esp32 library.json curiosity still open → C9b). Recovered after a token-limit
  interruption: doc was complete; only bookkeeping (progress/glossary) remained.
- **C9a teaching aid (2026-07-03):** wrote `09a_concept_teaching_notes.md` (a beginner concept
  companion — 17 concepts + 20-question quiz + answer key + readiness checklist) at user request.
  No source read beyond already-explained C9a files; no new claims.
- **C9b** → `code_explained/control_fw/09b_console_tuning_and_settings_store.md`. Ran
  `pio test -e native -f test_console` → 15/15 PASSED. Covered the pure `Console` (grammar
  help/status/get/set/save/load/reset; tokenizer + parsers `tokEq`/`tokenize`/`parseInt`/
  `parseGearIndex`; string fns strlen/strncmp/strtol/snprintf/strstr explained), the DISARMED gate
  (set/save/load/reset refused while armed; get/status/help always), **per-set validation on a
  TRIAL COPY** (`next = s` → `next.valid()` → commit only if valid — invalid never reaches live
  RAM), and the set/save/load/reset semantics table (set=RAM; save=serialize+store.save;
  load=store.load+deserialize; reset=RAM→kDefaults, no persist; failed save/load leave RAM
  untouched). `ConsoleRunner` = boot-load w/ defaults fallback + non-blocking CRLF line assembly +
  flood guard + save/load plumbing. Esp32NvsStore (Preferences/NVS, read-only load / rw-in-save)
  and Esp32SerialConsole (UART0, tuning-build-only) are HAL → excluded from native tests →
  flash/serial PROVISIONAL (open q #34a, #34b). RESOLVED the C1 curiosity: settings_hal_esp32
  library.json has no deps key — benign PlatformIO LDF auto-discovery of `hal`. PROVISIONAL/C10:
  main.cpp wiring (real seams, poll cadence, true arm state, setConfig apply loop) + how the
  console-free gift firmware loads persisted settings.

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
| `lib/crsf/include/crsf/CrsfFrame.hpp` | C3 | reviewed | header read during ch09 |
| `lib/crsf/include/crsf/CrsfFrameAssembler.hpp` + `src/CrsfFrameAssembler.cpp` | C3 | reviewed | |
| `lib/crsf/include/crsf/CrsfParser.hpp` + `src/CrsfParser.cpp` | C3 | reviewed | 11-bit unpacking |
| `lib/crsf/include/crsf/CrsfReceiver.hpp` + `src/CrsfReceiver.cpp` | C4 | reviewed | LQ latch |
| `lib/crsf/include/crsf/CrsfFrameBuilder.hpp` | C4 | reviewed | header-only |
| `lib/crsf_hal_esp32/include/.../Esp32CrsfUart.hpp` + `src/Esp32CrsfUart.cpp` | C4 | reviewed | |
| `test/test_crsf/test_main.cpp` | C4 | reviewed | 541 lines; key tests deep, rest catalogued |
| `lib/channels/include/channels/ChannelDecoder.hpp` + `src/ChannelDecoder.cpp` | C5 | reviewed | |
| `lib/channels/include/channels/ArmGate.hpp` + `src/ArmGate.cpp` | C5 | reviewed | header read during ch10 |
| `test/test_channels/test_main.cpp` | C5 | reviewed | |
| `lib/gearbox/include/gearbox/Gearbox.hpp` + `src/Gearbox.cpp` | C6 | reviewed | header read during ch10 |
| `lib/ers/include/ers/ErsSystem.hpp` + `src/ErsSystem.cpp` | C6 | reviewed | header read during ch10 |
| `test/test_gearbox/test_main.cpp` | C6 | reviewed | |
| `test/test_ers/test_main.cpp` | C6 | reviewed | |
| `lib/telemetry/include/telemetry/BatteryMonitor.hpp` + `src/BatteryMonitor.cpp` | C7 | reviewed | |
| `lib/telemetry/include/telemetry/WheelSpeed.hpp` + `src/WheelSpeed.cpp` | C7 | reviewed | |
| `lib/telemetry_hal_esp32/include/.../Esp32BatteryAdc.hpp` + `src/Esp32BatteryAdc.cpp` | C7 | reviewed | |
| `lib/telemetry_hal_esp32/include/.../Esp32HallPulseCounter.hpp` + `src/Esp32HallPulseCounter.cpp` | C7 | reviewed | ISR + atomics |
| `test/mocks/FakeVoltageSensor.hpp`, `FakeWheelPulseSensor.hpp` | C7 | reviewed | |
| `test/test_telemetry/test_main.cpp` | C7 | reviewed | |
| `lib/link2/include/link2/Link2Frame.hpp` | C8 | reviewed | header read during ch09 |
| `lib/link2/include/link2/Link2Codec.hpp` + `src/Link2Codec.cpp` | C8 | reviewed | |
| `lib/link2/include/link2/Link2Sender.hpp` + `src/Link2Sender.cpp` | C8 | reviewed | |
| `lib/link2_hal_esp32/include/.../Esp32Link2Uart.hpp` + `src/Esp32Link2Uart.cpp` | C8 | reviewed | |
| `test/mocks/MockByteSink.hpp` | C8 | reviewed | |
| `test/test_link2/test_main.cpp` | C8 | reviewed | golden frame |
| `lib/settings/include/settings/Settings.hpp` + `src/Settings.cpp` | C9a | explained | blob format + never-brick guard chain |
| `test/test_settings/test_main.cpp` | C9a | explained | 7 tests, all guard classes |
| `lib/console/include/console/Console.hpp` + `src/Console.cpp` | C9b | explained | grammar + per-set trial-copy validation + DISARMED gate |
| `lib/console/include/console/ConsoleRunner.hpp` + `src/ConsoleRunner.cpp` | C9b | explained | boot-load, non-blocking line assembly, save/load plumbing |
| `lib/settings_hal_esp32/include/.../Esp32NvsStore.hpp` + `src/Esp32NvsStore.cpp` | C9b | explained | NVS/Preferences; excluded from native tests (PROVISIONAL) |
| `lib/settings_hal_esp32/include/.../Esp32SerialConsole.hpp` + `src/Esp32SerialConsole.cpp` | C9b | explained | UART0, tuning-build-only; excluded from native tests |
| `test/mocks/MockCharIO.hpp`, `MockSettingsStore.hpp` | C9b | explained | both used by test_console |
| `test/test_console/test_main.cpp` | C9b | explained | 15 tests (console + runner + module setConfig) |
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
