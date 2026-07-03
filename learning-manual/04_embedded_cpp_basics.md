# 04 — Embedded C++ Basics

The C++ and embedded-programming concepts you need to read this codebase, each taught on
a real file from the project. This is not a general C++ course — it is *this project's*
C++, which is deliberately a small, readable subset ("readable over clever",
`w17-control-fw/CLAUDE.md` §5).

## 1. How C++ code becomes a program: files, headers, includes

C++ programs are built from **translation units**: each `.cpp` file is compiled
separately into machine code, then everything is linked together. A `.hpp` (header) file
is the *published interface* — declarations other files may use — and `#include`
literally pastes its text in during preprocessing.

Project specimen: `w17-control-fw/lib/gearbox/` has
`include/gearbox/Gearbox.hpp` (what the module offers: the `GearParams` struct, the
`shapeThrottle` function, the `Gearbox` class) and `src/Gearbox.cpp` (how it works).
`src/main.cpp` does `#include "gearbox/Gearbox.hpp"` and never sees the implementation.

- `#pragma once` (first line of every header here) = "if included twice, ignore the
  second time" — prevents duplicate-definition errors.
- Includes in angle brackets (`#include <cstdint>`) are standard-library; quotes
  (`#include "gearbox/Gearbox.hpp"`) are project files.

## 2. Integer types you can trust: `<cstdint>`

Plain `int` has a platform-defined size. Embedded and protocol code needs exact widths,
so the codebase uses fixed-width types everywhere:

| Type | Meaning | Project example |
|---|---|---|
| `uint8_t` | unsigned 8-bit, 0…255 | a raw protocol byte; a GPIO number in `PinMap.hpp` |
| `int8_t` | signed 8-bit, −128…127 | `throttlePercent` in a link2 frame (−100…+100) |
| `uint16_t` | unsigned 16-bit | a raw CRSF channel (172…1811); wheel rpm |
| `int16_t` | signed 16-bit | normalized controls (−1000…+1000) |
| `uint32_t` | unsigned 32-bit | timestamps in milliseconds (`nowMs`) |
| `int32_t` | signed 32-bit | the ERS energy store (0…1,000,000) |

Signed vs unsigned matters: unsigned types wrap around (255 + 1 = 0 for `uint8_t`),
which is a feature for timestamps and a bug for arithmetic — one reason the code is
careful about which it uses where.

**Integer division truncates:** `7 / 2 == 3`. The project does *all* control math in
integers (no floating point in control paths — soundlight `CLAUDE.md` makes it an
explicit rule), so you'll see idioms like scaling up before dividing. Example: the ERS
store counts **micro-permille** (millionths of full) precisely so that
`rate × elapsed_ms` needs *no division at all* and never loses fractions
(`lib/ers/ErsSystem.hpp`, comment at `kFullMicroPermille`).

## 3. `namespace` — name fencing

```cpp
namespace pinmap {
inline constexpr uint8_t kSteeringServoPin = 13;
}
```

(`w17-control-fw/lib/config/include/config/PinMap.hpp`)

A namespace groups names so they can't collide: outside it you write
`pinmap::kSteeringServoPin`. Every module here lives in its own namespace matching its
folder: `failsafe::`, `gearbox::`, `crsf::`, `link2::`, `hal::`.

## 4. `constexpr` and `const` — "known at compile time" vs "read-only"

- `const` = this value won't change after initialization (runtime is fine).
- `constexpr` = this value/function is computable **at compile time**.

Every pin, protocol constant, and default config in this codebase is `constexpr` —
e.g. `crsf::kCrsfBaud = 420000` (`lib/crsf/CrsfFrame.hpp`), `link2::kStartByte = 0xA5`
(`lib/link2/Link2Frame.hpp`). The `k` prefix is the project's naming convention for
constants. Why compile-time matters is §6.

## 5. `struct` — grouped data, and the config pattern

A `struct` is a bundle of named fields. This project's signature use is the **config
struct with defaults**, one per module:

```cpp
struct Config {
    uint32_t linkTimeoutMs = 500;   // default member initializer
    uint32_t rearmConfirmMs = 150;
};
```

(`lib/failsafe/FailsafeStateMachine.hpp`)

The `= 500` is a *default member initializer* — a fresh `Config{}` starts with these
values. Every tunable number in the firmware lives in such a struct (never scattered
"magic numbers"), each documented with a one-line source comment — a rule from
`CLAUDE.md` §5.

## 6. `valid()` + `static_assert` — invalid config cannot compile

The pattern that makes this codebase unusual and safe:

```cpp
// in the header: a compile-time-checkable validity rule
constexpr bool valid() const {
    if (numGears < 1 || numGears > kMaxGears) return false;
    ...
}

// in main.cpp, where the actual config is defined:
static_assert(kGearboxConfig.valid(), "gearbox: bad gear table (range or non-monotonic)");
```

