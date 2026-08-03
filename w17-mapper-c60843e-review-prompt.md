# Session prompt — targeted review of the D-partial / D-3 fix (`w17-mapper` `c60843e`)

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.**

> **Opus 5 at `xhigh`.** Fable if you specifically want the sixth error hunted — five consecutive
> passes on this code have each contained one, and this fix adds new mutable state, which is where the
> next one most plausibly lives. **Tightly scoped: this is not a full re-review.**

---

Review `w17-mapper` `c60843e` ("neutralize per owner, and fail safe when the walk truncates") plus its
docs commit `9ba6e06`. **Do not merge, do not push, do not fix** — report, and propose diffs for
anything small.

```bash
git -C w17-mapper log --oneline f81ec63..9ba6e06
git -C w17-mapper diff f81ec63..9ba6e06
```

## What is already established — do not re-derive

The `e452d55` review covered the walk, the swap gate, composition, cost, and the guards, and its
findings were acted on. `CURRENT_STATUS.md` → *VR-FPV batch status* carries the settled picture.
**Assume all of that.** Three things in `c60843e` were verified when it landed and need no re-proof:
the neutralization loop now runs on the **usable** path too (ordered after the channel write so a
failed owner overrides the reported channel), truncation is fail-safe via a per-port `Unresolved`
flag, and that flag is cleared on the no-channels path so it cannot latch.

## The three questions this review exists to answer

### 1. Side-effecting node types beyond `seq`

The session avoided a design where the walk evaluates each owner, because that would **double-advance
`InputSeq`** — `NextValue()` mutates an index on every evaluation, and a `seq` under a `channel` is an
ordinary config. Excellent catch. The open question is **how it was found**: swept, or hit?

**Sweep all 27 `input_*.go` types for evaluation-time mutation.** Any node whose `Eval`/`_Eval`
mutates state that a second evaluation would advance, corrupt, or double-count. Then check whether the
current design's invariant — *the walk must never evaluate* — is (a) actually true everywhere and
(b) **written down**. An unwritten load-bearing invariant is the next defect's habitat.

### 2. Shared owners

`resolvedThisPass` is new mutable per-`InputChannel` state, armed by the walk and cleared by
evaluation. **Can one `InputChannel` be an owner of two different top-level entries** — via a `read`
in entry 2 resolving through `IOMap` to a channel already used in entry 1? Can it be shared across two
`OutputTransmitter`s?

Arm-then-evaluate is consistent *within* one loop iteration. Across entries, across transmitters, and
across the eval loop's three trigger branches (`ConfigEventChan`, `StreamEventChan`,
`DeviceEventChan`), is it? Look specifically for an ordering where a channel is armed by one entry's
walk and cleared by another entry's evaluation, or left armed and neutralized while live.

### 3. The `Unresolved` flag

One latch case was found and fixed (no-channels path). **Are there others?** Enumerate every path
through `Eval` that returns without storing to the flag, and every path that stores `false`. A flag
that can latch true suppresses frames forever; a flag that can latch false disarms the protection.
Both are failure modes. Also: it is an `atomic.Bool` read by `SendLoop` on another goroutine —
confirm the read/write pairing is actually race-free and that `-race` exercises it.

## Also worth a look, briefly

- The test suite's stated limit: the surviving channel in partial-failure tests is a constant-fed
  `number`, not a second gamepad, because `Attached()` needs a live `*sdl.Joystick`.
  `TestLiveChannelsSurviveWhileAnotherDies` is claimed to cover what a second device would prove — does
  it?
- The closure wording in `CURRENT_STATUS.md`. It claims D-partial is closed **generally**, on the
  grounds that the neutral no longer depends on the holder's result. That reasoning looks sound, and
  it is the first structural claim in this chain rather than an enumeration — **but the previous four
  closures were also believed at the time.** Test the claim, not the confidence.

## What would make you say NO-GO

A side-effecting type the design's invariant does not actually protect · a shared-owner ordering that
arms or clears wrongly · an `Unresolved` latch path · a race the tests do not exercise · a closure
claim that is again true only for the shapes covered.

## Output

**GO / NO-GO / GO-WITH-FIXES**, most-severe first, **CONFIRMED** separated from **PLAUSIBLE**. A clean
review is a real outcome — do not manufacture a finding to look thorough, and do not soften one.

**Safety:** reading and running tests only; nothing built, powered, flashed, or pushed. In
`w17-mapper` work from **`w17-headtrack`**. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
