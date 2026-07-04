# C9a — Concept Teaching Notes

A standalone study companion to `09a_settings_persistence.md`. It teaches, from absolute
beginner level, every concept C9a introduced. It uses **only** the already-read C9a source
(`lib/settings/Settings.hpp`, `lib/settings/src/Settings.cpp`,
`test/test_settings/test_main.cpp`), the C9a explanation, and `glossary.md`. It does **not**
touch any C9b file (console, NVS store, serial console, `MockSettingsStore`).

Read it top to bottom. Each of the 17 concepts follows the same six-part shape you asked for.
The quiz + answer key + readiness checklist are at the end.

> **The one picture to hold in your head for all of C9a:**
> ```
> kDefaults (baked into the program)  ──►  live Settings in RAM  ──serialize──►  blob bytes
>                                                                                    │
>                        keep kDefaults ◄──reject── guard chain ◄──deserialize── blob bytes
>                              (all 4 guards must pass to apply)     (from flash, C9b)
> ```
> C9a is **only** the two arrows labelled `serialize` and `deserialize`, plus the `Settings`
> struct, `kDefaults`, and the blob constants. Everything about *flash* and *who calls these*
> is C9b/C10/hardware.

---

## Concept 1 — Persistence

**Simple explanation.** "Persistence" means data that *survives a power cycle*. Turn the car
off, turn it back on, and the value is still there. The opposite is data that vanishes the
instant power is lost.

**Why embedded systems need it.** A microcontroller has no hard disk and no operating system
saving files for you. When you tune the steering trim on the bench so the wheels sit dead
straight, that trim lives in the chip's RAM — and RAM forgets everything the moment power
drops. Without a deliberate persistence mechanism, every reboot would throw your calibration
away and you'd re-tune the car every single time you switched it on.

**How this project uses it.** The firmware lets you tune three things on the bench (steering
trim, battery calibration, gear feel) and wants them to survive. C9a defines the *format* those
values are stored in and the *rules* for trusting them when they come back. (The actual writing
to flash is C9b.)

**Relevant C9a code.** The struct that holds the persistable values:
```cpp
struct Settings {
    outputs::ServoConfig    steering{};   // steering trim/center/endpoints
    gearbox::GearboxConfig  gearbox{};    // gear feel table
    telemetry::BatteryConfig battery{};   // battery calibration
    ...
};
```

**Common beginner misunderstanding.** "If I set a variable, it's saved." No — assigning a
variable only changes RAM. Persistence is a *separate, explicit* step (serialize → write to
flash). C9a is about the format of that step; nothing in C9a actually writes to flash.

**What bug this prevents.** It prevents "silent amnesia": a car that loses your careful bench
calibration on every power cycle, forcing error-prone re-tuning and making the gift's behaviour
inconsistent from one power-up to the next.

---

## Concept 2 — RAM vs persistent storage

**Simple explanation.** Two different kinds of memory:
- **RAM** (Random Access Memory): fast, unlimited rewrites, but **volatile** — it's blank on
  every boot. This is where your *live* variables live while the program runs.
- **Persistent storage** (flash): keeps its contents with the power off (**non-volatile**), but
  is slower and *wears out* after many writes. This is where you *deliberately* save things you
  want to keep.

**Why embedded systems need it.** You need both. The control loop runs on RAM values 50 times a
second (fast, constantly changing). But a few of those values (calibration) must outlive power.
So you keep a *live copy in RAM* and, on an explicit command, *copy it into flash*; on boot you
*copy it back* from flash into RAM.

**How this project uses it.**
- **RAM ("live") settings:** the `Settings` object the firmware holds and uses while driving.
- **Persistent settings:** the *blob* stored in flash.
- C9a is the translator between them: `serialize` (RAM struct → blob bytes) and `deserialize`
  (blob bytes → RAM struct, if trusted). The blob's flash home is C9b.

**Relevant C9a code.** `serialize` turns the RAM struct into bytes; `deserialize` turns bytes
back into a RAM struct:
```cpp
size_t serialize(const Settings& s, uint8_t out[kBlobLen]);   // RAM  → bytes
bool   deserialize(const uint8_t* data, size_t len, Settings& out); // bytes → RAM (guarded)
```

**Common beginner misunderstanding.** "Saving is instant and free." Flash writes are slow and
wear the chip; that's *why* the design saves only on an explicit `save` (C9b), not every time a
value changes. C9a's `serialize` just prepares the bytes; it doesn't touch flash.

**What bug this prevents.** Confusing the two leads to either (a) losing data you thought was
saved (treating RAM as persistent), or (b) hammering flash with writes and wearing it out
(treating flash like RAM). Keeping a clear RAM-vs-flash boundary prevents both.

