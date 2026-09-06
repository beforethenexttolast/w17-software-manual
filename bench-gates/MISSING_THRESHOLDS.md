# MISSING_THRESHOLDS.md — every number these cards need that no document supplies

**27 items, deduplicated across both bench-gate card sets** (`INDEX.md` / `BG-*` and
`G-INDEX.md` / `G-*`). This is the single list; the cards each carry their own
**THRESHOLD MISSING** notes, and `bench-gates/tools/first_power_current_limits.md` carries the car-side
current rows in full. Nothing is copied here that would go stale — every row points at its
source.

**Evidence label: BENCH-TBD or BLOCKED throughout.** Not one number below has been measured
or ruled. **No number is invented here.** Where a value is *derivable* from shipped
constants at a desk, it is marked **DERIVED** and is a bound on the answer, never the
answer.

**How the split works.** Section 1 is the seven the owner can close **today, with no
hardware and no gate** — they are rulings, not measurements, and closing them costs one
sitting. Section 2 is the twenty a bench measurement has to set first; the owner then
ratifies the measured value. The two sections are disjoint and together they are the whole
list.

**Deduplication note.** C1's list held 21 and C2's held 7, but C1 itself flagged that
`MT-19` (ESP32 #1 3.3 V draw with BT active) and `T10` are the same number. 21 − 1 + 7 =
**27**.

---

## 1. The owner can rule these today — no hardware, no gate (7) — **RULED 2026-09-05 (Decision Round 1, D-4; record: `2026-09-05_offline_decision_round_1.md`)**

| # | Ruling |
|---|---|
| O-1 | RETAINED: 150 ms desired / 200 ms maximum (G-02 criterion 6 now has a target) |
| O-2 | ACCEPTED: 1000 ms minimum headroom vs LINK_UP_WAIT_MS = 5000 (G-04 criterion 2) |
| O-3 | ACCEPTED: 2000 ms maximum spread across cold runs (G-04 criterion 3) |
| O-4 | ACCEPTED: five cold runs (G-04) |
| O-5 | RULED: STOP-button lag ≤ 250 ms; record the measured value AND PASS/FAIL (G-04 criterion 10) |
| O-6 | STAIRCASE POLICY RATIFIED; initial amperage NOT invented — derive the starting limit per powered substep from component/rail limits before first power; trip = STOP AND DIAGNOSE; raise only when understood and justified; never exceed rail/component limits; if not derivable offline → BLOCKED + smallest owner decision (BG-03 / tools/first_power_current_limits.md T11) |
| O-7 | RULED: initial maxBrightness cap = 180 (operating target); may be reduced at the halo gate; no raise above 180 without halo/current/rail evidence + new ruling; 227 stays the compile ceiling only (BG-08) |

The card criteria below still carry the pre-ruling proposals in places; applying the rulings into each card's PASS/FAIL text is the next autonomous action (then verify the changed portion before landing, per D-6).


Every one of these is a *decision*, not an observation. None of them is blocked by A2,
Phase B, FIRST_ACTIVE, or by anything being assembled.

| # | The question | Source of the gap | Card it blocks |
|---|---|---|---|
| **O-1** | Does the **150 / 200 ms** phone-video latency target still apply, now that OD-16 replaced the direct RTP path with a laptop-relayed WHEP pull? | `VR_FPV_IMPLEMENTATION_PLAN.md`:541 states the target against the *old* topology; nothing restates it for the new one | **G-02** (its criterion 6 is "if and only if a target is adopted") |
| **O-2** | Minimum acceptable **headroom** against `LINK_UP_WAIT_MS = 5000` | not recorded anywhere. G-04 criterion 2 **proposes 1000 ms** and labels it its own suggestion in three places | **G-04** |
| **O-3** | Acceptable **spread** across cold runs | not recorded anywhere. G-04 criterion 3 **proposes 2000 ms**, same footing | **G-04** |
| **O-4** | How many cold runs constitute a **characterisation** | not recorded anywhere. G-04 **chose five**, and says so | **G-04** |
| **O-5** | Acceptable **STOP-button lag** | `w17-ground-station/docs/setup_flow_bench_checklist.md`:239 says *"record any lag you still see"* and sets no number | **G-04** (criterion 10) |
| **O-6** | **Bench-PSU current-limit policy** (`T11`): *how* to choose the limit, given T1–T9 will not exist until the first power-on. A staircase policy — "start at X, raise only when a step trips for a reason you understand" — is a **ruling**, not a measurement, and it can be written before anything is powered | `bench-gates/tools/first_power_current_limits.md`:91 defers T11 to "derived from T1–T9 once they exist", which makes it unresolvable at the moment it is first needed | **BG-03** |
| **O-7** | **Maximum acceptable `maxBrightness`** | `learning-manual/open_questions.md` #55 leaves it open; the *acceptable* value is a look, not a number in any document | **BG-08** |

> **O-7 is bounded from above without a bench.** **DERIVED: `maxBrightness` ≤ 227.**
> `LightRenderer::LightConfig::valid()` requires
> `((2 · 20 · renderedDuty(255, cap)) / 255) · kNumPixels ≤ 900`
> (`w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11, :209, :226, :242,
> with `renderedDuty` at :110-111 over the γ = 2.2 LUT at :90-102). At cap **227** the model
> gives exactly **900 mA** — the last passing value; at **228** it gives **930 mA**,
> `valid()` returns false and **the build fails**. The owner's ruling therefore lives in
> **1 … 227**, and the real constraint (UBEC rail headroom) is lower still. Derivation and
> the full cap/draw table are on **BG-08**.

**[Historical — all seven were RULED 2026-09-05; see the ruling table at the top of §1.] Cheapest order for one owner sitting:** O-2, O-3, O-4 and O-5 were G-04's own proposals
awaiting ratification — accept or replace, four decisions. O-1 is a yes/no on whether an old
target survived a topology change. O-7 needs the 227 ceiling above plus a taste call. O-6 is
the only one that needs real thought, and it is the one that unblocks first power.

---

## 2. A bench measurement sets these; the owner then ratifies (20)

### 2a. Car-side current — 12 rows, all of `bench-gates/tools/first_power_current_limits.md` §T except T11

No per-load current figure for the car's rails exists anywhere: not in
`HARDWARE_INVENTORY.md`, not in `w17-control-fw/docs/bill_of_materials_v2.md`, not in
`00_BUILD_SHEET.md`, not in any workspace `*.md`. The only per-device 5 V figures in the
project are **ground-side** (`w17-gcs-box-guide.md`:135-139), and they are the template these
rows should follow: a cited figure, an `[A]`/`[I]` evidence tag, and a stated decision
threshold.

| # | Row | Card it blocks | Source |
|---|---|---|---|
| **T1** | Rail-A quiescent, boards idle, nothing else connected | BG-03 | `bench-gates/tools/first_power_current_limits.md`:81 |
| **T2** | Rail-A with the camera + Wi-Fi module streaming | BG-03 | `bench-gates/tools/first_power_current_limits.md`:82 |
| **T3** | Rail-B with the steering servo holding centre, unloaded | BG-03 | `bench-gates/tools/first_power_current_limits.md`:83 |
| **T4** | Rail-B peak during a full-lock steering sweep (the reason cap C1 exists) | BG-03 | `bench-gates/tools/first_power_current_limits.md`:84 |
| **T5** | Per-MG90S, idle and moving | BG-03 | `bench-gates/tools/first_power_current_limits.md`:85 |
| **T6** | Blower (always-on, rail B) | BG-03 | `bench-gates/tools/first_power_current_limits.md`:86 |
| **T7** | MAX98357A + speaker at the shipped `sound.volume` | BG-03 / BG-04 Phase 9 | `bench-gates/tools/first_power_current_limits.md`:87 |
| **T8** | RP1 receiver | BG-03 | `bench-gates/tools/first_power_current_limits.md`:88 |
| **T9** | ESP32 module, Wi-Fi off, both boards | BG-03 | `bench-gates/tools/first_power_current_limits.md`:89 |
| **T10** | ESP32 #1 with **Bluetooth active** (BT show-off build). **≡ MT-19** — one number, listed once | BG-07 (`BT1_BENCH_GATE.md`:66 lists it as an unmeasured bench item) | `bench-gates/tools/first_power_current_limits.md`:90 |
| **T12** | ESC standby (logic only) on batt+, motor leads off | BG-03 | `bench-gates/tools/first_power_current_limits.md`:92 |
| **T13** | Inrush allowance at pack connection — the XT90-S anti-spark exists *because* it is large, and no number is stated | BG-01 §S7 / BG-03 | `bench-gates/tools/first_power_current_limits.md`:93 |

Full row text and the derivation procedure: `bench-gates/tools/first_power_current_limits.md`:81-93.

### 2b. CRSF on the wire — 2

| # | The number | Source of the gap | Card |
|---|---|---|---|
| **MT-14** | Acceptable **CRC-failure rate** on a healthy bench link | no document in any repo states one; zero is what a short tap should produce, but no tolerance has ever been set | **BG-06** |
| **MT-15** | Expected **RC frame rate** at the chosen ELRS packet rate | the packet rate is a TX setting, and `D8_BENCH_BRINGUP.md`:67-70 asks you to *characterise* it, not to match a target | **BG-06** |

> **Both fall out of one 30 s BG-06 T1 capture**, which needs no A2 and no Phase B — but T1
> is **not** gate-free: it is a live-TX bench procedure under
> `w17-windows-vm-validation-runbook.md`:370-397 (car UNPOWERED or RP1 UNBOUND, no bound RX
> powered in range, attended, discharges nothing (RESIDUAL A); requires explicit owner
> authorization like every other gate). See BG-06 preconditions 0a–0e.

### 2c. BT1 show-off — 3

`BT1_BENCH_GATE.md`:54-68 asks each of these to be *observed and recorded*. No row states a
number.

| # | The number | Card | Source |
|---|---|---|---|
| **MT-16** | Free-heap watermark with BT active | **BG-07** | `BT1_BENCH_GATE.md`:57 |
| **MT-17** | Control-tick jitter with BT active | **BG-07** | `BT1_BENCH_GATE.md`:58 |
| **MT-18** | Real disconnect → outputs-safe latency | **BG-07** | `BT1_BENCH_GATE.md`:62 |

### 2d. Halo — 1

| # | The number | Source of the gap | Card |
|---|---|---|---|
| **MT-20** | What **"visible"** means: a lux level, a viewing distance, or a contrast ratio | `LightRenderer.hpp`:114-127 says `kMinVisibleDuty = 6` is *"a floor, not a look"* and that whether it reads in daylight is a bench judgement | **BG-08** |

This one is a judgement made **at** the bench, in both lighting conditions — it cannot be
ruled in advance and it cannot be measured by a script.

### 2e. Ground — 2

| # | The number | Source of the gap | Card |
|---|---|---|---|
| **C2-1** | Phone-vs-laptop glass-to-glass **delta** | `iPhone_rc/README.md`:480 and `iPhone_rc/FPVHUDApp/Video/README.md`:33 both say `[bench-TBD]`; every latency figure in the repos is a simulator or loopback figure | **G-02** |
| **C2-2** | Cold **`spawn → port OPEN`** latency on real Windows | `w17-ground-station/main/raceDayOrchestrator.js`:89-96 says `LINK_UP_WAIT_MS = 5000` is unvalidated — *"nothing in this chain has run on any machine"* | **G-04** |

---

## 3. What is **not** on this list

- Numbers the documents already fix. `LINK_UP_WAIT_MS = 5000`, `kBudgetMilliamps = 900`,
  `kMinVisibleDuty = 6`, the CRSF frame geometry, the Hall guard's 180/100 ms bound: these
  exist and are cited on the cards. A number being *unvalidated* is not the same as a number
  being *missing*, and only the missing ones are here.
- Anything a card **proposes**. G-04's 1000 ms / 2000 ms / five runs appear above as O-2,
  O-3 and O-4 — listed at the time as *questions awaiting a ruling*, not as thresholds (since RULED, §1 table). No card's suggestion is
  promoted to a standard by being listed here.
- Anything that would need the car assembled to even ask.

## 4. Evidence label

**BENCH-TBD** for §2, **BLOCKED on an owner ruling** for §1, **DERIVED** for the
`maxBrightness ≤ 227` ceiling only. Nothing on this page has been measured, ruled, or
executed. Recording a gap is not closing it.
