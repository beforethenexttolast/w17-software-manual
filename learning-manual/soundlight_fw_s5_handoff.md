# Soundlight firmware — S5 handoff (2026-07-05)

A single-page checkpoint for starting **S5** (the final soundlight batch) in a fresh
session. S1–S4 are complete; this file collects their status, the findings S5 must carry
forward, every PROVISIONAL claim S5 is expected to close, the open questions in scope, the
exact files to read first, and the recommended model/effort. Authoritative per-batch detail
lives in `code_explained/soundlight_fw/0N_*.md`; campaign status in `source_code_progress.md`.

**S5 is the batch that closes the `w17-soundlight-fw` explanation phase** — the audio HAL,
the dual-core `main.cpp` that wires every prior module together, the sim feeder, the
end-to-end integration test, and the build configs.

---

## Batch status (S1–S4 all COMPLETE, all `explained`)

| Batch | Module(s) | Doc | Tests | Status |
|---|---|---|---|---|
| **S1** | `link2` (copy) + `link2monitor` | `01_link2_receiver_and_protocol_compatibility.md` (+ `01_concept_teaching_notes.md`, `01_recovery_status.md`) | `pio test -e native -f test_link2 -f test_link2monitor` → **11/11**; full suite **40/40** | explained |
| **S2** | `enginesim` | `02_engine_simulation.md` (+ `02_concept_teaching_notes.md`) | `pio test -e native -f test_enginesim` → **9/9** | explained |
| **S3** | `soundsynth` (`ISampleSource` + `EngineSynth`) | `03_sound_synthesis.md` (+ `03_concept_teaching_notes.md`, `03_recovery_status.md`) | `pio test -e native -f test_soundsynth` → **9/9** (+ scratchpad math harness) | explained |
| **S4** | `lights` + `lights_hal_esp32` | `04_lights_and_light_hal.md` | `pio test -e native -f test_lights` → **9/9** (+ independent gamma/current recompute) | explained |

- **All C1–C10 (control firmware) remain `reviewed`.** The full control campaign is done.
- **S1–S4 are `explained`, not `reviewed`** — no review pass has been run on the soundlight
  batches yet (parity with how the C-batches got a second pass). Optional; not a blocker for S5.
- **Full soundlight native suite = 40/40** across six suites: `test_link2`, `test_link2monitor`,
  `test_enginesim`, `test_soundsynth`, `test_lights`, `test_integration`. Note `test_integration`
  passes today but is **explained in S5** (it's the frames→audio end-to-end proof).

### One-line recap of each batch
- **S1** — receiver side of link2: `lib/link2` diff-verified **md5-identical** to control (only
  `Link2Sender` absent); `Link2Monitor` = staleness watchdog + three-state `LinkStatus`
  (NeverConnected/Up/Lost) + per-field effective-state projection (inclusive ≥500 ms edge).
  Resolved C8's cross-repo PROVISIONAL → VERIFIED. Note #50 (dangling `hal` dep in copied
  `library.json`).
- **S2** — `EngineSim`: armed-driven ignition FSM (Off/Cranking/Running), throttle→rpm map
  (3500–15000, wheel rpm **unused** = #51), asymmetric inertia, wobble/blips/limiter/overrun
  flags. Feeds `EngineState` → the synth.
- **S3** — `EngineSynth` DSP: phase accumulators → 256-entry ±256 sine table, 6-partial additive
  stack at firing freq (5·rpm/60), rpm-scaled xorshift32 noise + overrun bursts, 3×-pitch ERS
  whine, 18 Hz limiter gate, headroom budget, saturating clamp, mono→stereo. **#43 answered**
  (packed-word layout). Findings #52 (doc-lag) + #53 (smoother parking: full volume ≈75%).
- **S4** — `LightRenderer` + `Esp32NeoPixelStrip`: layered compositor (breathe / normal /
  hazard), gamma+cap, power budget. Findings #54 + #55 (below).

---

## Key findings from S4 (carry into S5)

- **#54a — `NeverConnected` renders a calm teal "breathe," NOT the amber hazard.** The
  three-state `LinkStatus` is rendered three ways (breathe / normal / hazard). Ch07 §5 and the
  S1 doc had wrongly said "amber for both" — **both corrected**. (This was the manual's pre-code
  inference; the repo docs never made the error.)
- **#54b — indicator "minimum-on" is comment-ware** (only hysteresis 40/20 is implemented).
- **#54c — documented compositor priority ≠ code order** (low-battery documented above the
  functional layer, painted below it) — moot with the default disjoint segments.
