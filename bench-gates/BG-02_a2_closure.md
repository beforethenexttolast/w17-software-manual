# BG-02 — A2 closure (the two-part gate, token `A2-CLOSED`)

*Card for `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` §12 (cited as
**A2**). Two parts that attest different things; **neither substitutes for the other**
(A2:730-734).*

> **What A2-CLOSED means, stated before anything else:** *"the no-power checklist is complete,
> self-consistent, and photo-corroborated, and the owner attests the measurements are real."* It
> does **not** mean *"the hardware is safe."* Opening Phase B is the owner's call on the owner's
> bench, informed by A2 — **not a verdict the reviewer is competent to issue** (A2:756-759).

## Prerequisites

1. **BG-01 executed to completion**: A2 §11's table filled with real readings, the photo set
   taken, deviations written up (A2:832-838).
2. The pasted-back package is **complete before review starts** — a partial table is not
   reviewable, and reviewing it anyway is how a blank row becomes a silent pass.
3. The reviewer is a Claude Code session with **read access to the photos as images**, not just
   filenames. Photo inspection is mandatory, not optional (A2:744).
4. Reviewer ≠ the person who took the measurements. Part 1 checks the record; Part 2 attests the
   measurements. One person doing both collapses the gate into one signature.

## Required equipment

- The filled A2 §11 table.
- The photo set, **identified by item number** — an unlabelled dump is explicitly not sufficient
  (A2:835).
- `w17-control-fw/project-review/11_hardware_validation_plan.md` for the cross-reference (its §A2
  maps A2.1–A2.5 onto the S-gates, :46-52).
- A calculator for the tolerance arithmetic. Nothing else — **this gate touches no hardware.**

## Topology (ASCII)

```
   BG-01 output                       BG-02 (this card)                     result
   ------------                       -----------------                     ------

   §11 table (filled) ─┐
   15 photos ──────────┼──►  PART 1  Reviewer check (Claude Code session)
   deviation notes ────┘        · completeness — no blank conditional rows
                                · gate attribution — right row at right gate
                                · arithmetic + tolerance
                                · internal consistency (CP3 vs M1 …)
                                · cross-ref against 11_hardware_validation_plan §A2
                                · DIRECT INSPECTION of the photos      ──┐
                                                                          ├─► A2-CLOSED
   owner ──────────────────►  PART 2  Owner attestation (signed line)  ──┘        │
                                                                                   │
                        ┌──────────────────────────────────────────────────────────┘
                        │
                        ▼   NOT automatic
                 owner-only decision  ──►  PHASE-B-OPEN  (a separate gate, BG-03)

   What Part 1 CANNOT see:  the hardware. A probe on the wrong pin, a misread range,
   37 kΩ transcribed as 3.7 kΩ — no independent signal exists (A2:746-749).
```

## Exact procedure (numbered)

**Part 1 — Reviewer check (A2:735-744).** Work the six sub-checks in this order; each one can
send the package back on its own.

1. **Completeness.** Every row in §11 filled, none silently skipped. Every conditional row —
   **H5, G11, G14, PD1, MS1–MS13, CP1–CP3, E7's no-metal case** — explicitly recorded as present
   *or* N/A rather than blank. MS1–MS13 close as a block under NOT-ASSEMBLED if the SP3T selector
   is not wired (A2:739).
2. **Gate attribution.** Each row taken at its listed gate. Check **D1–D3 at S1** and
   **E0–E3/E6 at S8a** specifically: a post-S6 divider reading, or an E-row probed after
   insulation, is **not valid evidence** — §3 rule 4 (A2:740).
3. **Arithmetic and tolerance.** Divider within **±5 %** of 10 / 27 / 37 kΩ; Hall pull-up
   **≈10 kΩ to 3V3** at the board end; W1 **≈330 Ω**; W2 in **0.15–0.35 V** (A2:741).
4. **Internal consistency.** No row contradicting another — the worked example is **CP3 vs M1**,
   which read the same composite through different paths and must agree (A2:742, :556).
