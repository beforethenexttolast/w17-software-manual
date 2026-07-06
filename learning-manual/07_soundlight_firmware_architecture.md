# 07 — Sound + Light Firmware Architecture (`w17-soundlight-fw`)

Board #2 turns board #1's 14-byte status frames into a living V10 soundtrack and F1
light show — and protects itself when those frames stop coming. It commands nothing;
it can only *perform*.

## 1. The pipeline

```mermaid
flowchart LR
  subgraph CORE1["CPU core 1 — control loop (src/main.cpp loop())"]
    RX["UART bytes<br/>GPIO16, 115200"]
    MON["Link2Monitor<br/>assembler + 500ms staleness<br/>→ EFFECTIVE VehicleState"]
    SIM["EngineSim<br/>virtual engine:<br/>rpm, ignition, limiter, overrun"]
    LGT["LightRenderer<br/>compositor → 30 RGB pixels"]
    PACK["pack synth params into ONE<br/>std::atomic&lt;uint32_t&gt; + heartbeat"]
  end
  subgraph CORE0["CPU core 0 — audioTask()"]
    UNPACK["unpack params<br/>(dead-man: stale 500ms → mute)"]
    SYN["EngineSynth<br/>wavetable DSP @ 22050 Hz"]
    I2S["Esp32I2sAudio → MAX98357A → speaker"]
  end
  RX --> MON --> SIM --> PACK
  MON --> LGT --> NEO["Esp32NeoPixelStrip<br/>WS2812 GPIO4"]
  PACK -.->|atomic word| UNPACK --> SYN --> I2S
```

**[C]** Structure per `w17-soundlight-fw/CLAUDE.md` (module map + cross-core rule),
`README.md`, and `src/main.cpp` (includes, `audioTask`, atomics — verified by skim).

> **[C] S5 verified this pipeline line-by-line in `src/main.cpp`**
> (`soundlight_fw/05_soundlight_main_integration.md`; 40/40 native + both firmware builds
> SUCCESS): the control loop runs at **50 Hz** (UART drained every pass, not just on
> ticks), the lights at **~30 Hz** (33 ms — this diagram's "core 1" grouping is right,
> but note the two cadences are independent tick guards), and the audio task re-reads the
> packed word before every 256-frame (~11.6 ms) block. Both `EngineSim` and
> `LightRenderer` receive the **same** `monitor.state()`. One correction of emphasis: the
> diagram's PACK step derives `volume` via `volumeFor()` (Off→0, Cranking→70,
> Running→90..255) — see §6. `main.cpp` itself is excluded from native tests
> (`test_build_src = no`), so composition claims are source+build-verified; the module
> chain is additionally exercised natively by `test_integration` (frames → Lost →
> exact-zero audio + hazard).

## 2. `Link2Monitor` — trust, but with an expiry date

The protocol is one-way: if the wire is cut, board #2 would otherwise keep performing
the last state forever. So the monitor wraps the frame assembler and answers two
questions every tick: *what did board #1 last say?* and *is that still believable?*

- **`LinkStatus`**: `NeverConnected` (nothing valid ever arrived — e.g. board #1 still
  booting) / `Up` / `Lost` (was up; silent ≥ 500 ms). The lights want this distinction
  as a first-class signal. **[C]** `lib/link2monitor/Link2Monitor.hpp`.
- **Per-field staleness projection** — the design decision worth studying. When the link
  is not `Up`, `state()` returns a *projected* state, not the last frame verbatim:

| Field class | On staleness | Reasoning [C, header comment] |
|---|---|---|
| Commands (throttle, steering, braking, drsOpen, armed, ersDeploying) | zeroed / cleared, `failsafe` forced **true** | a stale command must not drive anything |
| Motion telemetry (rpm) | zeroed | stale motion would keep sound/lights "moving" |
| Qualified judgments (lowBattery) and slow facts (batteryMv, gear, ersPercent, driveMode) | hold last value | board #1 already qualified them; blanking would flicker the display |

> **[C] S1 verified this table in code** (`soundlight_fw/01_link2_receiver_and_protocol_compatibility.md`
> §5, §7): `Link2Monitor::recompute` applies exactly this projection on `Lost`, pinned
> field-by-field by `test_per_field_staleness_projection` (6/6 tests pass). The window edge is
> inclusive (`elapsed >= 500 ms`), only CRC-valid frames refresh it, and `NeverConnected` never
> ages into `Lost`. The three-state `LinkStatus` and the `nowMs`-as-parameter clock seam are
> confirmed there too. (Full ch07 re-audit + the cross-core atomic-word bit layout, open q #43,
> still await S2–S5.)

## 3. `EngineSim` — the imaginary engine

