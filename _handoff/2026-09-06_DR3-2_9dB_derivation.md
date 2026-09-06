# DR3-2 — MAX98357A at the confirmed 9 dB GAIN: desk derivation, **v2**

> **Snapshot note (added on persisting, 2026-09-06 night).** **Non-canonical dated snapshot**, per the `_handoff/`
> convention (`_handoff/README.md`:8-10). This is the DR3-2 desk derivation of record, **v2**, kept **byte-identical**
> to the worker's file below this note and **never updated**. **v1 is SUPERSEDED and must not be cited**; §0 maps every
> finding of the adversarial review `R-DR3-2` (persisted alongside as `_handoff/2026-09-06_R-DR3-2_review.md`) to what
> changed. **Canonical source:** the live version of everything this file proposes is the **cards**, not this file —
> `bench-gates/BG-03_phase_b_first_power.md` (S4 row, Q6), `bench-gates/tools/first_power_current_limits.md`
> (L13 / T7 / T11), `bench-gates/BG-04_d8_bench_bringup.md`, `bench-gates/MISSING_THRESHOLDS.md` and
> `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` (item 11). **If this file and a card disagree, the card wins.** Path tokens
> of the form `…/scratchpad/…` are session-scratch locations, not repo paths, and do not resolve in any checkout.
> Repo line numbers were correct at the r4 tip that carried this application.

**Worker:** FIX-DR3 · **Model: Opus (claude-opus-5[1m])** · 2026-09-06 night.
I did **not** write v1 and did **not** review it; I am the fixer, per the owner's reviewer ≠ implementer ≠ verifier rule.
**Scope:** READ-ONLY on every nested repository; workspace edits confined to the r4 worktree. Nothing powered, flashed,
measured, transmitted or soldered, and **nothing in this document authorises any of those.**
**Governing rulings:** DR3-2 (9 dB is the intended shipped configuration; verify the board before soldering) ·
DR2-2 **M-PEAK** (manufacturer MAXIMUM/PEAK only, 0 % invented margin, a typ never substitutes for a peak) ·
DR2-8 (speaker impedance **BLOCKED** on photo/label packet item 6) · DR2-13 (the Rail-A sizing sum is owner-facing state).

> **v1 of this derivation is SUPERSEDED and must not be cited.** The adversarial review `R-DR3-2` returned
> **FIX_REQUIRED — 7 BLOCKING, 10 NON-BLOCKING**, and the quantitative core of v1 was broken **in the unsafe
> direction**. §0 maps every finding to what changed. The review is persisted verbatim alongside this file as
> `_handoff/2026-09-06_R-DR3-2_review.md`.

---

## §0 Changes from v1 (review `R-DR3-2`)

| # | Class | v1 said | v2 does |
|---|---|---|---|
| **B1** | BLOCKING | Every §6 anchor quoted "verbatim from the current cell" — but from the pre-DR3-apply tree | §6 is rewritten **as applied**: each block quotes the anchor **exactly as it stood on `program/offline-readiness-r4` at `24e0d08`**, gives the landed replacement, and names what is **retained**. §6.3 now quotes the S4 `P(N)` cell in full (v1 never did) and states that the DR3-2 confirmation, the AliExpress / "do not assume the Adafruit pinout" warning, the "Phase 9 has not run" note and the speaker "bench spec-check" cite are all **kept**, not dropped |
| **B2** | BLOCKING | Per-state figures labelled "≥ … mA" (26 / 43 / 156 / 346 / 540 / 620), every input chosen at the **upper** edge, ~7.4× too high, and written onto cards | **Every "≥ … mA" per-state figure is withdrawn from every card and from this report's conclusions.** §3.1 recomputes them from the firmware constants with the **gain MIN 8.4 dB**, the **actual profile peak**, and the **harmonic-sum RMS** (re-derived here independently — the review's 7 784 and crest ≥ 3.16 are confirmed, and a crackle-burst case the review did not carry is added). The recomputed figures are labelled **conditional estimates — not a bound, not a criterion, not M-PEAK-clean** and **do not appear on any card** |
| **B3** | BLOCKING | §6.3 proposed a "sanity-check band" with "a reading below the band means the amp was not rendering" | **Withdrawn entirely.** No band, and **no "below the band means …" sentence exists anywhere** — not in this report and not on any card. S4 instead carries: *there is no derivable expected value for this reading; no reading at this substep is a PASS, and a low reading is not by itself evidence that the amp was silent* |
| **B4** | BLOCKING | §2.4's "self-consistency check": 3.2 W / 3.125 W = 1.024× = "+0.10 dB — exactly what a 10 %-THD clipped waveform adds" | **Arithmetically wrong by an order of magnitude, confirmed by my own re-derivation.** A 10 %-THD symmetrically clipped sine adds **+1.098 dB (×1.288)**; 1 % adds **+0.202 dB (×1.048)**. §2.4 is replaced: the datasheet's four `POUT` rows, de-clipped, agree on ≈ **0.46–0.49 Ω** of series resistance and imply a real clean-sine ceiling of ≈ **2.49 W into 4 Ω**. Consequence: the part is **supply-limited at all three gain band edges**, not two of three. §2.4's invalid check is replaced by the valid one the review found (N7). **These figures stay in this report only** — the cards carry the **qualitative** conclusion |
| **B5** | BLOCKING | "Swap the amp term in T11's sizing sum from 640 mA to 1600 mA" | **Withdrawn, and the cite was wrong.** T11 (`first_power_current_limits.md`:106) carries the 640 mA term but **contains no sizing sum**. The sums live in **`W17_OWNER_ACTIONS.md`** (DR2-13) and **`CURRENT_STATUS.md`**. §4.2/§6.5 now flag, not propose: the sums keep **2628 / 3000 mA**, the amp term is **relabelled**, and **±1.6 A is not substituted** — it is a stress rating the part cannot draw into a 4 Ω or 8 Ω speaker at 5 V, and substituting it would invent a ~0.8 A design load |
| **B6** | BLOCKING | ±1.6 A put in L13's **Value** column and called "the amplifier branch's never-exceed" without the sentence that stops it being dialled in | Wherever ±1.6 A appears it now carries, verbatim: **a damage threshold under the datasheet's AMR caveat — NOT an allowance, NOT a PSU setting, NOT a prediction of draw; nothing may be set or permitted up to it**; never a `P(N)`, `Σ P(k)` or sizing-sum term; never dialled into the bench PSU (T11's policy is the lowest defensible limit per substep). It sits in **BG-03 S4's never-exceed column**; L13 names it explicitly as **not** one of that column's added-load allowances |
| **B7** | BLOCKING | "the only three [maxima] the part publishes" | **Struck — it is false.** §2.5 lists the further guaranteed maxima and adds the two that are currents: **`ISTNDBY` 400 µA max** (`SD_MODE` high, **no BCLK**, `TA = +25 °C`) and **`ISHDN` 2 µA max**. `ISTNDBY` is now on L13, T7, T11 and BG-03 S4 as the M-PEAK-clean maximum **for the un-clocked state only** |
| **N1** | non-blk | "into 4 Ω at ≤ 5.5 V the output current **cannot** exceed 1.375 A" | Softened to indicative, with the impedance-minimum caveat (DR2-8, packet item 6). The conclusion — ILIM is short/fault protection, not a normal-operation bound — survives and is what the cards carry; **no "cannot exceed 1.375 A" claim is on any card** |
| **N2** | non-blk | "Nothing in the shipped configuration clips" | Removed from the report body and replaced by the computed statement in §3.1a: at `sound.volume` 100 the **loudest transient** (the V6 overrun crackle burst) rides into the clipping region at gain typ and above; the steady voices do not. Not on any card |
| **N3** | non-blk | Diode-mode step unqualified | Kept, but **OPTIONAL**, restricted to a current-limited (≈ 1 mA) diode source, and carrying the AMR caveat and the bulk-capacitance note. Applied to procurement item 11 |
| **N4** | non-blk | Step 6's 15 dB / 3 dB discriminators dropped "clearly lower than the other side" | Restored, on the card, with the reason (the internal bias also reads in the 10⁵ Ω decade) |
| **N5** | non-blk | §6.2 was a partial replacement that duplicated the tail it did not mention | §6.2 now names the retained tail (*"Record with the measurement:"* onward, including the R-ADD N9 volume-100 gating) and adds no duplicate engine-state sentence |
| **N6** | non-blk | Revision-history cite `:2524-2534` | `:2524-2540` — the "Rev 7, 2/16" row is at `:2540`. Re-opened and confirmed |
| **N7** | non-blk | §2.2's A3 called "physics, not a datasheet number" | The datasheet proves it: the Dynamic Range row (`:257-258`) specifies `VRMS = 2.54 V` and the EC table's default condition is **`GAIN_SLOT = VDD`** = 6 dB (`:195`); 2.1 dBV + 6 dB = 8.1 dBV = **2.5409 V RMS**. Exact. This replaces §2.4's invalid check, and §2.2 now notes that most EC rows are at 6 dB, not 12 dB |
| **N8** | non-blk | §8 item 8: "crest factor NOT DERIVABLE" | **Wrong, and it is the refusal that let B2 stand.** The RMS of a sum of sines at distinct harmonics is `sqrt(Σaᵢ²/2)`, phase-independent, and every amplitude is a compile-time constant. §3.1 derives it; §8 item 8 is withdrawn and replaced by the derivation |
| **N9** | non-blk | "±0.6 dB = ±7.4 % in voltage, ±14.9 % in power" | Corrected and made asymmetric: **+7.15 % / −6.67 %** in voltage, **+14.8 % / −12.9 %** in power |
| **N10** | non-blk | Verification notes | All re-opened by me independently; every line cite in §7 was checked against the extract in this pass. The peak sums, composed bytes and truncating integer arithmetic reproduce exactly |

