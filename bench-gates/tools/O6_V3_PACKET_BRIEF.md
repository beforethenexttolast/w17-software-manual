# O-6 v3 packet worker brief — ready to launch the moment the photo/label packet lands

**Purpose of this file.** The owner's consolidated photo/label packet
(`W17_OWNER_PHOTO_LABEL_INTAKE.md`) is the next major offline input. This is the launch
document for consuming it: what to log, what it fills, who does what, in what order, with
what forbidden actions. Written so the next Director session can start the chain with zero
rediscovery — no re-reading of `_handoff/2026-09-06_O6_derivation_report.md`,
`_handoff/2026-09-06_O6_addendum_report.md`, or the two adversarial reviews is required before
launching EXTRACT.

## §0 Purpose and invariants

- **No power.** Nothing here authorises powering, flashing, live-TX, or a FIRST_ACTIVE step.
  A2 stays NOT-EXECUTED; Phase B stays BLOCKED regardless of how the v3 derivation turns out.
- **The packet authorises nothing.** It supplies identities and manufacturer figures. It does
  not open a gate, close A2, or advance the staircase policy.
- **BLOCKED beats plausible.** A row that cannot be closed by a manufacturer figure from an
  identified article stays BLOCKED. Do not fill it from a family figure, a search-engine
  number, or an adjacent product's datasheet.
- **M-PEAK stays in force** (`2026-09-06_offline_decision_round_2.md` DR2-2): manufacturer
  MAX/PEAK values only, 0% invented margin, never typ/nominal for peak, an unresolved max
  remains unresolved, a manufacturer max is design evidence, not a measured current.
- **No product-family assumptions.** An identified article's own datasheet, or nothing. A
  board-family datasheet, a marketplace listing's generic spec, or a "the same part probably
  behaves like X" inference are all refused, exactly as the v2 derivation refused them
  (`_handoff/2026-09-06_O6_derivation_report.md` §7, five refused figures).
- **No search-snippet number may override a contradictory datasheet.** If a fetched
  manufacturer PDF and a search-result summary disagree, the PDF wins; if no PDF exists, the
  snippet still does not fill the row.
- **Unreadable / no-brand / no-marking is valid evidence.** A photo that shows a label is
  absent, illegible, or generic ("MG90S, no brand") is a complete answer and correctly leaves
  the value BLOCKED — it is not a reason to ask again or to guess.
- **Every datasheet must be retrieved from the manufacturer or a named mirror of the
  manufacturer's own document**, with the retrieval date and the exact section/line quoted —
  the same discipline the v2 derivation and addendum already used (mirrors disclosed,
  `_handoff/2026-09-06_O6_derivation_report.md` §7 "Mirror disclosure").

## §1 Intake ledger template

