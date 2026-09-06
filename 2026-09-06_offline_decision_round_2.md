# W17 OFFLINE READINESS — Decision Round 2, owner rulings (2026-09-06, recorded 2026-09-06 evening)

Verbatim owner rulings, received in the owner's session-opening message of 2026-09-06 evening (Director: Claude Fable 5.1, session 719f19ec).
Authority: workspace `CLAUDE.md` safety boundaries 1–7 > readiness packet A1–A12 > `2026-09-05_offline_decision_round_1.md` > **this file** >
`W17_OFFLINE_READINESS.md`. The questions these rulings answer are recorded in `W17_OWNER_ACTIONS.md` (Decision Round 2 section) and
`_handoff/2026-09-06_O6_derivation_report.md` §5. **No powered, flashing, live-TX, FIRST_ACTIVE or other gated physical test is authorized by
these rulings.** Where a ruling says BLOCKED, the item waits for the owner's consolidated photo/label packet (`W17_OWNER_PHOTO_LABEL_INTAKE.md`).

## DR2-1 — PUSH GRANT
ONE-TIME EXACT-SCOPE grant: `program/offline-readiness-r2` at `4ae3536` → workspace main only. No nested-repository push is authorized.
Before landing: confirm the approved tree still matches the reviewed expected state; if content changed materially, independently verify the
changed portion; fast-forward; run workspace checks; push; record landing; mark the grant CONSUMED. If this grant was already executed in
durable state, do NOT execute it again.
**Status: EXECUTED and CONSUMED 2026-09-06 evening** — landing record `W17_OFFLINE_READINESS.md` §1b (main f1028ba → 4ae3536, record commit ca84c91).

## DR2-2 — M-PEAK
RATIFIED. For offline current derivations: use explicitly manufacturer-specified MAXIMUM / PEAK values; add 0% invented percentage margin;
never substitute typical/nominal/search-snippet values for peak; unresolved max remains unresolved; manufacturer max is design evidence,
NOT measured actual current; real bench measurements remain authoritative.

## DR2-3 — BENCH PSU
BLOCKED pending physical identification. Do not infer PSU model/current capability. The owner will provide: front-panel photo; model/spec label;
current-limit controls/display. Need: exact model; output voltage/current range; minimum reliably settable current limit / resolution.

## DR2-4 — UBEC
BLOCKED pending physical identification. The owner will provide clear photos of UBEC(s), labels and voltage-selection mechanism. Determine:
exact model; manufacturer current limits; actual BEC #2 setting: 5 V or 6 V. Do not infer from product family.

## DR2-5 — PSU-FIRST / ESC SEPARATION
RATIFIED. Initial logic/rail characterization uses bench-PSU-first operation with propulsion/ESC feed physically separated for the early
first-power substeps. Do not energize propulsion merely because logic-side first-power work is active. No execution is authorized yet.

## DR2-6 — S1/S2 RAMP CEILINGS
BLOCKED until actual MH-ET regulator marking is observed. Do not infer the regulator from board family. Once identified, derive relevant
ceiling from the actual regulator manufacturer's data and exact topology.

## DR2-7 — WI-FI RF MODE
Determine the actual SHIPPED / production Wi-Fi RF mode from canonical config and use that as the normal acceptance-condition load. If a
distinct demonstrably higher-current/max-TX mode exists, characterize it separately as STRESS/WORST-CASE. Do not silently redefine shipped
behavior around stress mode.

## DR2-8 — SOUND
Derive shipped sound volume from current canonical firmware/config. Determine speaker impedance from authoritative inventory or actual
article. If not conclusively known, leave BLOCKED for the owner's photo/label packet.

## DR2-9 — BLOWER
BLOCKED pending actual label/article identification. Use exact manufacturer evidence if identifiable.

## DR2-10 — MG90S
Do not use a generic internet MG90S value as if it describes the fitted servo. Wait for branding/label evidence. If the article cannot be
identified enough for a defensible ceiling, leave it BLOCKED and return the smallest specific question.

## DR2-11 — CONSTANT-CURRENT DURATION
Owner criterion: **Continuous PSU constant-current operation lasting more than 500 ms after connection = STOP.** Also: smell / abnormal heat /
smoke / unexpected sound / visual anomaly = IMMEDIATE STOP; brief inrush alone does not authorize raising current; CC trip never automatically
advances the staircase; diagnose and justify before increasing the limit; record actual observed CC duration.

## DR2-12 — (withdrawn 2026-09-06 afternoon, R-O6 N2; no ruling requested or given)

## DR2-13 — LED CAP
KEEP shipped `maxBrightness = 110`. 180 is only the owner-approved upper operating ceiling. Do NOT create a firmware-change branch now. Revisit
only after physical halo/visibility/current/rail evidence demonstrates 110 is inadequate. Any increase remains a reviewed firmware change
requiring a fresh push grant.

## DR2-14 — WI-FI HEATSINK
Do not deliberately ship below the module manufacturer's recommendation. Plan to source ≥ 32×32 mm heatsink if mechanical clearance permits. A
somewhat larger part is acceptable/preferred if it fits without creating mechanical, RF or serviceability problems. Still perform the planned
thermal validation at first power. Add this to procurement state if not already present.

## Consolidated owner photo / label packet (owner instruction)
Do not ask for these one at a time. Prepare ONE intake request for the car fully unpowered / battery disconnected: (1) bench PSU front panel +
model/spec label; (2) UBEC(s), both sides + jumper/voltage selector; (3) MH-ET board, both sides + regulator marking + USB-port area; (4) blower
label; (5) fitted MG90S branding/label(s); (6) speaker label if impedance remains unresolved; (7) Wi-Fi module + current 28×28×3 heatsink +
surrounding-clearance photo/measurement. When supplied: extract every defensible DR2/O-6 fact; update component identities; rerun the O-6
derivation; independently review the resulting current-limit table; leave genuinely underivable numbers BLOCKED.

## Model policy (restated by the owner)
Fable = Director / major adjudication only · Opus = difficult implementation, electrical/safety reasoning, adversarial review · Sonnet = normal
workforce, docs, scripts, bounded research, ordinary verification. Explicit model on every worker. Reviewer ≠ implementer ≠ fresh verifier for
consequential work.

## Push policy (restated by the owner)
Live durable state is authoritative. DR2-1 was exact-scope and one-time. Any NEW threshold/card/firmware/other branch needs a FRESH push grant.
Do not assume continuation of an old grant.

## Must not be lost from the physical/procurement queue (restated by the owner)
5 GHz AP-capable USB Wi-Fi adapter · in-envelope 2S car battery · GCS-box USB 3.x hub · boot-mode selector · OP-49/IP2326 evidence closure +
charge-path parts · ≥ 32×32 mm Wi-Fi heatsink if fit allows · TX16S internal-RF check → backup-handset decision · coupon C-1 · Windows ARM VM ·
no-power measurement sitting.
