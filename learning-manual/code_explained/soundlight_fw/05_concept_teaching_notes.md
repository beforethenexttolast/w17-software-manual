# S5 — Concept Teaching Notes (Integration, Dual-Core, and the Real ESP32 Program)

A beginner companion to `05_soundlight_main_integration.md`. The batch doc explains
*what every line does*; this file explains *the ideas behind them* — one concept at a
time, each with the same seven-part shape:

1. **Plain-English** — what it is, no jargon.
2. **Why embedded needs it** — the pressure that makes it necessary.
3. **The S5 code** — the exact place it lives.
4. **How it connects to S1–S4** — the module story it completes.
5. **Beginner traps** — the misunderstanding to avoid.
6. **The bug it prevents** — what goes wrong without it.
7. **Hardware-only remainder** — what a native test can never confirm.

Read this *after* the S1–S4 concept notes (`01`–`03_concept_teaching_notes.md`). S5 is
where all four modules stop being separate pure-logic exercises and become **one running
program on two CPU cores** — so most of these concepts are about *composition, timing,
and concurrency*, not about any single module's math.

A one-paragraph orientation before the concepts: **`main.cpp` is a conductor, not a
musician.** It contains almost no logic of its own (only the 12-line `volumeFor` and the
5-line dead-man check). Its whole job is to *construct* the S1–S4 objects, *inject* their
pins, *schedule* their cadences, and *carry two numbers between the two CPU cores*.
Everything hard has already been proven in S1–S4; S5's risk is entirely in the *wiring*
and the *concurrency* — and, crucially, **`main.cpp` is never run by any automated test**
(the build excludes it), so its correctness rests on reading + compiling, plus the
integration test that exercises the *module chain* without the real `main.cpp`.

---

## Concept 1 — `main.cpp` as the integration point (the conductor)

**1. Plain-English.** One file constructs every module, wires them together, and decides
who runs when. It's the "assembly instructions" that turn a box of tested parts into a
working machine.

**2. Why embedded needs it.** The house style (both W17 repos) keeps every library
*pure*: no hardware, no global wiring, no scheduling — so each can be unit-tested on a
Mac. But *something* must eventually say "this pin, this clock, this order, this rate."
That something is `main.cpp`. Concentrating all the impure glue in one place is what
*lets* everything else stay testable.

**3. The S5 code.** `src/main.cpp`, 142 lines. Constructs six objects (§4.4), defines
`volumeFor` + `audioTask`, and provides `setup()`/`loop()`. That's the whole program.

**4. Connects to S1–S4.** It is *literally* S1's `Link2Monitor` + S2's `EngineSim` +
S3's `EngineSynth` + S4's `LightRenderer` and both HALs, plus two atomics. Every
"PROVISIONAL until S5" note in the earlier docs is a claim about *this* file.

**5. Beginner traps.** Thinking `main.cpp` "does" the sound or lights. It does neither —
it *arranges* the modules that do. If you want to know *how* rpm becomes a tone, that's
S3; `main.cpp` only decides *when* the rpm number is handed over.

**6. The bug it prevents.** Scattering pin numbers, clocks, and `new` calls throughout
the libraries — which would make them untestable and couple them to one board. The
conductor pattern keeps that rot out of the reusable code.

**7. Hardware-only remainder.** Because `main.cpp` is excluded from tests
(`test_build_src = no`), *nothing here is test-executed*. Its claims are
"VERIFIED (source + build)" — the code reads correctly and compiles for the ESP32 — but
whether the composed program behaves on real silicon is a bench question.

---

## Concept 2 — Startup order (static init → `setup()` → `loop()`)

**1. Plain-English.** An ESP32 Arduino program boots in three phases: first C++
constructs all the global objects, then it runs `setup()` once, then it calls `loop()`
forever.

**2. Why embedded needs it.** Hardware peripherals (UART, I2S, LED driver) must be
configured *before* use but *after* the chip's clocks/RAM are ready — and some setup
(like starting a second CPU task) must happen after the objects it uses exist. Order is
not cosmetic; it's correctness.

**3. The S5 code.** Global objects at file scope (§4.4) → `setup()` (§4.9:
`Serial.begin` → `Serial2.begin` → `i2s.begin()` → `strip.begin()` →
`xTaskCreatePinnedToCore(...)`) → `loop()` (§4.10).

**4. Connects to S1–S4.** The module *constructors* run during static init: the monitor
sets its boot-failsafe state (S1 §5), the sim seeds `rpm_ = idle` (S2 §2), the renderer
builds its gamma LUT (S4 §3.9), the synth builds its sine table (S3 §4.1). None of these
touch hardware — that's deferred to the HALs' `begin()`.

**5. Beginner traps.** Assuming globals are constructed "when `setup()` runs." They're
constructed *before* it — which is exactly why a constructor must never poke a peripheral
(the clocks may not be ready; this is the whole lesson of control finding A5).

**6. The bug it prevents.** Creating the audio task *before* `i2s.begin()` would let
core 0 call `i2s.write` on an uninstalled driver — a crash or silence race. Putting
`xTaskCreatePinnedToCore` **last** in `setup()` prevents it.

**7. Hardware-only remainder.** The *timing* of the boot phases (how many milliseconds
until the first `loop()`, how long the WS2812 "random color" window actually is) is a
bench observation; source only proves the *order*.

---

## Concept 3 — `setup()` vs `loop()`

**1. Plain-English.** `setup()` runs **once** (initialize the world). `loop()` runs
**forever** (do the repeating work). Arduino calls them for you.

**2. Why embedded needs it.** There's no operating system launching your `main()` with
args and exiting. The device is *always on*; the natural shape is "prepare, then repeat."

**3. The S5 code.** `setup()` opens the two UARTs, inits the two HALs, spawns the audio
task. `loop()` drains the UART, runs the 50 Hz control tick and the ~30 Hz light tick.
Note `setup()`/`loop()` live *outside* the anonymous namespace (lines 86+) — they must
have external linkage so the Arduino core can find them.

**4. Connects to S1–S4.** `loop()` is where S1's `feedByte`/`poll`, S2's `update`, S3's
`packParams`, and S4's `render` are actually *called*, at their real cadences.

**5. Beginner traps.** Putting slow one-time work in `loop()` (it repeats!) or
per-iteration work in `setup()` (it runs once!). Also: expecting `loop()` to be called at
a fixed rate — it isn't; it spins as fast as core 1 allows, and the *tick guards* inside
it enforce the rates.

**6. The bug it prevents.** Re-installing the I2S driver every pass (if `begin()` were in
`loop()`) — leaking driver handles until the chip dies. Keeping init in `setup()` avoids
it.

**7. Hardware-only remainder.** How fast `loop()` actually spins on a 240 MHz core (and
therefore how promptly a stale link is detected within its 20 ms poll) is bench-measured.

---

## Concept 4 — Global / static object lifetime

