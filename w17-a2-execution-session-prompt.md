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
| **S4** | CRSF pair and each 3-pin actuator lead, **individually** | |
| **S4b** | Cross-signal isolation — all five actuator leads present, UBECs still off | |
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
