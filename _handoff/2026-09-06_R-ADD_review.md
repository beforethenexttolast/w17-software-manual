# R-ADD — adversarial review of `O6_addendum_v1.md`

> **Snapshot note (added on persisting, 2026-09-06 evening).** **Non-canonical dated snapshot**, per the `_handoff/` convention
> (`_handoff/README.md`:8-10). This is the adversarial review of record for the O-6 addendum, kept **verbatim** below and **never updated**;
> it is a historical document, not a live one. **Canonical source:** the corrections it demanded live in
> `_handoff/2026-09-06_O6_addendum_report.md` §0 (which maps every finding here to what changed) and, through it, in the cards that report
> names as its canonical homes — `bench-gates/BG-03_phase_b_first_power.md` § *"Starting current limits"*,
> `bench-gates/tools/first_power_current_limits.md` rows L11/L13/L16/T7/T11, `bench-gates/MISSING_THRESHOLDS.md`, `W17_OWNER_ACTIONS.md`,
> `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md` and `CURRENT_STATUS.md`.
>
> **What has gone stale in the body below, and is left standing because the record is verbatim:** path tokens of the form `scratchpad/…` and
> `reports/…` are session-scratch locations, not repo paths, and do not resolve in any checkout; `O6_addendum_v1.md` itself is superseded by
> **v2** and exists only in the session scratchpad. **Repo line numbers were correct at r3 tip `0429b3d`** and the application that followed
> moved several of them: `bench-gates/tools/first_power_current_limits.md` **T11 is now :106** (cited here as :103) because a new **L16** row
> was inserted, and the T-rows generally moved from :93-105 to :96-108; `bench-gates/BG-03_phase_b_first_power.md`'s S4/S5 rows are still
> :150/:151 but everything after them has moved. `first_power_current_limits.md` **L13 is still :76**. The three findings' targets are
> otherwise unchanged, and every citation this review corrects (`BG-04`:143, `open_questions.md`:389, `blm8812.txt`:206-211, §3.3 at :125-154)
> was **independently re-opened and confirmed** during the fix pass.

**Model: Claude Opus · adversarial reviewer (electrical/safety) · 2026-09-06 evening. READ-ONLY —
nothing was edited, created or committed in `~/Documents/projects` or in the r3 worktree. Evidence label:
NOT-EXECUTED** — nothing powered, flashed, measured or transmitted; nothing below authorises any of that.

Reviewed against: `2026-09-06_offline_decision_round_2.md` (DR2-2/7/8/11/13/14), `2026-09-05_offline_decision_round_1.md`
D-4 O-6, workspace `CLAUDE.md`, `_handoff/2026-09-06_O6_derivation_report.md` v2 (§0a B1, §4, §7),
`_handoff/2026-09-06_R-O6_review.md` (B1–B7, N3, N4, N11), and the live text it replaces at r3 tip **0c707e2**
(`bench-gates/BG-03_phase_b_first_power.md`:150-151, `bench-gates/tools/first_power_current_limits.md`:76, :103).
I re-opened the datasheet extract (`…/8d5a99ff…/scratchpad/blm8812.txt`, 367 lines) myself — §1.3, §3.1, §3.3,
**§4**, §5.1, §6.2.1, §6.3, §6.4, §8.2 — and every code and doc line the addendum cites.

*Branch note: the r3 tip advanced from `0c707e2` to `0429b3d` mid-review (a concurrent session, `W17_OFFLINE_READINESS.md`
only). Neither target file changed, so every line number below holds at `0429b3d`. I re-checked before writing.*

# VERDICT: `FIX_REQUIRED`

Three BLOCKING, ten NON-BLOCKING. **The three substantive conclusions survive falsification:** P(5) = 1800 mA
is right and the §3.3 refusal is not over-blocking; "≥ 640 mA whenever driven" is genuinely false for the shipped
build and the relabel is the protective direction; no heatsink surface-temperature PASS limit is derivable and
"has not plateaued" is correctly demoted from STOP to INCONCLUSIVE. What fails is sourcing, one omitted datasheet
section that bears directly on DR2-7, and one asymmetry the addendum's own S5 finding condemns.

---

# BLOCKING

### B1 — Two wrong citations in the 9 dB corroboration chain (§2.2)

Both carry the "9 dB" figure on which the whole Q-B conclusion rests.

