# Session prompt — A2 revision pass: close the 14 adversarial-review findings

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.**

> **Run on Claude Fable 5 at `xhigh` effort.** This rewrites the document that governs soldering,
> while holding fourteen findings, four owner decisions, and two sibling documents in view at once.
> Three of the findings are false-PASS class. A miss here becomes a wrong joint.

---

Revise `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` to close the findings in
`w17-control-fw/project-review/14_a2_staged_gates_adversarial_review.md`. **Both are on `main` in that
repo**, along with the four owner decisions appended to the review doc. Read the review in full first
— it carries the reasoning, the executed evidence, and the proposed fix for every finding.

**The verdict you are acting on:** A2 as written is not safe to execute, and the unsafety is of the
dangerous polarity — most of what is wrong produces **false PASSes, not false FAILs**. The staging
idea is right and stands. It was executed as a *subtraction*: the whole-harness screens the old §13
hard stops depended on were invalidated and never re-issued in staged form.

## Work in the review's order — it is dependency-ordered, not severity-ordered

1. **F1 + F2 + F3 — one edit session.** These are three faces of the same hole: after S6 the
   assembled car is the one configuration A2 no longer measures. Hard stops 1 and 4 currently have no
   generating measurement at all.
2. **F4 — restage S8 as S8a / S8b.** The hard gate. Currently both unexecutable (the cut end is under
   heat-shrink by S8) and unfalsifiable (the connector spec removes the +5 pin, so E1–E3 read OPEN
   whether or not the cut was made).
3. **F5 — S7's reference.** No pack exists; the fix is a harness-side reference.
4. **F8 — add S0 and fix the guide's build order.** Currently the guide's order manufactures a
   false-FAIL at S1. S0 also gives F2's pre-S6 rows a home.
5. **F6 / F7** — CRSF-lead isolation; the dropped A2.5 boot-float row.
6. **The rest** — F10, F13's six minor items, F14's §3 rule.

## The four owner decisions — already taken, implement them

- **F9 — the IP2326 is NOT fitted during A2 build week.** Strike guide step 8 from the A2 build, add
  the charger to S6's "after this point" list, and state in §14 that the charge path owns its own
  gate. **F9b:** the tap is **pack-side of the XT90-S**, decided even though the build is deferred,
  so the charger comes off the PDB block diagram in the connector guide.
- **F11 — Hall pull-up at the ESP32 end**, where 3V3 exists. Correct the guide's connector row and add
  **H1b `GPIO35 → 5V wiring: no beep`** so hard stop 8 finally has a generating row.
- **F12 — boards are SOCKETED**, so §3 rule 2's unseat-for-isolation stays runnable as written.
  ⚠ **This decision carries an owed verification:** socket height against the **S0 ≥ 9.82 mm**
  clearance has never been measured. Do not write anything that treats socketing as settled where S0
  is load-bearing; mark it. F12's other half — re-deriving the §2 adjacency call-outs from the
  **MH-ET silkscreen** rather than the DevKit V1 layout — is measurement work for the bench session,
  so leave a clearly-marked placeholder rather than inventing pairs.

## Sibling documents you must also edit

The checklist cannot be made correct alone. All three are workspace-repo or control-fw files you own:

- **`w17-pdb-build-and-connector-guide.md`** — §5 build order (F8), the Hall pull-up row (F11), the
  charger off the PDB (F9b), the stale `(opt GPIO26←17)` link2 row against the closed C4 decision
  (F13).
- **`w17-control-fw/project-review/11_hardware_validation_plan.md`** — §12 Part 1 cross-references it,
  and it still describes the single-pass A2.1–A2.5 shape (F13).
- **`CURRENT_STATUS.md`** — the revision itself, and whether A2's readiness statement changes.

## The trap, stated plainly

**A revision written to close fourteen findings is exactly the artifact that generates the
fifteenth.** This project has now produced five consecutive defects of one shape — *a property
asserted over a set where only some members were checked*. The A2 review found its own instance of
it, and the restructure it reviewed was itself a fix that introduced the hole it was fixing.

So, as you write each new row:

- **Can it fail?** Every row must have a reading that constitutes a FAIL. The "per your build" purge
  missed E1–E3; do not leave a new unfalsifiable row behind.
- **Is it valid at the gate it sits in?** F14's point generalized: **make "every pre-S6 row is
  single-shot evidence, valid only at its own gate" an explicit rule in §3**, so S1's warning becomes
  an instance of a stated rule rather than the only exception anyone happened to think of.
- **Does a hard stop have a row that generates it?** Walk §13 stop by stop and confirm each one is
  now reachable from a measurement. That check is what found F1 and F3.
- **Is it executable in sequence?** F4(a) failed because the probe target was insulated two gates
  earlier. For each new row, ask what physical state the harness is in when it is taken.

## Output

The revised checklist, the sibling edits, and a short **closure table** in the review doc: finding →
what changed → where. For anything you deliberately do not close, say so and why — an honest open
item beats a claimed closure, and **this workspace's cardinal error is the over-broad closure claim.**

If you find a fifteenth finding while revising, **record it; do not quietly fix it.** The review doc
is the register.

**Safety:** documents only. Nothing built, powered, flashed, or connected. This session cannot open a
gate: **A2 stays NOT-EXECUTED and Phase B stays BLOCKED** no matter how complete the revision is —
closing the findings makes A2 *executable*, not *executed*. Show diffs before committing; branch off
`main` in each repo.
