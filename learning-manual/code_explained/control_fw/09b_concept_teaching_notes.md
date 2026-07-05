# C9b — Concept Teaching Notes

A standalone study companion to `09b_console_tuning_and_settings_store.md`. It teaches, from
absolute beginner level, the concepts C9b introduced. It uses **only** the already-read C9b source
(`Console.{hpp,cpp}`, `ConsoleRunner.{hpp,cpp}`, `Esp32NvsStore.{hpp,cpp}`,
`Esp32SerialConsole.{hpp,cpp}`, `MockCharIO.hpp`, `MockSettingsStore.hpp`, `test_console`), the C9b
explanation, and `glossary.md`. It reads no C10 file.

Read it top to bottom. Each of the 16 concepts follows the same six-part shape. The quiz + answer
key + readiness checklist are at the end.

> **The one picture to hold in your head for all of C9b:**
> ```
>   serial bytes ──► ConsoleRunner ──(one line + armed)──► Console.handleLine
>       ▲                 │  owns the LIVE RAM Settings         │  PURE: decides only
>       │                 │                                     ▼
>    write()  ◄───────────┤◄──────────── Result{ text, settingsChanged, save?, load? }
>                         │
>          save ──► serialize ──► store.save() ──► NVS flash
>          load ──► store.load() ──► deserialize (C9a guards) ──► RAM
> ```
> **`Console` only *decides* (returns a `Result`). `ConsoleRunner` *does* the I/O and storage.**
> That split is the heart of C9b: it's why the console is trivially testable and why flash/serial
> stay isolated in one place.

---

## Concept 1 — Live RAM settings

**Simple explanation.** The "live" settings are the `Settings` object the running firmware
actually uses right now, held in RAM. When you tune a value, this is what changes first.

**Why embedded systems need it.** The control loop runs 50 times a second off these values (the
steering trim, gear table, battery calibration). It reads them from fast RAM, not from slow flash.
So there's always one authoritative in-memory copy the car drives on.

**How this project uses it.** `ConsoleRunner` *owns* the live copy (`settings_`), starting at the
compiled-in `kDefaults`. The pure `Console` mutates it (by reference) for `set`/`reset`.

**Relevant C9b code.**
```cpp
ConsoleRunner(hal::ICharIO& io, hal::ISettingsStore& store)
    : io_(io), store_(store), settings_(settings::kDefaults) {}   // live RAM copy starts at defaults
...
const settings::Settings& settings() const { return settings_; } // main.cpp reads this to apply
```

**Common beginner misunderstanding.** "The live settings and the saved settings are the same
thing." No — they're two separate copies. Editing the live RAM copy does *not* change flash, and
vice versa, until you explicitly `save`/`load`. (Concept 3, 4.)

**What bug this prevents.** A single, clearly-owned live copy prevents "which settings is the car
actually using?" confusion — every module gets its config from the one `settings_` the runner
owns.

---

## Concept 2 — Persistent settings

**Simple explanation.** The persistent settings are the copy stored in flash (as the C9a blob) so
they survive a power cycle. They are *not* what the car runs on directly — they're what gets
loaded *into* the live RAM copy at boot.

**Why embedded systems need it.** RAM is wiped on every boot (C9a Concept 1/2). Without a
persistent copy, your bench calibration would vanish each power-up. The persistent copy is the
"memory across power cycles."

**How this project uses it.** At boot, `loadAtBoot()` reads the blob and (if it passes the C9a
guard chain) copies it into the live RAM settings; otherwise it uses `kDefaults`.

**Relevant C9b code.**
```cpp
void ConsoleRunner::loadAtBoot() {
    uint8_t buf[settings::kBlobLen]; size_t len = 0; settings::Settings loaded;
    if (store_.load(buf, sizeof(buf), len) && settings::deserialize(buf, len, loaded)) {
        settings_ = loaded;   // persistent → live
        io_.write("[tune] loaded settings from flash\r\n");
    } else {
        settings_ = settings::kDefaults;   // nothing valid saved → defaults
        io_.write("[tune] using defaults (no valid saved settings)\r\n");
    }
}
```

**Common beginner misunderstanding.** "If it's in flash, the car is using it." Not until it's
*loaded* into RAM. Flash is the archive; RAM is the working copy. A blob can sit in flash while the
car runs on defaults (e.g. if the blob failed the guard chain).

