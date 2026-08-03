# W17 mapper — hand-entered node-graph config record

**Created:** 2026-08-03 · **Status:** IN PROGRESS (entry underway)

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

**Fix proposed: `inactive_value` = −32768 on the button node.** ⚠ **Attribution downgraded
2026-08-03 (pre-merge review): this line originally read "Fix chosen (owner, 2026-08-03)" and
the owner has not confirmed it.** The record did not distinguish *decision taken* from *decision
proposed*, which is the same conflation this workspace already corrected once for parts — an
owner's word for "a battery" was arrival evidence for *a* pack, never the expected one. The same
applies to decisions. **Treat as PROPOSED until the owner confirms; do not enter it as settled.**
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
- The failsafe value **bypasses `MapRange`** — `output_tx.go:92` writes it straight into
  `Values` — so 172 goes on the wire as raw 172 regardless of the endpoint fix.
- `decodeTriState` returns `1` for any normalized value within ±333
  (`ChannelDecoder.cpp:94-101`), confirming ch13 at 992 → RACE.

## UI traps to expect during entry

- The `crsf` autocomplete offers **only 0 / 992 / 1984**
  (`webapp/src/components/misc/autocomplete.jsx:73-78`). **172 is not in the list**, and the
  nearest offered value — "CRSF Min (0)" — is the one the schema explicitly warns against.
  The field is `freeSolo` (`GenericForm.jsx:135`) and `visitIntegerField` `parseInt`s it
  (`node-access-base.jsx:335-336`), so **172 must be typed by hand** and does persist.
- `onAutoChange` debounces **250 ms** (`GenericForm.jsx:82-90`) — **type, pause, then save.**
- The `raw` autocomplete *does* offer −32768 ("RAW Min"), so the DEFECT 2 value is selectable
  rather than typed (`autocomplete.jsx:79-86`).
- With no TX connected, the transmitter port autocomplete falls back to a synthetic
  `COM1..COM16` list (`autocomplete.jsx:67-71`) — those are placeholders, not detected
  hardware.

---

## Entered values

_Filled in as each node is entered. Nothing recorded here has been entered yet._

### Node inventory (planned)

| # | Node type | Purpose | Status |
|---|---|---|---|
| 1 | `gamepad` | device id for all inputs | ⬜ not entered |
| 2 | `axis` ×4 | steering, throttle, pan, tilt | ⬜ not entered |
| 3 | `button` ×6 | arm, DRS, gear-up, gear-down, boost, overtake | ⬜ not entered |
| 4 | ch13 source | 3-position drive mode — **node type OPEN, see below** | ⬜ not entered |
| 5 | `channel` ×11 | ch1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13 | ⬜ not entered |
| 6 | `tx` | port + channels array | ⬜ not entered |

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

  **Consequence for entry order:** keeping ch1–ch12 as plain `channel` nodes at top level sidesteps
  D entirely today, and ch13 is the only place a wrapper is currently planned. So this is a
  deliberate decision to take **before** entry, not something to discover at the bench. Three ways
  out, owner's call: pick `hat`; keep `switch`/`case` but nest it *under* a `channel` node rather
  than at top level (verify that actually avoids the asymmetry before relying on it); or hold ch13
  until the D fix lands. It still does not block ch1–ch12.
