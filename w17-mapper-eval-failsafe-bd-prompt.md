# Session prompt — RESIDUALS B **and D**: `output_tx.Eval` failsafe resolution and re-seed

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Arm-safety class,
and **D-1 re-opens throttle freeze** — the original defect, on a path the `2dc7c5a` fix does not reach.

> **Scope widened 2026-08-03.** This prompt was written for RESIDUAL B alone. The pre-merge review then
> found **RESIDUAL D**, and the structural fix for D subsumes B — both are `output_tx.Eval`
> resolution/re-seed bugs. Fixing them separately would touch that function twice with two sets of
> injections and two rounds of `PackChannels` byte-identity proof. **Do them together.**

---

Fix (or record a deliberate decision not to fix) **RESIDUALS B and D** — see *VR-FPV batch status* in
`CURRENT_STATUS.md`. Both were found after the 2026-07-30 entry and are not covered by any prior one.

## D first — it is the bigger one, and it re-opens the original defect

Two mechanisms, both **executed** against HEAD `5a28106` by the review:

- **D-1, stranding.** A **top-level wrapper node** in a transmitter's `channels` array — `linear`,
  `map`, `case`, `if`, `trim`, `switch` — propagates its child's `ch` on the healthy path and returns
  `-1` on nan (`input_linear.go:67` vs `:48`). The healthy tick writes the slot; the nan tick hits
  `ch < 1` and `continue`s, so **the slot keeps its last value**. Observed: `ch1` held **1984** across
  five detached ticks. That is full-deflection throttle frozen across a dropout.
- **D-2, configured failsafe discarded.** The `EvalOperation` family (`add`/`subtract`/`min`/`max`/
  comparisons) propagates `ch` on both paths and *does* write the slot — but `failsafeFor(ic)`
  (`output_tx.go:49-54`) asserts `FailsafeValuer` on the **top-level holder**, which a wrapper is not,
  and falls back to center. Observed: a configured `failsafe: 172` on an inner arm channel emitted
  **992** → inside the ±250 dead band → **arm latched ON**.
- Schema-valid: `schema.yaml:314` is `$ref: '#/definitions/input'`, the full union; `expected: channel`
  at `:311` is `$meta`, enforced nowhere in Go.

**Proposed structural fix** (the review's, not yet implemented — evaluate it, don't just execute it):
resolve the failsafe from the node that **owns** the channel number rather than the top-level holder,
and treat a valid-`ch`-when-healthy → `-1`-when-nan transition as a **nan for that channel**. Check it
actually covers both D-1 and D-2, and say so if it doesn't.

**Reachability, stated honestly.** PLAUSIBLE-but-unlikely in the config planned today — the UI steers
toward `channel` nodes at top level and the test harness only builds that shape. **But not
hypothetical:** `w17-mapper-config-entry-record.md` plans a `switch`/`case` construct for ch13 drive
mode, one of the six asymmetric types. Do not inflate this, and do not dismiss it.

## Then B — the mechanism as recorded

## The mechanism, as recorded