One row per packet item (1–7, per `W17_OWNER_PHOTO_LABEL_INTAKE.md`'s table). EXTRACT fills
this table; it is the first deliverable and every later worker reads it instead of the raw
photos.

| # | Delivered (filenames) | Label text as transcribed by the owner | Identity extracted (make/model/marking, or "none/unreadable") | Manufacturer source used | Figures extracted (label: MAX/PEAK/typ/rated/min-settable) | Closes (DR2-x / cell) | Residual owner question |
|---|---|---|---|---|---|---|---|
| 1 Bench PSU | | | | | | DR2-3 → S0 | |
| 2 UBEC A | | | | | | DR2-4 → S1–S9 η | |
| 2 UBEC B | | | | | | DR2-4 → S1–S9 η, S9 column | |
| 3 MH-ET regulator | | | | | | DR2-6 → S1 | |
| 4 Blower | | | | | | DR2-9 → S6 | |
| 5 MG90S ×3 (or "one article, ×3 same") | | | | | | DR2-10 → S7/S8 | |
| 6 Speaker | | | | | | DR2-8 residual → S4 | |
| 7 Wi-Fi heatsink + clearance | | | | | | DR2-14 → procurement row 6, M-31 | |

Row 2 and row 5 may need one line per unit if the two UBECs or the three MG90S turn out to be
different articles — do not collapse them if the photos show a difference.

## §2 Cell map — packet item → cell → exact rule

Copied from the derivation report, not invented. Every formula below already exists in
`bench-gates/BG-03_phase_b_first_power.md` § "Starting current limits" or
`_handoff/2026-09-06_O6_derivation_report.md` §3.1; the packet only supplies the missing
identity that the formula needs.

| Cell | Packet item(s) | Rule (verbatim from the derivation) |
|---|---|---|
| **S0** | 1 | S0 = the bench PSU's minimum reliably settable current-limit value (item 1's photo (a)/(c)). No other term is added at S0 under DR2-5 (ESC feed separated). |
| **Every S1–S9 pack-side limit `L(N)`** | 2 | `L(N) = max( R(N-1), Σ_{k<N} P(k) ) + P(N)` (chaining rule, `BG-03`:123-125). The pack-side never-exceed is `I_pack ≤ 5 A × V_rail / (V_pack × η)`, where **η is the UBEC's conversion efficiency, read from its datasheet at the load level of the relevant substep** once item 2 names the make/model. Until item 2 is answered every `L(N)` stays BLOCKED exactly as it is today. |
| **S9a/S9b/B3.1 voltage column** | 2 | **The bench reading governs.** `BG-03`:142-145 is the rule, verbatim: *"**Bench pre-step for every Rail-B row:** at D8 Phase 1, **record BEC#2's actual output voltage** before S6–S9 and B3.1, and select the servo stall column from it"* — and the v2 derivation says the same (`_handoff/2026-09-06_O6_derivation_report.md`:281, *"**2.1 A** is the applicable column **until BEC#2's actual output is recorded**"*; :282, *"Ceiling DERIVED = 2.1 A at 6 V, **selected from the recorded BEC#2 voltage**"*). Item 2(c) supplies BEC#2's **fitted jumper/label**, i.e. its **expected** (nominal) setting — 5 V or 6 V. That is what the packet buys: it tells the planner which of the DS3235SG columns (**1.9 A at 5 V / 2.1 A at 6 V / 2.3 A at 7.4 V**) to prepare, and it lets the S9a/S9b/B3.1 rows be **pre-filled** ahead of the bench. **It does not replace the reading**, and a photograph never selects the column (Rail B's documented band is 5–6 V, `w17-control-fw/docs/D8_BENCH_BRINGUP.md`:55). If the recorded output disagrees with the jumper, the recorded output wins and the pre-filled column is corrected. |
| **S1 ceiling** | 3 | S1's ramp ceiling = the MH-ET board's onboard regulator's **datasheet rated output current**, once item 3(c)'s marking is read and the part identified. If the marking is unreadable or absent, S1 stays BLOCKED and the smallest question is the marking itself, not a number. |
| **S2** | — | **No change from the v2 derivation.** The RP1 has no onboard regulator to read; item 3 does not touch S2. State this explicitly in the v3 report so a later reader does not assume item 3 closes both rows. |
| **S6** | 4 | S6 = the blower's manufacturer max/rated current, once item 4's label identifies the actual article (the BOM names only an "ACP2006-class" part, not a part number, `_handoff/2026-09-06_O6_derivation_report.md` §2). If the label is generic or absent, S6 stays BLOCKED. |
| **S7/S8** | 5 | S7/S8 = a manufacturer figure for the **identified article** shown in item 5's photos, if one exists. If the case reads only "MG90S" with no maker (the likely case — TowerPro's own page publishes no current figure even for the genuine article), S7/S8 **stay BLOCKED** and the smallest question is returned per `W17_OWNER_PHOTO_LABEL_INTAKE.md` row 5. Do not substitute a third-party reseller figure. |
| **S4 output-driven term** | 6 | **S4 has NO standing driven bound.** `P(4)` is BLOCKED on two named data (`BG-03`:154; `first_power_current_limits.md` L13 :76, T7 :102, after the DR3-2 derivation v2): (i) the datasheet publishes no *minimum* efficiency, so no upper bound on supply current is derivable at any gain — a gap no photo closes; (ii) the speaker impedance — this item. The `≥ 640 mA` figure on L13 is **REFERENCE ONLY** (a lower bound resting on a *typ* 3.2 W guidance value at the 12 dB spec point, a condition the car does not ship — DR3-2 confirmed 9 dB); it is **not M-PEAK-clean, is not a floor, and must not be entered as a rail-sizing term or a `P(N)`**. **What item 6 changes:** if the label proves 8 Ω rather than the BOM's stated 4 Ω, every amp figure derived at 4 Ω becomes slack, never tighter (P ∝ V²/Z, `BG-03`:154); if 4 Ω, nothing tightens. Record the confirmed impedance on S4 / T7 / L13 as a labelled fact; `P(4)` stays BLOCKED on (i) regardless of the answer, and the never-exceed for the branch stays the datasheet's ±1.6 A absolute maximum (a damage threshold, not an allowance). |
| **Wi-Fi heatsink envelope** | 7 | The footprint/height numbers in item 7(a)/(b)/(c) become the real envelope for `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` row 6 (the ≥ 32×32 mm BUY row, currently capped at "no taller than the fitted 7.0 mm stack until measured", `w17-batch1-measurements-for-codex.md`:40). They also close the "**heatsink fitted before first power-on**" precondition of `BG-03` (`learning-manual/05_control_firmware_documentation_explained.md`:365-366) once a part meeting the envelope is sourced and fitted — sourcing itself is a procurement action, not part of v3. Propose the new measurement row **M-31** (Wi-Fi bay free volume) exactly as flagged in the intake item 7 and in `_handoff/2026-09-06_O6_derivation_report.md`'s Q10′ — do not add it to the live measurement pack without a reviewed `w17-3d-codex` branch of its own. |

