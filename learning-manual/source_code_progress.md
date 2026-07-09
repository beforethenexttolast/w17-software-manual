# Source Code Explanation — Progress

Status values: `not started` → `explained` → `needs review` (you flagged questions) →
`reviewed` (you confirmed understanding). Priority = batch order from
`source_code_explanation_plan.md`. Updated after every batch.

> **Repo-drift note (2026-07-09).** The batch entries below are dated records — they
> describe the repos as of each batch's session. Since S5 (2026-07-06) the source repos
> received the **skeptical-audit fixes F1–F4** (2026-07-07/08) and iPhone-bridge work
> W1–W3 (ground station). The audit + F1–F4 are now explained in manual **chapter 12**
> (`12_the_skeptical_audit_and_f1_f4_fixes.md` — an overview chapter, not a code batch;
> the `project-review/` docs it covers are outside this campaign's line-by-line
> inventory, like `docs/`). Effects on this file's claims:
> - **"ci.yml byte-identical to control's" is no longer true** (F1 added the tuning
>   build to control's; F3 added a link2 drift-guard job to both). #46 stays closed;
>   drift notes added to ch07 §7, the S5 doc, and open question #46. ch11 §7 is current.
> - Explained files touched by the audit (comment/doc alignment only, no behavior:
>   control `main.cpp`, `ChannelDecoder.hpp`, `Link2Frame.hpp`, `link2_protocol.md` —
>   F4; `w17-control-fw/CLAUDE.md` **rewritten** 2026-07-09 as a maintenance guide, so
>   "`CLAUDE.md` §N" citations in batch docs refer to the pre-rewrite revision). Line
>   numbers cited in batch docs may be off by a few lines for these files. 147/147
>   control tests still pass post-F4 (per the F4 commit's own validation note).
> - The `lib/link2` copy + `docs/link2_protocol.md` remain **identical across the two
>   firmware repos** (re-verified 2026-07-09) — S1's cross-repo conclusion stands.
> - ~~The **G1–G4 inventory below is stale**~~ — **RESOLVED 2026-07-09**: the G0
>   re-inventory ran (`wc -l` per file; the old table matched the 2026-07-03 tree at
>   `b5ed803` exactly), the plan's Repo-3 section was rewritten (now batches G1–G5b),
>   and the table below reflects the current tree at `dab3039`.
> - Statuses (`reviewed`/`explained`) are unchanged — no explained logic changed.

**Last updated: 2026-07-09 — G0 re-inventory + G1 explained** (`code_explained/
ground_station/01_shared_pure_core.md` — the manual's first JS batch, with the
JS-for-C++-readers primer). Verification: `npx vitest run test/crsf.test.js
test/crsfTelemetry.test.js test/linkState.test.js` → **32/32 PASSED** (13+10+9), and
the full suite → **118/118 PASSED** (8 files, 347 ms). Covered: `TelemetrySource`
observer seam + the Telemetry typedef (armed/failsafe demo-only, audit R01);
`feelConstants` (values re-checked against C6's ErsConfig: 26/11/1.18 ✓, GEARS 4 =
audit R05; drift-guard test covers 3 of 5 constants → #59a); `crsf.js` (CRC-8/0xD5
fourth implementation, KAT 0xBC re-run + golden battery CRC 0x4E independently
re-computed via node; big-endian decoders; toInt8; parseFlightMode regex; decodeFrame
sync→length→CRC order matches C3); `crsfAssembler` (compared side-by-side with the
firmware `CrsfFrameAssembler.cpp` this session — same 64-byte bound, length guard,
CRC span, no-rewind resync; JS folds decode into assembly); `crsfTelemetry` mapper
(RSSI sign flip 75→−75; GPS keeps only speedKmh; unparseable flightmode → null, not
{}); `linkState.mjs` (audit F2/R01 — four states, precedence sim→telemetry-lost→
link-lost→live, inclusive ≥1000 ms edge, strict `=== 0` so missing LQ ≠ link-lost;
stickiness lives in the caller's everLive latch); `crsf_golden.json` (audit F3/R07 —
**fixture values cross-checked against the firmware builder tests in
w17-control-fw/test/test_crsf read-only this session: battery 79 dV/72 %, GPS 361 =
36.1 km/h, flightmode "G3 M2 E55" all match** [C]; no CI job diffs the fixture across
repos — discipline rule, unlike link2's drift-guard job). One forward coupling noted:
`linkState.test.js` imports `sampleTimeline`/`DEMO_TIMELINE` from `shared/replaySource.js`
(G2). NEW **#59** (doc-consistency ×2: feelConstants' "a test guards these" overstates;
`FRAME_TYPE_RC_CHANNELS_PACKED` exported but referenced nowhere — reads as deliberate
viewer-only documentation-by-name). Bench-gated: ELRS LQ→0 behavior (#27), serial
sharing (#28), real top speed. **No hardware claims — 118 green vitest tests are
source/test evidence only; iPhone-bridge W3 stays implemented + unit-tested, NOT
real-device validated (#58).** Next: G2 (main process + telemetry sources).

Prior milestone: 2026-07-06 — S5 explained (audio HAL + dual-core main.cpp + SimLink2Feeder
+ test_integration + platformio.ini/ci.yml). THE w17-soundlight-fw EXPLANATION PHASE IS
COMPLETE (S1–S5 all `explained`; review pass pending, C-batch parity).** Verification:
`pio test -e native` → **40/40 PASSED** (all six suites incl. test_integration's 2), and
`pio run -e esp32dev -e esp32dev_sim` → **both SUCCESS** (platform espressif32 7.0.1 /
Arduino core 2.0.17 / IDF 4.4 — the pinned legacy-I2S world the ini comment promises).
**#43 FULLY ANSWERED:** main.cpp packs the atomic word each 50 Hz tick; **volume derived by
`volumeFor()`** — Off→0 (the load-bearing silence path), Cranking→70, Running→90+
throttle·165/100 (90..255, a continuum). Dead-man real and where predicted: audioTask
(core 0, prio 5, 256-frame ≈11.6 ms blocks, static 1 KiB buffer, blocking i2s.write =
self-pacing/backpressure clock) forces setParams(0,…) when the heartbeat is >500 ms old —
**but main.cpp is native-excluded (test_build_src=no), so dead-man/volumeFor/atomics/task
wiring are source+build-verified only; the dead-man has never executed anywhere (#57)**.
Cross-core surface = exactly 2 relaxed `std::atomic<uint32_t>` (audited item-by-item; no
cross-variable invariant, so relaxed suffices). Both consumers get the SAME
`monitor.state()`; lights cadence **~30 Hz (33 ms — S4's 50 Hz guess corrected)**;
render→30×setPixel→show verbatim as S4 presumed; strip.begin()/i2s.begin() (zeroed DMA =
audio boot-blank) early in setup(); Serial2 RX16/TX−1 (GPIO17 never opened); loop() on
core 1 per framework (CONFIG_ARDUINO_RUNNING_CORE=1, checked in framework source).
**ci.yml byte-identical to control's (#46 fully answered). #50 RESOLVED benign** (LDF
never resolves the dangling `hal` dep — build graph shows no child). #51 confirmed final
(main.cpp reads no state field itself). **#53 practical impact pinned:** upward volume
moves park −63 → full throttle ≈75 % rendered, crank whir ≈2.7 % (7/255), idle
path-dependent 27 vs 90 — owner question stands, audibility → bench. Feeder's 14 s script
matches SIMULATION.md's phase table (the #48 analogue) with one wording caveat. NEW **#56**
(doc-consistency: integration test's volumeFor constants ≠ main's despite its comment;
"indicators sweep L/R" but demo steering never negative; dropout window encoded twice;
"ramps to 0" = the synth's ~3 ms smoother; NeoPixel dep floats `^` vs pinned platform) and
**#57** (bench: dead-man wedge test, render CPU cost on-target, DMA buf-unit semantics /
~70 ms ring, ≈100 ms worst-case param→speaker latency, crank-whir audibility). Next:
optional S1–S5 review pass, then G1 (ground station).

Prior: S4 explained 2026-07-05 (LightRenderer + light HAL; 9/9 + independent gamma/current
recompute; #54a breathe≠hazard + #54b–d + #55 dim layers), S3 (EngineSynth DSP; 9/9 +
harness; #43 layout half; #52 doc-lag + #53 smoother parking), S2 (EngineSim; 9/9; wheel
rpm unconsumed — #51), S1 (link2 receiver; 40/40; copy md5-identical; C8 cross-repo
PROVISIONAL → VERIFIED). All C1–C10 remain `reviewed`.

Prior milestone: 2026-07-05 — C10 explained + C2 review pass (all C1–C10 `reviewed`;
147/147 control native tests, all 3 control firmware envs build SUCCESS). The
w17-control-fw campaign's explanation phase is COMPLETE and reviewed.

C9 split (APPROVED; both halves done):
- **C9a — Settings persistence** → `09a_settings_persistence.md`. **DONE.** Files: `lib/settings/
  Settings.{hpp,cpp}` + `test/test_settings/test_main.cpp`. **`MockSettingsStore.hpp` confirmed
  NOT used by test_settings → moved to C9b.** Test: `pio test -e native -f test_settings`.
  Risk findings resolved: checksum IS the same 0xD5 CRC-8 as crsf/link2 (a THIRD self-contained
  copy — source-identical + cross-check test on "123456789", so proven not assumed); blob =
  [version][RAW struct memcpy][crc8], CRC over [version+struct]; guard chain length→CRC→version→
  valid(), out untouched on failure; kDefaults constexpr + static_assert(kDefaults.valid()).
- **C9b — Console + tuning HAL** → `09b_console_tuning_and_settings_store.md` (final
  name; the split plan's placeholder was `09b_console_and_tuning_hal.md`). Files: `lib/console/
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
- **C2 review (2026-07-05):** audited against the C2 sources; re-ran `pio test -e native -f
  test_outputs` → **10/10 PASSED**. Independently re-derived all arithmetic — servo two-sided
  scale (0→1500, ±1000→500/2500, +500→2000, −500→1000), ESC scale (+500→1750), and every
  LEDC duty value (1000µs→3276, 1500→4915, 2000→6553, 500→1638, 2500→8191, all matching the
  doc's table) — no errors. All 10 test descriptions/assertions verified against test_main.cpp;
  A4/A5/A11 linkage correct; hardware-validation notes (open q #29, LEDC electrical) sound.
  **One factual fix:** the doc claimed "main.cpp static_asserts the default config" — main.cpp
  does NOT assert the servo/ESC/DRS configs (confirmed by grep: asserts cover channel-map/
  gearbox/ers/battery/wheel/link2/settings only). Corrected §1 to state the real enforcement
  (tuning console per-set + the tuning build's aggregate `settings::kDefaults` assert; the gift
  build trusts the default). Added a C10-resolution note (reference-member lifetime, begin()
  wiring, A5 anchor in setup(), LEDC channels 0–4, DRS-closed-on-failsafe, and the ESP32
  `Esp32MillisClock` resolving the monotonic-clock assumption). Status: reviewed.
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
- **C10** → `code_explained/control_fw/10_main_integration.md`. Verification (2026-07-05):
  `pio test -e native` → **147/147 PASSED** (all ten suites) + **all three firmware envs build
  SUCCESS** (esp32dev, esp32dev_sim, esp32dev_tuning — CI builds only the first two; tuning
  verified locally). main.cpp has NO automated test (`test_build_src = no`) → wiring claims are
  "VERIFIED (source + build)"; the composition's runtime is PROVISIONAL until the Wokwi first
  run (#35–39) / bench (D8). Covered: static-init globals + per-config static_asserts (channel
  map's promised definition-site assert included); setup() boot order (A4 safe initial pulses;
  `esc.setThrottle(0)` anchors the 2 s hold, A5; boot-safety timeline incl. reset/brownout —
  gear→1, ERS refills); loop() = unconditional UART drain (~6 ms buffer math, `available()`
  guard), event-driven decode (runs during failsafe; edges consumed same pass; shifts un-gated =
  gear survives; Training-mode shifts still change state), 50 Hz tick (FSM fed rcFrameSinceTick
  + rxSignalsFailsafe; ArmGate every tick w/ forceDisarm=Safe; `baseCommanded=(Active&&armed)?
  shaped:0` — the one line both authorities gate; ERS every tick, ersActive=Active&&mode2,
  post-gate/pre-boost throttle; boost applied post-gate (applyBoost(0)==0); Safe branch
  no-early-return; steering+DRS live while disarmed; gimbal ungated, holds aim in failsafe),
  20 Hz link2 (reports commanded throttle; lowBattery = the warning's ONLY consumer →
  monitoring-only is now whole-program), 10 Hz battery (the EMA-tau cadence), 5 Hz CRSF
  telemetry (mV→dV, mm/s→0.1 km/h = ×36/1000, FLIGHTMODE "G%u M%u E%u"); ≈540 ms worst-case
  failsafe detection derived; drive modes wired (Training = fixed {400,50} shape via free fn;
  NO raw pass-through by design); tuning-build wiring (runner + real seams; loadAtBoot +
  applyTuning in setup; per-pass poll(armGate.isArmed()) = TRUE arm state; applyTuning = 3
  setConfigs). SimCrsfFeeder's 10-phase script **matches SIMULATION.md's table** (resolves
  #48); platformio.ini names the native-exclusion mechanism (test_build_src=no + lib_ignore ×5);
  ci.yml resolved (#46 control half; #45 answered). **RESOLVED 20+ PROVISIONALs from C4–C9b**
  (resolution notes added to docs 04–08 and 09b). **KEY FINDING:** the plain esp32dev gift
  build has **NO NVS load path** — the entire settings subsystem is behind W17_TUNING_CONSOLE,
  so bench tuning never reaches the delivered firmware (runs compiled defaults); corrected
  glossary + ch05 + ch06 + C9b docs ("persists" ≠ "loads"); NEW open question #49 (delivery
  options: bake into defaults / ship tuning build / add loader). Stale comments flagged:
  ChannelDecoder.hpp "pan/tilt unwired" (gimbal is wired now); FailsafeStateMachine.hpp
  "main.cpp carries a minimal neutral-latch" (ArmGate long since exists).
- **S1** → `code_explained/soundlight_fw/01_link2_receiver_and_protocol_compatibility.md`.
  First soundlight batch; the receiver side of link2. Ran `pio test -e native -f test_link2
  -f test_link2monitor` → **11/11 PASSED**, and full `pio test -e native` → **40/40 PASSED**
  (all six soundlight suites). **Diff-verified** `lib/link2` against control: `diff -r` shows
  only `Link2Sender.{hpp,cpp}` absent (correct — sender is board #1's job, needs `hal`); `md5`
  on all 4 shared files (`Link2Frame.hpp`, `Link2Codec.hpp`, `Link2Codec.cpp`, `library.json`)
  **byte-identical**; `docs/link2_protocol.md` byte-identical too. So the copy is referenced to
  C8, not re-explained. Covered: PinMap (RX16 / reserved-ack-TX17 mirroring control's GPIO26
  open q #33 / I2S 26/25/22 / LED4; all non-strapping); the codec re-read from the receiver's
  chair (VehicleState defaults = board #2's boot state; decode+assembler now load-bearing;
  encodeFrame kept for the sim feeder + tests); and the NEW module `Link2Monitor` — LinkStatus
  {NeverConnected/Up/Lost}, `nowMs`-as-parameter time seam (no IClock), the inclusive
  `elapsed >= 500 ms` staleness edge, and the **per-field projection** on Lost (commands zeroed +
  failsafe forced true; rpm zeroed; batteryMv/lowBattery/gear/ersPercent/driveMode HELD). Both
  test files walked assertion-by-assertion; `test_link2` diff-checked = a receiver-focused
  **rewrite** (5 vs control's 13; the `0xA5`-in-payload false-sync case is pinned sender-side
  only — transfers via source identity). **RESOLVED C8 PROVISIONALs:** cross-repo compatibility
  (now VERIFIED at source/test level via md5 + shared golden frame `A5 0B 01 2A E7 4C 03 DC 05
  DC 1E 3C 02 CE`); the "two independent failsafe mechanisms" INFERRED note upgraded to VERIFIED
  (frame `failsafe` flag decodes in `decodeFrame`; local staleness failsafe is `Link2Monitor`).
  **NEW open question #50** (dangling `hal` dep in the copied `link2/library.json` — no `lib/hal`
  in soundlight; benign for native build; a cost of do-not-fork discipline). **Corrected the C8
  doc**: the stale "12-byte" comment was misattributed to `Link2Frame.hpp` — it lives only in
  control's `IByteSink.hpp:9` + `Esp32Link2Uart.hpp:14` (both sender-side, never copied), so the
  copy's format docs are accurate. No protocol mismatch found. PROVISIONAL until S5: main.cpp
  wiring (UART→feedByte, poll cadence, `millis()` as nowMs, the config `static_assert`); until
  bench: the physical GPIO25→GPIO16 wire + common ground + 115200 inter-board timing.
- **S2** → `code_explained/soundlight_fw/02_engine_simulation.md`. Ran
  `pio test -e native -f test_enginesim` → **9/9 PASSED**. Covered `EngineSim` (100+138
  lines + 9 tests): the armed-driven ignition FSM (`!armed`→Off from ANY state first
  priority — so S1's projection makes disarm/failsafe/stale/boot all one signal;
  Off→Cranking on arm with clock anchor; Cranking→Running at inclusive ≥600 ms with
  `rpm_` SNAPPED to idle = the "catch"; every return from Off replays the starter);
  linear throttle→rpm map (idle+11500·t/100 → 3500/9250/15000 endpoint-exact; negative
  throttle = braking → clamps to idle target); asymmetric exponential inertia
  (`rpm += gap·rate·dt/1000`, 6‰/3‰ per ms = 12%/6% of gap per 20 ms tick; "~0.5s/~1.2s"
  comments re-derived and honest; overshoot snap guard; ≤8/≤16 rpm truncation residual;
  100 ms stall clamp like C6 ERS; first-call dt=0). Character layer: 400 ms ±120 idle
  wobble fading with throttle (perceptual — layered on audible rpm only); ±1400×130 ms
  shift blips with TRIPLE guard (everSeenState_ seeding / Running / !failsafe) + the key
  subtlety that `lastGear_` tracks UNCONDITIONALLY so failsafe recovery can't phantom-blip
  (pairs with S1's held-gear); limiter flag at throttle≥95 ∧ base `rpm_`≥14750 (not
  audible rpm — wobble/blip can't fake it); overrun crackle window 900 ms on ≥40-pt
  one-tick drop from ≥10400 rpm (int casts make braking count: drop 100−(−100)=200);
  Off short-circuit reports engineRpm=0 IMMEDIATELY (internal rpm_ decays hidden).
  **KEY FINDING:** engine rpm is simulated from commanded throttle; `VehicleState.rpm`
  (wheel rpm) has **no consumer anywhere on board #2** (grep-verified) — the spec's
  "derive engine revs from throttlePercent" option was taken; monitor's "stale rpm would
  drive the engine sound" comment is defensive, not descriptive → **NEW note #51**.
  Ch07 §3 constants all confirmed exact (S2-verified note added). Coverage gaps logged
  honestly (§5: failsafe blip guard, wobble, negative-throttle paths, blip magnitude —
  source-verified only). PROVISIONAL: main.cpp wiring/cadence + atomic word (#43) → S5;
  all synth-side semantics (silence-when-Off, buzz cadence, crackle bursts, whine) → S3;
  speaker voicing → bench (#32).
- **S3** → `code_explained/soundlight_fw/03_sound_synthesis.md`. Ran
  `pio test -e native -f test_soundsynth` → **9/9 PASSED** (1.08 s), plus a **scratchpad
  verification harness** (compiled read-only against the real `EngineSynth.cpp`) to measure
  the integer-truncation behaviors the tests don't pin. Covered `ISampleSource` (the
  PCM-fallback render seam; alloc-/lock-free contract), `EngineSynth.hpp` (packParams word,
  config voice, class), `EngineSynth.cpp` (sine table, phaseInc, render loop) + 9 tests
  line/block-by-line. DSP verified: **32-bit phase accumulator** (2³²=one cycle; wraparound
  IS the mechanism) → `phase>>24` into a **256-entry ±256 sine table** (Taylor-7 built once,
  float only at init; ~19-count worst error at the wrap, measured); **6-partial additive
  stack** at firing freq = 5·rpm/60 (table·amp>>8 makes partialAmp = peak int16 units);
  **rpm-scaled xorshift32 noise** (`1600·rpm/15000`) + **1-in-4 ×3 overrun burst** lottery;
  **3×-pitch ERS whine** with 512-sample (~23 ms) AR ramp; master **volume/255**; **18 Hz
  50%-duty limiter** ignition-cut gate (`limiterPhase>>31`); **saturating clamp**;
  mono→stereo duplication. **Headroom budget** peakSum 24,600 ≤ 30,000 (measured peak at max
  settings = **17,944**). **ANSWERED open q #43** (packed word layout: rpm bits 0–15 · volume
  16–23 · ersWhine 24 · limiter 25 · overrun 26 · 27–31 reserved). **KEY BOUNDARY:** the synth
  reads only (rpm, volume, 3 flags) — **NOT** `throttlePercent` or `Ignition`; silence-when-Off
  must arrive as `volume=0` from `main.cpp` (**PROVISIONAL → S5**). **NEW note #52**
  (doc-consistency: repo `CLAUDE.md`/ch07 "per-revolution AM" does not exist in code; noise is
  rpm-correlated, not "throttle-correlated"; ch07 §6 packed-word list said rpm/throttle/flags →
  actually rpm/**volume**/flags — ch07 corrected). **NEW question #53** (owner: the `>>6`
  smoother contradicts its "~1/1024, ~23 ms" comment — it's 1/64 ≈ 2.9 ms — and truncation
  makes upward approaches **park short**: volume 255 renders at 192 ≈ **75%**, targets 1–63 from
  silence stay **exactly silent**; downward converges exactly, so `volume=0` truly silences —
  measured). Confirmed **#51** in-context (soundsynth never reads a `VehicleState`, let alone
  wheel rpm). Test honesty logged (§8.2): never-clips test is a tautology, volume test compares
  sound-vs-silence, packed-roundtrip/limiter tests are existence-not-cadence. PROVISIONAL → S5:
  the real `std::atomic<uint32_t>`, who packs it + volume's origin, heartbeat dead-man, task
  pinning, I2S buffer/cadence, `Esp32I2sAudio`, `test_integration`, config `static_assert` site.
  Bench (#32): whether it *sounds* like an engine on MAX98357A + 3 W speaker; the PCM fallback
  decision this seam exists for.
- **S4** → `code_explained/soundlight_fw/04_lights_and_light_hal.md`. Ran
  `pio test -e native -f test_lights` → **9/9 PASSED** (1.18 s), plus an independent script
  re-computing every gamma-LUT output, rendered-palette value, and power-budget figure.
  Covered `LightRenderer.{hpp,cpp}` (99+150), `Esp32NeoPixelStrip.{hpp,cpp}` (25+20), both
  library.jsons, and all 9 tests assertion-by-assertion. The compositor: clear → classify
  (`localFailsafe = frame.failsafe ‖ Lost`; `neverConnected`) → **early-return breathe**
  (2 s teal triangle on the halo — NeverConnected is NOT the hazard, test-pinned) →
  **early-return hazard** (all-30 amber, 2 Hz, both phases pinned; Lost alone suffices even
  with a clean frame = defense in depth over S1's projection) → base (dim red tail always;
  halo teal-armed/dim-white-disarmed) → low-battery red triangle pulse on halo (1.6 s,
  REPLACES arm color; untested in suite) → brake bright-red on `braking` (no local
  hysteresis — flag pre-filtered by C8's sender) → **rain light** (harvest derived locally:
  `harvestSeeded_` first-frame baseline, `driveMode == 2`, strict `ersPercent >` rise →
  stamp; 400 ms window; deploy = falling = never triggers, pinned) → indicators (zone map:
  ≥40 latch / 20–39 hold = hysteresis / <20 self-cancel; free-running phase-locked 660 ms
  blink) → cap-then-gamma exit (scale to 110/255 then gamma-2.2 LUT via `__builtin_pow`,
  float-at-init). **Input surface: exactly 7 VehicleState fields** (failsafe, armed,
  lowBattery, braking, driveMode, ersPercent, steeringPercent); **NOT read: throttle,
  reverse, drsOpen, ersDeploying, gear, rpm, batteryMv → no DRS light, no deploy light**
  (deploy is S3's whine; harvest is the light); zero EngineSim/EngineState/synth coupling
  (includes = link2 + link2monitor only). Power budget in `valid()`: (2·20·cap)/255 per LED
  ×30 ≤ 900 mA → default 17×30=510 ✓, cap-255 40×30=1200 ✗ (test-pinned); estimate is
  pre-gamma + both-channels-full = ~5× conservative (real hazard ≈104 mA). HAL:
  `NEO_GRB + NEO_KHZ800` (lib handles GRB wire order), `begin()` = begin+clear+show =
  **boot-blank** (WS2812s power up random — the visual twin of C2's A4), buffer-then-show
  model (~0.9 ms wire time for 30 px); espressif32-only → excluded from native tests →
  ALL electrical/visual PROVISIONAL. **NEW note #54** (doc-consistency: (a) ch07 §5 + S1
  doc said hazard "also for NeverConnected" — corrected to breathe; (b) "minimum-on"
  promised by two comments, NOT implemented; (c) documented priority (low-battery above
  functional) vs code order (below) — moot w/ disjoint defaults; (d) `ILedStrip` named in
  CLAUDE.md/README/library.json but exists nowhere — the Rgb[30] array is the seam; plus
  observation: harvest tracker freezes during hazard → possible ≤400 ms phantom rain flash
  on recovery, contrast S2's unconditional `lastGear_`). **NEW question #55** (bench:
  rendered dim layers = 1–3/255 duty — disarmed halo {1,1,1}, tail {1,0,0}, breathe peak
  {1,3,3}, teal {0,9,7} — daylight visibility unknown). Suite coverage gaps logged (§8.2:
  low-battery pulse, breathe shape, left indicator, dim-vs-bright brake step). PROVISIONAL
  → S5: render cadence, millis() as nowMs, monitor→renderer→HAL plumbing, begin() at boot,
  static_assert site, GPIO4 injection, core-1 placement.
- **S5** → `code_explained/soundlight_fw/05_soundlight_main_integration.md`. Verification
  (2026-07-06): `pio test -e native` → **40/40 PASSED** + `pio run -e esp32dev -e
  esp32dev_sim` → **both SUCCESS** (espressif32 7.0.1 / core 2.0.17 pinned). Covered
  `Esp32I2sAudio.{hpp,cpp}` (legacy IDF 4.4 i2s; MASTER|TX, 16-bit, RIGHT_LEFT stereo-
  duplicated mono, 6×256-frame DMA ring ≈70 ms, tx_desc_auto_clear = underrun→silence,
  i2s_zero_dma_buffer = audio boot-blank, blocking write = backpressure clock; latency
  budget ≈100 ms worst-case INFERRED), `main.cpp` (2-atomic cross-core surface, relaxed
  suffices — no cross-variable invariant; 4 config static_asserts = the deferred sites
  from S1–S4; static-init order audit; volumeFor Off→0/Crank→70/Run→90..255 **closes
  #43**; audioTask dead-man >500 ms → setParams(0,…) — source-only, never test-executed;
  setup order Serial→Serial2(RX16,TX−1)→i2s.begin→strip.begin→xTaskCreatePinnedToCore
  ("audio", 4096 B, prio 5, core 0); loop = drain-every-pass → 50 Hz control tick
  (poll→update(state())→pack→heartbeat) → ~30 Hz lights (same state()+status();
  render→30×setPixel→show)), `SimLink2Feeder` (14 s script **matches SIMULATION.md's
  table**; 20 Hz emitter; 1 s true dropout; phase-by-pointer narration; steering triangle
  never negative → only one indicator side demoed, #56b), `test_integration` (2 tests
  assertion-by-assertion: composed Up→Running→loud (>12000 rpm, peak>3000) then
  Lost→Off→**exact-zero blocks** + hazard both phases probed at nowMs 0/250; 400-tick
  churn never hits −32768 rail — near-tautology noted honestly; its volumeFor constants
  differ from main's, #56a), `platformio.ini` (pin ~7.0.1 = the legacy-I2S insurance;
  test_build_src=no; lib_ignore ×2), `ci.yml` (**byte-identical to control's** — C10 §9
  transfers; #46 fully answered). #50 RESOLVED (LDF graph: no hal child). #51 confirmed
  final. Framework facts checked in installed source: loop()=loopTask prio 1 core 1;
  task WDT watches IDLE0 only. NEW #56 (doc-consistency ×5) + #57 (bench runtime facts).
  All PROVISIONAL-until-S5 notes in S1–S4 docs resolved via S5-resolution notes; ch07
  §§1/5/6/7, ch09 §2.4, ch11 §7 updated. **Soundlight explanation phase COMPLETE.**
- **G0+G1** → `code_explained/ground_station/01_shared_pure_core.md` (2026-07-09).
  G0: ground-station inventory re-verified file-by-file (drift = F2/F3/F4 + W1–W3 only;
  the 2026-07-03 table matched `b5ed803` exactly); plan Repo-3 section rewritten →
  batches **G1–G5b** (G5a = W2 telemetry-out bridge, G5b = W3 LOG-ONLY head-tracking +
  noControlPath guards; both gated on the deferred iPhone-bridge chapter decision, #58);
  `ci.yml` added to G4 (missed by the original inventory). G1: the six shared pure-core
  files + golden fixture + three suites explained (details in the Last-updated block
  above). Ran the three G1 suites → 32/32 PASSED; full suite 118/118. New #59; no
  corrections to ch08/ch09 needed (checked while reading).

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
| `lib/outputs/include/outputs/ServoOutput.hpp` + `src/ServoOutput.cpp` | C2 | reviewed | two-sided µs scale; A11 enforcement corrected (§1) |
| `lib/outputs/include/outputs/EscOutput.hpp` + `src/EscOutput.cpp` | C2 | reviewed | boot-arm hold (A5); IClock monotonic resolved via Esp32MillisClock |
| `lib/outputs/include/outputs/DrsOutput.hpp` + `src/DrsOutput.cpp` | C2 | reviewed | binary; closed-on-failsafe confirmed (C10) |
| `lib/outputs_hal_esp32/include/.../Esp32LedcPwm.hpp` + `src/Esp32LedcPwm.cpp` | C2 | reviewed | LEDC duty math re-derived; excluded from native tests |
| `test/mocks/MockPwmOutput.hpp` | C2 | reviewed | |
| `test/test_outputs/test_main.cpp` | C2 | reviewed | 10/10 re-run 2026-07-05 |
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
| `src/main.cpp` | C10 | explained | the conductor; no native test — source+build verified; NVS-gap finding (#49) |
| `src/SimCrsfFeeder.hpp` + `src/SimCrsfFeeder.cpp` | C10 | explained | 10-phase script matches SIMULATION.md (#48 answered) |
| `platformio.ini` | C10 | explained | 4 envs; native exclusion = test_build_src=no + lib_ignore |
| `.github/workflows/ci.yml` | C10 | explained | #46 answered (control half); tuning env not built by CI |
| `wokwi.toml` | — | explained | ch05 §9 (line-level: 6 lines, fully covered) |
| `diagram.json` | — | explained | ch05 §9 (part-by-part + netlist) |
| `docs/f1_hud.html` | — | summarize only | historical mockup; ch05 §10 |

## w17-soundlight-fw

| File | Batch | Status | Notes |
|---|---|---|---|
| `lib/config/include/config/PinMap.hpp` | S1 | explained | §2; RX16/TX17-reserved, I2S 26/25/22, LED 4; all non-strapping |
| `lib/config/library.json` | S1 | explained | §2; header-only shape, no deps |
| `lib/link2/include/link2/Link2Frame.hpp`, `Link2Codec.hpp` + `src/Link2Codec.cpp` | S1 | explained | §1/§3; **md5-identical to control** → referenced C8, not re-explained |
| `lib/link2/library.json` | S1 | explained | §1.4; md5-identical → carries a dangling `hal` dep (finding #50, benign) |
| `lib/link2monitor/include/.../Link2Monitor.hpp` + `src/Link2Monitor.cpp` | S1 | explained | §4/§5; the new module — staleness + per-field projection |
| `lib/link2monitor/library.json` | S1 | explained | §4; real `link2` dep (exercised) |
| `test/test_link2monitor/test_main.cpp` | S1 | explained | §7; 6/6 PASSED |
| `test/test_link2/test_main.cpp` | S1 | explained | §6; diff-checked = receiver-focused rewrite (5/5), golden bytes shared |
| `lib/enginesim/include/.../EngineSim.hpp` + `src/EngineSim.cpp` | S2 | explained | §1/§2; ignition FSM + asymmetric inertia; wheel rpm unused (#51) |
| `lib/enginesim/library.json` | S2 | explained | real `link2` dep |
| `test/test_enginesim/test_main.cpp` | S2 | explained | §3; 9/9 PASSED; coverage gaps in §5 |
| `lib/soundsynth/include/.../ISampleSource.hpp` | S3 | explained | §2; render seam (PCM fallback); alloc/lock-free contract |
| `lib/soundsynth/include/.../EngineSynth.hpp` + `src/EngineSynth.cpp` | S3 | explained | §3/§4; phase accumulators + sine table + partial stack + noise/whine/limiter; #43 answered; findings #52/#53 |
| `lib/soundsynth/library.json` | S3 | explained | §4.8; header-only shape, NO dependencies key (includes nothing outside itself) |
| `test/test_soundsynth/test_main.cpp` | S3 | explained | §5; 9/9 PASSED; test-strength caveats in §8.2 |
| `lib/lights/include/.../LightRenderer.hpp` + `src/LightRenderer.cpp` | S4 | explained | §2/§3; layered compositor; breathe≠hazard (#54a); harvest-derived rain light |
| `lib/lights/library.json` | S4 | explained | §3.10; real deps link2 + link2monitor (both exercised) |
| `lib/lights_hal_esp32/include/.../Esp32NeoPixelStrip.hpp` + `src/Esp32NeoPixelStrip.cpp` | S4 | explained | §4; Adafruit NeoPixel/RMT; boot-blank begin(); excluded from native (PROVISIONAL); ILedStrip doc-only (#54d) |
| `lib/lights_hal_esp32/library.json` | S4 | explained | §4.3; espressif32-only; Adafruit NeoPixel ^1.12.0 (only external LED dep) |
| `test/test_lights/test_main.cpp` | S4 | explained | §5; 9/9 PASSED; coverage gaps in §8.2 |
| `lib/audio_hal_esp32/include/.../Esp32I2sAudio.hpp` + `src/Esp32I2sAudio.cpp` | S5 | explained | §2/§3; legacy IDF i2s; DMA ring 6×256; zeroed at begin(); excluded from native (PROVISIONAL electrically) |
| `lib/audio_hal_esp32/library.json` | S5 | explained | §3.4; hardware-only shape; the 8th and last soundlight library.json |
| `src/main.cpp` | S5 | explained | §4; the conductor — closes #43 (volumeFor); dead-man source-only; no native test (test_build_src=no) |
| `src/SimLink2Feeder.hpp` + `src/SimLink2Feeder.cpp` | S5 | explained | §5; 14 s script matches SIMULATION.md (#48 analogue); L/R wording caveat (#56b) |
| `test/test_integration/test_main.cpp` | S5 | explained | §6; 2/2 PASSED; exact-zero silence + hazard probe; volumeFor drift (#56a) |
| `platformio.ini` | S5 | explained | §7; platform pin ~7.0.1 = legacy-I2S insurance; native exclusion = test_build_src=no + lib_ignore ×2 |
| `.github/workflows/ci.yml` | S5 | explained | §8; **byte-identical to control's** (#46 fully answered) |

## w17-ground-station

(Inventory re-verified 2026-07-09 against the tree at `dab3039`; line counts in the
plan's Repo-3 table.)

| File | Batch | Status | Notes |
|---|---|---|---|
| `shared/telemetry.js` | G1 | explained | §2; Telemetry typedef + TelemetrySource observer seam; armed/failsafe demo-only (R01) |
| `shared/feelConstants.js` | G1 | explained | §3; values match C6 ErsConfig; GEARS 4 = audit R05; drift guard partial (#59a) |
| `shared/crsf.js` | G1 | explained | §4; JS port of firmware decoder; KAT + golden CRC re-computed; RC-channels constant unused (#59b) |
| `shared/crsfAssembler.js` | G1 | explained | §5; compared with firmware CrsfFrameAssembler.cpp — same bounds/span/resync |
| `shared/crsfTelemetry.js` | G1 | explained | §6; frame→partial-Telemetry mapper; RSSI sign flip |
| `shared/linkState.mjs` | G1 | explained | §7; audit F2/R01 four-state model; inclusive ≥1 s edge; strict `=== 0` |
| `test/fixtures/crsf_golden.json` | G1 | explained | §8; audit F3/R07; values cross-checked vs firmware builder tests (read-only) |
| `test/crsf.test.js` | G1 | explained | §9.1; 13/13 PASSED |
| `test/crsfTelemetry.test.js` | G1 | explained | §9.2; 10/10 PASSED; golden end-to-end |
| `test/linkState.test.js` | G1 | explained | §9.3; 9/9 PASSED; imports replaySource helpers (G2 forward coupling) |
| `main/main.js` | G2 | not started | grew 106→159 (bridge/receiver wiring; forward refs to G5a/G5b) |
| `main/preload.cjs` | G2 | not started | grew 17→22 (`sendCommandMirror` one-way channel) |
| `main/mediamtx.js` | G2 | not started | |
| `main/CrsfSerialSource.js` | G2 | not started | |
| `shared/replaySource.js` | G2 | not started | now also exports `sampleTimeline`/`DEMO_TIMELINE` (used by G1's linkState tests) |
| `test/replay.test.js` | G2 | not started | 7 tests; carries the feel-constants drift guard (#59a) |
| `renderer/index.html` | G3 | not started | |
| `renderer/hud.css` | G3 | not started | 134→137 |
| `renderer/hud.js` | G3 | not started | 246→295 (F2 link states, F4 gear labels, command mirror); answers open question #47 |
| `renderer/whep.js` | G3 | not started | |
| `scripts/run.js` | G4 | not started | |
| `scripts/ensure-electron.js` | G4 | not started | |
| `scripts/fetch-mediamtx.js` | G4 | not started | |
| `package.json` | G4 | not started | |
| `electron-builder.yml` | G4 | not started | |
| `mediamtx/mediamtx.yml` | G4 | not started | |
| `.github/workflows/ci.yml` | G4 | not started | missed by the 2026-07-03 inventory; F2 added the Windows package-smoke job |
| `shared/telemetrySnapshot.js` | G5a | not started | W2; pure snapshot builder (contract: docs/windows_bridge_contract.md) |
| `main/IphoneTelemetryBridge.js` | G5a | not started | W2; send-only UDP 5601, off by default |
| `main/iphoneBridgeConfig.js` | G5a | not started | W2; pure env-config resolution |
| `test/telemetrySnapshot.test.js` | G5a | not started | 21 tests |
| `test/iphoneBridge.test.js` | G5a | not started | 18 tests |
| `shared/headTracking.js` | G5b | not started | W3; pure validator + diagnostics monitor — LOG-ONLY by safety boundary |
| `main/HeadTrackingReceiver.js` | G5b | not started | W3; UDP 5602 receive, LOG-ONLY dead end; real-device validation PENDING (#58) |
| `main/headTrackingConfig.js` | G5b | not started | W3; pure env-config resolution |
| `test/headTracking.test.js` | G5b | not started | 33 tests |
| `test/noControlPath.test.js` | G5b | not started | 7 tests; spans W2+W3 — the no-control-path structural guards |
| `package-lock.json` | — | skip | generated lockfile; concept noted in G4 |
| `mediamtx/mediamtx` (binary) | — | skip | fetched third-party binary |
| `README.md`, `CLAUDE.md`, `docs/*` | — | not in campaign | docs, covered by ch08 + (future) iPhone-bridge chapter; CLAUDE.md new 2026-07-09 |
