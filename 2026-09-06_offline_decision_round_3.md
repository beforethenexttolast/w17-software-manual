# W17 OFFLINE READINESS — Decision Round 3, owner rulings (2026-09-06, recorded 2026-09-06 night)

Verbatim owner rulings, received in the owner's session-opening message of 2026-09-06 night (Director: Claude Fable 5.1, session 82158128).
Authority: workspace `CLAUDE.md` safety boundaries 1–7 > readiness packet A1–A12 > `2026-09-05_offline_decision_round_1.md` >
`2026-09-06_offline_decision_round_2.md` > **this file** > `W17_OFFLINE_READINESS.md`. The questions these rulings answer were opened in
`W17_OWNER_ACTIONS.md` (Decision Round 3 section) by the O-6 addendum v2 (`_handoff/2026-09-06_O6_addendum_report.md`).
**No powered, flashing, live-TX, FIRST_ACTIVE or other gated physical test is authorized by these rulings.** The owner's own words:
*"Nothing in this prompt authorizes: powered car testing · battery connection · charging · flashing · live-TX · FIRST_ACTIVE · any other
gated physical procedure. For any such operation, explicit fresh owner authorization is required."*

## DR3-1 — WI-FI STREAMING SOAK
Adopt: **30 minutes continuous streaming in the actual shipped/production Wi-Fi mode** as the S5 thermal-soak **CHARACTERIZATION** duration.
Record at: **0 min · 5 min · 10 min · 15 min · 20 min · 30 min.**
This is NOT a claim that 30 minutes proves thermal equilibrium.
Existing sensory STOP policy remains active: abnormal smell · abnormal heat · smoke · unexpected sound · visible anomaly · any other abnormal
behavior → **IMMEDIATE STOP**.
If a suitable contact temperature instrument exists, record temperature at those intervals. If no suitable instrument exists, do **NOT**
estimate temperature from touch.
**No powered execution is authorized by this decision.**

## DR3-2 — AUDIO GAIN
Confirm **9 dB GAIN** as the intended shipped MAX98357A hardware configuration before soldering.
Use the 9 dB shipped configuration for power/current reasoning where defensible.
Do NOT treat the datasheet's 12 dB specification point as the shipped configuration.
Before permanent soldering, verify the actual board's GAIN implementation/pad mapping against the exact article/datasheet.

## DR3-3 — TEMPERATURE INSTRUMENT
OWNER CHECK: determine whether the owner owns (a) a contact temperature probe; OR (b) a multimeter with K-type thermocouple input + probe.
If yes: record the exact instrument and incorporate it into S5 evidence capture.
If no: add suitable contact temperature measurement to CHECK/BUY and keep quantitative heatsink temperature evidence **BLOCKED**.
Do not invent surface temperature.
**Status at recording (2026-09-06 night): the check is the owner's — no durable file records any temperature instrument (procurement row 14
was added for exactly this on 2026-09-06 evening), so the answer is OPEN and quantitative heatsink-temperature evidence stays BLOCKED until
the owner reports either the exact instrument or "none".**

## Push grant (same message) — ONE-TIME EXACT SCOPE, EXECUTED and CONSUMED 2026-09-06 night
Granted for exactly: workspace `program/offline-readiness-r3` at `86da42c` → workspace main; control-fw `offline/docfix-ci-count-and-wifi-topology`
at `631dee2` → control-fw main. Nothing else. Landing record: `W17_OFFLINE_READINESS.md` §1c (ws main 86da42c, then the record commit; cf main
631dee2, CI run 34054956474 green). *"This is NOT a general push grant. No new threshold/card/firmware/etc branch receives push authorization
from this grant."*

## Photo / label packet — the next major input (restated by the owner)
The ONE consolidated packet defined in `W17_OWNER_PHOTO_LABEL_INTAKE.md` (bench PSU · UBEC(s) · MH-ET board/regulator marking · blower ·
MG90S servos · speaker · Wi-Fi module/heatsink/clearance); do not ask for its seven items individually; the car stays fully unpowered and
battery disconnected. When provided: extract exact identities and observable configuration; use manufacturer sources for the actual
identifiable articles only; update durable component/state records; rerun the O-6 starting-current derivation (v3); Opus adversarial review;
fix demonstrated defects; fresh independent verify; return only genuinely unresolved numbers as the smallest specific owner questions.
No generic product-family assumptions. No search-snippet number may override a contradictory datasheet. Unreadable / no-brand / no-marking
is valid evidence and may leave the value BLOCKED.

## Model routing and review discipline (restated by the owner)
Every worker gets an explicit model. Fable = Director / major adjudication only · Opus = difficult electrical/safety reasoning,
implementation, adversarial review · Sonnet = normal workforce, bounded research, docs, scripts, ordinary verification.
Reviewer ≠ implementer ≠ fresh verifier for consequential work.

## Physical / procurement queue (restated by the owner; keep visible and durable)
5 GHz AP-capable USB Wi-Fi adapter (gift kit) · in-envelope 2S car battery · GCS-box USB 3.x hub · boot-mode selector · OP-49/IP2326 evidence
closure + charge-path parts · replacement Wi-Fi heatsink ≥ 32×32 mm (final size waiting on real clearance) · TX16S internal-RF check →
backup-handset decision · temperature-measurement capability check · coupon C-1 · Windows ARM VM (free disk → Fusion → ISO → bootstrap) ·
no-power measurement sitting.