**Findings I did not accept as stated:** none of R-DR3-2's. Every BLOCKING and NON-BLOCKING finding above is applied.

---

## §0a VERDICT (one paragraph)

The datasheet's gain table **agrees exactly** with `PinMap.hpp` (`GAIN_SLOT` unconnected = 9 dB, GND = 12 dB, VDD = 6 dB)
— **DERIVED**, Table 8 (`:2054-2068`) and the Electrical Characteristics gain rows (`:260-267`), and **9 dB is a *typ*
whose guaranteed band is 8.4 … 9.6 dB**. The headline result is counter-intuitive and safety-relevant, and the review
made it **stronger**: **moving from 12 dB to 9 dB does not reduce the amplifier's worst-case output at all.** Once the
series resistance the datasheet's own `POUT` rows imply is accounted for, the achievable clean-sine swing into 4 Ω is
≈ **3.15 V RMS**, which is **below** the full-scale output at **every** one of the three guaranteed gain band edges
(8.4 / 9 / 9.6 dB) — so the output is **SUPPLY-LIMITED at all three**, exactly as it is at 12 dB. What 9 dB changes is
only the digital level needed to reach that ceiling. **No upper bound on supply current is derivable at any gain —
CONFIRMED**: it needs a **minimum** efficiency and the datasheet publishes only a **typ** (92 %, 8 Ω, 1 W, 12 dB).
**Three M-PEAK relabels the cards needed:** 3.2 W is a **typ/guidance** value, so the `≥ 640 mA` resting on it is
reference-only and not M-PEAK-clean; **ILIM 2.8 A is a *typ*** and is an **output** limit; **IDD 3.35 mA max holds at
`TA = +25 °C` only**. **One genuinely new M-PEAK-clean maximum:** **`ISTNDBY` 400 µA max** (`SD_MODE` high, no BCLK,
`TA = +25 °C`) — the manufacturer maximum for the un-clocked state, and the only one of its kind that applies at S4.
The datasheet's **±1.6 A** absolute maximum is recorded as a **never-exceed damage threshold only** — not an allowance,
not a setting, not a prediction, and explicitly **not** a substitute in the Rail-A sizing sum. Speaker impedance stays
**BLOCKED** (packet item 6). **BG-03 S4's `P(4)` stays BLOCKED**, on two named data. **The per-engine-state current
figures this derivation computes are estimates and appear on no card.**

---

## §1 Does the datasheet's gain table agree with `PinMap.hpp`? — **DERIVED: YES, exactly.**

### 1.1 The datasheet, quoted

**Table 8. Gain Selection** (extract `max98357a.txt`:2054–2068):

| GAIN_SLOT | I²S/LJ GAIN (dB) |
|---|---|
| Connect to GND through 100 kΩ ±5 % resistor | 15 |
| Connect to GND | 12 |
| **Unconnected** | **9** |
| Connect to VDD | 6 |
| Connect to VDD through 100 kΩ ±5 % resistor | 3 |

**Electrical Characteristics**, *"Gain (Relative to a 2.1dBV Reference Level)"*, A_V, dB (`:260–267`) — the row with
guaranteed limits:

| Condition | MIN | TYP | MAX |
|---|---|---|---|
| `GAIN_SLOT = GND through 100kΩ` | 14.4 | 15 | 15.6 |
| `GAIN_SLOT = GND` | 11.4 | **12** | 12.6 |
| **`GAIN_SLOT = unconnected`** | **8.4** | **9** | **9.6** |
| `GAIN_SLOT = VDD` | 5.4 | **6** | 6.6 |
| `GAIN_SLOT = VDD through 100kΩ` | 2.4 | 3 | 3.6 |

Corroborated by the front-page feature line (`:11-13`). `PinMap.hpp`:20–24 says *"MAX98357A straps (documented, not
driven): GAIN floating = 9dB (start there; GND = 12dB, VDD = 6dB)."* **All three legs match the manufacturer table.
VERDICT: DERIVED — agreement; no defect in `PinMap.hpp`.**

**Two things `PinMap.hpp` does not say, and the cards now do:**
1. **9 dB is a *typ*.** The guaranteed band is **8.4 … 9.6 dB**. That ±0.6 dB is **+7.15 % / −6.67 %** in voltage and
   **+14.8 % / −12.9 %** in power — asymmetric (corrected from v1's "±7.4 % / ±14.9 %", R-DR3-2 N9). Under M-PEAK,
   a figure used as a **worst case in the high direction** takes **9.6 dB**; a figure used as a **floor** takes
   **8.4 dB**. v1 applied "use the max" to a floor, which is the wrong band edge for that direction — see §3.1.
2. **"Floating" is not a wiring instruction the *header* can satisfy.** See 1.2.

### 1.2 Why "floating at the header" ≠ "unconnected at the pin"

`GAIN_SLOT` is read by a **five-window comparator against fractions of VDD** (`:366–386`), not as a logic input:

| Setting | V_GAIN_SLOT window |
|---|---|
| A_V = 12 dB | 0 … 0.1 × VDD |
| A_V = 15 dB | 0.15 × VDD … 0.35 × VDD |
| **A_V = 9 dB** | **0.4 × VDD … 0.6 × VDD** |
| A_V = 3 dB | 0.65 × VDD … 0.85 × VDD |
| A_V = 6 dB | 0.9 × VDD … VDD |

9 dB is obtained by the pin sitting at **mid-rail**, so the IC biases the pin itself, and the 15 dB / 3 dB settings are
produced by a **100 kΩ resistor shifting that internal bias**. Consequences:

- **Any external resistor on the GAIN net changes the setting.** 100 kΩ to GND ⇒ **15 dB** — 6 dB hot, **4× the output
  power** at the same digital level. A hard short to GND ⇒ 12 dB; to VDD ⇒ 6 dB.
- **[INFERRED, not a datasheet value]** For 100 kΩ to land the pin at ~0.25 × VDD, the internal bias network must be
  ≈ **200 kΩ to VDD + 200 kΩ to GND**. The datasheet publishes **no** `GAIN_SLOT` bias resistance (`R_PD = 100 kΩ` is
  for `SD_MODE` only, `:365`). Indicative only; the check does not rely on it — but it is exactly why a 9 dB board and
  a 15 dB board both read in the **10⁵ Ω decade** and are separated by the **asymmetry between the two rails**, which
  is why the card's discriminators say *"and clearly lower than the reading to the other rail"* (R-DR3-2 N4).

### 1.3 The fitted article is NOT the Adafruit breakout

The fitted part is a generic AliExpress listing, *"MAX98357A I2S amplifier `1PCS`"* (`HARDWARE_INVENTORY.md`:97;
`w17-control-fw/docs/bill_of_materials_v2.md`:69-70 — the marketplace URL is on `:70`, R-DR3 N8). **No schematic, no
datasheet and no silkscreen legend for this board exists in any project document.** `PinMap.hpp`:16's *"the canonical
Adafruit hookup"* is a statement about the **I²S wiring** and is **not** evidence about this board's GAIN net.
`GAIN_SLOT` is **WLP ball B2 / TQFN pin 2** (`:1513–1517`).

**The pre-solder check lives on the card, not here:** `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`, "Physical actions that
need no purchase", **item 11**. It is a **resistance** measurement (ohms, unpowered, out of circuit, **both
polarities**, GAIN↔GND and GAIN↔VDD) because a continuity beeper closes below ~50 Ω and reads a 100 kΩ resistor as
**open** — it cannot tell **unconnected (9 dB)** from **100 kΩ to GND (15 dB)**, which is the exact confusion DR3-2
exists to prevent (R-DR3 B3). Diode mode is **optional**, needs a current-limited (≈ 1 mA) source, and carries the AMR
caveat (R-DR3-2 N3): with the board unpowered it momentarily places the pin outside *"All Other Pins to GND …
-0.3V to (VDD + 0.3V)"* (`:170`) though well inside *"Continuous Input Current (all other pins) … ±20mA"* (`:172`).
**Outcome rule on the card:** any resistor, jumper, bridge or trace on the GAIN net other than an open header pad ⇒
the board does **not** ship at 9 dB as fitted ⇒ **do not solder**; record the value and the rail; the shipped 9 dB then
needs the net brought to *"unconnected at the pin"* or an owner decision, returned as one smallest specific question.