5. **Cross-reference** against `11_hardware_validation_plan.md` §A2: A2.1 → S3+S4, A2.2 → S8a+S8b,
   A2.3 → S7, A2.4 → S5, A2.5 → S4/PD1 (plan:46-52; A2:743).
6. **Direct inspection of the §10 photos.** Solder bridges, connector orientation, cap stripe
   polarity **including C1 (item 14 — the only evidence stop 6 gets for it)**, the **1N5819 band
   direction**, and the **pre-shrink severed red conductor** (item 3) are all visually checkable.
   Scoped honestly: a photo **cannot** show harness topology — that every G-row conductor reaches
   one junction is attested by the S7/S8b electrical rows alone; item 9 corroborates only that a
   junction exists (A2:744).
7. Write the Part 1 verdict: **clean / send-back**, with the specific rows at fault. State the
   scope limit verbatim — Part 1 validates that the *record* is complete, coherent and
   photo-corroborated; it does **not** certify the car is safe (A2:746-749).

**Part 2 — Owner attestation (A2:751-754).**

8. The owner writes and signs **one line**: that they physically performed each §11 measurement on
   the actual assembly, at the gate recorded, with the meter in the stated mode.
9. **Both parts are recorded, dated, in `CURRENT_STATUS.md`**
   (`w17-parts-to-gift-master-sequence.md`:188-189). A2-CLOSED exists only when both lines are on
   file.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# Evidence folder for the closure record itself.
bench-gates/tools/bench_capture.sh BG-02 --no-serial --note "A2 closure, Part 1 review"

# The two documents Part 1 reconciles.
sed -n '730,760p' w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md   # §12
sed -n '31,53p'   w17-control-fw/project-review/11_hardware_validation_plan.md        # §A2 map

# Completeness screen: find any row in the pasted-back table with an empty
# "Measured" or "P/F" cell. A hit here is a send-back, not a judgement call.
awk -F'|' '/^\| *[A-Z]/ { if ($6 ~ /^ *$/ || $7 ~ /^ *$/) print "BLANK:", $2 }' \
    bench-gates/evidence/BG-01/<UTC-stamp>/a2_measurement_table.md

