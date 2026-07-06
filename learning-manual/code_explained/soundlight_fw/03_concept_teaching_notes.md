# S3 — Concept Teaching Notes

A beginner-first companion to `03_sound_synthesis.md`. The batch document explains
`EngineSynth` *line-by-line*; this document teaches *the ideas* behind it, one at a time,
so the lessons carry into S5 and into any future audio work. Same shape as the S1/S2
concept notes.

Every concept below follows the same seven steps (your requested structure):

1. **Plain meaning** — beginner level, no jargon.
2. **Why embedded audio needs it** — why a tiny microcontroller making engine noise cares.
3. **S3 code** — the exact place it lives (file + snippet or test).
4. **S2 connection** — how the engine model (batch S2) feeds this.
5. **Feeds S5/main** — how main.cpp's wiring (batch S5) will consume it (PROVISIONAL).
6. **Beginner traps** — the misunderstanding that bites first.
7. **Bug prevented** — the concrete failure this idea exists to stop.

Reference map: `03_sound_synthesis.md` (the line-by-line), `02_engine_simulation.md` (S2,
the input), `../../07_soundlight_firmware_architecture.md` (§4, §6), `../../glossary.md`,
`../../open_questions.md` (#43 answered here; #52/#53 raised here).

A one-sentence orientation: **`EngineSynth` turns five numbers — an engine rpm, a volume
byte, and three flags (ersWhine / limiter / overrun) — into a stream of 16-bit audio
samples at 22,050 per second, using pure integer arithmetic, deterministically. It makes
no decisions about the engine; it only renders one.**

---

## 1. What EngineSynth is responsible for — *rendering*, not *deciding*

**Plain meaning.** S2 (`EngineSim`) is the *model*: it decides what the engine is doing
(rpm, is it cranking, is the limiter hit). S3 (`EngineSynth`) is the *renderer*: it turns
those decisions into actual sound-pressure numbers. Model = "the engine is at 9,000 rpm on
the limiter." Render = "here are the next 256 loudspeaker positions that make that
audible." Two jobs, two libraries, a clean seam between them.

**Why embedded audio needs it.** Splitting *state* from *rendering* is what makes each
half testable and swappable. The model can be pure integer logic you can unit-test in
milliseconds; the renderer can be all-DSP and, crucially, **replaceable** — the whole
point of the `ISampleSource` interface is that if procedural synthesis sounds bad on the
real speaker, a PCM sample player (playing recorded engine audio) can drop in behind the
same seam without touching the model or anything upstream.

**S3 code.** The class is `EngineSynth : public ISampleSource`
(`EngineSynth.hpp:79`); the whole render contract is one method,
`size_t render(int16_t* out, size_t frameCount)` (`ISampleSource.hpp:21`). The interface
comment names the swap plan explicitly ("a PCM sample player can drop in behind this exact
interface later").

**S2 connection.** `EngineSynth` consumes what `EngineSim` produces — but *not* the whole
`EngineState` struct (concept 2). It is strictly downstream: it never reads a
`VehicleState`, never sees a frame, never touches a clock. Its only "time" is the sample
index.

**Feeds S5/main.** S5's `main.cpp` sits *between* S2 and S3: it reads `EngineState` off
`EngineSim`, converts it into the five synth parameters, and hands them across to the
render task. S3 defines the destination; S5 builds the road to it (**PROVISIONAL until
S5**).

**Beginner traps.** Thinking `EngineSynth` "plays a sound" as an action. It doesn't call
a speaker; it *fills a buffer* with numbers and returns. Something else (the I2S driver,
S5) carries those numbers to hardware.

**Bug prevented.** Tangling model and renderer — which would make the engine's *logic*
(does it stall on disarm? does the limiter trip?) impossible to unit-test without an audio
device, and would weld you to procedural synthesis forever (no PCM fallback).

---

## 2. How EngineState feeds the synth — five numbers, not a struct

**Plain meaning.** S2 outputs an `EngineState` with **six** fields. Only **five values**
reach the synth, and one of them (`volume`) isn't even in `EngineState` — it has to be
invented upstream. The synth's inputs are: `engineRpm`, `volume`, `ersWhine`,
`limiterActive`, `overrunActive`. What is **left out** matters as much as what's included:
`throttlePercent` and the `Ignition` state (Off/Cranking/Running) **never reach the
synth**.

**Why embedded audio needs it.** The renderer should take the *smallest* input that fully
determines the sound. Passing the whole model state would couple the renderer to the
model's internals and bloat the cross-core hand-off (concept 3). Five numbers is exactly
enough to render, and no more.

**S3 code.** The five parameters are the arguments of
`setParams(uint16_t engineRpm, uint8_t volume, bool ersWhine, bool limiter, bool overrun)`
(`EngineSynth.cpp:52`). Map them against S2's output struct
(`EngineSim.hpp:57–64`):

| `EngineState` field (S2) | Reaches synth? | As |
|---|---|---|
| `engineRpm` | yes | pitch + noise loudness |
| `limiterActive` | yes | the 18 Hz gate |
| `overrunActive` | yes | crackle bursts |
| `ersWhine` | yes | the whine layer |
| `throttlePercent` | **no** | — (the "throttle-correlated" noise is really rpm-scaled, #52) |
| `ignition` | **no** | — (Off→silence must become `volume = 0` upstream) |
| *(nothing)* | `volume` | **origin unknown until S5** |

**S2 connection.** This *is* the S2↔S3 seam. S2 spent 138 lines computing a believable
`EngineState`; S3 reads five slices of it. The `Ignition` state is the sharpest omission:
S2 uses it to force `engineRpm = 0` the instant the engine is Off — but rpm 0 alone does
**not** silence the synth (concept 17). Silence needs `volume = 0`, and nothing in S2's
`EngineState` carries a volume.

**Feeds S5/main.** S5's `main.cpp` must (a) copy `engineRpm` and the three flags straight
through, and (b) **derive `volume`** — almost certainly from `ignition` (Off → 0; running →
some level), possibly modulated further. That derivation is the load-bearing decision that
turns "engine Off" into actual silence, and it lives entirely in code we haven't read yet
(**PROVISIONAL until S5**; open q #43's remaining half).

**Beginner traps.** Assuming the synth "knows" whether the engine is off or what the
throttle is. It knows neither. It only knows a number called rpm, a number called volume,
and three booleans.

**Bug prevented.** A screaming engine at a standstill. If S5 wired rpm through but forgot
to map Off→`volume = 0`, the synth would happily render a tone from frozen phases (concept
17). The design makes volume the single, explicit "off switch" — so there is exactly one
place to get silence right.

---

## 3. The packed cross-core parameter word (open question #43, answered)

**Plain meaning.** The synth runs on one CPU core; the model runs on the other. To hand
five parameters from one core to the other *safely*, they are packed into a single 32-bit
integer — rpm in the low 16 bits, volume in the next 8, and one bit each for the three
flags. One integer crosses the gap; the receiver unpacks it back into five values.

**Why embedded audio needs it.** Two cores share memory, but if core 0 reads a
multi-field struct *while* core 1 is halfway through updating it, it can see a mix of old
and new fields — a **torn read** (new rpm with the old limiter flag). A single aligned
32-bit word is read or written in **one indivisible machine instruction** on this 32-bit
chip, so the reader sees either the whole old set or the whole new set — never a mixture.
No mutex needed (and a mutex next to real-time audio is dangerous — concept 4).

**S3 code.** `packParams` (`EngineSynth.hpp:21–27`) builds the word; `applyPackedParams`
(`EngineSynth.cpp:61–64`) takes it apart. The documented layout (the answer to #43):

```
bits  0..15  engineRpm   bits 16..23  volume   bit 24 ersWhine
bit 25 limiterActive      bit 26 overrunActive  bits 27..31 reserved
```

The two functions are exact mirrors — every `<< N` in pack has a matching `>> N & mask` in
unpack, so they cannot drift.

**S2 connection.** The five values packed here are S2's `EngineState`, minus throttle and
ignition, plus the derived volume (concept 2). S2 doesn't know about packing; it just
fills a struct.

**Feeds S5/main.** S5 will hold an actual `std::atomic<uint32_t>`: core 1 calls
`store(packParams(...))` each control tick; core 0 calls `applyPackedParams(atomic.load())`
inside the audio task. There is *also* a separate heartbeat atomic for the dead-man
(concept 20). None of that atomic machinery is in S3 — S3 only provides the pack/unpack
pair and proves it round-trips (**PROVISIONAL until S5** for the real atomic).

**Beginner traps.** (a) Thinking the atomic lives in `EngineSynth`. It doesn't — S3 offers
the *format*; S5 owns the *variable*. (b) Thinking you could just pass a pointer to a
struct across cores "since they share memory." You can, and it will tear. The single word
is the whole trick.

**Bug prevented.** Torn parameter reads: the audio task rendering full rpm with a
stale-but-still-set limiter bit, producing a half-updated sound for one buffer. One atomic
word makes that impossible.

---

## 4. Real-time discipline — allocation- and lock-free rendering

**Plain meaning.** The audio task must produce a finished buffer of samples every ~11.6 ms
(256 samples at 22,050 Hz), forever, without ever being late. To guarantee that, `render()`
is forbidden from doing anything that *might* pause: no memory allocation, no locks.

**Why embedded audio needs it.** If a buffer is late, the speaker runs out of samples and
**pops or stutters** — the most audible failure there is. A heap allocation can block while
the allocator is busy; a mutex can block while the other core holds it. Either can blow the
11.6 ms deadline. So the render path only touches member variables and the stack — bounded,
predictable time every call.

**S3 code.** The contract is stated in the interface comment (`ISampleSource.hpp:8–12`):
"render() runs on the core-0 audio task and must be allocation- and lock-free." The
implementation obeys — read `render()` (`EngineSynth.cpp:78–150`): no `new`, no `std::`
container, no lock, not even a function that could allocate. Even the sine table is built
*once* at startup (concept 9), never in the loop.

**S2 connection.** Same house rule S2 already followed ("integer math in all control/render
paths; float only in one-time setup" — repo CLAUDE.md). S2's `update()` is likewise
allocation-free. The discipline spans both libraries.

**Feeds S5/main.** S5 pins the render task to core 0 and feeds its output to
`Esp32I2sAudio` under a real DMA deadline. Only then is the "must be lock-free" contract
actually *load-bearing* — on the host it's just good hygiene (**PROVISIONAL until S5** for
the real deadline).

**Beginner traps.** Thinking "it's fast enough, a little `malloc` won't hurt." Real-time
isn't about *average* speed; it's about the *worst case* never exceeding the deadline. One
rare 12 ms allocation stall out of a million calls is still an audible pop.

**Bug prevented.** Buffer underruns — periodic clicks/dropouts that are maddening to
diagnose because they're intermittent and timing-dependent.

---

## 5. Samples, sample rate, and sample-by-sample generation

**Plain meaning.** Sound is a speaker cone moving. Digitally, we describe that motion as a
list of numbers — **samples** — each saying "where the cone should be right now," taken at
a steady **sample rate**. Here each sample is an `int16_t` (−32,768…+32,767; 0 = cone at
rest) and the rate is **22,050 samples per second**, so one sample represents ≈ **45.4 µs**
of sound. The synth generates them **one at a time** in a loop.

**Why embedded audio needs it.** The I2S hardware consumes samples at a fixed clock; the
synth must produce exactly that many, exactly that often. 22,050 Hz is a deliberate
embedded compromise — half of CD's 44,100 Hz, so half the CPU and half the data, while
still able to represent everything up to 11,025 Hz (concept 6's Nyquist limit), which
covers the engine's whole range.

**S3 code.** `inline constexpr uint32_t kSampleRateHz = 22050;` (`EngineSynth.hpp:9`). The
generation loop is `for (size_t f = 0; f < frameCount; ++f) { ... }`
(`EngineSynth.cpp:79`) — everything inside runs once per sample.

**S2 connection.** Note the *rate mismatch*: S2 updates the engine model ~50 times a second
(every 20 ms control tick); S3 updates the *sound* 22,050 times a second. So between two
model updates, the synth renders ~441 samples from the *same* parameters. That gap is
exactly why parameter smoothing exists (concept 12).

**Feeds S5/main.** S5 decides the *buffer size* (how many samples per `render()` call —
likely 256, ≈ 11.6 ms) and the cadence at which the audio task calls `render()` and pushes
to I2S. S3 renders whatever `frameCount` it's asked for; S5 chooses that number
(**PROVISIONAL until S5**).

**Beginner traps.** Confusing the **control rate** (50 Hz, the model) with the **audio
rate** (22,050 Hz, the samples). They are three orders of magnitude apart. Also: a "sample"
here is one cone position, not one musical note.

**Bug prevented.** Rate confusion — e.g. updating a phase once per control tick instead of
once per sample would produce a 50 Hz buzz instead of an engine note. Per-sample generation
keeps the audio smooth between sparse model updates.

---

## 6. RPM → firing frequency (the number that becomes pitch)

**Plain meaning.** How high the engine sounds is a frequency in Hz. It comes from rpm by
one formula: **f = rpm / 60 × firingsPerRev**. rpm/60 is revolutions per *second*;
multiplying by firings-per-revolution gives firings per second = Hz. With `firingsPerRev =
5` ("V10 flavor"), 3,500 rpm → 291.7 Hz and 15,000 rpm → 1,250 Hz.

**Why embedded audio needs it.** The *entire* pitch of the engine note is derived from one
input number, so the conversion must be cheap and precise. And the constants aren't
arbitrary: 5 firings/rev is real four-stroke V10 physics (10 cylinders over 2 revolutions),
and the 3,500–15,000 rpm range was chosen so the fundamental lands in a small 3 W speaker's
usable band (~300 Hz+) — audio engineering, not physics.

**S3 code.** `fundMilliHz = rpm * config_.firingsPerRev * 1000u / 60u`
(`EngineSynth.cpp:90–91`). It's computed in **milli-Hz** (thousandths of a Hz) so the
pitch resolution stays fine even at low rpm (concept 8). The ×1000 is done before the ÷60
to keep integer precision (divide-last, the house idiom).

**S2 connection.** The rpm here is S2's **synthesized engine rpm**, not the car's wheel
rpm. S2 deliberately maps throttle (not wheel speed) across 3,500–15,000 so the *sound*
sits in the speaker's band — the wheel maxes near 5,000 and is never read (note #51). So
this concept and S2 are two halves of one decision: S2 invents an rpm in a musical range;
S3 turns it into the matching frequency.

**Feeds S5/main.** Nothing new — S5 just delivers the rpm value into the packed word. The
conversion is entirely inside `render()`.

**Beginner traps.** (a) Thinking the engine sound tracks the *car's* speed. It tracks
S2's *invented* engine rpm, which follows throttle. (b) Forgetting the /60: rpm is per
*minute*, frequency is per *second*.

**Bug prevented.** A wrong-octave or out-of-band engine note. If you fed wheel rpm (≤5,000)
straight in, the fundamental would top out at ~417 Hz — a weak, low buzz the little speaker
barely makes. The rpm-range choice + this formula keep the note where the speaker lives.

---

## 7. The phase accumulator — how one oscillator remembers "where in the wave it is"

**Plain meaning.** To generate a repeating wave, the synth must track its position within
one cycle — its **phase**. Store phase as a `uint32_t` where the full range 0…2³²−1 means
"0 to one whole cycle." Each sample, add a fixed **increment**. When the addition overflows
past 2³², unsigned arithmetic wraps back toward 0 — which is *exactly right*, because
"one full cycle later" is the same as "back to the start."

**Why embedded audio needs it.** It's the cheapest exact oscillator there is: one add per
sample, and the dreaded integer wraparound becomes the *mechanism* instead of a bug. To
play frequency f, you want f cycles (f wraps) per second, so **increment = f × 2³² /
sampleRate**.

**S3 code.** Each partial owns a `uint32_t partialPhase_[p]`
(`EngineSynth.hpp:109`); the render loop does `partialPhase_[p] += inc;`
(`EngineSynth.cpp:101`) with `inc` from `phaseIncForMilliHz(...)`. The whine
(`whinePhase_`) and the limiter gate (`limiterPhase_`) are the same trick.

**S2 connection.** S2 uses the *same conceptual pattern at a different timescale*: its rpm
"chases" a target by a fraction each tick (exponential approach). Here the accumulator adds
a *fixed* step each sample. Both are "advance a stored value by a computed amount every
time step" — but the accumulator is linear-and-wrapping, S2's inertia is fractional-and-
converging. Recognizing the family helps; don't conflate the math.

**Feeds S5/main.** Nothing — phase state is audio-task-only and never crosses cores
(concept 3). S5 must *not* reach into it (the cross-core rule).

**Beginner traps.** (a) Thinking the overflow is a bug to guard against. It's the feature:
phase 2π = phase 0. (b) Thinking you need floating-point angles. You don't — a 32-bit
integer *is* the angle, scaled so the whole `uint32_t` range is one turn.

**Bug prevented.** Phase drift and clicks. Because the accumulator persists across samples
and only the *increment* changes when rpm glides, the wave bends pitch smoothly with **no
discontinuity** — no click on every rev change. A naive "recompute the wave from scratch
each block" approach would click at every parameter step.

---

## 8. Fixed-point / integer math (milli-Hz, eighths, and the 2³² map)

**Plain meaning.** There is no floating point in the render path. Fractional quantities are
represented as **integers in agreed units**: frequency in **milli-Hz** (so 291.666 Hz is
the integer 291,666), the whine's pitch ratio in **eighths** (24 means 24/8 = 3.0×), and
phase as a fraction of 2³² (so 2³² *is* "one cycle"). This is **fixed-point** thinking:
scale a real number by a known factor, store the integer, remember the factor.

**Why embedded audio needs it.** Integer math is fast, exactly reproducible, and available
everywhere (concept 19's determinism depends on it). Floating point on a microcontroller can
be slower and — worse for testing — can differ in the last bit between the Mac and the
ESP32. The one place float is allowed is the *one-time* sine-table build (concept 9),
because it never runs in the render path and its result is rounded to integers anyway.

**S3 code.** Milli-Hz: `phaseIncForMilliHz` (`EngineSynth.cpp:40–45`) computes
`freqMilliHz * 2^32 / (1000 * 22050)` in `uint64_t` to avoid overflow. Eighths:
`whineMilliHz = fundMilliHz * config_.whinePitchEighths / 8u` (`EngineSynth.cpp:124`). The
±256 sine table + `>> 8` (concept 11) is another fixed-point choice.

**S2 connection.** S2 is entirely integer too, with its own fixed-point trick: rpm inertia
uses **per-mille** rates (6‰/3‰ of the gap per ms). Same philosophy — represent a fraction
as an integer over a fixed denominator — different denominator. The whole soundlight board
is float-free in its logic.

**Feeds S5/main.** The packed word (concept 3) is the ultimate fixed-point object: five
values crammed into bit-fields of one integer. S5 packs and unpacks it.

**Beginner traps.** (a) Reading `whinePitchEighths = 24` as "24×." It's 24 *eighths* = 3×.
(b) Expecting the ×1000 milli-Hz factor to appear in the output — it's just internal
precision; it divides back out. (c) Thinking integer math is "less accurate." Here it's
*exactly* accurate to the chosen unit and, unlike float, bit-identical across machines.

**Bug prevented.** Non-reproducible tests and precision loss at low rpm. Integer Hz would
give a coarse 1 Hz pitch staircase at a 292 Hz idle; milli-Hz shrinks that to 0.001 Hz.
And float would break "same seed → same samples" across platforms (concept 19).

---

## 9. The wavetable (sine table) — compute the wave once, look it up forever

**Plain meaning.** Instead of calling `sin()` thousands of times a second, the synth
computes **one full sine cycle once**, at startup, into a 256-entry table (values ±256),
then just *reads* from it at render time using the phase accumulator's top 8 bits as the
index. A precomputed wave table is a **wavetable**.

**Why embedded audio needs it.** Trig is expensive; a table read is nearly free (one array
access). With up to 7 oscillators × 22,050 samples/s, calling `sin()` each time would be far
too costly on the chip, and the house rule bans float from the render path anyway. Build
once, look up millions of times.

**S3 code.** `struct SineTable` fills `int16_t v[256]` in its constructor
(`EngineSynth.cpp:10–34`) using a 7th-order Taylor polynomial (float allowed — init only);
`const SineTable kSine;` is built at static-init. `sineLookup(phase)` is just
`kSine.v[phase >> 24]` (`EngineSynth.cpp:66`) — the top 8 bits pick one of 256 entries.

**S2 connection.** None directly — S2 has no waveforms. This is genuinely new S3 machinery.
(Conceptually it pairs with concept 7: the accumulator says *where* in the cycle; the table
says *what value* is there.)

**Feeds S5/main.** Nothing — the table is internal. (Trivia for S5/bench: its worst
approximation error is ~19 counts of 256 near the wrap point — a tiny once-per-cycle kink,
i.e. a hair of extra harmonic "buzz." Whether that's audible is a bench question.)

**Beginner traps.** (a) Thinking 256 entries is too few. The phase's top 8 bits index it;
the lower 24 bits are dropped, adding a quantization "staircase" ~48 dB below the tone —
buried under the deliberate noise layer. (b) Thinking the float in the table build breaks
the "integer-only" rule — it doesn't, because it runs once at startup, not per sample.

**Bug prevented.** A render path too slow to hit its deadline (concept 4), and float
creeping into the hot loop (which would threaten both speed and cross-platform
reproducibility).

---

## 10. Additive synthesis — building the engine's *timbre* from harmonic partials

**Plain meaning.** A single sine wave sounds like a sterile test tone. Real engines (and
instruments) emit energy at the fundamental *and* at integer multiples of it — the
**harmonics**. The synth adds several sine waves — one at f, one at 2f, one at 3f, … — each
with its own loudness. Each sine is a **partial**; summing them is **additive synthesis**;
the *relative* loudnesses are the sound's **timbre** (its character).

**Why embedded audio needs it.** Timbre is what makes it sound like a V10 and not a beep.
Additive synthesis gives direct, cheap control: six amplitude numbers *are* the voice, and
they're deliberately weighted toward harmonics 2–4 (not a fundamental-heavy sawtooth)
because the little speaker barely reproduces the fundamental — so the energy is put where
the speaker can actually make it.

**S3 code.** The partial stack loop (`EngineSynth.cpp:96–104`): for each partial p, run an
oscillator at `fundMilliHz * (p + 1)` and add `(sineLookup(...) * partialAmp[p]) >> 8` to
the mix. The voice is `partialAmp = {2200, 4400, 5600, 4000, 2600, 1400, 0, 0}`
(`EngineSynth.hpp:42`) — fundamental 2200, 3rd harmonic loudest at 5600, top two partials
off (6 of 8 used).

**S2 connection.** S2 sets *how fast* the harmonics all sing (rpm → fundamental, concept 6);
S3 sets *what the chord of harmonics sounds like* (the fixed amplitude weights). S2 changes
pitch; the timbre weights are constant. Together: an engine that changes pitch with revs but
keeps its character.

**Feeds S5/main.** Nothing at runtime — the voice is config. (Bench/#32 may *retune* those
six numbers after hearing the real speaker; that's the voicing session the config is built
for.)

**Beginner traps.** (a) Confusing "partial" (one sine component) with "sample" (one output
number) — one sample is the *sum* of all partials at that instant. (b) Thinking more
partials = better. Above Nyquist they'd alias (concept 15); the top two are off partly for
that headroom.

**Bug prevented.** A lifeless beep, or wasted headroom. Weighting toward audible harmonics
puts the limited amplitude budget where the speaker and ear will use it, instead of pumping
a fundamental the cone can't move.

---

## 11. Amplitude scaling — how loud each layer is, in integer units

**Plain meaning.** Each layer's loudness is an integer "amplitude." The clever bit: the
sine table is ±256, and after multiplying table × amplitude the code shifts right by 8
(÷256), so **each partial contributes exactly ± its `partialAmp` value** in int16 units.
The table's amplitude and the shift cancel, making `partialAmp` a direct "peak height" knob.

**Why embedded audio needs it.** You want amplitudes in the same units you'll clip against
(int16), so you can *budget* them (concept 18). The ±256-then-÷256 design makes the units
line up with zero runtime cost — pure integer scaling, no division beyond a shift.

**S3 code.** Partial: `sample += (sineLookup(...) * config_.partialAmp[p]) >> 8`
(`EngineSynth.cpp:103`). Noise: `((nextNoise() - 32768) * noiseAmp) >> 15`
(`EngineSynth.cpp:113`). Whine: `(sineLookup(...) * config_.whineAmp) >> 8`
(`EngineSynth.cpp:126`). Master volume: `sample = sample * vol / 255`
(`EngineSynth.cpp:131`). Different shifts because the generators have different full-scale
ranges (table ±256 → ÷256; noise ±32,768 → ÷32,768).

**S2 connection.** None — S2 has no amplitudes. New S3 concept. (S2's numbers are rpm and
booleans; loudness is entirely S3's.)

**Feeds S5/main.** The **master volume** (concept 2) is the one amplitude S5 controls each
tick, via the packed word. Everything else is fixed config. So S5's volume value scales the
whole finished mix up or down.

**Beginner traps.** (a) Thinking the shift is a "divide for rounding." It's the units
cancelling: ±256 table × amp ÷ 256 = ±amp. (b) Missing that master volume scales *all*
layers together (after the mix), preserving balance at any loudness.

**Bug prevented.** Amplitudes in incomparable units — which would make the headroom budget
(concept 18) meaningless and let the mix clip unpredictably.

---

## 12. Parameter smoothing & the zipper trap (and finding #53)

**Plain meaning.** The model updates volume and rpm ~50 times a second in steps; if the
synth *jumped* to each new value, you'd hear a "zipper" — a gritty staircase on volume and
clicks on pitch. The fix: each sample, move a *fraction of the remaining gap* toward the
target, so steps become short glides. Here that fraction is 1/64 (`>> 6`).

**Why embedded audio needs it.** Audio is sensitive to discontinuities: an instantaneous
jump in amplitude or frequency injects a click (a burst of broadband energy). Smoothing
spreads each 50 Hz step over a few milliseconds so the ear hears a glide, not a step.

**S3 code.** `smoothRpm_ += (targetRpm_ - smoothRpm_) >> 6;` and the same for volume
(`EngineSynth.cpp:82–83`). This is a **one-pole smoother** — the exact same exponential-
approach math as S2's inertia and C7's battery EMA, now at the per-sample timescale (τ ≈
2.9 ms).

**S2 connection.** Third appearance of one idea: C7's EMA smooths battery volts; S2's
inertia smooths rpm per tick; S3's smoother smooths params per sample. Same shape,
different timescale. If you understood S2's inertia, you already understand this.

**Feeds S5/main.** S5 sets the *targets* (via the packed word) at 50 Hz; the smoother
absorbs the steps. **But two findings S5 must know (#53):** (1) the code comment claims
"~1/1024, ~23 ms" but `>> 6` is 1/64 ≈ 2.9 ms — the comment is wrong. (2) Integer
truncation makes *upward* approaches **park short of the target**: **volume 255 from silence
settles at 192 (~75% of full scale)**, and **any volume target 1–63 approached from silence
stays exactly 0 (silent)**; *downward* approaches converge exactly (so `volume = 0` truly
silences). So the volume values S5 chooses interact directly with this quirk (**PROVISIONAL/
owner question #53**).

**Beginner traps.** (a) Thinking `>> 6` and the "~1/1024" comment agree — they don't
(concept-level lesson: trust the code, not the comment). (b) Assuming an exponential
smoother always reaches its target — with integer truncation, it doesn't, upward.

**Bug prevented.** Zipper noise and click-on-step. And the *discovery* here prevents a
subtler bug shipping unnoticed: without measuring, nobody would know "full volume" is
actually 75% and low volumes are silent.

---

## 13. The noise layer — seeded pseudo-random rasp (xorshift32 / LFSR)

**Plain meaning.** Real engines have a rough, noisy edge, not just clean tones. The synth
adds **noise** — random-looking values — scaled to get louder with rpm. The randomness comes
from a fast generator (**xorshift32**, an LFSR-family algorithm) that is *seeded*: given the
same starting seed, it produces the exact same "random" sequence every run.

**Why embedded audio needs it.** (a) Character: noise is what separates a believable engine
from a synthesizer. (b) Determinism: a *seeded* generator makes the whole render
reproducible, so tests can render the same block twice and demand bit-identical output
(concept 19). A truly random source, or library `rand()`, would break that and vary across
platforms.

**S3 code.** `nextNoise()` (`EngineSynth.cpp:68–76`) — three XOR-with-shift steps (13/17/5),
returns the low 16 bits. Scaling: `noiseAmp = noiseAmpMax * rpm / 15000`
(`EngineSynth.cpp:109`) — 0 at rest, full 1,600 at redline. The generator has one dead fixed
point (state 0 → 0 forever), so the constructor guards the seed: `noiseState_(noiseSeed ?
noiseSeed : 1u)` (`EngineSynth.cpp:50`).

**S2 connection.** The noise loudness follows *rpm* (S2's synthesized engine rpm), **not
throttle** — despite comments calling it "throttle-correlated" (finding #52). Since S2 maps
throttle→rpm, the effect is throttle-correlated one inertia-lag later, but the code reads
rpm. Good example of "comment lineage vs code reality."

**Feeds S5/main.** S5 passes the seed at construction (or accepts the default `0x1234`). The
noise *amount* rides on the rpm S5 delivers; there's no separate noise knob in the packed
word.

**Beginner traps.** (a) "Seeded random isn't really random." Correct — it's *deterministic*
pseudo-random, and that's the point here. (b) Thinking seed 0 is fine. It silences the noise
permanently — hence the guard.

**Bug prevented.** Non-reproducible audio tests (a truly random source would make
`test_deterministic_given_seed` impossible), and a silent-noise-channel bug from a zero
seed.

---

## 14. Overrun crackle — the per-sample amplitude lottery

**Plain meaning.** When a race car lifts off the throttle at high revs, it pops and crackles
("overrun" / after-fire). The synth makes this by, during a special window, occasionally
(1 in 4 samples) blasting the noise 3× louder for that single sample — scattered loud noise
spikes = crackle.

**Why embedded audio needs it.** It's a signature F1 sound and a great example of building a
complex texture from a trivial rule (a per-sample coin flip), with no extra state or buffers
— cheap enough for the render loop.

**S3 code.** `if (overrun_ && (nextNoise() & 0x3) == 0) noiseAmp = config_.noiseAmpMax * 3;`
(`EngineSynth.cpp:110–112`). `& 0x3` keeps 2 random bits; `== 0` is a 1-in-4 chance; when it
hits, that one sample's noise amplitude jumps to 4,800.

**S2 connection.** S2 **decides when** overrun is happening — it opens a 900 ms
`overrunActive` window after detecting a ≥40-point throttle drop from ≥10,400 rpm
(`EngineSim`, S2 §2.7). S3 **fills that window with sound**. Clean division: S2 detects the
event; S3 renders it. (This resolves S2's forward-promise "the synth adds the actual gated
noise bursts.")

**Feeds S5/main.** S5 just passes `overrunActive` through as bit 26 of the packed word. No
extra wiring.

**Beginner traps.** (a) Thinking overrun is loud *all* the time in the window — it's random
1-in-4 spikes, so it crackles rather than roars. (b) Missing that the burst branch draws an
*extra* random number, shifting the noise sequence — harmless, but it's why the determinism
test runs with overrun on (to exercise that path).

**Bug prevented.** A flat, characterless lift-off. And by keeping detection in S2 and
rendering in S3, neither has to know the other's internals — you can retune the crackle
density without touching the engine model.

---

## 15. Nyquist & aliasing — the ceiling on partial frequencies

**Plain meaning.** A signal sampled at 22,050 Hz can only faithfully carry frequencies below
**half** that — 11,025 Hz (the **Nyquist limit**). Anything higher doesn't vanish; it
"folds back" and comes out as a *wrong, lower* tone — an artifact called **aliasing**.

**Why embedded audio needs it.** Additive synthesis stacks harmonics at 2f, 3f, … 6f. At
redline the 6th harmonic is 6 × 1,250 = 7,500 Hz — safely under 11,025. If a partial (or a
too-high rpm) pushed a harmonic past Nyquist, it would alias into an audible wrong pitch that
no volume control can remove.

**S3 code.** Implicit in the partial loop (`EngineSynth.cpp:100`, `fundMilliHz * (p+1)`) and
the config: only 6 partials are enabled and the rpm range is bounded, so the top populated
harmonic stays ~7.5 kHz. There's *no explicit anti-alias guard in the synth* — it relies on
upstream keeping rpm ≤ 15,000.

**S2 connection.** **S2 is the guard.** EngineSim's rpm map and clamps keep engine rpm within
3,500–15,000, which is what keeps the 6th harmonic under Nyquist. The synth trusts that. A
corrupt packed word claiming ~30,000 rpm would alias — but S2's output range (S2-verified)
plus S5's wiring are what make S2 the only source.

**Feeds S5/main.** S5 must ensure the rpm reaching the packed word really comes from
EngineSim (never an unclamped value). That's part of why the S2→S5→S3 chain matters
(**PROVISIONAL until S5**).

**Beginner traps.** (a) Thinking aliasing is "just a bit of distortion." It's a *false
frequency* — often dissonant and unremovable downstream. (b) Assuming the synth self-limits
rpm. It doesn't; the safety is upstream.

**Bug prevented.** Aliasing screeches at extreme rpm. The rpm-range discipline (S2) plus the
modest partial count keep every harmonic legal.

---

## 16. The rev-limiter gate & the crank/idle/silence behaviors (how S2 states *sound*)

**Plain meaning.** Several of S2's engine behaviors become sound in specific ways:
- **Rev limiter** ("braaap"): the synth chops its *whole output* to zero at 18 Hz, 50% duty
  — sound, silence, sound, silence, 18 times a second — mimicking an ignition cut.
- **Crank**: S2 reports `engineRpm = 1800` during Cranking, so the synth just plays a low
  ~150 Hz-fundamental tone (carried mostly by harmonics; the fundamental is below the
  speaker band).
- **Idle**: S2 adds a ±120 rpm wobble to the rpm, which the synth renders as a gently
  hunting pitch — there is **no** separate idle-AM code in the synth (finding #52).
- **Shift blip**: S2 injects a transient ±1400 rpm offset for 130 ms; the synth has **no
  dedicated shift sound** — it simply plays the momentary rpm change as a pitch blip.
- **Silence (Off)**: covered in concept 17.

**Why embedded audio needs it.** It shows the division of labor: *the synth renders numbers;
the "behaviors" are mostly just rpm being moved around by S2*, plus three flags the synth
interprets. Only the limiter and overrun are genuinely synth-side effects; crank, idle, and
shift are all "S2 changes rpm, the synth follows."

**S3 code.** Limiter: `limiterPhase_ += phaseIncForMilliHz(config_.limiterCutHz * 1000u);
if ((limiterPhase_ >> 31) != 0) sample = 0;` (`EngineSynth.cpp:134–139`) — the accumulator's
top bit is a square-wave; when it's 1 (second half of each cycle), zero the sample.
Crank/idle/shift have *no dedicated code* — they arrive as rpm values.

**S2 connection.** Direct: S2 *is* where crank rpm (1,800), the idle wobble, and the shift
blip live (S2 §2). S2 also raises `limiterActive` (throttle ≥95 ∧ base rpm ≥14,750). The
synth renders the flag and follows the rpm. (Resolves S2's forward-promise "the synth's
on/off buzz cadence" = 18 Hz square gate.)

**Feeds S5/main.** S5 passes `limiterActive` as bit 25 and the rpm value through. No extra
wiring for crank/idle/shift — they're already in the rpm number.

**Beginner traps.** (a) Looking for a "shift sound" or "idle wobble oscillator" in the synth
— there isn't one; both are rpm modulations from S2. (b) Thinking the limiter changes pitch
— it doesn't; it *gates* (mutes) at 18 Hz.

**Bug prevented.** Duplicating engine behavior in two places. Because crank/idle/shift are
purely S2 rpm effects, the synth stays simple and there's no risk of S2 and S3 disagreeing
about them.

---

## 17. Silence is `volume = 0`, not `rpm = 0` (the load-bearing boundary)

**Plain meaning.** You might expect "engine Off → rpm 0 → silence." But rpm 0 alone does
**not** silence the synth: at rpm 0 the oscillator increments are 0, so the phases *freeze*
at whatever value they held, and the frozen sine lookups sum to a **constant** (a DC offset)
— quiet-ish but not zero, and a click/thump on transition. True silence requires **`volume =
0`**, which multiplies the whole mix to exactly 0.

**Why embedded audio needs it.** There must be one unambiguous "off switch." Relying on rpm
0 would leave a DC offset on the speaker (bad for the cone and a pop on change). Making
volume the silence mechanism gives a single, exact, testable path to zero output.

**S3 code.** `sample = sample * vol / 255` (`EngineSynth.cpp:131`): only `vol == 0`
guarantees `sample == 0` regardless of the partial/noise state. `test_zero_volume_is_silent`
(`test_main.cpp:91–100`) pins 1,024 samples at exactly 0. And the smoother converges to 0
*exactly* from above (concept 12), so a `volume = 0` target really reaches 0.

**S2 connection.** S2's `Ignition::Off` forces `engineRpm = 0` immediately — but, per concept
2, `ignition` **does not reach the synth**. So Off does *not* automatically silence anything.
The connection is a *gap* that S5 must fill.

**Feeds S5/main.** **This is the single most important thing S5 must get right:** map
`ignition == Off` (and the dead-man, concept 20) to `volume = 0` in the packed word.
Everything about "link lost → engine dies → silence" ultimately depends on S5 setting volume
to 0 (**PROVISIONAL until S5**; the remaining half of #43).

**Beginner traps.** Assuming rpm 0 = silence. It's the top trap of this whole batch. Silence
is a volume decision, made upstream.

**Bug prevented.** A DC offset or a stuck constant tone when the engine "stops" — or worse, a
lingering sound after link loss. Volume-as-off-switch, wired in S5, is what actually kills
the sound.

---

## 18. Mixing, headroom, and clipping/saturation

**Plain meaning.** All layers (6 partials + noise + whine) are summed into one running total
— the **mix bus** — held in a wide `int32_t` so the sum can temporarily exceed the int16
output range. **Headroom** is the design guarantee that the *worst-case* sum still fits under
the int16 rail, so the mix can't clip. As a final safety net, the value is **clamped**
(saturated) to the rail before output.

**Why embedded audio needs it.** If a sum exceeded int16 and was just cast down, it would
**wrap** — a loud, ugly glitch (and signed overflow is undefined behavior in C++). Two
defenses: (1) *budget* the amplitudes so overflow can't happen (headroom), and (2) *clamp*
anyway, converting any hypothetical overflow into mere distortion instead of a wrap.

**S3 code.** Mix bus: `int32_t sample = 0;` then `+=` each layer (`EngineSynth.cpp:93–128`).
Headroom: `EngineSynthConfig::peakSum()` (sum of |partial| + noise + whine = 24,600 by
default) and `valid()` requires it ≤ `kHeadroomPeak = 30,000` (`EngineSynth.hpp:56–73`).
Clamp: `if (sample > 32767) sample = 32767; if (sample < -32768) sample = -32768;`
(`EngineSynth.cpp:141–142`). Measured worst-case real peak: **17,944** of 32,767 — the mix
rarely peaks all-together, so there's comfortable margin.

**S2 connection.** None directly (S2 has no amplitudes). Philosophically it mirrors S2/C6's
"prove the bound in `valid()`" habit — the headroom check is the audio analogue of the
gearbox monotonicity guard.

**Feeds S5/main.** S5's config gets the `static_assert(config.valid())` at its definition
site (like S1/S2's configs) — so a voice that could clip fails to *compile* (**PROVISIONAL
until S5** for the assert site). One caveat: `peakSum()` doesn't count the overrun ×3 burst,
so the guarantee is "no clip outside bursts"; the clamp covers the rest.

**Beginner traps.** (a) Thinking the clamp is the *main* anti-clip mechanism. The main one is
the headroom *budget*; the clamp is the backstop. (b) Thinking `int16` mixing would be fine —
it would overflow mid-sum; the wide `int32` bus is essential.

**Bug prevented.** Overflow wraparound — a deafening glitch when layers align — and undefined
behavior from signed overflow. Budget + clamp make output always in-range and usually
well-clear of the rails.

---

## 19. Deterministic audio testing — the same seed gives the same samples

**Plain meaning.** Because every part of the render path is integer and the noise is seeded,
two `EngineSynth` objects with the same config, seed, and parameter history produce
**bit-for-bit identical** output. That's what lets a test assert exact sample values instead
of vague "sounds about right."

**Why embedded audio needs it.** Audio is otherwise hard to test — you can't eyeball 22,050
numbers or assert on "how it sounds." Determinism turns the synth into an ordinary pure
function you can pin with exact-equality assertions and reproduce on any machine.

**S3 code.** `test_deterministic_given_seed` (`test_main.cpp:141–155`): two synths, same seed
`0xABCD`, same params (with whine + overrun on to exercise the stateful paths), render ten
blocks each, then assert all 512 samples equal. Underpinned by the seeded `nextNoise()`
(concept 13) and float-free rendering (concept 8).

**S2 connection.** S2 is deterministic too (integer, clock-as-parameter), which is why its
9 tests can assert exact rpm values. The whole board is built for reproducible tests.

**Feeds S5/main.** S5's integration test (`test_integration`) drives frames→audio end-to-end
and can rely on this determinism to assert exact output for a scripted input
(**PROVISIONAL until S5**).

**Beginner traps.** (a) Thinking "random noise" defeats testing — the *seeded* generator is
exactly what enables it. (b) Assuming determinism means Mac and ESP32 produce identical bytes
— extremely likely here (integer + float-free table) but formally a bench/S5 observation.

**Bug prevented.** Untestable, drift-prone audio code. Determinism means a regression in any
layer changes the output bytes and fails a test loudly.

---

## 20. What native tests prove, what they can't, and the S4/S5/hardware boundaries

**Plain meaning.** `pio test -e native -f test_soundsynth` (9/9) runs the DSP **on the Mac**
and proves the *logic*: pitch tracks rpm, volume 0 is silent, stereo channels match, the
limiter gates, output stays in range, the same seed reproduces. It proves nothing about
*sound* or *timing on real hardware*.

**Why embedded audio needs it.** Native tests are fast, deterministic, and hardware-free —
you pound the tricky integer math thousands of times without a chip. But "correct on the
laptop" ≠ "sounds like an engine through a 3 W speaker." Knowing the boundary keeps you
honest.

**S3 code / evidence.** The 9 tests (`test_main.cpp`) plus a scratchpad harness that measured
what the tests *don't* pin (smoother parking, true peak 17,944, settled pitch 994 Hz, limiter
duty ~50%). Honest test-strength notes are in `03_sound_synthesis.md` §8.2 (e.g.
`test_never_clips_at_max_settings` is a tautology; the volume test compares sound-vs-silence).

**S2 connection.** Same testing philosophy and same boundary as S2: logic proven natively,
acoustics deferred to bench. S2 couldn't prove the engine *sounds* right either.

**Feeds S5/main & hardware — the boundary list:**
- **Waits for S5** (`main.cpp` + audio HAL + `test_integration`): the real
  `std::atomic<uint32_t>` and who writes it; **where `volume` comes from** (the Off→silence
  mapping, concept 17); the heartbeat + **dead-man** (~500 ms no refresh → volume ramps to 0);
  task pinning to core 0; buffer size/cadence vs the ~11.6 ms deadline; `Esp32I2sAudio`; the
  config `static_assert` site; soundlight's `platformio.ini`/`ci.yml`.
- **Waits for real ESP32/I2S/speaker** (open q #32): whether it *sounds* like an engine on the
  MAX98357A + 3 W cone — the whole reason `ISampleSource` (PCM fallback) exists; the audibility
  of the 75%-volume quirk (#53), the sine-table wrap kink, and the ~150 Hz crank fundamental;
  the GAIN strap and SD_MODE (L+R)/2 mixing; the real-time CPU budget of ~7 oscillators/sample
  on a 240 MHz core; DMA underrun behavior.
- **S4 (lights)** depends on **none** of this — it reads `VehicleState` directly, not
  `EngineState` or audio.

**Beginner traps.** Reading "9/9 PASSED" as "the engine sound works." It means "the DSP logic
is correct on this Mac." Necessary, not sufficient.

**Bug prevented.** Overconfidence — shipping to the bench believing the sound is validated,
when only the math is. The boundary list is the to-do for the real speaker.

---

## Quiz — 20 questions

1. In one sentence each, state the jobs of `EngineSim` (S2) and `EngineSynth` (S3), and name
   the interface that lets a PCM player replace the synth.
2. `EngineState` has six fields. Which reach the synth, which two don't, and which synth
   input has *no* `EngineState` source at all?
3. Give the packed-word bit layout (all five fields + reserved). Why one 32-bit word instead
   of a struct?
4. Why must `render()` be allocation- and lock-free? What audible failure does a missed
   deadline cause?
5. What is the sample rate, how long is one sample in microseconds, and how many samples fall
   between two 50 Hz control updates?
6. Write the rpm→frequency formula and compute the fundamental at 9,000 rpm with 5
   firings/rev.
7. A phase accumulator is a `uint32_t` that overflows on purpose. Explain why the overflow is
   correct, and give the increment formula for frequency f.
8. Why is frequency carried in milli-Hz and the whine pitch in eighths? What does
   `whinePitchEighths = 24` mean as a ratio?
9. Why compute the sine table once at startup, and why is float allowed there but not in the
   render loop?
10. What is additive synthesis, and what do the six `partialAmp` numbers control? Why are they
    weighted toward harmonics 2–4?
11. The sine table is ±256 and the partial code shifts right by 8. What does that make each
    partial's `partialAmp` mean, in output units?
12. What is "zipper noise," and how does the one-pole smoother prevent it? State the two
    findings (#53) about that smoother.
13. Why is the noise generator *seeded*? What breaks if you seed it with 0, and how does the
    code handle that?
14. Describe how overrun crackle is produced sample-by-sample. Who decides *when* overrun is
    active?
15. What is the Nyquist limit here, what is aliasing, and what keeps the synth's harmonics
    legal? Where is that guard enforced?
16. How does the rev limiter make its sound? Where do the crank, idle-wobble, and shift-blip
    "sounds" actually come from?
17. Why does `rpm = 0` *not* silence the synth, and what does? Which batch must wire that, and
    from which `EngineState` field?
18. Explain headroom vs clamping. Which is the primary anti-clip mechanism, and what does the
    other one catch?
19. Why can audio be tested with exact-equality assertions here? Which test proves it, and
    which two paths does it deliberately turn on?
20. List two things the native tests prove, two they cannot, one thing that waits for S5, and
    one that waits for the real speaker.

## Answer key

1. S2 = the *model* (decides rpm/ignition/limiter/overrun from the effective VehicleState);
   S3 = the *renderer* (turns those numbers into int16 samples). The seam is `ISampleSource`.
2. Reach the synth: `engineRpm`, `limiterActive`, `overrunActive`, `ersWhine`. Don't:
   `throttlePercent`, `ignition`. No source in `EngineState`: **`volume`** (derived upstream,
   S5).
3. bits 0–15 engineRpm, 16–23 volume, 24 ersWhine, 25 limiterActive, 26 overrunActive, 27–31
   reserved. One aligned 32-bit word is read/written atomically (indivisibly), so the other
   core can't see a torn half-update; a multi-field struct could tear.
4. So a buffer is always ready before its ~11.6 ms deadline; `new`/locks can block for an
   unbounded time. A missed deadline = the speaker underruns → **pops/stutters**.
5. 22,050 Hz; one sample ≈ 45.4 µs; ~441 samples between 50 Hz updates (22050/50).
6. f = rpm/60 × firingsPerRev; 9,000/60 × 5 = **750 Hz**.
7. The `uint32_t` range 0…2³² maps to one cycle, so wrapping past 2³² returns to phase 0 —
   exactly "one cycle later." increment = f × 2³² / sampleRate.
8. Milli-Hz keeps fine pitch precision at low rpm (0.001 Hz steps instead of 1 Hz); eighths
   store a fractional ratio as an integer. 24 eighths = 24/8 = **3.0×** the firing frequency.
9. Calling `sin()` thousands of times/sample-set is too slow and float is banned in the render
   path; the table build runs *once* at startup (not per sample) and its result is rounded to
   integers, so the float there never touches real-time output or reproducibility.
10. Summing sine partials at f, 2f, 3f… to build a rich tone; the six amps set the **timbre**
    (relative harmonic loudness). Weighted toward 2–4 because the small speaker barely
    reproduces the fundamental, so energy goes where the speaker can make it.
11. table (±256) × amp ÷ 256 = ±amp, so each `partialAmp` is that partial's **peak
    contribution in int16 units** — directly budgetable against the clip rail.
12. Zipper = audible staircase/clicks when a parameter jumps on 50 Hz steps; the smoother
    moves 1/64 of the gap per sample so steps become ~3 ms glides. Findings: (a) the comment
    ("~1/1024, ~23 ms") is wrong — it's 1/64 ≈ 2.9 ms; (b) truncation parks upward approaches
    short — volume 255→192 (~75%), targets 1–63 from silence stay 0.
13. So the "random" noise is reproducible for tests. Seed 0 is a dead fixed point (xorshift of
    0 stays 0 → silent noise forever); the constructor maps a 0 seed to 1.
14. During `overrunActive`, each sample draws a random number; with 1-in-4 probability it sets
    that one sample's noise amplitude to 3× max — scattered loud spikes = crackle. **S2**
    decides when overrun is active (900 ms window after a hard high-rpm lift).
15. Nyquist = 11,025 Hz (half of 22,050); aliasing = frequencies above it fold back as false
    lower tones. Keeping only 6 partials and rpm ≤ 15,000 holds the top harmonic ~7.5 kHz.
    The guard is **upstream in S2** (rpm range) — the synth doesn't self-limit.
16. The limiter gates the whole output to zero at 18 Hz, 50% duty (accumulator top bit as a
    square wave). Crank = S2 sets rpm 1,800; idle wobble = S2's ±120 rpm modulation; shift
    blip = S2's transient ±1400 rpm offset — all are rpm changes the synth simply follows (no
    dedicated synth code).
17. At rpm 0 the oscillator increments are 0, phases freeze, and the frozen sine sum is a
    nonzero constant (DC) — not silence. `volume = 0` multiplies the mix to exactly 0. **S5**
    must wire it, mapping `ignition == Off` (which has no synth path) to volume 0.
18. Headroom = designing so the worst-case layer sum stays under the int16 rail (checked in
    `valid()`); clamping = saturating the final value to the rail. Headroom is primary; the
    clamp catches any hypothetical overflow (incl. the uncounted overrun burst) and turns a
    wrap into mild distortion.
19. Because the render path is integer and the noise is seeded → bit-exact reproducibility.
    `test_deterministic_given_seed` proves it, with **whine and overrun** turned on (the
    stateful paths, incl. the overrun extra-draw).
20. Proves (any two): pitch tracks rpm (~1%), volume 0 is exact silence, stereo channels
    identical, limiter gates, output in range, same-seed reproducibility, headroom holds.
    Cannot prove (any two): how it *sounds*, real-time timing on the chip, the cross-core
    atomic, cross-platform bit-exactness, proportional volume scaling. Waits for S5: the real
    atomic / volume origin / dead-man / task pinning / I2S / integration test / assert site.
    Waits for the speaker: engine believability on MAX98357A + 3 W (open q #32), the PCM
    fallback decision, GAIN strap, #53 audibility.

## Things to review before S4

- **`03_sound_synthesis.md` §0 and §6** — the S2→S3→S5 boundary and the exact `EngineState`→
  packed-word mapping. S4 won't use it, but it's the cleanest mental model of the pipeline
  and sets up S5.
- **The staleness/effective-state chain (S1) and the ignition FSM (S2)** — S4's lights read
  the same *effective* `VehicleState` (post-staleness) that S2 does; be fluent in
  `LinkStatus` (NeverConnected/Up/Lost) and per-field projection, because the lights key off
  `failsafe`, `braking`, `steeringPercent`, `lowBattery`, and ERS state directly.
- **Glossary terms added by S3** — phase accumulator, sine table/wavetable, additive
  synthesis, firing frequency, sample/sample rate, headroom, saturation, aliasing/Nyquist,
  xorshift32, zipper/parameter smoothing, packed parameter word, rev limiter, ERS whine.
- **open_questions #43 (answered), #52, #53** — know that the packed-word layout is settled,
  that some repo docs lag the code (per-rev AM doesn't exist; noise is rpm- not
  throttle-scaled), and that the smoother truncation makes full volume ~75%.
- **The cross-core rule (ch07 §6)** — one atomic param word + one heartbeat; synth phase is
  audio-task-only. S4's lights live on core 1 with the model, *not* on the audio core.

## "Ready for S4?" checklist

- [ ] I can state the model/renderer split and name the `ISampleSource` seam's purpose.
- [ ] I can list the synth's five inputs, the two `EngineState` fields excluded, and the one
      input (volume) that has no `EngineState` source.
- [ ] I can give the packed-word layout and say why one atomic word avoids torn reads.
- [ ] I can explain the sample rate, one sample's duration, and the 50 Hz vs 22,050 Hz split.
- [ ] I can derive a firing frequency from rpm and explain the milli-Hz and eighths
      fixed-point units.
- [ ] I can explain a phase accumulator, why its overflow is correct, and the increment
      formula.
- [ ] I can explain the wavetable (built once, float-at-init) and why 256 entries suffice.
- [ ] I can explain additive synthesis and what `partialAmp` + the ±256/>>8 trick control.
- [ ] I can explain zipper noise, the one-pole smoother, and the truncation finding (#53).
- [ ] I can explain the seeded xorshift32 noise, the overrun crackle lottery, and the ERS
      whine ramp.
- [ ] I can explain Nyquist/aliasing and say where the rpm guard actually lives (S2).
- [ ] I can explain the limiter gate and where crank/idle/shift sounds really come from (S2
      rpm).
- [ ] I understand why `volume = 0` — not `rpm = 0` — is the true silence, and that S5 wires
      it.
- [ ] I can explain headroom vs clamping and which is primary.
- [ ] I can explain why the audio is deterministically testable and what that test turns on.
- [ ] I can list what native tests prove, what they can't, and the S5 vs hardware boundaries.

If most boxes are checked, you're ready for S4 — the **lights** (`lib/lights` +
`lib/lights_hal_esp32`): a pure compositor from the effective `VehicleState` to 30 RGB
pixels, with gamma and a power budget. It shares S1's effective-state input and the house
patterns, but needs **no** audio/DSP from this batch. If several boxes aren't checked,
re-read the batch-doc sections named in each concept above — they're the shortest path back.

---

*Concept teaching notes for S3 complete. No source modified; written only in
`learning-manual/`. Awaiting approval before S4 ("Lights": `lib/lights` +
`lib/lights_hal_esp32`).*