---

## §2 Full-scale output at 9 dB into 4 Ω and 8 Ω at VDD = 5 V — **DERIVED, and SUPPLY-LIMITED at every gain band edge**

### 2.1 The datasheet's own gain definition

`:2029–2038`, verbatim:

> *"Gain is referenced to the full-scale output of the DAC, which is 2.1dBV (Table 8). … **Assuming that the desired
> output swing is not limited by the supply voltage rail**, the IC's output level can be calculated based on the digital
> input signal level and selected amplifier gain according to the following equation: Output signal level (dBV) = input
> signal level (dBFS) + 2.1dB + selected amplifier gain (dB), where 0dBFS is referenced to 0dBV."*

The datasheet flags the rail caveat itself. That caveat is the whole answer.

### 2.2 The equation is confirmed by the datasheet, and the EC default gain is 6 dB — not 12 dB

v1 called the bridge-tied/differential referencing *"physics, not a datasheet number"*. It is in fact **verifiable
against the datasheet directly** (R-DR3-2 N7): the Electrical Characteristics table's default condition is
**`GAIN_SLOT = VDD`**, i.e. **6 dB** (`:195`) — the 12 dB conditions are called out per row — and the Dynamic Range row
specifies `VRMS = 2.54 V` (`:257-258`). The equation gives 2.1 dBV + 6 dB = 8.1 dBV = **2.5409 V RMS**. **Exact.**
This is the self-consistency check §2.4 should have run; v1 ran an invalid one instead (B4).

### 2.3 Ideal-rail arithmetic

**Assumptions, stated:** VDD = **5.000 V** (Rail-A nominal; rated 2.5–5.5 V, `:198`). dBFS is referenced to a
**full-scale sine**; dBV is RMS. The bridge-tied output cannot swing beyond the rails (confirmed in 2.2). Load taken
purely resistive; the datasheet's test load is R + L (`:388-389`), and ignoring the reactance **overstates** power,
which is conservative for a ceiling.

DAC full scale: 2.1 dBV → **1.2735 V RMS**.

| Gain leg | A_V | Full-scale sine (V RMS) | vs ideal rail 3.5355 V | vs the **achievable** ≈ 3.153 V (see 2.4) |
|---|---|---|---|---|
| **MIN** (guaranteed) | 8.4 dB | 3.3497 | 0.47 dB under | **+0.55 dB over ⇒ supply-limited** |
| **TYP** | 9 dB | 3.5892 | 0.13 dB over | **+1.11 dB over ⇒ supply-limited** |
| **MAX** (guaranteed) | 9.6 dB | 3.8459 | 0.73 dB over | **+1.73 dB over ⇒ supply-limited** |
| (reference) 12 dB TYP | 12 dB | 5.0699 | 3.13 dB over | +4.13 dB over ⇒ supply-limited |

**Ideal-rail clean-sine ceiling at 5.0 V:** 3.5355 V RMS → **3.125 W into 4 Ω / 1.5625 W into 8 Ω**. **This is an
ideal-rail figure and ~25 % above what the datasheet's own `POUT` rows imply is achievable (§2.4)** — conservative as a
ceiling, and it must **not** be read as an achievable output. **It is a report figure and is on no card.**

**Answer to the question as asked: at 8.4, 9 and 9.6 dB alike the full-scale output is SUPPLY-limited, not
gain-limited.** v1 said only two of three edges were; the review's de-clipping analysis shows all three are, which
**strengthens** the conclusion. **Dropping 12 dB → 9 dB does NOT reduce the amplifier's worst-case output at
VDD = 5 V.** Anyone reasoning "3 dB less gain, so half the current" would be wrong, and wrong in the unsafe direction.

### 2.4 What the datasheet's own `POUT` rows actually say — v1's check was wrong by an order of magnitude

v1 claimed 3.2 W / 3.125 W = 1.024× = +0.10 dB was *"exactly what a 10 %-THD clipped waveform adds"*. **It is not.**
I solved the symmetrically-hard-clipped sine numerically myself (clip ratio `m`, `φ = arcsin m`; mean square
`(2/π)[A²(φ/2 − sin2φ/4) + L²(π/2 − φ)]`; fundamental `b₁ = (2A/π)[φ + m√(1−m²)]`; THD from the two):

| THD | clip ratio m | P / P(max clean sine at the same peak) |
|---|---|---|
| 1 % | 0.9715 | **1.0475× (+0.202 dB)** |
| 10 % | 0.7787 | **1.2878× (+1.098 dB)** |

Inverting that factor on all four published `POUT` rows (`:234-247`, all at gain 12 dB, VDD 5 V) recovers the real
output swing, and it is strikingly self-consistent:

| Row | Published | Clean-sine equivalent | V RMS | V peak | implied series resistance |
|---|---|---|---|---|---|
| 4 Ω, 10 % THD | 3.2 W | 2.485 W | 3.153 | 4.459 | 0.486 Ω |
| 4 Ω, 1 % THD | 2.5 W | 2.387 W | 3.090 | 4.370 | 0.577 Ω |
| 8 Ω, 10 % THD | 1.8 W | 1.398 W | 3.344 | 4.729 | 0.458 Ω |
| 8 Ω, 1 % THD | 1.4 W | 1.337 W | 3.270 | 4.624 | 0.650 Ω |

