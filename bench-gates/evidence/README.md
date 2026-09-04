# bench-gates/evidence/

**Empty by design.** Nothing has been executed: A2 is NOT-EXECUTED, Phase B is BLOCKED, BT1 is
unopened, and no board in this project has ever been flashed or powered.

## Layout

```
bench-gates/evidence/<GATE-ID>/<UTC-stamp>/
```

`<GATE-ID>` is `BG-01` … `BG-08` (see `../INDEX.md`). `<UTC-stamp>` is `YYYY-MM-DDTHHMMSSZ`, and
both are created for you by:

```bash
bench-gates/tools/bench_capture.sh BG-0N --no-serial --note "what you are about to do"
```

Each folder gets, automatically:

- `meta.txt` — host, UTC and local time, `uname`, the operator's note, **the git HEAD and
  clean/dirty state of every W17 repo at capture time**, tool versions, and the serial ports
  visible on the machine.
- `MANIFEST.txt` — sha256 of every other file in the folder, written when the capture ends.

Each card's **"Outputs to save"** section lists what else belongs in its folder.

## What makes a capture citable

1. **It names the code it tested.** `meta.txt`'s HEAD list is the point — an observation that
   cannot say which commit produced it is not evidence. A `(DIRTY)` marker there is not fatal, but
   it must be explained in the folder.
2. **It carries its raw form, not only a summary.** Keep `console.raw`, keep the `.bin` from a
   CRSF tap. Summaries are derived; raw bytes can be re-decoded years later by someone who does not
   trust your summary.
3. **It states its evidence label.** OBSERVED, VERIFIED, INFERRED, ASSUMED, BENCH-TBD, BLOCKED or
   NOT-EXECUTED. A simulation, a native test or a static analysis is **never** promoted to physical
   verification.
4. **A conditional row is recorded present *or* N/A — never blank.** A2 says so explicitly, and the
   same rule applies to every card here.
5. **A photograph is fixed-exposure and identified** by the item or state it shows. An unlabelled
   dump is not reviewable.

## What must never land here

Credentials, the owner's or the giftee's personal details, or anything a public reader of this
repository should not see. Evidence folders are committed alongside the cards.