**What bug this prevents.** Keeping "persistent" distinct from "live" prevents assuming a `save`
instantly changes behaviour, or that a boot always uses flash — the guard chain can reject a bad
blob and fall back to defaults.

---

## Concept 3 — `set` vs `save`

**Simple explanation.** Two separate steps: **`set`** changes the *live RAM* value; **`save`**
copies the current live RAM values into *flash*. Changing a value and persisting it are
deliberately two different commands.

**Why embedded systems need the split.** You want to *experiment* — try a trim, feel it, adjust —
without wearing out flash on every tweak (Concept 6). So edits stay cheap and RAM-only; you commit
to flash only when you're happy, with one explicit `save`.

**How this project uses it.** `set` mutates the RAM `Settings` and flags `settingsChanged`; it
*never* touches flash and even tells you so. `save` flags `saveRequested`, and the runner then
serializes RAM and writes it.

**Relevant C9b code.**
```cpp
// in Console::handleLine (set path), after validation:
s = next;  r.settingsChanged = true;
say(r, "ok (RAM only; type 'save' to persist)");   // <- explicit: set is RAM-only
...
// save just flags intent:
if (tokEq(c0,c0e,"save")) { r.saveRequested = true; say(r,"saving to flash"); return r; }
// the runner does the actual persist:
if (r.saveRequested) {
    uint8_t buf[settings::kBlobLen];
    const size_t n = settings::serialize(settings_, buf);
    io_.write(store_.save(buf, n) ? "saved\r\n" : "SAVE FAILED\r\n");
}
```

**Common beginner misunderstanding.** "`set` saves my change." No — `set` is RAM-only. If you `set`
and then power-cycle *without* `save`, your change is gone. The "(RAM only; type 'save')" message
is the reminder.

**What bug this prevents.** It prevents both flash wear (from saving on every keystroke) *and*
silent surprise ("I changed it, why didn't it persist?") — the two-step model makes persistence a
deliberate act.

---

## Concept 4 — `load` vs `reset`

**Simple explanation.** Both change the live RAM settings, but from different sources: **`load`**
pulls the *last-saved* values back from flash; **`reset`** reverts to the *compile-time defaults*
(`kDefaults`), ignoring flash. Neither one persists on its own.

**Why embedded systems need both.** `load` = "undo my un-saved experiments, go back to what I
saved." `reset` = "throw everything away, start from the factory baseline." Different intents,
different sources.

**How this project uses it.** `reset` assigns `kDefaults` in place; `load` flags `loadRequested`
and the runner reads flash + deserializes into RAM.

**Relevant C9b code.**
```cpp
if (tokEq(c0,c0e,"reset")) {
    s = settings::kDefaults;  r.settingsChanged = true;
    say(r, "reverted to defaults (RAM only; type 'save' to persist)");  // defaults, no persist
    return r;
}
if (tokEq(c0,c0e,"load")) { r.loadRequested = true; ... }   // runner reads flash + deserialize
```

**Common beginner misunderstanding.** "`reset` wipes flash" or "`load` saves." Neither. `reset`
only changes RAM (to defaults) and does *not* persist — flash still holds your old saved blob until
you `save`. `load` only reads flash into RAM; it doesn't write.

**What bug this prevents.** Confusing them could make you think a `reset` cleared your saved
calibration (it didn't) or that a `load` overwrote flash (it didn't). Clear semantics prevent
data-loss surprises.

---

## Concept 5 — NVS / flash storage

**Simple explanation.** **Flash** is the chip's non-volatile memory (keeps data with power off).
**NVS** ("Non-Volatile Storage") is the ESP32's managed way to store small named key→value blobs
in flash; the Arduino **`Preferences`** library is a friendly wrapper over it.

**Why embedded systems need it.** Raw flash is awkward — you must erase whole *sectors* before
rewriting, and a mid-write power loss can corrupt it. NVS hides that: it manages sectors, some
power-loss safety, and gives you "save this named blob / load this named blob."

**How this project uses it.** `Esp32NvsStore` stores the C9a blob under one namespace/key, opening
read-only for `load` and read-write only inside `save`.

