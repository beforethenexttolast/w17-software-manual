# C10 — Concept Teaching Notes

A standalone study companion to `10_main_integration.md`. It teaches, from absolute beginner
level, the integration concepts C10 introduced — the ideas you need to understand how a pile of
separately-tested modules becomes *one running program*. It uses **only** the already-read C10
source (`src/main.cpp`, `src/SimCrsfFeeder.{hpp,cpp}`, `platformio.ini`,
`.github/workflows/ci.yml`), the earlier control-fw batch docs (C1–C9b), `glossary.md`, and
`open_questions.md`. It reads no soundlight or ground-station file.

Read it top to bottom. Each of the 20 concepts follows the same seven-part shape you asked for.
The 25-question quiz + answer key + review list + readiness checklist are at the end.

> **The one picture to hold in your head for all of C10:**
> ```
>   power on
>      │
>      ▼
>   static init ── constructs EVERY global object (modules + HAL), in file order,
>      │           BEFORE setup() runs. No pins attached yet. Motor cannot move.
>      ▼
>   setup() ────── runs ONCE: attach PWM with SAFE pulses, first esc.setThrottle(0)
>      │           anchors the 2 s hold, (tuning build) loadAtBoot + applyTuning.
>      ▼
>   loop() ─────── runs FOREVER, one quick pass each time. No delay(). Every job is
>                  guarded by `if (now - last >= period)`. One pass:
>                    drain UART → (sim feed) → (console) → decode on new frame →
>                    battery 10Hz → telemetry 5Hz → CONTROL TICK 50Hz → link2 20Hz
> ```
> C10 is **wiring + scheduling**, not new mechanisms. Every *behaviour* was proven in C1–C9;
> C10 decides *who calls whom, with what, in what order, how often* — and that ordering **is**
> the safety argument.

**A note on evidence, carried into every concept below.** `main.cpp` has **no automated test**
(`platformio.ini` sets `test_build_src = no`, Concept 18/19). So "proven" here means one of two
things: the *wiring* is provable by reading the code and the code provably **builds** (verified
2026-07-05: `esp32dev` + `esp32dev_sim` + `esp32dev_tuning` all build SUCCESS), and the *module
behaviour* being wired is pinned by a native test (the full suite re-ran 2026-07-05:
**147/147 PASSED**). What is **not** proven is the composed program actually *running* — that is
the Wokwi sim and the bench (Concept 20).

---

## Concept 1 — `setup()` vs `loop()` (the Arduino runtime model)

**1. Beginner explanation.** A normal desktop C++ program starts at `int main()` and ends when
`main` returns. An Arduino-framework program is different: **you don't write `main()`**. Instead
you write two functions — **`setup()`**, called exactly once when the chip boots, and
**`loop()`**, called again and again, forever. The framework supplies a hidden `main()` that
initializes the chip, calls your `setup()` once, then calls your `loop()` in an endless `while`.

**2. Why it matters in embedded systems.** A microcontroller has no operating system launching
and quitting programs — it runs *one* program from power-on to power-off. `setup()` is your
"prepare the hardware" phase; `loop()` is your "do the work, forever" phase. Because `loop()`
runs constantly, **it must return quickly** — the whole system's responsiveness is "how fast one
`loop()` pass completes." That is the origin of the house rule *no `delay()` in the control path*
(C1): a `delay(100)` would freeze every other job for 100 ms.

**3. C10 code.**
```cpp
void setup() {
    crsfUart.begin();
    // ... attach PWM with safe pulses, first esc.setThrottle(0) ...
}

void loop() {
    const uint32_t nowMs = millis();
    // drain UART, decode, timed blocks ... then return (fast) and get called again
}
```

**4. Connection to earlier batches.** Every module you met in C1–C9 was written *assuming* this
model: pure logic that takes `nowMs` as a parameter (FSM, WheelSpeed, ERS, BatteryMonitor) so it
never calls a real clock, and non-blocking I/O seams (`ICharIO::read()` returns −1 when empty,
C9b). C10 is the first file that actually *is* the loop those modules were built to live inside.

**5. Common beginner misunderstanding.** "`loop()` is my program's main loop, so I can put a
`while(true)` or a `delay()` inside it." No — `loop()` **is already** the forever-loop; you get
one pass per call and must return. Blocking inside it stalls everything: failsafe, outputs,
telemetry. The correct pattern is "check the clock, do the due work, return" (Concept 14/15).