# Photo-set completeness: A2 §10 has exactly 15 items, and item 3 needs TWO shots.
ls -1 bench-gates/evidence/BG-01/<UTC-stamp>/photos/ | sort
```

No build, no flash, no port. **A2-CLOSED is a paperwork state; the only thing this gate runs is a
review.**

## Expected evidence

- A **Part 1 verdict document** naming every sub-check and its result, with the send-back rows
  listed explicitly if any.
- A **Part 2 attestation line**, signed and dated by the owner.
- Both **copied into `CURRENT_STATUS.md`** with dates (master sequence:188-189).
- The photo-inspection notes — what was actually seen in each image, not "photos reviewed".

## PASS/FAIL criteria (objective numbers)

| Check | PASS | FAIL |
|---|---|---|
| Completeness | **0** blank cells in §11; **0** blank conditional rows (H5, G11, G14, PD1, MS1–MS13, CP1–CP3, E7) | any blank |
| Gate attribution | **100 %** of rows carry the gate they were taken at, and it matches A2's listed gate | any mismatch, especially D1–D3 ≠ S1 or E0–E3/E6 ≠ S8a |
| Divider arithmetic | D1, D2, D3 each within **±5 %** of 10 / 27 / 37 kΩ | outside ±5 %, or D2 ≈ 20 kΩ (old design) |
| Hall pull-up | **≈10 kΩ to 3V3**; H1b shows **no beep** to any 5 V | pull-up to 5 V ⇒ stop 8 |
| WS2812 | W1 **≈330 Ω**; W2 **0.15–0.35 V**; W3 **OL** | outside the band |
| Consistency | CP3 settles to **≈ the M1 value** | a divergence neither row explains |
| Cross-reference | all **five** A2.x plan rows map onto executed S-gates | any A2.x with no executed gate behind it |
| Photo inspection | all **15** items present, item 3 has **2** shots, item 14 shows C1's stripe | a missing item, or item 3 with only the after-shrink shot |
| Part 2 | one signed line on file | absent, or written by anyone but the owner |
| §13 | **zero** hard stops recorded | any hard stop ⇒ FAIL, full stop (A2:762) |

**Minor deviations** (a resistor at the edge of tolerance, an unpopulated *optional* Hall RC) are
**PASS-with-note** and must appear in the verdict as such (A2:761).

## Stop conditions

- **Any §13 hard stop in the pasted-back data** — the gate does not close, and the finding goes
  back as a build fault, not as a paperwork problem.
- **A blank conditional row.** Do not infer "probably not populated". A2 says blank is not a pass
  (A2:370, :739); send it back.
- **A row measured at the wrong gate.** Do not accept a re-measurement taken later on the
  composite harness as a substitute — for the single-shot rows there is no valid later reading
  (A2:197-201).
- **An unlabelled photo dump.** Part 1 *inspects* the photos; it cannot inspect what it cannot
  identify (A2:835).
- **Pressure to close on "it's obviously fine".** The one thing this gate exists to prevent is a
  record that reads closed without the evidence behind it — that is precisely finding F19's
  lesson (A2:86-95).

## Rollback

- **Send-back is the normal rollback**: name the rows, return the package, re-run *those rows at
  their own gates* in a new BG-01 session. Nothing needs undoing physically unless the fault is
  physical.
- **A2-CLOSED recorded in error** is rolled back by an explicit dated correction in
  `CURRENT_STATUS.md` and by re-blocking Phase B. There is no other mechanism — the gate is a
  document state, so a wrong entry is corrected the way any wrong entry is.
- Because nothing is powered by this gate, there is no hardware rollback.

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-02/<UTC-stamp>/
  meta.txt
  MANIFEST.txt
  part1_verdict.md          # six sub-checks, each with its result; send-back rows named
  part1_photo_notes.md      # what was seen in each of the 15 items
  part2_attestation.txt     # owner-signed, dated
  crossref_11_plan.md       # A2.1..A2.5 -> executed S-gates
  deviations_accepted.md    # every PASS-with-note, with its reason
```

Then the two dated lines land in `CURRENT_STATUS.md` — that file, not this folder, is where
`A2-CLOSED` officially lives.

## Downstream unlocked by PASS

- **`A2-CLOSED`**, and *only* that. It is a precondition of, not a grant of, `PHASE-B-OPEN`.
- `PHASE-B-OPEN` is a **separate, owner-only decision** recorded in `CURRENT_STATUS.md`
  (master sequence:194-204). Once both exist:
  - **BG-03** Phase B first power becomes reachable;
  - **BG-04** D8 bench bring-up Phase 0 onward (its Phase -1 hard stop reads both states,
    `D8_BENCH_BRINGUP.md`:3-13);
  - **BG-05** coordinated flash and **BG-07** BT1 both inherit the same two gates.

## BENCH-TBD residue

- Everything BG-01 could not close carries forward as a **note inside the closure**, not as a
  silent omission: an SP3T selector recorded NOT-ASSEMBLED, CP1–CP3 recorded NOT-ASSEMBLED (which
  become a **hard precondition to the first pack connection**, A2:560-562), an unpopulated PD1.
- **F20 remains open** at closure by design — A2 records it as "open, recorded not fixed"
  (A2:91-95). Closing A2 does not close F20.
- The **IP2326 charge-path no-power checklist does not exist**; A2 closing says nothing about it
  (A2:823-830).
- Part 1's own limit is permanent residue: **no reviewer can certify the hardware is safe**
  (A2:746-749). Everything a photo cannot show — harness topology above all — stays attested only
  by the S7/S8b electrical rows.

## Evidence label at card creation

**NOT-EXECUTED.** A2 has not been run, so no closure exists; `A2-CLOSED` is unrecorded and
Phase B is BLOCKED (`W17_CURRENT_STATE.md` §6; `CURRENT_STATUS.md` top entry). This card grants
nothing and closes nothing.