---

## Concept 3 — NVS (conceptually, no C9b files)

**Simple explanation.** **NVS** = "Non-Volatile Storage." On the ESP32 it's a small, managed
area of flash you can store named key→value blobs in, like a tiny dictionary that survives
power-off. Think "a labelled drawer in flash you can put a small parcel into and find again
after a reboot."

**Why embedded systems need it.** Raw flash is awkward: you must erase whole *sectors* before
rewriting, and a power loss mid-write can corrupt data. NVS is a library that hides that — it
manages sectors, wear, and (some) power-loss safety, and gives you a simple "save this named
blob / load this named blob" interface.

**How this project uses it.** *Conceptually* (the real code is C9b), the plan is: `save` writes
the C9a blob into NVS under a key; on boot, the firmware reads that key back and hands the bytes
to `deserialize`. **C9a never mentions NVS** — it only produces/consumes a byte buffer. That
separation is deliberate: the pure format logic (C9a) has no idea *where* the bytes come from.

**Relevant C9a code.** The `Settings.hpp` comment describing the *format* NVS will hold — note
it says nothing about flash mechanics:
```cpp
// --- Versioned blob format: [version][struct bytes][crc8], CRC over
// [version + struct bytes]. Bump kBlobVersion on ANY layout change ... ---
```

**Common beginner misunderstanding.** "NVS guarantees my data can never be lost or corrupted."
No — a wire glitch, a half-finished write, or a firmware change can still hand back garbage or
nothing. That's *exactly why* C9a wraps the loaded bytes in a guard chain instead of trusting
them (Concept 13). NVS is where the bytes live; it is not a promise the bytes are valid.

**What bug this prevents.** Understanding NVS as "just a byte drawer that can occasionally
return junk" prevents the fatal assumption "if it loaded, it's good." The whole never-brick
design exists because a persistence layer *can* return bad bytes.

---

## Concept 4 — Blob serialization

**Simple explanation.** A "blob" is just a flat run of bytes. **Serialization** is turning an
in-memory object (with typed fields, maybe nested structs) into that flat run of bytes so it can
be stored or sent. **Deserialization** is the reverse.

**Why embedded systems need it.** Flash and wires only deal in bytes — they don't know what a
`Settings` struct is. To store or transmit a structured value you must flatten it to bytes on
the way out and rebuild it on the way in.

**How this project uses it.** C9a's blob is exactly three parts:
```
[ version (1 byte) ][ the Settings struct's bytes ][ crc8 (1 byte) ]
```
`serialize` writes those three parts; `deserialize` reads and checks them.

**Relevant C9a code.**
```cpp
size_t serialize(const Settings& s, uint8_t out[kBlobLen]) {
    out[0] = kBlobVersion;                                   // part 1: version
    std::memcpy(out + 1, &s, sizeof(Settings));             // part 2: the struct's bytes
    out[kBlobLen - 1] = computeCrc8(out, 1 + sizeof(Settings)); // part 3: checksum
    return kBlobLen;
}
```
`kBlobLen = 1 + sizeof(Settings) + 1` — the total size is version + struct + crc.

**Common beginner misunderstanding.** "Serialization is always a complicated library." It can be
as simple as "copy the bytes out and add a checksum," which is exactly what C9a does. The
sophistication here is not in the packing — it's in the *validation on the way back in*.

**What bug this prevents.** Without a defined serialization format, you can't reliably store and
reload structured data at all — you'd have ad-hoc byte fiddling that breaks the moment a field
changes. A named, versioned, checksummed format makes storage reliable and *auditable*.

---

## Concept 5 — Raw struct copy (`memcpy`)

**Simple explanation.** Instead of writing each field one at a time in a chosen byte order, C9a
copies the *entire struct's memory image* in one shot with `memcpy` — every field **plus any
invisible padding bytes** the compiler inserted between fields for alignment.

**Why embedded systems need it (and the tradeoff).** It's the simplest, fastest possible
serialization — one copy, no per-field code. The cost: the byte layout is *whatever this exact
compiler build produced*. It is **not portable** — a different build (or a different compiler, or
a changed struct) could lay the bytes out differently.

**How this project uses it.** `serialize` does `memcpy(out + 1, &s, sizeof(Settings))`. This is
safe *here* because the same firmware build that wrote the blob is the one that reads it back, so
the layout matches on both ends. The comment says exactly this:
```cpp
// Both writer and reader are the same firmware build, so a raw struct copy
// with natural alignment is deterministic; the version byte guards against
// cross-build layout drift.
```

