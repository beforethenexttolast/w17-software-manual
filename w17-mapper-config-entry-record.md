# W17 mapper — hand-entered node-graph config record

**Created:** 2026-08-03 · **Last updated:** 2026-08-04 · **Status:** IN PROGRESS (entry underway)

**Verified against `w17-mapper` `9ba6e06` and `w17-control-fw` `fff1ab7` on 2026-08-04.** All
source claims below were re-checked at those heads; two citations had drifted and are corrected
in place (see *Supporting checks* and *UI traps*).

> **This file is a record of what was typed into the mapper webapp UI. It is not a config.**
> It lives at the workspace root and is **deliberately NOT committed into `w17-mapper`**
> (see "Why nothing is committed" below).

---

## ⚠ Safety envelope for this session

Nothing connected to the car. **No TX bound, no ESC, no servos, no battery.** The mapper runs
for UI purposes only. **A2 stays NOT-EXECUTED. Phase B stays BLOCKED.**

## ⚠ The channel numbers below are PROVISIONAL

The firmware channel map has **not** been bench-verified against the TX. Verified 2026-08-03
by the checks below. ⚠ **Framing corrected 2026-08-03 (pre-merge review):** these are **two
independent lines of evidence plus three restatements**, not five independent checks. Check 1 is
load-bearing and carries the conclusion on its own; check 3 is semi-independent (a different axis —
the Windows enumeration path); checks 2, 4 and 5 all collapse into the single proposition *nothing
physical has happened*. The conclusion stands; only the "five independent checks" claim was
overstated. Line-number citations replaced with section references, which do not drift:

1. The placeholder banner is still present at HEAD —
   `w17-control-fw/lib/channels/include/channels/ChannelDecoder.hpp:9-11`: "DEFAULTS ARE
   PLACEHOLDERS … confirm every assignment at the bench and remap HERE only." Had the
   verification happened, that comment is what would have been edited.
2. Nothing is soldered; A2 `NOT EXECUTED` (`CURRENT_STATUS.md` → *Hardware gates*).
3. `ELRS TX enumeration on real Windows: UNVALIDATED` (`CURRENT_STATUS.md` → *Pending
   validations*). The TX
   arrived 2026-07-17 but no macOS host can exercise that path.
4. No bench work recorded between the 2026-07-30 entry that raised the prerequisite and
   today; the 2026-08-03 pass was source verification only.
5. It could not be done in this session either — the safety envelope forbids binding a TX.

**Therefore the channel assignments here are correct *relative to the firmware's current
map* and nothing more. Arming is NOT ready.** If the bench later shows a different TX
assignment, every `failsafe` value below lands on the wrong channel.

**Re-verified 2026-08-04 at `w17-control-fw` `fff1ab7` — still PROVISIONAL, nothing has moved.**
The load-bearing check was re-run: the placeholder banner is present at HEAD, and the only two
commits that have *ever* touched `ChannelDecoder.hpp` are `37ebe46` and `8ce670a`, both docs-only
(retiring stale gimbal comments; aligning link2 gear/drive-mode docs) — **neither is a remap**. A2
is still `NOT-EXECUTED` and Phase B still `BLOCKED` as of the newest `CURRENT_STATUS.md` entry, and
`ELRS TX enumeration on real Windows` is still `UNVALIDATED`. This session's own envelope forbids
binding a TX, so it could not be closed here either.

## Why nothing is committed into `w17-mapper`

The `read`/gamepad nodes bind to a gamepad device id not visible from this Mac, so a
committed config would be guesswork. `630ea96` already made "no config" the safe state — no
config resolves ⇒ no channel frame is sent ⇒ the receiver's own link-loss failsafe fires. An
unverified tracked config would replace a safe state with a wrong one.

---

## The two defects being corrected during entry

### DEFECT 1 — with default endpoints the car can never arm

`ChannelT.UnmarshalJSON` defaults `crsf_min`/`crsf_max` to `util.CRSFMinValue`/`CRSFMaxValue`
= **0 / 1984** (`pkg/config/input_channel.go:55-63`), and `util.MapRange` clamps to exactly
those (`pkg/util/util.go:21-23`). Both fall outside the firmware's
`kChannelRawPlausibleMin/Max` = **100 / 1900** band from control-fw `91f830f`, so full
deflection decodes as **absent** (analog 0 / switch OFF). A button's ON value is
`DefaultTruthyRawValue` = 32767 → 1984 → implausible → **arm forced OFF**.

**Fix applied:** `crsf_min` = **172**, `crsf_max` = **1811** on *every* channel node. Full
deflection then lands on the CRSF anchors and normalizes to exactly ±1000. No firmware
change needed.

### DEFECT 2 — a button-fed switch channel sits at CENTER when OFF

With default `raw_min`/`raw_max` = −32768/32767, a button's OFF value
(`DefaultFalsyRawValue` = `ZeroRaw` = 0, `pkg/util/util.go:37`) is mid-range and maps to
≈991 — inside the decoder's ±250 dead band, so `decodeSwitch` **holds the previous state**.