**Relevant C9b code.**
```cpp
static constexpr const char* kNamespace = "w17tune";
static constexpr const char* kKey = "settings";
bool Esp32NvsStore::save(const uint8_t* buf, size_t len) {
    Preferences prefs;
    if (!prefs.begin(kNamespace, /*readOnly=*/false)) return false;
    const size_t written = prefs.putBytes(kKey, buf, len);
    prefs.end();
    return written == len;
}
```

**Common beginner misunderstanding.** "NVS guarantees my data is always valid." No — NVS is a place
to put bytes; it can still hand back nothing (first boot) or stale/partial bytes. That's exactly
why the loaded blob goes through C9a's guard chain instead of being trusted (Concept 13, 14).

**What bug this prevents.** Using NVS (not raw flash) prevents sector-erase mistakes and reduces
power-loss corruption; the read-only-load / write-only-in-save discipline prevents needless wear
and lock contention.

---

## Concept 6 — Flash wear (conceptually)

**Simple explanation.** Flash memory can only be erased/rewritten a *finite* number of times per
region (think tens of thousands of cycles) before it wears out. So you must not write to it
constantly.

**Why embedded systems need to respect it.** A control loop runs 50×/second. If every value change
wrote to flash, you'd burn through the flash's write budget quickly and eventually the settings
region would fail. Writes must be *rare and deliberate*.

**How this project uses it.** Edits are RAM-only (`set`, Concept 3); flash is written *only* on an
explicit `save`. `Esp32NvsStore` opens read-write *only inside* `save()` and closes immediately,
minimizing wear/locking.

**Relevant C9b code.** The comment stating the discipline:
```cpp
// Persists the settings blob in ESP32 NVS via the Arduino Preferences library
// (one blob under a namespace). Opens read-only for load and read-write only
// inside save() to minimize wear/locking.
```

**Common beginner misunderstanding.** "Flash is like RAM — I can write it as often as I like." No —
flash wears out; RAM doesn't. This is *the* reason the design separates `set` (RAM) from `save`
(flash) rather than auto-saving.

**What bug this prevents.** It prevents wearing out the flash and eventually bricking the settings
region — by making persistence a deliberate, infrequent action.

---

## Concept 7 — The settings-store interface (`ISettingsStore`)

**Simple explanation.** An *interface* is a promise about what an object can do, without saying
how. `ISettingsStore` promises just two things: `load(buf, cap, len)` and `save(buf, len)`. Anything
that fulfils that promise can be a store.

**Why embedded systems need it (the seam idea).** The console logic shouldn't care *where* bytes
live. By depending on the interface (not on NVS directly), you can plug in real flash on the car or
a fake in-memory store in tests — same code, different backend. (This is the C1 §3.2 "seam"
pattern.)

**How this project uses it.** `ConsoleRunner` holds a `hal::ISettingsStore&`. On the car that
reference is an `Esp32NvsStore`; in tests it's a `MockSettingsStore`. The runner never knows which.

**Relevant C9b code.**
```cpp
hal::ISettingsStore& store_;   // borrowed by reference
...
if (store_.load(buf, sizeof(buf), len) && settings::deserialize(buf, len, loaded)) { ... }
```

**Common beginner misunderstanding.** "The runner talks to NVS." No — it talks to the *interface*.
That indirection is deliberate and is what makes the whole thing testable without hardware.

**What bug this prevents.** It prevents flash-specific code leaking into the console logic. Storage
can change (a different flash layout, a file, a network store) without touching the console — and
tests never need real flash.

---

## Concept 8 — Mock store vs real store

**Simple explanation.** Two implementations of the same `ISettingsStore` interface: the **real**
one (`Esp32NvsStore`, writes flash) and the **mock** one (`MockSettingsStore`, keeps bytes in a RAM
array). Tests use the mock; the car uses the real one.

**Why embedded systems need it.** You can't (and shouldn't) run flash-persistence tests on your
laptop. The mock lets you exercise *all the logic* — save records the blob, load returns it,
first-boot returns nothing — instantly and deterministically, with no chip.

**How this project uses it.** `MockSettingsStore` starts empty (first-boot), records blobs on
`save` (bumping `saveCount`), returns them on `load`, and lets a test pre-load a state with
`setStored`.

