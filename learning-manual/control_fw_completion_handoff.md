# Control Firmware — Completion Handoff (2026-07-05)

The **w17-control-fw source-code explanation campaign is complete and reviewed** (batches
C1–C10). This note is the checkpoint before starting **S1** (soundlight) in a fresh
session. Authoritative status always lives in `source_code_progress.md`; this file is the
one-page summary + the exact read-list for S1.

## 1. Control firmware C1–C10 status

All ten batches **explained and `reviewed`** (verified against 147/147 native tests and
all three firmware builds — `esp32dev`, `esp32dev_sim`, `esp32dev_tuning` — SUCCESS on
2026-07-05).

| Batch | Doc | Status |
|---|---|---|
| C1 Foundations (pins/HAL/failsafe) | `code_explained/control_fw/01_foundations_pins_hal_failsafe.md` | reviewed |
| C2 Outputs (µs scaling, ESC hold, LEDC) | `…/02_outputs_commands_to_microseconds.md` | reviewed |
| C3 CRSF I (framing + channel decode) | `…/03_crsf_framing_and_channel_decoding.md` | reviewed |
| C4 CRSF II (receiver facade + builders) | `…/04_crsf_receiver_facade_and_frame_building.md` | reviewed |
| C5 Channels (mapping + ArmGate) | `…/05_channels_mapping_and_arm_gate.md` | reviewed |
| C6 Feel (gearbox + ERS) | `…/06_feel_gearbox_and_ers.md` | reviewed |
| C7 Telemetry sensors | `…/07_telemetry_sensors.md` | reviewed |
| C8 link2 outbound protocol | `…/08_link2_outbound_protocol.md` | reviewed |
| C9a Settings persistence | `…/09a_settings_persistence.md` (+ `09a_concept_teaching_notes.md`) | explained (unreviewed, structurally strongest) |
| C9b Console + tuning HAL | `…/09b_console_tuning_and_settings_store.md` (+ `09b_concept_teaching_notes.md`) | explained (unreviewed) |
| C10 main.cpp integration | `…/10_main_integration.md` (+ `10_concept_teaching_notes.md`) | explained (fresh) |

Overview chapters (Standard A) 00–11 audited and patched — see
`manual_standardization_audit.md`. Control-firmware manual is internally consistent.

## 2. C2 review status

**Reviewed 2026-07-05.** `pio test -e native -f test_outputs` re-run → **10/10 PASSED**.
All servo/ESC/LEDC arithmetic independently re-derived (no errors); all 10 test
descriptions verified. **One factual fix:** the doc claimed `main.cpp` `static_assert`s
the servo config — it does **not** (grep-confirmed: asserts cover channel-map / gearbox /
ers / battery / wheel / link2 / settings only). §1 corrected to the real A11 enforcement
(tuning-console per-`set` `valid()` + the tuning build's aggregate
`static_assert(settings::kDefaults.valid())`; the plain gift build trusts the compiled-in
default). Added a C10-resolution note (reference-member lifetimes, `begin()`/A5 wiring in
`setup()`, LEDC channels 0–4, DRS-closed-on-failsafe, and `Esp32MillisClock` resolving the
monotonic-clock assumption).

## 3. Remaining control-fw quality items

**None blocking.** Optional (low value, your call, deferred by default):
- Formal review passes for **C9a / C9b / C10** — C9a/C9b are structurally the strongest
  docs and were partially re-verified during C10; C10's natural review moment is the
  Wokwi first run (it will exercise C10's PROVISIONAL composition claims). Not urgent.
- **Do not** retrofit structured close-outs or concept-notes companions onto C1–C8 —
  length without new facts (would violate the no-bloat rule).

## 4. Deferred to hardware / Wokwi (not manual work)

Tracked in `open_questions.md`; the control firmware cannot close these from source alone:
- **#5** channel map vs the real transmitter (arm-switch polarity above all) — D8 Phase 4.
- **#26 / #27** RP1 "No Pulses" failsafe mode + LQ=0 burst characterization — the FSM's
  two-signal design assumes both.
- **#29** ESC arming timing + forward/brake (not forward/reverse) mode — load-bearing for
  the gearbox's brake passthrough; the "negative throttle = brake" claim rests on it.
- **#30** battery ADC eFuse calibration; **#31** Hall EMI at full throttle.
- **#34a** NVS persistence across power cycles + version-bump fallback; **#34b** UART0
  console on the bench.
- **#35–39** Wokwi platform facts (pin labels, 420 k loopback decode, pot preset, boot
  image, button bounce) — the sim first-run tests C10's whole composition.
