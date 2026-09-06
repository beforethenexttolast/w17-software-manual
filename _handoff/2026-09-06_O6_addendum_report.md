# O-6 addendum v2 — DR2-7 (Wi-Fi mode), DR2-8 (amp term), DR2-14 (Wi-Fi thermal check)

> **Header note.** **v1 of this file is SUPERSEDED** (2026-09-06 evening) after the adversarial review `R-ADD` returned `FIX_REQUIRED`
> (3 BLOCKING, 10 NON-BLOCKING). Do not cite v1. §0 maps every finding to what changed. The review is persisted alongside this file as
> `_handoff/2026-09-06_R-ADD_review.md`.

**Model: Claude Opus** · fixer-and-applier (electrical/safety), 2026-09-06 evening. I did not write v1 and did not review it.
**Evidence label: NOT-EXECUTED** — nothing was powered, flashed, measured or transmitted, and **nothing in this document authorises a powered,
flashing, live-TX or FIRST_ACTIVE step, or any "raise until it works" ramp.**
Authority: workspace `CLAUDE.md` 1–7 > readiness packet > DR1 > **DR2** (`2026-09-06_offline_decision_round_2.md`).
Margin rule in force: **DR2-2 / M-PEAK** — manufacturer MAX/PEAK only, 0 % invented margin, never typ/nominal for peak, unresolved max stays
unresolved, manufacturer max is design evidence and **not** a measured current.

**Verification for v2.** I re-opened every citation this document carries, including the ones v1 got wrong. Datasheet extract
(`…/8d5a99ff…/scratchpad/blm8812.txt`, 367 lines): §1.3 (:45-54), §3.1 (:109-118), §3.3 (:125-154), **§4 (:155-250 — the section v1 never
read)**, §5.1 (:282), §6.2.1 (:303-305), §6.3 (:312-317), §6.4 (:320-329), §8.2 (:350-353). **The analog.com MAX98357A PDF stays unread in
this pass and I say why in §6.4 rather than dressing the refusal up** (N5).

**Non-canonical dated snapshot**, per the `_handoff/` convention (`_handoff/README.md`:8-10: snapshots are not canonical, and every snapshot
must name its canonical source).
**Canonical source — the live cards this report was applied into**, on `program/offline-readiness-r3`:
`bench-gates/BG-03_phase_b_first_power.md` § *"Starting current limits (O-6 derivation, 2026-09-06)"* — the **S4** row (:150), the **S5** row
(:151), the **"Thermal check at S5"** paragraph and capture list (:159 onward), the Q5/Q6 entries, and the card's Expected-evidence,
Stop-conditions and Outputs-to-save sections; `bench-gates/tools/first_power_current_limits.md` rows **L11**, **L13** (:76), **new L16** (:79),
**T7** (:102) and **T11** (:106); `bench-gates/MISSING_THRESHOLDS.md`'s T2/T7 note; `W17_OWNER_ACTIONS.md` DR2-7, DR2-8, DR2-13 (:64) and
**Decision Round 3** (:67-91); `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` CHECK-IF-I-ALREADY-HAVE row 14 (:91); `CURRENT_STATUS.md`:25.
**Those cards are the live version; if this file and a card disagree, the card wins.**
**Origin:** written as the session-scratch report `reports/O6_addendum_v2.md` in the session scratchpad (not a repo path, and not resolvable
from any checkout), which is kept **byte-identical** to this file. The adversarial review that produced §0 is persisted alongside as
`_handoff/2026-09-06_R-ADD_review.md`.

---

## §0 Changes from v1 (R-ADD)

