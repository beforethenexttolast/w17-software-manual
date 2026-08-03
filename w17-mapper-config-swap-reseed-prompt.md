# Session prompt — RESIDUAL B: a mid-session config swap re-seeds 992 over an ON switch

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Arm-safety class:
the worst case is a config swap leaving the car **armed**.

---

Fix (or record a deliberate decision not to fix) **RESIDUAL B** from the 2026-08-03 hold-last closure
— see *VR-FPV batch status* in `CURRENT_STATUS.md`. It is **new, found during that closure, and not
covered by any prior entry**. It is the DEFECT 2 failure class, reached by a different route.

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

**Start by re-deriving all of that from source.** Do not take the paragraph above on trust — it is a
transcription of a session report, and this workspace's standing rule (see the RETRACTION entry,
2026-07-27) is *open the file*. If any hop is wrong, say so and stop.

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

## Evidence obligation

Match the bar set by `2dc7c5a` and the closure session:

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