**Relevant C9b code.**
```cpp
bool save(const uint8_t* buf, size_t len) override {
    if (len > sizeof(stored)) return false;
    std::memcpy(stored, buf, len); storedLen = len; hasData = true; saveCount += 1;
    return true;
}
bool load(uint8_t* buf, size_t cap, size_t& len) override {
    if (!hasData || storedLen > cap) return false;   // first boot / too big
    std::memcpy(buf, stored, storedLen); len = storedLen; return true;
}
```

**Common beginner misunderstanding.** "The mock proves flash works." No — the mock proves the
*logic around* the store works (save→load round-trips, first-boot handling). Whether real NVS
persists across power cycles is a hardware question the mock can't answer (Concept 15, 16).

**What bug this prevents.** Testing against a mock catches logic bugs (wrong buffer sizes, ignoring
the `load` return, not handling first boot) without a chip — while honestly leaving flash reality
to the bench.

---

## Concept 9 — Serial console

**Simple explanation.** A "serial console" is a text conversation over a wire (here UART0 / USB
serial): you type a line, the firmware reads it byte-by-byte, acts, and prints a reply.

**Why embedded systems need it.** A microcontroller has no screen or keyboard. A serial console is
the simplest human interface — a terminal on your laptop talks to the chip so you can inspect and
tune it on the bench.

