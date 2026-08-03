# Session prompt — pre-merge review of `docs/mapper-holdlast-closure` and `docs/session-prompts`

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.**

> Consider running this on **Claude Fable 5**, or Opus 5 at high/max effort. One branch asserts that a
> **failsafe-class defect is CLOSED**, and the other contains the document that will govern soldering.
> A false PASS on either is the expensive kind.

---

Two branches are waiting to merge into `main`. **Do not merge them.** Review them and give me a
GO / NO-GO **per branch** — it is a valid outcome to merge one and hold the other.

```bash
git log --oneline main..docs/mapper-holdlast-closure    # fe4cd69, 926d442
git log --oneline main..docs/session-prompts            # fdcf8e9, 3ffb18f
git diff main..docs/mapper-holdlast-closure
git diff main..docs/session-prompts
```

Both branches are off `main`; they touch disjoint files and should merge in either order. **Verify
that rather than trusting it.** Note `main` is already **ahead 3 of `origin/main`** — pre-existing,
not from this work, but say so if it looks wrong.

## Your job is to falsify, not to confirm

Every claim below was produced by a Claude session. **Two of them have already been caught wrong**,
which is the calibration you should carry into this:

- The 2026-07-30 entry said the throttle-freeze defect was "not yet investigated or fixed." It had
  been fixed the same day. (Over-reporting open work — this workspace's usual drift direction.)
- The closure session then wrote that `AlertStreamChan` is "defined but never called." It is called.
  **My correction of that error is itself on this branch** (`926d442`) and is exactly as unverified as
  the thing it corrects. **Re-derive it; do not accept it because it sounds like a careful correction.**

Read the **RETRACTION** entry in `CURRENT_STATUS.md` (2026-07-27) before you start. Its recorded lesson
— *open the file* — is the whole method here. A claim that confirms what you already suspect is the
one that gets through.

## Branch 1 — `docs/mapper-holdlast-closure` (the safety-critical one)

It asserts: **the gamepad-dropout throttle-freeze defect is CLOSED**, with residuals A, B and C open.

Re-derive independently, from `w17-mapper` source at HEAD (`5a28106`), not from the entry's prose:

1. **Is the array genuinely written every tick for every mapped channel?** The entry's argument rests
   on `InputChannel` returning its channel number on *both* the nan and healthy paths, while
   non-channel node types return `ch = -1` and so never write a slot. Check that holds for **every**
   node type in the fork, not the ones the entry names.
2. **Does `Attached()` gate every config-side resolution path** — axis, button, hat? The entry says the
   two ungated registry readers are diagnostics-only with no path to `Values`. Confirm no path.
3. **Residual B.** Is the mid-session config-swap re-seed real, and is `output_tx.go:71` genuinely
   nil-guarded and *not* the path? Does a dropped switch channel actually land in the firmware's ±250
   dead band and hold ON? This one is **new**, checked by only two sessions, and lands on **arm**.
4. **Residual C, as corrected.** Verify all of: `AlertStreamChan` is called at `server_grpc.go:256`
   from the 25 ms ticker at `:246`; `StreamEventChan` is consumed at `eval.go:95`; that branch
   re-evaluates every top-level holder in `config.IOMap` including transmitters; and all three tick
   sources sit inside streaming RPCs. **If any of those is wrong, the record now carries a wrong
   correction on top of a wrong claim — say so loudly.**
5. **The injection evidence.** Three injections were claimed, tree restored after each. Re-run at least
   one and confirm it fails the intended assertion for the intended reason. Vacuous tests have bitten
   this workspace before (GS `085e1d1`: `.barsrc hidden` with no `.hidden` rule — the class-only jsdom
   assertions passed against a visually inert class).
6. **Confirm `w17-mapper` is genuinely untouched** — tree clean at `5a28106`, nothing committed, no
   `FIRST_ACTIVE` or `w17_first_active` anywhere in tracked Go or proto, proto still ends at
   `ACTIVE_LOG_ONLY = 8`. The fork's `origin` is **public**.
7. **Sample the line-number citations.** Both commits cite specific lines heavily. Line numbers drift.
   Pick a handful across both and confirm they resolve to what is claimed.

**The question to answer:** is CLOSED correct, or is it CLOSED-shaped? If any part of the throttle path
can still freeze, that outranks everything else in this review.

## Branch 2 — `docs/session-prompts`

Lower stakes per file, with one exception.

- **`w17-a2-execution-session-prompt.md` is the exception — it will govern physical work.** Check its
  S1–S8 table against the canonical
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`, gate by gate. Gate order, what
  is isolated when, the WS2812 option-A / 1N5819 decision, link2 RX GPIO26 = verify-no-wire, S8 as the
  hard gate, and the two-part §12 closure. **A wrong gate here produces a wrong solder joint.** Also
  confirm the claim in its banner is true: that the *old* single-pass version would false-FAIL a
  correctly-built car.
- **The other seven prompts:** are the facts they assert still true, and are the file paths and
  invariants they cite real? A prompt that sends a future session after a defect that no longer exists
  wastes a session; one that omits a safety line is worse. Confirm every prompt carries the standing
  envelope (no powering, no flashing, A2 NOT-EXECUTED, Phase B BLOCKED) and that the `w17-mapper` ones
  say to branch from **`w17-headtrack`**, not `main`.
- **`w17-mapper-config-entry-record.md`** claims a **DEFECT 2 owner decision** (`inactive_value` =
  −32768, dated 2026-08-03). Flag it for me to confirm — I am the only source for whether that
  decision was actually taken, and this file records the workspace's standing lesson that *an owner's
  word for a part is arrival evidence for a part, never for the part the BOM expected.* The same
  applies to decisions. Also check its five-check argument that the channel map is unverified: is each
  check load-bearing, or is it four restatements of "nothing is soldered"?

## What would make you say NO-GO

Say it plainly — do not soften a verdict to be encouraging:

- Any hop in the CLOSED argument that does not survive re-derivation
- An injection that passes vacuously
- A residual understated in severity, or one that is actually already fixed and being over-reported
- An A2 gate that contradicts the canonical checklist
- A citation that does not resolve, where the surrounding claim depends on it

## Output

Per branch: **GO / NO-GO / GO-WITH-FIXES**, with the fixes listed concretely. Separate **CONFIRMED**
from **PLAUSIBLE** throughout — the standing rule here. If you find nothing wrong, say so directly;
a clean review is a real outcome and manufacturing a finding to look thorough is its own failure.

**Do not merge, do not push, do not fix anything you find** — report, and I will decide. If a fix is
obvious and tiny, propose the diff rather than applying it.

**Safety:** documents and source reading only. Nothing built, powered, flashed, or connected. This
review cannot open a gate: A2 stays NOT-EXECUTED and Phase B stays BLOCKED whatever it concludes.