**Relevant C9a code.** Out (serialize) and back in (deserialize):
```cpp
std::memcpy(out + 1, &s, sizeof(Settings));        // struct → bytes
...
std::memcpy(&candidate, data + 1, sizeof(Settings)); // bytes → struct (into a LOCAL first)
```

**Common beginner misunderstanding.** "`sizeof(Settings)` equals the sum of its members' sizes."
Wrong — the compiler adds **padding** so each field lands on an address its type likes
(*alignment*). So `sizeof(Settings)` is usually *larger* than the field-size sum, and its exact
value is build-specific. (This is why C9a — and this note — refuse to state a numeric
`sizeof(Settings)` or pin a "golden blob"; contrast that with link2, where every byte is pinned.)

**What bug this prevents.** Used blindly, a raw struct copy is a *portability trap* — but paired
with the version byte + length + CRC guards, C9a turns that trap into a safe shortcut: any
layout mismatch from a different build is caught and rejected (Concept 6, 7, 13) rather than
silently misinterpreted.

**Vs. the simpler/other approach.** link2 and CRSF serialize *field-by-field* in an explicit
little-endian order (portable across builds, but more code and a fixed layout you must maintain).
Settings uses the raw copy because it never leaves this one build — so it gets the cheap version
and lets the guards cover the one risk (cross-build drift). Right tool, right place.

---

## Concept 6 — Version byte

**Simple explanation.** The first byte of the blob is a **format version number** (`kBlobVersion
= 1`). If you ever change the `Settings` layout, you bump this number, and old blobs (written
with the old number) are recognised as "not my format" and ignored.

**Why embedded systems need it.** Firmware gets reflashed. A new firmware may have a *different*
`Settings` layout. If it blindly loaded an old blob, it would misinterpret the bytes and apply
nonsense. A version byte lets the new firmware say "this blob is version 1, but I'm version 2 —
don't trust it," and fall back to defaults.

**How this project uses it.** `serialize` writes it first; `deserialize` checks it (after the
CRC). A mismatch → reject → keep `kDefaults`.

**Relevant C9a code.**
```cpp
inline constexpr uint8_t kBlobVersion = 1;
...
if (data[0] != kBlobVersion) return false;   // older/newer layout -> reject
```

**Common beginner misunderstanding.** "The CRC already protects me, so I don't need a version."
No — the CRC only proves the bytes are *intact*, not that they're the *right layout* (Concept 8).
An old blob can be perfectly intact (valid CRC) yet mean something different to new firmware. The
version byte catches exactly that case, which the CRC cannot.

**What bug this prevents.** It prevents "silent misinterpretation across firmware versions": a
reflashed car reading an old calibration blob as if it were the new layout and applying garbage
trim/gears. Instead it cleanly reverts to defaults.

---

## Concept 7 — Checksum / CRC

**Simple explanation.** A **checksum** is a small fingerprint computed from a block of bytes. Save
the fingerprint alongside the data; on load, recompute it and compare. If they differ, some byte
changed — the data is corrupt. A **CRC** (Cyclic Redundancy Check) is a particularly good kind of
checksum that reliably catches the bit-flip patterns real hardware produces.

**Why embedded systems need it.** Flash can flip bits over time; a write can be interrupted by
power loss; a wire can pick up noise. Without an integrity check you'd apply corrupt data as if it
were real. A CRC turns "silent corruption" into "detected corruption you can reject."

**How this project uses it.** The last blob byte is a CRC-8 over `[version + struct bytes]`. On
load, `deserialize` recomputes it and rejects any mismatch. It's the **same 0xD5 CRC-8 algorithm**
used by CRSF (C3) and link2 (C8) — copied a third time so `lib/settings` needs no dependency on
`lib/crsf`. A test proves the copy is identical.

**Relevant C9a code.**
```cpp
uint8_t computeCrc8(const uint8_t* data, size_t len) {   // poly 0xD5, MSB-first, init 0
    uint8_t crc = 0;
    for (size_t i = 0; i < len; ++i) {
        crc ^= data[i];
        for (int bit = 0; bit < 8; ++bit)
            crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0xD5) : (uint8_t)(crc << 1);
    }
    return crc;
}
...
out[kBlobLen - 1] = computeCrc8(out, 1 + sizeof(Settings)); // write
...
if (computeCrc8(data, 1 + sizeof(Settings)) != data[kBlobLen - 1]) return false; // check
```
And the cross-check test proving it's the standard algorithm:
```cpp
void test_crc_matches_crsf_implementation() {
    const uint8_t data[] = {'1','2','3','4','5','6','7','8','9'};
    TEST_ASSERT_EQUAL_HEX8(crsf::computeCrc8(data, sizeof(data)),
                           settings::computeCrc8(data, sizeof(data)));
}
```