**1. Plain-English.** A variable declared at file scope, or `static` inside a function,
lives for the *entire* program: constructed once, destroyed never (the program never
exits). Ordinary local variables live only during their function call.

**2. Why embedded needs it.** The modules must *persist* between `loop()` passes (the
monitor's timestamp, the sim's rpm, the synth's phase). And RAM is scarce — you place big
persistent buffers deliberately, not on a shrinking stack.

**3. The S5 code.** Six file-scope module objects + two atomics + two tick timestamps
(§4.4, §4.2, §4.8). Inside `audioTask`, `static int16_t buf[512]` (§4.7). Inside the sim
hook, `static uint8_t simFrame[14]` (§4.10). The feeder's `lastFrameMs`/`lastPhase` are
function-local statics too (§5.2).

**4. Connects to S1–S4.** Every module *is* a long-lived object here; the internal state
each doc described (S1's `lastGood_`, S2's `wobblePhase_`, S3's `partialPhase_`, S4's
`lastErsPercent_`) survives across `loop()` passes precisely because the enclosing object
has static lifetime.

**5. Beginner traps.** Thinking `static` inside `audioTask` means "one per call." No —
**one for the whole program**, initialized on first reach, kept forever. That's what
makes it safe to reuse the buffer every iteration.

**6. The bug it prevents.** Declaring `int16_t buf[512]` as a *plain local* would put
1 KiB on the audio task's stack — a quarter of its 4096-byte allowance — risking a stack
overflow (silent memory corruption on most MCUs). `static` moves it to `.bss`.

**7. Hardware-only remainder.** Actual stack high-water marks and whether 4096 bytes is
truly enough are bench/telemetry facts; source only proves the buffer isn't *on* the
stack.

---

## Concept 5 — The FreeRTOS audio task

**1. Plain-English.** A "task" is like a thread: an independent stream of execution with
its own stack and priority, scheduled by the FreeRTOS operating system that the ESP32
always runs underneath Arduino. `audioTask` is a second stream of execution running
alongside `loop()`.

**2. Why embedded needs it.** Audio is *unforgiving*: a new 11.6 ms buffer must be ready
on time or the speaker pops. If audio shared `loop()` with UART parsing and LED writes, a
slow pass would starve it. A dedicated task, on its own core, isolates audio's timing.

**3. The S5 code.** `void audioTask(void*)` with an infinite `for(;;)` (§4.7), created by
`xTaskCreatePinnedToCore(audioTask, "audio", 4096, nullptr, 5, nullptr, 0)` (§4.9). The
signature (untyped `void*` context, never returns) is the FreeRTOS task contract.

**4. Connects to S1–S4.** This task is the *only* place S3's `EngineSynth::render` runs.
It reads the parameters that S2 (via `volumeFor`) produced, packed by the control loop.

**5. Beginner traps.** Thinking a task "returns" like a function. A FreeRTOS task that
returns crashes the scheduler — tasks are infinite loops or explicitly deleted. Also:
confusing "task" with "core"; a task is *scheduled* work, a core is *hardware* — pinning
ties one to the other (Concept 6).

**6. The bug it prevents.** Audio glitching every time the control loop does something
slow (parse a burst of UART, push 30 LEDs). Separation guarantees audio's cadence is
independent of everything else.

**7. Hardware-only remainder.** That `render()` actually *finishes* within the deadline
on the Xtensa core (S3's Mac harness ≠ ESP32 cycles) — bench (#57b).

---

## Concept 6 — Core 0 vs core 1 (task pinning)

**1. Plain-English.** The ESP32 has **two** CPU cores. You can *pin* a task to one so it
only ever runs there. Here: `loop()` on core 1, `audioTask` on core 0.

**2. Why embedded needs it.** Two cores = genuine parallelism: audio can render on core 0
*while* core 1 parses UART. Pinning makes the split deterministic (no migrating tasks, no
surprise contention) and keeps each core's job predictable.

**3. The S5 code.** `xTaskCreatePinnedToCore(..., 0)` — the final `0` is the core.
`loop()` runs in Arduino's `loopTask`, which the framework pins to core 1
(`CONFIG_ARDUINO_RUNNING_CORE=1`, checked in the installed framework source, §1/§4.9).

**4. Connects to S1–S4.** The "cross-core rule" (repo CLAUDE.md, ch07 §6): S1's monitor,
S2's sim, S4's lights live on core 1; S3's synth lives on core 0. The *only* thing that
crosses is the packed word + heartbeat (Concept 8).

**5. Beginner traps.** Assuming priorities compete across cores. They don't — a prio-5
task on core 0 never preempts a prio-1 task on core 1; priority only orders tasks
*within* a core. Also: assuming Wi-Fi/BT are running on core 0 (a common ESP32 default) —
this firmware compiles neither, so the audio task effectively owns core 0.

**6. The bug it prevents.** Audio and control fighting for one core's time (jitter,
underruns). Pinning gives audio a whole core.

**7. Hardware-only remainder.** Whether core-0 audio *actually* stays glitch-free while
core-1 bit-bangs the WS2812 strip (`strip.show()`) — a documented bench risk
(SIMULATION.md; §11.5 rank 3).

---

## Concept 7 — Audio task scheduling & blocking I2S write as the clock

**1. Plain-English.** The audio task never sets a timer. It renders a block, hands it to
the I2S hardware, and the *handoff itself blocks* until the hardware has room — which only
happens as fast as the speaker consumes samples. So the loop runs at exactly real-time
audio speed, for free.

**2. Why embedded needs it.** Precisely pacing 22,050 samples/second with a software
timer is fiddly and drifts. Letting the *hardware's consumption rate* pace the producer
("backpressure") is self-correcting and exact.

**3. The S5 code.** In `audioTask`: `synth.render(buf, 256); i2s.write(buf, 256);`.
`Esp32I2sAudio::write` calls `i2s_write(..., portMAX_DELAY)` — block forever until the
1,024 bytes are queued into the DMA ring (§3.3, §4.7). The ring is 6 × 256 frames ≈
70 ms (§3.1).

**4. Connects to S1–S4.** This is the deadline S3 kept referencing ("~11.6 ms budget"):
256 frames / 22,050 Hz = 11.61 ms. The synth must render that fast; the *write* then
paces the next round.

**5. Beginner traps.** Thinking you need a `delay(11)` or a hardware timer interrupt to
pace audio. The blocking write *is* the pacing — adding a delay would cause underruns.
Also: thinking "blocking = bad." Here blocking is the *feature*; while blocked, the task
sleeps and lets core 0's IDLE task run (which the watchdog needs — Concept 20).

**6. The bug it prevents.** Producing samples faster than the speaker drains (buffer
overflow / dropped audio) or slower (underrun / pops). Backpressure keeps producer and
consumer in lockstep automatically.

**7. Hardware-only remainder.** That the DMA ring's *unit* is frames (not per-channel
samples) — so "~70 ms" is right — and that `render` keeps up with the drain on real
hardware. Both bench (#57c, #57b). The ≈100 ms worst-case param→speaker latency is
INFERRED arithmetic, bench-confirmable.

---

## Concept 8 — Cross-core communication (the shared surface)

**1. Plain-English.** Two cores can't just pass a struct around safely — one might read
while the other writes and see a half-updated mess. So this design shares the *absolute
minimum*: two 32-bit numbers, each read/written atomically.

**2. Why embedded needs it.** Shared mutable state between parallel executors is the
classic source of heisenbugs. Minimizing and disciplining the shared surface is how you
make concurrency *reason-about-able*.

**3. The S5 code.** `std::atomic<uint32_t> gSynthParams{0};` and
`std::atomic<uint32_t> gControlHeartbeatMs{0};` (§4.2). The audit table in §4.11 lists
*every* item both cores can touch and why each is safe.

**4. Connects to S1–S4.** S3 designed its parameters to fit one 32-bit word for exactly
this reason (ch07 §6). S5 is where that design pays off: the whole S2→S3 handoff is one
atomic store + one atomic load.

**5. Beginner traps.** Thinking "I'll just share the `EngineState` struct between cores."
That struct is multiple words — a reader could see a new rpm with an old flag (a *torn*
read). The single-word rule exists to make that impossible.

**6. The bug it prevents.** Torn reads: the audio core rendering with half-updated
parameters (e.g. new rpm, stale volume) — an audible glitch that would be nearly
impossible to reproduce or debug.

**7. Hardware-only remainder.** True concurrent contention is never exercised by the
single-threaded native tests; the correctness argument (§4.11) is *reasoning*, not a test.
Bench is where two cores actually hammer the words.

---

## Concept 9 — Atomics and `memory_order_relaxed`

**1. Plain-English.** An "atomic" variable is read/written in one indivisible step — no
half-values. `memory_order_relaxed` is the weakest (cheapest) atomic: it guarantees *that
one variable* is never torn, but makes **no promise about ordering relative to other
variables**.

**2. Why embedded needs it.** Atomicity is mandatory across cores (Concept 8). But full
ordering guarantees (acquire/release) cost more; if you don't *need* cross-variable
ordering, relaxed is correct and free.

**3. The S5 code.** Both stores (`gSynthParams.store(..., std::memory_order_relaxed)`,
`gControlHeartbeatMs.store(..., std::memory_order_relaxed)`) and both loads use relaxed
(§4.10, §4.7). The justification is §4.11: *no invariant spans the two atomics*.

**4. Connects to S1–S4.** This is C7's ISR-atomics lesson (chapter 04 §12) promoted from
"ISR vs loop on one core" to "core vs core." Same argument: the pair may be observed
slightly out of sync, and that's fine because nothing depends on their joint state.

**5. Beginner traps.** Thinking relaxed means "unsafe" or "might tear." It never tears a
*single* aligned word — atomicity is guaranteed. What relaxed drops is only *cross-
variable ordering*, which this design deliberately never relies on.

**6. The bug it prevents.** Using relaxed *where you DO need ordering* is the real
danger — e.g. "flag says the data is ready" needs release/acquire. This design avoids
creating any such dependency, so relaxed is genuinely correct here.

**7. Hardware-only remainder.** Memory-ordering behavior is architecture-specific; the
argument is sound for the Xtensa dual-core model but is untested (no native test runs two
threads).

---

## Concept 10 — The one-word packed-parameter rule (and open question #43)

**1. Plain-English.** All the synth's changing inputs — rpm, volume, and three on/off
flags — are squeezed into the bits of a *single* 32-bit number, so the whole set crosses
cores in one atomic move.

**2. Why embedded needs it.** One atomic word can be transferred torn-free with a plain
load/store (no locks — and locks next to real-time audio are dangerous). A *struct* of
several fields cannot. Packing is what *makes* the lock-free handoff possible.

**3. The S5 code.** `soundsynth::packParams(engineRpm, volumeFor(e), ersWhine,
limiterActive, overrunActive)` stored into `gSynthParams` each control tick (§4.10);
`synth.applyPackedParams(...)` on the audio side (§4.7). Layout (S3 §3.2,
`EngineSynth.hpp`): bits 0–15 rpm, 16–23 volume, 24 ersWhine, 25 limiter, 26 overrun,
27–31 reserved.

**4. Connects to S1–S4. This is the concept that closes open question #43.** S3 answered
the *layout* (which bits mean what). S5 answers the *rest*: **who packs it** (the 50 Hz
control tick in `loop()`) and **where volume comes from** (`volumeFor`, Concept 11).
Every `EngineState` field now has a home: rpm + 3 flags in the word; ignition + throttle
folded into the volume byte *before* the word.

**5. Beginner traps.** Assuming all six `EngineState` fields cross the cores. Only four go
into the word directly; `ignition` and `throttlePercent` are consumed by `volumeFor` on
core 1 and never cross raw. "Absent from the word" ≠ "dropped" — they're *pre-digested
into volume*.

**6. The bug it prevents.** A multi-field struct handoff that could be torn (Concept 8) —
or a lock, which could deadlock or add jitter to audio. One word sidesteps both.

**7. Hardware-only remainder.** That the pack/unpack is bit-identical on Xtensa as on the
Mac (overwhelmingly likely; formally bench). The *layout* was natively test-verified in
S3's roundtrip test; the *packing site* is source-only (main.cpp excluded).

---

## Concept 11 — `volumeFor()` — derived control at the composition layer

**1. Plain-English.** The synth needs a "volume" number, but no module produces one.
`main.cpp` computes it from the engine's state with a tiny 3-line rule: silent when off,
quiet while cranking, louder with throttle.

**2. Why embedded needs it.** Some values belong to *neither* the producer nor the
consumer — they're policy about how the two meet. Putting `volumeFor` in `main.cpp` (not
in EngineSim or EngineSynth) keeps both modules general and reusable.

