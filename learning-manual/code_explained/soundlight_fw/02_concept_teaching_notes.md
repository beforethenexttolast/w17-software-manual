# S2 — Concept Teaching Notes

A beginner-first companion to `02_engine_simulation.md`. The batch document explains
`EngineSim` *line-by-line*; this document teaches *the ideas* behind it, one at a time, so
the lessons carry into S3–S5 and beyond. Same shape as the S1 concept notes, with one
extra step per concept (part 5) because S2 sits in the middle of a pipeline and each idea
feeds a later batch.

Every concept below follows the same seven steps:

1. **Plain meaning** — what it is, no jargon.
2. **Why embedded/audio needs it** — why a tiny microcontroller making engine noise cares.
3. **S2 code** — the exact place it lives.
4. **S1 connection** — how the receiver (batch S1) feeds this.
5. **Feeds forward** — which later batch (S3 synth / S4 lights / S5 wiring / bench)
   consumes it.
6. **Beginner traps** — the misunderstanding that bites first.
7. **Bug prevented** — the concrete failure this idea exists to stop.

Reference map: `02_engine_simulation.md` (the line-by-line), `01_*` (S1, the input),
chapter 07 §3, `../../glossary.md`, `../../open_questions.md`.

A one-sentence orientation: **`EngineSim` turns five fields of the effective
`VehicleState` (armed, failsafe, throttle, gear, ersDeploying) plus a timestamp into an
`EngineState` of numbers (rpm, throttle, ignition mode, three effect flags) — no sound, no
hardware.**

---

## 1. What EngineSim is responsible for

**Plain meaning.** The real car motor is a quiet brushless unit. `EngineSim` is the
*imagination layer*: it invents a believable combustion engine — one that cranks, idles,
revs, blips on gear changes, hits a limiter, and crackles on overrun — and describes it as
plain numbers each control tick. It decides *what the engine is doing*; it does not make
the sound.

**Why embedded/audio needs it.** Separating "model the engine" from "synthesize the audio"
is the classic split between *state* and *rendering*. The model can be pure, integer-only,
and native-testable; the renderer (S3) can be all DSP. Mixing them would make both
untestable.

**S2 code.** The whole class is `EngineSim` (`EngineSim.hpp:68`, `EngineSim.cpp`). Its
output is `struct EngineState` (`EngineSim.hpp:57–64`) — "everything the synth + lights
need. Pure data."

**S1 connection.** Its sole input is `monitor.state()` — the *effective* `VehicleState`
S1 produces. `EngineSim` never sees a raw frame.

**Feeds forward.** `EngineState` → S3 (`EngineSynth` turns rpm + flags into samples). S4
(lights) does *not* read `EngineState` — it reads `VehicleState` directly. S5 wires the
tick.

**Beginner traps.** Thinking `EngineSim` "plays a sound." It emits a struct of numbers;
silence, pitch, and rasp are all S3's interpretation of those numbers.

**Bug prevented.** Tangling model and renderer — which would make the engine's *logic*
(does it stall on disarm?) impossible to unit-test without an audio device.

---

## 2. The VehicleState input from S1

**Plain meaning.** `update(nowMs, state)` takes the effective `VehicleState` — already
sanitized for staleness by S1's monitor. `EngineSim` trusts it completely and re-derives
nothing about link health.

**Why embedded/audio needs it.** Sanitizing stale data *once, centrally* (S1) means every
downstream consumer — engine, lights — gets safe inputs without re-implementing timeout
logic. `EngineSim` can be simple because the monitor already did the hard part.

**S2 code.** The header comment (`EngineSim.hpp:66–67`): *"Feed it the EFFECTIVE
VehicleState (post-staleness) each control tick."* Of 13 fields it reads exactly **five**:
`armed`, `failsafe`, `throttlePercent`, `gear`, `ersDeploying`.

**S1 connection.** This *is* the S1→S2 seam. S1's per-field projection (commands zeroed +
`armed` forced false on link-loss; slow facts held) is what makes §5–§7 below behave
correctly without `EngineSim` knowing a wire was cut.

**Feeds forward.** The same "trust the upstream stage's contract" discipline recurs: S3
trusts `EngineState`, S5 trusts that it wired `monitor.state()` → `update()`.

**Beginner traps.** Assuming `EngineSim` might get a *raw* frame if someone wires it wrong.
It's *documented* to get the effective state — but nothing in `EngineSim` enforces it; S5
must honor the contract (PROVISIONAL until S5).

**Bug prevented.** Duplicated, drifting staleness logic. If `EngineSim` re-checked
timeouts itself, two timers could disagree and the engine could act on data the lights
already discarded (or vice versa).

---

## 3. Why the engine follows commanded throttle, not wheel rpm

**Plain meaning.** The engine's pitch is derived from **commanded throttle** (how hard
board #1 told the motor to go), *not* from the car's measured **wheel rpm**. In fact
`EngineSim` never reads `VehicleState.rpm` at all.

**Why embedded/audio needs it.** Two reasons. (a) *Audio band:* wheel rpm maxes ~5,000;
a convincing V10 note needs 3,500–15,000 so its firing frequency lands where a small
speaker works (ch07 §3). (b) *Responsiveness:* commanded throttle changes the instant the
driver acts, so the engine revs immediately — waiting for the wheel to physically spin up
would feel laggy and dead.

