# Session prompt — W17 A2 staged build gates (the Phase-B gate)

Paste into a Claude Code session started at `~/Documents/projects`.

> **⚠ Rewritten 2026-08-03.** The previous version of this file walked A2 as a **single post-assembly
> pass** over §2–§10, to be run "only after the harness is assembled." That is no longer how A2 works.
> A2 was restructured on 2026-07-30 into **eight staged gates that ARE the build order** — they run
> *during* assembly, on isolated subassemblies, not once at the end. Several expected values are only
> valid while a subassembly is isolated, so running the old single-pass version against a finished
> harness would **false-FAIL a correctly-built car**. If you have the old prompt open somewhere,
> discard it.

---

I'm building the W17 harness and running the **A2 staged gates inline** as I go. Guide me gate by
gate; I solder and probe, you record. Nothing proceeds to the next gate until the current one passes.

**Golden rules:** battery stays disconnected and out of reach. **No USB, no bench PSU, nothing
flashed.** **Multimeter only** (continuity + resistance + diode mode). If any reading is suspicious →
**stop, photograph, report** — never "try again with power."

**Boot-mode selector note (SP3T, GPIO27/GPIO32) — check `OWNER-DECISION(SHIP-IMAGE)` first.** The
car carries one SP3T slide switch, common to GND, with two strap throws: center = **LAPTOP/DRIVE**
(both pins open on internal pull-ups), one throw = **GPIO27 (BT_SOLO)**, the other = **GPIO32
(SHOWCASE)** (`w17-control-fw/lib/config/include/config/PinMap.hpp`) — this is only read by the
`W17_BT_SHOWOFF` prototype build; delivery/tuning/sim builds never touch these two pins. **If this
car ships plain `esp32dev` (the default), the switch and its two strap wires carry no firmware
meaning at all and the SP3T rows below are not applicable** — note that explicitly rather than
leaving them blank. If it ships `esp32dev_btshowoff`, wire and verify the switch during this same
session (S4/S4b timing, alongside the other actuator/signal leads) — its own powered bench proof
is a separate gate, **BT1** (`w17-control-fw/docs/bt_showoff_design.md` §9), not this session.

## Boot-mode selector (SP3T) rows — only if this car's harness includes the switch

Run these at **S4** (build the three switch legs alongside the other signal leads) and **S4b**
(cross-signal isolation), the same two-pass discipline (continuity plug-seated, then isolation
ESP32-unseated) as every other row in this table. These rows are **not yet in the canonical A2
checklist** (`13_phase_a_a2_no_power_checklist.md` has no GPIO27/32 mention at all — its own open
items are F12, the MH-ET adjacency placeholder, and F20, the GPIO34↔35 isolation-matrix gap; the
SP3T gap is instead recorded at `2026-09-02_readiness_program.md:38-39` and in the
`PinMap.hpp`/`BootMode.hpp` headers cited above). A control-fw builder is adding these as rows S4c
in the canonical checklist now — record them here in the meantime, and drop this local copy once
they land there.