- `BG-04`:137 — **wrong target.** Line 137 is the Hall-guard rule (*"**≥ 10×** the elapsed-scaled allowance
  (a 2 s stall: **36 000** entries)"*) and says nothing about the amplifier. The GAIN reference is at
  **`bench-gates/BG-04_d8_bench_bringup.md`:143** — *"MAX98357A GAIN strap (start 9 dB floating)"*.
- `learning-manual/open_questions.md`:387 — the quoted string *"through the MAX98357A at 9 dB gain"* is at
  **:389** (:387 is *"(e) **Crank-whir audibility**: with #53's parking,"*).

**Correction:** `BG-04`:137 → **`BG-04`:143**; `open_questions.md`:387 → **:389**. The primary sources
(`PinMap.hpp`:20-24 and `SIMULATION.md`:40) are both **correct** — I verified them verbatim — so the conclusion
does not move; the citations must.

### B2 — §4.1's S4 row removes the amp's only cited peak-side term without requiring S4's load state — the exact defect §3.4 raises against S5

§4.2 correctly demands that S5 *"state its load state (powered-but-unassociated ≠ streaming)"*. §4.1 does the
opposite for S4: it strikes `P(4)` to **BLOCKED** and states *"the shipped driven draw is **not** bounded below by
640 mA"*, but requires only that `get sound.volume` be recorded — **the setting, not the state**. At S4 the engine
is almost certainly `Ignition::Off` (`synthVolumeFor` returns 0, `AudioDecision.hpp`:33 — bit-exact silence), so
`R(4)` will be a **silent-amp** reading. Under the chaining rule already on the card
(`L(N) = max(R(N-1), ΣP(k<N)) + P(N)`, BG-03:120-124) a settled reading *"may stand in for a load only where no
cited peak exists for it"* — and after this edit no cited peak exists for the amp. A silent-amp `R(4)` then stands
in for a **bursty** audio load at S5–S9. That is R-O6 B3's error, reintroduced by an edit whose stated purpose is
honesty. Direction of safety: a limit chained off a silent reading trips when audio first plays, and the only exit
on the bench is raising it — the loop O-6 exists to close.

**Correction:** add to the §4.1 S4 row, in the same protective form §4.2 uses for S5 —
*"**This row must also state its load state.** Record whether the engine sound was silent (`Ignition::Off` ⇒
`synthVolume 0`, `AudioDecision.hpp`:33) or actually rendering, and at what `sound.volume`. **A silent-amp reading
is not a bound on the amp and must not be chained as one** — if the amp was silent, T7 stays THRESHOLD MISSING and
the amp keeps no cited peak in `ΣP(k)`."*

### B3 — The addendum did not read datasheet §4, and its §4.5 card text substitutes an unsourced TX-power mechanism for the manufacturer's own

§4.5's card text asserts: *"the driver parameters decide whether an adaptive scheme can raise TX power as RSSI
falls — **the reason the shipped mode's own peak is unbounded**"* (same claim, §1.2 reason 1). Nothing cited
supports an RSSI→TX-power mechanism: `bitrate_max/bitrate_min/dbm_threshold` are unexplained in-repo
(`bill_of_materials_v2.md`:203, units unstated) and `learning-manual/05_…`:416 says only that their semantics are
*"outside these repos"*. On its face they are **rate** knobs, not power knobs. This is a plausible-sounding
mechanism presented as the load-bearing reason.

Meanwhile the extract's **§4 Transmitter Specifications — a section the addendum's own verification list omits
(it names §1.3, §3.1, §3.3, §6.2.1, §6.3, §6.4, §8.2)** — states the real, citable mechanism *and* a manufacturer
never-exceed the project has nowhere:

> *"Module TX power of some rates is calibrated, customers can define the target TX power of other rates by
> modifying configuration file of the Linux driver. **Customers must define the TX power same or lower than
> recommended Target TX Power as below!**"* — `blm8812.txt`:206-211, with per-rate targets 802.11a@6M **29 dBm**,
> HT20 MCS0 **28 dBm**, HT40 MCS0 **28 dBm**, VHT80 MCS0 **27 dBm** (calibrated rows 23 / 23 / 22.5 / 21.5 dBm).