**Common beginner misunderstanding.** "A CRC is encryption / makes data secure." No — a CRC is
about *accidental* corruption, not security. Anyone can recompute it. Also: a CRC does not *fix*
data; it only *detects* that something changed.

**What bug this prevents.** It prevents applying a corrupt blob (a flipped bit in flash, a
half-finished write) as though it were valid calibration — which could set a bizarre steering trim
or gear table.

---

## Concept 8 — Why CRC proves integrity but not correctness

**Simple explanation.** A valid CRC proves the bytes are **exactly what was written** (integrity).
It says *nothing* about whether those bytes represent **sensible values** (correctness). You can
write a perfectly-checksummed blob whose numbers are garbage-in-range terms.

**Why embedded systems need to separate these.** "Not corrupted" and "safe to use" are different
questions. A value can travel intact through flash and still be dangerous — for example a steering
trim so large it drives the servo past its endpoint. Integrity checking (CRC) and validity checking
(`valid()`) are two independent gates, and you need both.

**How this project uses it.** After the CRC passes, `deserialize` *still* runs `Settings::valid()`.
The dedicated test builds a blob with a **correct CRC but out-of-range values** and confirms it's
rejected:
```cpp
void test_crc_valid_but_out_of_range_rejected() {
    Settings s = kDefaults;
    s.steering.trimMicros = 30000;     // absurd: trim shoves center past the endpoint
    uint8_t blob[kBlobLen];
    serialize(s, blob);                // CRC is CORRECT for these (invalid) bytes
    TEST_ASSERT_FALSE(s.valid());      // precondition: the values are invalid
    Settings out;
    TEST_ASSERT_FALSE(deserialize(blob, kBlobLen, out)); // CRC+version pass, valid() rejects
}
```

**Common beginner misunderstanding.** "If the checksum passes, the data is good — I can apply it."
This is the single most important misconception C9a corrects: **integrity ≠ correctness.** A
checksum-valid blob can still hold values that must never be applied.

**What bug this prevents.** It prevents "the corrupt-but-checksummed" and "the intact-but-insane"
blob from reaching the actuators — e.g. a stored trim of 30000 that would peg the steering servo.

---

## Concept 9 — Guard order

**Simple explanation.** `deserialize` runs four checks in a *fixed order*, and **all four must
pass** before any value is applied. The order is: **length → CRC → version → `valid()`.**

**Why embedded systems need it (order matters).** The order is chosen so each check is safe and
each rejection is *meaningful*:
- **Length first** so you never read past (or dereference a null) buffer. A `nullptr`/short input
  returns immediately, before touching `data[...]`.
- **CRC before version** so a bit-flip *in the version byte itself* is reported as corruption
  (CRC), and a *version* rejection therefore means "an intact blob from a different format
  version," not "noise." (Same logic as link2's CRC-before-version, C8.)
- **`valid()` last** so it only runs on bytes already proven intact and same-version.

**How this project uses it.**
```cpp
bool deserialize(const uint8_t* data, size_t len, Settings& out) {
    if (len != kBlobLen) return false;                               // (1) length
    if (computeCrc8(data, 1 + sizeof(Settings)) != data[kBlobLen-1]) return false; // (2) CRC
    if (data[0] != kBlobVersion) return false;                       // (3) version
    Settings candidate;
    std::memcpy(&candidate, data + 1, sizeof(Settings));
    if (!candidate.valid()) return false;                            // (4) valid()
    out = candidate;                                                 // apply only if ALL pass
    return true;
}
```

**Common beginner misunderstanding.** "The order of the checks doesn't matter — they all just
return false." It matters for *safety* (length-first prevents a null/overrun read) and for
*meaning* (CRC-before-version makes a version rejection trustworthy). Reorder them and you can
crash on a null pointer or mislabel corruption as a version problem.

**What bug this prevents.** Length-first prevents a crash on empty/short input (Concept: first
boot returns 0 bytes). CRC-before-version prevents mis-diagnosing corruption as a version issue.
`valid()`-last prevents wasting a validity check on bytes that aren't even intact.

---

## Concept 10 — Compiled defaults

**Simple explanation.** `kDefaults` is a complete, valid `Settings` value **baked into the
program image at compile time**. It's always present, needs no flash, and is guaranteed valid
before the firmware ever runs.