**S2 code.** `targetRpm` (`EngineSim.cpp:14–21`) reads `state.throttlePercent` and the
config's idle/max — never `state.rpm`. The comment: *"the engine note tracks the actual
motor, not the raw stick."*

**S1 connection.** The throttle it reads is the *commanded* value that travelled C6→C10→C8
→the wire→S1. A disarmed or failsafed car has commanded throttle 0 (S1 zeroes it), so the
engine idles — you can't rev a parked car.

**Feeds forward.** S3 converts `engineRpm` into a firing frequency (5 firings/rev = V10).
Open question **#51** (found in S2): the received wheel-rpm field currently has *no*
consumer on board #2 — S3–S5 will confirm nothing else picks it up either.

**Beginner traps.** "Surely the engine sound should match how fast the wheels are turning?"
No — a real car's engine and wheels are linked by the gearbox, not identical; and here the
whole point is theatrical believability on a tiny speaker, which the throttle drives better.

**Bug prevented.** A screaming engine at a standstill (revving while wheels are stopped) —
or a dead-sounding engine that lags the throttle. Following *commanded* throttle sidesteps
both.

---

## 4. The Ignition enum and the ignition FSM

**Plain meaning.** The engine's "aliveness" is a three-state machine: **Off** (silent),
**Cranking** (starter whirring), **Running** (idle→redline). A tiny state machine, exactly
like S1's `LinkStatus`, but for the engine.

**Why embedded/audio needs it.** Sound has modes, not just a volume knob. "Silent," "a
starter churning," and "a live engine" are qualitatively different noises; a mode enum lets
S3 switch behaviour cleanly instead of guessing from rpm.

**S2 code.** `enum class Ignition : uint8_t { Off, Cranking, Running };` (`EngineSim.hpp:14`)
and the FSM in `update` (`EngineSim.cpp:34–43`).

**S1 connection.** The FSM's only driver is the effective `armed` flag — which S1 forces
false on link-loss. So the state machine's inputs are already safety-sanitized.

**Feeds forward.** S3 reads `EngineState.ignition`: silent when Off, a whir when Cranking,
full synthesis when Running. S5 ticks the FSM every control cycle.

**Beginner traps.** Expecting throttle or the failsafe flag to drive the mode. Neither does
directly — only `armed`. Throttle shapes rpm *within* Running; failsafe matters only
because S1 turns it into `armed = false`.

**Bug prevented.** Ad-hoc "is the engine alive?" checks scattered across the synth. One
enum, one source of truth.

---

## 5. Off / Cranking / Running — the three states in detail

**Plain meaning.** *Off:* disarmed → silence, rpm reported 0. *Cranking:* on arming, 600 ms
of low starter whir (1,800 rpm) before the engine catches. *Running:* normal idle
(3,500)→redline (15,000) behaviour.

**Why embedded/audio needs it.** The crank is pure *theater* — a real engine doesn't jump
from silence to idle, and the ear expects the starter churn. Encoding showmanship as a
state keeps it from contaminating the "is it safe?" logic.

**S2 code.** Transitions at `EngineSim.cpp:34–43`; the crank duration `crankMs = 600`, pitch
`crankRpm = 1800` (`EngineSim.hpp:19–21`). Entering Running assigns `rpm_ = idleRpm`
(line 42 — "the catch").

**S1 connection.** Every entry to these states comes from S1's `armed`. A recovered link
(S1 returns to Up with a fresh frame) re-arms → Off→Cranking → the engine audibly
*restarts*.

**Feeds forward.** S3 must render three distinct textures. S5's integration test
(frames→audio) is the first place all three are exercised as one chain.

**Beginner traps.** Thinking Cranking is skippable "since it's short." It's structural —
*every* return from Off replays it, including post-failsafe, because the FSM keeps no memory
of having been Running.

**Bug prevented.** An unnatural silence→idle pop. And, thanks to the catch (§10), a
post-crank rpm that depends on whatever `rpm_` happened to drift to during cranking.

---

## 6. `armed` as the *only* ignition driver

**Plain meaning.** Exactly one field decides Off vs alive: `armed`. Not throttle, not gear,
not the failsafe flag directly. `if (!state.armed) ignition_ = Off;` is checked *first*,
from any state.

**Why embedded/audio needs it.** A single, highest-priority safety input is easy to reason
about and impossible to accidentally override. "Is the car allowed to move?" and "should
the engine make noise?" become the same question.

**S2 code.** `EngineSim.cpp:35–36` — the first branch of the FSM, unconditional.

**S1 connection.** The elegant part: S1's projection **forces `armed = false`** on link
loss. So four different situations — deliberate disarm, board-#1 RC failsafe, cut wire
(stale link), and pre-first-frame boot — all reach `EngineSim` as `armed == false`, and all
produce silence. One check covers four dangers (§7).

**Feeds forward.** S3 keys silence off `ignition == Off`, which is downstream of this one
check. S5's dead-man is a *third* independent layer (§20).

**Beginner traps.** Believing you must handle failsafe, disarm, and link-loss separately in
`EngineSim`. You don't — S1 already collapsed them into `armed`. Adding extra checks here
would be redundant and could disagree.

**Bug prevented.** A live-sounding engine during a failsafe/disarm/dropout. Any path that
should silence the car converges on `!armed`.

---

## 7. Why disarm, failsafe, stale link, and pre-first-frame all become silence