| # | Gate | Check | Expect |
|---|---|---|---|
| SW1 | S4 | SP3T common terminal → star GND | beep |
| SW2 | S4 | GPIO27 wire → SP3T's BT_SOLO throw contact | beep |
| SW3 | S4 | GPIO32 wire → SP3T's SHOWCASE throw contact | beep |
| SW4 | S4b | GPIO27 ↔ GPIO32 | no beep (not bridged to each other) |
| SW5 | S4b | GPIO27 / GPIO32 → each of 13/14/18/19/23/34/35/16/17/25 and → rail-A/rail-B wiring | no beep (same isolation-matrix scope as S1r/S2r/S5r — do not assume it's covered just because those rows exist). **GPIO26 is deliberately absent from this list:** S3 already requires no wire be present there at all (link2 RX, closed decision C4 — `Serial1.begin(..., rxPin=-1, ...)`), so there is no conductor at that end for a continuity check to run against. |
| SW6 | S4b | Switch physically centered (LAPTOP/DRIVE): GPIO27 → GND, and GPIO32 → GND | **no beep on either.** This is a property of the switch part itself, not of the ESP32: the center throw is mechanically open on both contacts, so nothing connects them to the common/GND pole regardless of what's on the other end of the wire. (This check runs with the ESP32 unseated per the two-pass discipline above — the "internal pull-ups" that later make an unconnected pin read HIGH only exist once the chip is seated, powered, and configured at boot; they play no part in why this beeper check reads clean.) A beep here means a throw contact is shorting through in the center position. |
| SW7 | S4b | Switch thrown to **BT_SOLO**: GPIO27 → GND, and GPIO32 → GND | GPIO27 **beeps**, GPIO32 does **not** — proves this throw grounds only its own pin |
| SW8 | S4b | Switch thrown to **SHOWCASE**: GPIO32 → GND, and GPIO27 → GND | GPIO32 **beeps**, GPIO27 does **not** — proves this throw grounds only its own pin |

SW7/SW8 exist because `BootMode.hpp:120-124`'s classification logic *assumes* both-pins-grounded
is "electrically impossible from the part" and never defends against it in firmware (a corrupted
read still resolves to Drive, but a genuinely both-grounded harness fault would not be a corrupted
read — it would be the actual electrical state). SW1–SW3 only prove the wires reach the right
contacts; SW7/SW8 are what actually proves each throw of the physical part grounds exactly one pin
at a time, the assumption the firmware's fail-toward-drive logic is built on.

Read + follow: `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` (canonical),
cross-referenced with `w17-pdb-build-and-connector-guide.md` and
`w17-control-fw/lib/config/include/config/PinMap.hpp`. Read §3 (measurement conventions) once, aloud
to me, before I pick up a probe.

## The eight gates, in build order

| Gate | What | Note |
|---|---|---|
| **S1** | Battery divider, **isolated** — before the UBECs exist on the batt+ node | `batt+ → GND ≈ 37 kΩ` is **only** valid here. After S6 it reads in parallel with two UBEC input stages. |
| **S2** | Hall sensor, isolated | pull-up to **3V3**, not 5 V |
| **S3** | link2 pair (board #1 ↔ board #2) | RX (GPIO26) = **verify no wire present** — the firmware hard-disables it (`Serial1.begin(..., rxPin=-1, txPin_)`) |
| **S4** | CRSF pair and each 3-pin actuator lead, **individually** | if this car's harness includes the SP3T boot-mode selector, wire its three legs here too — SW1–SW3 above |
| **S4b** | Cross-signal isolation — all five actuator leads present, UBECs still off | if wiring the SP3T, run SW4–SW8 above in the same pass |
| **S5** | WS2812 path (board #2) | supply = **option A, the 1N5819 diode** (on hand; no 74AHCT125 in inventory or BOM v2 — it stays the documented fallback, at a recorded ~10 mV nominal V<sub>IH</sub> margin) |
| **S6** | Attach the UBECs | **after this point, S1's isolated values no longer apply** |
| **S7** | Common ground, whole harness | true whole-harness gate |
| **S8** | ESC BEC red-wire isolation | **hard gate** — nothing proceeds past a failure here |

§2 visual inspection runs **per-gate**, plus once at the end.

## ⚠ Before you start — check S7's reference actually exists

S7 probes from **battery −**, which assumes an XT60-terminated pack. Per `HARDWARE_INVENTORY.md`:
**no in-envelope pack is on hand** (the 1500 mAh pack recorded as arrived on 07-29 never existed —
corrected 07-31), and the only battery present is the out-of-envelope **5200**, classed bench-only.
The master switch arrived 2026-07-30 as a two-piece pigtail set (XT90-S female → XT60 male, plus
XT90H-M male with a bare tail); mated, the pair *is* the pull-apart master.

**First thing this session: tell me whether S7's reference is available.** If it isn't, we run S1–S6
and S8, and mark S7 explicitly BLOCKED rather than improvising a substitute reference.

## Recording

Fill the §11 measurement table with **real readings** + PASS/FAIL, note any PASS-with-note deviations,
and capture the exact reading + photo for anything hitting a §13 hard stop. Take the §10 photo set —
these are **reviewed**, not filed: the reviewer must be able to *see* the ESC red-wire cut and the
single star ground in them.

## Closure is a two-part gate (§12) — and neither part is "the hardware is safe"

- **Part 1 — reviewer check:** completeness, gate attribution, tolerance, cross-reference, **plus
  mandatory direct inspection of the §10 photos** (the one part that is independent observation rather
  than trust in transcription).
- **Part 2 — owner attestation** that the measurements were physically performed.

**A2 closed means the record is complete, coherent, and photo-corroborated — NOT that the hardware is
safe.** Opening Phase B is my call, informed by A2, not a reviewer verdict.

Paste the filled table back for review. Update `CURRENT_STATUS.md`. Show diffs before committing;
branch off main. **Still NO POWER** — A2 is entirely a multimeter exercise; powering is Phase B, which
comes only after A2 is filled, reviewed, and approved.

See `w17-parts-to-gift-master-sequence.md` (stage 3–5) for how this session's output (A2-CLOSED)
feeds into the Phase-B-open decision and the rest of the parts-to-gift order.
