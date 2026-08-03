# Session prompt — `InputRead._Eval` unguarded recursion (upstream defect, process-fatal)

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Branch from
**`w17-headtrack`** — `main` in `w17-mapper` tracks upstream `2b8031a`.

> **Opus 5 at `high`.** Small surface and an obvious-looking fix — but it kills the process, and the
> obvious fix on a resolver is where a subtle one hides. Care over speed; this does not need Fable.

---

Close the tracked upstream defect found during the `e452d55` code review.

## The defect

`InputRead._Eval` (`pkg/config/input_read.go:44`) resolves its target by id through `Config.IOMap` and
recurses **unguarded**. A `read` node pointed at itself, or at a cycle through a second `read`, does
not error, degrade, or return nan — it **fatally overflows the stack and the process is gone**:

```
fatal error: stack overflow
github.com/kaack/.../config.(*InputRead)._Eval  input_read.go:36
```

**Verify this yourself before fixing it.** Reproduce both shapes — self-reference and a two-node
mutual cycle — and confirm the crash is unrecoverable (a `recover()` does not catch a Go stack
overflow; if you believe otherwise, prove it).

## Two things to get right

**1. This is pre-existing upstream, present at `2b8031a`.** Confirm that — it changes the GPL §5(a)
framing. A fix here is a **fork modification to upstream behaviour**, not a repair of W17 code, and
`FORK-NOTICE.md`'s §5(a) table must say so in those terms. Keep the table in date order; it was out of
order once already.

**2. `channelOwnerMaxDepth` does NOT guard this.** The depth bound in `output_tx.go` is often assumed
to be the read-cycle backstop — it is not, and its comment was corrected to say so. `ic.Eval(c)`
overflows *before* the walk is ever reached. `TestChannelOwnersWalkTerminatesOnAReadCycle` passes only
because it calls `channelOwners` directly and never `Eval`. **Do not treat the existing walk bound as
partial coverage.**

## Design — bring me the trade-off, do not pick

The shape of the fix is a decision, not a detail:

- **Depth bound in `_Eval`**, mirroring the walk's. Simple; picks an arbitrary limit; a legitimately
  deep chain hits it.
- **Cycle detection** via a visited set threaded through evaluation. Exact; changes the `Eval`
  signature or needs per-pass state — and per-pass state on `InputChannel` is precisely what the last
  fix introduced, so consider whether these should share a mechanism rather than grow a second one.
- **Reject at config load.** A cycle is a malformed graph; catching it in `UnmarshalJSON` or a
  validation pass means it never reaches evaluation at all. Arguably the correct layer — a config that
  cannot be evaluated should not be adopted. Check how this interacts with `630ea96` (no config ⇒ no
  frames ⇒ the receiver's link-loss failsafe fires), which may already give you the safe outcome for
  free.

**Whichever we choose, the failure must be safe, not just non-fatal.** A `read` cycle that returns a
value is worse than one that crashes. Nan, or refusal to adopt the config, are the two safe answers.

## Evidence obligation

Reproduce first, fix second, and prove the test bites: injections restored and the tree verified
byte-identical after each; `go build`; full suite; `-race` on touched packages; `PackChannels`
byte-identity; `gofmt`; pre-push exit 0; proto still ending at `ACTIVE_LOG_ONLY = 8`. `go vet` has
exactly one pre-existing finding at `main.go:130` — leave it.

**Rename or re-scope any test whose name overstates what it covers.** That is how this defect stayed
invisible: a passing test called `TestReadCycleTerminates` that never called `Eval`.

## Record

`CURRENT_STATUS.md` (the tracked item closes or narrows), the `w17-mapper` checkpoint row, and the
GPL §5(a) table. **State the closure narrowly.** **Re-bundle** if code lands — newest is
`w17-mapper-allrefs-2026-08-04.bundle` at `9ba6e06`.

**Safety:** no hardware, nothing flashed or powered. No head-intent, arbitration or FIRST_ACTIVE path.
The fork's `origin` is **PUBLIC** and already 9 ahead — verify what you would push distributes no
control path; do not push. Show diffs before committing. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