**3. The S5 code (§4.6):**
```cpp
uint8_t volumeFor(const enginesim::EngineState& e) {
    if (e.ignition == enginesim::Ignition::Off) return 0;
    if (e.ignition == enginesim::Ignition::Cranking) return 70;
    return static_cast<uint8_t>(90 + e.throttlePercent * 165 / 100); // 90..255
}
```

**4. Connects to S1–S4.** It consumes exactly the two `EngineState` fields S3 said were
"notably absent" from the packed word (`ignition`, `throttlePercent`). It is the missing
half of #43. It also *interacts with* S3's smoother quirk (#53): because volume is a
continuum (90…255), every upward move parks 63 short → full = 75 %, crank whir ≈ 2.7 %.

**5. Beginner traps.** Thinking volume must live in a module. Glue policy that references
two modules belongs in the layer that *knows both* — the conductor. Also: assuming the
integration test's `volumeFor` matches main's — it doesn't (different constants, finding
#56a); only the endpoints (0 and 255) coincide.

**6. The bug it prevents.** Baking a volume policy into EngineSim would couple it to
"there is a synth downstream" and prevent reusing it elsewhere. Composition-layer glue
keeps the modules decoupled.

**7. Hardware-only remainder.** Whether these specific numbers *sound* balanced on the
speaker (idle at level 27–90, crank at ≈7) is voicing — bench (#32, #57e).

---

## Concept 12 — The silence path: why silence is `volume = 0`, not `rpm = 0`

**1. Plain-English.** To make the engine go quiet, you set **volume** to zero. Setting
**rpm** to zero does *not* silence it — the synth's oscillators keep holding a steady
(possibly non-zero) output.

**2. Why embedded needs it.** Safety-critical "off" must be *unambiguous* and *simple*.
"Volume 0 = silence" is a single, always-true rule. "rpm 0 = silence" is *false* in this
synth, so relying on it would be a latent bug.

**3. The S5 code.** `volumeFor` returns **0** for `Ignition::Off` (§4.6). The dead-man
forces `setParams(0, 0, ...)` — again *volume* 0 (§4.7). Both silence paths key on
volume.

**4. Connects to S1–S4.** S3 established this precisely (concept 17): a phase accumulator
frozen at rpm 0 still outputs its current sample value (a DC hold), and only the master
`volume` multiply of 0 zeroes the output. S2's `Ignition::Off` therefore *cannot* silence
by itself — it must be *translated* to volume 0 by `volumeFor`. S5 is where that
translation lives.

**5. Beginner traps.** "The engine is off, so rpm is 0, so it's silent." Wrong twice:
(a) rpm 0 doesn't silence this synth; (b) the internal `rpm_` may not even be 0 (S2 keeps
it decaying while reporting engineRpm 0). Silence is *only* volume 0.

