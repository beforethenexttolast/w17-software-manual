# Session prompt — RESIDUAL C: the eval tick is subscriber-dependent

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Branch from
**`w17-headtrack`** — `main` in `w17-mapper` tracks upstream `2b8031a`.

> **Run on Claude Fable 5 at `high`–`xhigh` effort.** Small surface, nasty argument: a non-blocking
> send on an unbuffered channel, competing consumers, and a heartbeat whose existence depends on
> whether a UI happens to be watching. Concurrency reasoning about a failsafe path.

---

Close **RESIDUAL C** — the last of the four residuals from the hold-last closure, and the only one
still undecided. **No approach has been chosen. Bring me options; do not pick.** Read
`CURRENT_STATUS.md` → *VR-FPV batch status* for the settled picture, including the correction that
already narrowed C once.

## The mechanism, as recorded

Neutralization needs at least one `Eval` tick after a device is removed. `AlertDeviceChan`'s send is
**non-blocking on an unbuffered channel** (`devices/controller.go:103`) with **two competing
consumers** — `eval.go:104` and the gamepad stream at `server_grpc.go:201`. If the `JOYDEVICEREMOVED`
alert is dropped, or taken by a stream handler instead of the eval loop, no further SDL event follows
(the device is gone) and `Eval` never re-runs on the stale array.

**What was already corrected once.** An earlier version of this entry claimed `AlertStreamChan` is
"defined but never called, so `StreamEventChan` never fires." Both halves were false — it is called at
`server_grpc.go:256` from the 25 ms ticker at `:246`, and `StreamEventChan` is consumed at
`eval.go:95`, whose branch re-evaluates every top-level holder in `config.IOMap`, transmitters
included. **Re-derive that yourself** rather than trusting either version.

**The sharpened claim, which is what you are actually solving:** there are three 25 ms tickers
(`:195` and `:222` poking `AlertDeviceChan`, `:246` poking `AlertStreamChan`) and **all three live
inside streaming RPCs**. So with **no gRPC subscriber there is no periodic eval tick at all**, and
neutralization rests entirely on one droppable alert landing. The re-evaluation heartbeat is coupled
to something watching — precisely the condition that does *not* hold while driving.

## First: measure, don't assume

- **Is C still reachable after `e452d55` and `c60843e`?** Those changed how neutrals are resolved, not
  what triggers a tick — but check rather than assume. If the config-swap gate or the `Unresolved`
  suppression path incidentally covers some of C, say so.
- **Confirm the two consumers and the unbuffered channel** at HEAD.
- **Can the alert actually be lost in practice**, or does the tight `StartPolling` spin
  (`devices/controller.go:117`) make it vanishingly unlikely? The loop fires on *every* SDL event —
  the question is whether a removal can be the last event. Say CONFIRMED or PLAUSIBLE, and don't
  inflate it: C has never been observed, only read.

## Options to develop — with the failure mode each leaves behind

At minimum these; propose better if you find it:

- **(a) Buffer `DeviceEventChan` to 1.** Smallest change. A dropped alert becomes a queued one. Does
  it fully close the race, or just narrow it? What happens when both consumers are alive?
- **(b) A subscriber-independent eval tick.** Removes the coupling entirely — the heartbeat stops
  depending on a UI. Costs a permanent background tick; consider rate, and whether it re-introduces
  cost on a path that currently has none.
- **(c) Make removal push state rather than signal it.** Have device removal write the neutral
  directly instead of relying on a later `Eval` to notice. Most direct; most invasive.
- **(d) Do nothing; record C as accepted.** Legitimate if the reachability measurement comes back
  weak enough — but then say so explicitly rather than leaving it open forever.

**Consider the interaction with `configSwapFailsafeWindow`.** That gate suppresses frames so the
receiver's own link-loss failsafe fires. If a subscriber-independent tick exists, does the same
"suppress rather than guess" answer apply to C — i.e. is the right fix *not* to guarantee a tick but
to suppress when one cannot be guaranteed? That reuses a shape already accepted twice here
(`630ea96`, the swap gate) and may be simpler than any of the above.

## Evidence obligation, and the trap

If code lands: injections that bite, tree restored and verified byte-identical after each,
`go build`, full suite, `-race` on the touched packages, `PackChannels` byte-identity, `gofmt`,
pre-push exit 0, proto still ending at `ACTIVE_LOG_ONLY = 8`. `go vet` has exactly one pre-existing
finding at `main.go:130` — leave it.

**The trap.** Five consecutive passes on this codebase produced five defects of one shape: *a property
asserted over a set where only some members were checked*. For a concurrency fix the set is **states
and interleavings**, not node types. A test that exercises the happy interleaving proves nothing; the
one that matters is the alert arriving while the other consumer is mid-handler. Build that.

## Record

Update `CURRENT_STATUS.md`'s RESIDUAL C entry and the `w17-mapper` checkpoint row. **State the closure
narrowly** — "closed for X" beats "closed", and the over-broad closure claim is this chain's cardinal
error. **Re-bundle** the backup if code lands; newest is `w17-mapper-allrefs-2026-08-04.bundle` at
`9ba6e06`.

**Safety:** no hardware, nothing flashed or powered. No head-intent, arbitration or FIRST_ACTIVE path.
The fork's `origin` is **PUBLIC** and already 9 ahead — verify what you would push distributes no
control path; do not push. Show diffs before committing. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
