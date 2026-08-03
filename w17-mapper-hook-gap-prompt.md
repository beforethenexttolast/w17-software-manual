# Session prompt — close the documented gap in the mapper pre-push accident guard (small, no hardware)

Paste into a Claude Code session started at `~/Documents/projects`. Small, self-contained; can be run
in the same sitting as `w17-mapper-holdlast-closure-prompt.md`.

---

`CURRENT_STATUS.md` (2026-07-30, *two more FIRST_ACTIVE gate corrections*) records this as **owed in
`w17-mapper` and NOT done** — it was deferred because that repo had a live session at the time:

> extend the hook's own verification to confirm it *misses* the const form and record that as a
> documented limit; the existing "bites on all three injections" evidence does not cover it.

## The gap

`w17-mapper/.githooks/pre-push` (enabled here via `core.hooksPath = .githooks`) scans code for exactly
two literals: lowercase `w17_first_active`, and the uppercase word `FIRST_ACTIVE`. The unlock plan's
own previously-suggested `const firstActive = false` matches **neither** — so arbiter code gated that
way would pass both checks and reach a **PUBLIC** remote
(`github.com/beforethenexttolast/w17-mapper`).

§2.3.11.4 has since been resolved to **the Go build tag, exclusively**, and the const alternative was
deleted rather than kept as a fallback — precisely because the const branch silently disarms the
shipped accident guard. The naming contract is that the tag must be lowercase `w17_first_active`
**exactly**, because that is the literal the hook greps.

## Do

1. **Prove the gap exists** before changing anything: inject `const firstActive = false` into a
   throwaway Go file and confirm the hook passes it. That is the missing evidence.
2. Decide with me between two closures — **do not pick unilaterally**:
   - **(a) Document the limit only.** Record in `FORK-NOTICE.md` and the hook header that the guard
     detects the tag and the uppercase identifier, and does *not* detect an arbitrary const; the
     control is the written push-review rule, the hook is only the accident guard.
   - **(b) Widen the hook** to also catch case-insensitive `firstactive` / `first_active`
     identifiers — stronger, but risks false positives on prose and on the doc files that legitimately
     discuss FIRST_ACTIVE by name. Show me the false-positive surface before I choose.
3. Whichever we pick, re-run the **full** injection matrix afterwards — the three existing injections
   plus the const form — and confirm a clean HEAD still passes. Record the matrix in the hook header
   so the next reader knows exactly what it does and does not catch.
4. Update `CURRENT_STATUS.md` to discharge the owed item.

**Safety:** no hardware. No FIRST_ACTIVE code, no arbiter, no active enum value — the proto must still
end at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8`. Remember the fork's `origin` is **public**: verify what
you are about to push distributes no control path. In `w17-mapper`, **branch from `w17-headtrack`, not
from `main`** — `main` there tracks upstream `2b8031a`, where both `.githooks/pre-push` and
`FORK-NOTICE.md` are **absent**; they exist only on the fork branch. Show diffs before committing.
A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
