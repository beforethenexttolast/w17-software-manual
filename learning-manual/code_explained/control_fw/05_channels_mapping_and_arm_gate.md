# C5 — Channels: Mapping + Arm Gate

**Batch C5 of the source-code campaign** (see `../../source_code_explanation_plan.md`).
C4 gave us *raw* 16 CRSF channels (172…1811 each). C5 turns them into **named, normalized
controls** (`ChannelDecoder`) and implements the **arm-switch safety gate** (`ArmGate`) —
CLAUDE.md §6.2's non-negotiable "no arm-into-full-throttle."

**A safety framing to hold throughout this batch (important):** *neither class in C5
commands any output.* `ChannelDecoder::decode` returns a `Controls` data struct; `ArmGate::
update` returns a `bool`. The actual "force throttle to neutral when disarmed," "center
steering," "apply a gear shift" happen in `main.cpp` (batch **C10**), which *uses* these
results. So everywhere below, "blocks throttle" really means "reports disarmed, and C10
must act on it." I mark the wiring **PROVISIONAL** wherever a safety outcome depends on
C10, hardware, or the ESC.

> **C10 resolution note (2026-07-05).** C10 read `main.cpp` and the wiring PROVISIONALs of
> this doc are now source-verified (see `10_main_integration.md` §11): decode runs on every
> new frame **including during failsafe**; gear edges are consumed in the same pass;
> `ArmGate.update` runs every control tick with `forceDisarm = (state == Safe)`; disarmed ⇒
> `baseCommanded = 0` ⇒ ESC commanded neutral (the A3 motor-side outcome); steering stays
> live while disarmed; and the firmware uses the **default** `ChannelMapConfig{}`,
> `static_assert`-ed at its definition site. Still open: whether those defaults match the
> real transmitter (open question #5, D8 Phase 4) — that's bench, not wiring.

## Scope (files explained here)

| File | Lines | What it is |
|---|---|---|
| `lib/channels/include/channels/ChannelDecoder.hpp` | 113 | Config, `Controls` struct, decoder class (declaration) |
| `lib/channels/src/ChannelDecoder.cpp` | 111 | Normalization, hysteresis, tri-state, edge detection |
| `lib/channels/include/channels/ArmGate.hpp` | 48 | The arm-switch gate (declaration) |
| `lib/channels/src/ArmGate.cpp` | 24 | …the latch logic |
| `test/test_channels/test_main.cpp` | 373 | 21 tests (decoder + arm gate) |

**Prerequisites:** C3/C4 (raw CRSF channels, `RcChannelsFrame`, the 172/992/1811 anchors),
C1 (failsafe FSM — for the `forceDisarm` link), C2 (the ESC's µs mapping — for what
"throttle" and "brake" mean downstream). I reference these, not re-explain them.

**Test status: RUN AND PASSING.** `pio test -e native -f test_channels` on 2026-07-03 →
**21/21 PASSED** (1.6 s). Behaviours marked **VERIFIED** are backed by that run.

---

## 0. Where C5 sits in the control chain

```mermaid
flowchart LR
  RCV["CrsfReceiver.channels() (C4)<br/>16 raw values 172..1811"] -->|decode()| DEC["ChannelDecoder (§1-4)<br/>→ Controls (named, ±1000)"]
  DEC -->|"controls.armSwitch, .throttle"| GATE["ArmGate (§5)<br/>→ armed? (bool)"]
  FSM["FailsafeStateMachine (C1)"] -->|"Safe ⇒ forceDisarm=true"| GATE
  DEC -->|"controls.steering/throttle/gearEdges/driveMode/..."| MAIN["main.cpp (C10)<br/>gates + commands outputs"]
  GATE -->|"armed"| MAIN
  MAIN -->|"if armed: throttle→gearbox→ESC (C2/C6)"| ESC["ESC / servos"]
```

The single most important thing this picture says: **the arm gate and the failsafe FSM
are advisory**; the *decision to move the motor* is assembled in C10 from `armed`,
`failsafe`, and the shaped throttle. C5 computes the inputs to that decision.

---

## 1. `ChannelDecoder.hpp` — the config and the output shape

### Lines 12–52: `ChannelMapConfig` — which raw channel is which control
```cpp
struct ChannelMapConfig {
    uint8_t steeringIndex = 0; // ch1
    uint8_t throttleIndex = 2; // ch3
    uint8_t armIndex = 4;      // ch5 ...
    uint8_t drsIndex = 5;      // ch6
    uint8_t gearUpIndex = 6;   // ch7, momentary
    uint8_t gearDownIndex = 7; // ch8, momentary
    uint8_t panIndex = 8;      // ch9
    uint8_t tiltIndex = 9;     // ch10
    uint8_t boostIndex = 10;   // ch11
    uint8_t overtakeIndex = 11;// ch12
    uint8_t driveModeIndex = 12;// ch13, 3-pos
    bool invertSteering = false; ... bool invertTilt = false;
    int16_t switchOnAbove = 250;
    int16_t switchOffBelow = -250;
    constexpr bool valid() const { ... }
};
```
- **The mapping is a config table** (as CLAUDE.md §2.2 required, "easy to re-map"). Each
  field is a **0-based** raw channel index: `chN` on the transmitter = index `N-1`. So the
  defaults are steering ch1, throttle ch3, arm ch5, DRS ch6, gearUp ch7, gearDown ch8,
  pan ch9, tilt ch10, boost ch11, overtake ch12, drive-mode ch13.
- **These defaults are PLACEHOLDERS.** The comment is blunt: "DEFAULTS ARE PLACEHOLDERS
  per CLAUDE.md §3 ('verify against my TX') — confirm every assignment at the bench and
  remap HERE only." So the *code* is VERIFIED to use these indices; whether they match the
  actual transmitter is **PROVISIONAL** — a bench task tracked in `open_questions.md` #5
  and D8 Phase 4. **VERIFIED** (defaults) / **PROVISIONAL** (that they're the right pins).
- **The four `invert*` bools** flip a normalized axis's sign — a bench convenience for a
  reversed transmitter axis or a backwards camera direction. Default false. **VERIFIED.**
- **`switchOnAbove = 250` / `switchOffBelow = -250`** are the **hysteresis thresholds** on
  the normalized ±1000 scale: a switch reads ON above +250, OFF below −250, and *holds its
  previous state in between* — so a value hovering near a threshold can't chatter. A 2-pos
  CRSF switch sits near ±1000, so it crosses both thresholds cleanly. **VERIFIED** (used in
  §2 `decodeSwitch`).
- **`valid()` — which indices are policed, and which aren't (safety-relevant):**
  ```cpp
  return steeringIndex < kNumChannels && throttleIndex < kNumChannels &&
         armIndex < kNumChannels && drsIndex < kNumChannels &&
         gearUpIndex < kNumChannels && gearDownIndex < kNumChannels &&
         switchOnAbove > switchOffBelow;
  ```
  - It checks that steering, throttle, arm, DRS, gearUp, gearDown are real indices (< 16),
    and that the thresholds are ordered. A bad index here fails the **compile** (via
    `static_assert` at the config's definition site in C10) — "a wrong index must fail the
    build, not remap a control onto the wrong channel."
  - **Deliberately *not* checked:** pan, tilt, boost, overtake, driveMode. The comment
    explains: `>= kNumChannels` for those means "control absent" with *safe degraded
    behavior* (analog 0, switch OFF, drive mode Gearbox). So an absent camera or ERS
    channel is a supported, safe configuration; an absent *throttle* or *arm* is a build
    error. **This asymmetry is a safety choice**: the controls that can hurt you must
    exist; the cosmetic/optional ones may be absent. **VERIFIED** (test
    `test_config_valid_rejects_bad_values`: `throttleIndex = 16` → invalid;
    `switchOnAbove = -300` → invalid).

### Lines 54–73: `Controls` — one frame's decoded output (mind the defaults)
```cpp
struct Controls {
    int16_t steering = 0;   int16_t throttle = 0;   int16_t pan = 0;   int16_t tilt = 0;
    bool armSwitch = false; bool drsSwitch = false;
    bool boostHeld = false; bool overtakeHeld = false;
    uint8_t driveMode = 1;  // 0 Training / 1 Gearbox / 2 Gearbox+ERS; default 1
    bool gearUpEdge = false; bool gearDownEdge = false;
};
```
- Plain data. **Every default is the safe/neutral value:** analog axes 0 (centered/neutral),
  switches OFF, `driveMode = 1` (plain Gearbox — "pre-first-frame ticks and a missing
  channel equal plain gearbox"). So a freshly-constructed `Controls`, or one from a missing
  channel, is inert. **VERIFIED.**
- **`throttle` is a symmetric ±1000 analog value** — the decoder does *not* distinguish
  "forward" from "brake." Negative throttle is just a negative number here; its meaning as
  *brake* is applied downstream (C2's ESC maps <1500 µs to the brake region; C6's gearbox
  passes brake through unshaped). So in C5, "throttle" = "the throttle stick's position,"
  nothing more. **VERIFIED** (it's `normalizedAnalog`, symmetric) / the brake *meaning* is
  a C2/C6/ESC concern.
- **The edge flags are consume-on-read** (comment): `gearUpEdge`/`gearDownEdge` are true
  *only* in the `Controls` returned by the decode that observed the OFF→ON transition.
  "Act on them the same tick or lose them." So C10 must apply a gear shift immediately when
  it sees an edge. **VERIFIED** (mechanism §4) / that C10 consumes them promptly is a
  **PROVISIONAL** C10 claim.

### Lines 75–111: the class + the "call it every frame" contract
```cpp
class ChannelDecoder {
public:
    explicit ChannelDecoder(ChannelMapConfig config = ChannelMapConfig{});
    Controls decode(const crsf::RcChannelsFrame& frame);
private:
    int16_t normalizedAnalog(...);  bool decodeSwitch(..., bool& state);  uint8_t decodeTriState(...);
    ChannelMapConfig config_;
    bool firstDecodeDone_ = false;
    bool armState_ = false; bool drsState_ = false; bool boostState_ = false;
    bool overtakeState_ = false; bool gearUpState_ = false; bool gearDownState_ = false;
};
```
- It's a **stateful** decoder: it remembers each switch's ON/OFF level between calls
  (`armState_`, …) plus a `firstDecodeDone_` latch. That state is what makes hysteresis and
  edge-detection possible. **VERIFIED.**
- **The header's call-contract comment (lines 78–83) is a safety instruction to C10:**
  "Call decode() exactly once per newly received frame — including while failsafe is Safe.
  … pausing decode during a link outage would make a switch moved during the outage look
  like a fresh transition on recovery (a phantom gear change). Decode is pure; gate
  ACTUATION on failsafe, not decoding."
  - Meaning: don't stop decoding just because the car is in failsafe. Keep the switch
    levels current so no phantom edge fires on recovery. The *failsafe gating* belongs on
    the **outputs**, not on the decoder.
  - **VERIFIED**: the decoder is pure and its edges derive from level transitions.
    **PROVISIONAL**: that `main.cpp` actually calls `decode()` on every frame including in
    failsafe — that's C10 wiring (ROADMAP D2 records the intent: "main.cpp: decode on every
    frame (phantom-edge-proof)").

---

## 2. `ChannelDecoder.cpp` — normalization + switch/tri-state helpers

### Lines 5–28: `normalizeRaw` — raw 172…1811 → ±1000 (exact at the anchors)
Inside an **anonymous namespace** (file-local; first seen in C4 §6.1):
```cpp
int16_t normalizeRaw(uint16_t raw) {
    constexpr int32_t kLowSpan  = crsf::kChannelRawCenter - crsf::kChannelRawMin;  // 992-172 = 820
    constexpr int32_t kHighSpan = crsf::kChannelRawMax - crsf::kChannelRawCenter;  // 1811-992 = 819
    const int32_t centered = static_cast<int32_t>(raw) - crsf::kChannelRawCenter;  // raw - 992
    const int32_t normalized =
        (centered >= 0) ? (centered * 1000) / kHighSpan : (centered * 1000) / kLowSpan;
    if (normalized > 1000)  return 1000;
    if (normalized < -1000) return -1000;
    return static_cast<int16_t>(normalized);
}
```
This is **piecewise-linear** with *two different divisors*, because the CRSF range is
slightly asymmetric: the low half is 820 raw units (172→992) and the high half is 819
(992→1811). A single divisor couldn't hit *both* −1000 and +1000 exactly. So:
- **`centered = raw − 992`** shifts so center is 0.
- **positive side** (`centered ≥ 0`): `centered * 1000 / 819`. At raw 1811, `819*1000/819 =
  1000` exactly.
- **negative side**: `centered * 1000 / 820`. At raw 172, `−820*1000/820 = −1000` exactly.
- **Widen-before-multiply** again (`int32_t`): `centered * 1000` can be ~±1,055,000, which
  overflows 16 bits but fits 32.
- **Integer division truncates toward zero**, which the comment notes "biases toward
  neutral — the safe direction." Worked micro-examples (VERIFIED by
  `test_normalization_truncates_toward_neutral`):
  - raw 991 → centered −1 → `−1*1000/820 = −1.21 → −1` (truncated toward 0).
  - raw 993 → centered +1 → `+1*1000/819 = 1.22 → 1`.
  So one raw unit off center gives ±1, and the rounding always shrinks magnitude — never
  *inflates* a command. **VERIFIED (ran).**
- **Out-of-range clamp:** the 11-bit field can carry 0…2047 (wider than the nominal
  172…1811). A zero-initialized channel (raw 0) computes to `−992*1000/820 ≈ −1209`, clamped
  to **−1000**; raw 2047 → ~+1288 → **+1000**. So garbage never escapes ±1000. **VERIFIED**
  (`test_normalization_clamps_out_of_range_raw`). This matters for safety: a corrupt/zero
  frame decodes to a bounded value, and (per below) the arm gate + failsafe still gate it.

### Lines 34–41: `normalizedAnalog` — apply index + invert, handle absent
```cpp
int16_t ChannelDecoder::normalizedAnalog(const frame&, uint8_t index, bool invert) const {
    if (index >= crsf::kNumChannels) return 0; // control absent
    const int16_t value = normalizeRaw(frame.channels[index]);
    return invert ? static_cast<int16_t>(-value) : value;
}
```
- **Absent index (≥ 16) → 0** (neutral). "Never silently remapped" — an out-of-range index
  reads as centered, not as some other channel. **VERIFIED** (`test_invalid_index_means_
  control_absent`: pan index 255, every real channel pegged high → pan decodes 0).
- **Invert** negates the normalized value. **VERIFIED** (`test_invert_flags_flip_analog_sign`,
  `test_pan_tilt_decode_and_invert`).

### Lines 43–65: `decodeSwitch` — hysteresis + first-decode seeding
```cpp
bool ChannelDecoder::decodeSwitch(const frame&, uint8_t index, bool& state) const {
    if (index >= crsf::kNumChannels) { state = false; return state; } // absent → OFF
    const int16_t value = normalizeRaw(frame.channels[index]);
    if (!firstDecodeDone_) {                 // first ever: SEED from level, fire no edge
        state = value > config_.switchOnAbove;
        return state;
    }
    if (value > config_.switchOnAbove)      state = true;
    else if (value < config_.switchOffBelow) state = false;
    // in between: hold previous state (hysteresis)
    return state;
}
```
- **`bool& state`** — a *reference parameter* (C1 §3.2): the caller passes one of the
  persistent members (`armState_`, …) and `decodeSwitch` reads-and-updates it in place. So
  one function serves all switches, each with its own memory.
- **Absent switch → OFF** (safe). **VERIFIED** (`test_absent_mode_and_boost_channels_
  degrade_safely`: boost index 255 → `boostHeld` false).
- **First decode seeds** the level without firing: a switch parked ON at boot reads ON
  immediately (values inside the ±250 band seed OFF). This is why a car powered on with the
  DRS switch already up shows `drsSwitch == true` on frame 1 — but (§4) *no gear edge* fires
  from a parked gear switch. **VERIFIED** (`test_first_decode_seeds_levels_and_fires_no_edges`).
- **Hysteresis:** ON above +250, OFF below −250, hold in between. **VERIFIED**
  (`test_switch_hysteresis_on_off_and_hold_in_band`: OFF→ON→(mid holds ON)→OFF→(mid holds
  OFF)).

### Lines 67–79: `decodeTriState` — the drive-mode 3-position switch
```cpp
uint8_t ChannelDecoder::decodeTriState(const frame&, uint8_t index) const {
    if (index >= crsf::kNumChannels) return 1; // absent → Gearbox (safe middle)
    const int16_t value = normalizeRaw(frame.channels[index]);
    if (value < -333) return 0;   // Training
    if (value >  333) return 2;   // Gearbox+ERS
    return 1;                     // Gearbox (includes exactly ±333)
}
```
- A **stateless** level classifier — no hysteresis, no seeding — because "a real 3-pos
  switch never dwells between detents." Low → 0 (Training), high → 2 (Gearbox+ERS), middle
  (and absent, and exactly ±333) → 1 (Gearbox). **The thresholds are strict** (`<`/`>`), so
  the boundaries −333 and +333 resolve to the middle. **VERIFIED**
  (`test_drive_mode_tri_state_positions` and `test_drive_mode_boundaries_are_exclusive`,
  which pins raw 718 → −334 → 0, raw 719 → −332 → 1, raw 1265 → 333 → 1, raw 1266 → 334 →
  2). Note the **safety default is the *middle*** (Gearbox), never the highest-power mode.

### Lines 81–109: `decode` — assemble one `Controls`, detect gear edges
```cpp
Controls ChannelDecoder::decode(const crsf::RcChannelsFrame& frame) {
    Controls out;
    out.steering = normalizedAnalog(frame, config_.steeringIndex, config_.invertSteering);
    out.throttle = normalizedAnalog(frame, config_.throttleIndex, config_.invertThrottle);
    out.pan = normalizedAnalog(frame, config_.panIndex, config_.invertPan);
    out.tilt = normalizedAnalog(frame, config_.tiltIndex, config_.invertTilt);

    out.armSwitch  = decodeSwitch(frame, config_.armIndex, armState_);
    out.drsSwitch  = decodeSwitch(frame, config_.drsIndex, drsState_);
    out.boostHeld  = decodeSwitch(frame, config_.boostIndex, boostState_);
    out.overtakeHeld = decodeSwitch(frame, config_.overtakeIndex, overtakeState_);
    out.driveMode  = decodeTriState(frame, config_.driveModeIndex);

    const bool gearUpWas = gearUpState_;
    const bool gearDownWas = gearDownState_;
    const bool gearUpNow = decodeSwitch(frame, config_.gearUpIndex, gearUpState_);
    const bool gearDownNow = decodeSwitch(frame, config_.gearDownIndex, gearDownState_);

    if (firstDecodeDone_) {
        out.gearUpEdge = gearUpNow && !gearUpWas;      // OFF->ON only
        out.gearDownEdge = gearDownNow && !gearDownWas;
    }
    firstDecodeDone_ = true;
    return out;
}
```
- Analog axes and switches are decoded straightforwardly. **Steering and throttle are
  decoded unconditionally** — the decoder has no notion of "armed"; that gating is C10's job
  (ROADMAP D2: "steering live while disarmed"). **VERIFIED** (decode is unconditional).
- **Edge detection** (the careful bit): capture the *old* level (`gearUpWas`) **before**
  `decodeSwitch` updates `gearUpState_`, then `edge = now && !was` (an OFF→ON transition of
  the hysteresis-filtered state). Only when `firstDecodeDone_` — the first decode seeds
  levels and must fire no edge. **VERIFIED** (`test_exactly_one_edge_per_transition`: one
  edge on OFF→ON, none while held, none on ON→OFF, another on a fresh OFF→ON).
- **`firstDecodeDone_ = true` at the end** flips the latch after the first call. **VERIFIED.**

---

## 3. The failsafe / outage interaction, stated precisely

Because the brief flags "failsafe interaction," here is exactly what the decoder does and
doesn't do:

- **The decoder never reads failsafe state.** It just decodes whatever frame it's given.
- **It should be run on every received frame, even while the FSM says Safe** (e.g. the
  hold-position case from C4, where LQ=0 but frames still arrive). Reason: its switch
  levels must stay current so recovery doesn't produce a phantom OFF→ON gear edge. This is a
  **C10 obligation** (ROADMAP D2 confirms main.cpp does it); the decoder merely makes it
  *possible* by being pure and level-based. **VERIFIED** (purity) / **PROVISIONAL** (C10
  actually calls it every frame).
- **During a true outage there are no frames**, so `decode` isn't called and levels freeze
  at their last value — which is the correct behaviour (nothing to update). The design point
  is only about *not artificially pausing* decode when frames *are* arriving.
- **Gating outputs on failsafe is done elsewhere** (C10, using the FSM state and `ArmGate`),
  never inside the decoder.

---

## 4. `ArmGate` — the "no arm-into-full-throttle" latch

### `ArmGate.hpp`
```cpp
struct ArmGateConfig { int16_t neutralWindow = 60; }; // |throttle| <= this counts as neutral

class ArmGate {
public:
    explicit ArmGate(ArmGateConfig config = ArmGateConfig{});
    bool update(bool armSwitchOn, int16_t normalizedThrottle, bool forceDisarm);
    bool isArmed() const { return seenNeutralSinceEnable_; }
private:
    ArmGateConfig config_;
    bool seenNeutralSinceEnable_ = false; // doubles as the armed flag
};
```
- The rule (header + CLAUDE.md §6.2): **armed ⇔ arm switch ON *and* throttle observed at
  neutral at least once since the last disarm.** `neutralWindow = 60` = ~6% of half-travel
  (stick-centering slop + a little trim).
- **One member does double duty:** `seenNeutralSinceEnable_` *is* the armed flag — set only
  while the switch is on and no disarm holds, cleared by any disarm. So `isArmed()` is just
  "have we seen neutral since we were enabled and not been disarmed since." **VERIFIED.**

### `ArmGate.cpp` — the whole logic (13 lines)
```cpp
bool ArmGate::update(bool armSwitchOn, int16_t normalizedThrottle, bool forceDisarm) {
    if (!armSwitchOn || forceDisarm) {          // (1) any disarm condition
        seenNeutralSinceEnable_ = false;
        return false;
    }
    if (!seenNeutralSinceEnable_) {             // (2) not yet armed: look for neutral
        const int16_t magnitude =
            normalizedThrottle >= 0 ? normalizedThrottle : static_cast<int16_t>(-normalizedThrottle);
        if (magnitude <= config_.neutralWindow) seenNeutralSinceEnable_ = true;
    }
    return seenNeutralSinceEnable_;             // (3) armed == latch
}
```
Read in three steps, exactly as the header documents:

1. **Disarm has priority.** If the switch is OFF **or** `forceDisarm` is true, clear the
   latch and return disarmed — *immediately, regardless of throttle position.* `forceDisarm`
   is "named for its effect: true disarms." **VERIFIED** (`test_armgate_force_disarm_polarity`:
   `update(true, 0, true)` → false even with switch ON and stick neutral).
2. **Arming requires fresh neutral.** While not yet armed, compute `|throttle|` and, if it's
   within the neutral window (≤ 60), latch armed. **`magnitude = throttle >= 0 ? throttle :
   −throttle`** is a manual absolute value (the ternary from C2). Note this trusts the caller
   passes `throttle` in [−1000, +1000] (the header says so); it does **not** clamp — but the
   decoder (§2) already guarantees that range. **VERIFIED** (the ArmGate math);
   the [−1000,1000] precondition is upheld by `ChannelDecoder`.
3. **Once armed, stay armed** (while the switch stays on and no `forceDisarm`): step (2) is
   skipped because the latch is set, so throttle can move to full and the gate still reports
   armed. **VERIFIED** (`test_armgate_blocks_arm_into_full_throttle`: `update(true,1000,…)`
   and `update(true,800,…)` → false; then `update(true,0,…)` → true; then `update(true,1000,…)`
   → true).

**Key behaviours, each pinned by a test:**
- **No arm-into-full-throttle** — switch ON with stick displaced never arms until neutral.
  (`test_armgate_blocks_arm_into_full_throttle`.) **VERIFIED.**
- **Switch ON + neutral arms the same tick.** (`test_armgate_switch_on_with_neutral_arms_
  same_tick`.) **VERIFIED.**
- **Instant disarm on switch-off, then fresh neutral required.**
  (`test_armgate_disarms_on_switch_off_and_requires_neutral_again`.) **VERIFIED.**
- **Failsafe recovery requires fresh neutral (finding A3).** Armed and driving at 900; a
  failsafe episode (`forceDisarm=true`) disarms; when the link recovers **with the stick
  still at 900**, the gate stays disarmed until the stick returns to neutral — so, *once C10
  gates throttle on this bool*, the motor can't "snap on" mid-drive (the gate itself only
  reports disarmed). (`test_armgate_failsafe_recovery_requires_fresh_neutral`.) **VERIFIED
  (ran)** for the gate's report; the motor-side outcome is **PROVISIONAL** until C10. This is
  the same fresh-neutral rule chapter 10 §2 described, now in code.
- **Neutral while disarmed does NOT pre-arm.** Observing neutral while the switch is OFF
  doesn't set the latch (step 2 only runs when the switch is ON and not force-disarmed);
  turning the switch on later with a displaced stick is still blocked.
  (`test_armgate_neutral_while_switch_off_does_not_prearm`.) **VERIFIED.**
- **Window boundary is inclusive.** `|throttle| == 60` counts as neutral (arms); `61` does
  not; symmetric for −60/−61. (`test_armgate_neutral_window_boundary`.) **VERIFIED.**

### How this reaches the motor (the safety wiring — PROVISIONAL until C10)
`ArmGate::update` returns a bool; it moves nothing. In `main.cpp` (C10) the intended wiring
is: pass `controls.armSwitch` and `controls.throttle` in, pass `forceDisarm = (failsafe ==
Safe)`, and when the result is **disarmed, command the ESC neutral** (throttle gated to 0).
So the *safety guarantee* "a disarmed car can't drive" is only realized once C10 acts on
this bool. **VERIFIED**: the gate computes armed/disarmed correctly. **PROVISIONAL**: that
C10 forces the ESC neutral when disarmed and passes FSM-Safe as `forceDisarm`. (C1's
failsafe FSM and C2's `EscOutput` boot-hold are *additional* independent layers — chapter 10
§2's "four gates.")

---

## 5. `test_channels/test_main.cpp` — the suite (21 tests)

Structure mirrors C1/C2/C4. Helpers in an anonymous namespace:
- **`constexpr uint16_t kRawOff/kRawOn/kRawMid`** = 172 / 1811 / 992 — a switch's low, high,
  and mid (in-band) raw positions.
- **`makeFrame(fill = 992)`** builds an `RcChannelsFrame` with all 16 channels at one raw
  value (default center). The tests then poke individual channels.
- **`auto frame = makeFrame();`** — first use of **`auto`**: the compiler deduces the
  variable's type from the initializer (`crsf::RcChannelsFrame`). Purely a convenience.

Test groups (all **VERIFIED (ran)**, 21/21):
- **Normalization** (33–76): exact anchors (−1000/0/+1000), truncation toward neutral (±1),
  out-of-range clamp (raw 0 → −1000, raw 2047 → +1000).
- **Invert** (78–91): sign flip for steering/throttle (and pan/tilt at 186–203).
- **Switches/edges** (95–157): hysteresis hold-in-band; first-decode seeds levels but fires
  no edges; exactly one edge per OFF→ON transition, none while held or on ON→OFF.
- **Mapping** (159–184): custom remap works and `valid()`s; an absent (index 255) control
  decodes neutral.
- **Held switches & tri-state** (205–250): boost/overtake as held levels; drive-mode three
  positions and the exclusive ±333 boundaries.
- **Degrade-safely & config validity** (252–275): absent mode → Gearbox, absent boost →
  off; `valid()` rejects a bad index and inverted thresholds.
- **ArmGate** (279–346): the seven behaviours enumerated in §4.

No `main.cpp`, hardware, or ESP32 file is involved — the whole batch is pure logic, fully
host-tested.

---

## 6. VERIFIED / INFERRED / PROVISIONAL summary

**VERIFIED** (code + the `test_channels` run 2026-07-03):
- Normalization: piecewise-linear with 820/819 spans, exact at 172/992/1811, truncates
  toward neutral, clamps out-of-range to ±1000.
- Switch decode: ±250 hysteresis with hold-in-band; first-decode seeds levels without
  firing; absent switch → OFF; absent analog → 0; absent tri-state → 1 (Gearbox).
- Gear edges: OFF→ON only, exactly one per transition, none on the seeding decode,
  consume-on-read.
- `driveMode` tri-state: strict ±333 thresholds, middle default.
- `ChannelMapConfig::valid()` polices steering/throttle/arm/DRS/gearUp/gearDown indices +
  threshold order; leaves pan/tilt/boost/overtake/driveMode unpoliced (absent = safe).
- `ArmGate`: disarm has priority (switch-off or `forceDisarm`); arming needs `|throttle| ≤
  60`; once armed stays armed; fresh-neutral required after any disarm including failsafe
  (A3); neutral-while-disarmed doesn't pre-arm; inclusive ±60 window.

**INFERRED** (reasoning atop code/comments):
- "Truncation toward neutral is the safe direction" (the code truncates; that it's *safe* is
  the comment's rationale, sound).
- The four-independent-safety-layers framing (arm switch here; failsafe FSM in C1; ESC
  boot-hold in C2; board-2 staleness later) — assembled from the separate modules.

**PROVISIONAL** (depends on C10 / hardware / later batches):
- That the **default channel indices match the actual transmitter** — bench task (open q #5,
  D8 Phase 4).
- That `main.cpp` (a) calls `decode()` on every frame including in failsafe, (b) commands
  steering while disarmed but **gates throttle to neutral when `ArmGate` reports disarmed**,
  (c) passes `forceDisarm = (FSM == Safe)`, and (d) consumes gear edges promptly. All C10.
- The downstream *meaning* of negative throttle as "brake" (C2's ESC mapping + the ESC's
  own forward/brake config — open q #29, D8 Phase 7).

---

## 7. Cross-references (open questions & risks already on file)

- **`open_questions.md` #5** — the TX channel mapping is unverified; C5 shows the defaults
  live in `ChannelMapConfig` and are explicitly placeholders (D8 Phase 4 remaps them).
- **ROADMAP A3** (chapter 05 §1.2, chapter 10 §2) — re-arm snapping throttle to the current
  stick position; C5 shows the fix in `ArmGate` (`test_armgate_failsafe_recovery_requires_
  fresh_neutral`).
- **ROADMAP D2** (chapter 05 §1.3) — the channels module + arm gate; C5 is that module.
  D2's "decode on every frame" and "steering live while disarmed" are the C10 wiring this
  batch depends on.
- **CLAUDE.md §6.2** — non-negotiable safety #2 (no arm-into-full-throttle); `ArmGate`
  implements it.
- **C1 forward-link** — `forceDisarm` is fed from the failsafe FSM's `Safe` state (wiring in
  C10); **C2 forward-link** — the ESC boot-hold is a separate arming layer; **C6** — the
  gearbox/ERS consume `throttle`, `driveMode`, `boostHeld`, `gearUpEdge`, etc.

No new open questions surfaced by C5.

---

## 8. Understanding questions

1. `ChannelMapConfig::valid()` checks the throttle and arm indices but **not** the pan,
   boost, or drive-mode indices. Explain the safety reasoning behind treating those two
   groups differently, and what happens at build time vs run time for each.
2. Raw channel value 993 normalizes to +1, but 991 normalizes to −1 (not −2). Which two
   constants differ (and by how much), and why does the code say truncation biases "toward
   neutral, the safe direction"?
3. A car powers on with the DRS switch already flipped up and the gear-up switch already
   held. After the very first `decode()`, what are `drsSwitch`, `gearUpEdge`? Which member
   variable and which `if` make the edge answer safe?
4. `ArmGate::update(true, 900, true)` returns false. Identify which of the three steps runs,
   and explain why the throttle value (900) is irrelevant to the outcome here.
5. The arm switch is ON and you hold the stick at −900 (full brake). Does the gate arm?
   Would it arm at −40? Explain using `neutralWindow` and the absolute-value line.
6. The header says "gate ACTUATION on failsafe, not decoding," and says to keep calling
   `decode()` during failsafe. Construct the phantom-gear-change scenario that this rule
   prevents, step by step.
7. Neither `ChannelDecoder` nor `ArmGate` moves a servo or the ESC. For the statement "a
   disarmed car cannot spin its motor" to be *true*, which file (and which later batch) must
   do what with `ArmGate`'s return value? Why is that correctly marked PROVISIONAL here?
8. `decodeTriState` returns 1 for an absent channel, exactly ±333, and the middle detent.
   Why is 1 (Gearbox) the right default rather than 0 (Training) or 2 (Gearbox+ERS)?

---

*Batch C5 complete. `source_code_progress.md` updated. Awaiting approval before C6
("Feel: gearbox + ERS").*