**6. What could go wrong on real hardware.** If any block in `loop()` blocked — a busy-wait, a
blocking serial read, a `delay()` — the 50 Hz control tick would miss its deadline, failsafe
detection would slip past its 500 ms budget, and outputs would stop updating. On the ESP32 the
watchdog timer might even reset the chip. The design avoids all of this by never blocking.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** `setup()`/`loop()` are
defined and the whole file compiles into three firmware images. **PROVISIONAL:** that a real pass
completes fast enough on silicon (it obviously should — there's no blocking call — but "the loop
keeps up at 50 Hz on the real chip" is a bench observation, not a test).

---

## Concept 2 — Global / static object lifetime

**1. Beginner explanation.** In C10, every module (the receiver, the decoder, the gearbox, the
outputs, the HAL wrappers) is a **global object** — declared at file scope, outside any function.
Global objects are **constructed once, automatically, before `setup()` runs** (a phase called
*static initialization*), and they live for the entire life of the program. There is no `new`,
no `delete`, no heap — the objects simply exist for the whole run.

**2. Why it matters in embedded systems.** Embedded code avoids dynamic memory (`new`/`malloc`)
because a long-running device can fragment or exhaust the heap and crash days later. Making every
module a global with a fixed lifetime means memory use is known at compile time (C10's build
reported RAM 7.0 % used) and there are no allocation surprises. But it has a subtle cost: **the
constructors run before `setup()`**, at a moment when *no hardware is attached yet*.

**3. C10 code.** All globals live in one anonymous namespace (lines 37–165):
```cpp
namespace {
crsf::CrsfReceiver crsfReceiver;
channels::ArmGate armGate;
gearbox::Gearbox virtualGearbox(kGearboxConfig);
outputs::EscOutput esc(escPwm, clock, escConfig);
// ... ~30 objects, constructed in this order, before setup() ...
} // namespace
```
The **anonymous namespace** gives every name *internal linkage* — private to this file, so no
symbol collides with a library (C4 reminder).

**4. Connection to earlier batches.** This is the concrete reason for finding **A5** (C2): the
`EscOutput` boot-arm hold is anchored to the *first `setThrottle()` call*, **not** to
construction — precisely because construction happens here, in static init, "long before
`setup()` attaches the PWM." If the 2 s timer started at construction, it could partly (or fully)
elapse before the ESC ever saw a neutral pulse. Global lifetime *forced* that design.

**5. Common beginner misunderstanding.** "The objects come alive when `setup()` runs." No — they
are fully constructed *before* `setup()`. `setup()` doesn't create them; it *initializes their
hardware* (attaches pins, opens UARTs). Two separate moments: construction (automatic, pre-setup)
and hardware attach (explicit, in setup).

**6. What could go wrong on real hardware.** A classic embedded bug is the *static init order
fiasco* — a global whose constructor depends on another global that hasn't been constructed yet.
C10 sidesteps it by making constructors trivial (just store references/configs) and doing all the
real work — anything order-sensitive — in `setup()`. On a reset or brownout mid-drive, **all
globals are reconstructed from scratch**: FSM back to Safe, ESC hold restarts, `controls` back to
neutral, and (side effects) the gear resets to 1 and the ERS store refills to 100 % (INFERRED
from the defaults).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** the objects exist,
construct in file order, and the file links. **PROVISIONAL:** the runtime brownout behaviour
(does the ESC also reboot? does the 1000 µF rail cap prevent the brownout at all?) is ch03/bench.

---

## Concept 3 — Module composition (wiring the seams)

**1. Beginner explanation.** "Composition" means assembling small independent pieces into a whole
by connecting their inputs and outputs. Each C1–C9 module was built with **seams** — interfaces
like `IPwmOutput`, `IClock`, `ICharIO`, `ISettingsStore` — so it could be tested with a fake.
C10 is where each seam finally gets its *real* implementation plugged in, by **constructor
injection**: you pass the real object into the module when you build it.

**2. Why it matters in embedded systems.** This is what let ~half the firmware be tested on a
laptop with no ESP32 (C1's whole premise). The pure module doesn't know or care whether it's
driving a real LEDC channel or a mock — it just calls `pwm_.setPulseMicroseconds(...)`. C10
decides "on the real car, that seam is an `Esp32LedcPwm`." Same logic, real hardware, zero change
to the tested code.

**3. C10 code.** The output chain shows injection clearly (lines 88–98):
```cpp
outputs_hal_esp32::Esp32LedcPwm steeringPwm(pinmap::kSteeringServoPin, /*channel=*/0);
outputs::ServoOutput steering(steeringPwm, steeringConfig);   // real PWM injected

outputs::EscOutput esc(escPwm, clock, escConfig);              // real PWM + real clock injected
```
In tests (C2) the same `ServoOutput` took a `MockPwmOutput`; the `EscOutput` took a `FakeClock`.
C10 swaps in `Esp32LedcPwm` and `Esp32MillisClock` (the one-line `millis()` adapter, Concept 4 of
C1's IClock).

**4. Connection to earlier batches.** Every "PROVISIONAL until C10 — pin injected by main.cpp"
note from C4/C8 was about exactly this moment: C4 could verify the CRSF UART's *baud* but not
which *pins* main.cpp would inject; C10 shows `Esp32CrsfUart(kCrsfUartRxPin=16, kCrsfUartTxPin=17)`
— resolving the note. Composition is where "the module is correct" (tested) meets "the module is
wired to the right hardware" (C10).

**5. Common beginner misunderstanding.** "C10 contains the real logic." No — C10 contains almost
*no* logic; it's wiring. The gearbox math, the CRC, the failsafe state machine — all of that
lives in the libraries and was tested there. If you're looking for *how* something works, read
the module doc; if you're looking for *how it's connected*, read C10.

**6. What could go wrong on real hardware.** Composition bugs are wiring bugs: the wrong pin, two
outputs sharing an LEDC channel, a config injected into the wrong module. C10 defends against
these at *compile time* — every config is `static_assert(valid())`-ed at its definition site, and
the five LEDC channels are hand-numbered 0–4 (distinct). A truly *wrong-but-valid* pin (e.g. a
typo that's still a real GPIO) would only show up on the bench (open question #5 for the channel
map, D8 for pins).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** every seam is plugged
with the correct real implementation and the injected pins match `PinMap.hpp`/CLAUDE.md §1; the
whole graph type-checks and links. **PROVISIONAL:** that the pins are physically wired to what the
map says, and that the map matches the real transmitter (#5, D8).

---

## Concept 4 — Startup sequence (the order of `setup()`)

**1. Beginner explanation.** `setup()` does its jobs in a deliberate order. First the input/sensor
`begin()`s (UARTs, ADC, Hall), then — critically — it **attaches each PWM pin with an explicit
safe pulse**, then it issues the first logical command to each output. The order is chosen so that
at *every instant* during boot, the outputs are in a safe state.

**2. Why it matters in embedded systems.** Between power-on and "fully running," a vehicle spends
a second or two in a fragile in-between state. If an output pin floats, or momentarily commands
full throttle, or the ESC arms on a garbage pulse, you can get a lurch — dangerous with a real
motor. Ordering the startup so outputs are *always* safe removes that window.

**3. C10 code (lines 178–190).**
```cpp
// Attach PWM with an explicit safe initial pulse so outputs never depend on ordering.
steeringPwm.begin(steeringConfig.centerMicros);   // 1500 us center
escPwm.begin(escConfig.neutralMicros);            // 1500 us neutral
drsPwm.begin(drsConfig.closedMicros);             // 1000 us closed
// ...
steering.setPosition(0);
esc.setThrottle(0);   // first-ever call: STARTS the 2 s boot-arm hold
drs.setOpen(false);
```

**4. Connection to earlier batches.** Two review findings meet here:
- **A4** (C2 §5): `Esp32LedcPwm::begin(initialPulse)` attaches the pin *and immediately commands
  a pulse* — because LEDC otherwise idles at duty 0 (**no pulses at all**), and a servo with no
  pulses is undefined. C10 supplies the *policy*: each channel's first pulse is its safe position.
- **A5** (C2): `esc.setThrottle(0)` here is the first `setThrottle` ever, so it anchors the boot
  hold *now* — not at construction.

**5. Common beginner misunderstanding.** "The two blocks (PWM `begin` then `setPosition/
setThrottle`) are redundant." They overlap deliberately (belt-and-suspenders), but they're not
identical: `begin` writes raw µs directly through the HAL; `setPosition(0)`/`setThrottle(0)` go
through the *scaling* layer (and `setThrottle(0)` has the side effect of starting the ESC hold).
Both paths land on the same safe µs, from two angles.

**6. What could go wrong on real hardware.** If the ESC's own arming beep expects a clean run of
neutral pulses and the firmware instead delivered a glitch, the ESC might refuse to arm (or arm
into a non-neutral state). Whether the real Hobbywing ESC arms on this exact 1500 µs/2 s sequence
is open question #29 (D8 — one bench session budgeted just for ESC characterization).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** the safe-pulse-first
ordering exists and each output's initial pulse is its safe config value; the ESC hold anchors on
the first command (module-test-pinned). **PROVISIONAL:** that the real ESC actually arms on it.

---

## Concept 5 — Boot-safe outputs

**1. Beginner explanation.** "Boot-safe" means: from the instant of power-on, every actuator sits
in a position that can't hurt anything — steering centered, throttle at neutral (motor off), DRS
wing closed — and it *stays* there until the firmware has positive proof it should do otherwise.

**2. Why it matters in embedded systems.** Power-on is exactly when you have the *least*
information: no radio frame yet, sensors not seeded, the ESC not armed. The only safe default is
"do nothing." A system that defaults to "last commanded" or "whatever the pin floats to" is
unsafe at boot.

**3. C10 code.** Boot-safety is layered, not one line. The initial pulses (Concept 4) plus the
snapshot default (line 144):
```cpp
link2::ControlSnapshot controlSnapshot;   // C8 defaults: failsafe=true, throttle 0, armed false
```
and the FSM's boot state `Safe` (C1) all conspire so that before anything is proven, outputs are
neutral and the reported state is "failsafe."

**4. Connection to earlier batches.** This pulls together *four* separately-designed defaults:
LEDC safe pulse (A4, C2), ESC neutral hold (A5, C2), FSM `State::Safe` + "unconditionally invalid
until first frame" (A1, C1), and `ControlSnapshot{failsafe = true}` (C8). None of them alone is
"boot safety" — C10 is where you see they *stack*.

**5. Common beginner misunderstanding.** "One of these mechanisms is the boot-safety feature." No
— it's the *combination*. Even if the ESC hold somehow didn't apply, the FSM would still be Safe;
even if the FSM were Active, the ArmGate would still be disarmed. Defense in depth: multiple
independent layers each sufficient to keep the motor off.

**6. What could go wrong on real hardware.** The dangerous scenario is any single mechanism
silently failing *and* the others not covering it. C10's layering is designed so no single failure
un-safes the boot. The residual risk is electrical: a floating pin *before* `setup()` runs (during
static init, before `begin()`) — but no PWM is attached then, so the pin is a plain GPIO input, not
driving a servo. Confirmed safe in the Wokwi SILENT phase (Concept 9) and D8 Phase 1.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + module tests):** the four
layers exist and each is individually test-pinned. **PROVISIONAL:** that they produce a visibly
safe car at power-on on real silicon (the SILENT sim phase and D8 smoke test).

---

## Concept 6 — Failsafe authority

**1. Beginner explanation.** "Authority" answers: *who gets to decide whether the motor may run?*
The `FailsafeStateMachine` is one of the two authorities. It watches the radio link and outputs a
single verdict — `Active` (link healthy) or `Safe` (link lost) — and when it says `Safe`, the
control tick forces every output to its safe position, no matter what the sticks say.

**2. Why it matters in embedded systems.** On an RC vehicle the #1 hazard is losing the radio
link while the throttle is open — the car would run away. Safety-critical systems concentrate that
decision in *one* small, heavily-tested place (the FSM) rather than scattering "is the link okay?"
checks everywhere. One authority, one verdict, one place to audit.

**3. C10 code (lines 311–312, and the Safe branch 340–348).**
```cpp
const failsafe::State state = failsafeStateMachine.update(
    nowMs, rcFrameSinceTick, crsfReceiver.rxSignalsFailsafe());
// ...
if (state == failsafe::State::Safe) {
    steering.setPosition(0);
    esc.setThrottle(0);
    drs.setOpen(false);
    // snapshot: failsafe = true
}
```

**4. Connection to earlier batches.** C1 built and tested the FSM in isolation (boot-Safe, the A1
"never Active before a real frame" latch, 500 ms timeout, 150 ms re-arm). C4 built the receiver
that supplies its two inputs. C10 is the wiring the FSM's header explicitly anticipated ("call
every loop tick") — and the CrsfReceiver header stressed that its `linkUp()` is "NOT the actuation
authority: the FailsafeStateMachine remains the sole decider." C10 honours that: `linkUp()` is
never consulted for gating; only the FSM's `state` gates outputs.

**5. Common beginner misunderstanding.** "The receiver decides failsafe" or "if `linkUp()` is
false the motor stops." No — the receiver *reports*; the FSM *decides*. They can even disagree
briefly (the FSM has its own latch and re-arm confirmation). Only the FSM's `state` reaches the
gating expression.

**6. What could go wrong on real hardware.** The FSM assumes the receiver actually signals link
loss the way ELRS is documented to (a burst of LQ=0 stats, then silence). If the real RP1 behaves
differently — keeps sending hold-position frames, or takes longer to declare loss — the *timing*
of the drop-to-safe changes. That's why the RP1's link-loss behaviour (#26 "No Pulses" mode, #27
burst characterization) is a bench must-verify.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C1/C4 tests):** the FSM is
the sole gate; both its inputs are wired; the Safe branch forces all outputs neutral every tick.
**PROVISIONAL:** the real-world *latency* (≈540 ms worst case is derived, not measured) and the
RP1's actual signalling.

---

## Concept 7 — ArmGate authority

**1. Beginner explanation.** The ArmGate is the *second* authority. Even when the link is healthy
(FSM `Active`), the motor still may not run unless the ArmGate says `armed`. Arming requires two
things: the arm switch ON **and** the throttle stick seen at neutral at least once since the last
disarm. This is the "no arm-into-full-throttle" rule.

**2. Why it matters in embedded systems.** "Link healthy" is not the same as "the operator intends
to drive." You want a deliberate arm action, and you never want the motor to jump to life the
instant conditions allow if the stick happens to be pushed. Two authorities (link-health AND
operator-intent) must *both* agree before power flows.

**3. C10 code (lines 318–328).**
```cpp
const bool armed = armGate.update(controls.armSwitch, controls.throttle,
                                  /*forceDisarm=*/state == failsafe::State::Safe);
// ...
const bool active = state == failsafe::State::Active;
const int16_t baseCommanded = (active && armed) ? modeShaped : 0;   // BOTH must agree
```
That last line is the whole safety composition: throttle is the shaped value **only if** FSM
Active AND ArmGate armed; otherwise `0`.

**4. Connection to earlier batches.** C5 built and tested the ArmGate but stressed it "does not
command any output — it returns a bool; C10 must act on it." C10 acts on it *here*, in that one
`baseCommanded` line — resolving C5's central PROVISIONAL. Note also `forceDisarm = (state ==
Safe)`: the FSM's verdict feeds *into* the ArmGate, so a failsafe episode clears the arm latch —
the two authorities are chained, not merely parallel.

**5. Common beginner misunderstanding.** "Flipping the arm switch arms the car." Not by itself —
the throttle must *also* be at neutral (and must have been seen at neutral since the last disarm).
Flip the switch with the stick pushed and the motor stays off until you center the stick. That's
the fresh-neutral rule (Concept 8), and it's deliberate.

**6. What could go wrong on real hardware.** If the arm channel is mapped to the wrong switch, or
its polarity is reversed (a "mix" on the transmitter that never crosses the −250 threshold), the
gate could be effectively always-armed or never-armable. This is open question #5 / D8 Phase 4 —
literally a bench check of the arm switch before anything else.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C5 tests):** the ArmGate
runs every tick, is fed the FSM verdict as `forceDisarm`, and its `armed` verdict is ANDed with
Active to gate throttle. **PROVISIONAL:** that the physical arm switch maps and polarizes correctly.

---

## Concept 8 — Disarmed vs failsafe (two different "motor off" states)

**1. Beginner explanation.** Both stop the motor, but they are different situations:
- **Disarmed** = the link is fine, but the operator hasn't armed (switch off, or throttle not yet
  seen at neutral). Steering still works, DRS still works, telemetry flows normally.
- **Failsafe (Safe)** = the link is *lost*. Everything is forced to its safe position —
  steering re-centered, DRS closed, throttle neutral — and the state is reported as failsafe.

**2. Why it matters in embedded systems.** They demand different behaviour. A disarmed car is a
*working* car you simply haven't armed — you want to steer it around the bench, aim the camera,
read its battery. A failsafed car has *lost communication* — you want maximum safety and a clear
"I've lost the link" signal to downstream systems (board #2's hazard lights). Conflating them
would either over-restrict a healthy car or under-react to a lost link.

**3. C10 code.** The Active branch (disarmed-but-linked) keeps steering/DRS live:
```cpp
} else {   // state == Active (link healthy) — armed OR disarmed
    steering.setPosition(controls.steering);   // steering LIVE while disarmed
    const int16_t commanded = ersSystem.applyBoost(baseCommanded); // baseCommanded is 0 if disarmed
    esc.setThrottle(commanded);
    drs.setOpen(controls.drsSwitch);           // DRS LIVE while disarmed
}
```
vs the Safe branch, which zeroes *everything* (Concept 6).

**4. Connection to earlier batches.** C5 noted "steering stays live while disarmed — CLAUDE.md
6.2 gates throttle *only*." C10 implements exactly that split: in the Active branch throttle is
gated (via `baseCommanded`) but steering/DRS are not. The Safe branch is the C1/CLAUDE.md 2.4
posture. Two branches, two meanings.

**5. Common beginner misunderstanding.** "Disarmed and failsafe are the same — motor's off either
way." The motor is off in both, yes, but *steering and DRS are live when disarmed and dead in
failsafe*, and the reported state differs (armed/failsafe flags). Board #2 reacts differently
(engine idle vs hazard blink). They are genuinely distinct states.

**6. What could go wrong on real hardware.** A subtle one: while **disarmed but link-Active in
mode 2 (ERS)**, `ersActive` is true and `baseCommanded` is 0 (coast band), so if the wheels are
turning the ERS *harvests* (store trickles up). Harmless, but surprising on the bench — "why is
the energy bar rising when I'm not driving?" (INFERRED in C10; wheels must be turning). Not a
fault, but a behaviour to expect.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** the two branches exist
with the correct output sets; steering/DRS live in Active, all-zero in Safe. **PROVISIONAL:** the
felt behaviour on the bench (does a disarmed car steer as expected? does DRS flap harmlessly?).

---

## Concept 9 — Before-first-frame behavior

**1. Beginner explanation.** When the car powers on, it may not have received a *single* valid
radio frame yet (transmitter off, still binding, out of range). The firmware must be completely
safe in this "never heard anything" state — and it must not *mistake* silence for a healthy link.

**2. Why it matters in embedded systems.** A naive design infers link health from timestamps: "the
last frame was less than 500 ms ago, so we're fine." At boot, `lastFrameMs_` is 0 and `nowMs` is
small, so `now - last < 500` is *accidentally true* — the car would think the link is up before
any frame arrived. That exact bug (a boot-time full-lock) was review finding **A1**.

**3. C10 code + the module it relies on.** C10 feeds the FSM `rcFrameSinceTick`; the FSM's own
latch does the work (C1 header):
```cpp
// FailsafeStateMachine: everReceivedFrame_ latches true on the first valid frame, never resets.
// Until then the link is UNCONDITIONALLY invalid — cannot report Active before a real frame.
```
And `controls` is all-neutral until the first decode (line 57, `driveMode = 1` = Gearbox).

**4. Connection to earlier batches.** This is A1 (C1) meeting `Controls`' defaults (C5) meeting
the snapshot default (C8). C10 wires them so the *whole program* is safe pre-frame: FSM Safe,
outputs neutral, snapshot reports failsafe, decode hasn't run so `controls` is neutral.

**5. Common beginner misunderstanding.** "No frames = timeout = failsafe, same as losing the
link." Almost — but the *mechanism* differs. Losing a link uses the timeout (500 ms since the last
frame). Never *having* a link uses the `everReceivedFrame_` latch (unconditionally invalid). The
distinction matters because a timeout needs a "last frame" to time out *from*; before the first
frame there is none. The Wokwi SILENT phase demonstrates both: first cycle = never-received;
later cycles = timeout.

**6. What could go wrong on real hardware.** If the latch weren't there, a car could arm-and-run
at boot before the operator's transmitter even connected — the A1 disaster. It *is* there and
tested, so the residual risk is only whether the real receiver's first-frame timing matches
expectations (bench).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C1 tests):** the FSM
cannot report Active before a real frame; C10 wires it and keeps `controls`/snapshot neutral
pre-frame. **PROVISIONAL:** the visible boot-silent behaviour on silicon (SILENT sim phase, D8).

---

## Concept 10 — Packet-loss behavior (the frame-timeout path)

**1. Beginner explanation.** Radio frames arrive ~50 times a second when the link is healthy. If
they *stop* arriving — car drives behind an obstacle, transmitter dies — the firmware detects the
silence via a **timeout**: "no valid RC frame for 500 ms ⇒ declare link loss ⇒ go Safe."

**2. Why it matters in embedded systems.** On a one-way-ish link you can't ask "are you still
there?" — you can only notice that the expected steady stream has stopped. A timeout turns
"absence of data" into a concrete, actionable event. Choosing the threshold (500 ms) trades
responsiveness against false alarms on a briefly marginal link.

**3. C10 code.** C10 accumulates frame arrivals and hands them to the FSM once per tick:
```cpp
// per pass, in the UART drain:
rcFrameSinceTick |= frameArrived;
// per 50 Hz tick:
const failsafe::State state = failsafeStateMachine.update(nowMs, rcFrameSinceTick, ...);
rcFrameSinceTick = false;   // consume
```
The FSM records the arrival time internally and compares `now - lastFrameMs_` to 500 ms.

**4. Connection to earlier batches.** The FSM's timeout logic and the 500 ms default are C1. C10
supplies the *arrival events*: `rcFrameSinceTick` accumulates "≥1 RC frame since the last tick"
across possibly several loop passes (Concept 14 on the two flags). The Wokwi `TIMEOUT_OUTAGE`
phase (15–17.5 s) demonstrates exactly this path — pure silence, **no** LQ=0 — showing the ~0.5 s
*delayed* drop, distinct from the instant LQ path (Concept 11).

**5. Common beginner misunderstanding.** "Failsafe is instant when frames stop." No — the
timeout path is deliberately *delayed* by up to ~500 ms (plus tick quantization → ≈540 ms worst
case, C10 §4.8). That delay is intentional: it prevents a single dropped frame or a 100 ms
marginal blip from cutting the motor. The *other* path (LQ=0, Concept 11) is the instant one.

**6. What could go wrong on real hardware.** If a misconfigured receiver keeps sending
*hold-position* frames during an outage, the frame stream never stops, so the timeout **never
fires** — the car would keep driving on stale commands. That failure mode is precisely why the
second, independent LQ=0 path exists (Concept 11, finding A8). The timeout alone is not enough.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C1 tests):** the timeout
inputs are wired; the FSM computes it. **PROVISIONAL:** the real drop *timing* (derived ≈540 ms,
not measured) and whether the RP1 actually goes silent on loss (#27).

---

## Concept 11 — LQ=0 latch behavior (the second, instant loss signal)

**1. Beginner explanation.** ELRS receivers send a small "link statistics" frame ~10×/second. It
carries **LQ** (link quality, 0–100 %). When the receiver decides the link is lost, it sends a
short burst of stats with **LQ = 0**. The firmware *latches* on LQ=0 — once seen, the failsafe
flag stays set and clears **only** when a stats frame with LQ > 0 arrives. RC frames alone can
never clear it.

**2. Why it matters in embedded systems.** This is the answer to Concept 10's failure mode. If the
receiver keeps emitting hold-position RC frames during an outage (no timeout fires), the LQ=0
stats still say "link's gone" — and this path drops the car **instantly**, despite fresh RC
frames. Two independent loss signals cover each other's blind spots.

**3. C10 code.** C10 reads the latched flag each tick and feeds it to the FSM alongside the
timeout:
```cpp
const failsafe::State state = failsafeStateMachine.update(
    nowMs, rcFrameSinceTick, crsfReceiver.rxSignalsFailsafe());  // <- the LQ=0 latch
```
The latch itself lives in the receiver (C4):
```cpp
bool rxSignalsFailsafe() const { return everLinkStats_ && linkStats_.uplinkLinkQuality == 0; }
```

**4. Connection to earlier batches.** The latch is finding **A8** (C4): it clears *only* on LQ>0
stats, never on RC frames and never on staleness — so a hold-position-frame receiver can't clear
it. C10 is the wiring the C4 header pointed at ("Feeds the FSM's `rxFailsafeFlag`; wiring is C10").
The Wokwi `HOLD_POSITION_FAILSAFE` phase (19–21 s) — LQ=0 stats *while RC frames keep flowing at
50 % throttle* — is called "D7's most valuable demonstration": instant drop despite fresh frames.

**5. Common beginner misunderstanding.** "A good RC frame means the link recovered." No — recovery
requires a stats frame with **LQ > 0**. This is why the sim (and the real receiver) must send
*stats before RC* on recovery (C10 §5.5): if RC came first, the latch would stay set for up to
100 ms even though frames were flowing. The latch trusts *stats*, not *frames*.

**6. What could go wrong on real hardware.** The whole path assumes the RP1 actually emits the
LQ=0 burst on loss and doesn't, say, just go silent (which the timeout would then catch instead).
The receiver's real behaviour — burst count, timing, whether "No Pulses" mode is set (#26) — is
unmeasured (#27). If the RP1 were set to "Set Position" (hold) mode *and* didn't send LQ=0, both
paths could be defeated — the reason #26 is a hard bench requirement.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C4 tests):** the latch is
wired to the FSM as an independent signal; either signal forces Safe. **PROVISIONAL:** the RP1's
real LQ signalling (#26/#27).

---

## Concept 12 — Drive modes (the 3-position switch policy)

**1. Beginner explanation.** A 3-position switch selects one of three "feels": **0 = Training**
(one fixed gentle throttle shape, gear paddles have no output effect), **1 = Gearbox** (the
virtual gearbox — the default), **2 = Gearbox + ERS** (gearbox plus the deployable energy boost).
There is deliberately **no raw pass-through** mode.

**2. Why it matters in embedded systems.** The modes let one car be a gentle learner's toy or a
full-power racer via a switch. The "no pass-through" choice is a safety/feel decision: top gear
(cap 1000, expo 0) *already is* full power, and keeping authority **monotone** along the switch
means a bumped switch changes power by one gentle step, never a cliff from "gentle" straight to
"raw full."

**3. C10 code (lines 323–325, the policy in one ternary).**
```cpp
const int16_t modeShaped =
    (controls.driveMode == 0)
        ? gearbox::shapeThrottle(controls.throttle, kTrainingGearParams)  // Training: fixed {400,50}
        : virtualGearbox.apply(controls.throttle);                        // Gearbox (1 and 2)
```
Modes 1 and 2 both call `virtualGearbox.apply()`; the ERS difference is applied *later* (Concept
13), not here.

**4. Connection to earlier batches.** C6 proved the gearbox and ERS were **mode-agnostic
mechanisms** and explicitly marked the mode→behaviour mapping "PROVISIONAL — the wiring is C10."
C10 *is* that wiring, and it matches C6's anticipated table exactly. Training uses the **free
function** `shapeThrottle` (C6) with fixed params, bypassing the stateful gearbox entirely.

**5. Common beginner misunderstanding.** "In Training mode the gear paddles do nothing." They do
nothing to the *output* (Training ignores the gearbox's shaped value), but the paddles still call
`virtualGearbox.shiftUp/Down()`, so the gearbox's internal gear *and the displayed gear* change.
Flip back to Gearbox mode and you're in whatever gear you paddled to (INFERRED in C10). Surprising,
not a bug.

**6. What could go wrong on real hardware.** If the drive-mode channel is unmapped or absent, it
decodes to **1 = Gearbox** (the safe default, C5) — so a missing switch gives plain gearbox, not
chaos. But if the switch is mapped to the *wrong* channel, you could get Training when you wanted
ERS or vice versa — a bench mapping check (#5).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** the three modes are
wired exactly as C6 anticipated, with no pass-through; absent channel → mode 1. **PROVISIONAL:**
the *feel* (is Training gentle enough? is the monotone step smooth?) — bench tuning.

---

## Concept 13 — Gearbox / ERS composition (the throttle pipeline)

**1. Beginner explanation.** The commanded throttle flows through a pipeline, in order:
raw stick → **mode-shape** (gearbox or Training) → **arm-gate** (zero unless armed+Active) →
**ERS boost** (multiply up if deploying). Each stage is a separate module; C10 chains them in the
right sequence so the safety gate can't be bypassed.

**2. Why it matters in embedded systems.** *Order is a safety property.* The boost must come
**after** the arm gate — because the gate produces 0 when disarmed, and ERS boost is purely
multiplicative (`applyBoost(0) == 0`), so boosting a gated-to-zero value stays zero. Put the boost
*before* the gate and a held boost switch could inject throttle into a disarmed car. Composition
order is not cosmetic.

**3. C10 code (lines 323–356).**
```cpp
const int16_t modeShaped = (driveMode==0) ? shapeThrottle(...) : virtualGearbox.apply(throttle);
const int16_t baseCommanded = (active && armed) ? modeShaped : 0;        // GATE
ersSystem.update(nowMs, active && driveMode==2, baseCommanded, wheelSpeed.rpm(), ...);  // pre-boost value
// ... in Active branch:
const int16_t commanded = ersSystem.applyBoost(baseCommanded);          // BOOST after gate
esc.setThrottle(commanded);
```

**4. Connection to earlier batches.** C6 built the gearbox, `shapeThrottle`, and the ERS with its
**hard invariant** `applyBoost(0) == 0` (test-pinned) and its rule that `update()` must be called
**every tick in every mode** with the *post-arm-gate, pre-boost* throttle. C10 satisfies every one
of those contracts literally: ERS is updated every tick, `ersActive = active && driveMode==2`, the
throttle argument is `baseCommanded` (post-gate, pre-boost), and boost is applied after.

**5. Common beginner misunderstanding.** "ERS is only relevant in mode 2, so skip `update()` in
other modes." No — the C6 contract (honoured by C10) calls `update()` *every* tick in *every*
mode. Outside mode 2, `ersActive` is false, so the store *freezes* and its internal clock
re-seeds — which means reactivation never sees a huge `dt` gap. Skipping the call would break that.

**6. What could go wrong on real hardware.** The gearbox's brake/reverse pass-through (C6: `x ≤ 0`
passes unshaped) is only safe if the ESC is in **forward/brake** mode, not forward/reverse — else
"reverse" would be ungoverned by the gearbox. That's an ESC configuration bench task (#29). The
composition is correct; the *ESC mode assumption* underneath it is the hardware risk.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C6 tests):** the pipeline
order (shape → gate → boost), the every-tick ERS update, `ersActive` formula, and the
post-gate/pre-boost throttle are all wired exactly to C6's contracts. **PROVISIONAL:** the ESC's
forward/brake mode, and the felt behaviour of deploy/harvest on the real motor.

---

## Concept 14 — Telemetry scheduling (5 Hz CRSF up the downlink)

**1. Beginner explanation.** The car sends data *back* to the ground (battery, speed, gear/mode/
ERS) as standard CRSF frames out UART2 TX, which the RP1 relays over the air. C10 does this at
**5 Hz** (every 200 ms), building three frames: battery (0x08), GPS/groundspeed (0x02), and a
FLIGHTMODE status string (0x21) like `"G3 M2 E55"`.

**2. Why it matters in embedded systems.** These values change slowly and a HUD only needs a few
updates per second, so 5 Hz is plenty — and it keeps the shared UART2 TX quiet (that same pad is
also used by... nothing inbound; TX and RX are separate pads, so telemetry never collides with RC
parsing). Scheduling telemetry *slower* than control is a deliberate bandwidth/priority choice.

**3. C10 code (lines 260–295).**
```cpp
if (nowMs - lastTelemetryMs >= kTelemetryPeriodMs) {   // 200 ms = 5 Hz
    lastTelemetryMs = nowMs;
    const uint16_t mv = batteryMonitor.batteryMv();
    if (mv > 0) { /* build + write battery frame, mV->dV via mv/100 */ }
    // GPS frame: mm/s -> 0.1 km/h via (mmPerSec * 36) / 1000
    // FLIGHTMODE: snprintf("G%u M%u E%u", displayGear, driveMode, ersPercent)
}
```

**4. Connection to earlier batches.** The frame builders are C4's `CrsfFrameBuilder` (the
"test/simulation support" side — the production firmware "only ever parses," and indeed the
control loop never builds an *RC* frame, only telemetry). Big-endian payloads were resolved back
in C4. The `mv > 0` guard leans on C7 (`batteryMv()` is 0 until the first sample).

**5. Common beginner misunderstanding.** "The car reports its link quality up to the ground." No —
uplink LQ is measured by the *ground* TX module itself; the car sends nothing for it. The car only
reports what *it* knows: battery, wheel speed, and the car-authoritative gear/mode/ERS (which the
ground can't infer without drift — the reason the FLIGHTMODE string exists).

**6. What could go wrong on real hardware.** Telemetry is best-effort and non-safety — a dropped
telemetry frame just means a momentarily stale HUD. The real risk is upstream: whether the RP1
actually relays these frames and the ground station decodes them (that's the ground-station
batches + #47 for HUD precedence). The unit math (mV→dV, mm/s→0.1 km/h ×36/1000) is arithmetic
C10 verified by hand.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C4 tests):** the three
frames are built with correct types/units at 5 Hz and written to TX. **PROVISIONAL:** that the
RP1 relays them and the ground decodes them (ground batches, #47).

---

## Concept 15 — link2 scheduling (20 Hz to board #2)

**1. Beginner explanation.** The control board sends the whole vehicle state to the sound/light
board (ESP32 #2) over a one-way UART at **20 Hz** (every 50 ms). C10 fills a `ControlSnapshot`
and calls `link2Sender.send()`. Crucially, it sends **unconditionally** — even during failsafe.

**2. Why it matters in embedded systems.** On a one-way link, *silence is ambiguous*: board #2
can't tell "the wire is cut" from "nothing changed." So the sender must keep transmitting at a
steady rate; board #2 runs a 500 ms dead-man timer and only declares link loss if the *stream*
stops. Sending continuously — including in failsafe — is what makes that timer meaningful. If the
control board went quiet *on purpose* during failsafe, board #2 couldn't distinguish it from a
dead wire.

**3. C10 code (lines 377–388) + the Safe-branch comment.**
```cpp
if (nowMs - lastLink2TickMs >= kLink2PeriodMs) {   // 50 ms = 20 Hz
    lastLink2TickMs = nowMs;
    controlSnapshot.lowBattery = batteryMonitor.lowVoltageWarning();
    controlSnapshot.displayGear = virtualGearbox.currentGear() + 1;
    // ... rpm, batteryMv, ersPercent, ersDeploying, driveMode ...
    link2Sender.send(controlSnapshot);
}
```
And the reason there's no early return in the Safe branch: *"link2 below must keep transmitting
during failsafe — that flag is its whole purpose."*

**4. Connection to earlier batches.** C8 built the sender, the 14-byte frame, the brake-light
hysteresis, and stressed that reported throttle is **what the ESC was actually commanded** (0 in
failsafe/disarm) "so engine sound tracks the motor, not the stick." C10 wires that: the snapshot's
`commandedThrottle` is literally the value passed to `esc.setThrottle()`. C10 also resolves C8's
"always sends in failsafe" — a design review had removed an early-return that would have silenced
it (ROADMAP D6); C10 §4.8 shows the Safe branch falling through to the link2 block.

**5. Common beginner misunderstanding.** "In failsafe the car stops talking to board #2." The
*opposite* — that's exactly when board #2 most needs to hear "failsafe = true" (to blink hazards,
drop the engine to idle). The snapshot in the Safe branch sets `failsafe = true` and zeroes the
outputs, and the 20 Hz send carries it.

**6. What could go wrong on real hardware.** The whole thing assumes board #2 receives and decodes
this stream correctly — which requires board #2's copy of `lib/link2` to be byte-identical
(documented as a verbatim copy). Verifying that copy hasn't drifted is the S1 diff-verify; the
cross-board wire behaviour is bench. C10 proves only the *sender* side.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C8 tests):** 20 Hz
cadence, unconditional send (incl. failsafe), commanded-throttle reporting, snapshot field
sourcing. **PROVISIONAL:** board #2's decoding + the physical wire (S1, bench).

---

## Concept 16 — Settings load / apply / save lifecycle

**1. Beginner explanation.** In the **tuning build**, bench-adjustable settings (steering trim,
battery calibration, gear feel) live in NVS flash and flow like this: at boot, **load** the saved
blob and **apply** it to the live modules; while running, `set` edits RAM and `save` writes flash
on demand. C10 is where "load" and "apply" get called, and where "apply" is defined.

**2. Why it matters in embedded systems.** Calibration must survive power-off (flash) but the
control loop must read it fast (RAM). So there are two copies and a defined lifecycle: flash → RAM
at boot, RAM → modules on any change, RAM → flash only on explicit `save`. C10 orchestrates the
boot end of that; C9b built the mechanism.

**3. C10 code (lines 158–162 apply, 196–197 boot load).**
```cpp
void applyTuning() {   // push RAM settings into the three live modules
    steering.setConfig(consoleRunner.settings().steering);
    virtualGearbox.setConfig(consoleRunner.settings().gearbox);
    batteryMonitor.setConfig(consoleRunner.settings().battery);
}
// in setup():
consoleRunner.loadAtBoot();   // NVS blob -> C9a guard chain -> settings or defaults
applyTuning();                // push into modules BEFORE loop() runs
```

**4. Connection to earlier batches.** `loadAtBoot()` runs C9a's never-brick guard chain (length →
CRC → version → valid()), falling back to `kDefaults` on any failure — resolving C9b's
"boot-lifecycle is C10" note. `applyTuning()` is the "apply loop" C9b anticipated: exactly three
`setConfig()` calls (the three tunables), which are pure config-copies that reset no state (the
C9b test `test_gearbox_setconfig_clamps_current_not_reset` pinned that ESC arm anchor + current
gear survive).

**5. Common beginner misunderstanding.** "`set` saves my change" or "settings apply themselves."
No — `set` is RAM-only (C9b); `applyTuning()` pushes RAM into the modules; only `save` writes
flash. Three separate steps. And apply happens *before* `loop()` at boot, and again immediately
whenever `poll()` reports a change (Concept 17).

**6. What could go wrong on real hardware.** The load path assumes real NVS returns the saved
bytes and that a version-bump + reflash correctly falls back to defaults (#34a) — untestable on a
laptop. **And the big finding (Concept 18/§8):** this entire block is compiled *out* of the gift
build, so a delivered car never loads NVS at all — it runs compiled-in defaults (#49).

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C9 tests):** in the tuning
build, boot loads + applies before loop, and apply is three `setConfig`s. **PROVISIONAL:** real
NVS persistence (#34a); and the gift build's lack of a load path is a *resolved-negatively*
finding, not a proof of loading (#49).

---

## Concept 17 — Console / tuning lifecycle (the runtime edit loop)

**1. Beginner explanation.** In the tuning build, a bench operator types commands over USB serial
(`get`/`set`/`save`/`load`/`reset`/`status`/`help`). C10 polls the console **every loop pass**,
non-blocking, and when a command changes settings it immediately re-applies them to the modules.
The console refuses to *change* settings while the car is armed.

**2. Why it matters in embedded systems.** You want to tune a car *live* on the bench without
recompiling — but tuning a *moving, armed* car mid-drive could change its behaviour dangerously.
So mutations are gated on DISARMED ("pit-lane only"), and the polling must be non-blocking so
typing never stalls the 50 Hz control loop.

**3. C10 code (lines 226–228).**
```cpp
if (consoleRunner.poll(armGate.isArmed())) {   // per pass; armed = the TRUE arm state
    applyTuning();                              // re-push on any change
}
```

**4. Connection to earlier batches.** C9b built the console + runner and the DISARMED gate, but
could only prove the console *obeys* the `armed` flag — it couldn't verify the flag's *source*.
C10 supplies it: `armGate.isArmed()`, the very same gate whose verdict gates the motor. That
resolves C9b's central PROVISIONAL. The `poll()` is C9b's non-blocking drain-and-return.

**5. Common beginner misunderstanding.** "The console reads the arm state itself." No — `armed` is
*passed in* by C10. And note the consequence: during a failsafe episode `forceDisarm` clears the
gate → `isArmed()` is false → the console would *accept* mutations. Consistent, because a
failsafed car is as parked as a disarmed one (outputs forced safe).

**6. What could go wrong on real hardware.** UART0 serial at 115200 must actually read/write typed
lines, tolerate CRLF, and trip the flood guard on overlong input (#34b) — none exercised on a
laptop. And this whole block, like Concept 16, exists **only** in the tuning build.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build + C9b tests):** per-pass
non-blocking poll fed the true arm state; immediate re-apply on change. **PROVISIONAL:** real UART0
behaviour (#34b).

---

## Concept 18 — Simulation / tuning compile flags (conditional compilation)

**1. Beginner explanation.** The *same* `main.cpp` produces three different firmwares, selected by
**compile-time flags**. `#ifdef NAME … #endif` keeps the enclosed lines **only if** the symbol
`NAME` is defined, and the build defines it with a `-DNAME` compiler flag. Code inside an
undefined `#ifdef` isn't "skipped at runtime" — it **does not exist** in the binary at all.

**2. Why it matters in embedded systems.** You want the shipped ("gift") firmware to be lean and
surface-free — no debug serial, no tuning console — while still developing with those tools. Flags
let one source tree yield a demo build (Wokwi feeder), a bench build (console), and a clean gift
build, with the extra code *physically absent* from the gift image, not merely disabled.

**3. C10 code + `platformio.ini`.**
```cpp
#ifdef W17_SIM_CRSF_FEEDER
    simfeeder::tick(nowMs);        // only in esp32dev_sim
#endif
#ifdef W17_TUNING_CONSOLE
    if (consoleRunner.poll(armGate.isArmed())) applyTuning();   // only in esp32dev_tuning
#endif
```
```ini
[env:esp32dev_sim]
build_flags = ${env:esp32dev.build_flags}   -DW17_SIM_CRSF_FEEDER
```
The `${...}` interpolation is **mandatory**: a child's `build_flags` *replaces* the parent's, so
without pasting the parent flags back you'd silently lose `-std=gnu++17 -Wall -Wextra`.

**4. Connection to earlier batches.** C9b introduced `W17_TUNING_CONSOLE` conceptually ("compiled
out of the gift firmware"); C10 shows it *is* an `#ifdef` around the includes, objects, and calls.
Even the `#include`s are conditional, so PlatformIO's Library Dependency Finder doesn't even
*link* the settings libraries into the plain build.

**5. Common beginner misunderstanding.** "The gift firmware has the console, it's just turned
off." No — it's **not compiled in**. The gift build contains *no settings/console code whatsoever*.
This is stronger than a runtime disable and has a sharp consequence (Concept 16/§8).

**6. What could go wrong on real hardware — the §8 finding.** Because *every* settings line is
behind `W17_TUNING_CONSOLE`, the gift build (`esp32dev`) has **no NVS load path**. A blob saved
during bench tuning *persists in flash* but is **never read** by the delivered firmware — it runs
compiled-in defaults. D8's "reflash plain `esp32dev` — the NVS-saved tuning persists" is literally
true but *functionally discards the tuning*. This is **open question #49** (deliver options: bake
tuned values into source defaults / ship the tuning build / add a load-only path). Also worth
knowing: CI builds `esp32dev` and `esp32dev_sim` but **not** `esp32dev_tuning`, so the tuning
build could silently rot in CI's eyes.

**7. What C10 proves / what's PROVISIONAL.** **Proven (source + build):** the three flags select
three real, buildable firmwares (all three built SUCCESS 2026-07-05); the gift build has no
settings code. **PROVISIONAL:** none of the *conditional* logic runs in CI's gift build — the
sim/tuning paths are verified by building, and by the sim/bench respectively.

---

## Concept 19 — What native tests prove (and the `main.cpp` blind spot)

**1. Beginner explanation.** "Native tests" compile the pure modules for your laptop and run them
with no ESP32. C10's verification ran the whole suite — **147/147 PASSED** (2026-07-05) — covering
every module's behaviour. But `main.cpp` itself is **never compiled into the test binary**
(`test_build_src = no`), so *no test executes `setup()` or `loop()`.*

**2. Why it matters in embedded systems.** This is the honest boundary of C10. The 147 tests prove
every *piece* is correct; a clean build proves the *wiring* type-checks and links. Neither proves
the *composed program behaves correctly when run* — that emergent behaviour (does failsafe
actually drop the motor at the right moment? do the cadences interleave as intended?) has no
automated test. So C10's claims are labelled "VERIFIED (source + build)," a weaker guarantee than
earlier batches' "VERIFIED (ran)."

**3. C10 code — `platformio.ini` [env:native] (the enforcement).**
```ini
test_build_src = no          ; never compile src/main.cpp (it includes Arduino.h) into tests
lib_ignore =                 ; belt-and-suspenders: hard-exclude the esp32-only HAL libs
    crsf_hal_esp32
    outputs_hal_esp32
    telemetry_hal_esp32
    link2_hal_esp32
    settings_hal_esp32
```

**4. Connection to earlier batches.** This finally *names* the mechanism behind a phrase used
since C2 — "excluded from the native tests." It's two mechanisms: `test_build_src = no` (skip
`src/`) and `lib_ignore` (drop the five HAL libs), so a test that mistakenly included a HAL header
would fail loudly. Every "HAL file excluded from native tests → PROVISIONAL/hardware" note in
C2/C4/C7/C8/C9b traces to these lines.

**5. Common beginner misunderstanding.** "147 tests pass, so the firmware works." No — 147 tests
prove the *modules* work; the *integration* is unproven by tests. "Green suite ≠ working car."
The integration tier is the Wokwi sim (Concept 20) and the bench, not the native suite.

**6. What could go wrong on real hardware.** A wiring bug that *compiles* — a swapped argument, a
mis-ordered cadence, a subtly wrong `#ifdef` — would pass all 147 tests and build cleanly, yet
misbehave on the car. That class of bug is exactly what the sim and bench exist to catch. C10's
line-by-line reading is the manual's best defense against them short of running the sim.

**7. What C10 proves / what's PROVISIONAL.** **Proven:** every module behaviour (147/147) + the
whole file builds. **PROVISIONAL:** everything about the *running composition* — no test touches
`loop()`.

---

## Concept 20 — What real hardware still must prove

**1. Beginner explanation.** A lot of C10 is "correct on paper and in the build, but only silicon
can confirm." The remaining unknowns cluster into: the Wokwi sim first-run (platform facts) and
the D8 bench bring-up (electrical/timing reality).

**2. Why it matters in embedded systems.** Perfect logic and a clean build never guarantee the
*physical* layer: that the ESC arms, servos center, the 420 k UART decodes, NVS persists, the ADC
reads true, Hall edges are clean, the radio link behaves. The last mile is always the bench.

**3. C10 references (the sim as the designed integration test).** `SimCrsfFeeder`'s 10-phase
script (which C10 confirmed **matches SIMULATION.md's table exactly**, resolving #48) is the
intended proof that the *composed* firmware behaves — each phase targets one property: SILENT
(boot-safe), ARM_BLOCKED (ArmGate), TIMEOUT_OUTAGE (timeout path), HOLD_POSITION_FAILSAFE (LQ
latch), RECOVERY_2 (fresh-neutral), etc.

**4. Connection to earlier batches.** Every batch's hardware list rolls up here: ESC arming/mode
(#29, C2/C6), ADC calibration (#30, C7), Hall EMI (#31, C7), NVS persistence (#34a, C9), UART0
console (#34b, C9b), channel map vs real TX (#5, C5), RP1 failsafe mode + LQ burst (#26/#27,
C1/C4), link2 cross-board (S1). C10 doesn't *close* any of these — it collects them at the
integration boundary.

**5. Common beginner misunderstanding.** "The sim proves the car works." The sim proves the
*firmware logic* runs end-to-end against a *virtual* circuit — a huge step, but still not the real
ESC, real receiver, real ADC. And even the sim's own platform facts (does 420 k decode over the
loopback? does the pot preset the voltage?) are open questions #35–39.

**6. What could go wrong on real hardware (the ranked risks, C10 §12.5).**
1. **ESC behaviour** (#29) — boot hold length, neutral arming, forward/brake vs forward/reverse
   (load-bearing for the gearbox's brake passthrough).
2. **RP1 "No Pulses" failsafe mode** (#26/A8) — if it holds position instead, only the LQ latch
   saves the car; and the LQ burst timing (#27) is unmeasured.
3. **Channel map / arm-switch polarity** (#5) — a reversed arm channel could default to armed.
4. **420 k CRSF decode** (#36 sim / bench) — all input depends on it.
5. **The gift-build tuning gap** (#49) — not electrical, but the highest-risk *workflow*
   assumption: believing bench tuning reaches the delivered firmware when it doesn't.

**7. What C10 proves / what's PROVISIONAL.** **Proven:** the composition is coherent, builds, and
its module pieces are tested; the sim script faithfully implements the demo. **PROVISIONAL:**
literally everything electrical/timing/radio — the entire D8 checklist and Wokwi #35–39.

---

## 25 Quiz Questions

1. In the Arduino model, where is `main()`, and what two functions do you write instead? Which
   runs once and which runs forever?
2. Why is `delay()` banned in `loop()`? Name one concrete thing that would slip if a block took
   100 ms.
3. When exactly are the global module objects constructed — before or after `setup()`? What is
   that phase called?
4. Explain how global object lifetime *caused* the design of finding A5 (the ESC boot hold anchor).
5. What is "constructor injection," and give the C10 example of a real seam being plugged that a
   test had filled with a mock.
6. In `setup()`, why are the PWM pins attached with an *explicit* pulse rather than just attached?
   (Name the finding.)
7. Which single line in `setup()` starts the ESC's 2-second boot-arm hold, and why can't it start
   at construction?
8. Name the four independent layers that keep the motor off at boot. Why four instead of one?
9. Who is the *sole* authority on failsafe (Safe vs Active)? What does `CrsfReceiver::linkUp()` do,
   and what does it explicitly *not* do?
10. State the two conditions ArmGate requires to arm. What is the "fresh-neutral" rule?
11. Write the one line of `main.cpp` that combines both safety authorities into the throttle
    decision. What value does it produce when either says no?
12. Contrast "disarmed" and "failsafe": in which one are steering and DRS still live?
13. Before the first radio frame ever arrives, why can't the FSM report Active? (Name the finding
    and the latch.)
14. Describe the frame-timeout failsafe path. Roughly how delayed is it, and why is that delay
    deliberate?
15. Describe the LQ=0 latch path. What clears it, and what can *never* clear it? Which failure mode
    does it cover that the timeout can't?
16. On recovery, why must LINK_STATISTICS (LQ>0) be sent *before* the first RC frame?
17. List the three drive modes. What does mode 0 (Training) use instead of the stateful gearbox,
    and why is there deliberately no raw pass-through mode?
18. In Training mode you press gear-up twice. What changes and what doesn't? What surprise awaits
    when you switch to Gearbox mode?
19. In the throttle pipeline, why must ERS boost be applied *after* the arm gate? Which test-pinned
    invariant makes that safe?
20. Why does `ersSystem.update()` get called *every* tick in *every* mode, not just mode 2?
21. At what rate does the car send CRSF telemetry, and what three frame types? Why doesn't the car
    report its own uplink LQ?
22. At what rate does link2 send to board #2, and does it send during failsafe? Why is sending
    during failsafe essential on a one-way link?
23. Trace the tuning build's boot: which two calls load and apply settings, and in what order
    relative to `loop()`? What does `applyTuning()` actually do?
24. What does `test_build_src = no` mean, and why does it mean `main.cpp` has no automated test?
    What *do* the 147 tests prove, then?
25. The gift build is flashed after bench tuning per D8. What settings does the delivered car
    actually run, and why? Name the three delivery options (open question #49).

---

## Answer Key

1. The framework supplies a hidden `main()`; you write **`setup()`** (runs once at boot) and
   **`loop()`** (called forever). 
2. `loop()` *is* the forever-loop, called repeatedly; a `delay()` freezes all other jobs for its
   duration. A 100 ms block would push the 50 Hz control tick past its 20 ms period and slip
   failsafe detection past its 500 ms budget (and could trip the watchdog).
3. **Before** `setup()`, during **static initialization**.
4. Globals are constructed in static init, *before* `setup()` attaches the PWM — so a hold timer
   anchored at *construction* could partly/fully elapse before the ESC ever saw a neutral pulse.
   A5's fix anchors the hold to the *first `setThrottle()` call* instead.
5. Passing a module's dependency into its constructor. E.g. `ServoOutput steering(steeringPwm, …)`
   injects the real `Esp32LedcPwm`; C2's test injected a `MockPwmOutput`. (Also acceptable:
   `EscOutput`'s real `Esp32MillisClock` vs the test's `FakeClock`.)
6. Because LEDC idles at duty 0 (**no pulses at all**) until first commanded, and a servo with no
   pulses is undefined — so `begin(initialPulse)` attaches *and* commands a safe pulse. Finding
   **A4**.
7. `esc.setThrottle(0);` — the first-ever `setThrottle` call. It can't start at construction
   because construction (static init) happens before the PWM is attached (finding A5).
8. (1) No PWM attached before `setup()` (pins idle, ESC sees no pulses); (2) ESC boot-arm hold
   forces neutral for 2 s; (3) FSM boot-Safe + "unconditionally invalid until first frame" (A1);
   (4) ArmGate disarmed until switch ON + fresh neutral. Four (defense in depth) so no single
   failure un-safes the boot.
9. The **`FailsafeStateMachine`** is the sole authority. `linkUp()` is a *reporting* convenience
   for telemetry/link2; it is explicitly **not** the actuation authority and is never consulted
   for gating.
10. Arm switch ON **and** throttle seen at neutral (|throttle| ≤ 60) at least once since the last
    disarm. Fresh-neutral: after *any* disarm (switch off or failsafe episode), neutral must be
    re-observed before the motor may run — so a recovery mid-stick-input can't snap the motor on.
11. `const int16_t baseCommanded = (active && armed) ? modeShaped : 0;` — it produces **0** when
    either the FSM is not Active or the ArmGate is not armed.
12. In **disarmed** (link Active), steering and DRS are live (throttle gated to 0). In **failsafe
    (Safe)**, *all* outputs are forced neutral/closed.
13. The FSM's `everReceivedFrame_` latch stays false until the first valid frame, making the link
    *unconditionally invalid* — so it can't infer health from timestamps (`now - last < 500` is
    accidentally true at boot). Finding **A1**.
14. "No valid RC frame for 500 ms ⇒ Safe." It's delayed by up to ~500 ms (≈540 ms worst case with
    tick quantization). The delay is deliberate: it prevents a single dropped frame or a brief
    marginal blip from cutting the motor.
15. The receiver latches on a stats frame with LQ=0; it clears **only** on a stats frame with
    LQ>0, and **never** on RC frames (or staleness). It covers the misconfigured-receiver case
    where hold-position RC frames keep flowing (no timeout) but the link is dead — instant drop.
16. Because the latch clears *only* on good stats; if RC came first on recovery, the latch would
    stay set (and the car stay Safe) for up to ~100 ms even though frames were flowing.
17. **0 = Training, 1 = Gearbox, 2 = Gearbox+ERS.** Training uses the free function
    `shapeThrottle` with fixed `{400, 50}` params (bypassing the stateful gearbox). No raw
    pass-through because top gear already *is* full power, and keeping authority monotone along
    the switch means a bump changes power by one gentle step, never a cliff.
18. The gearbox's internal gear (and the *displayed* gear) advance, but the *output* is unchanged
    (Training ignores the gearbox). Surprise: switch to Gearbox mode and you're in whatever gear
    you paddled to.
19. Because the arm gate produces 0 when disarmed, and `applyBoost` is purely multiplicative with
    the invariant **`applyBoost(0) == 0`** (test-pinned) — so boosting after the gate can't inject
    throttle into a disarmed car. Boost *before* the gate could.
20. The C6 contract: calling every tick keeps the ERS clock re-seeding so reactivation never sees
    a huge `dt` gap; outside mode 2 (or in failsafe) the store *freezes* rather than skipping the
    call.
21. **5 Hz** (200 ms); battery (0x08), GPS/groundspeed (0x02), FLIGHTMODE status (0x21). Uplink LQ
    is measured by the ground TX module itself — the car sends nothing for it.
22. **20 Hz** (50 ms); yes, it sends during failsafe. On a one-way link, silence is
    indistinguishable from a cut wire, so a steady stream (with `failsafe=true` in the snapshot)
    lets board #2's 500 ms dead-man work.
23. `consoleRunner.loadAtBoot()` (NVS → guard chain → settings/defaults) then `applyTuning()`,
    both in `setup()` *before* `loop()`. `applyTuning()` calls `setConfig()` on exactly three
    modules — steering, gearbox, battery.
24. It tells PlatformIO never to compile `src/` (which includes `Arduino.h`) into the test binary
    — so no test can execute `setup()`/`loop()`. The 147 tests prove every *module's* behaviour;
    the *composition* is unproven by tests (source + build only).
25. It runs the **compiled-in defaults** — because the entire settings subsystem (load path
    included) is behind `#ifdef W17_TUNING_CONSOLE`, absent from the plain build; the saved NVS
    blob persists but is never read. Options (#49): (a) transcribe tuned values into source
    defaults and rebuild plain; (b) ship the `esp32dev_tuning` build; (c) add a load-only NVS path
    to the plain build.

---

## Things I should review before standardization

- **The two safety authorities and their single composition line** (Concept 6, 7, 11): FSM
  (Safe/Active) AND ArmGate (armed) → `baseCommanded = (active && armed) ? modeShaped : 0`. This
  is the heart of the firmware; be able to recite it and explain each half.
- **The boot-safety stack** (Concept 5, 9): four independent layers, none sufficient to remove,
  each individually tested. Know what each covers.
- **Disarmed vs failsafe** (Concept 8): same "motor off," different steering/DRS/reporting. A
  frequent conflation.
- **The two loss signals** (Concept 10, 11): timeout (delayed, needs a "last frame") vs LQ=0
  latch (instant, covers hold-position receivers). Know which sim phase demonstrates each.
- **The throttle pipeline order** (Concept 13): shape → gate → boost, and *why* boost-after-gate
  is a safety property (`applyBoost(0)==0`).
- **Compile-flag architecture and the §8 finding** (Concept 18, 16): three builds from one source;
  the gift build has *no* settings code, so bench tuning doesn't reach it (#49). This is the most
  important *new* fact C10 surfaced.
- **The evidence boundary** (Concept 19, 20): "source + build" vs "ran"; 147 tests prove modules,
  not the composition; the sim + bench are the integration tier. Carry this humility into every
  C10 claim.
- **Which earlier PROVISIONALs C10 resolved** (C10 §11 table): 20+ items across C4–C9b — so the
  standardization pass can upgrade those tags consistently.

## "Ready for standardization?" checklist

Tick honestly. If any is shaky, re-read the linked concept (and, if useful,
`10_main_integration.md`) before the standardization pass.

- [ ] I can explain `setup()` vs `loop()` and why no block may ever `delay()` or busy-wait.
- [ ] I can say when globals are constructed and why that forced the ESC-hold-at-first-call design
      (A5).
- [ ] I can explain constructor injection and point to one seam C10 fills with real hardware that
      a test filled with a mock.
- [ ] I can list the boot startup order and the two review findings it satisfies (A4, A5).
- [ ] I can name the four boot-safety layers and explain "defense in depth."
- [ ] I can identify the FSM as the sole failsafe authority and explain why `linkUp()` is not it.
- [ ] I can state ArmGate's two arm conditions and the fresh-neutral rule.
- [ ] I can write the `baseCommanded` line and explain what happens when either authority says no.
- [ ] I can distinguish disarmed from failsafe by what stays live.
- [ ] I can explain the before-first-frame latch (A1) and why timestamp-only inference is a bug.
- [ ] I can contrast the timeout path and the LQ=0 latch path, and name the sim phase for each.
- [ ] I can explain why stats must precede RC on recovery.
- [ ] I can list the three drive modes, Training's use of `shapeThrottle`, and the no-pass-through
      rationale.
- [ ] I can explain the throttle pipeline order and why boost-after-gate is a safety property.
- [ ] I can explain why ERS updates every tick in every mode.
- [ ] I can state the telemetry (5 Hz) and link2 (20 Hz) cadences and why link2 sends in failsafe.
- [ ] I can trace the settings load→apply lifecycle at boot and the console poll→apply loop.
- [ ] I can explain the three compile flags and the §8 gift-build finding (#49).
- [ ] I can state precisely what the 147 native tests prove and what they don't (the `main.cpp`
      blind spot).
- [ ] I can name the top hardware bring-up risks and which open questions track them.

When most boxes are ticked, the C10 material is solid enough to carry into **manual
standardization** — the campaign's next phase.

---

*This is a study companion; it changes no source and reads no soundlight/ground-station file. The
authoritative line-by-line explanation remains `10_main_integration.md`.*
