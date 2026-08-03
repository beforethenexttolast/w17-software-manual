# Session prompt — D-partial redesign + D-3 depth bound (`w17-mapper`, control path)

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Arm-safety class.
Branch from **`w17-headtrack`** — `main` in that repo tracks upstream `2b8031a`.

---

Close the two open findings from the `e452d55` code review. **Both approaches are DECIDED** (owner,
2026-08-03) — implement them, do not re-litigate. Read `CURRENT_STATUS.md` → *VR-FPV batch status*
for the settled picture, including the retraction of the false "D closed for ALL node types" claim.

## Fix 1 — D-partial: redesign the walk to carry evaluation state

**The defect.** `EvalOperation` (`util.go:295-303`), `InputAnd`/`InputOr._Eval`
(`input_and.go:63-77`) and `EvalRelational` (`util.go:247-252`) all **ignore a nan operand** and
return `nan=false` with a valid channel number. The holder reports healthy, `output_tx.go:165` takes
the healthy branch, and `channelOwners` is never called. Reproduced: `add{ch1←number, ch2←axis on a
DETACHED gamepad}` at top level transmits **ch2 = 1984** indefinitely on a healthy link, configured
172 rail never applied. The `and` variant leaves a detached arm channel at **992**.

**✅ DECIDED: redesign `channelOwners` to return per-owner evaluation state.** Do **not** ship the
reviewer's interim patch, which reads `InputChannel.IsNaN` — a field set as a side effect of
evaluation, and therefore only trustworthy for owners actually evaluated this tick. `and`/`or`/
`switch`/`case` early-exit, so an unvisited owner carries a **stale** `IsNaN`. Every spurious write
that could cause is toward failsafe, so the direction is safe — but acting on stale state is how this
chain produced five defects, and a spurious neutral on a live channel is nondeterminism on the
control path. The redesign is affordable: nothing is soldered and no hardware depends on this.

The shape to aim for: the walk should report, per owner, *whether it resolved on this tick* — derived
from the traversal, not read back from a mutable field. Design it; the above is the constraint, not
the implementation.

## Fix 2 — D-3: fail-safe the truncation, and raise the bound

**The defect.** `channelOwnerMaxDepth = 32` (`output_tx.go:63`) truncates a deep tree to **zero
owners**, so `ch` is `-1`, the `ch >= 1` guard writes nothing, and the slot **keeps its last value** —
hold-last, silently. Reproduced with a 40-deep `linear` chain: `ch1 = 1984` after five detached ticks.

**✅ DECIDED: do both halves.**

1. **Raise the bound to 256** so it effectively never fires for any tree the editor can build.
2. **Make truncation itself fail-safe.** Zero owners from a truncated walk means *unknown state*, and
   the correct response to unknown state on this path is already established twice in this fork —
   `630ea96` and the config-swap gate both **suppress** rather than transmit a guess. Do the same.
   Distinguish it from "legitimately no owners," which must stay a no-op.

**Correct the comment.** It currently claims the bound is a `read`-cycle backstop. It is not:
`InputRead._Eval` (`input_read.go:44`) recurses unguarded and **fatally overflows the stack before
the walk is ever reached**. Say what the bound actually does and that truncation is now fail-safe.

**Rename and re-scope `TestReadCycleTerminates`** — it passes only because it calls `channelOwners`
directly and never `Eval`, so it does not test what its name says.

## Out of scope — record, do not fix

`InputRead._Eval`'s unguarded recursion is a **pre-existing upstream defect** (present at `2b8031a`).
A `read` cycle kills the process with an unrecoverable stack overflow. Do not fix it in this commit;
record it as its own tracked item so it is not lost.

## Evidence obligation — and the specific trap

Match the bar of `e452d55` and the review: injections that bite, tree restored and verified
byte-identical after each, `go build`, full suite, `-race` on `pkg/config` + `pkg/link`,
`PackChannels` byte-identity, `gofmt`, pre-push exit 0, proto still ending at `ACTIVE_LOG_ONLY = 8`.
`go vet` has exactly one pre-existing finding at `main.go:130` — leave it.

**The trap, stated plainly, because it has now caught five consecutive passes.** `e452d55`'s 22 tests
were rigorous and its verdict was still wrong, because **every one detached the whole device** — so
the left operand went nan first and the top-level result was genuinely unusable. **Your tests must
build a subtree where one channel survives and another dies**: a constant-fed channel or a second
gamepad alongside a detached one. Single-device configs are safe by construction (`allNan` ⇒
`nan=true`) and prove nothing about this.

Also cover: the seven opaque types (`invert`, `seq`, `number`, `axis`, `button`, `hat`, `gamepad`)
return `ch = -1` on **both** paths, so a healthy top-level `invert` is now pinned to its failsafe rail
every tick. That is the safe direction and an improvement on the 992 it sat at before — but **no test
covers it**, and the test file's justification for excluding these seven ("neither can strand a slot")
is a statement about the *old* defect. Pin the current behaviour.

## Record

Update `CURRENT_STATUS.md` (D-partial, D-3), the `w17-mapper` checkpoint row, and the GPL §5(a) table
in `FORK-NOTICE.md` — **and fix that table's date ordering while you are there**: the `e452d55`
(2026-08-03) row was inserted above `630ea96` (2026-07-30). **Re-bundle** the backup afterwards; the
newest is `w17-mapper-allrefs-2026-08-03b.bundle` at `f81ec63`.

**State the closure precisely.** "Closed for shapes X" beats "closed," and an over-broad closure claim
is what this whole chain has been correcting. If a shape remains open, name it.

**Safety:** no hardware, nothing flashed or powered. No head-intent, arbitration or FIRST_ACTIVE path.
The fork's `origin` is **PUBLIC** and already 7 ahead — verify what you would push distributes no
control path; do not push. Show diffs before committing. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
