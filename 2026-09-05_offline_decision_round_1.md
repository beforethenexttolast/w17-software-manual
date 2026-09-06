# W17 OFFLINE READINESS — Decision Round 1, owner rulings (2026-09-05, recorded 2026-09-06)

Verbatim owner rulings. Authority: workspace `CLAUDE.md` safety boundaries 1–7 > readiness packet A1–A12 > **this file** > `W17_OFFLINE_READINESS.md`.
No powered/gated test is authorized by these rulings.

## D-1 Hotspot / adapter
Use BOTH: (1) validate before handover on a real x64 Windows 11 PC when available; (2) repeat the relevant acceptance check on the actual giftee PC at
handover. The 5 GHz AP-capable USB Wi-Fi adapter is part of the GIFT KIT / production GCS setup, not merely validation equipment. One adapter; no ARM-VM duplicate.

## D-2 OP-49
Adopt the two on-hand IP2326 boards as the selected charge-module candidate. This does NOT waive remaining OP-49 evidence/safety requirements. Complete the
remaining identification / envelope / interface / interlock / isolation / thermal / fault / charge-safety work before any powered charge test. Keep the no-power
visual board-marking inspection.

## D-3 CRSF tap (BG-06 T1)
Ratified as a LIVE-TX GATED BENCH PROCEDURE: car unpowered OR RP1 unbound; no bound receiver powered in range; attended; explicit owner go before execution.
It discharges no A2 / Phase B / FIRST_ACTIVE gate.

## D-4 Thresholds (bench-gates/MISSING_THRESHOLDS.md §1)
- O-1: retain phone-video target = 150 ms desired / 200 ms maximum.
- O-2: accept 1000 ms minimum link-up headroom against LINK_UP_WAIT_MS = 5000.
- O-3: accept 2000 ms maximum spread across cold runs.
- O-4: accept five cold runs.
- O-5: maximum acceptable STOP-button lag = 250 ms. Record actual measured values as well as PASS/FAIL.
- O-6: ratify the current-limit STAIRCASE POLICY, but do NOT invent an unsupported initial amperage. Before first power, derive/document the starting current
  limit from the exact powered substep and applicable component/rail limits. Policy: lowest defensible limit for that substep; current-limit trip = STOP AND
  DIAGNOSE; never simply increase until it works; increase only after the trip is understood and the next setting is justified; never exceed applicable
  rail/component safety limits. If no exact initial value can be defensibly derived offline, keep it BLOCKED and bring the owner the smallest specific decision required.
- O-7: initial owner maxBrightness cap = 180. May be reduced at the visibility bench gate. Do not raise above 180 without halo/current/rail evidence and a new owner
  ruling. 227 remains only the compile ceiling, not an operating target.

## D-5 Booklet voice (applied in commit f03066f)
Section 4 phone-app paragraph: Alternative B. Section 6 DRS-green line: Alternative B. Section 9 controller reconnect: Alternative B. Section 1 replacement-device
line: Alternative A ("ping Vitaliy — happy to help"). Section 3 wake-up/breathe line: leave current verified wording as-is. Voice rulings; verified technical facts remain authoritative.

## D-6 Merge/push grant — ONE-TIME, EXACT SCOPE
GRANTED for the already reviewed → fixed → independently re-verified branches enumerated in `W17_OWNER_ACTIONS.md` D-6 (listed again in `NEW_SESSION_HANDOFF.md` §2).
Use each repo's guarded merge/push rules and observe CI. NOT a general push grant. If approved branch content changes materially before landing, independently verify
the changed portion before push. Additional/new branches require a fresh grant, except mechanically necessary merge resolution whose resulting tree is independently verified.

## Must not be lost from the physical/procurement queue
5 GHz AP-capable USB Wi-Fi adapter · in-envelope 2S car battery · GCS-box USB 3.x hub · boot-mode selector · OP-49/IP2326 closure + charge-path parts ·
TX16S internal-RF check → backup-handset decision · coupon C-1 · Windows ARM VM · no-power measurement sitting.