(`lib/gearbox/Gearbox.hpp`; `src/main.cpp`)

`static_assert` is checked **by the compiler**: if someone edits the gear table into
nonsense (say, gear 3 weaker than gear 2), the firmware *refuses to build* with that
message. No runtime check to forget, no way to flash a broken table. You'll find one
`static_assert(...valid()...)` for every config near the top of both `main.cpp` files.
(For values changed at runtime via the tuning console, the same `valid()` functions are
called at `set` time instead — same rule, two enforcement points.)

## 7. `enum class` — named states

```cpp
enum class State : uint8_t { Active, Safe };
```

(`lib/failsafe/FailsafeStateMachine.hpp`)

An `enum class` defines a type whose only values are the listed names — perfect for
state machines. `: uint8_t` fixes its storage size. Unlike old C enums, you must qualify
(`State::Safe`) and can't accidentally mix it with integers. Other examples:
`link2monitor::LinkStatus { NeverConnected, Up, Lost }`,
`enginesim::Ignition { Off, Cranking, Running }`, and the protocol decoders' result
codes (`crsf::DecodeResult`, `link2::DecodeResult`).

## 8. `class` — data + behavior + protection

A `class` is a struct whose fields default to **private** (inaccessible from outside),
exposing only chosen **public** functions. This is how state machines protect their
invariants. Sketch of the failsafe machine's shape:

```cpp
class FailsafeStateMachine {
public:
    explicit FailsafeStateMachine(Config config = Config{});
    State update(uint32_t nowMs, bool frameArrivedThisTick, bool rxFailsafeFlag);
    State state() const { return state_; }
private:
    Config config_;
    State state_ = State::Safe;       // boot-safe default
    bool everReceivedFrame_ = false;  // latches true on first frame, never resets
    uint32_t lastFrameMs_ = 0;
    ...
};
```

Reading aids:

- Trailing underscore (`state_`) = member variable (project convention).
- `explicit` on a constructor = no silent conversions from a bare `Config`.
- `const` after a function (`state() const`) = "calling this cannot modify the object" —
  a read-only accessor.
- Members initialized at declaration (`= State::Safe`) define the object's birth state —
  note it is born *Safe*: the boot-safe default is literally one token in the header.

## 9. Virtual interfaces — the testability trick (THE key pattern)

Here is `w17-control-fw/lib/hal/include/hal/IPwmOutput.hpp`, complete:

```cpp
namespace hal {
class IPwmOutput {
public:
    virtual ~IPwmOutput() = default;
    virtual void setPulseMicroseconds(uint16_t microseconds) = 0;
};
}
```

- `virtual ... = 0` declares a function with **no implementation** — any concrete class
  *must* provide one. Such a class is an **interface**: a promise, not a mechanism.
- `EscOutput` (pure logic) holds a reference to `hal::IPwmOutput` and calls
  `setPulseMicroseconds(1500)`. It genuinely does not know whether that lands in
  `Esp32LedcPwm` (which programs chip registers) or `MockPwmOutput`
  (`test/mocks/MockPwmOutput.hpp`, which just stores the number so a test can assert
  "the ESC was commanded 1500 µs").
- `virtual ~IPwmOutput() = default;` is boilerplate ensuring correct cleanup when
  deleting through an interface pointer; you can treat it as part of the pattern.
- The `I` prefix marks interfaces: `IClock`, `IByteSink`, `ICharIO`, `IVoltageSensor`,
  `IWheelPulseSensor`, `ISettingsStore` — one per kind of hardware touch.

This single pattern is why 187 tests run on your laptop. When you see a constructor take
`hal::ISomething&`, read it as: "I need *a* something; main.cpp gives me the real one,
tests give me a fake."

## 10. The caller-supplies-time pattern