**Correction:** (a) replace the mechanism sentence with *"the driver's TX-power configuration decides the operating
point — the manufacturer states it is customer-set in the Linux driver's configuration file (§4) and that it **must
not exceed** the recommended Target TX Power per rate; until that file is captured the shipped mode's own peak is
unbounded by the §3.3 streaming rows"*; (b) add to the §4.5 capture list the instruction to **record the configured
TX power against §4's per-rate recommended targets, and to flag any value above them as a manufacturer-limit
violation**; (c) add §4 to the S5 row's never-exceed cell as a **camera-side config** never-exceed (it is not a
rail limit). This strengthens, not weakens, the addendum's own conclusion.

---

# NON-BLOCKING

### N1 — The one derived thermal criterion loses its criterion status in the card text

§3.2(1) derives *"Bay air above 70 °C is out of rated conditions"*. §4.3's card text keeps the **range**
(−20…+70 °C) but demotes it to a measurement aid (*"Its job is to make the surface reading interpretable"*) and
states no consequence. That is the only bench-reachable derived criterion in the whole section.
**Correction:** append to §4.3 item 1 — *"**Ambient above +70 °C is outside the module's rated operating
conditions** (§1.3, §3.1): stop, improve bay ventilation, and re-run — the reading taken above it characterises
nothing."*

### N2 — "Every §3.3 row is '(Linux Platform Device and Driver)'" is false, in card text

Only **4 of 19** rows carry that label (`blm8812.txt`:130-139). The fifteen RF-test rows carry *"(1TX RF test)"* /
*"(2TX RF test)"* instead. §4.2's card text repeats the misattribution. The error is conservative — an RF-test row
matches the platform even less — but it misquotes the manufacturer.
**Correction:** *"every §3.3 row is a manufacturer bench condition at `VDD5.0 = 5.0 V`, `Ta 25 °C`: four
Linux-driver rows (unassociated 113/123 mA; TCP-throughput up to 732/928 mA) and fifteen fixed-MCS, fixed-dBm
`(RF test)` rows."*

### N3 — §1.2's §3.3 line range and row count are both wrong, and internally inconsistent

*"§3.3, read in full [`blm8812.txt`:126-152] … fourteen fixed-MCS, fixed-dBm `(RF test)` rows"*. §3.3 spans
**:125-154** (the cited range truncates the last two rows), and there are **fifteen** RF-test rows —
1 + 3 + 15 = 19, which is the "nineteen rows" the same paragraph uses. 1 + 3 + 14 = 18.
**Correction:** `:126-152` → **`:125-154`**; "fourteen" → **"fifteen"**. (I independently re-verified that
**1510 mA is the maximum of the Max/IPeak column and 927 mA of the Typ/IRMS column across all 19 rows** — the
stress-case identification is right.)

### N4 — Stale line cite for the defect the addendum exists to fix

§2.6 cites `bench-gates/BG-03_phase_b_first_power.md`:126 for *"≥ 640 mA whenever driven"*. The quote is verbatim
correct but at **:150** at r3 tip 0c707e2 (:126 was correct at 9f7707c, three commits back; the DR2-13 S3 row split
in 0c707e2 moved it). An applier following :126 lands in the inrush paragraph.
**Correction:** `:126` → **`:150`**; the sibling occurrences are `first_power_current_limits.md` **:76** (L13) and
**:103** (T11), which the addendum names by row id only.

### N5 — The MAX98357A mirror refusal is inconsistent with the project's own accepted practice, and left Q-B under-derived

§6.4 refuses *"Using a mirror for the MAX98357A after analog.com timed out twice"*. But **every** manufacturer
figure this addendum relies on came from a mirror under R-O6 N5's disclosure rule — including the BL-M8812EU2
extract itself (`jkrorwxhkqmllp5m-static.micyjz.com`) and the Maxim figures the addendum quotes throughout (3.35 mA,
2.8 A, 3.2 W, 92 %), which O-6 §7 records reading from `cdn-shop.adafruit.com`. The header's *"(the same failure
O-6 §7 records)"* omits that O-6 then **succeeded** via that mirror. So the gain table was reachable by the
project's own standing method and was not attempted.
**Correction:** either re-open the disclosed mirror and record what the 9 dB row says, or restate the refusal
honestly as *"not attempted this pass — the disclosed mirror (R-O6 N5) was available"*. The structural claim
(no η_min ⇒ no upper bound on supply current at any gain) I independently checked and it **holds**: the extract
offers only a **typ** efficiency at the wrong impedance, and ILIM 2.8 A is an **output** limit, correctly kept out
of P(4).