✅ **Fix DECIDED (owner, 2026-08-04): `inactive_value` = −32768 on the button node.** The owner
was asked explicitly, with the rejected alternative presented alongside, and chose this one.

> *Attribution history, kept because the correction is the point:* this line first read "Fix
> chosen (owner, 2026-08-03)" when no owner had confirmed it; the 2026-08-03 pre-merge review
> downgraded it to PROPOSED. It is now genuinely decided — the 2026-08-04 confirmation is what
> promoted it, not the passage of time.

The
rejected alternative was `raw_min` = 0 on the channel node; it was rejected because it leaves
a live trap — if that channel's input is ever re-pointed from a button to an axis, an axis at
rest (raw 0) would map to `crsf_min` = 172, which normalizes to −1000, i.e. a centred stick
reading as full deflection. Putting the fix on the button node keeps all channel nodes
identical in raw range.

---

## Per-channel failsafe rationale

| Channel | Control | Decoder path | Failsafe | Why |
|---|---|---|---|---|
| ch1 | steering | `normalizedAnalog` | **992** | centre is the safe neutral |
| ch3 | throttle | `normalizedAnalog` | **992** | centre = neutral. Note `throttleIndex = 2` → ch**3**, not ch2 |
| ch5 | arm | `decodeSwitch` | **172** | OFF rail; 992 would hold the previous armed state |
| ch6 | DRS | `decodeSwitch` | **172** | OFF rail |
| ch7 | gear-up | `decodeSwitch` | **172** | OFF rail |
| ch8 | gear-down | `decodeSwitch` | **172** | OFF rail |
| ch9 | gimbal pan | `normalizedAnalog` | **992** | centre |
| ch10 | gimbal tilt | `normalizedAnalog` | **992** | centre |
| ch11 | ERS boost | `decodeSwitch` | **172** | OFF rail |
| ch12 | ERS overtake | `decodeSwitch` | **172** | OFF rail |
| ch13 | drive mode | `decodeTriState` | **992** | centre → `1` = RACE, the safe middle. **172 would force TRAINING on a dropout.** |

Supporting checks (verified against source this session):

- `172 → −1000`: `normalizeRaw` is exact at the anchors 172/992/1811
  (`ChannelDecoder.cpp:23-38`), well below `switchOffBelow` = −250, so 172 is unambiguously
  OFF and not a dead-band value.
- **No per-switch inversion exists** in the firmware — the header calls it a deliberately
  deferred extension point, and `invert*` applies only to `normalizedAnalog`. Nothing on
  either side can flip 172 into ON.
- The failsafe value **bypasses `MapRange`** — `output_tx.go` writes it straight into `Values`
  (`(*i.Values)[number-1] = owner.FailsafeValue()`) — so 172 goes on the wire as raw 172
  regardless of the endpoint fix. ⚠ **Citation corrected 2026-08-04: this read `output_tx.go:92`,
  which drifted when `c60843e` landed; the write now happens at two sites (lines 293 and 325 at
  `9ba6e06`), one per failsafe path. Behaviour is unchanged — both bypass `MapRange`.** Cited by
  code rather than line, since line numbers in this file have now drifted twice.
- `decodeTriState` returns `1` for any normalized value within ±333
  (`ChannelDecoder.cpp:94-101`), confirming ch13 at 992 → RACE.

## UI traps to expect during entry

- The `crsf` autocomplete offers **only 0 / 992 / 1984**
  (`webapp/src/components/misc/autocomplete.jsx:73-78`). **172 is not in the list**, and the
  nearest offered value — "CRSF Min (0)" — is the one the schema explicitly warns against.
  The field is `freeSolo` (`GenericForm.jsx:135`) and `visitIntegerField` `parseInt`s it
  (`node-access-base.jsx:335-336`), so **172 must be typed by hand** and does persist.
- ⚠ **ADDED 2026-08-04 — the trap above also applies to the `failsafe` field, which this list
  previously did not mention.** `failsafe` is `$meta.autocomplete: crsf` in `pkg/config/schema.yaml`
  (title "Failsafe CRSF value", `default: 992`), so its dropdown offers the same 0 / 992 / 1984 and
  **the six 172s must be hand-typed there too**. Same freeSolo path, same 250 ms debounce. The field
  *is* present in the UI — the form is generated from the embedded schema, so there is no
  fork-specific React component to grep for, and its absence from `webapp/src` is not evidence of
  absence from the form. The schema's own description already prescribes the value: "Switch-like
  channels should not be left at center … Set those channels to their OFF rail instead — typically
  `172`."
- `onAutoChange` debounces **250 ms** (`GenericForm.jsx:82-90`) — **type, pause, then save.**
- The `raw` autocomplete *does* offer −32768 ("RAW Min"), so the DEFECT 2 value is selectable
  rather than typed (`autocomplete.jsx:79-86`).
- With no TX connected, the transmitter port autocomplete falls back to a synthetic
  `COM1..COM16` list (`autocomplete.jsx:67-71`) — those are placeholders, not detected
  hardware.