**Rows a packet item does NOT feed, stated so v3 does not over-claim:** T12 (ESC standby — no
manufacturer figure exists at any identity; unaffected by the packet), T13 (inrush magnitude —
blocked on PSU/UBEC input-capacitance data no manufacturer publishes; the packet's PSU/UBEC
identity does not change this), L11/L14/L15/L16 (Wi-Fi module and LED-strip figures — already
resolved in v2/addendum, untouched by any of the seven items), and the camera's S5 operating
point (blocked on an uncaptured driver config, `_handoff/2026-09-06_O6_addendum_report.md` §1.2
— a camera bring-up task, not a photo).

## §3 Worker chain and briefs

Sequence: EXTRACT → DERIVE v3 → R-O6-3 → FIX → V-O6-3 → state-file pass → push grant request.
Reviewer ≠ implementer ≠ verifier (owner model policy, restated in every DR). Every worker
names its model explicitly when launched.

**EXTRACT — Sonnet, read-only intake → ledger.**
Inputs: the packet's photos/filenames and the owner's transcribed label text (wherever the
owner said they are); this brief's §1 template.
Outputs: `_handoff/<date>_O6_v3_intake_ledger.md` (§1 filled, one row per item, no gaps);
identity-only updates to `HARDWARE_INVENTORY.md` component notes (exact marking, no current
figures yet) on a new branch `offline/o6-v3`.
Forbidden: fetching or citing any datasheet; writing any current, voltage, or efficiency
figure; touching BG-03 or the tools file.
Done when: all 7 ledger rows are complete (including "none/unreadable" rows) and the branch
diff touches only the ledger file and identity notes.

**DERIVE v3 — Opus, on `offline/o6-v3`.**
Inputs: the intake ledger; §2 of this brief; `_handoff/2026-09-06_O6_derivation_report.md`
(v2, canonical formulas) and its addendum.
Outputs: `_handoff/<date>_O6_v3_report.md` (same shape as the v2 report: §0 changes, part
identities, the staircase table, §5 owner questions, §7 refusals); applies the closed cells
into `bench-gates/BG-03_phase_b_first_power.md`, `bench-gates/tools/first_power_current_limits.md`
(T11–T13, L-rows), and `bench-gates/BG-04_d8_bench_bringup.md` where the D8-1c bench pre-step
is affected.
Forbidden: filling any cell from a family figure or an unidentified article; inventing a
percentage margin; touching any gate line, A2, or Phase B's BLOCKED status.
Done when: every §2 cell is either closed with a manufacturer citation or explicitly restated
BLOCKED with the smallest remaining question, and the report cites the ledger for every
identity claim.