**6. The bug it prevents.** A disarm/failsafe that drops rpm to 0 but leaves volume up —
a steady DC tone or held partial from the speaker during what should be silence. Routing
"off" through volume 0 prevents it.

**7. Hardware-only remainder.** That volume 0 produces *true* speaker silence (not a
faint idle hiss from the amp) — bench. The native integration test *does* pin
`blockPeak == 0` exactly, so the digital silence is proven; the acoustic silence is not.

---

## Concept 13 — Dead-man / stale-link behavior

**1. Plain-English.** A "dead-man switch" cuts power if the operator stops responding.
Here: if the control loop stops refreshing the audio parameters (e.g. it wedged), the
audio task mutes itself after ~500 ms.

**2. Why embedded needs it.** The audio task runs independently on core 0. If core 1
froze mid-scream, nothing else would stop the noise. The dead-man is audio's *last*
line of defense, owned entirely by the audio side.

**3. The S5 code (§4.7):**
```cpp
const uint32_t now = millis();
const uint32_t hb = gControlHeartbeatMs.load(std::memory_order_relaxed);
if (now - hb > kAudioDeadmanMs) {          // 500 ms, strict >
    synth.setParams(0, 0, false, false, false);
} else {
    synth.applyPackedParams(gSynthParams.load(std::memory_order_relaxed));
}
```
The control tick stamps `gControlHeartbeatMs.store(nowMs, ...)` each 50 Hz pass (§4.10).

**4. Connects to S1–S4.** It's the **third** speaker-silencing layer: (1) S1's link
staleness (500 ms) → (2) S2's ignition-off on `armed=false` → (3) this dead-man (500 ms).
Each catches a *different* failure: wire cut / commanded silence / **wedged control
loop**. The dead-man is the only one that survives core 1 dying.

**5. Beginner traps.** Confusing the dead-man with the link-staleness monitor. The
monitor watches *board #1's frames* (core 1); the dead-man watches *core 1 itself* (from
core 0). They use the same 500 ms magnitude but guard different things. Also: the "ramp
to 0" in the docs is not a separate ramp — it's the synth's own ~3 ms smoother turning
the volume-0 step into a fade (#56d).

**6. The bug it prevents.** A hung control loop leaving the last-published (possibly
full-throttle) parameters screaming from the speaker forever. The dead-man forces silence
regardless of what the packed word last held.

**7. Hardware-only remainder. This is the single most safety-relevant untested path in
the repo.** `main.cpp` is excluded from tests, so the dead-man branch has *never
executed anywhere*. A bench check (wedge the loop, expect silence within ~0.6 s) is
priority #57a.

---

## Concept 14 — `LinkStatus`: NeverConnected / Up / Lost

**1. Plain-English.** Three states, not two: the link has *never* worked
(NeverConnected), is *working* (Up), or *was working and stopped* (Lost). "Never spoke"
and "stopped speaking" are genuinely different situations.

**2. Why embedded needs it.** A boolean "connected?" can't tell power-on (board #1 still
booting — normal) from a mid-drive wire cut (an emergency). The lights react differently,
so the distinction must be first-class.

**3. The S5 code.** `main.cpp` passes `monitor.status()` to the light renderer every
frame (§4.10). The state itself is S1's (`Link2Monitor`), computed from timestamps.