**Plain meaning.** Four unsafe-or-unknown situations must all silence the engine, and they
do — because each becomes `armed == false` by the time `EngineSim` sees it.

**Why embedded/audio needs it.** "When in doubt, be silent" is the audio equivalent of a
control failsafe. A performer that keeps screaming when the car is parked, disarmed, or out
of contact is worse than useless.

**S2 code / S1 connection (they're inseparable here):**
- *Disarm:* board #1 sends `armed = false` → straight through S1 → Off.
- *Board-#1 failsafe:* the frame's `armed` is false and `failsafe` true → Off.
- *Stale link (cut wire):* S1's monitor **projects** `armed = false` after 500 ms → Off.
- *Pre-first-frame boot:* S1's `NeverConnected` returns the default `VehicleState`
  (`armed = false`) → Off. **The engine is silent before the very first valid frame.**

**Feeds forward.** S3 renders silence for all four identically. The bench will confirm the
speaker is actually quiet (not hissing) in these states — open q #32-adjacent.

**Beginner traps.** Thinking the four cases need four code paths. They collapse to one. Also:
thinking "stale link" reaches `EngineSim` as some special flag — no, it arrives *disguised
as disarm*, which is the whole point of S1's projection.

**Bug prevented.** A forgotten case. If each situation had its own branch, someone would
eventually miss one (say, pre-first-frame) and the engine would make a phantom noise at
boot. Convergence on `armed` makes that structurally impossible.

---

## 8. Crank duration and the catch-to-idle behaviour

**Plain meaning.** Cranking lasts 600 ms at 1,800 rpm; then the engine "catches" — rpm
jumps instantly to idle (3,500) and the state becomes Running.

**Why embedded/audio needs it.** The catch models combustion starting: the slow starter
churn suddenly becomes a self-sustaining idle. Modeling it as an instant jump (rather than
inertia carrying 1,800→3,500) both sounds right and makes post-crank rpm deterministic.

**S2 code.** `EngineSim.cpp:40–42`: `Cranking && (nowMs - crankStartMs_) >= config_.crankMs`
→ Running, `rpm_ = config_.idleRpm`. The `>=` is inclusive (600 ms exactly is enough).

**S1 connection.** `crankStartMs_` is anchored to `nowMs` when arming happens — the same
"anchor the clock at the event" pattern S1 used for `lastFrameMs_`.

**Feeds forward.** S3 renders the whir during Cranking, then the idle after the catch. The
600 ms and 1,800 rpm are config knobs the bench may re-voice (§21).

**Beginner traps.** Expecting rpm to *ramp* from crank to idle. It *snaps*. The inertia loop
governs Running behaviour, not the catch.

**Bug prevented.** A post-crank idle that varies run-to-run (because `rpm_` drifted to
different values during different-length effective cranks). The assign makes it exact.

---

## 9. Simulated rpm vs received wheel rpm (the two numbers)

**Plain meaning.** There are two completely separate rpm concepts: the **wheel rpm** on the
wire (`VehicleState.rpm`, ~0–5,000, from a Hall sensor) and the **engine rpm** `EngineSim`
invents (3,500–15,000). They are not related by any formula here — the engine one is
throttle-driven fiction.

**Why embedded/audio needs it.** See §3 — audio band + responsiveness. The names being
similar (`rpm` vs `engineRpm`) is the only thing connecting them.

**S2 code.** Input side: `VehicleState.rpm` — untouched. Output side:
`EngineState.engineRpm` (`EngineSim.hpp:58`) — computed from throttle.

**S1 connection.** S1's monitor carefully **zeroes** `VehicleState.rpm` on staleness
(so a stale wheel speed can't animate anything). That care is currently precautionary —
because nothing reads it (§3, #51) — but correctly future-proofs it.

**Feeds forward.** S3 uses `engineRpm`. If a future feature wants real speed (a
speed-linked light, say), `VehicleState.rpm` is sitting there unused (#51).

**Beginner traps.** Conflating the two because both say "rpm." `engineRpm` is *not* a
scaled wheel rpm; it ignores the wheel entirely.

**Bug prevented.** Wiring the wrong rpm into the synth — which would either scream at a
standstill (wheel rpm mis-scaled) or produce sub-audible pitches (raw wheel rpm too low).

---

## 10. The throttle-to-rpm mapping

**Plain meaning.** Engine *target* rpm is a straight line: throttle 0% → idle (3,500),
100% → redline (15,000), linear in between. Target 50% = 9,250.

**Why embedded/audio needs it.** A simple, predictable map means the pitch tracks the stick
intuitively, and it's trivial to test. Integer-only (house rule) keeps it cheap.

**S2 code.** `targetRpm` (`EngineSim.cpp:18–20`): `idleRpm + span * t / 100`, span = 11,500.
Endpoint-exact (100·11500/100 = 11500 divides cleanly).

**S1 connection.** `t` is the effective commanded throttle. Disarmed/stale → 0 → target =
idle (though Off short-circuits to 0 output anyway).

**Feeds forward.** This *target* is what the inertia loop (§11) chases; the *result*
(`engineRpm`) is what S3 pitches.

**Beginner traps.** Thinking the engine instantly *is* the target. No — target is the
destination; inertia (§11) governs how fast rpm travels there. `targetRpm` alone would make
rpm teleport.

**Bug prevented.** A throttle map that clips or inverts. The `valid()` guard (`maxRpm >
idleRpm`) ensures the line always slopes up.

---

## 11. Braking clamps to idle

**Plain meaning.** Throttle can be negative (−100…+100, braking). For engine rpm, negative
throttle is treated as 0 → target = idle. The engine falls to idle under braking; it never
goes "below idle" or negative.

**Why embedded/audio needs it.** Braking isn't engine load — a real engine on the brakes
(clutch in) drops to idle. And rpm below idle or negative is meaningless/dangerous for the
pitch math.

**S2 code.** `targetRpm`: `const int32_t t = state.throttlePercent < 0 ? 0 :
state.throttlePercent;` (`EngineSim.cpp:19`). Same clamp when storing `lastThrottle_`
(line 69).

**S1 connection.** The sign comes straight from the wire (C8's signed throttle byte, S1's
two's-complement decode). S1 doesn't clamp it — `EngineSim` does, at the point of use.

**Feeds forward.** The overrun detector (§17) deliberately does *not* pre-clamp: it uses the
raw signed value so hard braking registers as a big throttle drop (§17). Two different
treatments of the same negative value — know which is which.

**Beginner traps.** Assuming negative throttle would make rpm negative or the cast would
wrap to a huge positive (231). The explicit `< 0 ? 0` clamp prevents both — it's not left to
an implicit cast.

**Bug prevented.** A braking command decoded as a huge positive throttle (if `−25` were read
unsigned as 231) redlining the engine — or negative rpm crashing the pitch math downstream.

---

## 12. Asymmetric exponential inertia — the heart

**Plain meaning.** rpm doesn't jump to its target; it *chases* it, moving a **fraction of
the remaining gap** each tick. And the fraction differs by direction: faster up (rev-up)
than down (rev-down).

**Why embedded/audio needs it.** Real engines have rotating mass — they can't change speed
instantly, and they spin up harder than they coast down (the flywheel keeps them turning).
Modeling that inertia is what makes the sound *breathe* instead of stepping robotically.

**S2 code.** `EngineSim.cpp:83–85`:
```cpp
const int32_t gap = target - rpm_;
const uint16_t rate = (gap >= 0) ? config_.revUpPerMille : config_.revDownPerMille; // 6 vs 3
rpm_ += gap * rate * dtMs / kInertiaScale; // /1000
```
At 20 ms ticks: up closes 6·20/1000 = **12 %** of the gap/tick, down **6 %**.

**S1 connection.** `dtMs` comes from the `nowMs` the caller passes — the same clock seam as
S1. Time is injected, not read from hardware.

**Feeds forward.** The smooth rpm curve is what S3 pitches; a stepped rpm would click. (S3
may add *further* smoothing — PROVISIONAL.)

**Beginner traps.** (a) Reading "per-mille per ms" as a fixed rpm step — it's a fraction of
the *gap*, so it slows as it approaches. (b) Thinking up and down use the same rate.

**Bug prevented.** A robotic, instant-response engine (no inertia) or a symmetric one that
sounds unnaturally eager to slow down. It's the same exponential-approach math as C7's EMA
battery filter — worth seeing the family resemblance.

---

## 13. Rise vs fall response (the asymmetry, measured)

**Plain meaning.** From the same starting gap, over the same time, rev-up covers more ground
than rev-down. That gap between the two *is* the asymmetry.

**Why embedded/audio needs it.** It's the audible signature of a real engine — snappy on the
throttle, lazy on the overrun. Getting the *ratio* right matters more than the exact times.

**S2 code.** Rates 6 vs 3 (`EngineSim.hpp:25–26`). Test `test_rev_down_is_slower_than_rev_up`
(`test_main.cpp:74–90`) measures `gained` (idle→afterRevUp) vs `shed`
(afterRevUp→afterRevDown) over equal 200 ms windows and asserts `gained > shed`.

**S1 connection.** None specific — this is internal dynamics.

**Feeds forward.** S3's pitch glide inherits this asymmetry directly.

**Beginner traps.** Expecting the test to check exact rpm values. It checks a *relationship*
(gained > shed), which is robust to wobble noise and the exact constants — a better test
design than pinning brittle numbers.

**Bug prevented.** Someone "simplifying" to a single symmetric rate. The relational test
fails loudly, protecting the feel.

---

## 14. The overshoot snap guard

**Plain meaning.** If a tick's step is big enough to *cross* the target, rpm is snapped
exactly onto the target instead of overshooting.

**Why embedded/audio needs it.** Without it, a large `dtMs` (or an aggressive rate) could
push rpm past the target; then the sign-picked rate flips and rpm could oscillate or hold a
never-settling residual — an audible warble.

**S2 code.** `EngineSim.cpp:87–89`:
```cpp
if ((gap >= 0 && rpm_ > target) || (gap < 0 && rpm_ < target)) rpm_ = target;
```

**S1 connection.** Matters most alongside the stall clamp (§16), which bounds `dtMs`; the
guard is the second line of defence for the overshoot the clamp doesn't fully prevent.

**Feeds forward.** Guarantees S3 gets a monotone approach (no ringing at the target).

**Beginner traps.** Thinking it's dead code because defaults never overshoot (6‰·100ms =
0.6 < 1). It's defensive against re-voiced configs — cheap insurance, not waste.

**Bug prevented.** A settling oscillation at every throttle target — an engine that "hunts"
audibly around each rev point.

---

## 15. Truncation residuals

**Plain meaning.** Integer division throws away the remainder, so once the gap is small the
per-tick step rounds to 0 and rpm parks *just short* of the target — e.g. idles around
3,492 instead of exactly 3,500.

**Why embedded/audio needs it.** Integer math (house rule — no floats in control paths) is
fast and deterministic, but it has this rounding floor. You must know it exists so you don't
write tests demanding exact equality.

**S2 code.** `rpm_ += gap * rate * dtMs / kInertiaScale` truncates; at 20 ms ticks the step
is 0 once `|gap|·6·20 < 1000`, i.e. `|gap| ≤ 8` climbing (≤16 falling).

**S1 connection.** None specific.

**Feeds forward.** An 8-rpm error at 3,500 is ≈0.2% — inaudible; S3's pitch won't reveal it.
Every S2 test uses `WITHIN` tolerances, never exact equality, precisely because of this.

**Beginner traps.** Expecting `engineRpm == 3500` exactly at idle. It won't be, and that's
fine. Writing `TEST_ASSERT_EQUAL(3500, …)` would fail.

**Bug prevented.** Brittle tests, and chasing a "phantom" idle error that's just integer
rounding.

---

## 16. The stall clamp

**Plain meaning.** A single tick's elapsed time is capped at 100 ms. If the loop stalls for
a second, `EngineSim` integrates only 100 ms of movement and discards the rest.

**Why embedded/audio needs it.** If the control loop hiccups (a slow log, a debugger pause),
you don't want the engine to lurch a huge rpm jump on the next tick. Capping `dtMs` bounds
the per-tick change.

**S2 code.** `kMaxDtMs = 100` (`EngineSim.cpp:7`), applied at lines 30–32. First-call `dtMs`
is forced to 0 by seeding (lines 24–27). Note: wall-clock windows (blip, overrun, wobble)
use raw `nowMs` and are *not* clamped — only the inertia integration is.

**S1 connection.** Same 100 ms clamp idea as C6's ERS; and the same first-call-anchor pattern
S1/C2/C7 use.

**Feeds forward.** Keeps rpm continuous for S3 even when core 1 (S5) is briefly busy with LED
writes or frame parsing.

**Beginner traps.** Thinking the clamp "loses time" incorrectly. It deliberately drops the
excess — a stalled engine model shouldn't fast-forward. (The alternative, catching up, would
lurch.)

**Bug prevented.** A giant rpm leap (and pitch jump) after any loop stall — the audio
equivalent of C10's tick-guard discussion.

---

## 17. Idle wobble

**Plain meaning.** A small triangle wave (±120 rpm, 400 ms period ≈ 2.5 Hz) added to the
*audible* rpm at idle, fading to zero as throttle opens. It stops the idle from being a
dead-flat tone.

**Why embedded/audio needs it.** A perfectly steady rpm sounds like a synthesizer test tone,
not a machine. Real engines hunt slightly at idle. The wobble sells "engine."

**S2 code.** `EngineSim.cpp:113–116`: `wobblePhase_` accumulates `dtMs % 400`; a two-piece
formula makes a triangle in ≈[−100,+100]; scaled by `idleWobbleRpm * idleness / 10000`, so
±120 at idle, 0 at full throttle. It's added to `audible`, **not** `rpm_`.

**S1 connection.** None specific.

**Feeds forward.** S3 pitches the wobbling `engineRpm` directly — the wobble becomes audible
pitch flutter. It's *perceptual*: layered on the output, leaving the internal `rpm_` clean.

**Beginner traps.** Thinking the wobble changes the "real" rpm. It doesn't — `rpm_` stays
smooth; only the reported `engineRpm` wobbles. (This perceptual-vs-physical split is why the
limiter reads `rpm_`, §18.)

**Bug prevented.** A lifeless idle. And — because it's layered on output only — it can't
corrupt the inertia math or fake a limiter trigger.

---

## 18. Shift blip

**Plain meaning.** On a gear change, the audible rpm briefly jumps: an upshift *dips*
(−1,400 rpm for 130 ms), a downshift *blips up* (+1,400). It mimics how a real engine's revs
move when you change gear.

**Why embedded/audio needs it.** Gear changes are a huge part of a car's character
(especially F1's rev-matched downshifts). A blip makes shifting *audible* and dramatic.

**S2 code.** Detection at `EngineSim.cpp:48–56` (compare `state.gear` to `lastGear_`, set a
signed `blipRpm_` and `blipUntilMs_`); application at lines 120–122 (`if (nowMs <
blipUntilMs_) audible += blipRpm_`). Perceptual — added to `audible`, not `rpm_`.

**S1 connection.** `state.gear` is a *held* field in S1's projection (it survives staleness).
That interacts crucially with the phantom guard (§19).

**Feeds forward.** S3 pitches the blipped `engineRpm`; the listener hears the dip/blip.

**Beginner traps.** Thinking a second shift within 130 ms stacks. It overwrites — one blip
at a time. And the blip is edge-triggered (on the *change* of gear), not level-triggered.

**Bug prevented.** Silent, undramatic gear changes. (And the guard, §19, prevents *fake*
ones.)

---

## 19. The phantom-guard for shift blips

**Plain meaning.** Blip detection is suppressed in three situations where a gear *difference*
is not a real *shift*: the first state ever seen, while not Running, and while board #1
reports failsafe. Crucially, `lastGear_` is still updated *every* tick regardless.

**Why embedded/audio needs it.** A "gear changed" edge is only meaningful if there was a
prior real gear to change *from*. At boot, or across a failsafe where gear jumped while the
driver did nothing, a naive edge detector would fire a fake blip.

**S2 code.** Guard `if (everSeenState_ && ignition_ == Running && !state.failsafe)`
(`EngineSim.cpp:48`); unconditional bookkeeping `lastGear_ = state.gear;` (line 70).

**S1 connection.** Two layers cooperate. S1 **holds** gear during staleness (so it doesn't
blank to a default and snap back). S2 additionally (a) seeds `lastGear_` on first sight
without emitting an edge, and (b) tracks `lastGear_` even while the guard blocks blips — so
when a real failsafe *does* change gear silently, the recovery frame finds `gear ==
lastGear_` and no phantom blip fires.

**Feeds forward.** S3/the listener never hears a spurious shift at boot or on recovery.

**Beginner traps.** Thinking you should gate the `lastGear_` *update* too. That's the classic
bug: if you skip the update while guarded, the first clean frame after failsafe sees a stale
`lastGear_`, computes a false edge, and blips. Gate the *detection*, never the *bookkeeping*.

**Bug prevented.** A phantom gear-shift sound at boot (first state is gear 4) or right after
a failsafe recovery — jarring and wrong.

---

## 20. The limiter flag

**Plain meaning.** When you're near-full throttle *and* pinned near redline, `limiterActive`
goes true — the signal for the iconic F1 rev-limiter "buzz." `EngineSim` only *detects* it;
the buzz cadence (ignition-cut bursts) is the synth's job.

**Why embedded/audio needs it.** The limiter buzz is a defining F1 sound. Splitting
*detection* (here) from *rendering* (S3) keeps each simple.

**S2 code.** `EngineSim.cpp:123–126`: `throttlePercent >= 95 && rpm_ >= maxRpm -
limiterBandRpm` (i.e. ≥14,750). Note it checks **`rpm_`**, the clean internal rpm — *not*
the wobble/blip-inflated `audible`.

**S1 connection.** Throttle is the effective commanded value; a disarmed car can't hit the
limiter (Off short-circuits first).

**Feeds forward.** S3 reads `limiterActive` and applies the cut-burst cadence — PROVISIONAL
until S3.

**Beginner traps.** Thinking it reads the audible rpm. It reads `rpm_` on purpose: otherwise
a +1,400 downshift blip near redline could *fake* a limiter trigger. Perceptual layers must
never drive real decisions.

**Bug prevented.** A false limiter buzz caused by a wobble/blip briefly poking `audible`
above the threshold. Reading `rpm_` immunizes it.

---

## 21. The overrun window

**Plain meaning.** After a *fast* throttle lift from *high* revs, a 900 ms window opens
during which `overrunActive` is true — the cue for the pop-and-bang crackle. Again,
`EngineSim` opens the window; the synth makes the crackle.

**Why embedded/audio needs it.** Overrun crackle (unburnt fuel firing in the hot exhaust on
a lift) is a beloved motorsport sound. It only happens after a *sharp* lift from *high* rpm,
so both conditions must be detected.

**S2 code.** `EngineSim.cpp:59–66`: `drop >= 40` (percentage points in one tick) **and**
`rpm_` was ≥ 10,400 (60% of the idle→max span). Opens `overrunUntilMs_ = nowMs + 900`.
Applied at line 134. The `int` casts on `drop` make hard braking (drop 100−(−100)=200) count.

**S1 connection.** Throttle from the wire; the negative-braking case relies on S1's signed
decode being preserved (not pre-clamped) here.

**Feeds forward.** S3 gates noise bursts on `overrunActive` — PROVISIONAL until S3.

**Beginner traps.** Thinking the crackle needs continuous conditions. No — the *window* is
armed by a single qualifying tick and then runs on wall-clock for 900 ms regardless of what
throttle does next (unless a failsafe kills Running).

**Bug prevented.** Crackle at the wrong time — e.g. a gentle lift from low rpm. Requiring
*both* a big drop *and* high starting rpm keeps it authentic.

---

## 22. Source-verified but untested paths, and the three "waits-for" boundaries

**Plain meaning.** Some behaviours are proven by reading the code (VERIFIED source) but have
no dedicated test asserting them; and some claims can't be settled at all until a later batch
or hardware.

**Why embedded/audio needs it.** Honest labeling prevents overconfidence. "9/9 green" is not
"everything works" — it's "the asserted subset works, on this laptop."

**S2 code / the honest lists (batch doc §5, §6):**
- *Source-verified, untested:* the `!failsafe` blip guard, the idle wobble shape, negative-
  throttle paths, blip magnitude/duration, the overshoot guard, six of seven `valid()`
  clauses.
- *What native tests prove:* the FSM transitions, the throttle map endpoints, the rev
  up/down asymmetry (relationally), limiter and overrun flags firing/clearing, ERS-whine
  passthrough, config validity. **Logic, on the host.**
- *What native tests do NOT prove:* anything audible; the wiring; real-time behaviour on the
  ESP32.

**S1 connection.** Same discipline S1 used (its false-sync case was source-only via copy
identity).

**Feeds forward — the three boundaries:**
- **Waits for S3:** every synth-side meaning of `EngineState` (silence when Off, whir
  texture, buzz cadence from `limiterActive`, crackle from `overrunActive`, pitch from
  `engineRpm`, whine from `ersWhine`, and any further smoothing).
- **Waits for S5:** that `main.cpp` feeds `monitor.state()` → `update()` with `millis()`,
  every tick, on core 1; the config `static_assert` site; which fields cross into the packed
  atomic word (open q **#43**); the frames→audio integration test.
- **Waits for real speaker/audio hardware:** whether the constants *sound* right on the
  MAX98357A + 4Ω speaker (open q **#32**); I2S behaviour; whether 600 ms crank / 130 ms blip
  *feel* right trackside. The config struct exists so these can be re-voiced.

**Beginner traps.** Reading a passing suite as total proof, or reading "PROVISIONAL" as
"probably broken." PROVISIONAL means "not yet confirmable from *this* batch's evidence."

**Bug prevented.** Shipping on false confidence — labeling audio or wiring "done" before the
batch/bench that can actually check it.

---

## Quiz — 20 questions

1. `EngineSim` reads how many of `VehicleState`'s 13 fields, and which ones? Which field is
   conspicuously *not* read?
2. Name the one field that drives the ignition FSM, and the four distinct situations that
   all reach `EngineSim` as that field being false.
3. Why does the engine note follow commanded throttle instead of the car's wheel rpm? Give
   the audio reason and the responsiveness reason.
4. List the three ignition states and the trigger for each transition (including the exact
   crank duration and its boundary type).
5. When the engine "catches" (Cranking→Running), what happens to `rpm_`, and why an assign
   rather than letting inertia carry it?
6. Compute the throttle-target rpm at 0%, 50%, and 100%. Why are the endpoints exact?
7. A braking command arrives as throttle −25. What target rpm does the engine chase, and by
   what line of code?
8. Explain "6 per-mille per ms" in plain terms. At a 20 ms tick, what fraction of the gap
   does rev-up close? Rev-down?
9. `test_rev_down_is_slower_than_rev_up` asserts `gained > shed` rather than exact rpm.
   Why is that a *better* test?
10. What is the overshoot snap guard, and why isn't it dead code even though the default
    config never overshoots?
11. At idle with 20 ms ticks, roughly how far short of 3,500 does rpm park, and why? What
    does this imply about how the tests assert idle rpm?
12. What does the stall clamp cap, what value, and which timers is it deliberately *not*
    applied to?
13. Describe the idle wobble: amplitude, period, how it changes with throttle, and — the key
    point — is it added to `rpm_` or to `audible`? Why does that distinction matter?
14. An upshift and a downshift produce what signed blip, for how long? Is the blip physical
    or perceptual?
15. Name the three conditions that suppress shift-blip detection. Why is `lastGear_` updated
    *outside* that guard, and what bug appears if you move it inside?
16. The limiter reads `rpm_`, not `audible`. Construct the false positive this prevents.
17. State both conditions for the overrun window to open, with their numeric thresholds. Why
    does hard braking (throttle → −100) count as a qualifying drop?
18. The engine goes Off. What does `engineRpm` report *immediately*, and what is the internal
    `rpm_` doing meanwhile?
19. Give three behaviours that are source-verified but have no dedicated test.
20. Sort each into S3 / S5 / bench: (a) the limiter *buzz cadence*; (b) that `update()` is
    called every tick with `millis()`; (c) whether the idle wobble sounds good on the
    speaker; (d) which fields enter the packed atomic word.

## Answer key

1. Five: `armed`, `failsafe`, `throttlePercent`, `gear`, `ersDeploying`. Not read:
   `VehicleState.rpm` (the wheel rpm) — nor, per grep, anything else on board #2 (#51).
2. `armed`. The four: deliberate disarm; board-#1 RC failsafe (frame `armed` false); stale
   link (S1's monitor projects `armed = false` after 500 ms); pre-first-frame boot (S1's
   NeverConnected default has `armed = false`). All → Off → silence.
3. Audio: wheel rpm maxes ~5,000 but a convincing V10 note needs 3,500–15,000 for the firing
   frequency to land in a small speaker's band. Responsiveness: commanded throttle changes
   the instant the driver acts, so the engine revs immediately instead of lagging the wheel.
4. Off (→Cranking on `armed` becoming true, anchoring `crankStartMs_`); Cranking (→Running
   when `nowMs - crankStartMs_ >= 600 ms`, inclusive); Running (→Off whenever `!armed`).
   `!armed` → Off is checked first, from any state.
5. `rpm_ = idleRpm` (snapped to 3,500). An assign makes post-crank rpm deterministic
   regardless of what `rpm_` drifted to during cranking, and models combustion catching as
   an instant event — the ear expects a jump, not a ramp.
6. 3,500 / 9,250 / 15,000. span = 11,500; at 100%, 11500·100/100 = 11500 divides exactly,
   and at 0% the span term is 0 — so both endpoints have no truncation loss.
7. Idle (3,500). `targetRpm`'s clamp `const int32_t t = state.throttlePercent < 0 ? 0 :
   state.throttlePercent;` turns −25 into 0 → target = idle + 0.
8. Each ms, rpm moves toward target by 6/1000 of the remaining gap. Over a 20 ms tick:
   6·20/1000 = 12% up; rev-down uses rate 3 → 6% down.
9. It pins a *relationship* (the asymmetry) that's robust to idle-wobble noise and to the
   exact constant values, instead of brittle exact rpm numbers that would break on any
   re-voicing or rounding change.
10. If a step ever crosses the target, rpm is snapped onto it (no overshoot/ring). Not dead
    code: it's defensive for *re-voiced* configs (a larger rate or dt could overshoot); the
    default 6‰·100ms = 0.6 is safe, but the guard protects future tuning.
11. About 8 rpm short (parks ≈3,492), because once `|gap|·6·20 < 1000` the integer step
    truncates to 0. Implication: tests must use `WITHIN` tolerances, never exact equality.
12. It caps a single tick's `dtMs` at 100 ms (`kMaxDtMs`). It is *not* applied to the
    wall-clock windows (blip `blipUntilMs_`, overrun `overrunUntilMs_`, wobble phase) — only
    to the inertia integration.
13. ±120 rpm, 400 ms period (≈2.5 Hz), fading linearly to 0 as throttle → 100%. Added to
    `audible`, not `rpm_`. It matters because the internal `rpm_` stays clean, so the wobble
    can't corrupt the inertia math or fake a limiter trigger — it's a *perceptual* layer.
14. Upshift → −1,400 (a dip); downshift → +1,400 (a blip); each for 130 ms. Perceptual
    (added to `audible`, `rpm_` untouched).
15. `everSeenState_` (not the first state), `ignition_ == Running`, and `!state.failsafe`.
    `lastGear_` updates unconditionally so that a gear change *during* a guarded period is
    tracked silently; if you moved the update inside the guard, the first clean frame after
    failsafe would compare against a stale `lastGear_`, see a false edge, and fire a phantom
    blip.
16. A downshift near redline adds +1,400 to `audible`, poking it above 14,750 while the base
    `rpm_` is actually below the limiter band → a *fake* limiter buzz. Reading `rpm_` (the
    clean value) immunizes the decision.
17. Both, in one tick: throttle *drop* ≥ 40 percentage points, AND `rpm_` was ≥ 10,400 (idle
    + 60% of the 11,500 span). Hard braking counts because `drop` is computed with `int`
    casts: 100 − (−100) = 200 ≥ 40.
18. `engineRpm` reports 0 immediately (the Off short-circuit). Internally `rpm_` still decays
    toward 0 with rev-down inertia, but that decay is hidden from the output.
19. Any three of: the `!failsafe` blip guard; the idle wobble shape/period/fade; negative-
    throttle paths (target clamp + overrun drop); blip magnitude/duration; the overshoot
    guard; the `rpm_ < 0` floor; six of the seven `valid()` clauses; the Cranking rpm value.
20. (a) S3 — buzz cadence is synth rendering. (b) S5 — the wiring/tick. (c) bench — how it
    sounds on the speaker (#32). (d) S5 — the packed atomic word (#43).

## Things to review before S3

- **`EngineState`'s six fields** (`EngineSim.hpp:57–64`) — S3's *entire input*. Be fluent in
  what each means: `engineRpm` (pitch), `throttlePercent` (loudness/rasp hint), `ignition`
  (silence/whir/run mode), `limiterActive`, `overrunActive`, `ersWhine`.
- **Chapter 07 §4** — the S3 preview: firing frequency (5 firings/rev = V10), wavetable
  partials, per-rev AM, seeded-LFSR noise, pitch-tracking ERS whine, parameter smoothing.
- **The perceptual-vs-physical split** (concepts 17, 18, 20) — S3 takes the *audible*
  `engineRpm` and pitches it; know that wobble/blips are already baked in.
- **Firing-frequency arithmetic** — engine rpm → Hz. At 5 firings/rev: 3,500 rpm →
  ≈292 Hz, 15,000 → 1,250 Hz. S3 lives in this frequency domain; get comfortable with
  rpm→Hz now.
- **Integer/fixed-point comfort** — S3 is the project's hardest integer math (phase
  accumulators, wavetables, LFSR). Concepts 12/15 (exponential approach, truncation) are the
  warm-up.
- **Glossary terms added by S2** — ignition state machine, asymmetric inertia, idle wobble,
  overrun.

## "Ready for S3?" checklist

- [ ] I can explain why the engine follows commanded throttle and never reads wheel rpm.
- [ ] I can draw the ignition FSM and name `armed` as the sole driver, checked first.
- [ ] I can explain how S1's projection makes disarm/failsafe/stale/boot all become silence.
- [ ] I can compute a throttle-target rpm and explain the braking-clamps-to-idle rule.
- [ ] I can explain asymmetric exponential inertia and why up ≠ down, and relate it to C7's
      EMA.
- [ ] I understand the stall clamp, the overshoot guard, and why idle parks ~8 rpm short.
- [ ] I can distinguish *perceptual* layers (wobble, blip on `audible`) from *physical* rpm
      (`rpm_`), and say why the limiter reads the physical one.
- [ ] I can state the shift-blip phantom guard AND why `lastGear_` updates outside it.
- [ ] I can name what `limiterActive` and `overrunActive` are for, and that S3 renders them.
- [ ] I can list what native tests prove vs what waits for S3, S5, and the bench.
- [ ] I know `EngineState` is S3's input and can name all six fields from memory.

If most boxes are checked, you're ready for S3 — the synthesizer, the project's hardest
math. If several aren't, re-read the batch-doc sections named in each concept; they're the
shortest path back.

---

*Concept teaching notes for S2 complete. No source modified; written only in
`learning-manual/`. Awaiting approval before S3 ("The synthesizer (DSP)":
`lib/soundsynth`).*