**Why embedded systems need it.** You need a known-good fallback for the very first boot (nothing
saved yet) and for every rejected blob. If loading fails, the car must *still* have a sane config.
Compiled defaults are that guaranteed floor.

**How this project uses it.** `kDefaults` is a `constexpr` and a `static_assert` proves it's valid
*at compile time* — if someone edited the defaults into something invalid, the firmware wouldn't
build:
```cpp
inline constexpr Settings kDefaults{};
static_assert(kDefaults.valid(), "default Settings are invalid");
```
Whenever `deserialize` returns false, the caller keeps `kDefaults`.

**Common beginner misunderstanding.** "Defaults are loaded from somewhere at startup." No —
`kDefaults` is *in the binary itself* (like a constant literal), not read from storage. That's why
it's always available even on a blank chip.

**What bug this prevents.** It prevents "no valid config exists" states: first boot, corrupt flash,
wrong version — in every failure the firmware falls back to a config that the compiler already
proved valid. It also prevents shipping firmware whose defaults are themselves broken (the
`static_assert` refuses to build them).

---

## Concept 11 — `valid()` functions

**Simple explanation.** A `valid()` function returns `true` only if a config's values are within
sane, safe ranges. It's the config's own definition of "these numbers make sense."

**Why embedded systems need it.** Numbers arrive from many sources — defaults, a saved blob, (in
C9b) a console edit. Any of them could be out of range. A `valid()` check is a single, reusable
gate that decides whether a config is safe to apply, no matter where it came from.

**How this project uses it.** Each sub-config (from earlier batches) has its own `valid()`:
- `ServoConfig::valid()` (C2): endpoints ordered, and the *trimmed* center still inside the
  endpoints (the "trim can't push past an endpoint" A11 rule).
- `GearboxConfig::valid()` (C6): gear count/initial in range, each gear's numbers in range, and
  `maxOutput` non-decreasing across gears.
- `BatteryConfig::valid()` (C7): divider denominator ≠ 0, calibration in [900,1100], EMA shift in
  [1,6], positive delay/hysteresis, and overflow bounds.

**Relevant C9a code.** These are *called by* the aggregate (Concept 12); the point here is that
each config knows how to police itself.

**Common beginner misunderstanding.** "`valid()` is the same as the CRC check." No — CRC checks the
*bytes*, `valid()` checks the *meaning*. They're independent (Concept 8).

**What bug this prevents.** It prevents out-of-range values (a monotone-broken gear table, an
over-range battery calibration, a trim past the endpoint) from being applied — regardless of
whether they came from a blob, a default, or an edit.

---

## Concept 12 — Aggregate `valid()` vs sub-config `valid()`

**Simple explanation.** The `Settings` struct bundles three sub-configs. Its *aggregate* `valid()`
is just the logical-AND of the three sub-`valid()`s: the whole thing is valid only if *every* part
is valid.

**Why embedded systems need it.** Composition. Each module already knows how to validate itself;
the aggregate reuses those checks instead of re-implementing them, so there's a single source of
truth per config and one combined verdict for the bundle.

**How this project uses it.**
```cpp
struct Settings {
    outputs::ServoConfig    steering{};
    gearbox::GearboxConfig  gearbox{};
    telemetry::BatteryConfig battery{};

    constexpr bool valid() const {
        return steering.valid() && gearbox.valid() && battery.valid();
    }
};
```
Because it's `constexpr`, this combined check can run **at compile time** (used by the
`static_assert` on `kDefaults`) *and* at run time (used by `deserialize`).

**Common beginner misunderstanding.** "The aggregate re-checks everything itself." No — it delegates
to each sub-config's `valid()`. If you later tighten `GearboxConfig::valid()`, the aggregate
automatically inherits the stricter rule with no change here.

**What bug this prevents.** It prevents validation drift and gaps: you can't forget to check one
sub-config, and you can't have two different definitions of "valid gearbox." One `&&` chain, three
authoritative checks.

---

## Concept 13 — "Never-brick" config loading

**Simple explanation.** "Never-brick" = **no stored blob, however bad, can make the firmware run
invalid settings.** Every bad-blob case (missing, truncated, wrong length, corrupt, wrong version,
in-range-failing) is *rejected*, and the firmware keeps the compiled-in, provably-valid
`kDefaults`.

**Why embedded systems need it.** The device is a gift with a hard deadline and no easy debugging
in the field. If a bad saved config could make it behave dangerously or refuse to run, that's a
disaster. Never-brick guarantees the car always boots with a sane config, whatever is in flash.

**How this project uses it.** The four-guard `deserialize` (Concept 9) is the never-brick chain.
Each early `return false` happens *before* `out` is written; only after all four pass is
`out = candidate` applied. So a rejected blob never even touches the caller's settings.