### N6 — §1.3's relabel has no §4 implementation, and the files carrying the old label are outside the stated apply scope

§0 and §1.3 conclude *"two changes to the label"*, but §4 proposes no replacement text. The live "floor" wording is
at **`W17_OWNER_ACTIONS.md`:64** (*"Rail A's admissible-only floor is already ≥ 3000 mA of 5 A (≥ 60 %)"*) and
**`CURRENT_STATUS.md`:25**, neither of which is BG-03 or `first_power_current_limits.md`.
**Correction:** say explicitly that the relabel is out of this application's scope and name the two files, or add
the text. Arithmetic re-checked independently and **correct**: `1800 + 188 + 640 = 2628 mA` = **52.56 %** ("≈ 53 %")
and `1800 + 560 + 640 = 3000 mA` = **60.0 %** of 5 A; 188 mA = 30 × 2 × 20 mA × 40/255 and 560 mA = 30 × 2 × 20 mA
× 119/255 both reproduce from `LightRenderer.hpp`:11,:152,:226. **Both figures with their caps, and no redefinition
of shipped behaviour around 180 — DR2-13 is respected.**

*Precision note on the label itself:* "sizing sum — what the rail must supply if each part runs at its own cited
worst case" is not strictly right either. 1800 mA is an upper bound (part max), 188 mA an emitter-only upper bound
**excluding** an unquantified positive adder, and 640 mA a **lower** bound at a condition the car does not ship.
The sum's direction is undetermined. Honest form: *"a mixed-direction sizing sum: two upper bounds and one lower
bound, with the boards, RP1, camera, Hall and per-pixel controller terms unquantified."*

### N7 — Three canonical docs still assert the superseded AP topology, and the addendum raises it without proposing an action

§1.1 correctly identifies `bill_of_materials_v2.md`:22, `learning-manual/03_…`:220-221 and
`learning-manual/05_…`:361 as stale against the 2026-09-03 correction — all three verified verbatim. §4 proposes no
doc fix, §5 no item, §6 no refusal. The shipped-mode fact then rests, as §1.1 says, on one document against three,
and §4.2's card text tells a reader those three are wrong without fixing them.
**Correction:** add a **doc-fix item** (not an owner question) naming the three lines and the ruling text at
`w17-gcs-box-guide.md`:195-197, for a separate reviewed pass.

### N8 — L11 and T11's "until the RF mode is named" become stale and are not corrected

§4.4 corrects *"whenever driven"* in L13 and T11 but leaves the Wi-Fi clause. After DR2-7 the mode **is** named and
the number did **not** move, so `first_power_current_limits.md`:76 (L11, *"the added-load allowance until the RF
mode is named"*) and :103 (T11, *"which is the allowance until the RF mode is named"*) will contradict the new S5
row.
**Correction:** in both, *"until the RF mode is named"* → *"and DR2-7 named the shipped mode (5 GHz station) without
moving it; the operating point inside that mode is still uncaptured."*

### N9 — §4.4's "again at **100**" implies an armed full-throttle command the card does not place

T7's *"Take the reading at the **recorded** volume (acceptance) and again at **100** (`kVolumeMax`, the ceiling —
unity gain at Running + full throttle)"* can only be obtained by commanding `Ignition::Running` + full throttle.
BG-03's S0–S9 substeps are load-additions; arm/throttle sequencing lives at B3/B4, and prerequisite 5 has the ESC
signal disconnected. The text names no gate for the state change.
**Correction:** *"the ceiling reading is taken only where the card already authorises an armed throttle command
(not during the S0–S9 load-addition staircase); if that state is not reached, record the acceptance reading alone
and leave the ceiling THRESHOLD MISSING."*

### N10 — Redundancies with work already on r3 (0c707e2 / ee1ae2f), and small precision slips

- §3.5's mechanical caveat is **already applied**: procurement BUY NOW **row 6** carries the ≥ 32×32 mm footprint,
  *"height: no taller than the fitted stack until photo/label packet item 7 measures the real gap"*, the U.FL /
  solder-pad-edge prohibition, and the `ZK…:100` + `w17_params.scad:97` citations.