**R-O6-3 — Opus, adversarial, fresh (not DERIVE v3's author).**
Inputs: the v3 report and its edited cards; §4 of this brief.
Outputs: a persisted review (`_handoff/<date>_R-O6-3_review.md`) with a verdict, BLOCKING /
NON-BLOCKING / NOTE findings, each tied to a specific line.
Forbidden: fixing anything itself; weakening a BLOCKED row to make the review shorter.
Done when: every checklist item in §4 has been attempted against every changed cell, not just
skimmed.

**FIX — Opus.** (The owner's routing reserves implementation to Opus; Fable is Director / major adjudication only, `2026-09-06_offline_decision_round_3.md` "Model routing and review discipline".)
Inputs: R-O6-3's findings.
Outputs: a v3.1 (or v3-fixed) report and card edits, with a §0-style change table mapping every
finding to what changed, exactly as v2 and the addendum did.
Forbidden: accepting a finding without applying it or recording why it was not applied; reopening
a ruling that already has an owner DR/D ruling behind it.
Done when: every BLOCKING and NON-BLOCKING finding has a row in the change table.

**V-O6-3 — Opus, fresh (not DERIVE v3's or FIX's author).** Named, not a choice: this round is safety-bearing (rail limits, never-exceed cells), and the owner's routing puts difficult electrical/safety reasoning on Opus. A round that turns out to be ordinary bookkeeping may be re-scoped to Sonnet by the Director in writing before it starts — never by the worker.
Inputs: the fixed v3 report, the review, the change table.
Outputs: a verdict (`_handoff/<date>_V-O6-3_review.md`): PASS, or FIX_REQUIRED with its own
findings (assume it will find something — every prior artifact in this program did, v1 7B, v2
1B, DR2 application 3B, addendum 3B, per `NEW_SESSION_HANDOFF.md` §4 item 2).
Forbidden: re-deriving numbers from scratch instead of checking the applied ones; skipping the
citations it did not personally choose.
Done when: it returns PASS, or another FIX/V-O6-3 round closes its findings.

**State-file pass — Sonnet, and it is only half the set.**
Inputs: the PASSed v3 chain.
Outputs: `W17_OFFLINE_READINESS.md` and `W17_OWNER_ACTIONS.md` updated to reflect v3 as the live
derivation, plus any newly-BLOCKED smallest questions surfaced per §5 below.
Forbidden: pushing; touching any file outside those two and the branch already in use; **editing
`CURRENT_STATUS.md` or `NEW_SESSION_HANDOFF.md`** — this program treats both as **Director-owned**
and no worker branch touches them. The worker returns the exact replacement sentences for those two
files in its report instead.
Done when: those two files are consistent with v3, and the Director's own pass has landed the
`CURRENT_STATUS.md` / `NEW_SESSION_HANDOFF.md` half.

**Director state-file half — Director.**
Inputs: the state-file pass's returned replacement sentences.
Outputs: `CURRENT_STATUS.md` and `NEW_SESSION_HANDOFF.md`.
Done when: a fresh boot from `NEW_SESSION_HANDOFF.md` alone finds v3, not v2, as current.

**Fresh push grant request — Director only.**
This is a **new** branch; DR2-1 and DR3's grants are CONSUMED and exact-scope
(`2026-09-06_offline_decision_round_3.md` "Push grant"). Request scope: workspace
`offline/o6-v3` (or its fixed tip) → main, nothing else, in the same shape as the prior two
grants.

## §4 Adversarial pre-checks

Run every row against every changed cell — not a sample. Each is a defect class the adversarial
reviews of this same program actually found; a v3 review that skips one is not equivalent to
R-O6/R-ADD's coverage.

| # | Check | Found by (do not repeat this exact defect) |
|---|---|---|
| 1 | Voltage/column mixing: does a Rail-B figure select its column (5/6/7.4 V) from the recorded BEC#2 setting, not a bare single number? | `R-O6_review.md` B1 |
| 2 | Domain mixing: is every P(N)/never-exceed cell labelled 5 V rail-side, and every L(N) labelled pack-side, with the η conversion stated or BLOCKED — never dialled in directly? | `R-O6_review.md` B2 |
| 3 | Settled-reading-as-bound: does any row let a quiescent/silent/unassociated reading stand in for a load that has a cited peak? (The chaining rule forbids it; a load's *state* — silent vs driven, unassociated vs streaming — must be recorded with every reading.) | `R-O6_review.md` B3; `R-ADD_review.md` B2 |
| 4 | Spec-condition mismatch: does a figure taken from one datasheet condition (a different gain, a different Z, a different revision) get used as if it described the shipped configuration? | `R-O6_review.md` B7 (uncited 20 mA/channel); addendum §2.2 / §2.6 (12 dB datasheet condition vs shipped 9 dB) |
| 5 | Unread sections/revisions: was the datasheet read in full, including sections not obviously relevant (a §4 configuration section, a later document revision with a table the earlier one lacks)? | `R-O6_review.md` B6 (Worldsemi Mar-2017 vs Jan-2016); `R-ADD_review.md` B3 (BL-M8812EU2 §4 unread in v1) |
| 6 | Family/generic substitution: does every figure trace to the *identified* article's own datasheet, never a board-family, reseller, or "same part probably" figure? | `_handoff/2026-09-06_O6_derivation_report.md` §7 (five refused figures) |
| 7 | Cite drift: does every `path:line` actually contain the quoted text, re-opened by this reviewer, not copied from the prior report? | `R-ADD_review.md` B1, N4 |
| 8 | Uncited numbers: does every mA/A/V/Ω figure carry a source tag (`[datasheet]`/`[code]`/`[doc]`), with no bare number introduced by this pass? | `R-O6_review.md` B7 |
| 9 | Margin-direction inversion: is a "requirement on the supply" (a datasheet's minimum-capability spec) kept out of P(N), and is the part's own rated maximum draw kept in P(N) even when it looks large? | `R-O6_review.md` N4; addendum §1.2 item 3 (V-O6-2 B1) |
| 10 | Unbounded ramp: does any BLOCKED-ceiling row still read as "ramp until it leaves constant-current" instead of naming a ruled or derived ceiling? | `R-O6_review.md` B5 |
| 11 | Topology-change consequence: if separating or re-routing anything is proposed, is the A2 gate consequence (re-run P2/P4/P5) stated explicitly? | `R-O6_review.md` N9 |

## §5 Smallest specific owner question — format

One line per number that remains genuinely underivable after the packet and this chain. No
other content per line.

```
Q<n> — <the exact fact needed, in the fewest words that are still unambiguous>. Unblocks: <cell(s)>.
```

Example shape (not a prediction of what will remain open — v3 may close all seven items or
none):

```
Q1 — Is there a manufacturer marking anywhere on the blower's frame/hub besides "ACP2006-class"? Unblocks: S6.
```

Do not bundle two facts into one question, do not restate context already in the ledger, and do
not propose a number for the owner to approve — only ask for the fact that would make the
number derivable.

## §6 What the packet does NOT do

- Authorises no power, no flashing, no live-TX, no FIRST_ACTIVE step, and discharges no gate.
- **A2 stays NOT-EXECUTED.**
- **Phase B stays BLOCKED** regardless of how many of the seven items close — closing every S1–S9
  cell only makes the staircase *runnable once Phase B is opened*, which needs A2 closed and
  reviewed first (`bench-gates/BG-03_phase_b_first_power.md`:3-10).
- Does not authorise sourcing or fitting the replacement Wi-Fi heatsink; item 7 only fixes the
  size envelope. Fitting it is a procurement + build action, tracked separately
  (`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` row 6).
- Does not touch Decision Round 3: **DR3-1 and DR3-2 are RULED and applied**
  (`2026-09-06_offline_decision_round_3.md`); **DR3-3 (temperature instrument) is the one open
  owner CHECK** of that round and is not a photo item. Do not re-ask DR3-1 or DR3-2.
- Does not by itself authorise a fresh push grant — see the last row of §3.
