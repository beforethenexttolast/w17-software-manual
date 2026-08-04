# Session prompt — close F15 and F16, and settle the `S0` name collision

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.**

> **Opus 5 at `xhigh`.** Fable is not needed — F15 and F16 are already characterised, with the
> mechanism and the affected sections named. This is implementation, not discovery.

> ⚠ **CONCURRENCY.** Other sessions have been sharing these working trees and it has already
> destroyed uncommitted work once. **Before you touch anything:** run `git worktree list` in both
> `w17-control-fw` and the workspace repo, and `git branch --show-current` in each. If either tree
> is on a branch that isn't yours, **do not `git checkout`** — create your own worktree
> (`git worktree add`) and work there. Report what you found before starting.

---

The A2 revision pass closed the fourteen adversarial-review findings, and **generated two more in
doing so** — exactly the outcome its prompt warned about, and correctly recorded rather than quietly
fixed. Close them.

## Read first

- `w17-control-fw/project-review/14_a2_staged_gates_adversarial_review.md` — the **closure table**
  (`0caf4e4`) plus the full F15 and F16 write-ups. This is authoritative; everything below is a
  summary of it.
- `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` at `docs/a2-revision-pass` —
  the revised checklist.
- `w17-pdb-build-and-connector-guide.md` at the **workspace** `docs/a2-revision-pass` (`d523983`) —
  the guide edits.

**The work spans two repos and both have a `docs/a2-revision-pass` branch.** Build on those branches,
not on `main`.

## F15 — CONFIRMED

F7's minimal fix, implemented as specified, **manufactures a §3-rule-2 false FAIL when the
GPIO13/GPIO14 pull-downs are fitted.** Same class as the finding that started all of this: a rule
written for one configuration applied to a set that includes another.

Note the shape — **a fix generated the defect.** So when you close it, ask the same question of your
own closure: what configuration does the corrected rule now mis-handle?

## F16 — CONFIRMED

**C1's fit moment was sequenced by neither document**, and the revision's own new rows made it
load-bearing. Affected: guide §5 old step 4 (C1 between the UBECs and the divider), the F2/F8 rows'
charging signature, and §5's order.

C1 is the 1000 µF across Rail B. Whether it is fitted changes what several new rows *expect to see* —
so an unsequenced fit moment means those rows have no defined expected value.

## The `S0` collision — settle it, don't annotate it

The revision created **gate S0** (PDB frame) while **S0 ≥ 9.82 mm** already exists as the ZK cassette
clearance. The closure table annotates the clash ("no relation to gate S0"). **That is not enough.**
This is the second name collision in two days — the R16 one produced a near-miss where a commit
subject read as closing a Phase-B safety gate.

**Rename one of them.** The gate is newer and has fewer references, so it is the cheaper rename unless
you find otherwise — but check before deciding, and sweep every reference in both repos. Annotation
is what we did for R16 because that name was already load-bearing in two published series; here
nothing is published yet, so fix it properly while it is cheap.

## Also verify while you are in here

The closure table records **two owed measurements that are NOT closed** under F12 — the socket-stack
caliper against the ZK clearance, and the MH-ET adjacency list (currently an explicit OWED
placeholder). **Confirm both are still marked owed and neither has been quietly promoted.** They are
bench work and must survive this pass as open.

## Output

Updated checklist and guide, plus F15/F16 rows added to the closure table with the same
finding → what changed → where format. If closing either one generates an F17, **record it; do not
quietly fix it.** The register is the point.

Then state plainly: **is the checklist now executable?** That is the question the bench sitting is
waiting on, and it is the only thing anyone needs from this session.

**Safety:** documents only. Nothing built, powered, flashed, or connected. Closing findings makes A2
*executable*, not *executed* — **A2 stays NOT-EXECUTED and Phase B stays BLOCKED** regardless. Show
diffs before committing.
