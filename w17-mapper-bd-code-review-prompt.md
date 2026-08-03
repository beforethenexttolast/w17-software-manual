# Session prompt — code review of the B+D fix (`w17-mapper` `e452d55`) before it merges

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.**

> Consider **Claude Fable 5**, or Opus 5 at high/max effort. This is the **first code change on the
> stick→CRSF control path** in this chain, and it is the one artifact nobody has independently
> checked. Every prior layer — the closure, the pre-merge review, the narrowing, the owner's own (c)
> ruling — contained an error that the next layer found.

---

Review `w17-mapper` `e452d55` ("resolve neutrals from the owning channel node, suppress frames across
a config swap") plus its docs commit `f81ec63`. **Do not merge, do not push, do not fix.** Report, and
propose diffs for anything small rather than applying them.

```bash
git -C w17-mapper log --oneline 5a28106..f81ec63
git -C w17-mapper diff 5a28106..f81ec63
git -C w17-mapper show e452d55 --stat
```

## Scope: review the implementation, not the defect

RESIDUALS B and D are thoroughly established — mechanisms reproduced by execution across three
sessions, node types enumerated twice independently with matching results. **Do not re-derive them.**
Read `CURRENT_STATUS.md` → *VR-FPV batch status* for the settled picture and spend your effort on
whether the **code** is right.

The one exception: if something in the fix implies the defect was misunderstood, say so.

## Calibration — the failure mode in this chain has a shape

Four errors so far, each an **unexamined generalization** that the next layer caught:

1. The closure claimed a universal over ~30 node types after checking two.
2. The pre-merge review narrowed it to six; the real count is fourteen (`and`/`or` missed, the
   comparisons misfiled).
3. The owner's `(c)` ruling specified "suppress until one full `Eval`" and separately "do not bound
   the window" — thinking only of the *upper* bound. One `Eval` is sub-millisecond, so the receiver's
   500 ms failsafe would never have fired and B would not have been fixed. The implementing session
   caught it and added a **1 s minimum**.
4. The 27-type enumeration was complete *as a classification*, but nobody asked whether the walk could
   **reach** every case — `read.Children()` returns nil while its `Eval` still reports a channel
   number. Found only during implementation.

**Assume a fifth exists and that it is of this shape.** Look for the property asserted over a set
where only some members were checked.

## What to check, hardest first

### 1. The subtree walk — termination and reach

- **Does it terminate on every shape?** `read` can point at itself; the walk follows `read` through
  `IOMap` with a depth bound. Verify the bound exists, is hit rather than overflowing, and that a
  cycle through *two* `read` nodes (not just self-reference) is also caught.
- **Does it reach all fifteen cases** — the fourteen D-1 asymmetric types plus `read`? Enumerate
  against the walk yourself rather than trusting the count.
- **Multi-channel subtrees.** The walk-all rule exists because keying off the reported number strands
  the second channel (`EvalOperation` reports the last right operand when healthy, the left one on
  nan). Confirm the pinning test actually builds that shape and would fail without the rule.
- **D-2 coverage.** For `add`/`subtract`/`min`/`max` the slot *is* written — with the wrong value.
  Confirm the walk corrects it rather than only handling the unwritten case.
- **The `switch` case strands with no nan at all**, so the fix keys off "unusable result" rather than
  nan. Verify that predicate is right everywhere it's used, and that it cannot mis-fire on a
  legitimately unusable-but-not-broken result.

### 2. `configSwapFailsafeWindow` — the 1 s minimum

- **Is it genuinely a minimum and never a timeout?** The comment at `send.go:91-106` claims it only
  ever lengthens the no-frame window. Verify `configSwapGate.holdOff` cannot *end* a suppression that
  another condition (`630ea96`'s no-config path) is holding open.
- **Two suppression mechanisms now coexist.** Check they compose — a swap during an existing
  no-config suppression, and a no-config state arising during a swap window.
- **Repeated swaps.** Hand-entering the config means pressing Apply many times. Do windows reset,
  stack, or leak a goroutine/timer per Apply?
- **The sizing is 2× the firmware's `linkTimeoutMs = 500`** (`FailsafeStateMachine.hpp:12` —
  verified). The TX-module/RX hold on top is **unmeasured**; confirm the code says so rather than
  implying the value is validated.

### 3. The passing fix

`EvalLoop` published the synthetic arrays *before* evaluating them, so after every Apply all 16
channels read 992. Real bug, fixed in passing — **and passing fixes get less scrutiny than they
deserve.** Check the reordering changes nothing else that depended on publish timing.

### 4. Regression surface

- `crsf.PackChannels` byte-identity — claimed to hold; **re-run it**, don't read it.
- Does the walk add per-tick cost in the send path? Bound it.
- **Nothing may have leaked into the head-intent path.** Proto must still end at
  `ACTIVE_LOG_ONLY = 8`; no `FIRST_ACTIVE` / `w17_first_active` in tracked Go or proto; pre-push hook
  exit 0. The fork's `origin` is **public** and this is 7 commits ahead of it.
- Confirm no hold-last semantics were reintroduced anywhere.

### 5. Test quality — the specific trap this chain already fell into

The previous closure's tests were **genuinely non-vacuous and its verdict was still wrong**, because
every test built the same config shape. So:

- Do the 22 new tests build **top-level wrapper** shapes, or only `channel` nodes?
- Re-run at least two of the four claimed injections and confirm they fail for the **intended reason**.
- Verify the tree was actually restored after each injection (`git status`, and diff against
  `f81ec63`).

### 6. The record

- Does the GPL §5(a) table entry in `FORK-NOTICE.md` describe what the commit actually does?
- Does the `CURRENT_STATUS.md` closure (workspace `c9e5692`) overstate anything? Both B and D are
  claimed CLOSED — is that true in general, or true for the shapes tested? **That exact
  over-generalization is what produced D in the first place.**

## What would make you say NO-GO

- A shape where the walk fails to terminate or fails to reach a channel
- The window ending a suppression it shouldn't, or leaking per-Apply state
- An injection that passes vacuously, or a tree not restored
- `PackChannels` byte-identity not actually holding
- A CLOSED claim that is again true only for the shapes covered

## Output

**GO / NO-GO / GO-WITH-FIXES**, fixes listed concretely. Separate **CONFIRMED** from **PLAUSIBLE**.
A clean review is a real outcome — do not manufacture a finding to look thorough, and do not soften
one to be encouraging.

**Safety:** reading and running tests only. Nothing built, powered, flashed, or connected; no pushing.
In `w17-mapper`, work from **`w17-headtrack`** — `main` there tracks upstream `2b8031a`. This review
cannot open a gate: A2 stays NOT-EXECUTED and Phase B stays BLOCKED whatever it concludes.