- ⚠ **ADDED 2026-08-04 — the `gamepads` autocomplete has NO such fallback.** It returns whatever
  `getGamepads()` yields and an **empty map** otherwise (`autocomplete.jsx:123-133`), with no
  synthetic entries. So the gamepad `id` field is blank-with-no-options when no pad is attached.
  Every auto-complete field in this form is `freeSolo` (`GenericForm.jsx:135` — it is set on the
  shared `Autocomplete`, not per field), so an id *can* be typed blind, **but a typed-blind id is
  exactly the guesswork this session exists to avoid**: `GetInputGamepad` would not resolve it, and
  post-`c60843e` an unresolvable device drives every owned channel to its failsafe rail. **Attach
  the pad before entering node 1 and pick the id from the list.**

---

## Entered values

_Filled in as each node is entered. Nothing recorded here has been entered yet._

### Node inventory (planned)

Revised 2026-08-04 after the ch13 deferral: **10** `channel` nodes in this pass, not 11.

| # | Node type | Purpose | Status |
|---|---|---|---|
| 1 | `gamepad` ×1 | device id for all inputs | ⬜ not entered |
| 2 | `axis` ×4 | ch1 steering, ch3 throttle, ch9 pan, ch10 tilt | ⬜ not entered |
| 3 | `button` ×6 | arm, DRS, gear-up, gear-down, boost, overtake | ⬜ not entered |
| 4 | `channel` ×10 | ch1, 3, 5, 6, 7, 8, 9, 10, 11, 12 | ⬜ not entered |
| 5 | `tx` ×1 | port + channels array (10 entries this pass) | ⬜ not entered |
| — | ch13 source + `channel` | 3-position drive mode | ⏸ DEFERRED by owner choice, not blocked — see the 2026-08-04 update above |

### Open items

- **ch13 drive mode source node type is undecided — and as of 2026-08-03 the choice carries a
  safety dimension, not just an ergonomic one.** It needs three distinct levels (low = TRAINING,
  mid = RACE, high = ERS). A gamepad has no native 3-position control, so this needs either a
  `hat` node or a `switch`/`case` construct.

  ⚠ **`switch` and `case` are two of the six node types implicated in RESIDUAL D** (see
  `CURRENT_STATUS.md` → *VR-FPV batch status*). At the **top level** of a transmitter's `channels`
  array they propagate `ch` on the healthy path and `-1` on nan, which strands the slot — the
  original throttle-freeze defect, on a path the `2dc7c5a` fix does not reach. A `hat` node does
  not have this property.

  ✅ **RESOLVED 2026-08-03 (owner): enter ch1–ch12 now as plain `channel` nodes; HOLD ch13 until the
  B+D fix lands.** Not a deferral for its own sake — it is the only route that neither relies on an
  unverified sidestep nor forces an architecture decision under time pressure:

  - `switch`/`case` **at top level** is D-1. Rejected.
  - **`channel`-wrapping** the construct *should* be safe, because `channel` is the sole originator of
    a channel number and reports it on every path — but that is a "should," and this defect chain has
    already punished three unverified "shoulds." Rejected **as a load-bearing assumption**; it becomes
    available once someone executes it.
  - **`hat`** is genuinely clean (always-`-1` class, no wrapper at all). **Take it if three positions
    on a D-pad is ergonomically acceptable** — that is the one route that would let ch13 be entered
    today.
  - **Holding costs nothing.** `decodeTriState` returns `1` = RACE at center by design, so an
    **unmapped ch13 already sits in its safe middle**, and drive mode is not needed for first arming.
    Once B+D lands, `switch`/`case` is free to use and the question dissolves.

  Nothing here blocks ch1–ch12.

  ### ⏫ UPDATE 2026-08-04 — the hold condition is SATISFIED, and the choice is deferred by choice

  **B+D landed.** `w17-mapper` `f81ec63` → **`9ba6e06`** (`c60843e` fix + `9ba6e06` GPL §5(a)
  table), 2026-08-04. D-partial is closed **"for every shape in which a top-level entry's subtree
  stops resolving, whether or not the entry's own result stays usable"**, and the unusable-result
  path explicitly **still drives ALL owners** — the dated entry names `switch` fallthrough as the
  reason it must. **`switch`/`case` at top level is therefore no longer D-1**, and the reason this
  item was held has gone.

  Still open and deliberately not folded in: **`InputRead._Eval`'s unguarded recursion** (a `read`
  cycle kills the process by stack overflow, pre-existing upstream at `2b8031a`). It does not touch
  this decision — no `read` node appears anywhere in this graph. **RESIDUALS A and C remain open.**

  ✅ **DECIDED 2026-08-04 (owner): decide ch13's node type AFTER ch1–ch12 are entered.** All three
  routes — `switch`/`case`, `channel`-wrapped, `hat` — are now available; none is blocked. This is a
  deferral of a now-free choice, **not** the earlier safety hold, and the two must not be conflated
  in any later reading of this file. The cost of deferring is still nil, for the reason above:
  `decodeTriState` returns `1` = RACE at center, so an unmapped ch13 sits in its safe middle.
