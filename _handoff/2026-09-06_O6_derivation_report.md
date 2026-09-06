# O-6 derivation — starting current limits for the first-power staircase (v2)

> **Header note.** The v1 of this file was **superseded on 2026-09-06** after the adversarial
> review `R-O6` (persisted alongside as `_handoff/2026-09-06_R-O6_review.md`) returned
> `FIX_REQUIRED`. Do not cite v1; it is gone from this path and survives only in git history.

**Model: Claude Opus** · Worker report, offline desk work, 2026-09-06.
**This is v2. It supersedes v1 in full**, after the adversarial review `R-O6` returned
`FIX_REQUIRED` (7 BLOCKING, 11 NON-BLOCKING, 6 notes — every one accepted by the Director and
applied here). §0 maps each finding to what changed. The review is persisted alongside this
file as `_handoff/2026-09-06_R-O6_review.md`. The v2 text was then **independently re-verified
as `V-O6-2`**, which returned `FIX_REQUIRED` (1 BLOCKING, 8 NON-BLOCKING, 3 observations —
again every one accepted by the Director and applied here); **§0a** maps those to what changed.

**Evidence label: NOT-EXECUTED.** Nothing was powered, flashed or measured. Every row below
is a citation or a BLOCKED row; none is a reading.

**Serves:** owner ruling D-4 / **O-6** (2026-09-05), recorded verbatim at
`2026-09-05_offline_decision_round_1.md`:25-28 and `bench-gates/MISSING_THRESHOLDS.md`:35.

**Non-canonical dated snapshot**, per the `_handoff/` convention (`_handoff/README.md`:8-10:
snapshots are not canonical, and every snapshot must name its canonical source).
**Canonical source — the bench-gates cards this report was transcribed into:**
`bench-gates/BG-03_phase_b_first_power.md` § *"Starting current limits (O-6 derivation,
2026-09-06)"* (transcribed from §6.1 below, byte-identical modulo heading level) and
`bench-gates/tools/first_power_current_limits.md` rows **T11–T13** and **L11–L15**
(transcribed from §6.2 below, byte-identical). Those cards are the live version; if this file
and a card disagree, the card wins. **Origin:** written as the session-scratch report
`O6_derivation_v2.md`, in the session scratchpad's `reports/` directory (not a repo path, and
not resolvable from any checkout), which is kept byte-identical to this file.

---

## 0. Changes from v1 (R-O6)