The two 10 %-THD rows — the ones actually at clipping onset — agree on ≈ **0.46–0.49 Ω**, i.e. ≈ **0.47 Ω** of total
series resistance (H-bridge `RDS(on)`, for which the datasheet publishes **no numeric spec**, only the qualitative
mention at `:2003`, plus the test inductor's DCR).

**Consequences, and the boundary of what may leave this report:**
1. The **real clean-sine ceiling into 4 Ω is ≈ 2.49 W (3.153 V RMS)**, not 3.125 W; into 8 Ω ≈ 1.40 W.
2. **Supply-limited at all three gain band edges** (§2.3), not two of three.
3. v1's margins ("0.13 dB over", "0.73 dB over", "0.47 dB under") are all wrong; the real margins over the achievable
   swing are ≈ **+1.11 / +1.73 / +0.55 dB**.

**These are typ-derived figures.** Every one of them descends from the `POUT` rows, which the datasheet's own closing
statement puts in the **guidance** class, not the guaranteed class (`:2542-2543`). **They therefore stay in this report
and go on no card.** The conclusion the cards carry is the **qualitative** one, and only that one:

> **At 9 dB the full-scale output remains SUPPLY-LIMITED at every gain band edge, so 9 dB does not reduce the
> amplifier's worst case versus 12 dB (DERIVED).**

### 2.5 What is NOT derivable here, and the M-PEAK labelling

**NOT DERIVABLE — a published output-power figure at 9 dB.** Every `POUT` row is at **12 dB** (`:234-247`). Everything
in §2 comes from the gain equation plus the rail. *Missing datum: an Electrical Characteristics `POUT` row at
`GAIN_SLOT = unconnected`.* It does not exist in Rev 7.

**M-PEAK re-labels.** The datasheet's closing statement (`:2542-2543`): *"The parametric values (min and max limits)
shown in the Electrical Characteristics table are guaranteed. Other parametric values quoted in this data sheet are
provided for guidance."* So:
- **3.2 W is neither a MIN nor a MAX — it is guidance.** The `≥ 640 mA` resting on it is **REFERENCE ONLY** and **not
  M-PEAK-clean**, and must not be a rail-sizing term.
- **ILIM 2.8 A is explicitly a *typ*** (*"2.8A typ"*, `:2021`; EC row `:268`) and is an **output** limit.
- **Efficiency 92 % is a typ** (`:269-271`).

**The guaranteed maxima the part actually publishes.** v1 said *"the only three"*; that is **false** (B7). The
Electrical Characteristics table publishes several, including four that matter here:

| Guaranteed maximum | Value | Condition | Line |
|---|---|---|---|
| **IDD** | **3.35 mA max** | `TA = +25 °C` **only** — no max over the operating range | `:200` |
| **ISTNDBY** | **400 µA max** | `SD_MODE = 1.8 V`, **no BCLK**, `TA = +25 °C` | **`:205`** |
| **ISHDN** | **2 µA max** | `SD_MODE = 0 V`, `TA = +25 °C` | `:204` |
| **A_V** | **9.6 dB max** (8.4 dB min) | `GAIN_SLOT = unconnected` | `:260-267` |

Also guaranteed maxima, not currents: UVLO 2.3 V (`:199`), VOS ±2.5 mV (`:207`), THD+N 0.06 % (`:249`), frequency
response +0.2 dB (`:273`).

**`ISTNDBY` 400 µA max is the one that earns a card.** At S4 the amplifier is added to the rail; one of the two
plausible states at that moment is **powered with the I²S clocks not running**, and for exactly that condition the
manufacturer publishes a guaranteed maximum. It bounds **that state only** — it is not a bound on the driven amp,
which stays BLOCKED. (v1 reached past it for a 1.6 A stress rating.)

Separately, the abs-max **continuous power dissipation** is package-dependent — WLP **1096 mW**, TQFN **1666 mW** at
`TA = +70 °C`, derating 13.7 / 20.8 mW/°C (`:175-177`) — and **which package the fitted board carries is unrecorded**,
so that route is BLOCKED; even once known it is **NOT DERIVABLE for this board**, because θJA (73 / 48 °C/W,
`:188-191`) is measured *"using a four-layer board"* per JEDEC JESD51-7 (`:192-193`), which the module is not.

---

## §3 Supply current at 9 dB

### 3.1 The synth's RMS is derivable — and v1's per-state figures were ~7.4× too high

v1 refused the crest factor (§8 item 8) and assumed a sine at the digital peak. That refusal is what let the per-state
figures stand at the wrong magnitude **and** in the wrong direction (labelled "≥", i.e. floors, while every input was
chosen at the **upper** edge). **The crest factor is exactly derivable**, and I re-derived it here from the firmware
constants rather than adopting the review's number:

For a sum of sines at **distinct** harmonics the RMS is `sqrt(Σaᵢ²/2)` and is **phase-independent**. The whine lands on
an **existing** harmonic in both voices, so it is folded in at worst-case phase (coherent addition — an upper bound).
The noise term is uniform on ±`noiseAmp` (`EngineSynth.cpp`:136-137, from `(nextNoise() − 32768) × noiseAmp >> 15`),
so its mean square is `noiseAmp²/3`.

- **V10** (`EngineSynth.hpp`:87-90, the shipped default, `SynthProfiles.hpp`:37): partials
  {2200, 4400, 5600, 4000, 2600, 1400} at harmonics 1…6; whine **2800** at `whinePitchEighths = 24` = **3.0×**
  (`:93`), i.e. **harmonic 3** ⇒ fold to {2200, 4400, **8400**, 4000, 2600, 1400}; noise ±1600 at redline
  (`EngineSynth.cpp`:127). **RMS = 7 784.**
- **V6** (`SynthProfiles.hpp`:55-69): partials {1400, 4600, 5200, 3800, 2600, 1600, 800}; whine **4200** at 5.0×
  ⇒ harmonic 5 ⇒ {…, **6800**, …}; noise ±1800. **RMS = 7 622.**
- **Overrun crackle burst** (`EngineSynth.cpp`:128-130, `noiseAmp × 3`, randomly gated 1-in-4 inside the overrun
  window): V10 **RMS = 8 211**, V6 **RMS = 8 170**. **This is my one addition to the review's figure** — the review
  computed the redline-noise case (7 784) and did not carry the burst. The burst is the higher number, so it is the
  conservative one; it raises every figure below by ≈ 11 %.

**Crest factors:** V10 24 600 (coherent peak) / 7 784 = **3.16**; against `kHeadroomPeak` 30 000, **3.85**; with the
crackle burst, 27 800 / 8 211 = **3.39**. v1 assumed **1.414**. Ratio in voltage 0.367, in power **0.135** — v1's
output-power table overstated by **≈ 7.4×**, and it then divided by VDD and wrote "≥".

**Peak sums, independently recomputed and correct:** V10 20 200 + 1 600 + 2 800 = **24 600**; V6 20 000 + 1 800 +
4 200 = **26 000**; with the ×3 crackle **27 800 / 29 600**; `kHeadroomPeak = 30 000` of 32 768 = **−0.767 dBFS**
(`EngineSynth.hpp`:103, enforced in `valid()`, `:114-118`). **The actual profile peaks are used below, not the 30 000
design cap** (R-DR3-2 B2).

**The volume chain, both stages confirmed in code:** `synthVolumeFor(ignition, throttlePercent)` → **0 / 70 /
(90 + throttle·165/100 = 90…255)** (`AudioDecision.hpp`:32-36); `applyOperatorVolume` = `stateVolume × min(op,100)/100`,
**linear, truncating** (`:78-82`, comment at `:58`); the synth's final stage `sample = sample × vol / 255`
(`EngineSynth.cpp`:155). Composed bytes: Cranking@80 = **56**, Running/idle@80 = **72**, Running/50 %@80 = **137**,
Running/full@80 = **204**, Running/full@100 = **255**. `kVolumeMax = 100`, `kDefaultVolume = 80`
(`Link2Frame.hpp`:92-93).

**Recomputed per-state figures — CONDITIONAL ESTIMATES. NOT bounds. NOT criteria. NOT M-PEAK-clean. On NO card.**
Using the harmonic-sum RMS above, the actual profile peak, `output dBV = dBFS + 2.1 + gain` with 0 dBFS = a full-scale
sine (RMS 23 170), 4 Ω, VDD 5.0 V, and `I = P_out/VDD`:

| Engine state | composed byte | dBFS | **gain MIN 8.4 dB** | gain typ 9 dB | typ + crackle burst |
|---|---|---|---|---|---|
| `Ignition::Off` | 0 | — | 0 (bit-exact silence, `AudioDecision.hpp`:33) | 0 | 0 |
| Cranking @ 80 | 56 | −22.6 | **3.1 mA** | 3.5 mA | 3.9 mA |
| Running, throttle 0 % @ 80 | 72 | −20.5 | **5.0 mA** | 5.8 mA | 6.5 mA |
| Running, throttle 50 % @ 80 | 137 | −14.9 | **18 mA** | 21 mA | 23 mA |
| Running, full throttle @ 80 | 204 | −11.4 | **41 mA** | 47 mA | 52 mA |
| Running, full throttle @ 100 | 255 | −9.5 | **63 mA** | 73 mA | 81 mA |

(At 8 Ω every figure halves.) **What these are and are not.** They are the **audio-derived component** of the amp's
supply current at a stated state, computed with a **typ**-class chain (a typ gain, a typ-derived rail behaviour) and an
RMS that is itself an **upper** bound (worst-case whine phase, redline noise). They are therefore **not a floor, not a
ceiling, not a bound in either direction, and not a PASS criterion for any reading.** They must never be entered in a
`P(N)` cell, a `Σ P(k)` term or a rail allowance. The single fact worth carrying is qualitative and it is already on the
card: **at the states this staircase can reach, the amp's audio-derived draw is of the same order as the part's own
quiescent current (3.35 mA max at +25 °C), so a low reading is not evidence that the amp was silent — only the recorded
engine state and `get sound.volume` say what the amp was doing.**

The Cranking figure landing **below the part's own quiescent current** is the proof that v1's "sanity-check band"
(26 mA / 43 mA) was unusable: a correctly working, actually-rendering amplifier would read roughly an order of
magnitude below it, and the card would have told the operator the amp was broken. **Withdrawn; no band exists.**

### 3.1a Does anything clip? — corrected

v1 asserted *"nothing in the shipped configuration clips"* on the strength of the 30 000 design cap and the ideal rail.
With the **actual** profile peaks and the ≈ 4.459 V peak the datasheet's own 10 %-THD rows imply is reachable into 4 Ω:

| Case (volume 100, full scale) | predicted peak | vs ≈ 4.459 V |
|---|---|---|
| V10 steady, gain typ | 3.81 V | clear |
| V10 + crackle burst, gain typ | 4.31 V | clear |
| **V6 + crackle burst, gain typ** | **4.59 V** | **rides into clipping** |
| V10 + crackle burst, gain **max** 9.6 dB | 4.61 V | rides into clipping |
| V6 + crackle burst, gain **min** 8.4 dB | 4.28 V | clear |

So: **at `sound.volume` 100 the loudest transient — the V6 overrun crackle burst — rides into the clipping region at
gain typ and above.** The steady voices do not. Because the crest factor is ≈ 3.2–3.4 this affects **peaks only** and
does not materially move the RMS-derived figures — but *"nothing clips"* is not true and is not claimed anywhere.
**Not on any card:** it is an acoustic-voicing observation, not a rail fact.

### 3.2 An UPPER bound on supply current — **NOT DERIVABLE at any gain. CONFIRMED at 9 dB.**

`I_supply = P_out / (η · VDD)`. An upper bound needs a **minimum** η. The datasheet publishes **one** efficiency
number: *"Efficiency ε — Z_SPK = 8Ω + 68µH, THD+N = 10 %, f = 1kHz, gain = 12dB — **92** %"* (`:269-271`). It is a
**typ**, at **8 Ω**, at **1 W**, at **12 dB**, at one frequency; the efficiency-vs-output curves are likewise
*typical* curves. DR2-2 forbids substituting a typ for a minimum. **VERDICT: NOT DERIVABLE. Missing datum: a
manufacturer MINIMUM efficiency (or a guaranteed maximum supply current, or a maximum dissipation at a stated output
condition). This is a datasheet gap, not an owner question — no photograph can close it.** **No efficiency has been
invented here.**

**The ±1.6 A absolute maximum, and the sentence that must travel with it.** Absolute Maximum Ratings, `:171`:
*"Continuous Current In/Out of V_DD/GND/OUT_ … ±1.6A"*.

> **±1.6 A is a damage threshold under the datasheet's own AMR caveat — NOT an allowance, NOT a PSU setting, NOT a
> prediction of draw; nothing may be set or permitted up to it.** (*"These are stress ratings only, and functional
> operation of the device at these or any other conditions beyond those indicated in the operational sections of the
> specifications is not implied."* `:182-184`.) It must never be entered in a `P(N)` or `Σ P(k)` cell, never used as a
> rail-sizing term, and never dialled into the bench PSU as the amp branch's current limit — T11's ratified policy is
> the **lowest defensible limit per substep**. Its only use is negative: **no figure, setting or allowance may permit
> sustained amp-branch current above it.**

Three reasons the guard is not optional (R-DR3-2 B6): (a) the amp cannot draw near 1.6 A into its own load, so a 1.6 A
trip point would sit far above any fault short of a dead short; (b) L13's Value column is where added-load allowances
are read from, which is exactly the pathway that produced v1's sizing-sum proposal; (c) the same AMR block rates
*"Duration of OUT_ Short Circuit to GND or VDD … Continuous"* and *"Duration of OUTP Short to OUTN … Continuous"*
(`:173-174`), so the datasheet itself contemplates fault currents above the number — further reason it is not a
statement about what the branch will do.

**On ILIM and the output current.** Into a **purely resistive** 4 Ω at ≤ 5.5 V the output current would not exceed
≈ **1.375 A**; but 4 Ω is **nominal**, DR2-8 has the impedance BLOCKED (packet item 6), a nominal-4 Ω driver's
impedance **minimum** is lower than its nominal, and the datasheet's own test load is R + L (`:388-389`). At a 3.2 Ω
minimum, 5.5 V would give 1.72 A. So treat 1.375 A as **indicative, not a "cannot"** (R-DR3-2 N1). The conclusion
survives comfortably and is what the cards carry: **ILIM 2.8 A is a typ, is an output limit, and is short/fault
protection — never a normal-operation bound and never a supply-current maximum.**

### 3.3 If the speaker proves 8 Ω — **BLOCKED on packet item 6, direction known**

Impedance traces to a single BOM line, `Speaker 4 Ω 3 W` (`bill_of_materials_v2.md`:71), which
`HARDWARE_INVENTORY.md`:98 itself calls *"impedance/power a bench spec-check"*. Under DR2-8 it is **BLOCKED**.
**If it proves 8 Ω, `P = V²/Z` halves** — every figure becomes **slacker, never tighter**, so the 4 Ω forms are the
conservative ones to carry and the cards keep saying so. §3.2 is unaffected: the absence of a minimum efficiency and
the ±1.6 A abs-max are impedance-independent.

*(The BOM line's "3 W" is a speaker **thermal** rating, not a limit on the amplifier. Against the achievable ≈ 2.49 W
clean-sine ceiling into 4 Ω (§2.4), the speaker's own rating is not reached by a clean sine; that is an acoustic
bring-up question, not a rail question, and no card carries it.)*

---

## §4 Should "≥ 640 mA at the 12 dB spec point" stay? — **YES, demoted; and the sizing-sum substitution is WITHDRAWN**

### 4.1 Which way each candidate errs

| Figure | Kind | As a **PSU current limit** | As a **rail-sizing term** |
|---|---|---|---|
| **640 mA** (3.2 W / 5 V, 12 dB, **typ**-based) | **lower** bound, at an unshipped condition, resting on a guidance value | Errs **LOW** — a limit near it can trip in CC on a legitimate draw, and DR2-11 makes that a STOP that costs the session | Errs **UNSAFE** — a lower bound understates a load |
| **The 9 dB per-state estimates** (§3.1) | **estimates**, typ-and-min-gain-based, neither bound | **Not usable.** Not a bound in either direction | **Not usable.** Never a `P(N)` or `Σ P(k)` term |
| **±1.6 A** (abs-max continuous into VDD) | manufacturer **MAXIMUM**, a **stress rating** | Safe **only** as a never-exceed the design may not permit crossing — **never as a setting** | **Not a sizing term.** The part cannot draw it into a 4 Ω or 8 Ω speaker at 5 V; entering it would invent a ~0.8 A design load |
| **The output ceiling** (§2.3/§2.4) | output-side, and typ-derived | Not a PSU figure. **Never a supply-current ceiling** | Not a sizing term |

### 4.2 Recommendation, as applied

1. **On L13 / T7 / T11 — keep 640 mA, demoted** to an explicitly labelled **datasheet reference point**, with the
   M-PEAK label it was missing: it rests on a **typ** output power (`:2542-2543`), so it is **not** design evidence
   under DR2-2 and **not** a rail-sizing term. **Do not delete it** — it is the only figure tying the project's
   reasoning to a published manufacturer output-power row, and deleting it would make the 9 dB derivation
   unfalsifiable against the datasheet. **Applied.**
2. **Add `ISTNDBY` 400 µA max** as the M-PEAK-clean maximum for the un-clocked state. **Applied** (L13, T7, T11, S4).
3. **Put ±1.6 A in BG-03 S4's never-exceed column, with the guard sentence of §3.2, and name it in L13 as explicitly
   NOT one of that column's allowances. Applied.**
4. **Do NOT add the per-state figures to any card. Applied** (they are in §3.1 of this report and nowhere else).
5. **The Rail-A sizing sum — FLAG, not a proposal (v1's §6.5 is withdrawn).** v1 mis-cited it: **T11**
   (`bench-gates/tools/first_power_current_limits.md`:106) carries the 640 mA term but **contains no sizing sum at
   all**. The sums live in **`W17_OWNER_ACTIONS.md`** (the DR2-13 ruling's rationale) and **`CURRENT_STATUS.md`** —
   both **owner-facing / Director-owned state attached to a ruling**, so changing a printed percentage is an **owner
   adjudication**, not a worker fix. **Director ruling applied on this branch:** the sums keep **2628 mA** (shipped cap
   110) and **3000 mA** (180 ceiling); **±1.6 A is NOT substituted**; the amp term is **relabelled**:

   > amp **≥ 640 mA — a lower bound resting on a typ 3.2 W guidance figure at the 12 dB spec point, a condition the car
   > does not ship; the amp has no derivable upper bound, so the sum has no defensible upper value and remains a
   > mixed-direction sizing sum.**

   The arithmetic v1 offered is correct as arithmetic (`1800 + 188 + 1600 = 3588 mA = 71.76 %`;
   `1800 + 560 + 1600 = 3960 mA = 79.20 %`) and is recorded here **only** to show what was refused: it would allocate
   ~0.8 A of Rail A to a current the part cannot draw into its own speaker, and would move the headline utilisation
   from 53 % to 72 % on that fiction.

---

## §5 What DR3-2 changes for BG-03 S4 — **`P(4)` stays BLOCKED; four things around it move**

### 5.1 Does an acceptance state at 9 dB give a defensible `P(4)`? — **NO.**

The chaining rule is `L(N) = max(R(N−1), Σ P(k) for k<N) + P(N)`, and `P(N)` must be an **upper bound on the added
load's draw**. §2 gives an upper bound on **output power**; §3.2 shows it cannot be converted into an upper bound on
**supply current** without a **minimum** efficiency. **`P(4)` stays BLOCKED**, on two named, separable data:

- **B-i — a manufacturer MINIMUM efficiency** (or a guaranteed max supply current / max dissipation at a stated output
  condition). Absent from Rev 7; only a typ at 8 Ω / 1 W / 12 dB (`:269-271`). **A datasheet gap, not an owner
  question — no photograph can close it.** It closes by bench measurement, or not at all.
- **B-ii — the speaker impedance** (DR2-8, photo/label packet **item 6**).

Two further items attach to the row without being `P(4)` blockers:
- **B-iii — the fitted board's GAIN implementation** (§1.3; procurement item 11). DR3-2's own creation; an owner
  action with no power required.
- **B-iv — the IC package (WLP vs TQFN)**, which gates the abs-max dissipation route — and that route is **NOT
  DERIVABLE for this board** anyway (θJA is a JEDEC four-layer-board number, `:192-193`).

### 5.2 What DOES move

1. **A never-exceed for the row: ±1.6 A**, with the §3.2 guard sentence attached wherever it appears. S4 previously
   carried only *"amp ILIM 2.8 A"*, which is (a) an **output** limit, not a supply limit, and (b) a **typ**, so under
   DR2-2 it should never have stood alone as the never-exceed.
2. **The row's premise is corrected.** The old reasoning implies 9 dB is *quieter*. It is not: the ceiling is the same
   5 V rail at all three gain band edges. The row now says so, **qualitatively**.
3. **The evidence requirement sharpens.** R-ADD's B2 required *silent vs rendering* and the `sound.volume`. That is
   still not enough: `synthVolumeFor` is the dominant term, so the same volume byte spans more than an order of
   magnitude across Cranking / idle / full throttle. **S4 must record the ENGINE STATE — `Ignition` (Off / Cranking /
   Running) and the throttle percentage — with the reading.**
4. **`ISTNDBY` 400 µA max** gives the un-clocked half of S4 a real manufacturer maximum for the first time.

**Net: S4 stays BLOCKED for `P(4)`, and gains a never-exceed, a corrected premise, a sharper evidence requirement and
one new manufacturer maximum. It does not gain a number for `P(4)`, and it does not gain a pass criterion.**

---

## §6 CARD TEXT — **as applied on `program/offline-readiness-r4`**

Each block quotes its anchor **exactly as it stood at tip `24e0d08`** (the state after the DR3 application pass), then
gives what replaced it and what is **retained**. Re-anchoring was R-DR3-2's B1: v1's quotes came from
`offline/o6-v3-brief`, which predates the DR3 apply, so none of them would have matched.

### 6.1 `bench-gates/tools/first_power_current_limits.md` — **L13** (:76)

**Anchor at `24e0d08`, verbatim (the head and tail of the Value cell):**
> *"**3.35 mA max IDD**; **≥ 640 mA at the datasheet's own 3.2 W condition** — `ZSPK = 4Ω + 33µH`, `THD+N 10%`,
> **`gain = 12dB`**, `VDD = 5V` (3.2 W / 5 V, by energy conservation; no efficiency figure needed). **This is a
> spec-point figure, not a prediction for the shipped car:** `GAIN` floating = **9 dB is CONFIRMED (DR3-2)** as the
> intended shipped configuration … at 9 dB the manufacturer publishes no output-power figure, and the speaker's 4 Ω is
> unverified (`HARDWARE_INVENTORY.md`:98, "a bench spec-check"). **2.8 A ILIM** is the part's **output** current limit,
> not a supply-current maximum"*

**Retained unchanged:** the DR3-2 confirmation, the pre-solder pad-mapping requirement, the generic-AliExpress
attribution with *"do not assume the Adafruit pinout"*, the unverified-4 Ω note, and the whole `≥ 640 mA` condition
string. **Added:** `TA = +25 °C` on the IDD max; **`ISTNDBY` 400 µA max** (un-clocked state only); the **8.4 / 9 /
9.6 dB** band with *"the shipped 9 dB is a typ"*; the **3.2 W typ/guidance relabel** with the datasheet's own sentence,
making `≥ 640 mA` **REFERENCE ONLY / not M-PEAK-clean / not a sizing term**; the **Table 8 ≡ `PinMap.hpp` agreement**
and the 100 kΩ-pulldown-⇒-15 dB warning pointing at procurement item 11; the **qualitative supply-limited
conclusion**; **ILIM relabelled a *typ***; and **±1.6 A** with the full guard sentence and an explicit statement that
it belongs in **BG-03 S4's never-exceed column, not in this Value column's allowances**.
**Not added:** any per-state mA figure; any watt ceiling; any "cannot exceed 1.375 A".

### 6.2 `bench-gates/tools/first_power_current_limits.md` — **T7** (:102)

**Anchor at `24e0d08`, verbatim (the opening of the Status cell):**
> *"Quiescent **3.35 mA max**; the part draws **≥ 640 mA at the datasheet's own 3.2 W condition** (4 Ω + 33 µH,
> THD+N 10 %, **gain = 12 dB**, VDD 5 V); **ILIM 2.8 A** is the part's **output** current limit. **The shipped
> configuration is a different condition:** GAIN floating = **9 dB is CONFIRMED (DR3-2)** as the intended shipped
> configuration (`PinMap.hpp`:20-24) — verify the fitted board's actual pad mapping against the datasheet before
> soldering — speaker impedance unverified (`HARDWARE_INVENTORY.md`:98), and the synth's own theoretical peak sits below
> full scale (`kHeadroomPeak = 30000` of 32767 …). **No upper bound on supply current is derivable** — it needs a
> **minimum** efficiency and only a **typ at 8 Ω** exists."*

**Retained unchanged, and explicitly so (R-DR3-2 N5):** everything from *"**Record with the measurement:**"* onward,
including the R-ADD N9 language that gates the volume-100 ceiling reading to a card that already authorises an armed
throttle command, and the *"if the amp was silent this row stays THRESHOLD MISSING"* rule. **Added:** the `TA = +25 °C`
qualifier; **`ISTNDBY` 400 µA max**; the **3.2 W typ relabel** (⇒ `≥ 640 mA` REFERENCE ONLY, not M-PEAK-clean);
**ILIM = typ**; the **±1.6 A never-exceed pointer with its guard sentence**; the **Table 8 agreement + 8.4 … 9.6 dB
band + 15 dB-pulldown warning**; the **qualitative supply-limited conclusion**; the upgrade of the load-state
requirement to the **ENGINE STATE** (`Ignition` + throttle percentage) with the `synthVolumeFor` reason; and the
**"volume 80 and volume 100 are two separate figures and neither can be scaled to the other"** rule (output power
scales by (100/80)² = 1.5625 because the mapping is linear, `AudioDecision.hpp`:78-82, but supply current does not,
and no published figure relates them). **No duplicated engine-state sentence was introduced.**

### 6.3 `bench-gates/BG-03_phase_b_first_power.md` — the **S4 row**

**Anchor — the `P(N)` cell at `24e0d08`, quoted IN FULL** (v1 never quoted it, and its replacement would have silently
dropped four things this cell carries):
> *"quiescent **3.35 mA max**. **Driven: BLOCKED for the shipped configuration.** The part draws **≥ 640 mA at the
> datasheet's own 3.2 W condition** — `ZSPK = 4Ω + 33µH`, `THD+N 10%`, **`gain = 12dB`**, `VDD = 5V` (energy
> conservation, 3.2 W / 5 V; no efficiency figure needed). **The car ships at a different gain:** `GAIN` floating =
> **9 dB is CONFIRMED (DR3-2)** as the intended shipped configuration (`w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24;
> `bench-gates/BG-04_d8_bench_bringup.md`:143; Phase 9 has not run) — **before permanent soldering, the actual board's
> GAIN implementation/pad mapping must be verified against the exact article and the manufacturer datasheet** (the
> fitted part is a generic AliExpress "MAX98357A I2S amplifier 1PCS" — `HARDWARE_INVENTORY.md`:97,
> `w17-control-fw/docs/bill_of_materials_v2.md`:69 — do not assume the Adafruit pinout), and the speaker's 4 Ω traces
> to one BOM line the inventory itself calls "a bench spec-check" (`HARDWARE_INVENTORY.md`:98). **The datasheet's 12 dB
> specification point is NOT the shipped configuration** and must not be presented as it: at 9 dB the manufacturer
> publishes no output-power figure, so the shipped driven draw is **not** bounded below by 640 mA"*

**All four of those — the DR3-2 confirmation, the AliExpress / "do not assume the Adafruit pinout" warning, the
"Phase 9 has not run" note and the speaker "bench spec-check" cite — are RETAINED.** **Added:** the `TA = +25 °C`
qualifier and **`ISTNDBY` 400 µA max**; the **3.2 W typ/guidance relabel** (⇒ `≥ 640 mA` REFERENCE ONLY, not
M-PEAK-clean, not a sizing term); the **Table 8 ≡ `PinMap.hpp` agreement**, the **8.4 … 9.6 dB** band, the
15 dB-pulldown warning and the pointer to procurement item 11; and the **qualitative** premise correction —
*"Do NOT read 9 dB as 'quieter than the 12 dB spec point': at 9 dB the full-scale output remains SUPPLY-LIMITED at
every one of the three gain band edges, exactly as at 12 dB, because the binding ceiling is the 5 V rail and not the
gain. 9 dB therefore does not reduce the amplifier's worst case, and nothing here is tightened by it."*
**Not added: no sanity-check band, no per-state figure, no watt number.** The `:69` BOM cite became `:69-70`
(R-DR3 N8).

**Anchor — the never-exceed cell at `24e0d08`, verbatim:**
> *"amp **ILIM 2.8 A** (the part's own **output** current limit, not a supply-current maximum); Rail A output **5 A**"*

**Replaced by** the ±1.6 A AMR entry carrying the guard sentence verbatim, the ILIM relabel (**typ**, output-side,
short/fault protection only), and **Rail A output 5 A retained**.

**Anchor — the Status cell opening at `24e0d08`, verbatim:**
> *"**BLOCKED.** No **upper** bound on supply current is derivable at any gain: it needs a **minimum** efficiency, and
> the only cited efficiency is a **typ at 8 Ω** (92 %), which DR2-2 forbids substituting. **This row must state its
> load state.**"*

**Retained unchanged:** the entire remainder of the cell — the silent-vs-rendering rule, *"A silent-amp reading is not
a bound on the amp and must not be chained as one"*, the D8 Phase 11a acceptance load, the ceiling = 100 rule,
*"Record `get sound.volume` with the reading"*, and the 8 Ω slack note. **Replaced by** the restructured
*"BLOCKED — on two separable data, both named"* opening: (i) no manufacturer **minimum** efficiency, with the full typ
condition and *"a datasheet gap, not an owner question: no photograph can close it"*; (ii) speaker impedance, DR2-8
packet item 6; plus the GAIN-implementation note, the **ENGINE STATE** requirement, and *"There is no derivable
expected value for this reading: no reading at this substep is a PASS, and a low reading is not by itself evidence
that the amp was silent."*

### 6.4 `bench-gates/BG-03_phase_b_first_power.md` — **Q6**, and `bench-gates/BG-04_d8_bench_bringup.md`:143

**Q6 anchor at `24e0d08`, verbatim:** *"The datasheet's 3.2 W figure is published at **12 dB**, which is **NOT** the
shipped configuration, so it is a spec-point figure and not a prediction for this car."* — **retained**, and joined by
the Table 8 agreement, the 8.4 … 9.6 dB band, the 15 dB-pulldown warning with the item-11 pointer, the typ/guidance
relabel, and the qualitative supply-limited conclusion.

**BG-04:143 anchor at `24e0d08`, verbatim:** *"MAX98357A GAIN strap (9 dB, GAIN floating — CONFIRMED DR3-2; verify the
board's pad mapping against the datasheet before soldering)."* — **retained in substance**, with 9 dB named as a
**typ** (band 8.4 … 9.6 dB), the strap stated to remain **BLOCKED until the unpowered pre-solder check is recorded**,
the pointer to procurement item 11, the beeper-cannot-do-this note, and the **do-not-solder** outcome rule.

### 6.5 The pre-solder GAIN check

v1 proposed it as a new BG-04 block. **It lives on `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11 instead** (it is
an unpowered owner action, and that file is where such actions are tracked), with BG-04:143 pointing at it. R-DR3-2's
item-11 list (§"§6 edits I would let through UNCHANGED", entry 11) is applied there in full, plus R-DR3 B3's
resistance method and outcome rule, R-DR3-2 N3's diode-mode caveat and N4's discriminator qualifier. **Every step is
unpowered; the card authorises no power and no soldering.**

### 6.6 The Rail-A sizing sum

**Not a §6 block — see §4.2 item 5.** It is owner-facing state (`W17_OWNER_ACTIONS.md`, `CURRENT_STATUS.md`), not a
bench card, and the only change made is the **relabel** of the amp term. **`CURRENT_STATUS.md` is Director-owned and
was not touched on this branch**; the replacement sentence for it is returned in the FIX-DR3 worker report.

---

## §7 SOURCES, with line cites

**Primary — manufacturer datasheet.** Maxim Integrated, *MAX98357A/MAX98357B — PCM Input Class D Audio Power
Amplifiers*, document **19-6779; Rev 7; 2/16** (self-identified at `max98357a.txt`:85; © 2016 Maxim Integrated;
revision history **`:2524-2540`**, the Rev 7 row at `:2540` — corrected from v1's `:2524-2534`, R-DR3-2 N6). Extract:
`…/scratchpad/max98357a.txt`, 2 546 lines. **Every line below was re-opened by me in this pass.**

| Fact | Extract line(s) |
|---|---|
| Five gain settings, front page | `:11-13` |
| Abs-max: *"All Other Pins to GND … -0.3V to (VDD + 0.3V)"* | `:170` |
| Abs-max: **Continuous Current In/Out of VDD/GND/OUT_ ±1.6 A** | **`:171`** |
| Abs-max: *"Continuous Input Current (all other pins) … ±20mA"* | `:172` |
| Abs-max: OUT_ short-circuit duration *"Continuous"* (both rows) | `:173-174` |
| Abs-max: continuous dissipation, WLP 1096 mW / TQFN 1666 mW at `TA = +70 °C` | `:175-177` |
| Abs-max boilerplate — *"stress ratings only … functional operation … not implied"* | **`:182-184`** |
| θJA WLP 73 °C/W, TQFN 48 °C/W; JEDEC four-layer-board caveat | `:188-193` |
| **EC table default condition — `GAIN_SLOT = VDD`, i.e. 6 dB** | **`:195`** |
| Supply voltage range 2.5–5.5 V | `:198` |
| UVLO max 2.3 V | `:199` |
| **IDD 2.75 typ / 3.35 mA max, `TA = +25 °C`** | **`:200`** |
| **ISHDN 0.6 typ / 2 µA max** (`SD_MODE = 0 V`) | `:204` |
| **ISTNDBY 340 typ / 400 µA max** (`SD_MODE = 1.8 V`, **no BCLK**) | **`:205`** |
| VOS ±2.5 mV max | `:207` |
| **POUT rows — all at `gain = 12dB`**: 4 Ω + 33 µH **3.2 W** @ 10 % THD+N, 8 Ω + 68 µH 1.8 W; 1 % rows 2.5 W / 1.4 W | **`:234-247`** |
| THD+N 0.06 % max | `:249` |
| **Dynamic Range row — `VRMS = 2.54 V`** (the §2.2 check) | **`:257-258`** |
| **Gain, min/typ/max for all five legs** | **`:260-267`** |
| **ILIM 2.8 A** (typ) | `:268`; *"2.8A typ"* at `:2021` |
| **Efficiency 92 % — typ, 8 Ω + 68 µH, THD+N 10 %, 1 kHz, gain 12 dB** | **`:269-271`** |
| Frequency response ±0.2 dB | `:273` |
| `SD_MODE` pulldown `R_PD = 100 kΩ` (GAIN_SLOT has none published) | `:365` |
| **GAIN_SLOT comparator trip points** | **`:366-386`** |
| Note 3 — test load is R + L (33 µH at 4 Ω, 68 µH at 8 Ω) | `:388-389` |
| Pin description — GAIN_SLOT = WLP B2 / TQFN pin 2 | `:1513-1517` |
| *"power loss … mostly due to the I²R loss of the MOSFET on-resistance"* (no numeric `RDS(on)`) | `:2003` |
| Speaker current limit — *"2.8A typ"* | `:2019-2025` |
| **Gain Selection text + the output-level equation + the rail caveat** | **`:2026-2038`** |
| **Table 8. Gain Selection** | **`:2054-2068`** |
| Revision history (Rev 7 row at `:2540`) | `:2524-2540` |
| **"min and max limits … are guaranteed. Other parametric values … provided for guidance."** | **`:2542-2543`** |

**Provenance.** v1 re-fetched an independent copy of the Maxim-authored PDF from the Adafruit mirror
(`https://cdn-shop.adafruit.com/product-files/3006/MAX98357A-MAX98357B.pdf`, 2 648 763 bytes) after analog.com timed
out, and re-extracted its text to `…/scratchpad/max98357a_refetch.txt`; the gain rows, the ±1.6 A line, the comparator
windows, Table 8 and the gain equation matched the extract verbatim. **That work is v1's and I did not repeat the
fetch**; I re-read every line above in `max98357a.txt`. The mirror is named, per the disclosure rule.

**Project sources** (all re-opened in this pass):

| Fact | File:line |
|---|---|
| GAIN strap intent, *"documented, not driven"*; `SD_MODE` strapped high | `w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24 (SD_MODE at :21-22); *"canonical Adafruit hookup"* = **I²S only**, `:16` |
| `kHeadroomPeak = 30000`, enforced in `valid()` | `w17-soundlight-fw/lib/soundsynth/include/soundsynth/EngineSynth.hpp`:103, :105-118 |
| V10 partial stack, noise 1600, whine 2800 at `whinePitchEighths = 24` (3.0×) | `EngineSynth.hpp`:87-93; profile named at `SynthProfiles.hpp`:37 |
| V6 hybrid partials, noise 1800, whine 4200 at 5.0× (`whinePitchEighths = 40`) | `w17-soundlight-fw/lib/soundsynth/include/soundsynth/SynthProfiles.hpp`:55-69 |
| Harmonic partial render (`fundMilliHz × (p+1)`); noise `(nextNoise() − 32768) × noiseAmp >> 15`; ×3 overrun crackle; whine at `fundMilliHz × whinePitchEighths / 8` | `w17-soundlight-fw/lib/soundsynth/src/EngineSynth.cpp`:114-152 (noise :127-137, crackle :128-130, whine :148) |
| Final synth gain stage `sample = sample * vol / 255` | `EngineSynth.cpp`:154-155 |
| `synthVolumeFor` → 0 / 70 / 90…255 | `w17-soundlight-fw/lib/audiodecision/include/audiodecision/AudioDecision.hpp`:32-36 (bit-exact silence at `:33`) |
| `applyOperatorVolume` is **linear** on 0–100 | `AudioDecision.hpp`:58-59 (comment), :78-82 |
| `kVolumeMax = 100`, `kDefaultVolume = 80` | `w17-control-fw/lib/link2/include/link2/Link2Frame.hpp`:92-93 |
| Fitted amp is a generic AliExpress article (URL on `:70`) | `HARDWARE_INVENTORY.md`:97; `w17-control-fw/docs/bill_of_materials_v2.md`:69-70 |
| Speaker *"4 Ω 3 W"*, *"impedance/power a bench spec-check"* | `HARDWARE_INVENTORY.md`:98; `bill_of_materials_v2.md`:71 |
| Cards this derivation touched | `bench-gates/tools/first_power_current_limits.md` L13 / T7 / T11; `bench-gates/BG-03_phase_b_first_power.md` S4 row + Q6; `bench-gates/BG-04_d8_bench_bringup.md`:143; `bench-gates/MISSING_THRESHOLDS.md` §4; `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` item 11 |
| The Rail-A sizing sums (NOT T11) | `W17_OWNER_ACTIONS.md` (DR2-13 rationale); `CURRENT_STATUS.md` |
| Prior amp reasoning this pass revises | `_handoff/2026-09-06_O6_addendum_report.md` §2.2 (:176), §2.6 (:234); `_handoff/2026-09-06_R-ADD_review.md` B2, N5, N9 |

---

## §8 WHAT I REFUSED TO DERIVE, AND WHY

1. **An upper bound on the amplifier's supply current, at 9 dB or any other gain.** Needs a **minimum** efficiency;
   Rev 7 publishes one efficiency figure and it is a **typ**, at **8 Ω**, at **1 W**, at **12 dB** (`:269-271`).
   **No efficiency was invented and 92 % was not treated as a floor.** The ±1.6 A abs-max is offered **only** as a
   never-exceed and does **not** close this.
2. **A `P(4)` figure for BG-03 S4.** Follows from (1). **BLOCKED**, on the two data named in §5.1.
3. **A published output-power figure at 9 dB.** Does not exist — every `POUT` row is at 12 dB. The ceiling is derived
   from the gain equation plus the rail and is labelled as such; 3.2 W was **not** scaled by "3 dB = half the power".
4. **The speaker's impedance.** **BLOCKED — DR2-8, packet item 6.** Figures given at 4 Ω with the 8 Ω consequence
   stated (halve). I did not pick one.
5. **The fitted board's actual GAIN implementation.** **BLOCKED** — no schematic exists for the article, and
   `PinMap.hpp`:16's *"canonical Adafruit hookup"* refers to the **I²S** wiring only. The unpowered physical check
   (procurement item 11) is the deliverable in place of a guess.
6. **The IC package (WLP vs TQFN).** **BLOCKED** — unrecorded in every project document; and the dissipation route it
   gates is **NOT DERIVABLE for this board** regardless (θJA is a JEDEC four-layer-board number, `:192-193`).
7. **A junction- or surface-temperature figure for the amplifier.** **NOT DERIVABLE** — same θJA objection, plus no
   dissipation figure at the shipped operating point.
8. **~~The synth waveform's crest factor.~~ WITHDRAWN — v1's refusal was wrong, and it is the refusal that let v1's
   per-state figures stand ~7.4× high.** The crest factor **is** derivable from the firmware constants and is derived
   in §3.1 (V10 ≈ 3.16 against the coherent peak, 3.39 with the crackle burst).
9. **A per-state figure that any card may use.** The estimates in §3.1 are **not** bounds and **not** criteria, so
   they appear on **no** card. Refused: any "band", any "a reading below X means …", and any numeric ceiling taken from
   the typ `POUT` rows.
10. **Whether Rev 7 (2/16) is still the current revision.** v1 re-fetched a second copy and it is also Rev 7, but both
    trace to the same Maxim document and analog.com could not be reached. **Unresolved, flagged, low consequence** —
    the gain table and the abs-max ratings are structural.
11. **A change to any printed rail-utilisation percentage.** That is owner-facing state attached to the DR2-13 ruling;
    it is an owner adjudication, not a worker fix (§4.2 item 5).
12. **Nothing was powered, flashed, soldered, measured or transmitted, and nothing here authorises any of those.**
