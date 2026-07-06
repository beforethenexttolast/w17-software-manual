# S3 — Recovery / Completion Status (2026-07-05)

A short bookkeeping note written after S3's main document was created but before final
confirmation (a session/request limit interrupted the batch during bookkeeping).
Authoritative content lives in `03_sound_synthesis.md`; per-file status lives in
`../../source_code_progress.md`. This file is the one-page recovery checkpoint.

## Status: S3 COMPLETE

The main batch document (`03_sound_synthesis.md`, **1,452 lines**) was verified complete —
every required section is present (fixed-string confirmed, 2026-07-05 recovery):

| Required section | Present? | Where |
|---|---|---|
| Exact scope/files table | ✅ | "Scope (files explained here)" |
| Prerequisites | ✅ | after the scope table |
| Where-this-fits explanation | ✅ | §0 (pipeline + the EngineState→word mapping table) |
| Digital-audio / math concepts primer | ✅ | §1 (sample rate, Nyquist, harmonics, clipping, determinism) |
| Line-by-line / small-block explanation | ✅ | §2 (ISampleSource), §3 (.hpp), §4 (.cpp), §5 (tests) |
| Fixed-point / phase-accumulator / waveform math | ✅ | §4.1 (sine table), §4.2 (phaseInc), §4.5, §4.7c |
| Amplitude scaling / clipping / saturation | ✅ | §3.4 (headroom), §4.7d/g/i |
| Mixing / multiple sound layers | ✅ | §4.7c–h (partials, noise, whine, volume, limiter) |
| idle/limiter/overrun/shift/crank behavior | ✅ | §3.3, §4.7e/f/h (crank acoustics noted §3.3) |
| How EngineSim outputs feed the synth | ✅ | §0 mapping table, §6 |
| Pure logic vs I2S/hardware boundary | ✅ | §0, §2 (alloc/lock-free), §8.3/§8.4 |
| All tests + every assertion explained | ✅ | §5.1–§5.9 |
| Test status | ✅ | "Test status: RUN AND PASSING (2026-07-05)" |
| VERIFIED / INFERRED / PROVISIONAL labels | ✅ | throughout (66 VERIFIED / 11 [I] / 8 PROVISIONAL) |
| What S3 proves | ✅ | §8.1 |
| What S3 does NOT prove | ✅ | §8.2 |
| What waits for S4/S5 | ✅ | §8.3 |
| What waits for real ESP32 / I2S / audio hardware | ✅ | §8.4 |
| Understanding questions | ✅ | §8.5 (10 questions) |
| Concepts for later teaching | ✅ | §8.6 |

No content was missing; **no patch to the S3 document was required** during recovery. Only
bookkeeping in the shared files remained (see below).

## Tests run and result

- `pio test -e native -f test_soundsynth` → **9/9 PASSED** (1.08 s):
  `test_config_valid_and_headroom`, `test_pitch_matches_firing_frequency`,
  `test_volume_scales_amplitude`, `test_zero_volume_is_silent`,
  `test_never_clips_at_max_settings`, `test_stereo_channels_identical`,
  `test_limiter_gates_some_samples_to_zero`, `test_deterministic_given_seed`,
  `test_packed_params_roundtrip`.
- **Verification harness** (session scratchpad only, compiled read-only against the real
  `EngineSynth.cpp`) measured what the tests don't pin: sine-table values + worst error
  (~19 counts at the wrap), smoother parking points (0→255 parks at **192**; 0→40 parks at
  **0**; 0→12000 parks at **11,937**), max-settings peak (**17,944** of 32,767), settled
  pitch (**994** crossings/s vs 1,000 nominal — matches the parked rpm), limiter zero-count
  (**11,040 / 22,050** ≈ 50.07 %).

Native tests + harness prove *logic on this Mac*, not audio on an ESP32.

## Files explained (all `w17-soundlight-fw/lib/soundsynth` + test)

- `include/soundsynth/ISampleSource.hpp` (24) — the render seam (PCM fallback), alloc-/lock-free.
- `include/soundsynth/EngineSynth.hpp` (118) — `packParams` word, `EngineSynthConfig`, class.
- `src/EngineSynth.cpp` (152) — sine table, `phaseIncForMilliHz`, `nextNoise`, `render()`.
- `library.json` (7) — header-only shape, **no dependencies key**.
- `test/test_soundsynth/test_main.cpp` (186) — 9 tests, assertion-by-assertion.

## Key results