Notice `update(uint32_t nowMs, ...)` everywhere: no module ever reads the clock itself.
`main.cpp` passes in the time; tests pass in *fabricated* time ("now pretend 600 ms
elapsed") to exercise timeouts instantly and deterministically. `hal::IClock` exists for
the few places that need injectable real time. The failsafe header says it outright:
"it never reads a real clock itself, so it is fully testable with synthetic time."

## 11. The Arduino model: `setup()`, `loop()`, and non-blocking code

An Arduino-framework program has no `main()` you write; instead:

```cpp
void setup() { /* runs once at boot: construct, configure */ }
void loop()  { /* runs forever, as fast as it can */ }
```

(`w17-control-fw/src/main.cpp` — `setup()` wires HALs into modules; `loop()` runs the
work.)

The cardinal rule (from `CLAUDE.md` §2.8): **no `delay()` in the control path**.
`delay(100)` would freeze *everything* — no CRSF parsing, no failsafe checks — for
100 ms. Instead, the loop free-runs and each activity keeps a "when did I last run"
timestamp using `millis()` (milliseconds since boot), acting only when its period
elapsed. That's how one single-threaded loop runs three cadences at once: 50 Hz control,
20 Hz link2, ~5 Hz telemetry (chapter 06 §5).

`millis()` wraps around after 49.7 days — acknowledged and accepted for an RC car
(ROADMAP finding A10).

## 12. Interrupts (ISRs) and `std::atomic`

A hardware **interrupt** pauses your code mid-instruction, runs a tiny **ISR (interrupt
service routine)**, then resumes. The Hall sensor pulse is one: each rising edge on
GPIO35 increments a counter in `Esp32HallPulseCounter`
(`lib/telemetry_hal_esp32/`), regardless of what `loop()` was doing.

Two rules the project follows:

- **ISRs are tiny** — count and timestamp, nothing else. (Marked `IRAM_ATTR` so the code
  lives in RAM — flash access inside an ISR can crash an ESP32.)
- **Shared data is `std::atomic`.** When two execution contexts (ISR + loop, or two CPU
  cores) touch the same variable, a plain variable can be read half-updated.
  `std::atomic<uint32_t>` guarantees indivisible reads/writes. The sound board's whole
  cross-core design rests on this: core 1 packs the synth parameters into **one**
  `std::atomic<uint32_t>` word that core 0 unpacks — one atomic word is safe where a
  struct of four fields would tear (soundlight `CLAUDE.md`, cross-core rule).

## 13. Bits and bytes (preview)

Protocol code packs many values into few bytes — e.g. one link2 byte carries eight
boolean flags, defined as masks:

```cpp
inline constexpr uint8_t kFlagBraking = 1u << 0;   // 0b00000001
inline constexpr uint8_t kFlagDrsOpen = 1u << 2;   // 0b00000100
```

(`lib/link2/Link2Frame.hpp`)

`1u << n` means "1 shifted left n places"; OR-ing masks sets flags, AND-ing tests them.
CRSF goes further: 16 channels × 11 bits sardine-packed into 22 bytes. Chapter 09 works
through both in detail.

## 14. Reading a Unity test

Test files look like this (shape, from `test/test_failsafe/test_main.cpp`):

```cpp
void test_no_frame_ever_stays_safe_forever() {
    FailsafeStateMachine fsm;
    TEST_ASSERT_EQUAL(State::Safe, fsm.update(1000000, false, false));
}
...
int main(...) { UNITY_BEGIN(); RUN_TEST(test_no_frame_ever_stays_safe_forever); ... }
```

`TEST_ASSERT_EQUAL(expected, actual)` fails the test with a message if they differ.
Each `test/test_<module>/` folder is one standalone program running against the pure
libs + mocks. The tests double as *executable documentation* — often the fastest way to
learn a module's intended behavior is its test names.

## Confirmed vs inferred

**Confirmed [C]:** all code excerpts are verbatim (or lightly elided, marked `...`) from
the cited files; conventions (k-prefix, trailing underscore, I-prefix, no-delay rule,
integer-math rule, no-Arduino-headers rule) are visible across the tree and/or stated in
the CLAUDE.md files.

**Inferred [I]:** the *pedagogical* claims (why `static_assert` beats runtime checks,
why atomics are needed) are standard C++/embedded reasoning applied to the project's
stated rules. That `IRAM_ATTR` is used for the Hall ISR is stated in ROADMAP D5.

**Assumed [A]:** none.

## Questions to check your understanding

1. Why does `GearboxConfig::valid()` have to be `constexpr` for the `static_assert` in
   `main.cpp` to work?
2. `EscOutput` needs to output pulses but contains no ESP32 code. Trace which three
   files cooperate to make a real pulse happen on GPIO14, and which file substitutes for
   the last one during tests.
3. What could go wrong if `FailsafeStateMachine::update()` called `millis()` internally
   instead of taking `nowMs` as a parameter? Name both the testing consequence and the
   architectural rule it would break.
4. The link2 flags byte reads `0x4C`. Using the masks in §13 (braking bit0, reverse
   bit1, drsOpen bit2, armed bit3, failsafe bit4, lowBattery bit5, ersDeploying bit6),
   which flags are set?
5. Why is `delay(20)` in `loop()` more dangerous in this firmware than in a typical
   blink-an-LED Arduino sketch?
6. The wheel-pulse counter is written by an ISR and read by `loop()`. Why must it be
   `std::atomic`, and what *kind* of bug appears if it isn't? (Describe the symptom, not
   just "race condition.")