| # | Severity | What v1 said | What v2 says |
|---|---|---|---|
| **B1** | BLOCKING | Servo never-exceed *"stall 1.9 A at 5 V"* everywhere | Never-exceed is **2.1 A at 6 V**, with the manufacturer's full triple **1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V**, because Rail B's documented band is **5–6 V** (`w17-control-fw/docs/D8_BENCH_BRINGUP.md`:55; `bench-gates/BG-04_d8_bench_bringup.md` PASS row for Phase 1). A 1.9 A ceiling would trip on a *healthy* 6 V stall. The bench pre-step (record BEC#2's actual output before S6–S9) is folded into **Q2** and kept as a bench action |
| **B2** | BLOCKING | NEVER-EXCEED column read *"Rail A 5 A"* inside a table whose L(N) column is a pack-side supply setting | Every P(N) and NEVER-EXCEED cell is now labelled **"5 V side, NOT a PSU setting"**, with a standing domain warning above the table. The pack-side form is stated as **`I_pack ≤ 5 A × V_rail / (V_pack × η)`**, η = the UBEC's efficiency — **unknown**, so the pack-side never-exceed stays **BLOCKED on Q2**. No η figure is invented and no η question is asked separately: the UBEC's own datasheet supplies it once the model is known |
| **B3** | BLOCKING | `L(N) = R(N−1) + P(N)` | **`L(N) = max( R(N−1), Σ_{k<N} P(k) ) + P(N)`**, plus the sentence *"a settled reading is never a bound on a bursty load"*. v1's own S5 data (113 mA unassociated vs 1510 mA peak on one part) is the proof it needed |
| **B4** | BLOCKING | Inrush carve-out justified by C1/C2 and the word *"momentarily"* | The inrush argument is restated **on the correct side**: what the supply sees at a connect is **UBEC input capacitance and soft-start** on the **7.4 V** side; **C1 (Rail B) and C2 (strip input) are 5 V-side capacitors, downstream of the UBECs**, and are named as such. *"Momentarily"* is withdrawn as a discriminator: the CC-duration criterion is now **BLOCKED on owner ruling Q9** |
| **B5** | BLOCKING | Q4 / Q8 proposed an unbounded ramp *"until it leaves constant-current"* | Characterisation of S1/S2 and S7/S8 is allowed **only under a per-substep ramp ceiling**. Q4 now asks first for a **no-power LOOK** at the MH-ET board's onboard regulator marking, so a datasheet output maximum can become a derivable S1 ceiling; failing a readable marking the owner **rules** the number. S2 and S7/S8 ceilings are owner rulings outright |
| **B6** | BLOCKING | *"Worldsemi's datasheet supplies nothing here"* | Scoped to the **Jan-2016 V1.0** revision. The **Mar-2017** revision's *LED Characteristics* table publishes **16 mA/channel** operating current, quoted in §2, §4 and §6; it **bounds the code's 20 mA/channel from below** (448 mA at cap 180 against the model's 560 mA) |
| **B7** | BLOCKING | 560 mA called *"the honest real-number bound"* on the strip | Relabelled throughout as an **emitter-model** upper bound. The model's 20 mA/channel is flagged as an **uncited code comment** (`LightRenderer.hpp`:205), and the **per-pixel controller quiescent current** — which neither Worldsemi revision publishes — is carried as a **named unquantified adder**, not silently omitted |
| **N1** | NON-BLOCKING | *"reproduces the code comment's 510 mA at :220-222"* | Claim dropped as a corroboration and re-attributed: the code's 510 mA is the **pre-gamma model at the shipped cap 110**, stated at `LightRenderer.hpp`:**214-215**; v2's 510.6 mA is the **post-gamma actual all-amber draw at cap 227** — a different quantity that collides numerically |
| **N2** | NON-BLOCKING | Q10 asked the owner to read the servo case marking | **Q10 DROPPED.** Page 1 of the cited PDF shows a case marked "DS3235SG". A one-line provenance note and a build-week visual check remain. **Q10′** replaces it (see N11) |
| **N3** | NON-BLOCKING | S4's driven term fully BLOCKED on the 8 Ω-vs-4 Ω efficiency gap | Conservation of energy needs no efficiency: with the datasheet's own 3.2 W into 4 Ω at 5 V, the supply current when driven is **≥ 640 mA** regardless of efficiency, bounded above by the cited **ILIM 2.8 A**. §4's Rail-A floor now enters the amp as *"unquantified (≥ 640 mA when driven)"*, not 3 mA |
| **N4** | NON-BLOCKING | *"DERIVED = 1800 mA … the conservative choice"* | **1800 mA moves to never-exceed**, cited as the module's own **supply-capability requirement** (§6.2.1, *"Peak current ≥1800mA"*) alongside the §1.3 headline. The word "conservative" is dropped — for a limit, higher is *less* protective. **Partly superseded by V-O6-2 B1 (§0a):** v2 also moved P(5) *off* 1800 mA, which put the largest 5 V load's allowance below the part's own §1.3 Max; P(5) is **1800 mA** again, on §1.3's authority, while 1800 mA stays in never-exceed on §6.2.1's |
| **N5** | NON-BLOCKING | BL-M8812EU2 presented as fetched from `b-link.net.cn`; called V1.0.1.0 | Mirror disclosed (`jkrorwxhkqmllp5m-static.micyjz.com`) on the same footing as the other two mirrors. The document's own stated revision is **V1.0**; "V1.0.1.0" is the filename string |
| **N6** | NON-BLOCKING | *"wrong by 2×"*, used three times | Replaced by *"uncited, with no stated test voltage; the manufacturer's own figures are 1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V"* — accurate, sufficient, and not a falsifiable claim inside a gate card |
| **N7** | NON-BLOCKING | *"Fourteen powered substeps … eleven in BG-03's staircase"* | **Fifteen**: twelve rows (S0, S1, S2, S3a, S3b, S4–S8, S9a, S9b) covering the nine-load staircase plus its PDB-alone step, and D8 Phase 1's three. The staircase lives in `bench-gates/tools/first_power_current_limits.md`, **not** in BG-03, whose own card carries 22 numbered powered steps B1.1–B4.4; the misnomer is removed. The "five substeps" claim is corrected to **six rows across four parts** |
| **N8** | NON-BLOCKING | No row for BG-03 step **B3.1** (linkage-**fitted** sweep) | A **B3.1** row is added in §3.2a. It inherits S9b's ceiling **at the rail's set voltage**, and its expected draw is BLOCKED — a bind under real mechanical load drives the DS3235SG toward stall |
| **N9** | NON-BLOCKING | T12 offered "separate the ESC's 12 AWG feed" as a resolution | The consequence is now stated wherever it appears: separating that feed is an **A2 gate S6 topology change** (`w17-pdb-build-and-connector-guide.md`:167-168), so A2's batt+ rows **P2 / P4 / P5** (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`:237-241) must be re-run **before and after**, and the change recorded. Folded into **Q3** |
| **N10** | NON-BLOCKING | T11's status cell opened with bolded mA figures in a pack-side row | The figure block is prefixed **"All figures below are 5 V rail-side added-load allowances, NOT bench-PSU settings."** |
| **N11** | NON-BLOCKING | 1800 mA cited from §1.3 only; heatsink mismatch not raised | §6.2.1 cited alongside §1.3. The **28×28×3 mm** fitted heatsink (`HARDWARE_INVENTORY.md`:76, :360) against the datasheet's **≥ 32×32 mm** recommendation (§6.4) and its *"must be added by customers … Tj<125℃"* note (§3.1) becomes new owner question **Q10′** |
| **T2** | NOTE | Two loose citation ranges; a joint rail-membership cite | `00_BUILD_SHEET.md`:36 is cited for **C1 only** (C2 comes from the PDB guide alone); the gamma LUT range is **:90-98 and :102**; and the PDB guide :51-53 is named as the **sole** authority for the MAX98357A and the A3144, because `D8_BENCH_BRINGUP.md`:47's rail list omits both |
| **T3** | NOTE | Hobbywing identity not tied to the owner's unit | The fetched page is the **Sensored G2** variant, which is the owner's unit (`w17-batch1-measurements-for-codex.md`:41) — the identity match is now stated |
| **T1 / T4 / T5 / T6** | NOTE | — | No change required: both central negatives survived falsification, no question re-opens a D-1…D-7 ruling, staircase coverage is complete, and §6 mirrors §3 figure-for-figure (re-verified for v2) |

## 0a. Changes from v2 (V-O6-2)

The v2 text above was then **independently re-verified** (`V-O6-2`, Opus, read-only,
2026-09-06). It returned `FIX_REQUIRED` — **1 BLOCKING, 8 NON-BLOCKING, 3 observations** — with
every R-O6 correction confirmed genuinely applied, every arithmetic claim reproduced on an
independent compile, and no BLOCKED row weakened. Every finding was accepted by the Director and
is applied below. The structure of v2 is unchanged; only the rows named here moved.

| # | Severity | What v2 said | What this revision says |
|---|---|---|---|
| **B1** | **BLOCKING** | `P(5) = 1510 mA`, with **both** of the module's 1800 mA figures classed as *"a requirement on the supply, not a limit to set"* | **`P(5) = 1800 mA`.** §1.3's *"Power Supply DC 5.0V±0.25V @1800mA (Max)"* sits in the module's *General Specifications* table, between `Dimension` and `Operation Temperature`, and is the part's **own maximum supply current** — precisely the Max column §3.0's M-PEAK selects. v2's figure was **290 mA below it**, so a healthy module at its rated maximum would trip the supply and the only exit would be raising the limit: the loop O-6 exists to close. 1800 mA stands **until Q5 names the RF mode**, at which point the applicable §3.3 row may replace it. §3.3's **1510 mA** is the largest of nineteen **per-use-case** RF-test peaks, not an envelope; it is now quoted only as that, never as the allowance. 1800 mA **also stays** in never-exceed, on §6.2.1's separate supply-sizing authority — the two figures are different claims that coincide. §4's Rail-A floor is restated as **≥ 3000 mA = ≥ 60 %** of UBEC A's 5 A (v2's figure and, before it, v1's are both superseded) |
| **N1** | NON-BLOCKING | `Serves:` cited `2026-09-05_offline_decision_round_1.md`:19-23 | **:25-28** (re-read). :19 is the `## D-4 Thresholds` heading and :20-24 are O-1…O-5 |
| **N2** | NON-BLOCKING | §3.2 S5 cited `w17-pdb-build-and-connector-guide.md`:91 for the 2T2R configuration | **:89** (re-read) — the *Antennas / Wi-Fi → antennas / RF / U.FL (×2, J0/J1)* row. :91 is the *"Connectors likely still to source"* paragraph. The fact was true; only the pointer was wrong |
| **N3** | NON-BLOCKING | §2 quoted *"two switching UBEC outputs hard-paralleled"* as evidence of the UBEC **topology** | That phrase is the Note on **A2 row P3**, whose Expected is *"no beep"* — it describes the **fault** of bridged rails, not the design, and as quoted it asserted one 10 A rail where the project has two independent 5 A ones. **Removed as evidence.** The type now rests on A2's own §S1 design note (`13_phase_a_a2_no_power_checklist.md`:252-253, *"two switching-regulator input stages … whatever internal path the switcher and any reverse-protection diode present"*), and §2 now states the rails are **independent** |
| **N4** | NON-BLOCKING | Neither `_handoff` file named a canonical source, which `_handoff/README.md`:9-10 requires of every snapshot | Both headers now carry the non-canonical marker and name their canonical homes. This file's are BG-03 § *"Starting current limits (O-6 derivation, 2026-09-06)"* (from §6.1) and `bench-gates/tools/first_power_current_limits.md` rows T11–T13 / L11–L15 (from §6.2) |
| **N5** | NON-BLOCKING | BG-03's *"waiting on"* list named five of the ten open questions | It names **all ten — Q1–Q9 and Q10′** — as an explicit enumeration, with **Q10′** (the Wi-Fi heatsink) called out as a **precondition of that very card**, since the project's own rule is *"heatsink fitted before first power-on"* and BG-03 **is** the first power-on. §6.1 mirrors it |
| **N6** | NON-BLOCKING | §6.1's S0 row put the pack-side *"0.20 mA @7.4 V"* in the column headed **5 V side**, with the annotation moved to never-exceed | The *"this one row is genuinely pack-side"* annotation is back in the **P(N)** cell, where §3.2 has it, with the 8.4 V value alongside. 0.2 mA, so no hazard — but it is the construct R-O6 B2 existed to remove |
| **N7** | NON-BLOCKING | §6.1's S9 linkage-OFF never-exceed carried a bare *"2.1 A at 6 V"* | It carries the full **1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V** triple and *"select from the recorded BEC#2 voltage"*, like every other occurrence — which is R-O6 B1's whole point |
| **N8** | NON-BLOCKING | §6.1 said *"the literal first number step 1 asks for"*, which inside BG-03 reads as **that card's** step 1 (B1.1, a CRSF baud/inversion check) | The referent is named: **the staircase's step 1**, `bench-gates/tools/first_power_current_limits.md`:112-114 |
| **O-2** | OBSERVATION | The R-O6 snapshot's repo line numbers went stale when this branch renumbered the tools rows | Its snapshot note now says so, and also labels the three figures in its verbatim body that B1 and N3 supersede |
| **O-1 / O-3** | OBSERVATION | — | **No change.** O-1 (`bench-gates/tools/first_power_current_limits.md`:107 reads *"How to derive T1–T12 safely"* while T13 exists) is **pre-existing and identical at 0802c55** — the fix queue's, not this branch's. O-3 records agreement and needs nothing |
| **D-1 / D-2 / D-3** | APPLIED ON r2 | — | Three findings land in `W17_OWNER_ACTIONS.md`, which is checked out on branch `program/offline-readiness-r2` in a different working tree, so they were not applied on this branch (one session per working tree). **They were applied by the Director on r2 at commit d4abefd (2026-09-06 14:19):** DR2-2 now ratifies M-PEAK *without* the inrush carve-out R-O6 B4 removed; DR2-4 cites BG-04's Phase 1 PASS row at `:218` (this branch moved it from `:208`); DR2-13 quotes the v2 Rail-A floor (≥ 3000 mA / ≥ 60 %) instead of v1's 2363 mA. V-O6-3 confirmed zero divergence between r2 and this branch |

---

## 1. Verdict

**Fifteen powered substeps were examined** — twelve rows covering the nine-load staircase at
`bench-gates/tools/first_power_current_limits.md` (its step 3 order) plus its PDB-alone step,
and D8 Phase 1's three — with one further BG-03 powered step, **B3.1**, added in §3.2a because
it is the one place the servo stall figure is load-bearing under real mechanical load.
**ZERO substeps can be given a settable starting amperage offline. All of them are BLOCKED** —
but not all for the same reason, and the block is much narrower than "no numbers exist".

**Six rows now carry a fully derived added-load allowance or never-exceed ceiling**, across
**four parts**: the WS2812 strip (S3a, S3b — **560 mA** emitter-model bound at the O-7 cap of
180, **188 mA** at the shipped cap 110), the BL-M8812EU2 Wi-Fi module (S5 — **1800 mA**, the
module's own §1.3 rated maximum supply current, which stands until Q5 names the RF mode; the
largest **per-use-case** peak in its §3.3 table is **1510 mA**, a single RF-test case and not an
envelope. It is the largest single car-side 5 V load in the project and was previously
undocumented), the MAX98357A (S4 — **3.35 mA** quiescent max, and **≥ 640 mA** when
driven, under **ILIM 2.8 A**), and the DS3235SG (S9a, S9b — **5 mA** idle, **2.1 A** stall at
6 V). S0 additionally carries a derived divider term (**0.20 mA**) but not a complete
allowance, because the UBEC quiescent and ESC standby terms are still absent.

What blocks every *absolute* limit is structural, not a missing lookup:

- **(a) No document names the bench PSU**, so its minimum settable constant-current value —
  the literal first number the staircase asks for — is unknown, and it is not even established
  that the supply has a settable limit.
- **(b) The supply sits on the pack side (7.4 V) while every derivable load figure is a 5 V
  rail current.** Converting between them needs the UBEC's efficiency, which cannot be known
  because **no document names the UBEC's make or model** — only "UBEC 5 A (2 pcs)". This is
  not a separate unknown to be ruled: the UBEC's own datasheet supplies η the moment the model
  is known, so it collapses into Q2.
- **(c) The first rail-A load in the staircase order is the pair of MH-ET LIVE D1-mini ESP32
  boards**, an AliExpress store-brand product with no manufacturer datasheet, so every later
  rail-A substep inherits an unquantified term.

Two owner answers (§5 Q1 and Q2) convert the staircase from "blocked" to "self-bootstrapping",
because from S1 onward each substep's limit can chain onto a reading taken minutes earlier in
the same session — **provided the chaining rule keeps every cited peak in the sum** (§3.1).
**Four family-level figures that were readily available and would have looked authoritative
were refused** (§7). One of them — a search engine's "DS3235SG stall current 3.9 A" — is
**uncited and carries no stated test voltage**; the manufacturer's own datasheet gives
**1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V**.

---

## 2. Part identities

Identity is taken **only** from this project's documents. Every path below is
**workspace-root-relative** (`w17-control-fw/…`, `w17-soundlight-fw/…`, or a workspace file with
no repo prefix). All datasheet retrievals: **2026-09-06**.

| Part (staircase role) | Exact model **as the project's docs name it** | path:line | Manufacturer datasheet found? |
|---|---|---|---|
| Bench PSU (S0 limit source) | **NOT NAMED ANYWHERE.** A2's tool list says only *"USB cable and bench PSU: **have them, do not connect them** — both are Phase B"*; the procurement sheet's status column reads *"unknown — no current-limit spec … is named in any gate doc"* | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`:116 ; `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`:82 | **none found — no model to look up** |
| UBEC A / UBEC B (rail sources) | **"UBEC 5 A (2 pcs)"** / BOM `UBEC 5 A  2PCS 5A`. No brand, no model. Type is doc-stated as **switching regulators** — A2's own §S1 design note says that once the UBECs are on the batt+ node you are measuring the divider *"in parallel with two **switching-regulator** input stages — input caps charging, plus whatever internal path the switcher and any reverse-protection diode present"*. **The two rails are independent**, not paralleled: UBEC-A out = Rail A, UBEC-B out = Rail B, and A2 row P3 requires rail-A ↔ rail-B to read **no beep** precisely because a bridge between them would be a fault | `HARDWARE_INVENTORY.md`:113 ; `w17-control-fw/docs/bill_of_materials_v2.md`:77 ; `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`:252-253 (type), :238 (row P3, the rails-independent check) ; `w17-pdb-build-and-connector-guide.md`:167-168 (UBEC-A → Rail A, UBEC-B → Rail B) | **none found — no model to look up.** This is why η in §3.1's pack-side form is unknown |
| ESP32 #1 / #2 (S1) | **MH-ET Live D1-Mini ESP32 (USB-C)** / BOM: *"2× 'D1 Mini ESP32' / MH-ET Live MiniKit (ESP32-**WROOM-32**, ~39×31 mm, micro-USB)"*. ⚠ the two docs disagree on USB-C vs micro-USB | `HARDWARE_INVENTORY.md`:96, :200 ; `w17-control-fw/docs/bill_of_materials_v2.md`:66 | **none found.** MH-ET LIVE is a marketplace store brand; it publishes no datasheet. Espressif's ESP32-WROOM-32 datasheet covers the *module*, not this *board* (LDO + USB-UART bridge + power LED are outside it) → **not usable.** The board's **onboard regulator marking is readable with no power applied** — see Q4 |
| RP1 receiver (S2) | **RadioMaster RP1 ELRS receiver** ("rp1-v2 rx") | `HARDWARE_INVENTORY.md`:83 ; `w17-control-fw/docs/bill_of_materials_v2.md`:33 | **manufacturer page fetched — NO CURRENT FIGURE.** radiomasterrc.com's RP1 page lists *"Working voltage: 5v"*, MCU, RF chip, weight, dimensions and refresh rates, and no mA/A anywhere |
| WS2812B strip (S3) | **WS2812B addressable LED strip, `Black PCB / 1m / 30 LED / IP30`**. ⚠ inventory qualifies it: *"(addressable WS2812B type to eyeball at wiring)"* — the type is to be confirmed at build time | `w17-control-fw/docs/bill_of_materials_v2.md`:73 ; `HARDWARE_INVENTORY.md`:99 | **YES, but revision-dependent.** **Jan-2016 V1.0** (*"WS2812B Datasheet and Specifications … Jan,2016 V1.0"*): its *RGB IC characteristic parameter* table has no current column, and its Electrical Characteristics give only *"Input current II  VI=VDD/VSS … ±1 µA"* — a DIN-pin leakage spec, not a supply current. **Mar-2017** (*WORLDSEMI CO., LIMITED — WS2812B Specifications — Mar-2017*): its **LED Characteristics** table publishes *"Operating Current(mA)"* = **16** for RED, GREEN and BLUE. **Neither revision publishes the per-pixel controller's quiescent supply current** |
| MAX98357A + speaker (S4) | **MAX98357A I2S amplifier** (owner-confirmed 2026-07-22); speaker **4 Ω 3 W** (*"impedance/power a bench spec-check"* — i.e. unverified) | `HARDWARE_INVENTORY.md`:97, :98 ; `w17-control-fw/docs/bill_of_materials_v2.md`:69, :71 | **YES** — Maxim Integrated, *MAX98357A/MAX98357B PCM Input Class D Audio Power Amplifiers*, fetched from the `cdn-shop.adafruit.com` **mirror** (Maxim-branded document; analog.com's own copy timed out twice) |
| Camera (S5) | **Camera — OpenIPC SSC338Q (MC800S-V3, IMX335 sensor)**, owned + already flashed; fed *"5 V→VDD5.0 from clean BEC Rail A"* | `HARDWARE_INVENTORY.md`:78 ; `w17-control-fw/docs/bill_of_materials_v2.md`:30, :202 | **none found** for MC800S-V3 + IMX335 at 5 V. (Search surfaced only IMX415 variants quoted at 12 V — a different sensor and a different rail; **refused**) |
| Wi-Fi module (S5) | **BL-M8812EU2 USB WiFi module `High-Power`** — the camera's video-link radio | `HARDWARE_INVENTORY.md`:74 ; `w17-control-fw/docs/bill_of_materials_v2.md`:22 | **YES** — B-link (Shenzhen Bilian Electronic), *BL-M8812EU2 datasheet*, document revision **V1.0**, official release 2023-10-27, fetched from a **mirror** (`jkrorwxhkqmllp5m-static.micyjz.com`; "V1.0.1.0" is the filename string, not the document's revision), corroborated by the LB-LINK product page |
| Blower (S6) | **Blower fan 5 V 20 mm** / BOM: *"Blower fan 5 V 20 mm (**ACP2006-class**)"* — a **class**, not a part number | `HARDWARE_INVENTORY.md`:170 ; `w17-control-fw/docs/bill_of_materials_v2.md`:145 | **not attempted — identity is explicitly a class.** Looking one up would be the family guess the rule forbids |
| MG90S ×3 (S7, S8) | **MG90S micro servos (3 pcs)** / BOM: `MG90S micro servos  90-180° / 3PCS`. **No manufacturer named** | `HARDWARE_INVENTORY.md`:122 ; `w17-control-fw/docs/bill_of_materials_v2.md`:91 | **doubly negative.** Identity is generic, *and* TowerPro's own MG90S page (fetched) lists weight, dimensions, stall torque, speed, temperature, deadband, wire and plug — and **NO CURRENT FIGURE**. It does give *"Operating voltage: **4.8V**"*, which is **below** Rail B's documented 5–6 V band. TowerPro's page itself warns of counterfeits, so even the brand cannot be assumed |
| Steering servo (S9) | **DSServo DS3235SG steering servo `180°`** (35 kg-class, 25T horn) | `HARDWARE_INVENTORY.md`:121 ; `w17-control-fw/docs/bill_of_materials_v2.md`:89 | **YES** — DS SERVO (Dongguan City Dsservo Technology Co., Ltd.) datasheet whose model line reads *"DS3235 / DS3235-180 / DS3235-270"*, fetched from a **mirror** (`hajim.rochester.edu`). **Provenance note (R-O6 N2):** page 1's product photograph shows the servo case labelled **"DS3235SG"** with the DSSERVO logo, so this **is** the DS3235SG's datasheet. The manufacturer's own download index still lists no DS3235 file, so no primary URL can be offered — a build-week visual check of the case marking closes it |
| ESC (D8 Phase 1) | **Hobbywing QuicRun 10BL120 + Rocket 540 V3 sensored combo `17.5T`**, product number **HW30125002** | `HARDWARE_INVENTORY.md`:90 ; `w17-control-fw/docs/bill_of_materials_v2.md`:62 ; `w17-control-fw/docs/00_BUILD_SHEET.md`:45 | **manufacturer page fetched** — the **Sensored G2** variant, which is the owner's unit (`w17-batch1-measurements-for-codex.md`:41, *"QuicRun 10BL120 **G2** ESC"*): *"BEC Output: Switch Mode 6V/7.4V @4A"*, *"2-3S Lipo"*, *"120A/Peak Current 760A"* — and **NO STANDBY CURRENT FIGURE** |
| Master switch (D8 Phase 1 inrush) | **Amass XT90-S anti-spark**, arrived as a two-piece pigtail set; the anti-spark (resistor) half is the female, facing the pack | `HARDWARE_INVENTORY.md`:203, :305 | **no manufacturer specification located** giving the pre-charge resistor value |
| Bench pack (D8 Phase 1) | **ZEEE 5200 mAh 2S LiPo — BENCH ONLY, not a car pack.** The only battery on hand; no in-envelope car pack exists | `HARDWARE_INVENTORY.md`:208, :182 | n/a — and **its C-rating is nowhere in the docs**. The `≥25 C` figure at `HARDWARE_INVENTORY.md`:277 is the *sourcing spec for the unbought car pack*, not this pack |
| Wi-Fi heatsink (Q10′) | **Heatsink 28×28×3 mm** — *"cooling heatsink for wifi module"* | `HARDWARE_INVENTORY.md`:76, :360 | n/a — but the **module's** datasheet §6.4 recommends *"The heat sink recommended size ≧ 32*32mm"*, and §3.1 requires that *"additional heat dissipation devices must be added by customers … Ensure that the junction temperature of module chipset is within rated value: Tj<125℃"*. See Q10′ |

### Topology facts that constrain every row below

- Rails: **A (clean)** = BL-M8812EU2 Wi-Fi, camera 5 V, ESP32 #1, ESP32 #2, RP1, WS2812 strip,
  MAX98357A, A3144 Hall VCC. **B (servos)** = DS3235SG, 3× MG90S, blower.
  (`w17-pdb-build-and-connector-guide.md`:51-53 — the **sole** authority for the MAX98357A
  and the A3144, because `w17-control-fw/docs/D8_BENCH_BRINGUP.md`:47's rail list omits both.)
- **Rail B's documented voltage band is 5–6 V, not 5 V**: *"Confirm BEC#1 ≈ 5 V, BEC#2 ≈ 5–6 V
  under a light load"* (`w17-control-fw/docs/D8_BENCH_BRINGUP.md`:55), carried as a PASS criterion on
  `bench-gates/BG-04_d8_bench_bringup.md` (Phase 1 row of its PASS/FAIL table) and in the
  manual (`learning-manual/03_hardware_and_electronics_basics.md`:39). Every servo figure
  below therefore has to name its voltage column.
- **The ESC's +5 V BEC red wire is CUT and insulated** — signal + GND only. The ESC's 4 A BEC
  therefore feeds **nothing**; it is not a rail source and cannot be a rail limit.
  (`w17-pdb-build-and-connector-guide.md`:80, :162-165;
  `w17-control-fw/docs/bill_of_materials_v2.md`:195; `w17-control-fw/docs/00_BUILD_SHEET.md`:32;
  `w17-control-fw/docs/D8_BENCH_BRINGUP.md`:38)
- **The supply is on the pack side.** BG-03's own *Topology (ASCII)* draws it as
  `bench PSU / pack --[XT90-S master]-- PDB --+-- UBEC A --> Rail A`. Any PSU current limit is a
  **7.4 V-side** limit; every load figure derived below is a **5 V rail** current.
- Bulk capacitance, and **which side of the UBEC it is on**: **C1 1000 µF across Rail B
  (+5 V ↔ GND)** and **C2 1000 µF at the WS2812 strip input (5 V ↔ GND at the first LED)** —
  **both on the 5 V side, downstream of the switching UBECs**
  (`w17-pdb-build-and-connector-guide.md`:119-120; `w17-control-fw/docs/00_BUILD_SHEET.md`:36
  supports **C1 only** — C2 comes from the PDB guide alone). What the **supply** sees at a
  connect is the **UBEC's input capacitance and soft-start**, not C1/C2 charging.
- Pack-side resistive load present from S0 onward: the **27 kΩ / 10 kΩ** battery divider
  (`w17-control-fw/docs/D8_BENCH_BRINGUP.md`:40).
- The ESC's 12 AWG direct feed to batt+ is part of **A2 gate S6**
  (`w17-pdb-build-and-connector-guide.md`:167-168). Separating it is a topology change,
  not a wiring convenience — see Q3.

---

## 3. The derivation

### 3.0 The margin, stated as a decision

> **Margin M-PEAK (proposed decision, not a fact).** For each load, take the **manufacturer's
> Max / peak column, never its Typ column**, and for the LED strip take the firmware model's
> **stated upper bound, never its actual draw**. Add **no further percentage**.
>
> **Rationale.** A percentage margin would be an invented number, which O-6 forbids. The
> typ→max gap is the manufacturer's own worst case and is itself cited, so using it *is* the
> margin and it carries a source. Where a load has no cited figure at all, no margin can rescue
> the row — the substep is BLOCKED, and that is the correct outcome rather than a smaller-looking
> one.
>
> **Direction, stated once so it cannot invert (R-O6 N4).** A current limit is a fuse: *lower*
> is more protective. M-PEAK picks the load's worst case so the limit is not set below a
> healthy draw; it is **not** a licence to pick the largest number a datasheet contains. Where
> a datasheet's headline figure is a **requirement on the supply** rather than an operating
> draw — the BL-M8812EU2's *"Peak current ≥1800mA"* (§6.2.1) is exactly that — it belongs in
> the never-exceed column, never in P(N).
>
> **The converse, which v2 got wrong (V-O6-2 B1).** A figure that *is* the part's own rated
> maximum draw belongs in **P(N)**, however large it looks. The same module publishes both:
> §6.2.1's *"Peak current ≥1800mA"* is a requirement on the supply, while §1.3's *"Power Supply
> DC 5.0V±0.25V @1800mA (Max)"* sits in the *General Specifications* table between `Dimension`
> and `Operation Temperature` and is the module's **maximum supply current** — precisely the
> Max column M-PEAK selects. A per-use-case RF-test peak from §3.3 is **not** an envelope and
> may not stand in for it.
>
> **Inrush is NOT covered by M-PEAK, and v1's carve-out is withdrawn.** v1 argued that C1/C2
> charging makes a momentary constant-current excursion the healthy signature. That argument is
> on the wrong side of the converter: **C1 and C2 are 5 V-side capacitors** (§2), while the
> supply is on the **7.4 V** side, where what it actually sees is the **UBEC's input
> capacitance and soft-start**. And *"momentarily"* is not a criterion — at a low starting limit
> the supply can hold the rail down so the UBEC never completes soft-start, which presents
> **exactly** as the *"the supply **sits** in constant-current"* fault the staircase's stop
> condition describes. **The discriminator is BLOCKED on owner ruling Q9.**

### 3.1 The chaining rule (what makes the staircase self-bootstrapping)

The supply's limit applies to **everything present**, not to the load just added. v1 wrote this
as `L(N) = R(N−1) + P(N)`, which under-limits whenever an already-present load's **peak**
exceeds the **settled** reading taken for it — and the BL-M8812EU2 spans 113 mA unassociated to
1510 mA peak, a factor of more than 13 on one part. The corrected rule is:

```
  L(N)  =  max( R(N-1),  Σ_{k<N} P(k) )  +  P(N)
```

where **R(N−1)** is the *settled total recorded minutes earlier in the same session* after
substep N−1, **P(k)** is the cited peak of the load added at substep k, and the sum runs over
every load already present. **A settled reading is never a bound on a bursty load**: a settled
reading may stand in for a load only where **no** cited peak exists for it; any load with a
cited peak contributes its **peak** at every later substep. Only **L(0)** and **L(1)** need a
number that no measurement can supply. P(N) is what this pass could derive offline; R(N−1) is
what the staircase itself creates.

**The domain the rule lives in (R-O6 B2).** L(N) is a **pack-side (7.4 V)** supply setting;
every P(N) below is a **5 V rail-side** current. They are not interchangeable. The pack-side
never-exceed corresponding to a rail rated 5 A is

```
  I_pack  ≤  5 A × V_rail / (V_pack × η)
```

with **η the UBEC's conversion efficiency — unknown, because no document names the UBEC**. Set
naively at the rail's own 5 A, a pack-side limit would permit roughly 7 A of 5 V-rail current at
a high η: **40 % above the rating it is supposed to protect**. Until Q2 is answered, **the
pack-side never-exceed is BLOCKED**, and no 5 V figure in this report may be dialled into the
supply. Consequently the table below reports **P(N) as DERIVED or BLOCKED**, and reports
**L(N) as BLOCKED for every N**.

### 3.2 The staircase (order per `bench-gates/tools/first_power_current_limits.md`, step 3)

Every row is **NOT-EXECUTED**. `[code]` = compile-time constant/model in this project.
`[doc]` = rating already cited in this project with a path:line. `[datasheet]` = manufacturer
document fetched 2026-09-06, quoted.

> **Domain warning — read before using any number in this table.** Every figure in the
> **P(N)** and **NEVER-EXCEED** columns is a **5 V rail-side** current. **None of them is a
> bench-PSU setting.** The supply sits on the pack side; see §3.1 for the conversion and why it
> is BLOCKED.

| # | Substep | Loads present (Rail A / Rail B / batt+) | Admissible cited figure(s) for the load being **added** | **P(N)** — added-load allowance under M-PEAK (**5 V side**) | Absolute starting limit **L(N)** (**pack side**) | NEVER-EXCEED | Status |
|---|---|---|---|---|---|---|---|
| **S0** | Bench PSU + PDB alone, nothing on the rails | A: — · B: — · batt+: 2× UBEC input, 27k/10k divider, **and the ESC unless its 12 AWG feed is separated** | Divider: **27 kΩ + 10 kΩ = 37 kΩ** `[doc `D8`:40]` → at 7.4 V, **0.20 mA**; at 8.4 V, **0.23 mA** (Ohm's law on cited resistors). UBEC quiescent: **none — no model**. ESC standby: **none — Hobbywing publishes no standby figure** | **BLOCKED** — divider term derived, UBEC and ESC terms absent. (This one row is genuinely pack-side) | **BLOCKED.** The staircase's own answer is *"the lowest setting the supply offers"* (step 1), which is a **procedure that still needs the PSU's minimum settable CC value** — and no document names the PSU | PSU's own limits — **unknown**. XT60/XT90/12 AWG are not the binding limit | **BLOCKED** → Q1, Q3 |
| **S1** | + Rail A: ESP32 #1 and #2, idle | A: 2× MH-ET D1-mini · B: — · batt+: as S0 | **NONE.** MH-ET LIVE publishes no datasheet. The Espressif ESP32-WROOM-32 datasheet covers the module, not the board's LDO / USB-UART bridge / power LED — **refused as a family figure** | **BLOCKED** | **BLOCKED** (and this block propagates to S2–S5 and S9, all of which keep the boards powered) | Rail A output **5 A** `[doc `HARDWARE_INVENTORY.md`:113]` — **5 V side, NOT a PSU setting**. A ramp with only the rail's 5 A above it is **not** a ceiling: 5 A into two D1-mini boards destroys them long before the rail notices | **BLOCKED** → Q4 (ramp ceiling required) |
| **S2** | + RP1 receiver | A: + RP1 · B: — | **NONE.** RadioMaster's own product page lists working voltage 5 V and no current figure at all (fetched 2026-09-06) | **BLOCKED** | **BLOCKED** (inherits S1) | Rail A output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting**; same objection as S1 | **BLOCKED** → Q4 (ramp ceiling required) |
| **S3a** | + WS2812 strip, **at the O-7 operating cap 180** | A: + 30-pixel strip (+ C2 1000 µF) · B: — | `kNumPixels = 30` `[code `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11]`; model `perLedMa = (2·20·renderedDuty(255, cap))/255` `[code :226]`; γ-LUT `[code :90-98, :102, :110-111]`. The **20 mA/channel is an uncited code comment** `[code :205]`, not a manufacturer figure. Worldsemi **Mar-2017** *LED Characteristics* gives **16 mA/channel** — which **bounds the code's model from below** | **DERIVED = 560 mA — an upper bound on the strip's *emitter* current only** (un-truncated model bound; the code's integer form gives **540 mA**). **Excludes each pixel's controller quiescent draw**, which neither Worldsemi revision publishes: carry it as a **named unquantified adder**. Cross-check at 16 mA/channel: **448 mA**. Arithmetic in §4 | **BLOCKED** (inherits S1/S2) | Compile budget **900 mA** `[code :209, checked :242]`; Rail A output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| **S3b** | + WS2812 strip, **at the shipped value** | as S3a | Shipped `maxBrightness = **110**` **verified in code** `[code :152]` | **DERIVED = 188 mA**, same emitter-model caveat and the same unquantified controller adder (code integer form **180 mA**, which is exactly row L5 of the existing table) | **BLOCKED** (inherits S1/S2) | as S3a | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| **S4** | + MAX98357A amp (+ speaker) | A: + amp + 4 Ω speaker · B: — | `[datasheet]` Maxim MAX98357A/B: *"Quiescent Current IDD … TA = +25°C … 2.75 [typ] 3.35 [max] mA"*; *"Standby Current ISTNDBY  SD_MODE = 1.8V, no BCLK, TA = +25°C  340  400  µA"*; *"Shutdown Current ISHDN … 0.6  2  µA"*; *"Output Power … ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB … 3.2 [W]"*; *"Efficiency ε  ZSPK = **8Ω** + 68µH … 92 %"*; *"Current Limit ILIM  2.8 A"* | **PARTIAL, bounded both ways.** Quiescent **DERIVED = 3.35 mA** (not driven). **When driven, DERIVED ≥ 640 mA**: conservation of energy on the datasheet's own 3.2 W into 4 Ω at VDD = 5 V needs **no** efficiency figure (3.2 W / 5 V). Upper-bounded by the cited **ILIM = 2.8 A**. A **settable point value is still BLOCKED**: the shipped `sound.volume` is not yet recorded (it is created at D8 Phase 11a; the link2 wire default `kDefaultVolume = 80` `[code `w17-soundlight-fw/lib/link2/include/link2/Link2Frame.hpp`:93]` is a protocol default, **not** the shipped tune), and the only cited efficiency is at **8 Ω**, not the 4 Ω speaker the BOM specifies | **BLOCKED** | Amp's own **ILIM = 2.8 A** `[datasheet]`; Rail A output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **BLOCKED** → Q6 (bounds DERIVED) |
| **S5** | + camera / Wi-Fi module | A: + camera 5 V + BL-M8812EU2 · B: — | `[datasheet]` B-link BL-M8812EU2 V1.0, §1.3: *"Power Supply  DC 5.0V±0.25V @1800mA (Max)"*; §6.2.1: *"Peak current **≥1800mA**; For achieve fast transient response, a current mode buck converter DC/DC recommended"*; §3.3 Current Consumption (VDD5.0 = DC 5.0 V, Ta 25 °C), Typ (IRMS) / Max (IPeak): *"WLAN Unassociated … 113 / 123 mA"*; *"WLAN TX/RX TCP throughput 300Mbps … 732 / 928 mA"*; *"HT20 MCS8 TX @ 27.5 dBm (2TX RF test) … 927 / **1510** mA"*. **Camera: no figure** | **PARTIAL.** Wi-Fi module **DERIVED = 1800 mA** — §1.3's *"@1800mA (Max)"* is the module's **own maximum supply current** (the Max column M-PEAK takes), so it is the added-load allowance **until Q5 names the RF mode**; once the mode is named the applicable §3.3 row may replace it. The largest **per-use-case** IPeak in §3.3 is **1510 mA** (HT20 MCS8 TX @ 27.5 dBm, 2TX RF test — the 2T2R configuration the project builds, `w17-pdb-build-and-connector-guide.md`:89); it is one test case, **not an envelope**, and is quoted here only as that. **Camera BLOCKED** | **BLOCKED** | Module's own **supply-capability requirement: the rail must be able to deliver ≥ 1800 mA peak** (§6.2.1) — a requirement on the supply, **not** a limit to set (§1.3's numerically identical 1800 mA is a different claim: the module's own Max draw, and it is the P(N) figure); Rail A output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **BLOCKED** → Q5 |
| **S6** | + Rail B blower (always-on) | A: as S5 · B: + blower (+ C1 1000 µF) | **NONE.** The BOM names an *"ACP2006-**class**"* part, not a part number | **BLOCKED** | **BLOCKED** | Rail B output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **BLOCKED** → Q7 |
| **S7** | + one MG90S | B: + 1 servo | **NONE.** Generic MG90S; TowerPro's own page publishes no current figure, and quotes *"Operating voltage: 4.8V"* — **below** Rail B's documented 5–6 V band | **BLOCKED** | **BLOCKED** | Rail B output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting**; as with S1, the rail's own rating is not a ceiling for one micro servo | **BLOCKED** → Q8 (ramp ceiling required) |
| **S8** | + remaining two MG90S | B: + 2 servos | **NONE** (as S7) | **BLOCKED** | **BLOCKED** | as S7 | **BLOCKED** → Q8 (ramp ceiling required) |
| **S9a** | + DS3235SG, **holding centre, no load** (**T3**) | B: + steering servo | `[datasheet]` DS SERVO *"DS3235 / DS3235-180 / DS3235-270"*, §4 Electrical Specification: *"3-1 Idle current (at stopped) … **5mA** 5mA 5mA"* across the 5 V / 6 V / 7.4 V columns; §1-3 *"Operating Voltage Range 5-7.4V"* | **DERIVED = 5 mA** — the datasheet gives the same figure in all three voltage columns, so this row does not depend on which column Rail B lands in | **BLOCKED** | Servo **stall 2.1 A at 6 V** (**1.9 A at 5 V, 2.3 A at 7.4 V**) `[datasheet]` — Rail B's documented band is **5–6 V** (`D8`:55; BG-04's Phase 1 PASS row), so **2.1 A** is the applicable column until BEC#2's actual output is recorded; Rail B output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **P(N) DERIVED**, L(N) **BLOCKED** |
| **S9b** | + DS3235SG, **deliberate full-lock sweep, linkage OFF** (**T4**) | B: as S9a | `[datasheet]` *"3-4 Stall current (at locked)"*: **1.9A / 2.1 A / 2.3A** at 5 / 6 / 7.4 V. **The datasheet gives no running / no-load current** — row 3-2 is a *speed*, not a current | **BLOCKED for the expected draw** (a linkage-off sweep is neither idle nor stall, and no cited figure covers it). **Ceiling DERIVED = 2.1 A at 6 V**, selected from the recorded BEC#2 voltage | **BLOCKED** | **2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V) — this is the number C1 exists for (`00_BUILD_SHEET.md`:36; PDB guide:119); Rail B output **5 A** `[doc :113]` — **5 V side, NOT a PSU setting** | **ceiling DERIVED**, expected draw **BLOCKED** |

### 3.2a One BG-03 powered step outside the staircase (R-O6 N8)

The staircase's S9b is the **linkage-off** sweep. BG-03 carries a second, later steering step
with the linkage **fitted**, and that is the one where the stall figure is actually
load-bearing — a bind drives the servo toward stall under real mechanical load, which a
linkage-off sweep cannot.

| # | Substep | Loads present | Admissible cited figures | P(N) | L(N) | NEVER-EXCEED | Status |
|---|---|---|---|---|---|---|---|
| **B3.1** | *"Narrow steering endpoints to the linkage's mechanical travel; **sweep full L/R with the linkage fitted** — no bind, no stall"* (BG-03, step B3.1) | Everything S9b had, plus the steering linkage | As S9b: idle **5 mA**, stall **1.9 / 2.1 / 2.3 A** at 5 / 6 / 7.4 V `[datasheet]`. **No cited figure covers a linkage-loaded sweep** | **BLOCKED** — a loaded sweep is neither idle nor stall | **BLOCKED** | **Inherits S9b's ceiling at the rail's set voltage** — i.e. the stall column selected from the recorded BEC#2 output (**2.1 A** if Rail B sits at 6 V); Rail B output **5 A** — **5 V side, NOT a PSU setting** | **ceiling INHERITED**, expected draw **BLOCKED** |

### 3.3 BG-04 / D8 Phase 1 — the substeps that precede or differ from the staircase's

D8 Phase 1 is *"the first battery connection of this bring-up"* (`w17-control-fw/docs/D8_BENCH_BRINGUP.md`:51-57).
It differs from the staircase in one decisive way: **it is written around the battery, and a
battery has no settable current limit at all.**

| # | Substep (D8 Phase 1) | What is present | Admissible figures | Starting limit | NEVER-EXCEED | Status |
|---|---|---|---|---|---|---|
| **D8-1a** | The moment the pack is mated at the XT90-S (**T13, inrush**) | Pack → XT90-S → PDB → ESC + UBEC A + UBEC B | **None.** No document states the ESC's input capacitance or the **UBEC's input capacitance and soft-start behaviour** — which is what the supply actually sees on the 7.4 V side; no Amass specification for the XT90-S pre-charge resistor was located; the bench pack (ZEEE 5200, `HARDWARE_INVENTORY.md`:208) has **no C-rating in any document** — the `≥25 C` at `:277` is the sourcing spec for the *unbought car pack*, not this one. **C1 and C2 are 5 V-side capacitors and are not this event** | **BLOCKED — and there is no limiting device in the path.** A pack does not current-limit. The only thing bounding this event is the XT90-S's own pre-charge resistor, whose value is unstated | **Not derivable.** The anti-spark part exists precisely *because* the inrush is large, and the documents bound it **not at all** — neither above nor below | **BLOCKED** → Q9 |
| **D8-1b** | ESC standby on batt+, motor leads off (**T12**) | ESC logic energised; motor disconnected | **None.** Hobbywing's own page (Sensored G2, the owner's variant) gives 120 A/760 A, 2-3S, *"BEC Output: Switch Mode 6V/7.4V @4A"* and **no standby figure** | **BLOCKED** | ESC BEC 4 A is **irrelevant** — the red wire is cut (`PDB guide`:80), so the BEC feeds nothing | **BLOCKED** → Q3 |
| **D8-1c** | *"Confirm BEC#1 ≈ 5 V, BEC#2 ≈ 5–6 V **under a light load**, before connecting the ESP32s"* (`D8`:55) | Both UBECs, no ESP32s | **None.** *"a light load"* is undefined in every document, and no UBEC model exists to say what load makes its regulation valid. **This step is also where BEC#2's actual output voltage gets recorded**, which selects the servo stall column for S6–S9 and B3.1 | **BLOCKED** | Rail output **5 A** each `[doc :113]` — **5 V side, NOT a PSU setting** | **BLOCKED** → Q2 |

> **A doc conflict worth surfacing while it is cheap.** BG-03's *Required equipment* permits
> *"A bench PSU **or** the battery via the XT60 split"*; `D8`:55 writes Phase 1 as battery-only.
> Choosing the PSU for the first energisation is the only option that has a current limit at
> all — see Q3.

---

## 4. The LED recompute at the O-7 cap of 180 — full arithmetic

**Inputs, all compile-time, all in `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:**

- `kNumPixels = 30` — `:11`
- shipped `maxBrightness = 110` — `:152` (**verified in code**)
- `kBudgetMilliamps = 900` — `:209`, enforced by `(perLedMa * kNumPixels) <= kBudgetMilliamps` at `:242`
- `renderedDuty(ch, cap) = kGamma.v[ch·cap/255]` — `:110-111` (**cap applied before gamma**)
- `kGamma.v[i] = (int)(255·(i/255)^2.2 + 0.5)`, clamped 0..255 — `:90-98`, `:102`
- model: `perLedMa = (2u * 20u * renderedDuty(255, maxBrightness)) / 255u` — `:226` (**integer** division)
- **the 20 mA/channel is an uncited code comment** — `:205`, *"WS2812 ~ 20 mA/channel at full duty"*
- hazard colour `kAmber{255, 90, 0}` — `w17-soundlight-fw/lib/lights/src/LightRenderer.cpp`:21

**Method note.** I did not do this by hand. I copied the header's own `gamma_detail` block
verbatim into a standalone C++17 program in the session scratchpad and compiled it, so the LUT
below is the project's own constexpr pipeline, not a re-implementation of it. The reviewer
independently reproduced every figure in this section by the same method.

**At the ruled operating cap 180 (O-7):**

```
  index      = 255 · 180 / 255                     = 180
  (180/255)                                        = 0.70588235
  0.70588235 ^ 2.2                                 = 0.4647424
  255 · 0.4647424                                  = 118.509
  kGamma[180] = (int)(118.509 + 0.5)               = 119        <- renderedDuty(255, 180)

  perLedMa    = (2 · 20 · 119) / 255 = 4760/255 = 18.667 -> 18   (integer division, as in code)
  strip       = 18 mA x 30 px                      = 540 mA      <- the code's modelled worst case
  strip (un-truncated)  = 18.667 mA x 30           = 560.0 mA    <- emitter-model upper bound

  valid() check: 540 <= 900  ->  PASSES
```

**At the shipped value 110 (verified `:152`):**

```
  kGamma[110] = 40   (= renderedDuty(255,110))
  perLedMa    = (2 · 20 · 40)/255 = 1600/255 = 6.275 -> 6
  strip       = 6 mA x 30 = 180 mA        <- reproduces row L5 exactly
  strip (un-truncated) = 6.275 x 30 = 188.2 mA
```

**Manufacturer cross-check on the one constant the model does not cite (R-O6 B6).** The
Worldsemi **Mar-2017** WS2812B *LED Characteristics* table gives **16 mA/channel** operating
current for all three colours. Substituting it for the code comment's 20 mA at cap 180:

```
  2 · 16 · 119 / 255 = 14.933 mA/LED  ->  x 30 px = 448 mA
```

so the manufacturer's figure **bounds the code model from below**: the firmware's 560 mA is the
more protective of the two, by about a quarter. The **Jan-2016 V1.0** revision has no such
column — v1's blanket "Worldsemi supplies nothing" was true only of that revision.

**What 560 mA is, precisely (R-O6 B7).** It is an upper bound on the strip's **emitter**
current under the firmware's own model. It is **not** an upper bound on the strip, because
**each pixel's controller draws current at zero duty** and neither Worldsemi revision publishes
that figure. (The *"Input current II … ±1 µA"* in the Jan-2016 Electrical Characteristics is a
DIN-pin leakage spec, not a supply current.) That term is carried below as a named unquantified
adder rather than treated as absent.

**Actual all-amber hazard draw (not the model — the palette's real worst state):**

| cap | duties R/G/B for `kAmber{255,90,0}` | actual mA/LED = 20·(R+G+B)/255 | × 30 px |
|---|---|---|---|
| **110 (shipped)** | 40 / 4 / 0 | 3.451 | **103.5 mA** — reproduces row L6's *"≈ 104 mA"* |
| **180 (O-7)** | 119 / 12 / 0 | 10.275 | **308.2 mA** |
| 227 (compile ceiling) | 197 / 20 / 0 | 17.020 | 510.6 mA |

**A corroboration v1 claimed and v2 withdraws (R-O6 N1).** v1 read the 510.6 mA above as
reproducing the code's *"510 mA"*. It does not. The code's 510 mA is the **pre-gamma** model at
the **shipped cap 110** — `(2·20·110)/255 = 17` mA/LED × 30 — stated at `LightRenderer.hpp`:**214-215**
as the over-count the current model replaced. v2's 510.6 mA is the **post-gamma actual
all-amber draw at cap 227**. Two different quantities that collide numerically; the claim was
not an independent check and is dropped.

**Cost of the O-7 ruling, stated plainly:** raising the cap 110 → 180 costs **+360 mA** on the
model (180 → 540 mA) and **+205 mA** on the real all-amber state (103.5 → 308.2 mA), on Rail A.
`BG-08_dim_light_halo.md`:217-224 already tabulates 180 → 540 mA; this pass reproduces it
independently and adds the actual-draw column, which BG-08 does not have.

**What that does to Rail A's budget — a floor, not a total.** Summing **only** the loads that
now have an admissible figure, each at its worst applicable cited case (v1 mixed worst-case and
quiescent terms in the same column; R-O6 N3):

```
  BL-M8812EU2   1800 mA   [datasheet, §1.3 rated maximum supply current — the part's own Max;
                           §3.3's largest per-use-case peak, 1510 mA, is not an envelope]
  WS2812 @ 180   560 mA   [code model, EMITTER upper bound]
                        + per-pixel controller quiescent: UNQUANTIFIED (no revision publishes it)
  MAX98357A      640 mA   [datasheet, energy-conservation LOWER bound when driven: 3.2 W / 5 V;
                           3.35 mA when not driven; ILIM 2.8 A above]
  ------------------------
              >= 3000 mA  =  >= 60 % of UBEC A's 5 A rating
```

with **ESP32 #1, ESP32 #2, RP1, the camera, the A3144 Hall and the strip's controller term still
unquantified**. This is a **floor on the rail total, not the rail total**, and it sits higher
than v1's figure precisely because the amp is no longer entered at its quiescent 3.35 mA on a
car whose whole point is engine sound. It is the first time this project
has had any number at all for Rail A, and it says the headroom is real but not generous — which
is exactly the *"check the **UBEC headroom** before raising the cap"* instruction at
`BG-08_dim_light_halo.md`:110 and `w17-soundlight-fw/docs/SIMULATION.md`:49-53, now with one side of the
comparison filled in.

---

## 5. Owner questions — smallest and cheapest first

Each names what it unblocks. **Q1 and Q2 are the two that convert the whole staircase from
blocked to runnable**; everything after them narrows individual rows. Q4, Q8 and Q9 ask for a
**number the owner rules**, because no citable figure exists and the alternative is an
unbounded procedure.

1. **Q1 — Which bench power supply do you have, and what is the smallest current limit it can be
   set to (and does it have a settable limit at all)?** *Unblocks: S0, and with it the first
   number the entire staircase asks for; no document anywhere names the PSU.*
2. **Q2 — Which UBEC is it (make/model, or a photo of the label), and what output voltage is
   BEC#2 set to — 5 V or 6 V (jumper position or label)?** *Unblocks: (i) the pack-side ↔
   rail-side conversion every one of S1–S9 needs — the UBEC's own datasheet supplies η once the
   model is known, which is why there is no separate efficiency question; (ii) D8-1c's undefined
   "light load"; (iii) which stall column applies to S9a/S9b/B3.1 — 1.9 A at 5 V or 2.1 A at
   6 V.* **The bench still records BEC#2's measured output at D8-1c before S6–S9**; the label
   answer is what lets the card carry a number beforehand.
3. **Q3 — For the first energisation, do you accept using the bench PSU rather than the battery
   (BG-03's Required equipment already permits it, D8:55 says battery), and can the ESC's 12 AWG
   feed be physically separated at the PDB so it is absent for S0–S9?** *Unblocks: S0 (removes
   the unquantified ESC standby term), D8-1a and D8-1b (a supply has a limit; a pack does not).*
   **Consequence to accept with it:** that feed is part of **A2 gate S6**
   (`w17-pdb-build-and-connector-guide.md`:167-168), so separating it is a **topology change** —
   A2's batt+ rows **P2 / P4 / P5**
   (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`:237-241) must be re-run
   **before and after**, and the change recorded.
4. **Q4 — S1/S2 characterisation, under a ceiling.** The staircase's own ramp technique is
   authorised for the **empty-rail** case only, and it is legitimate *because* it stops at a
   ceiling. Extending it to a loaded substep without one is "raise until it works". So, smallest
   question first: **with no power applied, read the marking on the MH-ET board's onboard
   voltage regulator** (a small three-pin part near the USB connector, typically an
   "AMS1117-3.3"-type LDO) **and tell me what it says** — that part's own datasheet output
   maximum then becomes a **derivable** ramp ceiling for S1, with a citation. **If the marking
   is unreadable or absent, rule a number:** the S1 ramp ceiling in mA, above which the step is
   a fault regardless. **For S2 there is no regulator to read** (the RP1 is a sealed receiver
   with no published current figure at all), so **rule the S2 ceiling** as a number. *Unblocks:
   S1 and S2, the only two rows where no datasheet will ever exist.*
5. **Q5 — At what RF power / mode will the BL-M8812EU2 actually run on the car, so the right row
   of its datasheet applies (unassociated 123 mA peak, TX/RX 300 Mbps 928 mA peak, or 2TX
   1510 mA peak)?** *Unblocks: S5's Wi-Fi term, and tells you whether Rail A is comfortable or
   tight.* **Absent an answer, `P(5) = 1800 mA`** — §1.3's *"Power Supply DC 5.0V±0.25V
   @1800mA (Max)"* is the module's own rated maximum supply current, and no single §3.3 row is
   an envelope. Name the mode and the applicable §3.3 row **may** replace it. Note separately
   that the datasheet also **requires the supply to be capable of ≥ 1800 mA peak** (§6.2.1) —
   that is a never-exceed / supply-sizing figure, not a limit to dial in. The two 1800 mA
   figures are different claims that happen to coincide.
6. **Q6 — What `sound.volume` will ship, and is the speaker confirmed 4 Ω (the inventory calls
   its impedance "a bench spec-check")?** *Unblocks: S4's settable output-driven term.* The
   bounds are already derived without it: **3.35 mA** quiescent, **≥ 640 mA** whenever the amp
   is actually driven, **ILIM 2.8 A** above.
7. **Q7 — What is the blower's actual part number (a photo of the fan label)?** *Unblocks: S6 —
   the BOM only names an "ACP2006-class" part, which is a class, not a part.*
8. **Q8 — Are the MG90S servos a branded part with a readable label?** *If yes, name it and S7/S8
   may resolve from its datasheet.* **If not — and TowerPro's own page publishes no current
   figure even for the genuine article, so this is the likely case — rule the S7/S8 ramp ceiling
   as a number**, the same shape as Q4. *Unblocks: S7 and S8.*
9. **Q9 — Rule the constant-current duration criterion for a connect.** Every connect will pull
   the supply into constant current briefly; on the **7.4 V** side that is the **UBEC's input
   capacitance and soft-start**, not C1/C2 (which are 5 V-side capacitors, downstream of the
   UBECs). v1 offered *"momentarily enters, then leaves"* as the discriminator; that is not a
   criterion, and at a low starting limit the supply can hold the rail down so the UBEC never
   completes soft-start — which looks exactly like the fault. **Rule it in this shape: "constant
   current persisting longer than _N_ after a connect, or constant current that has not cleared
   by the time the rail reaches nominal, is a STOP."** *N is yours to set; this report proposes
   no value.* *Unblocks: the stop condition for every connect in the staircase, and D8-1a's
   only non-numeric mitigation.*
10. **Q10′ — The Wi-Fi module's heatsink is smaller than its datasheet recommends. Source a
    larger one, or accept the fitted one with a documented thermal check at first power?** The
    module's datasheet §6.4 recommends *"heat sink recommended size ≧ 32*32mm"*, and §3.1 states
    that *"additional heat dissipation devices must be added by customers … Ensure that the
    junction temperature of module chipset is within rated value: Tj<125℃"*. The fitted part is
    **28×28×3 mm** (`HARDWARE_INVENTORY.md`:76, :360), and the project's own rule is *"heatsink
    fitted before first power-on"*
    (`learning-manual/05_control_firmware_documentation_explained.md`:362;
    `learning-manual/03_hardware_and_electronics_basics.md`:223). *Found inside O-6's own source
    and gating the same first power-on; strictly outside O-6's scope, which is why it is asked
    rather than decided.*

**Dropped from v1's set: Q10 (the servo case marking).** Page 1 of the DS3235 datasheet this
report cites shows a case labelled **"DS3235SG"**, so the question is already answered by the
source. What remains is a one-line provenance note (§2) and a **build-week visual check** of the
case marking — not an owner decision.

---

## 6. Proposed verbatim text

### 6.1 New subsection for `bench-gates/BG-03_phase_b_first_power.md`

*Suggested placement: immediately after "Required equipment", before "Topology (ASCII)".*

```markdown
## Starting current limits (O-6 derivation, 2026-09-06)

**Evidence label: NOT-EXECUTED.** Nothing below has been measured. O-6 (owner, 2026-09-05)
ratified the staircase policy and forbade inventing an initial amperage; this subsection is
the offline derivation that ruling required, and it ends in BLOCKED rows on purpose.

**The policy, in force:** lowest defensible limit for the substep · a current-limit trip is
**STOP AND DIAGNOSE** · never simply increase until it works · increase only after the trip
is understood and the next setting is justified · never exceed the applicable rail/component
limit.

> **DOMAIN WARNING — read before using any number here.** Every figure in the P(N) and
> NEVER-EXCEED columns below is a **5 V rail-side** current. **None of them is a bench-PSU
> setting.** The supply sits on the **pack side (7.4 V)**; the pack-side never-exceed that
> corresponds to a 5 A rail is `I_pack <= 5 A * V_rail / (V_pack * eta)`, where `eta` is the
> UBEC's conversion efficiency — **unknown, because no document names the UBEC**. Dialling a
> 5 A rail figure into a pack-side supply would permit roughly 7 A of rail current at a high
> efficiency: 40 % above the rating it is meant to protect.

**The margin, named:** *M-PEAK* — take each load's manufacturer **Max/peak** figure (never
Typ) and the LED model's **stated upper bound** (never its actual draw); add no percentage.
A percentage would be an invented number; the typ→max gap is the manufacturer's own worst
case and it carries a citation. **Direction:** a limit is a fuse, so *lower* is more
protective; M-PEAK exists so the limit is not set below a healthy draw, and a datasheet
figure that is a **requirement on the supply** (the Wi-Fi module's "Peak current ≥1800mA",
its §6.2.1) belongs in never-exceed, never in P(N) — while a figure that **is** the part's own
rated maximum draw (the same module's §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)") belongs
in P(N), however large it looks.

**Inrush is NOT covered by M-PEAK, and the criterion is BLOCKED.** Every connect pulls the
supply into constant current briefly. On the **7.4 V** side that is the **UBEC's input
capacitance and soft-start** — **C1 (Rail B) and C2 (strip input) are 5 V-side capacitors,
downstream of the UBECs, and are not what the supply sees**. "Momentarily" is not a
criterion: at a low starting limit the supply can hold the rail down so the UBEC never
completes soft-start, which presents exactly as the "the supply **sits** in constant-current"
fault. **The duration criterion is an owner ruling (Q9), in the shape "constant current
persisting longer than N after a connect, or constant current that has not cleared by the
time the rail reaches nominal, is a STOP."** Until it is ruled, treat any constant-current
event you cannot explain as a STOP.

**The chaining rule:** the limit applies to everything present, so
`L(N) = max( R(N-1), SUM of P(k) for k < N ) + P(N)`, where `R(N-1)` is the settled total
recorded minutes earlier in this same session and `P(k)` is the cited peak of the load added
at substep k. **A settled reading is never a bound on a bursty load** — a settled reading may
stand in for a load only where no cited peak exists for it (the Wi-Fi module alone spans
113 mA unassociated to 1510 mA peak). Only L(0) and L(1) need a number no measurement can
supply.

**Two facts that block every absolute value, and are not lookups:**
1. **No document names the bench PSU** (`13_phase_a_a2_no_power_checklist.md`:116 says only
   "have them, do not connect them"), so its minimum settable constant-current value — the
   literal first number the staircase's step 1 asks for
   (`bench-gates/tools/first_power_current_limits.md`:112-114) — is unknown, and it is not
   established that it has a settable limit at all.
2. **The supply is on the pack side (7.4 V) and every derived load figure is a 5 V rail
   current** (this card's own *Topology (ASCII)* section). Converting between them needs the
   UBEC's efficiency, and **no document names the UBEC's make or model** — only "UBEC 5 A
   (2 pcs)" (`HARDWARE_INVENTORY.md`:113).

**Bench pre-step for every Rail-B row:** at D8 Phase 1, **record BEC#2's actual output
voltage** before S6–S9 and B3.1, and select the servo stall column from it. Rail B's
documented band is **5–6 V** (`D8_BENCH_BRINGUP.md`:55; this card's sibling
`BG-04_d8_bench_bringup.md` PASS row for Phase 1), not 5 V.

| Substep | Added-load allowance P(N) — **5 V side** | Absolute limit L(N) — **pack side** | Never-exceed — **5 V side, NOT a PSU setting** | Status |
|---|---|---|---|---|
| S0 PDB alone | divider 37 kΩ → **0.20 mA at 7.4 V** (0.23 mA at 8.4 V) — **this one row is genuinely pack-side**; UBEC quiescent and ESC standby absent | — | PSU's own limits (unknown) | **BLOCKED** — needs the PSU's minimum settable limit |
| S1 + ESP32 #1/#2 idle | — | — | Rail A output **5 A** — and the rail's rating is **not** a ramp ceiling for two D1-mini boards | **BLOCKED** — MH-ET LIVE publishes no datasheet; the WROOM-32 module datasheet is not the board. A ramp needs the ceiling Q4 asks for |
| S2 + RP1 | — | — | Rail A output **5 A** — same objection as S1 | **BLOCKED** — RadioMaster's own page gives 5 V and no current figure. A ramp needs the ceiling Q4 asks for |
| S3 + WS2812 strip @ cap **180** | **560 mA** — **emitter-model** upper bound (code's integer form 540 mA); **excludes each pixel's controller quiescent draw, which Worldsemi does not publish** — carry it as an unquantified adder | — | compile budget **900 mA**; Rail A output **5 A** | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S3 + WS2812 strip @ shipped **110** | **188 mA** — same emitter-model caveat (code's integer form 180 mA) | — | as above | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S4 + MAX98357A + speaker | quiescent **3.35 mA max**; **≥ 640 mA whenever driven** (energy conservation on 3.2 W into 4 Ω at 5 V — no efficiency figure needed) | — | amp **ILIM 2.8 A**; Rail A output **5 A** | **BLOCKED** for a settable point value — shipped `sound.volume` unrecorded; the only cited efficiency is at 8 Ω, not the 4 Ω speaker. **Both bounds DERIVED** |
| S5 + camera / Wi-Fi | Wi-Fi **1800 mA** — the module's own §1.3 rated maximum supply current, which stands until the RF mode is named (Q5); §3.3's largest per-use-case peak, 1510 mA, is one RF-test case and not an envelope. Camera term absent | — | module requires the rail to **deliver ≥ 1800 mA peak** (its §6.2.1) — a supply-capability requirement, not a limit to set; Rail A output **5 A** | **BLOCKED** — no figure for the OpenIPC SSC338Q at 5 V |
| S6 + blower | — | — | Rail B output **5 A** | **BLOCKED** — the BOM names an "ACP2006-class" part, not a part number |
| S7 + one MG90S | — | — | Rail B output **5 A** — not a ramp ceiling for one micro servo | **BLOCKED** — generic part; TowerPro's own page publishes no current figure and quotes 4.8 V operating, below Rail B's band. A ramp needs the ceiling Q8 asks for |
| S8 + remaining MG90S | — | — | Rail B output **5 A** | **BLOCKED** — as S7 |
| S9 DS3235SG holding centre (T3) | **5 mA** (datasheet idle-at-stopped; identical in all three voltage columns) | — | servo **stall 2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — select from the recorded BEC#2 voltage); Rail B output **5 A** | **P(N) DERIVED**, L(N) **BLOCKED** |
| S9 DS3235SG full-lock sweep, linkage OFF (T4) | — (no running-current figure exists; the datasheet gives only idle and stall) | — | **2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — select from the recorded BEC#2 voltage) — this is the number C1 exists for | **ceiling DERIVED**, expected draw **BLOCKED** |
| **B3.1** full L/R sweep **with the linkage fitted** | — (a loaded sweep is neither idle nor stall) | — | **inherits the S9 sweep ceiling at the rail's set voltage** — a bind drives the servo toward stall under real mechanical load | **ceiling INHERITED**, expected draw **BLOCKED** |

**Cited figures used above, with sources (all retrieved 2026-09-06):**

- WS2812 strip: `w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp`:11 (`kNumPixels`
  = 30), :110-111 (`renderedDuty`), :152 (shipped `maxBrightness` = 110), :209
  (`kBudgetMilliamps` = 900), :226 (`perLedMa`), :242 (the check). At cap 180,
  `renderedDuty(255,180)` = 119 and the model gives 540 mA (integer) / 560 mA (un-truncated).
  **The model's 20 mA/channel is an uncited code comment** (`:205`), not a manufacturer
  figure; Worldsemi's **Mar-2017** *LED Characteristics* table gives **16 mA/channel**, which
  bounds the code model from below (448 mA at cap 180). The **Jan-2016 V1.0** revision has no
  current column. **Neither revision publishes the per-pixel controller's quiescent supply
  current**, so the strip figures bound emitter current only.
- MAX98357A: Maxim Integrated *MAX98357A/MAX98357B* datasheet, Electrical Characteristics —
  "Quiescent Current IDD … 2.75 [typ] 3.35 [max] mA", "Current Limit ILIM 2.8 A", "Output
  Power … ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB … 3.2 W", "Efficiency ε … ZSPK = 8Ω +
  68µH … 92 %". The ≥ 640 mA driven bound is 3.2 W / 5 V — conservation of energy, which
  needs no efficiency figure.
- BL-M8812EU2: B-link *BL-M8812EU2 datasheet*, document revision **V1.0** (official release
  2023-10-27), §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)"; §6.2.1 "Peak current
  ≥1800mA"; §3.3 "WLAN Unassociated 113/123 mA", "WLAN TX/RX TCP throughput 300Mbps
  732/928 mA", "HT20 MCS8 TX @ 27.5 dBm (2TX RF test) 927/1510 mA". Its §6.4 recommends a
  heat sink "≧ 32*32mm" against the project's fitted 28×28×3 mm — an open owner question,
  not an O-6 figure.
- DS3235SG: DS SERVO datasheet, model line "DS3235 / DS3235-180 / DS3235-270" (page 1's
  product photo shows a case marked "DS3235SG"), §4 Electrical Specification — "Idle current
  (at stopped) 5mA" in all three columns, and "Stall current (at locked) 1.9A / 2.1 A / 2.3A"
  at 5 V / 6 V / 7.4 V; "Operating Voltage Range 5-7.4V". **Caveat:** DS Servo's own download
  index lists no DS3235 file; confirm the case marking at build week.
- Rail ratings: `HARDWARE_INVENTORY.md`:113 ("UBEC 5 A (2 pcs)"). Rail B's voltage band:
  `D8_BENCH_BRINGUP.md`:55.
- The ESC's BEC is **not** a rail source and imposes no rail limit — its red +5 V wire is cut
  (`w17-pdb-build-and-connector-guide.md`:80; `bill_of_materials_v2.md`:195;
  `00_BUILD_SHEET.md`:32).

**Explicitly NOT used, and why:** a general-knowledge "typical ESP32 draws ~X"; a third-party
"80 mA" figure for the MH-ET board; a third-party "MG90S stall 400 mA"; a search result
claiming the DS3235SG stalls at 3.9 A — that figure is **uncited and states no test voltage**,
while the manufacturer's own datasheet gives 1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V. Family
figures are refused, not discounted.

**Owner decisions this subsection is waiting on — all ten of them** (Q1–Q9 and Q10′ of the
derivation report's §5; none is answered, and none may be filled in from a family figure):

1. **Q1** — the bench PSU's identity and its minimum settable current limit.
2. **Q2** — the UBEC's make/model **and BEC#2's set output voltage** (5 V or 6 V).
3. **Q3** — whether the first energisation uses the PSU rather than the pack, and whether the
   ESC feed can be separated for S0–S9 (an A2 gate S6 topology change — re-run A2 rows
   P2/P4/P5 before and after, and record it).
4. **Q4** — the S1/S2 ramp ceiling (after the no-power look at the MH-ET regulator marking).
5. **Q5** — the RF power/mode the BL-M8812EU2 will actually run at. Until it is named, S5
   carries the module's own §1.3 rated maximum, 1800 mA.
6. **Q6** — the shipped `sound.volume`, and whether the speaker is confirmed 4 Ω.
7. **Q7** — the blower's actual part number (the BOM names a class, not a part).
8. **Q8** — the S7/S8 ramp ceiling.
9. **Q9** — the constant-current duration criterion for a connect.
10. **Q10′ — the Wi-Fi heatsink decision**, which gates **this very card**: the fitted heatsink
    is 28×28×3 mm against the module datasheet's *"≧ 32*32mm"* recommendation, and the
    project's own rule is *"heatsink **fitted before first power-on**"*
    (`learning-manual/05_control_firmware_documentation_explained.md`:362), which is what this
    card is.

See `bench-gates/tools/first_power_current_limits.md` row T11 and
`_handoff/2026-09-06_O6_derivation_report.md` §5.
```

### 6.2 Replacement rows for `bench-gates/tools/first_power_current_limits.md`

*New figure rows, appended to the "only current numbers the documents fix" table:*

```markdown
| L11 | BL-M8812EU2 Wi-Fi module: rated maximum supply current / largest RF-test peak / rated supply capability | **1800 mA (Max)** — §1.3 "Power Supply DC 5.0V±0.25V @1800mA (Max)", the module's own maximum supply current and therefore the added-load allowance until the RF mode is named; largest **per-use-case** §3.3 peak **1510 mA** (HT20 MCS8 TX @ 27.5 dBm, 2TX RF test), one test case and **not** an envelope; supply must deliver **≥ 1800 mA peak** (§6.2.1) | B-link *BL-M8812EU2 datasheet* V1.0, §1.3, §3.3 and §6.2.1 (retrieved 2026-09-06) | manufacturer datasheet |
| L12 | DS3235SG steering servo idle / stall current | **5 mA idle** (all columns) / **stall 1.9 A at 5 V, 2.1 A at 6 V, 2.3 A at 7.4 V** — Rail B's documented band is 5–6 V, so **2.1 A** is the applicable figure until BEC#2's output is recorded | DS SERVO datasheet, §4 (retrieved 2026-09-06); band per `D8_BENCH_BRINGUP.md`:55 | manufacturer datasheet |
| L13 | MAX98357A quiescent / driven / internal limit | **3.35 mA max IDD**; **≥ 640 mA whenever driven** (3.2 W into 4 Ω at 5 V, by energy conservation); **2.8 A ILIM** | Maxim Integrated *MAX98357A/MAX98357B* datasheet (retrieved 2026-09-06) | manufacturer datasheet |
| L14 | WS2812 strip modelled **emitter** draw at the O-7 operating cap 180 | **540 mA** (code's integer form) / **560 mA** (un-truncated). Excludes each pixel's controller quiescent draw — an unquantified adder | `LightRenderer.hpp`:11, :110-111, :152, :209, :226; the model's 20 mA/channel is an **uncited code comment** at `:205` | code |
| L15 | WS2812B per-channel operating current, manufacturer | **16 mA/channel** (RED, GREEN, BLUE) — bounds L14's code model **from below** (448 mA at cap 180) | Worldsemi *WS2812B Specifications*, **Mar-2017** revision, LED Characteristics table (retrieved 2026-09-06). The **Jan-2016 V1.0** revision has no current column | manufacturer datasheet |
```

*Replacement rows T11 / T12 / T13:*

```markdown
| T11 | The bench-PSU current limit to set at each step below | **BLOCKED — O-6 derivation done 2026-09-06 (v2, after review R-O6); owner decisions outstanding.** Policy ratified (O-6, 2026-09-05): lowest defensible limit per substep, trip = STOP AND DIAGNOSE, never raise to make a trip go away, never exceed the rail/component limit. Per-substep derivation is on **BG-03 § "Starting current limits (O-6 derivation, 2026-09-06)"**, with named margin **M-PEAK** and the chaining rule `L(N) = max(R(N-1), SUM P(k) for k<N) + P(N)` — a settled reading is never a bound on a bursty load. **All figures below are 5 V rail-side added-load allowances, NOT bench-PSU settings.** **DERIVED:** WS2812 strip **560 mA** emitter-model bound at the O-7 cap 180 / **188 mA** at the shipped cap 110, excluding an unquantified per-pixel controller term `[code LightRenderer.hpp:11,:110-111,:152,:209,:226]`; BL-M8812EU2 **1800 mA** — §1.3's own rated maximum supply current, which is the allowance until the RF mode is named (§3.3's largest per-use-case peak, 1510 mA, is one RF-test case and not an envelope), with the rail additionally required to deliver **≥ 1800 mA peak** per §6.2.1 `[datasheet, B-link V1.0 §1.3, §3.3, §6.2.1]`; MAX98357A quiescent **3.35 mA max** and **≥ 640 mA whenever driven**, ILIM **2.8 A** `[datasheet, Maxim]`; DS3235SG idle **5 mA** / stall **2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — Rail B's documented band is 5–6 V, `D8_BENCH_BRINGUP.md`:55) `[datasheet, DS SERVO]`. **STILL BLOCKED, and no absolute limit is settable until these are answered:** (1) **no document names the bench PSU**, so its minimum settable CC value is unknown and a settable limit is not even established (`13_phase_a_a2_no_power_checklist.md`:116); (2) **the supply is on the pack side (7.4 V) and every derived figure is a 5 V rail current** (BG-03 § Topology (ASCII)) — the pack-side form is `I_pack <= 5 A * V_rail / (V_pack * eta)` and eta needs the UBEC's model, which **no document names** (`HARDWARE_INVENTORY.md`:113 gives only "UBEC 5 A (2 pcs)"); (3) **S1/S2 and S7/S8 need a ruled ramp ceiling** — the empty-rail ramp of step 2 below is legitimate because it has one, and a loaded ramp without one is "raise until it works"; (4) **the constant-current duration criterion for a connect is unruled** (see T13). Do **not** fill this row from a family figure — a search-engine "DS3235SG stall 3.9 A" is uncited and states no test voltage, while the manufacturer gives 1.9 / 2.1 / 2.3 A at 5 / 6 / 7.4 V. |
| T12 | ESC standby (logic-only) draw on batt+ with motor leads off | **BLOCKED — manufacturer publishes no standby figure.** Hobbywing's own QuicRun 10BL120 page (Sensored G2, the owner's variant per `w17-batch1-measurements-for-codex.md`:41; fetched 2026-09-06) gives "120A/Peak Current 760A", "2-3S Lipo" and "BEC Output: Switch Mode 6V/7.4V @4A" and no standby current. Note the 4 A BEC is **irrelevant to every rail** — its red wire is cut (`w17-pdb-build-and-connector-guide.md`:80). Cheapest resolution: separate the ESC's 12 AWG feed for the whole staircase so this term is absent until D8 Phase 1 — **but that feed is part of A2 gate S6** (`w17-pdb-build-and-connector-guide.md`:167-168), so separating it is a topology change: re-run A2's batt+ rows **P2 / P4 / P5** (`13_phase_a_a2_no_power_checklist.md`:237-241) **before and after**, and record the change. Owner decision, not a bench convenience. |
| T13 | Inrush allowance at the moment the pack is connected | **BLOCKED — bounded by nothing citable, in either direction, and the stop criterion is an owner ruling.** The XT90-S anti-spark exists because the inrush is large; no Amass specification giving its pre-charge resistor was located, no document states the ESC's input capacitance or the **UBEC's input capacitance and soft-start** behaviour — which is what a pack-side supply actually sees — and the bench pack (ZEEE 5200, `HARDWARE_INVENTORY.md`:208) has no C-rating in any document (the `≥25 C` at `:277` is the sourcing spec for the *unbought car pack*). **C1 and C2 are 5 V-side capacitors, downstream of the UBECs, and are not this event.** A battery has **no** settable limit, so nothing in this path limits it. Mitigation is procedural: mate the XT90-S deliberately and fully, observe, and treat any spark, heat or tick as a stop. **"Momentarily in constant current" is NOT a discriminator** — at a low starting limit the supply can hold the rail down so a UBEC never completes soft-start, which looks identical to the fault. The criterion the owner must rule: *"constant current persisting longer than N after a connect, or constant current that has not cleared by the time the rail reaches nominal, is a STOP."* Until N is ruled, treat any unexplained constant-current event as a STOP. |
```

---

## 7. Limitations — what I could not get, and what I refused

**Mirror disclosure (all three, on the same footing — R-O6 N5):**

- **MAX98357A** — **analog.com's** own copy timed out twice (60 s), as did the ADI product page.
  The **Maxim-branded** PDF was read from the `cdn-shop.adafruit.com` **mirror**; the document
  itself is Maxim's ("Maxim Integrated" footer, *PCM Input Class D Audio Power Amplifiers*).
- **DS SERVO DS3235** — read from the `hajim.rochester.edu` **mirror**. The document is DS
  SERVO-branded and its model line reads "DS3235 / DS3235-180 / DS3235-270", but the
  manufacturer's own download index lists no DS3235 file at all, so there is no primary URL to
  offer.
- **BL-M8812EU2** — read from the `jkrorwxhkqmllp5m-static.micyjz.com` **mirror**, not from
  `b-link.net.cn` as v1's §2 row implied. The content is B-link's (the `b-link.net.cn` footer
  and "SHENZHEN BILIAN ELECTRONIC CO., LTD" appear on every page), and its stated revision is
  **V1.0**; "V1.0.1.0" is the filename string, not the document's version.
- **Bash had no outbound network** in the session that produced v1 (curl exit 92), and the
  machine has no `pdftoppm`/`pdftotext`/`mutool`/`gs`. Image-only and CID-font PDFs were read by
  rendering / extracting through the system `swift` + PDFKit in the scratchpad. Nothing was
  installed.

**Identity caveats carried forward rather than papered over:**

- **DS3235"SG"**: the project says DS3235SG; the datasheet's model line says
  DS3235 / DS3235-180 / DS3235-270 — but **page 1's product photograph shows the case marked
  "DS3235SG"**, so the document is the right one. What remains is a build-week visual check of
  the case, not an owner question.
- **WS2812B**: the inventory qualifies the strip as *"addressable WS2812B **type to eyeball at
  wiring**"*, i.e. the type is provisional. It now matters slightly more than v1 allowed,
  because a manufacturer per-channel figure (16 mA, Mar-2017) is being used as a
  bounds-check on the code model.
- **MH-ET board**: the inventory says USB-C, the BOM says micro-USB. Unresolved, and it hints
  the two documents describe different board revisions — another reason not to reach for any
  third-party board figure, and a reason Q4 asks for a marking that is on the board in front of
  the owner.

**A term the model omits, now named rather than assumed away (R-O6 B7):** each WS2812B pixel's
**controller quiescent supply current**. It is real — the logic draws current at zero duty — and
neither Worldsemi revision publishes it. It is carried as an **unquantified adder** on S3a, S3b
and the Rail-A floor. It is also a candidate bench measurement: the strip at cap 0 is the
cleanest way to obtain it.

**Family-level figures that were available and that I REFUSED to use:**

1. **"DS3235SG stall current 3.9 A"** — a search-engine summary with **no source and no stated
   test voltage**. The manufacturer's own datasheet gives **1.9 A at 5 V / 2.1 A at 6 V /
   2.3 A at 7.4 V** over a stated *"Operating Voltage Range 5-7.4V"*, and says nothing about a
   full 2S pack at 8.4 V. The search figure is not *shown* to be wrong; it is uncited and
   condition-free, which is a sufficient reason to refuse it and does not put a falsifiable
   claim into a gate card.
2. **"MH-ET LIVE D1 mini ESP32 … 80 mA active"** — third-party board-catalogue site, not a
   manufacturer document. MH-ET LIVE publishes nothing. Refused; S1 stays BLOCKED, which is the
   honest state, and Q4 asks for a marking on the board instead.
3. **"MG90S … ~2.7 mA idle, ~70 mA no-load, ~400 mA stall"** — third-party reseller/aggregator
   figures. TowerPro's own MG90S page publishes **no current figure at all**, and the project's
   servos are unbranded parts that TowerPro's own site warns are widely counterfeited. Refused;
   S7/S8 stay BLOCKED and Q8 asks for a ruled ceiling.
4. **"MC800S … 12 V @ 170 mA"** — a listing for an **IMX415** variant. The project's camera is
   the **IMX335** MC800S-V3 fed at **5 V** from Rail A. Different sensor, different rail,
   third-party source. Refused; the camera term in S5 stays BLOCKED.
5. **An XT90-S pre-charge resistor value** — commonly repeated in hobby forums, published by
   Amass nowhere I could find. Refused; T13 stays unbounded, and I have said so rather than
   producing a comfortable-looking number.

**What I did not do:** I did not attempt the A3144 Hall sensor's supply current. It is on
Rail A but is not a substep in the staircase order, so it never becomes the added load in any
row above; it remains an unquantified term in the Rail-A floor in §4. The reviewer's own
workspace-wide grep found no project document giving it either.

**One stale citation observed but not fixed here (out of this task's file set):**
`W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`:82 attributes the *"have them, do not connect them"*
quote to `13_phase_a_a2_no_power_checklist.md`:114; the quote is at **:116**.

**Every table in this file is NOT-EXECUTED.** Nothing here authorises powering, flashing or
connecting anything, and Phase B remains BLOCKED on A2 by its own gate line (BG-03's gate line,
`PHASE_B_FIRST_POWER.md`:3-10).