**Relevant C9a code.** The proof that `out` is untouched on failure:
```cpp
void test_corrupt_blob_rejected() {
    uint8_t blob[kBlobLen];
    serialize(kDefaults, blob);
    blob[5] ^= 0xFF;                         // corrupt a struct byte
    Settings out = kDefaults;
    out.steering.trimMicros = 999;           // sentinel
    TEST_ASSERT_FALSE(deserialize(blob, kBlobLen, out));
    TEST_ASSERT_EQUAL_INT16(999, out.steering.trimMicros); // untouched
}
```

**Common beginner misunderstanding — what never-brick does NOT mean:**
- It does **not** mean a bad blob is *repaired or applied* — it's *discarded* for defaults. (Your
  saved trim is silently lost; that's the safe trade.)
- It does **not** mean the whole firmware can't be bricked by *other* means (bad code, a botched
  program-image flash, hardware faults). It's scoped to the **settings-load decision only**.
- It does **not** prove the flash actually returned these bytes or that anyone calls `deserialize`
  — those are C9b/C10/hardware.

**What bug this prevents.** It prevents "a bad saved config bricks or endangers the car." No matter
what's in flash, the firmware runs a valid config.

---

## Concept 14 — What native tests prove

**Simple explanation.** "Native tests" compile the *pure logic* for your laptop and run it there
(no ESP32). They can prove everything about the *format and rules* because those are hardware-free.

**Why embedded systems need them.** You get fast, deterministic, repeatable checks of the logic
without flashing a chip. Most real bugs (off-by-one, wrong guard order, endianness, missing
validation) are logic bugs the native tests catch instantly.

**How this project uses it.** `pio test -e native -f test_settings` runs 7 tests → **7/7 PASSED**.
They cover: defaults are valid; round-trip fidelity; corrupt-blob rejected (+ `out` untouched);
wrong-version rejected (even with fixed CRC); empty/truncated rejected; CRC-valid-but-out-of-range
rejected; and the CRC matches crsf's.

**Relevant C9a code.** The runner that ties them together:
```cpp
int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_defaults_are_valid);
    RUN_TEST(test_roundtrip);
    RUN_TEST(test_corrupt_blob_rejected);
    RUN_TEST(test_wrong_version_rejected);
    RUN_TEST(test_empty_and_truncated_rejected);
    RUN_TEST(test_crc_valid_but_out_of_range_rejected);
    RUN_TEST(test_crc_matches_crsf_implementation);
    return UNITY_END();
}
```

**Common beginner misunderstanding.** "Tests passing means the feature works on the car." No —
native tests prove the *logic*, not the *hardware behaviour* (Concept 15). Each test's *name* is a
precise claim; the test proves *that* claim and nothing broader.

**What bug this prevents.** They lock in the format and guard behaviour so a later edit that breaks
(say) the version check or the "untouched on failure" property fails a test immediately, before it
can ship.

---

## Concept 15 — What native tests cannot prove

**Simple explanation.** The native tests never touch flash, NVS, a real UART, or a real ESP32. So
they prove nothing about *storage or timing on the device*.

**Why this matters.** It's easy to over-read a green test suite. The tests prove `serialize` and
`deserialize` are correct *as functions over byte buffers*. They do **not** prove that a real chip
stores the blob, survives a power cycle, handles flash wear, or that any code even calls these
functions.

**How this project frames it.** C9a explicitly marks all flash/lifecycle behaviour **PROVISIONAL /
requires C9b or hardware**. There is deliberately **no "golden blob" test** pinning exact bytes,
because the raw struct layout is build-specific (Concept 5) — pinning bytes would be meaningless
and brittle.

**Common beginner misunderstanding.** "7/7 passed, so persistence works." Persistence *end to end*
(edit → save → power-cycle → survives) is untested here — that's a hardware task (Concept 17,
open question #34a).

**What bug this prevents (by being honest).** Believing "tests pass = shipped feature works" would
let real persistence bugs (a store that doesn't persist, a version-bump that doesn't fall back)
slip through. Naming the boundary keeps those on the to-verify list.

---

## Concept 16 — What must wait for C9b

**Simple explanation.** C9a is only the *format + validation*. The parts that *use* it live in
C9b (and are not read here):
- the **store seam** (`ISettingsStore`) and its ESP32 flash implementation,
- the **serial console** that lets you type `get`/`set`/`save`/`load`/`reset`/`status`/`help`,
- the **RAM-vs-flash lifecycle**: `set` edits the RAM copy, only `save` writes flash, edits gated
  on the car being **disarmed**, per-`set` re-validation, and the console being *compiled out* of
  the delivered gift firmware,