- **#54d — `ILedStrip` exists only in repo docs** (CLAUDE.md / README / `lights_hal_esp32`
  library.json) — no such interface in any header. The renderer's pure `Rgb[30]` output array is
  the seam; none is needed. **S5 relevance:** don't expect a strip interface when reading how
  `main.cpp` wires the renderer to the HAL.
- **#54 observation — phantom rain flash on failsafe recovery:** the harvest tracker freezes
  during hazard/breathe early-returns, so ERS rising during an outage can fire a ≤400 ms rain
  flash at recovery (cosmetic; contrast S2's unconditional `lastGear_`).
- **#55 (bench) — dim layers render very dim:** after 43% cap + gamma-2.2, disarmed halo {1,1,1},
  tail {1,0,0}, breathe peak {1,3,3}, teal {0,9,7} (1–3/255 duty). Daylight visibility unknown;
  power budget ~5× conservative post-gamma (safe direction).
- **No DRS light and no ERS-deploy light exist.** The lights read **exactly 7** `VehicleState`
  fields (failsafe, armed, lowBattery, braking, driveMode, ersPercent, steeringPercent). **NOT
  read:** throttlePercent, reverse, **drsOpen**, **ersDeploying**, gear, rpm, batteryMv. Deploy is
  the *synth's* whine (S3); harvest is the *light*.
- **Harvest is derived locally** (no harvest flag on the wire): `ersPercent` strictly rising while
  `driveMode == 2`, seeded on the first frame, remembered 400 ms per rise. Deploying makes the
  percent fall → never triggers.
- **Zero EngineSim/EngineSynth coupling in the lights.** `LightRenderer` includes only `link2` +
  `link2monitor`; sound and light are parallel consumers of the effective `VehicleState`, not a
  chain. **S5 relevance:** `main.cpp` should feed the *same* effective state to both the
  sim→synth path and the light renderer — confirm it does.

---

## PROVISIONAL items S5 is expected to resolve

These accumulated across S1–S4 and are all `main.cpp` / audio-HAL / build wiring — exactly S5's
scope:

**Cross-core + audio hand-off (the big ones):**
- The **real `std::atomic<uint32_t>` param word** — that `main.cpp` on core 1 stores
  `packParams(...)` and the audio task on core 0 reads it via `applyPackedParams` (S3 §3.2).
- **Where `volume` comes from** — there is no `volume` in `EngineState`; S5 must derive it, and
  **map `Ignition::Off` → `volume = 0`** (S3 §concept 17: rpm 0 alone does NOT silence — frozen
  phases output DC; only volume 0 truly silences). This is the load-bearing silence path.
- The **heartbeat atomic + dead-man** (~500 ms without a param refresh ⇒ audio task ramps volume
  to 0). Repo CLAUDE.md mandates it; it lives in the audio task, not in `EngineSynth` (S3 §20).
- **Task pinning** — audio task on core 0, control loop on core 1 (the cross-core rule); which
  core runs the lights (S4 says core-1-only — confirm).
- I2S **buffer size / cadence** vs the ~11.6 ms deadline (256 frames?), and `Esp32I2sAudio`
  delivery (stereo-duplicated mono).

**Wiring cadences + seams:**
- The control-loop cadence: UART drain → `Link2Monitor::feedByte`/`poll` with `millis()` as
  `nowMs` → `EngineSim::update` → pack params; and the light render cadence (50 Hz tick?).
- `millis()` as the `nowMs` seam for both the monitor (S1) and the light renderer (S4).
- **Config `static_assert(...valid())` sites** for `EngineSimConfig`, `EngineSynthConfig`,
  `LightConfig`, `Link2MonitorConfig` — all deferred to the definition site in `main.cpp`.
- **Pin injection:** UART RX GPIO16, I2S BCLK26/LRC25/DIN22, LED data GPIO4 — passed from
  `PinMap.hpp` into the HAL constructors (S1 §2, S4 §4.1).
- **HAL boot order:** `Esp32NeoPixelStrip::begin()` (boot-blank) and the I2S init early in
  `setup()` (S4 §4.2).

**Build/CI:**
- Soundlight `platformio.ini` (native-exclusion mechanism; the `esp32dev` / `esp32dev_sim` envs).
- Soundlight `.github/workflows/ci.yml` (diff vs control's — closes #46's soundlight half).
- The `esp32dev` build actually resolving/ignoring the dangling `hal` dep (#50).

---

## Open questions relevant to S5

- **#43 (packed word) — layout ANSWERED (S3); remaining half is S5:** confirm `main.cpp` packs
  the atomic with `packParams` each tick and **where `volume` is derived** (from `ignition`?).
- **#50 (dangling `hal` dep in copied `link2/library.json`)** — benign for native (40/40);
  **PROVISIONAL for `esp32dev`/`esp32dev_sim` builds until S5** proves LDF doesn't choke.
- **#54 (lights doc-lag, all four items + the recovery-phantom observation)** — no code action;
  S5 just shouldn't expect an `ILedStrip` when reading the wiring, and should note whether
  `main.cpp` feeds the light renderer the effective state on the same cadence.
- **#55 (dim-layer visibility)** — bench; S5 doesn't resolve it but may surface the render→HAL
  brightness path.
- **#52 / #53 (S3 synth doc-lag + smoother parking)** — #53's practical impact depends on **what
  volume values `main.cpp` sends** (if only 0 and 255, the quirk reduces to "full = 75%"); S5's
  volume-derivation code is where that gets pinned. #52 is pure doc-lag, no S5 action.
- **#51 (`VehicleState.rpm` wheel rpm unconsumed)** — S5 should confirm nothing in `main.cpp`
  revives it.
- **New audio/HAL/main questions S5 will likely raise (anticipated, not yet filed):** the exact
  I2S driver (legacy IDF i2s per CLAUDE.md — API/version pinning), sample-buffer sizing and
  whether `render()`'s per-sample cost fits the real-time budget on a 240 MHz core, the dead-man
  timing constant, FreeRTOS task priorities/stack sizes, and whether `SimLink2Feeder`'s scripted
  drive matches `docs/SIMULATION.md`'s phase table (the soundlight analogue of C10's #48 check).
- **Bench (#32)** — whether the synth *sounds* like an engine on the MAX98357A + 3 W speaker; the
  PCM-fallback decision the `ISampleSource` seam exists for. Not S5-resolvable.

---

## Exact files a fresh S5 session should read first

**S5 source scope (`w17-soundlight-fw/`, line counts verified 2026-07-05):**

| File | Lines | What it is |
|---|---|---|
| `lib/audio_hal_esp32/include/audio_hal_esp32/Esp32I2sAudio.hpp` | 32 | the I2S audio HAL — interface |
| `lib/audio_hal_esp32/src/Esp32I2sAudio.cpp` | 50 | …implementation (legacy IDF i2s, stereo-duplicated mono) |
| `lib/audio_hal_esp32/library.json` | 7 | the last soundlight `library.json` (8th) |
| `src/main.cpp` | 142 | the dual-core conductor — wires every module |
| `src/SimLink2Feeder.hpp` | 24 | bench-demo frame feeder — interface |
| `src/SimLink2Feeder.cpp` | 106 | …implementation (scripted 14 s drive) |
| `test/test_integration/test_main.cpp` | 158 | the frames→audio end-to-end test |
| `platformio.ini` | 45 | envs + native-exclusion mechanism |
| `.github/workflows/ci.yml` | 36 | CI (diff vs control's) |

Total ≈ **600 lines** — a normal batch, but rated ★★★★ (dual-core + FreeRTOS + I2S). May split
into two sittings if the atomic/dead-man/task-pinning analysis runs long.

**Manual context to re-read first (in this order):**
1. `code_explained/soundlight_fw/03_sound_synthesis.md` §0, §3.2, and §concept-17/§20 — the
   packed word, the volume-derivation gap, the dead-man's home. **This is the most important
   context for S5.**
2. `code_explained/soundlight_fw/01_link2_receiver_and_protocol_compatibility.md` §4–§5 — the
   monitor's `feedByte`/`poll`/`state()` seam that `main.cpp` drives.
3. `code_explained/soundlight_fw/04_lights_and_light_hal.md` §0 and §4 — the light render→HAL
   path and the `begin()` boot-blank.
4. `07_soundlight_firmware_architecture.md` §1 (pipeline) and §6 (dual-core design, the atomic
   word, the dead-man) — the architecture claims S5 finally verifies in code.
5. `source_code_explanation_plan.md` (S5 row) and `source_code_progress.md` (top + soundlight
   table) — the plan and current status.
6. `open_questions.md` — #43, #50, #51, #52, #53, #54, #55, #32, #46.

**Reference (control-repo analogue, for the composition pattern):**
`code_explained/control_fw/10_main_integration.md` — C10 is the control board's `main.cpp`
walkthrough; S5 is the same *kind* of batch (the conductor), so its structure is a good template
(static-init + static_asserts, `setup()` boot order, the tick cadences, the sim-feeder-vs-SIMULATION
check, the platformio/ci pass).

**First action in the S5 session:** run `pio test -e native` (expect 40/40, incl.
`test_integration`) to confirm the baseline, then read the audio HAL + `main.cpp`.

---

## Recommended model / effort for S5

- **Model: Opus 4.8** (or the strongest available). S5 is the hardest *conceptual* soundlight
  batch — it's where FreeRTOS dual-core reasoning, the `std::atomic` memory-ordering argument, the
  dead-man timing, and I2S DMA all land, plus it must correctly close ~a dozen PROVISIONALs
  without overstating (the native suite can't prove any of the concurrency/hardware behavior). The
  fable-class model handled S4 well, but S5's cross-core correctness reasoning wants the stronger
  model.
- **Effort: high**, and **budget a full session** (the plan flags S5 ★★★★ and "may spill into two
  sittings"). Do not rush the atomic/dead-man/task-pinning analysis.
- **Same discipline as S1–S4:** read-only on `w17-*`; write only in `learning-manual/`; run
  `test_integration` and report honestly what native tests do vs don't prove (all
  concurrency/timing/I2S/speaker behavior is PROVISIONAL/bench); separate VERIFIED / INFERRED /
  PROVISIONAL; update `source_code_progress.md`, `glossary.md`, `open_questions.md`, and
  `07_*` if S5 resolves notes. Consider writing `04_recovery_status.md`-style notes only if
  interrupted. An **S5 concept-teaching-notes** companion is recommended after the batch doc
  (parity with S1–S3; S5 introduces cores/atomics/RTOS/I2S) — optional, on request.

---

## Source repositories — clean / unchanged (confirmed 2026-07-05)

- `w17-control-fw` — 0 changed files (HEAD `8404117`)
- `w17-ground-station` — 0 changed files (HEAD `b5ed803`)
- `w17-soundlight-fw` — 0 changed files (HEAD `db6fe92`)

No source code modified in any batch. All S1–S4 output lives in `learning-manual/`.

*Handoff complete. Stop here — do not start S5. Awaiting a fresh session.*
