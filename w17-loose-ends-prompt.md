# Session prompt — 13. Two loose ends before the final reconciliation (docs-only, no hardware)

Small session. Run it **immediately before prompt 10** (`w17-record-reconcile-prompt.md`), so that pass has
nothing stale left to record. Two phases in two repos; finish A before starting B.

No hardware, no gate change: **A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**

---

## PHASE A — `w17-design-system`: one wrong number, one unrendered mockup

Start the session in `~/Documents/projects/w17-design-system`. Baseline `1415686`, clean and pushed.

### A1. Fix the dead-column figure

`DESIGN_NOTES.md:208` records "**~300 px** dead left column at 1024×640" in the §14(d) reasoning. The
measured figure is **~191 px**. The ~300 px number came from the original audit estimate; prompt 12 phase A
measured the real screen and corrected it, but the session that wrote §14(d) ran a pre-correction copy of the
prompt.

Everything else in that passage is right and must not change: the ratio **3.0–3.2 : 1**, the column-end
figures **41.8% / 71.6%** at 1024×640, and SEAT FIT's **1.31–1.38 : 1** inversion. Verify each of those
against §14(d) as you go — if any other figure disagrees with this list, say so rather than assuming this list
wins.

While you're in that section, consider adding one sentence a future reader will otherwise trip over: the
shipped single-column SETUP **exceeds the viewport at three of four sizes** (30 / 72 / 95 px at 1280×800 ·
1366×768 · 1024×640), and **every pixel of that is `--gate-toast-reserve`** — 121.6 px of `.gate` bottom
padding held for the `position:fixed` `.radioLog` — not content. All content plus BACK/NEXT stays visible
unscrolled (worst case nav bottom 95.8% of a 640 px viewport), an all-elements intersection sweep found
**zero** hits against the radio band, and `.gate` already carried `overflow-y:auto` +
`justify-content:safe center`. Owner accepted scroll. Without that note, anyone who measures the shipped
screen finds an overflow and cannot tell it was diagnosed and accepted. Propose the wording; keep it to a
sentence or two.

### A2. Actually look at the mockup you changed

`screens/05-hud.html` was reordered to the shipped BATT → pillrow → ERS order in `1415686` but was **never
rendered** — the browser pane refuses `file://` outside the project folder. The workaround that worked in
prompt 12 phase A: serve the directory over a local static HTTP server on `127.0.0.1` and load it over
`http://`, which sidesteps the folder restriction entirely.

Confirm three things visually, then stop the server: the right column reads **BATT → pillrow → ERS** top to
bottom; the pill row reads **BOOST · OVERTAKE · DRS**; and the bottom edge terminates in a **full-width
block, not a chip** — that last one is the whole basis of §11(f)'s ruling, so it is the one worth actually
seeing. The change is a sibling reorder inside an existing `flex-direction:column` container, so a layout
surprise is unlikely; this is confirmation, not investigation. If it looks wrong, stop and report rather than
adjusting the ruling.

Show diffs before committing. Docs/mockup only. **Do not touch `CURRENT_STATUS.md`** (prompt 10 is the single
writer) or `w17-ground-station`. Report the new HEAD as text.

---

## PHASE B — `w17-3d-codex`: read-only inspection, no writes, no push

Move to `~/Documents/projects/w17-3d-codex`. **This repo is Codex-owned.** The workspace `CLAUDE.md` says do
not edit Codex-owned repos from a Claude Code session, and that holds here — this phase is **strictly
read-only**. Do not commit, do not push, do not stage anything, do not run any command that mutates the tree.

It has **2 unpushed commits** on `main`:

- `59a1634` — "docs: stop this repo tracking arrivals; point to HARDWARE_INVENTORY.md"
- `2325fd9` — "assembly: add fit studies and validation evidence"

They have sat unpushed since ~2026-07-19, and the first one is the very cleanup that `HARDWARE_INVENTORY.md`
listed as owed — so the workspace's arrival-tracking story is only half-landed while it stays local.

Report, as text, so the owner can decide whether to push or hand it to Codex:

1. What each commit actually contains — `git show --stat` and enough of the content to judge, especially
   whether `2325fd9`'s "validation evidence" asserts anything about **physical hardware** that a Claude
   session has no basis to confirm.
2. Whether either commit **contradicts** anything the workspace now records — in particular the batch-1
   measured envelopes, the MH-ET D1-Mini board decision, the ESC 34 mm station reopen (CAS-06/ASM-49), the
   DS3235SG ~1.7 mm interference, or `HARDWARE_INVENTORY.md`'s §E ⏳ rows.
3. Whether pushing them would publish anything that shouldn't be public. Note that **this repo is PUBLIC**,
   as are all the other W17 repos except `w17-rc-print-codex`.
4. Whether the tree is otherwise clean and whether `main` has an upstream configured.

Then stop. The decision — push, hand to Codex, or leave — is the owner's.

---

## After this

Run **prompt 10** (`w17-record-reconcile-prompt.md`) next. It is the single writer for `CURRENT_STATUS.md` and
`VR_FPV_MASTER_PLAN.md`, and it should be the last session of this sequence. Give it phase A's new
`w17-design-system` HEAD and phase B's findings as text.