**4. Connects to S1–S4.** S1 built the three-state enum; S4 renders it three ways —
**breathe** (NeverConnected, a calm teal — finding #54a), **normal** (Up), **hazard**
(Lost). S5 wires `status()` into the render call so those three renderings actually
happen.

**5. Beginner traps.** Thinking NeverConnected shows the hazard (the *pre-code* manual
inference — corrected by S4). Power-on is *calm*, not an alarm; only Lost/failsafe is
amber. Also: thinking a NeverConnected board "ages into" Lost after 500 ms — it doesn't;
never-connected stays never-connected until the first valid frame (S1's `everReceived_`
gate).

**6. The bug it prevents.** Crying wolf at every power-on (hazard blinking for the second
or two before board #1 boots), which would train the user to ignore the hazard — the
signal that matters when the wire *actually* cuts.

**7. Hardware-only remainder.** Whether the teal breathe is *visible* at its computed
dim level (peak {1,3,3} PWM) in daylight — bench (#55).

---

## Concept 15 — Pre-first-frame boot behavior

**1. Plain-English.** From power-on until board #1's first valid frame, the board must be
*silent and calm* — no accidental noise or hazard flash. And it must be silent *by
default*, not by racing to some init step.

**2. Why embedded needs it.** Boot is when state is least defined (peripherals warming,
no data yet). Encoding safety in the *initial values* makes it impossible for boot timing
to produce a bad output.

**3. The S5 code.** The atomics init to `{0}` (word 0 = rpm 0, volume 0 = silence);
`i2s_zero_dma_buffer` queues silence; `strip.begin()` blanks the LEDs; the monitor
constructs in failsafe. The §4.12 timeline walks every step.

**4. Connects to S1–S4.** S1's monitor boots NeverConnected + failsafe effective state;
S2's sim boots Off (engineRpm 0); S3's synth boots with target volume 0; S4's renderer
shows breathe for NeverConnected. S5 confirms *nothing in the boot path* overrides these.

**5. Beginner traps.** Thinking silence requires the first control tick to *run* in time.
No — even before any tick, the packed word is 0 (silence) and the DMA is zeroed. Boot
safety is structural, not timing-dependent.

**6. The bug it prevents.** A power-on "pop" or a hazard flash or a random LED show before
board #1 connects — an ugly, alarming, or confusing startup. Safe-by-initial-value
prevents all three.

**7. Hardware-only remainder.** The *audible/visible* boot (any amp turn-on pop, the
WS2812 random-color window's real length) is bench; source proves the *logic* is silent.

---

## Concept 16 — S1's VehicleState projection (the effective state)

**1. Plain-English.** The monitor doesn't hand consumers the raw last frame. When the
link is stale, it hands a *sanitized* version: commands zeroed, failsafe forced true, rpm
zeroed, but slow facts (battery, gear) held. One place cleans stale data for everyone.

**2. Why embedded needs it.** If every consumer had to check "is this stale?" itself,
they'd diverge and some would forget. Centralizing the projection means the sim and the
lights *cannot* act on a stale command — the sanitization already happened.

**3. The S5 code.** `engine.update(nowMs, monitor.state())` and
`lightRenderer.render(monitor.state(), monitor.status(), ...)` — **both** consume
`state()`, the *effective* (projected) state, never a raw frame (§4.10).

**4. Connects to S1–S4.** This is S1's core design. S5 proves both consumers actually use
it, and use the *same* one (the handoff's "confirm main feeds the same effective state to
both" — confirmed).

**5. Beginner traps.** Thinking the sim or lights re-check staleness. They don't — they
trust `state()`. The monitor is the *single* staleness authority; downstream just performs.

**6. The bug it prevents.** The engine roaring on a 500 ms-old throttle value, or the
lights showing a stale "armed" — because a consumer forgot to check freshness. Central
projection makes forgetting impossible.

**7. Hardware-only remainder.** The projection is fully native-tested (S1's suite +
S5's integration test); the only bench part is the physical link that *triggers* staleness
(the wire).

---

## Concept 17 — S2 feeding S3 (EngineSim → EngineSynth)

**1. Plain-English.** The virtual engine (S2) produces *numbers* (rpm, flags). The synth
(S3) turns numbers into *sound*. S5 is the pipe between them.

**2. Why embedded needs it.** Separating "model the engine" from "make the sound" lets
each be tested alone and lets the synth be swapped (e.g. for a PCM player) without
touching the engine model. The pipe is thin on purpose.

**3. The S5 code.** Per control tick (§4.10): `engine.update(...)` → read
`engine.engine()` → `packParams(e.engineRpm, volumeFor(e), e.ersWhine, e.limiterActive,
e.overrunActive)` → store to the atomic. The audio task unpacks and renders.

**4. Connects to S1–S4.** S2 defined `EngineState`; S3 defined the five synth inputs +
the packed word; S5 is the *conversion* (including `volumeFor` bridging the field
mismatch). The chain frames→sim→synth is natively exercised by the integration test.

**5. Beginner traps.** Expecting S3 to read S2's `EngineState` struct directly. It
doesn't — the data is *repackaged* into the atomic word (and cranks the cores). The synth
never sees `EngineState`.

**6. The bug it prevents.** Tight coupling where the synth reaches into engine internals —
which would break the "swap in a PCM player" seam and the clean core split.

**7. Hardware-only remainder.** Whether the resulting sound *is* an engine on the speaker
(#32) — the whole chain is math until it hits the amp.

---

## Concept 18 — S1 feeding S4 (VehicleState → LightRenderer)

**1. Plain-English.** The lights read the *same* effective vehicle state as the engine,
plus the link status — and render brake/indicators/halo/rain/hazard from it.

**2. Why embedded needs it.** Sound and light are *parallel* consumers of one truth, not a
chain. Feeding both from the same `state()` guarantees they agree (you never get a silent
engine with driving lights).

**3. The S5 code.** The ~30 Hz light tick: `lightRenderer.render(monitor.state(),
monitor.status(), nowMs, px)` → 30 × `strip.setPixel` → `strip.show()` (§4.10).

**4. Connects to S1–S4.** S4's renderer reads exactly seven `VehicleState` fields and the
`LinkStatus`; S5 supplies both from the monitor, at a cadence S4 had only *guessed*
(S4 said "50 Hz?"; S5 shows **~30 Hz**).

**5. Beginner traps.** Thinking lights and sound share a pipeline (sound → light). They're
*siblings*, both fed from the monitor. The lights never read `EngineState` or anything
audio.

**6. The bug it prevents.** Desync between what you hear and what you see (e.g. hazard
lights but engine still roaring) — impossible when both read one projected state.

**7. Hardware-only remainder.** The LEDs actually lighting (WS2812 electrical, the dim-
layer visibility #55) — bench; the render *logic* is native-tested.

---

## Concept 19 — Render cadence & `millis()` / `nowMs`

**1. Plain-English.** Different jobs run at different rates: control at 50 Hz (every
20 ms), lights at ~30 Hz (every 33 ms), audio as fast as the speaker drains. A "tick
guard" checks the clock and only runs a job when its interval has elapsed. The clock is
`millis()`.

**2. Why embedded needs it.** You don't want to parse UART or repaint LEDs millions of
times a second; you want *rate-limited* work driven by wall-clock time, decoupled from how
fast `loop()` happens to spin.

**3. The S5 code.** `if (nowMs - lastControlMs >= kControlPeriodMs) { lastControlMs =
nowMs; ... }` and the ~30 Hz twin (§4.10). One `const uint32_t nowMs = millis();` per
pass feeds everything — the single clock read.

**4. Connects to S1–S4.** `millis()` is the `nowMs` seam that S1's monitor, S2's sim, and
S4's renderer *all* left "PROVISIONAL until S5." S5 resolves it: the caller-is-the-clock
design terminates in this one `millis()` call. It's monotonic-until-wrap (49.7 days),
exactly what the modules' unsigned-subtraction idioms assumed.

**5. Beginner traps.** Thinking `loop()` runs at a fixed rate (it doesn't — the guards do
the rating). Also: using `last += period` (which fires make-up ticks after a stall)
instead of `last = now` (which drops lost time) — this code uses the drop-lost-time
variant (C10's tick-guard glossary term).

**6. The bug it prevents.** Two bugs: (a) burning CPU running jobs every spin; (b) time
wraparound bugs — solved by unsigned subtraction, which is *why* one consistent `millis()`
seam matters.

**7. Hardware-only remainder.** The actual spin rate of `loop()` and therefore the jitter
around the 20/33 ms intervals — bench.

---

## Concept 20 — The task watchdog (why a never-blocking `loop()` is safe)

**1. Plain-English.** A "watchdog" resets the chip if a watched task stops making
progress. Here it watches only *core 0's* idle task — so core 1's `loop()` may spin
forever, but the *audio* task on core 0 must block (yield) regularly or the chip resets.

**2. Why embedded needs it.** A watchdog catches truly-hung firmware and reboots it. But
it must be told *what* to watch; watching the wrong thing either misses hangs or
false-triggers.

**3. The S5 code.** No explicit code — it's a framework `sdkconfig` fact
(`CONFIG_ESP_TASK_WDT_CHECK_IDLE_TASK_CPU0=y`, `..._CPU1` not set; §1). The audio task
satisfies it by *blocking in `i2s.write`*, which lets core 0's IDLE task run.

**4. Connects to S1–S4.** It's why Concept 7's blocking write is not just elegant pacing
but *required*: the block feeds IDLE0, keeping the watchdog fed.

**5. Beginner traps.** Assuming a busy `loop()` will trip the watchdog. On this config it
won't — core 1's idle task isn't watched (standard Arduino arrangement). The danger is a
core-0 task that *never blocks*.

**6. The bug it prevents.** A wedged audio task starving core 0's IDLE task → watchdog
reset (or, if misconfigured, a silent hang). The blocking-write design avoids it.

**7. Hardware-only remainder.** Watchdog behavior only manifests on hardware; native
tests have no watchdog.

---

## Concept 21 — Light HAL `begin()` / `show()`

**1. Plain-English.** `strip.begin()` initializes the LED driver and blanks the strip
(WS2812s power up to random colors). `strip.show()` pushes the 30 pixel values out the
one data wire.

**2. Why embedded needs it.** LEDs must be explicitly cleared at boot (random-on is ugly),
and updates are *buffered then latched* — you set all 30 pixels, then `show()` transmits
them in one ~0.9 ms burst.

**3. The S5 code.** `strip.begin()` in `setup()` (§4.9); in the light tick, 30 ×
`strip.setPixel(i, r, g, b)` then `strip.show()` (§4.10). The HAL is S4's
`Esp32NeoPixelStrip` (Adafruit NeoPixel wrapper).

**4. Connects to S1–S4.** S4 explained `begin()` as boot-blank and `show()` as the wire
transfer; S4 left "is begin() called early in setup()?" PROVISIONAL. S5 answers: yes,
right after `i2s.begin()`.

**5. Beginner traps.** Forgetting that `setPixel` only writes a *buffer* — nothing appears
until `show()`. Also: expecting per-LED wiring; it's one serial data line (Concept
covered in S4).

**6. The bug it prevents.** A boot-time random LED show (no `begin()` blank) or updates
that never appear (no `show()`).

**7. Hardware-only remainder.** The actual WS2812 timing, the boot-blank window's visible
length, and whether `show()` glitches while audio DMA runs — all bench (§11.5 rank 3).

---

## Concept 22 — Audio HAL `begin()` / `write()` and the I2S/DMA boundary

**1. Plain-English.** `i2s.begin()` installs the audio driver, routes the three pins, and
zeroes the DMA buffers (boot-silence). `i2s.write()` hands stereo samples to the DMA
hardware and blocks until there's room.

**2. Why embedded needs it.** I2S + DMA is how you stream audio without the CPU babysitting
every sample — the peripheral clocks bits out, DMA feeds it from a ring. The HAL hides the
driver's many config knobs behind two methods.

**3. The S5 code.** `Esp32I2sAudio::begin()` fills `i2s_config_t` (MASTER|TX, 16-bit,
stereo, 6×256 DMA ring), installs, routes pins 26/25/22, zeroes the ring (§3.2).
`write()` = `i2s_write(..., portMAX_DELAY)` (§3.3).

**4. Connects to S1–S4.** This is the hardware end of S3's audio: the synth renders mono,
duplicates to stereo (so the amp's SD_MODE strap doesn't matter), and this HAL streams it.
S3's "~11.6 ms deadline" is the 256-frame block this write consumes.

**5. Beginner traps.** Thinking `write` copies to the *speaker*. It copies to a *DMA ring*
in RAM; the hardware drains the ring to the amp on its own schedule. Also: `tx_desc_auto_
clear = true` means an underrun plays *silence*, not a repeat — fail-quiet.

**6. The bug it prevents.** Boot noise (unzeroed DMA garbage) and, via
`tx_desc_auto_clear`, a stuck-repeating buffer on underrun. Also the blocking write
prevents overrunning the ring.

**7. Hardware-only remainder. Almost everything here is bench**: the legacy driver's
semantics on the pinned platform, the amp locking to the I2S frame, the DMA unit
(frames vs samples — the "~70 ms" claim), underrun behavior, and any turn-on pop. This is
the repo's #1 bring-up risk (§11.5).

---

## Concept 23 — GPIO / pin mapping (injection)

**1. Plain-English.** Every peripheral needs to know which physical pins to use. The pin
*numbers* live in one file (`PinMap.hpp`); `main.cpp` *injects* them into each HAL's
constructor. Nothing hardcodes a pin deep in a library.

**2. Why embedded needs it.** Pins are board-specific. Centralizing them (and injecting
rather than hardcoding) keeps the libraries board-agnostic and makes a re-pin a one-file
edit.

**3. The S5 code (§4.4, §4.9).** `i2s(pinmap::kI2sBclkPin, kI2sLrclkPin, kI2sDataPin,
...)`, `strip(pinmap::kLedStripPin, ...)`, `Serial2.begin(115200, SERIAL_8N1,
pinmap::kLink2UartRxPin, -1)`. RX = GPIO16; TX = −1 (GPIO17 reserved, never opened).

**4. Connects to S1–S4.** S1 walked the PinMap (RX16, I2S 26/25/22, LED4, TX17-reserved);
S4 noted GPIO4 injection PROVISIONAL. S5 shows every constant landing where the comments
promised.

**5. Beginner traps.** Thinking board #2's GPIO25 (I2S LRCLK) conflicts with board #1's
GPIO25 (link2 TX). They're *different chips* — pin numbers are per-chip; only a *wire*
between two pins links boards. Also: TX = −1 is not a bug, it's "don't route a TX pin"
(the reserved ack channel stays closed).

**6. The bug it prevents.** Pin conflicts and un-relocatable hardcoded pins; also driving
the reserved GPIO17 into board #1's GPIO26 (avoided by never opening it).

**7. Hardware-only remainder.** That the chosen pins are electrically fine (no strapping
surprise, the WS2812 level-shift, the UART wire) — bench.

---

## Concept 24 — PlatformIO environments & the platform pin

**1. Plain-English.** One config file defines several *build environments*: `esp32dev`
(real firmware), `esp32dev_sim` (adds the demo feeder), `native` (host tests). Each is a
toolchain + flags recipe. The platform version is *pinned* on purpose.

**2. Why embedded needs it.** You build the same source for different targets (real chip,
demo, host test). And you pin the platform because the audio HAL depends on a *specific*
driver API (`driver/i2s.h`) that a newer platform would remove.

**3. The S5 code.** `platformio.ini` (§7): `[env:esp32dev]` pins
`platform = espressif32 @ ~7.0.1` (= Arduino core 2.0.17 / IDF 4.4, the legacy-I2S world);
`[env:esp32dev_sim]` adds `-DW17_SIM_LINK2_FEEDER`; `[env:native]` sets
`test_build_src = no` + `lib_ignore` of the two HALs.

**4. Connects to S1–S4.** `test_build_src = no` is *why* every `main.cpp` claim across
S1–S5 is "source + build," never "ran." `lib_ignore` (+ the HALs' `platforms: espressif32`
metadata) is why the pure modules test on the Mac while the HALs never compile there.

**5. Beginner traps.** Thinking `extends` *adds* build flags. It *replaces* them — the
sim env must re-interpolate `${env:esp32dev.build_flags}` before adding its define (the
same gotcha control documents). Also: thinking the platform pin is fussiness — it's
load-bearing (see the bug below).

**6. The bug it prevents.** A future `pio` update pulling espressif32 8.x / Arduino 3.x
(IDF 5), which *deletes* the legacy I2S API — silently breaking `Esp32I2sAudio.cpp`. The
`~7.0.1` pin turns that into a deliberate migration, not a surprise.

**7. Hardware-only remainder.** The build *proves compilation*, not that the compiled
binary runs. And the floating NeoPixel dep (`^1.12.0`, resolved 1.15.5) means a future
checkout may compile a different LED lib (#56e) — a reproducibility nuance.

---

## Concept 25 — What each verification level actually proves

**1. Plain-English.** Three tiers of confidence: **native tests** (logic runs on the Mac),
**source + build** (code reads correctly and compiles for the ESP32), **hardware**
(it actually works on the chip). S5 lives mostly in the middle tier.

**2. Why embedded needs it.** Honesty about confidence prevents over-trust. "40/40 green"
is *not* "the firmware works" — it's "the pure logic works on a host." Knowing the gap is
how you plan a bench session.

**3. The S5 code / evidence.** Native (VERIFIED-ran): the module chain via
`test_integration` (frames→Lost→exact-zero audio + hazard; 400-tick no-clip). Source+build
(VERIFIED): `main.cpp`'s wiring, the dead-man branch, `volumeFor`, the atomics, the HAL
config — *compiled* (both ESP32 envs SUCCESS) but *never executed by a test*. Hardware
(PROVISIONAL): everything electrical/acoustic/visual/real-time.

**4. Connects to S1–S4.** Every batch drew this line; S5 makes it sharpest because
`main.cpp` is the biggest source-only file and holds the safety-critical dead-man.

**5. Beginner traps.** Reading "40/40 passed" as "the soundlight firmware works." It means
the *pure logic* of six modules works on a Mac, plus their composition in *one thread*.
The dual-core reality, the HALs, and the hardware are all outside that number.

**6. The bug it prevents.** Shipping with false confidence — e.g. assuming the dead-man
works because tests pass, when *no test ever runs it* (Concept 13). Naming the tiers
forces the bench check onto the plan.

**7. Hardware-only remainder — the whole point of this concept.** The bench list (#57 +
§11.5): dead-man execution, render CPU cost, I2S/DMA behavior, WS2812-vs-audio coexistence,
crank/dim-layer perceptibility, engine-ness of the sound, the physical UART wire.

---

## 25 Quiz Questions

1. In one sentence, what is `main.cpp`'s job, and what is it *not*?
2. List the three boot phases in order and say which one constructs `Link2Monitor`.
3. Why must `xTaskCreatePinnedToCore` be the *last* statement in `setup()`?
4. `static int16_t buf[512]` inside `audioTask` — why `static`, and what breaks if it
   were a plain local?
5. Which core runs `loop()`, which runs `audioTask`, and how do you know the first one
   from the framework?
6. Explain "the blocking I2S write is the audio clock." What paces the pump if not a
   timer?
7. Name the *only* two things shared between the cores. Why exactly two, and why not a
   struct?
8. What does `memory_order_relaxed` guarantee, and what does it *not*? Why is "not" okay
   here?
9. State the packed-word bit layout (all six regions). Which two `EngineState` fields are
   *not* in it, and where do they go instead?
10. Write `volumeFor`'s three cases from memory. What value silences the engine?
11. Why does setting rpm = 0 *not* silence the synth? What does?
12. Trace the full chain that makes a cut wire produce speaker silence — name every
    module and threshold.
13. What is the dead-man, which core owns it, and what does it watch (be precise: not the
    link)?
14. Distinguish NeverConnected from Lost. What does each show on the lights?
15. Give four independent reasons the board is silent at boot before the first frame.
    Which one alone would suffice?
16. What is the "effective state," and why do *both* the sim and the lights consume it
    instead of raw frames?
17. At what cadence do the control tick, the light tick, and the audio pump run? Which
    one did S4 guess wrong?
18. Why is `millis()` read exactly *once* per `loop()` pass?
19. What does `test_build_src = no` mean, and what class of claim does it force `main.cpp`
    into?
20. Why is the platform pinned `~7.0.1` specifically? What breaks if it floats to 8.x?
21. `Serial2.begin(..., RX=16, TX=-1)` — what does the `-1` mean and why does GPIO17 stay
    closed?
22. What does `i2s_zero_dma_buffer` prevent? Name its LED and PWM cousins in this project.
23. Does "40/40 native tests pass" prove the dead-man works? Explain.
24. Two boards both use GPIO25. Is that a conflict? Why or why not?
25. Which single bench test is the highest-value / lowest-cost, and why?

---

## Answer Key

1. It *composes* the tested modules — constructs, injects pins, schedules cadences,
   carries two numbers between cores. It does *not* implement the sound or light logic
   (that's S3/S4).
2. Static initialization (constructs all globals, incl. `Link2Monitor`) → `setup()` (once)
   → `loop()` (forever). The monitor is constructed in phase 1.
3. It spawns the audio task, which immediately uses `i2s` and the synth's sine table;
   those must be constructed and `i2s.begin()` must have run first. Creating the task
   earlier races an uninstalled driver.
4. `static` places the 1 KiB buffer in `.bss`, not on the task's 4096-byte stack. A plain
   local would consume ¼ of the stack each call and risk overflow. Safe because only one
   task runs the function.
5. `loop()` on core 1 (Arduino `loopTask`, `CONFIG_ARDUINO_RUNNING_CORE=1` in the framework
   `sdkconfig`); `audioTask` on core 0 (the final `0` arg to `xTaskCreatePinnedToCore`).
6. `i2s_write(..., portMAX_DELAY)` blocks until the DMA ring has room, and the ring drains
   at exactly the sample rate — so the render→write loop runs at real-time speed with no
   timer (backpressure pacing).
7. `gSynthParams` and `gControlHeartbeatMs`, both `std::atomic<uint32_t>`. Exactly two so
   each is a single aligned word (torn-free with a plain load/store); a struct is multiple
   words and could be read half-updated.
8. Guarantees atomicity of *that one variable* (no torn reads); does *not* guarantee
   ordering relative to other variables. Okay here because no invariant spans the two
   atomics — any slight cross-variable skew is tolerated (500 ms / 20 ms tolerances ≫ any
   reordering window).
9. bits 0–15 rpm, 16–23 volume, 24 ersWhine, 25 limiter, 26 overrun, 27–31 reserved. Not
   in it: `ignition` and `throttlePercent` — both consumed by `volumeFor` (folded into the
   volume byte) on core 1.
10. Off → 0; Cranking → 70; Running → 90 + throttle·165/100 (90…255). Volume 0 silences.
11. A phase accumulator frozen at rpm 0 still outputs its current sample (a DC/steady
    hold); only the master `volume` multiply of 0 zeroes the output. Silence = volume 0.
12. Wire cut → no CRC-valid frame → `Link2Monitor` staleness ≥ 500 ms → LinkStatus Lost →
    projection forces effective `armed = false` → `EngineSim` ignition → Off →
    `volumeFor` → 0 → synth volume smooths to 0 → silence. (Plus the dead-man as backstop
    if the loop itself wedged.)
13. A switch that mutes audio if the control loop stops refreshing params. Core 0 (the
    audio task) owns it. It watches the *heartbeat atomic stamped by core 1* — i.e. the
    control loop's liveness — **not** board #1's link (that's the monitor).
14. NeverConnected = no valid frame ever (board #1 maybe booting) → calm teal breathe.
    Lost = was Up, then silent ≥ 500 ms → amber hazard. (Up = normal render.)
15. (a) atomics init to 0 (word 0 = silence); (b) `i2s_zero_dma_buffer` queues silence;
    (c) monitor boots failsafe → volumeFor 0; (d) even the dead-man branch forces silent
    params. Any one suffices — silence is over-determined by design.
16. The monitor's per-field-sanitized state (`state()`): last frame while Up, projected
    (commands zeroed, failsafe true, rpm zeroed, slow facts held) while stale. Both
    consumers use it so stale data is cleaned *once, centrally* — neither can act on a
    stale command.
17. Control 50 Hz (20 ms), lights ~30 Hz (33 ms), audio self-paced (~86 Hz blocks of
    11.6 ms). S4 guessed lights at 50 Hz — it's ~30 Hz.
18. So every consumer in the pass (UART stamps, both tick guards, `poll`, `update`,
    `render`) shares one consistent timestamp — no drift, one clock.
19. `src/` (main.cpp + feeder) is not compiled into the test build. It forces every
    `main.cpp` claim to "VERIFIED (source + build)" — read + compiled, never test-executed.
20. `~7.0.1` locks Arduino core 2.0.17 / IDF 4.4, the world where the legacy `driver/i2s.h`
    exists. Floating to 8.x (Arduino 3 / IDF 5) deletes that API and breaks
    `Esp32I2sAudio.cpp` at compile time.
21. `-1` = don't route a TX pin (RX-only UART). GPIO17 is reserved for a future ack
    channel; never opening it keeps the pin high-impedance so it drives nothing into
    board #1's reserved GPIO26.
22. Boot noise from garbage DMA memory (queues silence instead). Cousins: `strip.begin()`
    blanking the WS2812s (S4), and C2's A4 safe initial servo pulses. One principle:
    never let boot-garbage reach the physical world.
23. No. `main.cpp` is excluded from tests, so the dead-man branch has never executed
    anywhere. The 40/40 proves module *logic* + the *chain* in one thread — not the
    dual-core dead-man. Bench required (#57a).
24. Not a conflict. Pin numbers are per-chip; board #1's GPIO25 and board #2's GPIO25 are
    different physical pins on different chips. Boards are linked by a *wire between two
    pins*, not a shared number.
25. Wedge the control loop and confirm the speaker mutes within ~0.6 s (the dead-man). It's
    a few lines to stage, and it's the last-resort speaker failsafe that no test has ever
    run — highest safety value per minute.

---

## Things to Review Before Soundlight Standardization

- **The three silence layers and what each catches** (Concepts 12, 13, 16): link staleness
  (S1) → ignition-off (S2, via projection) → dead-man (S5). Be able to say which one
  survives core 1 dying.
- **Why silence is volume 0, not rpm 0** (Concept 12) — the single most common
  misconception, and the reason `volumeFor(Off) = 0` exists.
- **The one-word packed rule and #43's two halves** (Concept 10): S3 = layout, S5 =
  packing site + volume origin.
- **The verification tiers** (Concept 25): what "40/40" does and does not mean; which
  claims are source-only; the bench list.
- **The cadences** (Concept 19): 50 Hz control, ~30 Hz lights (S4's corrected guess),
  self-paced audio — and the single `millis()` read.
- **The cross-core discipline** (Concepts 6, 8, 9): two atomics, relaxed, no cross-variable
  invariant, pinned tasks.
- **Startup order and object lifetime** (Concepts 2, 4): why the task is created last, why
  the audio buffer is `static`.
- **The open questions carried forward**: #53 (volume parking: full = 75 %, crank ≈ 2.7 %),
  #56 (doc-consistency), #57 (bench runtime), #32/#55 (acoustic/visual). None blocks
  standardization but all must keep honest labels.

---

## "Ready for Standardization?" Checklist

Mark each before freezing the soundlight section:

- [ ] I can explain `main.cpp` as a conductor and name what it does *not* contain.
- [ ] I can trace power-on → static init → `setup()` → `loop()` and say what each phase does.
- [ ] I can state which core runs `loop()` vs `audioTask` and why pinning matters.
- [ ] I can explain backpressure pacing (blocking `i2s.write`) without invoking a timer.
- [ ] I can name the two cross-core atomics and justify `memory_order_relaxed`.
- [ ] I can recite the packed-word layout and say where `volume` comes from (#43 closed).
- [ ] I can write `volumeFor` and explain the silence path (volume 0, not rpm 0).
- [ ] I can describe the dead-man, its owner core, and why it's *never test-executed*.
- [ ] I can distinguish NeverConnected / Up / Lost and their three light renderings.
- [ ] I can explain pre-first-frame safety as *initial-value*, not timing, based.
- [ ] I can explain the effective-state projection and why both consumers share it.
- [ ] I can state the three cadences and the single-`millis()` rule.
- [ ] I can explain `test_build_src = no` and the source+build vs native vs hardware tiers.
- [ ] I can justify the `~7.0.1` platform pin (legacy I2S API) and the `lib_ignore` HALs.
- [ ] I can list the bench-only items (#57 + §11.5) and rank the dead-man test first.
- [ ] I understand S1–S5 are `explained`, not `reviewed` — a review pass is recommended
      (C-batch parity) before the manual is frozen.

When every box is checked and the review-pass decision is made, the soundlight firmware
section is ready to standardize.

---

*Teaching notes complete. This is a companion to `05_soundlight_main_integration.md`; no
source code was read beyond the already-explained S5 files, and no new claims are made.
Stop here — awaiting approval before any standardization work or a ground-station batch.*