The car has a quiet brushless motor; the *drama* is synthesized. `EngineSim` maintains a
believable engine state from the effective `VehicleState`, **[C]** all constants from
`lib/enginesim/EngineSim.hpp`:

- **Ignition state machine:** `Off` (disarmed → silence) → `Cranking` (armed edge → 600 ms
  starter whir at 1800 rpm) → `Running`. Failsafe (effective `armed == false`) drops back
  to `Off` — so link loss *sounds like* the engine dying, which is exactly the right
  user feedback.
- **RPM with asymmetric inertia:** engine rpm chases a target derived from throttle
  between idle 3500 and redline 15,000 rpm, closing the gap faster on rev-up (~0.5 s
  idle→max) than rev-down (~1.2 s) — engines spin up harder than they brake.
- **Character details:** idle wobble (±120 rpm triangle so idle isn't sterile),
  gear-shift blips (rpm dips 1400 on upshift / blips up on downshift for 130 ms),
  rev limiter detection (within 250 rpm of redline at full throttle → the F1 "buzz"
  flag), and an overrun-crackle window (900 ms of pop-and-bang eligibility after a fast
  lift from high rpm).

Note the scale trick: **wheel** rpm from the car maxes ~5000, but *engine* rpm is
simulated 3500–15,000 — the range was chosen so the fundamental frequency lands where a
tiny speaker can actually reproduce it. **[C]** soundlight `CLAUDE.md` (soundsynth
bullet).

> **[C] S2 verified this section in code**
> (`soundlight_fw/02_engine_simulation.md`, 9/9 tests pass): every constant above is
> exact (idle 3,500 / redline 15,000 / crank 600 ms @ 1,800 / wobble ±120 / blips
> 1,400 × 130 ms / limiter 250-band / overrun 900 ms), and the "~0.5 s / ~1.2 s"
> inertia figures check out against the 6 ‰/3 ‰ rates. Two refinements: engine rpm is
> derived from **commanded throttle only** — the received wheel rpm is not read by
> EngineSim (or, per grep, by anything else on this board yet; open q **#51**); and on
> any return of `armed` (including failsafe recovery) the FSM **replays the full
> cranking sequence** — the engine audibly restarts.

## 4. `EngineSynth` — the DSP (concepts only here)

`EngineSynth` renders audio samples: a stack of harmonic partials at the engine's
*firing frequency* (5 firings per revolution ⇒ V10 flavor), **rpm-scaled** noise from a
**seeded LFSR** (xorshift32 — deterministic pseudo-random, same seed = same "random"
noise, so tests can assert exact output; louder bursts during the overrun window give the
crackle), a pitch-tracking ERS whine layer gated by `ersDeploying`, a rev-limiter
ignition-cut gate, and per-sample parameter smoothing so values glide instead of clicking.
All integer math (float only in the one-time sine-table build). Behind `ISampleSource`, so
a future PCM sample player could replace synthesis without touching anything above.
**[C]** `CLAUDE.md` module map + `lib/soundsynth/` headers.

> **[C] S3 verified this section in code**
> (`soundlight_fw/03_sound_synthesis.md`, 9/9 tests pass + a harness compiled against the
> real source): the DSP is 32-bit **phase accumulators** feeding a **256-entry ±256 sine
> table**, a **6-partial additive stack** at 5·rpm/60 Hz, rpm-scaled xorshift32 noise with
> 1-in-4 **×3 overrun bursts**, a **3× firing-frequency** ERS whine ramped over ~23 ms, a
> master volume, and an **18 Hz 50 %-duty limiter gate**, all clamped and duplicated to
> stereo. **Two corrections to the description above** (open q **#52**): there is **no
> per-revolution amplitude modulation** in the code — the idle's life comes from S2's rpm
> wobble, not an AM envelope; and the noise is **rpm-correlated, not throttle-correlated**
> (throttle is not even a synth input). The synth reads only `engineRpm`, a `volume` byte,
> and the `ersWhine`/`limiter`/`overrun` flags — **not** `throttlePercent` or the ignition
> state, so silence-when-Off must arrive as `volume = 0` from `main.cpp` (**PROVISIONAL
> until S5**). Also found: the parameter smoother truncates so full volume renders at ~75 %
> and sub-64 volumes stay silent (open q **#53**).

## 5. `LightRenderer` — the compositor

A layered compositor: (effective state, LinkStatus, nowMs) → 30 RGB values — pure logic,
stateful only for indicator hysteresis and harvest edge detection, **[C]** soundlight
`CLAUDE.md` + `README.md` + (S4) the source:

1. base: halo (teal armed / dim white disarmed) + always-on dim red tail,
2. brake bar (from the pre-filtered `braking` flag — hysteresis lives on board #1),
3. turn indicators (steering-threshold latch with 40/20 hysteresis + self-cancel,
   blinking ~1.5 Hz),
4. F1 **rain light** — flashes while ERS is *harvesting* (the real F1 2026-era cue;
   derived locally from `ersPercent` rising in ERS mode — the frame has no harvest flag),
5. low-battery pulse (slow red triangle on the halo),
6. **failsafe hazard: all-amber 2 Hz blink overriding everything** — for a frame-reported
   failsafe *or* a `Lost` link; **`NeverConnected` instead shows a calm teal "waiting
   breathe"** (a 2 s triangle on the halo) so power-on doesn't cry wolf — the three-state
   `LinkStatus` is rendered three ways,
then a gamma lookup (perceptual brightness correction) and a brightness cap whose power
budget is enforced in the config's `valid()` (~43% — keeps worst-case all-amber inside
the UBEC's current headroom).

> **[C] S4 verified this section in code**
> (`soundlight_fw/04_lights_and_light_hal.md`, 9/9 tests pass + independent recomputation
> of the gamma/current figures): segments brake 0–5 / rain 6–7 / halo 8–21 / indicators
> 22–25 + 26–29; budget (2·20·cap)/255 per LED × 30 ≤ 900 mA (default 510 ✓). **One
> correction to this chapter's earlier text** (open q **#54**): the hazard is **not**
> "also shown for NeverConnected" — never-connected gets the calm breathe, pinned by
> `test_never_connected_is_calm_not_hazard`. Also found: the comments' indicator
> "minimum-on" is not implemented (hysteresis only); `ILedStrip` exists only in the repo
> docs (the renderer's `Rgb[30]` array is the seam); the lights read exactly seven
> `VehicleState` fields — **no DRS or ERS-deploy light exists** (deploy is the synth's
> whine; harvest is the light), and nothing audio-side is read. Post-cap-post-gamma the
> dim layers render at 1–3/255 duty — daylight visibility is a bench question (**#55**).

> **[C] S5 added the wiring** (`05_soundlight_main_integration.md` §4.10): `loop()`
> renders the lights at **~30 Hz** (33 ms tick, not the control loop's 50 Hz), passing
> `monitor.state()`, `monitor.status()`, and `millis()`; the 30 pixels are copied into
> the Adafruit buffer one `setPixel` at a time and latched with one `show()` (~0.9 ms).
> `strip.begin()` (the boot-blank) runs early in `setup()`. Frame rate and blink timing
> stay independent because every animation is free-running off `nowMs`.

## 6. The dual-core design — why and how

Audio is unforgiving: 22,050 samples/second, every ~11 ms buffer must be ready or the
speaker pops. LED writes and frame parsing have their own timing quirks. The solution:
**core 0 does nothing but audio; core 1 does everything else.**

The entire shared surface between the cores (the "cross-core rule," **[C]** soundlight
`CLAUDE.md`, verbatim rule):

- one packed `std::atomic<uint32_t>` — the synth parameters bit-packed into 32 bits,
  written by core 1, read by core 0. **[C] S3 confirmed the exact layout** (open q **#43**
  answered, `EngineSynth.hpp:12–27`): **bits 0–15 = engineRpm**, **bits 16–23 = volume**,
  **bit 24 = ersWhine**, **bit 25 = limiterActive**, **bit 26 = overrunActive**, bits 27–31
  reserved. (Note: the second field is **volume**, not throttle as an earlier draft of this
  section said — see #52.);
- one heartbeat atomic (separate from the param word — the dead-man's "refreshed recently"
  signal, not squeezed into the reserved bits).

Nothing else crosses. Synth phase state lives only in the audio task; `VehicleState`,
`EngineSim`, lights live only on core 1. Why one atomic word instead of a struct: a
32-bit atomic is indivisible on this hardware — the audio task can never observe
half-updated parameters (no locks needed, and locks are dangerous next to real-time
audio anyway).

**The dead-man switch:** if the heartbeat shows core 1 hasn't refreshed params for
~500 ms (a wedged control loop), the audio task ramps volume to zero — "a wedged control
loop must not leave the engine screaming." **[C]** `CLAUDE.md`. Count the failsafe
layers protecting the speaker alone: link staleness (monitor) → ignition Off on disarm
(enginesim) → cross-core dead-man (audio task).

> **[C] S5 verified this whole section in `src/main.cpp`**
> (`05_soundlight_main_integration.md` §4.2, §4.6, §4.7, §4.11): the shared surface is
> **exactly** the two atomics (`gSynthParams`, `gControlHeartbeatMs`), audited
> object-by-object — the discipline holds. The control tick stores the packed word then
> the heartbeat, both `memory_order_relaxed` (sufficient: no invariant spans the two
> words; the 500 ms tolerance dwarfs any reordering window). The dead-man is exact
> **500 ms** (`kAudioDeadmanMs`, strict `>`), and "ramps to 0" is implemented as *forced
> silent params* (`setParams(0, 0, false, false, false)`) + the synth's per-sample
> smoother (τ ≈ 2.9 ms, downward-exact) — the ramp is the smoother. **The missing piece
> this chapter couldn't state before: `volume`.** `EngineState`'s `ignition` and
> `throttlePercent` never cross the cores raw — `volumeFor()` folds them into the volume
> byte: **Off → 0** (this is how link-loss/disarm silence actually reaches the synth,
> since rpm 0 alone does not silence it), **Cranking → 70**, **Running → 90 +
> throttle·165/100**. The audio task: pinned core 0, priority 5, 4096-byte stack,
> self-paced by the blocking `i2s.write` into a ~70 ms DMA ring; `loop()` runs on core 1
> per the framework (`CONFIG_ARDUINO_RUNNING_CORE=1`). **Honest scope:** `main.cpp` has
> no native test, so the dead-man branch has *never executed anywhere* — a priority
> bench check (open q **#57**); the atomics/task claims are source+build-verified.

## 7. Build variants + the bench demo

| Env | Purpose |
|---|---|
| `esp32dev` | real firmware (waits for board #1's frames) |
| `esp32dev_sim` | `-DW17_SIM_LINK2_FEEDER`: `SimLink2Feeder` scripts a 14 s drive — idle → revs/gears → ERS deploy → brake+harvest (rain light) → cornering (indicators) → **1 s dropout → local failsafe demo** → recovery. **[C]** `docs/SIMULATION.md` |
| `native` | 40 unit tests, incl. a full frames→audio integration test |

Its `docs/SIMULATION.md` also carries the board's bench checklist (I2S sanity on the
pinned driver version, MAX98357A straps, WS2812 fixes, "does the synth actually read as
engine on the real speaker," LED power budget).

> **[C] S5 verified the sim feeder against that table**
> (`05_soundlight_main_integration.md` §5): the 14 s script's phases and timings match
> SIMULATION.md exactly (the soundlight analogue of C10's #48 check), the dropout is a
> true 1 s emission gap through the real assembler+monitor path, and the demo loops
> seamlessly (armed across the wrap — no re-crank per lap). One wording caveat (open q
> **#56b**): the CORNERING steering triangle never goes negative, so only one indicator
> side is actually demonstrated despite "indicators sweep L/R." Also confirmed: `ci.yml`
> is **byte-identical** to the control repo's (#46 closed), and the copied link2
> `library.json`'s dangling `hal` dep is inert in all environments (#50 closed).

## Confirmed vs inferred

**Confirmed [C]:** module responsibilities, all numeric constants (§3), the staleness
table (§2), the cross-core rule and dead-man (§6) — from the headers read
(`Link2Monitor.hpp`, `EngineSim.hpp`, `Link2Frame.hpp`) and the repo's CLAUDE.md/README/
SIMULATION.md.

**Inferred [I]:** the *why* narratives (audio real-time pressure, lock avoidance,
"sounds like the engine dying" as intended feedback) — standard reasoning consistent
with, but stated beyond, the docs. *(The packed word's bit layout, once listed here as
awaiting the deep-dive, was confirmed by S3; the packing site, volume derivation, and
dead-man wiring by S5 — every mechanism claim in this chapter is now source-verified,
with runtime/acoustic behavior still bench-pending, #32/#55/#57.)*

**Assumed [A]:** that synthesis quality is acceptable on the physical speaker — the
repo itself flags this as a bench question with the PCM fallback ready
(`docs/SIMULATION.md` checklist).

## Questions to check your understanding

1. The link2 wire is cut mid-drive. List what the speaker and the LEDs each do, and
   name the module + threshold responsible.
2. Why does `Link2Monitor` keep `gear` and `batteryMv` on staleness but zero `rpm`?
   What would look wrong if it were the other way round?
3. Board #1 says wheel rpm is 3200. Why doesn't the synth just make a 3200-rpm sound?
   Trace how engine rpm is actually determined.
4. Why is the noise generator *seeded* (deterministic) rather than truly random? Which
   file benefits most from that choice?
5. Explain why the synth parameters cross cores as ONE `std::atomic<uint32_t>` rather
   than four separate atomic fields. What specific artifact does this prevent?
6. Three separate mechanisms can silence the engine. Order them by how quickly they
   react to: (a) driver flips arm off, (b) board #1 hangs but UART keeps DMA-ing old
   bytes… wait — can (b) even happen on this design? Why not?