- **#49** (new, from C10) the delivered gift build has **no NVS load path** — bench tuning
  persists in flash but is never read; runs compiled-in defaults. Owner decision on
  delivery (bake into defaults / ship tuning build / add a loader).

## 5. Deferred to soundlight / ground-station batches

- Chapter **07** re-audit + atomic-word bit layout (**#43**) → after **S2–S5**.
- Chapter **08** re-audit + HUD widget precedence (**#47**), `preload.cjs` details → after
  **G1–G4**.
- Chapter **09**: JS-decoder "third implementation" cross-links → **G1**; link2
  receiver-side notes → **S1**.
- Chapter **11** §7: soundlight `ci.yml` diff → **S5**.
- Soundlight-half of **#46** (ci.yml contents); **#48**-adjacent items already closed for
  control.

## 6. Recommended next batch: S1

**S1 — Input side: pins, link2 copy, monitor** (soundlight, `w17-soundlight-fw`).
Entry dependency **C8** is satisfied (link2 is explained + reviewed). Scope per
`source_code_explanation_plan.md` (repo 2, batch S1):

| File (w17-soundlight-fw) | Note |
|---|---|
| `lib/config/include/config/PinMap.hpp` | board #2's pins (link2 RX 16; I2S 26/25/22; LEDs 4) |
| `lib/link2/include/link2/Link2Frame.hpp` + `Link2Codec.{hpp,cpp}` | **diff-verify byte-for-byte against the control repo's copy, then reference C8** — do not re-explain. A non-empty diff is a finding → `open_questions.md`. |
| `lib/link2monitor/include/link2monitor/Link2Monitor.{hpp,cpp}` | staleness watchdog: NeverConnected/Up/Lost + per-field projection (ch07 §2) |
| `test/test_link2monitor/test_main.cpp` | the monitor's tests |
| `test/test_link2/test_main.cpp` | **diff-check vs control's** test file |

Key concept focus: C8 (the shared protocol, now from the *receiver* side); ch07 §2
(per-field staleness projection). Test command: `pio test -e native -f test_link2monitor`
(and `-f test_link2`), plus the full `pio test -e native` (expect **40** soundlight tests).

## 7. Exact files a fresh session should read before S1

**Recovery / state (always):**
1. `CLAUDE.md` (root) — the hard rules (read-only source; write only in `learning-manual/`).
2. `learning-manual/source_code_explanation_plan.md` — the campaign inventory + S1 scope.
3. `learning-manual/source_code_progress.md` — current status (C1–C10 done; S1 next).
4. `learning-manual/open_questions.md` — the open items (esp. #43, and the diff-verify rule).
5. `learning-manual/glossary.md` — existing terms (link2, staleness, dead-man, endianness…).
6. `learning-manual/control_fw_completion_handoff.md` — this file.

**Directly needed for S1 content:**
7. `learning-manual/code_explained/control_fw/08_link2_outbound_protocol.md` — the C8
   control-side explanation S1 references and diff-verifies against.
8. `learning-manual/07_soundlight_firmware_architecture.md` — the soundlight architectural
   pass (Link2Monitor, staleness table, the cross-core picture) — orientation for S1–S5.

**Source to read during S1 (read-only, `w17-soundlight-fw/`):** the five files in the §6
table, plus `w17-soundlight-fw/CLAUDE.md` for board #2's brief; and the control repo's
`lib/link2/*` for the byte-for-byte diff.

---

*Control firmware campaign complete (C1–C10, all reviewed). No source code was modified.
Next session: start S1. This handoff + `source_code_progress.md` are the entry points.*
