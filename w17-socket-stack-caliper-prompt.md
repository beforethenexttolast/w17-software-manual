# Session prompt — the socket-stack caliper (five minutes, and it gates the build)

Paste into a Claude Code session started at `~/Documents/projects`. **No power. One measurement.**

> **Opus 5, `medium`.** Deliberately a *standalone* session, not the first step of the build sitting:
> its outcome decides **which version of the checklist the bench runs**, and you should not spin up a
> long soldering session only to abort in its first five minutes.

---

Take one measurement and give me a **GO / NO-GO on socketing**. Nothing else.

## What to measure

The **female header** intended for the PDB, stacked with an MH-ET D1-Mini's **pre-soldered male
pins**, seated as it would be in the cassette. Then compare the total stack height against the ZK
cassette clearance **`S0` ≥ 9.82 mm**.

⚠ **`S0` here is the ZK clearance figure.** The A2 gate formerly called S0 was **renamed SF** on
2026-08-04 to end exactly this collision — there is no gate S0 any more. If you meet a bare `S0` in
any document, it is the clearance.

Measure the real parts, not a datasheet. Record value, unit, instrument, and date, and tag it
**MEASURED** — this project has been burned by order-spec numbers written in as though observed.

## Why it gates

The owner's **F12 decision is socketed**, and it was recorded with this verification explicitly owed
and a **stated reopening condition**. If the stack breaks the clearance:

- socketing reopens and the boards go **hard-wired**;
- **§3 rule 2's unseat-for-isolation method stops being runnable**;
- which changes how the isolation rows execute across **S2, S4b and S8**.

So this is a precondition, not a to-do. **Caliper first, then the first joint** — not "start SF and
measure as you go."

## The two outcomes

**PASS** — record it, mark F12's owed verification discharged in `CURRENT_STATUS.md` and in §3 rule 2
of `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`, and say plainly that the
bench sitting is cleared to start. Then stop; do not begin building.

**FAIL** — **stop. Do not solder.** Reopening F12 is a document change before it is a build change:
the checklist's isolation method has to be rewritten before anyone touches the harness. Report the
numbers and the margin, and leave the decision to me. Do not improvise a lower-profile socket or a
partial-height compromise on the spot.

**Marginal** (inside a millimetre or so) is a **report, not a judgement call.** Give me the number
and your read; I decide.

## While you have the boards out

Optional, and only if the caliper passes — **do not let it delay the verdict.** The **MH-ET adjacency
list** (§2 call-outs, currently an explicit OWED placeholder) is derived by reading the risky
neighbour pairs off the silkscreen. Its fallback, "inspect every joint," is valid but slower, so it
is a to-do rather than a precondition. If you do it, record which pairs and from which board.

## Before you touch a repo

Run `git worktree list` and `git branch --show-current` in both repos. `w17-control-fw`'s tree has
recently been held by another session — if it is on a branch that is not yours, **do not check out**;
create a worktree outside `~/Documents/projects` (see `CLAUDE.md` → *Concurrent sessions*).

**Safety:** no power, no battery, no USB, nothing flashed or connected — calipers only. Nothing here
opens a gate: **A2 stays NOT-EXECUTED and Phase B stays BLOCKED** whatever the number says. Show
diffs before committing.