**How this project uses it.** `Esp32SerialConsole` implements the `ICharIO` seam over Arduino
`Serial`: non-blocking `read()` (returns −1 when nothing's there) and `write()`. It's built *only*
under the tuning flag.

**Relevant C9b code.**
```cpp
int  Esp32SerialConsole::read()  { return Serial.available() > 0 ? Serial.read() : -1; } // non-blocking
void Esp32SerialConsole::write(const char* text) { Serial.print(text); }
```

**Common beginner misunderstanding.** "`read()` waits for a key." No — it's *non-blocking*: if no
byte is waiting, it returns −1 immediately, so the control loop never stalls waiting for typing
(the no-`delay()` discipline). The runner calls it repeatedly to drain whatever has arrived.

**What bug this prevents.** Non-blocking I/O prevents the console from freezing the 50 Hz control
loop while waiting for a human — safety-critical: the car must keep running its failsafe/outputs
even mid-command.

---

## Concept 10 — Command parsing

**Simple explanation.** Parsing turns a raw line of text ("`set gear.2.max 500`") into structured
meaning (command = set, key = gear.2.max, value = 500). It's done here with small helper functions
over pointer ranges — no copying, no fancy library.

**Why embedded systems need it.** Text from a human is unstructured and error-prone. Parsing
validates the shape (right number of tokens, a clean integer, a known key) and rejects garbage
before anything acts on it.

**How this project uses it.** `tokenize` splits the line into `[start, end)` token ranges;
`tokEq` compares a token to a word; `parseInt` requires a *clean* integer; `parseGearIndex` pulls a
1-based gear number out of a `gear.<N>.…` key.

**Relevant C9b code.**
```cpp
bool parseInt(const char* start, const char* end, long& out) {
    char buf[24]; const size_t n = end - start;
    if (n == 0 || n >= sizeof(buf)) return false;
    std::memcpy(buf, start, n); buf[n] = '\0';
    char* endptr = nullptr;
    out = std::strtol(buf, &endptr, 10);
    return endptr == buf + n;   // consumed the WHOLE token → clean integer
}
```

**Common beginner misunderstanding.** "`strtol` (or `atoi`) accepts any number-ish text." `atoi`
silently accepts `"40x"` as 40. The `endptr == buf + n` check here *rejects* trailing junk — only a
fully-numeric token passes. Careful parsing is a validation step, not a formality.

**What bug this prevents.** It prevents acting on malformed input — e.g. treating `"set steer.trim
40x"` as trim 40, or overrunning a buffer with an over-long token (the `n >= sizeof(buf)` guard).

---

## Concept 11 — Command grammar

**Simple explanation.** The "grammar" is the fixed set of legal commands and their shapes:
`help | status | get <key> | set <key> <value> | save | load | reset`, with keys `steer.center`,
`steer.trim`, `batt.ppt`, `gear.<N>.max`, `gear.<N>.expo`.

**Why embedded systems need a defined grammar.** A small, explicit vocabulary is easy to parse,
easy to document (`help` prints it), and easy to make safe (you can gate exactly the mutating
verbs). Anything outside the grammar is cleanly rejected as "unknown."

**How this project uses it.** `handleLine` dispatches on the first token, resolves the key, and
handles unknown command/key/gear-index gracefully.

**Relevant C9b code.**
```cpp
if (tokEq(c0,c0e,"help"))   { ...; return r; }
if (tokEq(c0,c0e,"status")) { ...; return r; }
...
if (!isSet && !isGet) { say(r,"unknown command (try 'help')"); return r; }
...
if (!matched) { say(r,"unknown key (try 'help')"); return r; }
```

**Common beginner misunderstanding.** "Channels can be `set` too." No — channels are **read-only**:
`status` displays them, but they aren't in `Settings` and there's no `set` for them (the channel map
isn't tunable, C9a). The grammar deliberately excludes safety-sensitive config.

**What bug this prevents.** A closed grammar prevents typos or garbage from doing anything
surprising — every non-matching input is an explicit "unknown," never an accidental action.

---

## Concept 12 — DISARMED gating

**Simple explanation.** The console refuses all *mutating* commands (`set`, `save`, `load`, `reset`)
while the car is **armed**. Read-only commands (`get`, `status`, `help`) are always allowed.

**Why embedded systems need it.** Tuning is a "pit-lane" activity — you change settings on a car
that isn't about to move. Letting someone re-tune (or reload/reset) a *live, armed* car mid-drive
could change its behaviour dangerously. Gating the verbs on disarmed state prevents that.

**How this project uses it.** A single check near the top of `handleLine`, before any mutating
command runs.

**Relevant C9b code.**
```cpp
if ((isSet || tokEq(c0,c0e,"save") || tokEq(c0,c0e,"load") || tokEq(c0,c0e,"reset")) && armed) {
    say(r, "refused: disarm to change settings (tuning is a pit-lane activity)");
    return r;
}
```

**Common beginner misunderstanding.** "The console reads the arm state itself." No — `armed` is
*passed in* by the caller. C9b proves the console *obeys* the flag; whether main.cpp feeds the true
arm state is C10 wiring (PROVISIONAL).

**What bug this prevents.** It prevents changing calibration/gears on a moving, armed car — keeping
tuning a deliberate, stopped-car activity.

---

## Concept 13 — Validation before applying changes (trial-copy)

**Simple explanation.** A `set` writes the new value onto a *copy* of the settings, checks that the
copy is valid, and only then commits it to the live settings. An invalid value never touches the
live config.

**Why embedded systems need it.** An out-of-range value (a trim that peg the servo, a gear table
that isn't monotone) must never reach the modules. Validating a copy first means a bad edit is
rejected with the live config completely untouched — not half-applied.

**How this project uses it.** `next = s` (copy) → set the field on `next` → `next.valid()` (the C9a
aggregate) → commit `s = next` only if valid.

**Relevant C9b code.**
```cpp
settings::Settings next = s;   // trial copy
...
if (isSet) next.steering.trimMicros = static_cast<int16_t>(v);   // onto the COPY
...
if (isSet) {
    if (!next.valid()) { say(r,"rejected: value out of range / would violate config invariants"); return r; }
    s = next;   // commit only if valid
    r.settingsChanged = true;
}
```

**Common beginner misunderstanding.** "The value is written, then checked, then undone if bad." No —
it's written to a *copy*, checked, and the live value is assigned *only if valid*. There's no "undo"
because the live settings were never changed on the reject path. (Test: `set steer.trim 2000` →
rejected, live trim stays 0.)

**What bug this prevents.** It prevents ever applying an invalid config — no partially-applied or
transiently-bad state can reach the actuators. This is the runtime cousin of C9a's deserialize
`valid()` guard.

---

## Concept 14 — Failure handling

**Simple explanation.** Every risky operation returns a success/failure result, and the code keeps
the live settings safe on failure: a failed `save` reports "SAVE FAILED" and changes nothing; a
failed `load` reports "no valid saved settings" and leaves RAM untouched.

**Why embedded systems need it.** Storage can fail (flash error, first boot, corrupt/old blob). The
firmware must degrade gracefully — never crash, never apply garbage, always keep a valid live
config.

**How this project uses it.** The store returns `bool`; the runner branches on it. Loaded bytes go
through the C9a guard chain into a *local* first, so a bad load never overwrites RAM.

**Relevant C9b code.**
```cpp
io_.write(store_.save(buf, n) ? "saved\r\n" : "SAVE FAILED\r\n");   // save failure: RAM unchanged
...
if (store_.load(buf, sizeof(buf), len) && settings::deserialize(buf, len, loaded)) {
    settings_ = loaded; changedOut = true; io_.write("loaded\r\n");
} else io_.write("no valid saved settings\r\n");                    // load failure: RAM unchanged
```

**Common beginner misunderstanding.** "If load fails, the settings become empty/garbage." No — on
any load failure the live `settings_` is left exactly as it was (the deserialized value lives in a
*local* until success). Failure is safe, not destructive.

**What bug this prevents.** It prevents a storage failure from corrupting the running config — the
never-brick discipline (C9a) extended into the live lifecycle: no failure path applies bad settings.

---

## Concept 15 — What native tests prove

**Simple explanation.** The native tests compile the *pure logic + mocks* for your laptop and run
them (no ESP32). They prove the console grammar, the DISARMED gate, the trial-copy validation, the
runner's line assembly and save/load plumbing, and the module `setConfig`s — all logic.

**Why embedded systems need them.** Fast, deterministic, repeatable checks of the behaviour without
a chip. Most bugs (bad parsing, missing gate, unhandled failure) are logic bugs these catch
instantly.

**How this project uses it.** `pio test -e native -f test_console` → 15/15 PASSED: get/set,
armed-refusal, out-of-range/monotonicity rejection, unknown handling, reset-RAM-only, runner
set→save→persist round-trip (via the mock store), armed-blocks, overlong-line guard, boot-load, and
the three module `setConfig`s.

**Relevant C9b code.** The end-to-end persistence-logic proof (through the mock):
```cpp
io.feed("set steer.trim 30\nsave\n");
runner.poll(false);
TEST_ASSERT_EQUAL_UINT32(1, store.saveCount);
Settings back;
TEST_ASSERT_TRUE(settings::deserialize(store.stored, store.storedLen, back));
TEST_ASSERT_EQUAL_INT16(30, back.steering.trimMicros);   // the persisted blob round-trips
```

**Common beginner misunderstanding.** "15/15 green = the console works on the car." No — it proves
the *logic*, using a mock store and mock serial. Real flash and real UART are untested (Concept 16).

**What bug this prevents.** They lock in the behaviour so a later change that breaks (say) the
DISARMED gate or the trial-copy validation fails a test immediately, before it can ship.

---

## Concept 16 — What hardware testing must still prove

**Simple explanation.** The two `settings_hal_esp32` files (NVS store, UART0 serial) touch real
hardware and are excluded from native tests. So the bench must still prove the *real* flash and
serial behaviour.

**Why embedded systems need this stage.** Perfect logic doesn't guarantee the flash actually
persists across power cycles, survives wear/partial writes, or that UART0 reads/writes at 115200 on
the real board. Only the bench closes that loop.

**How this project frames it.** All flash/serial reality is marked PROVISIONAL and tracked as open
questions #34a (persistence: save→power-cycle survives; version-bump→reflash falls back to
defaults) and #34b (UART0 console on the bench; and how the *console-free* gift firmware loads
saved settings — a C10 question. *C10 answer (2026-07-05): it doesn't — the plain build has no
load path; see the C10 doc §8 and open question #49*).

**Relevant C9b code (the boundary marker).** These files include hardware headers, so they never
enter the native test build:
```cpp
#include <Preferences.h>   // Esp32NvsStore.cpp — hardware-only
#include <Arduino.h>       // Esp32SerialConsole.cpp — hardware-only
```

**Common beginner misunderstanding.** "The store round-trip test proves persistence." It proves the
*logic* round-trips through a RAM mock — not that a real chip keeps the blob with the power off.

**What bug this prevents (by scheduling it).** Naming the boundary prevents shipping with an
*assumed*-working flash/serial path. The version-bump fallback in particular can only be tested on a
device that has a genuinely old blob in NVS — a pure test can't create that.

---

## 20 Quiz Questions

1. Name the two separate copies of the settings and say which one the control loop actually reads.
2. You `set steer.trim 40` and immediately power-cycle without saving. Is the trim still 40 on the
   next boot? Why?
3. In one sentence each, contrast `set` vs `save`.
4. In one sentence each, contrast `load` vs `reset`. Which one reads flash, which uses `kDefaults`?
5. Does `reset` erase the saved blob in flash? Does `load` write to flash? Explain both.
6. What is NVS, and what is `Preferences`' relationship to it?
7. Why must the design avoid writing to flash on every value change? Name the physical limit.
8. `ConsoleRunner` holds a `hal::ISettingsStore&`, not an `Esp32NvsStore`. Why does that indirection
   matter for testing?
9. What does `MockSettingsStore` prove, and what can it *not* prove?
10. Why does `Esp32SerialConsole::read()` return −1 when no byte is available, instead of waiting?
    What bad outcome does that prevent?
11. `parseInt` accepts `"40"` but rejects `"40x"`. Which exact expression enforces that, and what
    does it mean?
12. Why are channels *read-only* in the console grammar? Where does the channel map live?
13. Which four commands are refused while armed, and which three are always allowed? Why is that
    split a safety choice?
14. Is the `armed` flag read by the console itself, or passed in? What is therefore still
    PROVISIONAL until C10?
15. Walk through `set steer.trim 2000` (disarmed). Onto which object is 2000 written first, what
    rejects it, and what is the live trim afterward?
16. Why is the trial-copy pattern safer than "write the value, then validate, then undo if bad"?
17. A `save` fails (store returns false). What does the user see, and what happens to the live RAM
    settings?
18. A `load` at boot finds a corrupt blob. What does the car run on, and which C9a mechanism decides
    that?
19. The console tests are 15/15 green. State two specific things about the *real car* those tests do
    not prove, and where they're tracked.
20. The gift firmware is built *without* the tuning console. Can it still use previously-saved
    calibration? What batch answers *how* it loads them?

---

## Answer Key

1. The **live RAM copy** (`settings_`, owned by `ConsoleRunner`) — which the control loop reads —
   and the **persistent blob in flash**. The loop reads the RAM copy.
2. **No.** `set` is RAM-only; without `save`, the change never reached flash, and RAM is wiped on
   power-off. Next boot loads flash (unchanged) or defaults.
3. `set` = change the live RAM value (validated first). `save` = copy the current RAM values into
   flash.
4. `load` = copy the *last-saved* values from **flash** into RAM. `reset` = set RAM to the
   **compile-time `kDefaults`**, ignoring flash. `load` reads flash; `reset` uses `kDefaults`.
   Neither persists.
5. `reset` does **not** erase flash (your saved blob stays until you `save`); `load` does **not**
   write flash (it only reads flash into RAM).
6. NVS = the ESP32's managed non-volatile (flash) key→value storage; `Preferences` is the Arduino
   library that wraps NVS with a simple save/load-named-blob API.
7. Flash **wears out** — it tolerates only a finite number of erase/write cycles per region. Writing
   on every change (50×/s) would burn through that budget; hence RAM edits + a deliberate `save`.
8. The runner depends on the *interface*, so tests plug a `MockSettingsStore` (RAM) and the car
   plugs `Esp32NvsStore` (flash) — same code, no hardware needed for tests.
9. It proves the *logic around* storage (save records / load returns / first-boot returns nothing /
   round-trips). It cannot prove real flash persists across power cycles, wear, or partial-write
   safety.
10. To be **non-blocking** — the control loop must never freeze waiting for a human to type; a
    blocking read would stall the 50 Hz failsafe/output loop.
11. `endptr == buf + n` — it means `strtol` consumed the *entire* token, so trailing junk like
    `"40x"` (where `endptr` stops at `x`) is rejected.
12. Because the **channel map is not part of `Settings`** (it's not tunable, C9a); `status` shows
    default channel numbers as a reminder, but there is no `set` for them.
13. Refused while armed: **`set`, `save`, `load`, `reset`.** Always allowed: **`get`, `status`,
    `help`.** Mutating a live/armed car's config could change behaviour dangerously; inspecting it
    can't. Tuning is a stopped-car ("pit-lane") activity.
14. **Passed in** by the caller. That main.cpp feeds the *true* arm state is C10 wiring —
    PROVISIONAL. C9b only proves the console *obeys* the flag.
15. 2000 is written onto the **trial copy `next`** (`next.steering.trimMicros = 2000`); `next.valid()`
    fails (center 1500 + trim 2000 = 3500 > max 2500, the A11 rule); the function returns without
    `s = next`, so the **live trim stays 0**.
16. Because the live settings are **never changed on the reject path** — there's nothing to "undo."
    A partially-applied/transiently-bad live config can't occur; only a fully-valid config is ever
    committed.
17. The user sees **"SAVE FAILED"**; the live RAM settings are **unchanged** (a failed persist
    doesn't lose or alter what's in RAM).
18. It runs on **`kDefaults`**; the C9a **deserialize guard chain** (length→CRC→version→`valid()`)
    rejects the corrupt blob, and `loadAtBoot` falls back to defaults.
19. Any two of: that real NVS persists across power cycles / survives wear / survives partial writes;
    that a version-bump + reflash falls back to defaults on a real device; that UART0 reads/writes
    at 115200 on the bench. Tracked in `open_questions.md` #34a and #34b.
20. *(corrected by C10, 2026-07-05)* **No.** The saved blob *persists in flash*, but the plain
    `esp32dev` build compiles out the **entire** settings subsystem (`#ifdef W17_TUNING_CONSOLE`
    around the includes, objects, and the boot load) — there is **no load path**, so the gift
    firmware runs compiled-in defaults. *(This answer originally said "Yes … can still be loaded
    at boot," anticipating a load path C10 was expected to find; main.cpp proved otherwise — see
    the C10 doc §8 and open question #49.)*

---

## Things to review before C10

- **The pure-decision vs. side-effect split** — `Console` returns a `Result`; `ConsoleRunner` acts.
  C10 wires the runner to real seams and applies `settings()` to the modules, so be solid on *who
  does what* (Concept 7, 13, 14).
- **`set`/`save`/`load`/`reset` semantics** — the RAM-vs-flash table. C10 decides when `loadAtBoot`
  and `poll` are called and where `armed` comes from (Concept 3, 4, 12).
- **DISARMED gating and its PROVISIONAL edge** — the console obeys `armed`; C10 supplies the real
  arm state (Concept 12).
- **Trial-copy validation as the runtime never-brick** — no invalid config reaches the modules
  (Concept 13); pairs with C9a's load-time guard.
- **Build-flag-gated subsystems** — the console exists only under `W17_TUNING_CONSOLE`; the gift
  firmware omits it. C10's `platformio.ini` is where those envs live (Concept 16).
- **What native tests do and don't prove** — carry the "green ≠ shipped" discipline into C10, which
  ties hardware-only pieces together in `main.cpp` (Concept 15, 16).

---

## "Am I ready for C10?" checklist

Tick honestly. If any is shaky, re-read the linked concept (and, if useful,
`09b_console_tuning_and_settings_store.md`) before starting C10.

- [ ] I can name the two settings copies (live RAM vs persistent flash) and say which the car runs
      on.
- [ ] I can explain `set` vs `save` and why they're separate (flash wear + deliberate persistence).
- [ ] I can explain `load` vs `reset` and confirm neither persists on its own.
- [ ] I can explain what NVS/`Preferences` is and why flash writes must be rare.
- [ ] I can explain why the runner depends on `ISettingsStore` (the seam) and how the mock replaces
      the real store in tests.
- [ ] I can explain why `read()` is non-blocking and what it prevents.
- [ ] I can explain the trial-copy validation and why it means no invalid value reaches the live
      settings.
- [ ] I can describe what a failed `save`/`load` does (and does *not* do) to the live settings.
- [ ] I can state which four commands the DISARMED gate blocks, and what's still PROVISIONAL about
      the `armed` flag until C10.
- [ ] I can name two things the 15/15 native tests do **not** prove and where they're tracked.
- [ ] I understand that C10 supplies the wiring: constructing the runner with real seams, the poll
      cadence, the true arm state, and applying `settings()` to the modules — plus the C10
      *finding* that the console-free gift build does **not** load saved settings at all (C10 §8).

When most boxes are ticked, you're ready for **C10 — The conductor: `main.cpp` + sim + build
configs.**

---

*This is a study companion; it changes no source and reads no C10 file. The authoritative
line-by-line explanation remains `09b_console_tuning_and_settings_store.md`.*