- `SetConfig` (`pkg/server/server_grpc.go:102`) unmarshals a **wholly new** `Config`.
- `pkg/config/config.go:41-42` seeds every fresh transmitter with `Values: centeredValues()` — all 16
  slots at **992**. (`output_tx.go:71`'s re-seed is nil-guarded and is *not* the path here.)
- `pkg/config/eval.go:85-92` rebuilds `EvalDataMap` from the new transmitters.
- A channel the **new** config no longer maps therefore goes `1811 → 992` on the wire. Since
  `firstDecodeDone_` is already true, 992 normalizes to 0, lands inside the firmware's **±250 dead
  band**, and `decodeSwitch` **holds the previous state — ON**.
- `630ea96` covers the *cleared*-config case by suppressing frames entirely. The *replaced*-config case
  is not covered.

**Re-derive all of the above from source — B and D alike.** Do not take any of it on trust: every
paragraph here is a transcription of a session report, and **the last time a claim in this chain was
accepted from its argument rather than from the files, it was wrong** — that is exactly how the
"non-channel node types return `ch = -1`" universal got through, and how D came to be missed. This
workspace's standing rule (RETRACTION entry, 2026-07-27) is *open the file*. If any hop fails, say so
and stop.

**Enumerate every node type yourself.** The specific error being corrected here was generalizing over
~30 types after checking two. There are ~30 `input_*.go` files in `pkg/config/`; the six named above
are the ones the review found. **Confirm that list is complete** rather than inheriting it — an
asymmetric type nobody has named yet is the same bug again.

## Then establish reachability honestly

Recorded as "narrow (bench-only today, requires a config swap mid-session) but real." Test that
framing: what actually calls `SetConfig` while a transmitter is streaming? Is a swap reachable from
the webapp UI mid-session, from a gRPC client, on reconnect, or only by explicit user action? The
answer decides whether this is urgent or merely correct. **Report reachability before proposing a
fix**, and don't inflate it — an overstated severity here costs the same credibility as an understated
one.

## Design options — bring me the trade-offs, do not pick

This is a change on the stick→CRSF control path. Present these (and any better one you find) with the
failure mode each leaves behind:

- **(a) Carry forward.** Preserve the previous `Values` for channels the new config still maps; emit
  each dropped channel's configured failsafe. Most faithful, most state to get wrong.
- **(b) Seed from configured failsafe** instead of uniform 992 on a fresh array. Small and local —
  **but note it composes with RESIDUAL A**: if `ChannelT.Failsafe` still defaults to 992 and no config
  sets 172, (b) changes nothing for exactly the switch channels that matter. Say so if you propose it.
- **(c) Suppress frames across the swap** the way `630ea96` suppresses them for no-config, until the
  new config has produced one full `Eval`. Reuses a shape already accepted here; costs a brief
  no-frame window that the receiver's own link-loss failsafe would cover.
- **(d) Firmware side.** Probably not viable — the firmware cannot see a config discontinuity, so it
  cannot distinguish "992 because swap" from "992 because centred". Record it as considered and
  rejected rather than silently omitted.

Whichever we choose: **the mapper is the arbitration authority for this path**, so the fix belongs in
the fork unless there is a strong reason otherwise.

**Check the interaction before proposing anything.** B's fix and D's fix both land in
`output_tx.Eval`. Option (b) for B and the ownership-based failsafe resolution for D are arguably the
same change seen from two sides — if so, say so and propose one change, not two. If they conflict,
that is the most important thing this session can tell me.

## Evidence obligation

Match the bar set by `2dc7c5a` and the closure session — and note it was **not enough last time**: that
session's tests were genuinely non-vacuous and its verdict was still over-generalized, because the
tests only ever built one config shape. **Your injections must cover a top-level wrapper node, not
just `channel` nodes at top level.** A green suite over the covered shape is what produced D.

- An **injected regression** that reproduces the held-ON switch across a swap *before* the fix, and
  fails without it after — restore the tree after each injection.
- `go build ./...`; `go test ./... -count=1` and `-race` on the touched packages.
- **`crsf.PackChannels` byte-identity** must still hold.
- `go vet` has exactly **one** finding, `main.go:130`, present at upstream `2b8031a` — **not** a
  regression. Do not "fix" it.
- `.githooks/pre-push` exit 0.

## Record

Update the RESIDUAL B paragraph in `CURRENT_STATUS.md` to CLOSED-with-evidence or
OPEN-with-a-decision, and the `w17-mapper` checkpoint row. If code lands, note that the durable backup
bundle (`~/Documents/w17-backups/w17-mapper-allrefs-2026-07-25b.bundle`) caps at `0e11d6b` and now
predates three failsafe fixes — **re-bundle**.

**Safety:** no hardware, nothing flashed or powered. No head-intent, no arbitration, no FIRST_ACTIVE —
the proto must still end at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8`. The fork's `origin` is **public**;
verify what you push distributes no control path. In `w17-mapper`, `main` tracks upstream `2b8031a` —
the fork work lives on **`w17-headtrack`**, so branch from there, not from `main`. Show diffs before
committing. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