- the **`MockSettingsStore`** test double (confirmed unused by `test_settings`, so deferred),
- the still-open C1 curiosity about `settings_hal_esp32`'s `library.json` dependencies.

**Why the split is clean.** C9a's functions are *pure* — they don't know where bytes come from or
go. That's precisely what lets C9b plug a real flash store and a console on top without changing
the format logic.

**What bug this prevents.** Keeping format (C9a) separate from storage + UI (C9b) prevents tangled
code where a flash change could break the validation rules, or a console change could corrupt the
blob format. Each layer is testable and replaceable on its own.

---

## Concept 17 — What must wait for real ESP32 hardware

**Simple explanation.** Some claims can only be checked on a physical chip:
- that NVS actually **persists across power cycles and reflashes**, and behaves under flash
  **wear / partial writes**,
- that a **firmware version bump + reflash** makes a *real* device with an *old* blob in NVS
  correctly fall back to `kDefaults` (the entire reason for the version byte),
- **end-to-end bench tuning**: edit over the console → `save` → power-cycle → the values survive.

**Why embedded systems need this stage.** Native logic being perfect doesn't guarantee the flash
part, the timing, or the electrical reality. Only the bench proves the loop closes on real
hardware. This is tracked as **open question #34a** (D8 Phase 6/8).

**What bug this prevents (by scheduling it).** It prevents shipping with an *assumed*-working
persistence path. The version-bump-fallback in particular is subtle: it only ever exercises on a
device that has a genuinely old blob sitting in flash — a pure test can't create that situation.

---

## 20 Quiz Questions

1. Define "persistence" in one sentence, and name the memory type that does *not* have it.
2. You assign `settings.steering.trimMicros = 42;` in the running firmware. Is that value saved
   across a power cycle yet? Why or why not?
3. What are the three parts of the settings blob, in order?
4. What does `kBlobLen = 1 + sizeof(Settings) + 1` count?
5. Why does the code refuse to state a numeric value for `sizeof(Settings)`?
6. Explain "alignment padding" and why `sizeof(Settings)` is usually larger than the sum of its
   fields' sizes.
7. Why is a raw `memcpy` serialization safe for the settings blob but would be wrong for the link2
   wire to board #2?
8. What does the version byte protect against that the CRC cannot?
9. In one sentence, what does a CRC prove?
10. In one sentence, what does a CRC *not* prove?
11. A blob has a perfectly correct CRC but `steering.trimMicros = 30000`. Which of the four guards
    rejects it, and why can't the CRC guard catch this?
12. Why is the length check placed *first* in `deserialize`?
13. Why is the CRC check placed *before* the version check?
14. What is `kDefaults`, and where does it physically live (flash? RAM? the program image?)?
15. What does `static_assert(kDefaults.valid())` guarantee, and *when* is it checked?
16. Write, in words, the boolean expression that `Settings::valid()` evaluates.
17. If you later tighten `GearboxConfig::valid()`, do you have to change `Settings::valid()`? Why
    or why not?
18. State one thing "never-brick" guarantees and two things it explicitly does *not* guarantee.
19. `test_corrupt_blob_rejected` plants `out.steering.trimMicros = 999` before a failed load and
    checks it's still 999 afterward. What property is that proving?
20. The suite is 7/7 green. Name two things about the *real car* that this does not prove.

---

## Answer Key

1. Persistence = data that survives a power cycle. **RAM** is volatile (no persistence).
2. **Not saved.** Assigning a variable only changes RAM; saving is a separate explicit step
   (serialize → write to flash, which is C9b). Power loss erases RAM.
3. `[version (1 byte)] [Settings struct bytes] [crc8 (1 byte)]`.
4. The total blob size: version(1) + the struct's bytes + crc(1).
5. Because `sizeof(Settings)` is compiler/alignment-dependent (build-specific); the source never
   states it, and pinning a number would be a guess that could be wrong on another build.
6. The compiler inserts invisible padding bytes so each field starts at an address its type
   requires (e.g. a 4-byte field on a 4-aligned address). Those padding bytes make the struct
   bigger than the raw sum of field sizes.
7. Safe here because the *same firmware build* writes and reads the blob, so the layout matches
   both ends; wrong for link2 because board #2 is a *different* program that needs a fixed,
   portable, documented byte order (field-by-field little-endian), not this build's raw layout.
8. A *layout/format change across firmware versions* — an old blob can be perfectly intact (valid
   CRC) yet mean something different to new firmware. The version byte catches that; the CRC can't.