| # | Sev | What v1 said | What v2 says |
|---|---|---|---|
| **B1** | BLOCKING | 9 dB corroborated by `BG-04`:137 and `open_questions.md`:387 | **`BG-04_d8_bench_bringup.md`:143** — *"MAX98357A GAIN strap (start 9 dB floating)"* — and **`learning-manual/open_questions.md`:389** — *"MAX98357A at 9 dB gain"*. Both re-opened and verified. `:137` is BG-04's Hall-guard 10×/36 000 rule and says nothing about the amplifier; `:387` is the crank-whir line's opening. The primary sources (`PinMap.hpp`:20-24, `SIMULATION.md`:40) were correct, so **the conclusion does not move; the citations do** |
| **B2** | BLOCKING | S4 row struck P(4) to BLOCKED and demanded only that `get sound.volume` be recorded — the **setting**, not the **state** — the exact defect v1 raised against S5 | The S4 row now **requires S4's load state**, in the same protective form as S5: record whether the engine sound was **silent** (`Ignition::Off` ⇒ `synthVolumeFor` returns **0** — bit-exact silence, `AudioDecision.hpp`:33) or actually rendering, and at what `sound.volume`. **"A silent-amp reading is not a bound on the amp and must not be chained as one"** — if the amp was silent, T7 stays THRESHOLD MISSING and the amp keeps **no** cited peak in `Σ P(k)`. Without this, the chaining rule (`L(N) = max(R(N−1), Σ P(k<N)) + P(N)`, BG-03:119-125) lets a silent `R(4)` stand in for a bursty audio load at S5–S9 — R-O6 B3's error, reintroduced |
| **B3** | BLOCKING | *"an adaptive scheme can raise TX power as RSSI falls — the reason the shipped mode's own peak is unbounded"*, sourced to nothing | **Mechanism replaced with the manufacturer's own, read from §4** (`blm8812.txt`:206-211, verbatim in §1.5): TX power is **customer-set in the Linux driver's configuration file**, with a per-rate **recommended Target TX Power that must not be exceeded**. The unsourced RSSI→power claim is **dropped everywhere** (§1.2 reason 1 and the capture list). The capture list now **checks the configured TX power against §4** and flags any value above the row for the rate in use as a manufacturer-limit violation. §4 is added to the S5 never-exceed cell as a **camera-side configuration** never-exceed **in dBm — not a rail current** |
| **N1** | non-blk | §4.3 kept the ambient **range** but demoted it to a measurement aid with no consequence | The one bench-reachable derived criterion now **states its consequence**: *"ambient above +70 °C is outside the module's rated operating conditions (§1.3, §3.1): stop, improve bay ventilation, and re-run — a reading taken above it characterises nothing"* |
| **N2** | non-blk | *"every §3.3 row is '(Linux Platform Device and Driver)'"*, in card text | **4 of 19** carry that label (`blm8812.txt`:130-139); the other **fifteen** are `(1TX RF test)` / `(2TX RF test)`. Card text now reads *"a manufacturer bench condition at `VDD5.0 = 5.0 V`, `Ta 25 °C`: four Linux-driver rows … and fifteen fixed-MCS, fixed-dBm `(RF test)` rows"* |
| **N3** | non-blk | *"§3.3, read in full [:126-152] … fourteen RF-test rows"* | **`:125-154`** and **fifteen** (1 + 3 + 15 = 19, the same paragraph's "nineteen"). Re-counted line by line. The stress-case identification is unchanged: 1510 mA is the maximum of the Max/IPeak column and 927 mA of the Typ/IRMS column across all 19 |
| **N4** | non-blk | `BG-03`:126 for *"≥ 640 mA whenever driven"* | **`BG-03`:150** (verified at r3 `0429b3d`); the S5 row is **`BG-03`:151**; the siblings are **`first_power_current_limits.md`:76** (L13) and **:103** (T11). An applier following `:126` lands in the inrush paragraph |
| **N5** | non-blk | Refused a MAX98357A mirror as if no route existed, while every manufacturer figure in the document came from a mirror | **I chose the second option the review offers: state exactly what would be needed and refuse honestly.** See §6.4 — the refusal is now *"not attempted this pass"*, with the reason (this pass's mandate admits no number beyond the extract, the code, the rulings and O-6 v2) and with what a future pass must obtain. The structural claim is **unchanged and independently sound**: even a 9 dB POUT figure cannot upper-bound supply current without a **minimum** efficiency, and only a **typ at 8 Ω** exists |
| **N6** | non-blk | Concluded *"two changes to the label"* and proposed no text; the live "floor" wording sits outside BG-03 | **The relabel is now implemented**, in `W17_OWNER_ACTIONS.md`:64 (DR2-13) and `CURRENT_STATUS.md`:25 — the two live files that assert it as current state. Wording per the review's own precision note: a **mixed-direction sizing sum**, two upper bounds and one lower bound, with the unquantified terms named. Both figures carried, each labelled with its cap (§1.4). BG-03 carries no "floor" phrase — verified by grep |
| **N7** | non-blk | Named three stale-AP doc lines and proposed no action | **Doc-fix item added** (§5.7), and the two learning-manual lines are corrected in this application in their own commit, citing `w17-gcs-box-guide.md` §5 (:190-199) and its 2026-08-17 Addendum (:281-291). `bill_of_materials_v2.md`:22 is **already fixed** on the `w17-control-fw` branch `offline/docfix-ci-count-and-wifi-topology` at **631dee2**; `docs/w17_wiring_assembly_atlas.html`:170 stays queued |
| **N8** | non-blk | Corrected *"whenever driven"* but left *"until the RF mode is named"* stale | **DR2-7 named the shipped mode and the number did not move**, so L11 and T11 now read *"…and DR2-7 named the shipped mode (5 GHz station) without moving it; the operating point inside that mode is still uncaptured"* |
| **N9** | non-blk | T7's *"again at 100"* implied an armed `Running` + full-throttle command the S0–S9 staircase never places | The ceiling reading is now **explicitly gated**: taken *"only where the card already authorises an armed throttle command (not during the S0–S9 load-addition staircase); if that state is not reached, record the acceptance reading alone and leave the ceiling THRESHOLD MISSING"* |
| **N10** | non-blk | Ten precision slips and two redundancies | All applied: §3.5's mechanical caveat and §5 item 2 are **already live** (procurement BUY NOW row 6; intake item 7) and are **not re-proposed**; *"Z ≈ 0 mm spare"* → the documented **3 mm** gap, *"5 mm short of moving policy"*; `w17-gcs-box-guide.md`:194-196 → **:195-197**; `SynthProfiles.hpp`:32,:50 → **:37,:54**; the delivery read-only invariant → `w17-control-fw/CLAUDE.md`:**86-90** + `platformio.ini`:52 (`Console.cpp`:277-285 stays, as the `sound.volume` handler); G-02's soaks also at **:274**; *"meets none of the three legs"* → **two legs differ, impedance is unverified**; §4.6 is placed **inside** BG-03's thermal paragraph and does not displace the tools file's global stop list; and *"longer is more informative"* now carries *"until a duration is ruled, take the reading at the S5 step's own natural length; do not extend a powered run to chase a plateau."* One further slip I found myself: v1 cited the module dimension at `blm8812.txt`:52 — it is **:51** (:52 is the power-supply row) |

---

## §1 Q-A — S5 Wi-Fi allowance under DR2-7

### 1.1 The shipped mode, verified

- **Station, not AP:** *"the box's own dual-band adapter **hosts** the 5 GHz Mobile Hotspot; the car's camera radio (RTL8812EU) **joins that
  hotspot as a client**"* — `w17-gcs-box-guide.md`:**195-197**, inside a block headed *"Correction (2026-09-03 …) … the addendum is the ruling"*
  (:193-194), and consistent with the Addendum 2026-08-17 at :281-291.
- **Stale AP wording elsewhere (N7):** `learning-manual/03_hardware_and_electronics_basics.md`:220-221 and
  `learning-manual/05_control_firmware_documentation_explained.md`:361 — **corrected in this application**;
  `w17-control-fw/docs/bill_of_materials_v2.md`:22 — **already fixed** on `offline/docfix-ci-count-and-wifi-topology` **631dee2**;
  `w17-control-fw/docs/w17_wiring_assembly_atlas.html`:170 — queued. **It never changed the answer** — no §3.3 row describes AP/beaconing either.
- **Both U.FL ports populated** [`w17-pdb-build-and-connector-guide.md`:89; `HARDWARE_INVENTORY.md`:75; `bill_of_materials_v2.md`:203]. 2T2R
  **hardware capability** is real; it is **not** evidence of the 2TX RF-test operating point.
- **TX power / channel width / encoder bitrate: NOT FOUND** in any canonical config. Nearest figures: *"Tune `bitrate_max=12, bitrate_min=2,
  dbm_threshold=-52`"* [`bill_of_materials_v2.md`:203, verbatim — **units unstated in-repo**] and *"Codec/mode: H.264, 1280×720, 60 fps"*
  [`w17-ground-station/docs/video_topology_baseline.md`:11], which `video_profiles.md`:98-107 says explicitly excludes camera-side encoder knobs.
- **No camera-side config is checked in anywhere**; capturing it is an open bring-up task [`video_topology_baseline.md`:45-49], and the camera
  hardware is CB5-gated [`video_profiles.md`:102].

### 1.2 Ruling — no §3.3 row now; P(5) stays 1800 mA

**BLOCKED — the shipped mode maps to no published row.** §3.3, read in full [`blm8812.txt`:**125-154**], holds nineteen rows in three classes:
`WLAN Unassociated 113/123 mA` (not the streaming state); three `WLAN TX / RX / TX+RX TCP throughput 300Mbps` rows (643/920, 359/916,
**732/928 mA**) — TCP **link-saturation** tests; and **fifteen** fixed-MCS, fixed-dBm `(RF test)` rows, the largest
`HT20 MCS8 TX @ 27.5 dBm (2TX RF test) 927 / 1510 mA` [:150]. Assigning any of them substitutes a plausible figure for a manufacturer maximum,
which DR2-2 forbids in terms. Three independent reasons, each sufficient:

1. **The operating point is unknown, not merely unnamed — and the manufacturer says why it can be.** §4 states that TX power for the
   non-calibrated rates is **customer-defined in the Linux driver's configuration file**, subject to a per-rate recommended ceiling (§1.5).
   That configuration file **is not captured anywhere in this project**, so the operating point inside the shipped mode is a setting nobody has
   read. *(v1 asserted instead that an RSSI-gated adaptive scheme raises TX power; nothing cited supports it —
   `bitrate_max/bitrate_min/dbm_threshold` are unexplained in-repo and read on their face as **rate** knobs, and
   `learning-manual/05_…`:416 says only that their semantics live *"outside these repos"*. **Dropped.**)*
2. **No row's conditions match the platform.** Every §3.3 row is a manufacturer bench condition at `VDD5.0 = DC 5.0V ; Ta : 25 ℃` [:126] —
   **four** rows *"(Linux Platform Device and Driver)"* [:130-139], **fifteen** `(1TX/2TX RF test)` rows. The car's host is an OpenIPC SSC338Q
   whose driver and settings are uncaptured.
3. **Direction of safety cuts both ways, so "pick the smaller row" is not the safe default.** P(5) does **two jobs**: it sets `L(5)`, a **limit**
   (lower = more protective), and it is a term in the Rail-A sizing sum (**higher** = more protective). No single number is "conservative"
   without naming the job. §1.3's *"Power Supply DC 5.0V±0.25V @1800mA (Max)"* [:52] is the part's own maximum supply current: correct for the
   sizing job by construction, and for the limit job the only figure that is a **manufacturer maximum for this part** rather than a test case.
   **P(5) = 1800 mA stands** [§1.3; consistent with V-O6-2 B1's correction of R-O6 N4].

**Stress / worst case, as the owner asked.** The demonstrably higher-current mode is `HT20 MCS8 TX @ 27.5 dBm (2TX RF test) — 927 mA IRMS /
1510 mA IPeak` [:150], the maximum of the IPeak column across all nineteen rows. **No bench step should ever deliberately enter it:** it needs a
vendor RF test mode rather than the shipped driver path; it is a live-TX action and nothing in DR2 authorises one; DR2-7 forbids redefining
shipped behaviour around stress mode; and it adds no protective information, because the datasheet already publishes the number and the rail can
be sized to it on paper. **Characterise it on paper, never on the bench.**

### 1.3 §4 — the manufacturer's TX-power mechanism and its per-rate never-exceed (new in v2)

Read directly from the extract, verbatim [`blm8812.txt`:206-211]:

> *"Module TX power of some rates is calibrated, customers can define the target TX power of other rates by modifying configuration file of
> the Linux driver . Customers must define the TX power same or lower than recommended Target TX Power as below!"*

The table that follows [:212-250], quoted verbatim from the extract, all rows `± 2 dBm` tolerance:

| TX Rate | TX Power | Extract lines |
|---|---|---|
| 802.11a @ 6Mbps | *"Recommended Target TX Power :29 dBm"* | :213-215 |
| 802.11a @ 54Mbps | *"Calibrated TX Power :23 dBm"* | :217-219 |
| 802.11n @ HT20 MCS0 | *"Recommended Target TX Power :28 dBm"* | :221-224 |
| 802.11n @ HT20 MCS7 | *"Calibrated TX Power :23 dBm"* | :226-229 |
| 802.11n @ HT40 MCS0 | *"Recommended Target TX Power :28 dBm"* | :231-234 |
| 802.11n @ HT40 MCS7 | *"Calibrated TX Power :22.5 dBm"* | :236-238 |
| 802.11ac @ VHT80 MCS0 | *"Recommended Target TX Power :27 dBm"* | :241-244 |
| 802.11ac @ VHT80 MCS9 | *"Calibrated TX Power :21.5 dBm"* | :246-248 |

**What this is and is not.** It is a **configuration never-exceed in dBm** that the *customer* — this project — is responsible for honouring in
the camera's driver config. It is **not a current**, it is **not a rail limit**, and it must never be entered in a P(N) or L(N) cell. It does
not move P(5): §4 constrains the setting, §1.3 bounds the part's supply current, and the two are different claims. Its practical use is a
**checkable acceptance item at camera bring-up** — read the configured TX power, compare it against the row for the rate actually in use, and
flag anything above it as a manufacturer-limit violation to be corrected in configuration, never accommodated by raising a current limit.
**Which row applies is not yet knowable**, because the rate in use is part of the uncaptured operating point.

### 1.4 Does the Rail-A "≥ 3000 mA of 5 A" change?

**Not from Q-A** — the 1800 mA term is untouched. Two defects DR2 created or exposed:

1. **It is not a "floor."** A floor must be a **lower bound on the true total**. The three terms do not point the same way: **1800 mA** is an
   upper bound (the part's own max), **188 / 560 mA** is an emitter-only upper bound that **excludes** an unquantified positive adder, and
   **640 mA** is a **lower** bound at a condition the car does not ship. **Correct label: a mixed-direction rail *sizing sum* — two upper bounds
   and one lower bound, with the two boards, RP1, the camera, the A3144 Hall and the per-pixel WS2812 controller quiescent all unquantified.**
   That is exactly the quantity its actual use needs (*"check the **UBEC headroom** before raising the cap"*, `BG-08_dim_light_halo.md`:109-110),
   so **the number survives its relabelling unchanged**.
2. **DR2-13 makes 3000 mA a contingency, not the shipped case.** DR2-13 KEEPS shipped `maxBrightness = 110` [`LightRenderer.hpp`:152,
   re-verified] and rules 180 the upper operating ceiling only. Recomputed independently for v2:
   - **shipped cap 110:** `1800 + 188 + 640 =` **2628 mA** = **52.56 % ≈ 53 %** of UBEC A's 5 A;
   - **ceiling cap 180:** `1800 + 560 + 640 =` **3000 mA** = **60.0 %**.

   (188 mA = 30 × 2 × 20 mA × 40/255 and 560 mA = 30 × 2 × 20 mA × 119/255, both from `LightRenderer.hpp`:11, :110-111, :152, :226; the model's
   20 mA/channel is an **uncited code comment** at :205.) Direction: quoting 2628 mA alone would overstate headroom for the cap decision, so
   **both must appear, each labelled with its cap** — and neither redefines shipped behaviour around 180, which DR2-13 forbids.

**Verdict: no change to the number, two changes to the label — and in v2 the relabel is implemented, not just recommended** (`W17_OWNER_ACTIONS.md`:64, `CURRENT_STATUS.md`:25).

### 1.5 Capture list for first camera bring-up

**§4.5**, as card text — best-knowledge for an OpenIPC/BusyBox target and **not verified against this camera's firmware**, because no camera-side
config is checked in anywhere. It authorises nothing; it runs when camera bring-up is gated open. Every command is read-only, it carries the
Wi-Fi PSK redaction warning, and it now includes the §4 Target-TX-Power check.

---

## §2 Q-B — the S4 amplifier term under DR2-8

### 2.1 Verified code facts (each file opened for v2)

| Fact | Value | Citation |
|---|---|---|
| Wire volume scale / max / default | `kVolumeMax = 100`, `kDefaultVolume = 80`, linear 0..100 | `w17-soundlight-fw/lib/link2/include/link2/Link2Frame.hpp`:92-93 |
| Engine-state volume | `Off 0 · Cranking 70 · Running 90 + throttle*165/100` → 255 | `…/audiodecision/AudioDecision.hpp`:32-36 (**:33 is the `Off ⇒ 0` line**) |
| Operator composition | `stateVolume * op / 100`, linear, truncating | `AudioDecision.hpp`:78-82 |
| Final gain stage | `sample = sample * vol / 255;` | `w17-soundlight-fw/lib/soundsynth/src/EngineSynth.cpp`:155 |
| Crackle burst | `noiseAmp = config_.noiseAmpMax * 3;` during overrun | `EngineSynth.cpp`:129 |
| Design headroom | `kHeadroomPeak = 30000` of int16 32767 (:103), enforced in `valid()` (:114-118) | `…/soundsynth/EngineSynth.hpp`:101-118 |
| Shipped value set at the bench | Phase 11a `set sound.volume (0–100, the giftee's shipped volume preset)` → `save` → NVS; **both builds load the same blob**, delivery **reads only** | `w17-control-fw/docs/D8_BENCH_BRINGUP.md`:315, :302-306, :327-328 |
| `get sound.volume` exists and is executable | help line `get <key>` at `Console.cpp`:123; key match :277; handler prints `sound.volume=%u` at :285 | `w17-control-fw/lib/console/src/Console.cpp`:123, :277-285 |
| No runtime change in delivery | console only under `-DW17_TUNING_CONSOLE` | `w17-control-fw/platformio.ini`:52; `w17-control-fw/CLAUDE.md`:86-90 |
| GAIN strap | *"MAX98357A straps (**documented, not driven**): GAIN floating = 9dB (start there; GND = 12dB, VDD = 6dB)"* | `w17-soundlight-fw/lib/config/include/config/PinMap.hpp`:20-24 |
| Speaker impedance | one BOM line + one AliExpress link; inventory calls it *"a bench spec-check"* | `bill_of_materials_v2.md`:71-72; `HARDWARE_INVENTORY.md`:98 |

### 2.2 (i) Does "≥ 640 mA whenever driven" stand? **No — as written it is false for the shipped configuration.**

The arithmetic is sound: `3.2 W / 5 V = 640 mA` is a lower bound by conservation of energy, needing no efficiency figure. The **scope of the
claim** is what is wrong: the datasheet states 3.2 W at *"ZSPK = 4Ω + 33µH … THD+N 10%, **gain = 12dB**"*, and the shipped car matches **neither
of the two legs the project has decided**, with the third unverified:

- **Gain — different.** The project plans **9 dB** (GAIN floating) [`PinMap.hpp`:20-24; corroborated `w17-soundlight-fw/docs/SIMULATION.md`:40,
  **`BG-04_d8_bench_bringup.md`:143** and **`learning-manual/open_questions.md`:389**]; the strap is *documented, not driven*, and Phase 9 has not
  run **[BLOCKED — the quoted datasheet text publishes POUT only at 12 dB]**.
- **Impedance — unverified, not known-different** (N10). 4 Ω traces to one BOM line the inventory itself flags a bench spec-check
  **[BLOCKED — photo packet item 6]**.
- **Drive level — different.** The synth's *theoretical fully-constructive* peak is ≈ 24 600/32767 (V10) and ≈ 26 000/32767 (V6) steady,
  ≈ 27 800 / 29 600 with the crackle burst [`EngineSynth.hpp`:101-118, `SynthProfiles.hpp`:**37**, :**54**, `EngineSynth.cpp`:129] — it never
  presents the sustained full-scale sine a POUT spec is measured with.

**Verdict:** 640 mA survives **as a statement about the part at the datasheet's own spec condition** and must be relabelled as such; **"whenever
driven" must go. Direction of safety:** the correction changes **no limit** (L(4) is BLOCKED regardless) and removes an unsupported claim —
protective for an evidence document, because a lower bound that is wrong low is the shape of number that produces nuisance trips and, with them,
the "raise it until it works" loop O-6 exists to close. It does lower the amp's honest contribution to the Rail-A total, which is why §1.4
relabels that total a **sizing** sum, where a part's own spec-condition draw legitimately belongs.

### 2.3 (ii) Any UPPER bound at 9 dB into 4 Ω? **No — and the block is structural.**

- **The gain-conditioned POUT table is unread** — see §6.4 for the honest form of that refusal (N5). **[BLOCKED — not obtained this pass.]**
- **Even with a 9 dB POUT figure, supply current could not be upper-bounded.** That conversion needs a **minimum** efficiency; the only
  efficiency figure in the project is *"Efficiency ε ZSPK = **8Ω** + 68µH … 92 %"* — a **typ**, at the **wrong impedance**. DR2-2 forbids both
  substitutions. **[BLOCKED — no η_min exists at any impedance.]** This is the binding block, and it does not depend on the unread table.
- **`ILIM = 2.8 A` remains the only cited upper figure**, and it is the part's **output** current limit, not a supply-current maximum. It stays
  in never-exceed, not in P(4).
- **M-PEAK applied honestly:** the 12 dB / 4 Ω / 10 % THD+N figure **is** this part's maximum-output condition and is the figure to carry — **but
  only with its condition named, and with the statement that the project does not plan that gain and has not verified the strap.**

### 2.4 (iii) If the speaker is 8 Ω

**Direction of safety: favourable for every current claim here.** At a fixed 5 V supply the maximum deliverable output power falls as impedance
rises (P ∝ V²/Z), so an 8 Ω speaker **cannot** exceed the 4 Ω-based figures — discovering 8 Ω would make every limit slacker, never tighter. Two
non-current consequences: an 8 Ω speaker is quieter at the same setting (an acceptance risk on a gift whose point is engine sound), and the 92 %
efficiency figure would then be at the *right* impedance — the one route by which a future upper bound becomes derivable. Independent of
impedance: the datasheet's **3.2 W at 4 Ω exceeds the BOM's claimed 3 W speaker rating** [`bill_of_materials_v2.md`:71] — a speaker-side margin
question at the 12 dB strap, not a rail question. **[BLOCKED — impedance is photo packet item 6.]**

### 2.5 (iv) Volume 80 vs 100 — acceptance vs ceiling, and the load state (B2)

**Acceptance = the value recorded at D8 Phase 11a**, not 80 by assumption: Phase 11a is the canonical delivery procedure and step 5 records
*"the `sound.volume` the giftee will hear at first power-on"* [`D8_BENCH_BRINGUP.md`:315, :327-328]. The compiled default **80**
[`Link2Frame.hpp`:93] applies **only if** the blob was never saved or fails the loader's length/CRC/version/`valid()` check, in which case
complete compiled defaults load [`D8`:302-306] — so a limit derived at 80 is valid **only alongside a `get sound.volume` reading from the same
session**. **Ceiling = 100** [`Link2Frame.hpp`:92], at `Running` + full throttle (`stateVolume = 255`), where `applyOperatorVolume(255,100) = 255`
and the final gain stage is unity [`AudioDecision.hpp`:32-36, :78-82; `EngineSynth.cpp`:155]. **The delivery build cannot change it in the field**
[`platformio.ini`:52; `w17-control-fw/CLAUDE.md`:86-90; handler `Console.cpp`:277-285].

**And the setting is not the state (B2).** At S4 the engine will almost certainly be `Ignition::Off`, for which `synthVolumeFor` returns **0** —
bit-exact silence [`AudioDecision.hpp`:33]. A reading taken then is a **silent-amp** reading. **A silent-amp reading is not a bound on the amp and
must not be chained as one:** under the chaining rule a settled reading may stand in for a load *only where no cited peak exists for it*, and
after this correction no cited peak exists for the amp in the shipped configuration. If the amp was silent, **T7 stays THRESHOLD MISSING and the
amp keeps no cited peak in `Σ P(k)`**. Direction: a limit chained off a silent reading trips the first time audio plays, and the only bench exit
is raising it.

### 2.6 (v) Is the 12 dB / 9 dB mismatch a defect in the O-6 v2 text? **Yes — in the card text.**

O-6 **§3.2's S4 cell** quotes the full condition including *"gain = 12dB"* and is correct. **The card is not:**
`bench-gates/BG-03_phase_b_first_power.md`:**150** reads *"**≥ 640 mA whenever driven** (energy conservation on 3.2 W into 4 Ω at 5 V — no
efficiency figure needed)"* — **no gain condition, and an unconditional "whenever driven"**. The same omission sits in
`bench-gates/tools/first_power_current_limits.md` row **L13** (:76) and inside row **T11** (:106); all three are corrected here.

---

## §3 Q-C — Wi-Fi thermal validation at first power under DR2-14

### 3.1 What the datasheet contains (read directly from `blm8812.txt`)

| Item | Verbatim | Location |
|---|---|---|
| Ambient operating range | *"Operation Temperature -20℃ to +70℃"* | §1.3, :53 |
| Same, as a spec row | *"Ambient Operating Temperature * / -20 25 70 ℃"* (Min/Typ/Max) | §3.1, :111-112 |
| Customer cooling duty | *"This module built-in high-power FEMs will generate more heat … additional heat dissipation devices must be added by customers. Ensure that the junction temperature of module chipset is within rated value: Tj<125℃."* | §3.1 note, :115-118 |
| Internal thermal path | *"Caution: … high temperature of soldering can damage the thermal conductive silicon pad between module's main chip and shielding cover!"* | §6.3, :315-317 |
| Heatsink recommendation | *"The heat sink recommended size ≧ 32*32mm, It is located **directly below the module**, gold-plated … aluminum-extruded heat-sink"*; TCP *"thermal conductivity 4W/mK, thickness<1.5mm"* | §6.4, :324-329 |
| Module PCB size | *"Dimension 32.0*32.0*3.5mm (L*W*H)"* | §1.3, **:51** (§5.1 :282 says 3.4 mm — a datasheet-internal inconsistency, immaterial here) |
| Storage | *"Storage temperature: -40℃ to +85℃"* | §8.2, :352 |
| **Thermal resistance / case-temp limit / dissipation figure** | **NOT PRESENT** — grep for `resistance\|W/mK\|theta\|θ\|junction\|Rth\|dissipat` returns only the §3.1 note, §6.3's pad caution and §6.4's TCP conductivity | [BLOCKED — not in the document] |

### 3.2 What the check can legitimately assert

**Cannot: a surface PASS temperature.** `Tj < 125 ℃` cannot be converted into one without a junction-to-case/sink thermal resistance **and** the
module's actual dissipation; **neither exists**. Any surface number — 60, 70, 80 °C — would be invented, in the *dangerous* direction: a
fabricated PASS temperature reads as safety evidence while proving nothing. **[BLOCKED — no θ data, on purpose.]** Can:

1. **Ambient — DERIVED, and it is a criterion, not an aid (N1).** Rated ambient operating maximum **70 °C** [§1.3, §3.1]. **Ambient above +70 °C
   is outside the module's rated operating conditions: stop, improve bay ventilation, and re-run — a reading taken above it characterises
   nothing.** Measure with a **probe/air thermometer, not an IR gun** (IR reads surfaces, not air). On a bench it will essentially never trip;
   its second purpose is to make the surface reading interpretable, because **ΔT above ambient carries the information**.
2. **Proof-of-violation — DERIVED, one-directional.** Heat flows chip → shield can → heatsink → air, and §3.1's note establishes the chipset as
   the source, so `T_surface ≤ Tj` while the module is the dominant local source. A surface reading **≥ 125 °C therefore proves Tj > 125 °C** =
   STOP. The converse does **not** follow, so **no false PASS is created**. This limit is derivable and **useless as protection** — no bench
   should come near it — and it is stated only because it is the one Tj-linked number that survives DR2-2.
3. **The protective stop already exists and is not numeric:** DR2-11 — *smell / abnormal heat / smoke / unexpected sound / visual anomaly =
   IMMEDIATE STOP*. The step should **cite** it, not compete with it.

**So the step is EVIDENCE-RECORDING, not pass/fail** — its value is that it creates the project's first thermal data.

### 3.3 Instrument, duration, and an honest verdict on "rate of rise"

- **Instrument.** IR (non-contact) thermometer **or** contact probe / K-type thermocouple; the contact probe is the more defensible, because an
  IR reading depends on surface emissivity and bare or polished aluminium reads badly. The fitted part is specified *"Black"*
  [`bill_of_materials_v2.md`:26], which helps, but the face is small and the instrument's spot must be confirmed smaller than it. **Touch is not
  a measurement**, and on a module the docs call "runs hot" it is also a burn risk. Record which instrument and where on the part.
- **Duration: no card defines one.** Workspace-wide the only soak durations are `bench-gates/G-02_phone_video_glass_to_glass_latency.md`:87
  (*"≥ 60 s before the first sample"*), :102 and :274 (*"≥ 5-minute soak"*) — and **G-02 is the phone glass-to-glass latency gate, measuring the
  phone's thermal and battery, not the first-power staircase**. The Wi-Fi soak the project plans is `w17-gcs-box-guide.md`:290-291
  (*"sustained-bitrate soak"*), marked **`[bench-TBD]`**, with no duration. **[BLOCKED — an owner/bench decision, not a derivation; DR3-1.]**
  Direction: **longer is more informative** — a small finned block's time constant is minutes, so a short window can end mid-rise — but until a
  duration is ruled, **take the reading at the S5 step's own natural length; do not extend a powered run to chase a plateau** (N10).
- **"STOP on any rate-of-rise that has not plateaued" — NOT defensible as a STOP.** Every thermal system rises monotonically during warm-up, so
  as a live criterion it fires on healthy behaviour; as a terminal criterion what it establishes is not "fault" but **"steady state not
  demonstrated"**. Making it a STOP would manufacture exactly the failure O-6 exists to prevent — a stop the operator cannot diagnose, whose only
  exit is to ignore it. **Correct form: an INCONCLUSIVE marker**, and the recorded value is a **lower bound**. The STOPs stay DR2-11's sensory
  rule and §3.2(2).
- **A cadence such as t = 0 / 5 / 10 min contains chosen numbers.** They are a **recording cadence**, not a limit — they gate nothing, so DR2-2
  does not reach them — but the choice belongs next to the data.

### 3.4 Where it attaches — and a gap this exposed

**S5 does not define the module's load state:** *"+ camera/Wi-Fi"* [BG-03:151; `first_power_current_limits.md` staircase step 3] says nothing
about associated vs streaming. Heat and current both depend almost entirely on RF duty, so a reading taken with the module unassociated
characterises neither — while the T-row it fills says *"Rail-A draw with the camera + Wi-Fi module **streaming**"* [T2]. **This is a staircase
defect independent of thermal work**: it lets a settled unassociated reading (113/123 mA) stand in for a load whose published rows reach
928–1510 mA — precisely the error R-O6 B3 corrected in the chaining rule. **S5 must state its load state**, and **if the module was not
streaming, T2 stays THRESHOLD MISSING** (note that streaming is CB5-gated, `video_profiles.md`:102).

### 3.5 Procurement consequence — one row, and only one

- **Temperature instrument: YES, add to "CHECK IF I ALREADY HAVE."** A workspace grep for `thermometer|infrared|thermocouple|IR gun|thermal cam`
  returns **zero** genuine hits — no such instrument appears in `HARDWARE_INVENTORY.md`, in the fourteen "CHECK IF I ALREADY HAVE" rows of
  `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`, or in any gate card's required equipment. Check-first matters: many multimeters include a K-type
  input and the owner already needs a multimeter [row 4], so the question is *"does your meter have a temperature function or a bead probe?"*
  before it is a purchase (DR3-3).
- **Already live, and NOT re-proposed (N10):** the heatsink's mechanical envelope is already carried by procurement **BUY NOW row 6** (≥ 32×32 mm
  footprint, *"height: no taller than the fitted stack until photo/label packet item 7 measures the real gap"*, the U.FL / solder-pad-edge
  prohibition, the `ZK_electronics_cassette_fit_study.md`:100 and `w17_params.scad`:97 citations), and the extra measurements are already **intake packet item 7** (total stack
  height base-to-fin-tip; distance from each heatsink edge to the two U.FL jack roots and to the solder-pad edge). Restating them would duplicate
  the packet.
- **The documented clearance figure, correctly (N10):** the CAD records a **3 mm** physical gap to the provisional KO-01, *"5 mm short of moving
  policy"* (8 mm moving / 5 mm static, `w17-3d-codex/10_assembly_architecture/C_clearance_keepout_register.md`:97), to a KO-01 floor that is itself `ko01_z_lo = 22; // ASSUMED`
  (`w17-3d-codex/11_cad/w17_params.scad`:97). Measured stack 32.4 × 32.0 × **7.0** mm, 11.2 g with antennas
  [`w17-batch1-measurements-for-codex.md`:40]. Direction: growth **in X/Y up to 32 × 32** is lower-risk than growth in **Z** or **beyond 32 mm**.
- **One datasheet-vs-as-fitted mismatch to record, not resolve:** §6.4 recommends the sink *"located **directly below** the module"* against the
  solder-mask side, while the project's arrangement is *"heatsink **up**"* on the shield-can face [`w17-3d-codex/10_assembly_architecture/AA_electronics_placement_study.md`:154].
  §6.3's caution about the pad *"between module's main chip and shielding cover"* shows a can-side sink does conduct — but **honouring
  "≥ 32×32 mm" honours a size stated for a different mounting face**, and nobody should claim datasheet compliance from the size number alone.

---

## §4 Corrected verbatim card text

*(These are the texts applied into the r3 worktree by the same pass; the cards are canonical, this file is the snapshot.)*

### 4.1 BG-03 — replacement **S4** row

```markdown
| S4 + MAX98357A + speaker | quiescent **3.35 mA max**. **Driven: BLOCKED for the shipped configuration.** The part draws **≥ 640 mA at the datasheet's own 3.2 W condition** — `ZSPK = 4Ω + 33µH`, `THD+N 10%`, **`gain = 12dB`**, `VDD = 5V` (energy conservation, 3.2 W / 5 V; no efficiency figure needed). **The car is planned at a different gain and an unverified load:** `GAIN` floating = **9 dB** (`PinMap.hpp`:20-24, "documented, not driven"; `BG-04_d8_bench_bringup.md`:143; Phase 9 has not run), and the speaker's 4 Ω traces to one BOM line the inventory itself calls "a bench spec-check". At 9 dB the manufacturer publishes no output-power figure, so the shipped driven draw is **not** bounded below by 640 mA | — | amp **ILIM 2.8 A** (the part's own **output** current limit, not a supply-current maximum); Rail A output **5 A** | **BLOCKED.** No **upper** bound on supply current is derivable at any gain: it needs a **minimum** efficiency, and the only cited efficiency is a **typ at 8 Ω** (92 %), which DR2-2 forbids substituting. **This row must state its load state.** Record whether the engine sound was **silent** (`Ignition::Off` ⇒ `synthVolume 0`, `AudioDecision.hpp`:33 — bit-exact silence) or actually rendering, and at what `sound.volume`. **A silent-amp reading is not a bound on the amp and must not be chained as one** — if the amp was silent, T7 stays THRESHOLD MISSING and the amp keeps no cited peak in `Σ P(k)`. Acceptance load = the `sound.volume` **recorded at D8 Phase 11a** (compiled default **80**, `Link2Frame.hpp`:93, applies only if the NVS blob was never saved or fails validation); **ceiling = 100** (`kVolumeMax`), at which Running + full throttle gives unity gain (`AudioDecision.hpp`:32-36,:78-82; `EngineSynth.cpp`:155). **Record `get sound.volume` with the reading, or the reading cannot be interpreted.** If the speaker proves **8 Ω**, every figure here is slack, not tight (P ∝ V²/Z) |
```

### 4.2 BG-03 — replacement **S5** row

```markdown
| S5 + camera / Wi-Fi | Wi-Fi **1800 mA** — the module's own §1.3 rated maximum supply current ("Power Supply DC 5.0V±0.25V @1800mA (Max)"). **DR2-7 resolved the shipped RF mode and it does NOT move this number:** the shipped role is **5 GHz STATION**, joining the laptop's hosted hotspot (`w17-gcs-box-guide.md`:195-197, a 2026-09-03 correction that supersedes the AP wording still standing in `w17-control-fw/docs/w17_wiring_assembly_atlas.html`:170), with **both** U.FL ports populated (`w17-pdb-build-and-connector-guide.md`:89). **No §3.3 row may be assigned to it:** TX power, channel width and encoder bitrate are NOT FOUND in any canonical config, no camera-side config is checked in anywhere (capturing it is an open bring-up task, `video_topology_baseline.md`:45-49), the manufacturer states TX power is **customer-set in the Linux driver's configuration file** (§4) and that file is uncaptured, and every §3.3 row is a manufacturer bench condition at `VDD5.0 = 5.0 V`, `Ta 25 °C` — four Linux-driver rows (unassociated 113/123 mA; TCP-throughput up to 732/928 mA) and fifteen fixed-MCS, fixed-dBm `(RF test)` rows. **STRESS / WORST CASE, on paper only:** `HT20 MCS8 TX @ 27.5 dBm (2TX RF test) — 927 mA IRMS / 1510 mA IPeak`, the largest IPeak in the table. **No bench step may deliberately enter it** — it needs a vendor RF test mode, it is a live-TX action, DR2-7 forbids redefining shipped behaviour around stress mode, and the datasheet already publishes the number. Camera term absent | — | module requires the rail to **deliver ≥ 1800 mA peak** (§6.2.1) — a supply-capability requirement, not a limit to set; Rail A output **5 A**. **Camera-side CONFIGURATION never-exceed, in dBm and NOT a current:** §4 — "Customers must define the TX power same or lower than recommended Target TX Power", per rate (802.11a 6M **29 dBm**, HT20 MCS0 **28 dBm**, HT40 MCS0 **28 dBm**, VHT80 MCS0 **27 dBm**; ± 2 dBm). It constrains the camera's driver config, never a rail limit | **BLOCKED** — no figure for the OpenIPC SSC338Q at 5 V, and the RF operating point is unresolved, so under DR2-2 it **stays** unresolved. **This row must also state its load state** (powered-but-unassociated ≠ streaming): a settled reading taken unassociated cannot stand in for T2, "Rail-A draw with the camera + Wi-Fi module **streaming**" — **if the module was not streaming, T2 stays THRESHOLD MISSING** (streaming is CB5-gated, `video_profiles.md`:102) |
```

### 4.3 BG-03 — new paragraph, "Thermal check at S5"

Applied verbatim after the table; it contains the stop-condition line (§4.6) inside it, and does **not** displace the global stop list in
`first_power_current_limits.md`. Full text as applied — see `bench-gates/BG-03_phase_b_first_power.md`.

### 4.4 `first_power_current_limits.md` — T7, L13, L11/T11 and new L16

T7 states both bounds honestly and **gates the ceiling reading** (N9); L13 carries the 12 dB spec-point label instead of *"whenever driven"*;
L11 and T11 lose *"until the RF mode is named"* (N8) and *"whenever driven"*; **L16** is new and carries §4's Target TX Power, explicitly labelled
a configuration never-exceed **in dBm, not a current**. Applied text is in the file.

### 4.5 Camera bring-up capture list (best-knowledge, unverified against this firmware)

Read-only commands only, PSK redaction warning, and the §4 check. Applied text is in BG-03.

### 4.6 Stop-condition line for the thermal step

```markdown
**STOP:** DR2-11's sensory rule (smell / abnormal heat / smoke / unexpected sound / visual anomaly) — or a heatsink surface
reading **≥ 125 °C**, which proves the datasheet's Tj < 125 °C is already violated. **No other numeric thermal STOP is
derivable**, and "still rising" is an inconclusive result, not a fault.
```

---

## §5 Owner questions that remain (smallest and cheapest first)

1. **Photo packet item 6, speaker label:** impedance (4 Ω vs 8 Ω) and rated power. *Unblocks* S4's load leg. Direction: 8 Ω would make every
   current figure slacker, never tighter.
2. **DR3-2 — the GAIN strap as it will actually be soldered.** `PinMap.hpp`:20-24 says floating = 9 dB, *"documented, not driven"*. Confirm 9 dB
   (or rule otherwise) **before anyone solders**: it is the difference between the datasheet's characterised condition and one the manufacturer
   has not characterised. A free build decision, not a photo.
3. **DR3-3 — a temperature instrument.** None exists anywhere in the workspace. Check the multimeter for a K-type input or a bead probe first;
   buy only if it has neither. An IR gun reads **surfaces, not air**, and is acceptable only for the surface proof-of-violation reading.
4. **DR3-1 — rule the streaming-soak duration** for BG-03 S5. No card defines one; `w17-gcs-box-guide.md`:291 says `[bench-TBD]`. Longer is more
   informative; the number is the owner's and **I propose none**.
5. **Photo packet item 7** (Wi-Fi module + heatsink + clearance) — **already asks** for the stack height and edge distances; nothing to add.
6. **Standing and still blocking everything:** DR2-3 (bench PSU identity + minimum settable current limit), DR2-4 (UBEC model + BEC#2's set
   voltage), and the **S1/S2 and S7/S8 ramp ceilings** (O-6 Q4 / Q8), still unruled.
7. **Doc-fix item, not an owner question (N7):** three canonical docs asserted the superseded AP topology against
   `w17-gcs-box-guide.md`:195-197. `bill_of_materials_v2.md`:22 is fixed on `w17-control-fw` `offline/docfix-ci-count-and-wifi-topology`
   **631dee2**; the two learning-manual lines (`03_…`:220-221, `05_…`:361) are corrected by this pass;
   `w17-control-fw/docs/w17_wiring_assembly_atlas.html`:170 remains queued for a reviewed pass in that repo.

---

## §6 What I refused, and why

1. **Assigning any §3.3 row to S5** — including the "TX/RX TCP throughput 300 Mbps 732/928 mA" row. It *is* plausible, and DR2-2 forbids
   plausible: none of its conditions is established for this platform, and a mapping that lowers P(5) would simultaneously loosen the limit's
   nuisance margin and overstate Rail-A headroom.
2. **Computing the amplifier's output power at 9 dB** from the 12 dB figure. "3 dB less gain ⇒ half the power" assumes the 12 dB/full-scale case
   is exactly rail-limited, which the datasheet text this project holds does not establish.
3. **Using the 92 % efficiency figure** to convert output power to supply current upward — a **typ** at **8 Ω**; DR2-2 forbids both substitutions.
4. **Obtaining the MAX98357A gain-conditioned POUT table this pass — and I state the refusal honestly (N5).** The review is right that a mirror
   was available: every manufacturer figure this project relies on came from one under R-O6 N5's disclosure rule — the BL-M8812EU2 extract from
   `jkrorwxhkqmllp5m-static.micyjz.com` and the Maxim figures from `cdn-shop.adafruit.com` (O-6 v2 §7:684-691, which records that analog.com
   timed out **and that the mirror then succeeded**). So the honest form is **"not attempted this pass — the disclosed mirror was available"**,
   not "unreachable". **Why I still refuse here:** this pass's mandate admits no number beyond the datasheet extract, the code, the rulings and
   the O-6 v2 report, and a fetched POUT row would be exactly such a number, entering card text without an adversarial review of its own.
   **What a future pass needs, precisely:** (a) the MAX98357A *Electrical Characteristics* **output-power row at gain = 9 dB**, with its ZSPK,
   inductor and THD+N conditions quoted; and — the part that actually decides the question — (b) a **minimum** efficiency at the fitted
   impedance. Without (b), (a) still yields **no upper bound on supply current**, so obtaining (a) alone would change no limit on any card.
5. **Proposing any heatsink surface-temperature limit**, and converting Tj < 125 ℃ into one. No thermal resistance exists; a converted number
   would be invented in the *dangerous* direction.
6. **Turning "has not plateaued" into a STOP.** It fires on healthy warm-up and is undiagnosable; the correct outcome is an **inconclusive
   result**, and the protective stop already exists in DR2-11.
7. **Sizing the heatsink** — the live procurement row carries the constraints and no SKU, and I did not add one.
8. **Authorising, planning or scheduling any powered step** — including the 2TX RF-test stress case, which I recommend never be run on this car.
   Nothing in §4's card text authorises a powered step, and nothing in it permits raising a limit to make a trip go away.
9. **Proposing any number for the soak duration** (DR3-1), any heatsink SKU, or any figure for the S1/S2 and S7/S8 ramp ceilings.
10. **One thing I could not verify and did not paper over:** whether an NVS blob written by a tuning build survives a later delivery-build flash
    on this toolchain. `D8_BENCH_BRINGUP.md`:302-306 says both builds load the same blob through the same loader, which implies persistence, but
    flash-time erase behaviour is not stated there. The S4 card text is correct either way, because it demands a `get sound.volume` reading —
    **and now the load state** — in the same session as the measurement.