- §5 item 2 is **already applied**: `W17_OWNER_PHOTO_LABEL_INTAKE.md` item 7 already asks for *"total stack height
  base-to-fin-tip"* and *"the distance from the heatsink edge to the two U.FL jack roots and to the solder-pad
  edge"*. Applying it again would duplicate the packet.
- *"Z ≈ 0 mm documented spare"* is not the documented figure. ZK:100 records **3 mm** physical gap, *"5 mm short of
  moving policy"* (8 mm moving / 5 mm static, `C_clearance_keepout_register.md`:97), to a KO-01 floor that is itself
  `// ASSUMED` (`w17_params.scad`:97). Direction is conservative; use the documented numbers.
- `w17-gcs-box-guide.md`:194-196 — the quoted ruling spans **:195-197**; :193-194 is the "Correction" header.
- `SynthProfiles.hpp`:32,:50 → **:37** (`v10()`) and **:54** (*"partials sum 20000 + noise 1800 + whine 4200 =
  26000"*). :32 is blank. The four synth peaks are nonetheless **arithmetically correct** — I recomputed them:
  V10 20200+1600+2800 = **24 600**, V6 20000+1800+4200 = **26 000**, with the ×3 crackle burst (`EngineSynth.cpp`:129)
  **27 800** / **29 600**, all < 32 767 (−2.5 dBFS … −0.9 dBFS).
- `Console.cpp`:277-285 is the `sound.volume` handler; the delivery-build read-only invariant is at
  `w17-control-fw/CLAUDE.md`:**86-90** and `platformio.ini`:52, not at :78 (a section heading).
- *"the only soak durations are G-02:87 and :102"* — `G-02`:274 carries the same ≥ 5-minute figure. Conclusion
  (no card defines a Wi-Fi soak) unaffected.
- §2.2's *"the shipped car meets **none** of the three legs"* overstates for impedance: 4 Ω is **unverified**, not
  known-different. The card text (§4.1, *"an unverified load"*) is correct; the report prose is not.
- §4.6 does not say **where** it goes. Place it inside BG-03's thermal paragraph; do **not** let it displace the
  global stop-condition list in `first_power_current_limits.md`, which already carries DR2-11's 500 ms rule.
- §4.3's *"Longer is strictly more informative"* sits next to *"Duration is BLOCKED"* with no upper bound. Add:
  *"until a duration is ruled, take the reading at the S5 step's own natural length; do not extend a powered run to
  chase a plateau."*

---

# VERIFIED CLEAN

Everything below I re-derived or re-opened myself and found correct.

**Q-A.**
1. **P(5) = 1800 mA is the right M-PEAK outcome.** `blm8812.txt`:52 — *"Power Supply DC 5.0V±0.25V @1800mA (Max)"*
   — verbatim, inside §1.3 General Specifications between `Dimension` and `Operation Temperature`. Consistent with
   V-O6-2 B1's overturn of R-O6 N4.
2. **The refusal to assign a §3.3 row is NOT over-blocking under DR2-7.** DR2-7 asks for the shipped mode *"from
   canonical config"*; TX power, channel width and encoder bitrate are genuinely NOT FOUND, no camera-side config is
   checked in (`video_topology_baseline.md`:45-49 ✓, `video_profiles.md`:98-107 ✓), and D-4 O-6 directs exactly this
   outcome — keep it BLOCKED and return the smallest specific question, which §4.5 and §5 do.
3. **The "two jobs, opposite directions" reasoning is sound** (a limit is a fuse: lower = more protective; a sizing
   sum: higher = more protective), and it correctly **changes no number**.
4. **Stress case verified:** `HT20 MCS8 TX @ 27.5 dBm (2TX RF test) 927 / 1510 mA` (`blm8812.txt`:150) is the
   maximum of **both** columns across all 19 rows. *"Characterise on paper, never on the bench"* satisfies DR2-7's
   *"characterize it separately as STRESS/WORST-CASE"* — DR2-7 asks for characterisation, not execution — and
   tightens in the protective direction, consistent with D-3's live-TX gating.
5. **Shipped-mode determination verified:** station-not-AP at `w17-gcs-box-guide.md`:195-197; both U.FL ports
   populated at `w17-pdb-build-and-connector-guide.md`:89 ✓, `HARDWARE_INVENTORY.md`:75 ✓, `bill_of_materials_v2.md`:203 ✓;
   2T2R is hardware capability, correctly **not** treated as evidence of the 2TX operating point.

**Q-B.**
6. **"≥ 640 mA whenever driven" is genuinely false for the shipped build.** 3.2 W is published only at
   *"ZSPK = 4Ω + 33µH … THD+N 10%, gain = 12dB"*; the project plans **GAIN floating = 9 dB**
   (`PinMap.hpp`:20-24 verbatim ✓, `SIMULATION.md`:40 ✓, `BG-04`:143 ✓). Energy conservation gives a lower bound
   only at the stated condition. Relabelling is the protective direction: it moves no limit (L(4) BLOCKED either
   way) and removes a wrong-low bound, which is the shape that produces nuisance trips.
7. **No upper bound derivable at any gain** — structurally correct; needs η_min, only a **typ at 8 Ω** (92 %) exists.
8. **8 Ω is the favourable direction** — P ∝ V²/Z at fixed 5 V, so an 8 Ω speaker cannot exceed the 4 Ω figures.
   The two non-current consequences (quieter; 92 % would then be at the right impedance) are correctly flagged.
9. **3 W vs 3.2 W is correct and relevant:** `bill_of_materials_v2.md`:71 *"Speaker 4 Ω 3 W"*, corroborated
   `SynthProfiles.hpp`:45 (*"the small 3 W speaker"*) — a speaker-side margin question at the 12 dB strap.
10. **Acceptance/ceiling split correct.** `kVolumeMax = 100`, `kDefaultVolume = 80` (`Link2Frame.hpp`:92-93 ✓);
    D8 Phase 11a step 2 :315 ✓ and step 5 :327-328 ✓ verbatim; compiled defaults load only on loader failure
    (`D8`:304-306 ✓); **`get <key>` exists** (`Console.cpp`:123 help line, :285 handler) so *"record
    `get sound.volume`"* is executable; ceiling arithmetic checks out (`synthVolumeFor` → 255,
    `applyOperatorVolume(255,100) = 255`, `sample * vol / 255` unity).