9. That the bytes are exactly what was written — **integrity**.
10. That the values are *sensible/safe* — **correctness** (a valid CRC can wrap garbage-but-intact
    values).
11. Guard **(4) `valid()`** rejects it. The CRC guard can't, because the bytes are *intact* (the
    CRC was computed correctly for those exact bytes) — CRC checks integrity, not range.
12. So that a `nullptr` or too-short buffer returns immediately, *before* any `data[...]` access —
    it prevents a null-pointer/out-of-bounds read.
13. So a bit-flip *in the version byte itself* is reported as **corruption** (CRC mismatch), which
    means a *version* rejection is trustworthy: it signals "an intact blob from a different format
    version," not noise.
14. `kDefaults` is a complete valid `Settings` **baked into the program image** at compile time
    (a `constexpr`), not read from flash or RAM-loaded — always present, even on a blank chip.
15. It guarantees the factory defaults are valid; checked **at compile time** — if they weren't
    valid, the firmware would fail to build.
16. `steering.valid()` **AND** `gearbox.valid()` **AND** `battery.valid()` — true only if all three
    sub-configs are valid.
17. **No.** `Settings::valid()` just calls `gearbox.valid()`; it automatically inherits any
    stricter rule you put inside `GearboxConfig::valid()`.
18. Guarantees: the load path never *applies* invalid settings (falls back to valid `kDefaults`).
    Does *not* guarantee: (a) a bad blob is repaired/applied (it's discarded); (b) the firmware
    can't be bricked by other means (bad code, botched image flash, hardware) — it's scoped to the
    settings-load decision only. (Also acceptable: it doesn't prove flash worked or that anyone
    calls `deserialize`.)
19. That on a *failed* load, `out` (the caller's live settings) is **left untouched** — a rejected
    blob never clobbers the current config. (This is the mechanical heart of never-brick.)
20. Any two of: that a real ESP32/NVS actually persists across power cycles; that flash wear /
    partial writes behave; that a version-bump + reflash falls back to defaults on a real device;
    that any code actually calls `serialize`/`deserialize`; that `save` writes flash. (All
    hardware/C9b, untested here.)

---

## Things to review before C9b

- **Struct memory layout / `sizeof` / alignment & padding** — the reason the blob is
  non-portable and no numeric size is claimed (Concept 5, 6). This is the subtlest idea in C9a.
- **Integrity vs correctness** — CRC vs `valid()` are *two* independent gates (Concept 7, 8, 11).
  If only one idea sticks from C9a, make it this one.
- **The guard chain and its order** — length → CRC → version → `valid()`, all-must-pass, `out`
  untouched on failure (Concept 9, 13).
- **RAM vs persistent, and where `kDefaults` lives** — compiled-in vs loaded-from-flash (Concept 2,
  10). C9b builds directly on this distinction (`set` = RAM, `save` = flash).
- **The precise meaning and limits of "never-brick"** (Concept 13) — you'll want this exact framing
  when C9b adds the console `set`/`save` and the DISARMED gate.
- **What tests do and don't prove** (Concept 14, 15) — carry the "green ≠ shipped" discipline into
  C9b's HAL files, which are excluded from native tests entirely.

---

## "Am I ready for C9b?" checklist

Tick each honestly. If any is shaky, re-read the linked concept (and, if useful,
`09a_settings_persistence.md`) before starting C9b.

- [ ] I can state the three-part blob layout from memory and say which part the CRC covers.
- [ ] I can explain why the blob uses a raw `memcpy` and why that's safe *here* but not for link2.
- [ ] I can explain why `sizeof(Settings)` isn't the sum of its fields, and why no numeric size is
      pinned.
- [ ] I can explain, with an example, why a valid CRC does **not** mean the data is safe to apply.
- [ ] I can list the four guards **in order** and say why each is where it is.
- [ ] I can explain what the version byte catches that the CRC cannot.
- [ ] I can say exactly where `kDefaults` lives and what the `static_assert` guarantees and when.
- [ ] I can write the aggregate `valid()` expression and explain the sub-config delegation.
- [ ] I can state one thing never-brick guarantees and two things it does not.
- [ ] I can name at least two things the 7/7 native tests do **not** prove.
- [ ] I understand that C9b adds *where the bytes live* (a store), *how you edit them* (a console),
      and the *RAM-edit vs flash-save* lifecycle — none of which C9a contains.

When most boxes are ticked, you're ready for **C9b — Console + tuning HAL**.

---

*This is a study companion; it changes no source and reads no C9b file. The authoritative
line-by-line explanation remains `09a_settings_persistence.md`.*