- **Open question #43 ANSWERED (layout):** the cross-core `std::atomic<uint32_t>` =
  bits 0–15 engineRpm · 16–23 **volume** · 24 ersWhine · 25 limiter · 26 overrun ·
  27–31 reserved. Heartbeat is a *separate* atomic. Remaining for S5: that `main.cpp`
  actually packs it, and **where `volume` comes from** (no `volume` in `EngineState`).
- **Boundary finding:** the synth reads only (rpm, volume, 3 flags) — **not**
  `throttlePercent` or `Ignition`. So **silence-when-Off is NOT the synth's job**; it must
  arrive as `volume = 0` upstream (**PROVISIONAL until S5**). Note #51 confirmed in-context
  (soundsynth never touches a `VehicleState`).
- **S2 forward-promises resolved:** limiter buzz = 18 Hz / 50 %-duty gate; overrun crackle
  = 1-in-4 per-sample ×3 noise-amplitude lottery; ERS whine = 3× firing-freq sine, 23 ms ramp.

## New findings / open questions

- **#52 (NEW, doc-consistency):** repo `CLAUDE.md`/ch07 claim **"per-revolution amplitude
  modulation"** that **does not exist** in the code (idle life = S2's rpm wobble); the noise
  is **rpm-correlated, not "throttle-correlated"**; ch07 §6's packed-word list said
  rpm/throttle/flags → actually rpm/**volume**/flags. Minor stale code comments folded in
  (`phaseIncForMilliHz` optimization narration + 194.98 vs ≈194.78; SineTable comment).
  **Ch07 §4/§6 corrected in the manual;** repo files untouched (read-only).
- **#53 (NEW, for the owner):** the `>> 6` param smoother contradicts its own "~1/1024,
  ~23 ms" comment (it's 1/64 ≈ 2.9 ms) and its integer truncation **parks below target on
  upward approaches** — **volume 255 renders at 192 ≈ 75 %**; **volume targets 1–63 from
  silence stay exactly 0 (silent)**. Downward converges exactly (so `volume = 0` truly
  silences). Intended voicing or off-by-shift? Interacts with S5's volume mapping + bench (#32).
- **Headroom note (no action):** `valid()` excludes the overrun ×3 burst; with defaults the
  burst still fits (27,800 < 32,767) and the clamp is the universal backstop.
- **Test-strength honesty (§8.2):** never-clips test is a tautology (int16 can't be out of
  int16 range); volume test compares sound-vs-silence (quiet path is literally 0);
  limiter/packed-roundtrip tests prove existence, not cadence/per-bit correctness.

## Bookkeeping applied during recovery

- `source_code_progress.md` — header already updated (pre-limit); **S3 batch-log entry
  added**; all four S3 soundsynth rows → `explained` (incl. a new `library.json` row).
- `glossary.md` — added **Additive synthesis**, **Aliasing / Nyquist limit**, **Firing
  frequency**, **Headroom (audio)**, **Packed parameter word (cross-core)**, **Phase
  accumulator**, **Sample / sample rate**, **Saturation (hard clip)**, **Sine table /
  wavetable**, **Rev limiter (ignition cut)**, **ERS whine**, **xorshift32 (LFSR noise)**,
  **Zipper noise / parameter smoothing** (13 terms).
- `open_questions.md` — **#43 marked ANSWERED** (layout, with the S5 remainder); **added
  #52** (doc-consistency) and **#53** (owner: smoother truncation).
- `07_soundlight_firmware_architecture.md` — **§4 rewritten** (removed the non-existent
  per-rev AM; fixed rpm- vs throttle-correlated noise; added an S3-verified callout);
  **§6 corrected** (packed-word field list rpm/**volume**/flags; #43 layout; heartbeat is a
  separate atomic).

## Source repositories — clean / unchanged

- `w17-control-fw`, `w17-ground-station`, `w17-soundlight-fw`: **0 changed files** each
  (`git status --porcelain` empty; HEADs unchanged). No source code modified. The
  verification harness was compiled read-only from a copy in the session scratchpad, never
  written into any repo.

## Ready for?

- **S3 concept teaching notes:** RECOMMENDED before S4. S3 is the project's only ★★★★★
  batch and introduces the most new, reusable ideas (phase accumulators, fixed-point,
  additive synthesis, one-pole smoothers + their integer traps, real-time audio discipline).
  S1 and S2 each got a `NN_concept_teaching_notes.md` companion; parity + the difficulty
  argue for an S3 one. Optional (deferred by default per the no-bloat rule) — write on request.
- **S4 (`lib/lights` + `lib/lights_hal_esp32`):** unblocked. S4 reads `VehicleState`
  directly (not `EngineState` or audio), so it does not depend on S3's internals. **Not
  started** — awaiting approval.

*Recovery complete. No source code modified. Stop after S3.*