11. **`kHeadroomPeak = 30000` of 32767** at `EngineSynth.hpp`:103, enforced in `valid()` :114-118 — cite range
    :101-118 is right. **`EngineSynth.cpp`:129 is the correct line** for the ×3 crackle burst (the earlier Sonnet
    :123-125 was the comment block); the narrowing is right.
12. **The §6.9 attribution narrowings are both correct:** `PinMap.hpp`:7 is a file-level *"Bench-verify before
    soldering"* about pin choices ✓, not a GAIN-strap line.

**Q-C.**
13. **Datasheet negatives hold.** I grepped the extract independently for
    `resistance|W/mK|theta|θ|junction|Rth|dissipat|temperature|power`: **no thermal resistance, no case-temperature
    limit, no dissipation figure** anywhere in 367 lines. Refusing a surface PASS temperature is correct and is the
    protective refusal — an invented PASS reads as safety evidence while proving nothing.
14. **Every §3.1/§6.3/§6.4/§1.3 quote is verbatim-exact:** ambient −20…+70 °C (:53, :111-112 ✓); the Tj<125 ℃
    customer-cooling note (:115-118 ✓); §6.3's silicon-pad caution (:315-317 ✓); §6.4's *"≧ 32*32mm, It is located
    directly below the module"* (:326 ✓) and the 4 W/mK TCP (:324 ✓); module 32.0×32.0×3.5 mm (:51 ✓ — note §5.1
    :282 says 3.4 mm, a datasheet-internal inconsistency, immaterial here). The §6.4-vs-as-fitted mismatch
    (sink recommended below the solder mask, project fits it **up** on the can face, `AA…:154` ✓) is correctly
    recorded-not-resolved.
15. **The one-directional proof-of-violation is physically sound.** With the module the dominant local source, every
    point on chip → can → sink → air is at or below Tj, so surface ≥ 125 °C ⇒ Tj ≥ 125 °C ⇒ *"Tj<125℃"* violated.
    The converse is explicitly denied in the card text, so no false PASS is created. Correctly called derivable and
    useless as protection.
16. **"INCONCLUSIVE, not STOP" is defensible under both O-6 and DR2-11.** Every thermal system rises during warm-up,
    so the criterion would fire on healthy behaviour and be undiagnosable; DR2-11's sensory IMMEDIATE STOP remains
    the protective stop and is cited rather than competed with. Protection is not weakened.
