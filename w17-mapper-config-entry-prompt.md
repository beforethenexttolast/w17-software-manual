# Session prompt — build the mapper channel-node graph by hand (bench prep, no hardware)

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware powered.** This is
the config that decides whether the car can arm at all — with mapper defaults, **it cannot**.

---

I'm building the `w17-mapper` node graph in the webapp UI by hand. Guide me field by field; I type,
you check each value against the firmware and record what was entered.

## Why this session exists

The 2026-07-30 investigation (see *VR-FPV batch status* in `CURRENT_STATUS.md`) found:

- **No persisted mapper config exists on this Mac in any form.** The webapp keeps the live graph in
  browser `localStorage` only (`webapp/src/components/misc/storage.jsx`); it becomes a file only on
  an explicit save-to-file. Chrome localStorage was enumerated — 37 origins, no `localhost` or
  `127.0.0.1` at all. The repo carries only `default-config.json` and `mock-device-fields.json`.
- **Owner decision: the graph is built in the UI by hand and NOT committed** — the `read` nodes bind
  to a gamepad device id not visible from this Mac, so a committed config would be guesswork, and
  `630ea96` already made "no config" the safe state (no frames → the receiver's own link-loss
  failsafe fires). An unverified tracked config would replace a safe state with a wrong one.

## The two defects to fix while entering it

**DEFECT 1 — with default endpoints the car can never arm.** `ChannelT.UnmarshalJSON` defaults
`crsf_min`/`crsf_max` to `util.CRSFMinValue`/`CRSFMaxValue` = **0 / 1984**, and `util.MapRange` clamps
to exactly those. Both fall **outside** the firmware's `kChannelRawPlausibleMin/Max` = **100 / 1900**
band established by control-fw `91f830f`, so full deflection decodes as **absent** (analog 0 / switch
OFF). A button's ON value is `DefaultTruthyRawValue` = 32767 → 1984 → implausible → **arm forced OFF**.
→ **Set `crsf_min` = 172, `crsf_max` = 1811 on every channel node.** Full deflection then lands on the
CRSF anchors and normalizes to exactly ±1000. No firmware change needed.

**DEFECT 2 — a button-fed switch channel sits at CENTER when OFF.** With default `raw_min`/`raw_max`
= −32768/32767, a button's OFF value (`DefaultFalsyRawValue` = 0) is mid-range and maps to ≈**991** —
inside the decoder's ±250 dead band, so `decodeSwitch` **holds the previous state**. Same failure
class as the `2dc7c5a` gap but reachable with the gamepad fully connected.
→ **Make OFF reach the channel's `raw_min`** — either `raw_min` = 0 on the channel node, or
`inactive_value` = −32768 on the button node.

## Per-channel failsafe values

**172** on the six `decodeSwitch` channels — **ch5 arm, ch6 DRS, ch7 gear-up, ch8 gear-down,
ch11 boost, ch12 overtake**. Leave the **992** default on the analog channels — **ch1 steering,
ch3 throttle** (note: throttle is `throttleIndex = 2` → ch**3**, not ch2), **ch9 pan, ch10 tilt**.
**ch13 drive mode keeps 992** even though it is switch-like: it decodes through `decodeTriState`, and
center → `1` = RACE, the safe middle; 172 would force TRAINING on a dropout. The failsafe value
bypasses `MapRange` (`output_tx.go:92` writes it straight into `Values`), so 172 goes on the wire as
raw 172 regardless of the endpoint fix.

## ⚠ PREREQUISITE — every channel number above is conditional

`ChannelMapConfig`'s indices are **labelled placeholders** in
`w17-control-fw/lib/channels/include/channels/ChannelDecoder.hpp:10-12` ("DEFAULTS ARE PLACEHOLDERS …
verify every assignment at the bench and remap HERE only"). The table is correct *relative to the
firmware's current map* — **confirm the TX assignments at the bench first**, or the 172s land on the
wrong channels. Start this session by telling me whether that verification has happened; if it hasn't,
we enter the config but mark the channel numbers PROVISIONAL and do not treat arming as ready.

Two supporting checks already done: raw **172 → −1000** (`normalizeRaw` is exact at 172/992/1811),
well below `switchOffBelow` = −250, so 172 is unambiguously OFF and not a dead-band value; and there
is **no per-switch inversion** in the firmware, so nothing on either side can flip 172 into ON.

## UI trap

The `crsf` autocomplete offers only **0 / 992 / 1984** — **172 is not in the list**, and the nearest
offered value, "CRSF Min (0)", is the one the schema explicitly warns against. The field is `freeSolo`
(`GenericForm.jsx:135`) and `visitIntegerField` `parseInt`s it, so **172 must be typed by hand** and
does persist. `onAutoChange` debounces 250 ms — **type, pause, then save.**

## What to produce

A record of exactly what was entered, per node, in a workspace-root doc (not committed into
`w17-mapper`). Then update `CURRENT_STATUS.md`: config entered, PROVISIONAL-or-verified on the channel
map, and note that it lives in browser localStorage only and is lost if that store is cleared —
recommend an explicit save-to-file as a local backup outside the repo.

**Safety:** the mapper may run for UI purposes only. **Nothing connected to the car, no TX bound, no
ESC, no servos, no battery.** A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Do not commit a config
into `w17-mapper` — nothing in this session commits to that repo at all, so the only branch involved is
in the **workspace** repo, off its `main`. Show diffs before committing.