17. **The S5 load-state defect is real.** BG-03:151 reads *"S5 + camera / Wi-Fi"* and step 3 of
    `first_power_current_limits.md` reads *"camera/Wi-Fi"* — neither names associated vs streaming — while **T2**
    reads *"Rail-A draw with the camera + Wi-Fi module **streaming**"*. A settled unassociated reading (113/123 mA)
    standing in for a load whose rows reach 928–1510 mA is R-O6 B3's error. §4.2's fix forbids that substitution
    correctly. (It stops one step short: it does not say what happens if streaming is not reached — add *"if the
    module was not streaming, T2 stays THRESHOLD MISSING"* — and note that streaming is CB5-gated,
    `video_profiles.md`:102.)
18. **"Soak duration BLOCKED → owner/bench decision" is the right call.** A workspace-wide grep for `soak` returns
    only `G-02`:87/:102/:274 (the phone glass-to-glass latency gate) and `w17-gcs-box-guide.md`:291's
    *"sustained-bitrate soak"* marked `[bench-TBD]`. No card defines a Wi-Fi thermal soak.
19. **The capture list is correctly labelled and safely built.** Marked *"best-knowledge … NOT verified against this
    camera's firmware"*, *"authorises nothing"*, and it carries the **PSK redaction warning** (`# REDACT psk= BEFORE
    PASTING`). Every command is read-only — no `iw … set txpower`, no write, nothing resembling a "raise until it
    works" ramp.
20. **Instrument reasoning is correct:** probe for air (IR reads surfaces), emissivity caveat for bare aluminium,
    and the fitted part is *"Black"* (`bill_of_materials_v2.md`:26 ✓). *"Touch is not a measurement"* is right.
21. **Procurement facts traceable:** 32.4 × 32.0 × 7.0 mm, 11.2 g with antennas, and the fin-height doubt
    (`w17-batch1-measurements-for-codex.md`:40 ✓); ZK:100 gap and ZK:103/AA:524 U.FL reserves (12×12×6, ≥ 10 mm
    bend, *"never clamp a plug"*) ✓; `w17_params.scad`:97 `ko01_z_lo = 22; // ASSUMED` ✓; C_clearance:97 policy ✓;
    at exactly 32 × 32 mm a sink covers the module PCB, so X/Y growth beyond it is the overhang risk — traceable and
    correctly flagged as a **visual, uncalipered** observation.
22. **The temperature-instrument gap is real:** a workspace grep for `thermometer|infrared|thermocouple|IR gun|
    thermal cam` returns **zero** genuine hits; `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`:203 confirms **14**
    "CHECK IF I ALREADY HAVE" rows and the multimeter is **row 4** ✓ — so "check your meter first" is right.

**§4 card text, §5, §6.**
23. **No invented figure enters any card.** Every number in §4.1–§4.6 traces to DR2, the extract, the code, or v2.
    2628 mA appears only in the report (and already, correctly, in `W17_OFFLINE_READINESS.md`:75).
24. **No sentence in §4 authorises a powered step**, and none authorises a ramp. §4.3's *"do not change anything to
    make it stop rising"* actively closes the fiddle loop.
25. **No contradiction with the DR2 applications already on r3:** the 500 ms STOP wording (BG-03:108-117, T13,
    stop-conditions list), the two DR2-13 S3 rows (:148-149), the M-PEAK clauses (:95-99, T11) and the never-exceed
    column's voltage-domain labelling (R-O6 B2) are all left intact.
26. **§5's questions are genuinely the smallest** and are not answerable from the repos: the GAIN strap is a
    pre-solder **decision** (three docs plan 9 dB floating; the strap is *"documented, not driven"*), the instrument
    exists nowhere, and no card defines a soak duration. §5.6 correctly re-raises DR2-3, DR2-4 and the S1/S2, S7/S8
    ceilings as still-unruled.
27. **§6's refusals 1, 2, 3, 5, 6, 7, 8, 9, 10 are each justified** — in particular refusing *"3 dB less gain ⇒ half
    the power"* (invalid if the 12 dB case is rail-limited) and refusing to use the 92 % **typ** at 8 Ω to convert
    POUT upward (which would understate current). Only refusal 4 (N5) is not.
