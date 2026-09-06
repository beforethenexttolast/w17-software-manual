# BG-03 — Phase B first power (logic only, ESC motor power disconnected)

*Card for `w17-control-fw/docs/PHASE_B_FIRST_POWER.md` (cited as **PB**), whose source ordering
is `w17-control-fw/project-review/11_hardware_validation_plan.md` §Phase B (cited as **plan**),
with the checkbox detail in `w17-control-fw/docs/D8_BENCH_BRINGUP.md` (cited as **D8**).*

> **Gate line, verbatim in force:** Phase B is **BLOCKED** until A2 is filled in with real bench
> readings, its §12 two-part PASS is recorded, **and** the result is reviewed and approved
> (PB:3-10). As of this card, A2 is NOT-EXECUTED and Phase B is BLOCKED.

## Prerequisites

1. **`A2-CLOSED` recorded** (BG-02) **and `PHASE-B-OPEN` recorded** — two separate states, the
   second owner-only, both dated in `CURRENT_STATUS.md`
   (`w17-parts-to-gift-master-sequence.md`:188-192, :204).
2. **Wheels off the ground**, car on a stand or fixture that cannot roll (PB:28).
3. **An observer present** — not a solo unattended session; this is the workspace rule against
   unattended flashing/powering (PB:29-30).
4. **The battery lead must be pullable at the master switch / XT60 split without reaching past
   any moving or hot part.** Know where your hand goes before you need it there (PB:31-32).
5. **ESC signal and both servo/actuator leads physically disconnected** until B3 reconnects them
   one at a time (PB:33-34).
6. **ESC motor leads disconnected for the whole of this card.** The motor does not turn in
   Phase B; that is Phase C (PB:14-17).
7. RP1 bound to the TX **with failsafe mode "No Pulses"** — "Set Position" would keep sending hold
   frames and defeat the frame-timeout failsafe entirely (D8:63-64).
8. **CP1–CP3 are not optional here.** If A2 recorded them NOT-ASSEMBLED, they are a **hard
   precondition to the first pack connection** — run them before any pack meets this harness
   (A2:560-562, :816-821).

## Required equipment

- Multimeter.
- **Oscilloscope or logic analyser** — B1.3 and B1.4 are scope rows and cannot be done with a
  meter (PB:44-45).
- Serial monitor at **115200** (PB:35-36).
- `elrs-joystick-control` on the PC (PB:36), and the RP1 + TX bound at the same ELRS
  major.minor + bind phrase (D8:61-62).
- A way to spin the rear axle by hand (PB:36).
- A bench PSU or the battery via the XT60 split — see
  `bench-gates/tools/first_power_current_limits.md` before choosing a limit, and read its
  finding: **the project documents no expected current for any car-side 5 V load** (the
  ground-side GCS box loads do have cited figures — `w17-gcs-box-guide.md:135-139`).
  **Current-limit policy RULED 2026-09-05 (D-4 O-6, staircase policy ratified):** set the
  lowest defensible limit for the substep being powered; a current-limit trip means **STOP
  AND DIAGNOSE**, never simply increase the limit until it works; raise the limit only after
  the trip is understood and the next setting is justified; never exceed applicable
  rail/component safety limits. **Starting limit per substep: derived offline 2026-09-06
  (v2, after review R-O6) — see the subsection below; still BLOCKED on owner Decision
  Round 2 (bench PSU identity and minimum settable limit; UBEC make/model and BEC#2's set
  voltage; the S1/S2 and S7/S8 ramp ceilings; the constant-current duration criterion for a
  connect).** No amperage is stated on this card, and **no figure in the subsection below is
  a bench-PSU setting** — they are 5 V rail-side allowances.

### Starting current limits (O-6 derivation, 2026-09-06)

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
figure that is a **requirement on the supply** (the Wi-Fi module's "Peak current ≥1800mA")
belongs in never-exceed, never in P(N).

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
   literal first number step 1 asks for — is unknown, and it is not established that it has a
   settable limit at all.
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
| S0 PDB alone | divider 37 kΩ → **0.20 mA @7.4 V** derived; UBEC quiescent and ESC standby absent | — | PSU's own limits (unknown) — this row is genuinely pack-side | **BLOCKED** — needs the PSU's minimum settable limit |
| S1 + ESP32 #1/#2 idle | — | — | Rail A output **5 A** — and the rail's rating is **not** a ramp ceiling for two D1-mini boards | **BLOCKED** — MH-ET LIVE publishes no datasheet; the WROOM-32 module datasheet is not the board. A ramp needs the ceiling Q4 asks for |
| S2 + RP1 | — | — | Rail A output **5 A** — same objection as S1 | **BLOCKED** — RadioMaster's own page gives 5 V and no current figure. A ramp needs the ceiling Q4 asks for |
| S3 + WS2812 strip @ cap **180** | **560 mA** — **emitter-model** upper bound (code's integer form 540 mA); **excludes each pixel's controller quiescent draw, which Worldsemi does not publish** — carry it as an unquantified adder | — | compile budget **900 mA**; Rail A output **5 A** | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S3 + WS2812 strip @ shipped **110** | **188 mA** — same emitter-model caveat (code's integer form 180 mA) | — | as above | **P(N) DERIVED (emitter model)**, L(N) **BLOCKED** |
| S4 + MAX98357A + speaker | quiescent **3.35 mA max**; **≥ 640 mA whenever driven** (energy conservation on 3.2 W into 4 Ω at 5 V — no efficiency figure needed) | — | amp **ILIM 2.8 A**; Rail A output **5 A** | **BLOCKED** for a settable point value — shipped `sound.volume` unrecorded; the only cited efficiency is at 8 Ω, not the 4 Ω speaker. **Both bounds DERIVED** |
| S5 + camera / Wi-Fi | Wi-Fi **1510 mA** — peak of the worst applicable cited row; camera term absent | — | module requires the rail to **deliver ≥ 1800 mA peak** (its §6.2.1) — a supply-capability requirement, not a limit to set; Rail A output **5 A** | **BLOCKED** — no figure for the OpenIPC SSC338Q at 5 V |
| S6 + blower | — | — | Rail B output **5 A** | **BLOCKED** — the BOM names an "ACP2006-class" part, not a part number |
| S7 + one MG90S | — | — | Rail B output **5 A** — not a ramp ceiling for one micro servo | **BLOCKED** — generic part; TowerPro's own page publishes no current figure and quotes 4.8 V operating, below Rail B's band. A ramp needs the ceiling Q8 asks for |
| S8 + remaining MG90S | — | — | Rail B output **5 A** | **BLOCKED** — as S7 |
| S9 DS3235SG holding centre (T3) | **5 mA** (datasheet idle-at-stopped; identical in all three voltage columns) | — | servo **stall 2.1 A at 6 V** (1.9 A at 5 V, 2.3 A at 7.4 V — select from the recorded BEC#2 voltage); Rail B output **5 A** | **P(N) DERIVED**, L(N) **BLOCKED** |
| S9 DS3235SG full-lock sweep, linkage OFF (T4) | — (no running-current figure exists; the datasheet gives only idle and stall) | — | **2.1 A at 6 V** — this is the number C1 exists for | **ceiling DERIVED**, expected draw **BLOCKED** |
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

**Owner decisions this subsection is waiting on:** the bench PSU's identity and minimum
settable limit; the UBEC's make/model **and BEC#2's set output voltage**; whether the first
energisation uses the PSU rather than the pack and whether the ESC feed can be separated for
S0–S9 (an A2 gate S6 topology change — re-run A2 rows P2/P4/P5 before and after); the S1/S2
and S7/S8 ramp ceilings; and the constant-current duration criterion for a connect. See
`bench-gates/tools/first_power_current_limits.md` row T11 and
`_handoff/2026-09-06_O6_derivation_report.md` §5.

- Car on a stand. Battery pullable. Observer.

## Topology (ASCII)

```
   PC (elrs-joystick-control)          <-- ground side; BG-06 covers the wire out of here
        |  USB
   ELRS TX module  ) ) )  2.4 GHz  ) ) )  RP1 receiver
                                            |  CRSF 420000 8N1 NOT inverted
                                            |  RP1_TX -> GPIO16 ,  GPIO17 -> RP1_RX
                                            v
   bench PSU / pack --[XT90-S master]-- PDB --+-- UBEC A --> Rail A --> ESP32 #1  ---- link2 ---->  ESP32 #2
        (pullable, known hand path)           |                            |     GPIO25 -> GPIO16
                                              +-- UBEC B --> Rail B        |     115200 8N1
                                              |                            |
                                              +-- ESC 12 AWG feed          +--> GPIO13 steer   ) DISCONNECTED
                                                     |                     +--> GPIO14 ESC sig ) until B3
                                                     X                     +--> GPIO18 DRS     )
                                              MOTOR LEADS OFF              +--> GPIO19/23 gimbal)
                                              for ALL of Phase B

   scope points for B1.3 / B1.4:  GPIO13, GPIO14, GPIO18  (before any actuator is attached)
```

## Exact procedure (numbered)

**B1 — Links & signals** (PB:38-56; D8 Phases 2–3):

1. **B1.1** Confirm the RP1's CRSF output is **420000 baud, 8N1, NOT inverted**; `NewRcFrame`
   decodes; channels move with the TX. If nothing arrives, suspect RP1 binding and baud/inversion
   **before** suspecting firmware (PB:53-54). BG-06 is the frame-level version of this row.
2. **B1.2** Antenna-off / RX-down drives `uplinkLinkQuality → 0` and **latches**
   `rxSignalsFailsafe`.
3. **B1.3** **Scope GPIO13/14/18** pulse widths (**1000 / 1500 / 2000 µs**) and the **50 Hz**
   period on the real ESP32 **before** connecting the ESC or servos — this confirms LEDC did not
   silently reduce 16-bit resolution.
4. **B1.4** **Scope GPIO14 + GPIO13 from power-on through the first `setup()` write** — confirm no
   ESC arm/twitch or servo kick in the pre-`ledcAttachPin` float window. This is the firmware-timing
   side of the exposure A2's PD1 row records the harness side of. **Actuators stay disconnected
   until B1.4 passes** (PB:55-56).

**B2 — The safety chain** (PB:58-81; D8 Phase 5 — **THE GATE**). Do not skip; do not proceed on a
partial pass:

5. **B2.1** Power up with **no CRSF** → ESC neutral, DRS closed, steering centred.
6. **B2.2** Bring the link up **with the throttle stick forward** → motor command stays off until
   the stick returns to neutral (ArmGate) and the arm conditions are met.
7. **B2.3** Confirm the ESC arms every boot with the neutral-hold sequence (motor still
   disconnected); reconcile **`bootArmHoldMs = 2000`** against the ESC's own manual; confirm
   **forward/brake** mode, not forward/reverse.
8. **B2.4** Confirm worst-case failsafe detection at the chosen RP1 packet rate + an LQ=0 burst
   stays within **~540 ms worst case against the 500 ms budget**.
9. **B2.5 — the re-arm invariant** (2026-08-20, owner-ratified): a failsafe episode **latches** a
   disarm. Recovery with the arm switch left ON through the episode **must stay disarmed**; only an
   **OFF→ON toggle with the stick centred** re-arms; a boot with the switch already ON needs the
   same toggle. Contract: `lib/channels/include/channels/ArmGate.hpp`. **A fresh neutral appearing
   to re-arm is a regression, not a bench quirk** (PB:69-74).

**B3 — Actuators (bench, unloaded) & board #2** (PB:83-106; **D8 Phases 6, 7b and 9 — NOT Phase 7,
which is ESC + motor (`D8_BENCH_BRINGUP.md`:210) and therefore Phase C.** `PHASE_B_FIRST_POWER.md`:83
cites the range as "6–7b"; that range includes the motor phase and contradicts this card's own
precondition 6 — ESC motor leads disconnected for the whole of this card. The source defect is
recorded for a control-fw session.) Only after B2
passes **completely**; reconnect actuators **one at a time**:

10. **B3.1** Narrow steering endpoints to the linkage's mechanical travel; sweep full L/R with the
    linkage fitted — no bind, no stall.
11. **B3.2** Confirm **DRS 1000 µs = wing closed** (the failsafe-safe position); swap in config if
    reversed.
12. **B3.3** **link2 on the wire**: capture GPIO25 → board #2 GPIO16 at **115200 8N1**; board #2's
    `Link2Monitor` reports **`FrameReady`**, not `BadVersion`/`FrameInvalid`. If it does not, go to
    **BG-05** — this is the coordinated-flash symptom.
13. **B3.4** Decode a live link2 frame on board #2 identical to sender intent (throttle %, brake
    bit, ERS-deploy bit, gear, driveMode).
14. **B3.5** I2S audio through the legacy driver on the pinned core; check `i2s.begin()` return
    codes; confirm no fail-silent/block.
15. **B3.6** WS2812 `show()` does not glitch while audio DMA runs.
16. **B3.7** Board #2 with link2 RX disconnected at boot → the calm never-connected idle is
    acceptable; then cut the wire mid-run → **Lost → hazard within 500 ms**.
17. **B3.8** Board #2 mid-frame power-on with board #1 already transmitting → boots
    NeverConnected, syncs on the next start byte.
18. **B3.9** Camera gimbal (right stick, ch9/ch10): servos centre when disarmed; axes track and are
    not inverted; on a link drop, a **smooth ~2 s glide to centre** (`gimbal.decay`) — **not a snap
    and not a hold**; it glides back on recovery.

**B4 — Sensors (bench)** (PB:108-126):

19. **B4.1** ADC divider extremes — open/disconnected divider and full 8.4 V → sane `batteryMv`,
    no spurious low-voltage latch; log the eFuse cal type; check the 8.4 V point is not compressed
    by the 11 dB attenuation ceiling.
20. **B4.2** Hall (GPIO35) counts on a rolling bench test with a single magnet; baseline **before**
    any motor EMI exists.
21. **B4.3 — battery-sense plausibility (OD-10)**: with the pack at a known voltage, lift the
    divider's **lower** leg, then the **upper** leg, one at a time. Expect **no CRSF battery frame
    at all**, **no newly latched** low-battery warning, and `batteryMv` **0** on link2 — not a
    fabricated number, not a 100 %-full reading. An **already-latched** warning is held for
    `warnDelayMs` (**3 s**) of continuous implausibility and only then dropped. Restore each leg →
    the reading returns exact on the next sample. Record the converted mV each fault produces and
    confirm it lands **outside 4000–9000 mV**.
22. **B4.4 — Hall interrupt-rate margin, motor-free half (OD-11)**: hand-spin the rear axle, log
    `hallSensor.isrEntries()`, `lastWindowEntries()` and `guardFaults()` over a **~10 s** roll (the
    console `status` line prints all three), then repeat with the GPIO35 10 kΩ pull-up lifted
    (scope the pin). Record **entries per 100 ms** for both, and whether `guardFaults()` ever
    increments. The guard's bound is **180 entries / 100 ms** (20× the 5000 rpm maximum); the
    hand-spun roll must sit far below it. The full-throttle half is D8 Phase 8, **not this card**.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# 0. GATE CHECK, every session, before anything is plugged in.
#    STOP if any line says "Phase B stays BLOCKED", or no dated "PHASE-B-OPEN" line
#    appears: the rest of this card is not runnable.
grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN" CURRENT_STATUS.md | head

# 1. Evidence folder + environment stamp.
bench-gates/tools/bench_capture.sh BG-03 --no-serial --note "Phase B first power, B1"

# 2. The bench firmware, flashed ONLY once Phase B is open (D8:79):
cd w17-control-fw
pio run -e esp32dev_tuning -t upload

# 3. Console capture with real per-line timestamps (read-only; opening the port
#    resets the board, which is why this is Phase-B work):
cd /Users/vitaliykhomenko/Documents/projects
ls /dev/tty.*                       # identify the bridge
bench-gates/tools/bench_capture.sh BG-03 \
  --port /dev/tty.usbserial-XXXX --baud 115200 --seconds 600 \
  --note "B2 safety chain: arm gate, failsafe latch, re-arm invariant"

# 4. Console rows that produce B4.4's numbers (type into the tuning console):
#      status            -> prints isrEntries / lastWindowEntries / guardFaults
#      get batt.ppt      -> the calibration in force

# 5. Frame-level proof of B1.1, from a passive tap on the RP1 -> GPIO16 line
#    (see BG-06 for the tap and its rules):
bench-gates/tools/crsf_sniff.py --port /dev/tty.usbserial-YYYY --baud 420000 \
  --seconds 30 --raw-out bench-gates/evidence/BG-03/<stamp>/rp1_tap.bin --summary
```

## Expected evidence

- **B1.3**: scope captures of GPIO13/14/18 showing **1000 / 1500 / 2000 µs** at **50 Hz**, clean.
- **B1.4**: a scope capture spanning power-on → first `setup()` write on GPIO13 and GPIO14, with
  **no pulse or transient** in the pre-`ledcAttachPin` window (PB:49-51).
- **B2**: a timestamped console log showing every B2 row, including the **re-arm invariant**
  sequence — episode → recovery with switch ON → *still disarmed* → OFF→ON toggle → armed.
- **B2.4**: a measured detection latency figure with the packet rate it was measured at.
- **B3.3/B3.4**: board #2 reporting `FrameReady` plus a decoded frame matching sender intent.
- **B4.3**: the recorded mV each divider fault actually produced, and where it sat relative to the
  4000–9000 mV band.
- **B4.4**: entries per 100 ms for the plain roll and for the lifted-pull-up roll, plus the
  `guardFaults()` count.
- The `bench_capture.sh` `meta.txt` naming the **exact firmware commit** each observation was made
  against — an observation that cannot name its code is not evidence.

## PASS/FAIL criteria (objective numbers)

| Row | PASS | FAIL |
|---|---|---|
| B1.1 | CRSF decodes at **420000 8N1, not inverted**; channels track the TX | no frames, or frames only after an inversion change (that would contradict the firmware, which has no inversion path — plan:66) |
| B1.3 | **1000 / 1500 / 2000 µs** at **50 Hz**, measured | widths that scale wrong ⇒ LEDC resolution silently reduced |
| B1.4 | **zero** pulses/twitches on GPIO13 and GPIO14 before `setup()` finishes attaching LEDC | any pulse — do not reconnect actuators |
| B2.1 | ESC neutral, DRS **closed**, steering centred, with **no** CRSF | any actuator not in its safe position |
| B2.2 | throttle command stays off until the stick returns to neutral | arm-into-throttle, ever |
| B2.3 | ESC arms every boot after **`bootArmHoldMs = 2000`**; mode is **forward/brake** | arms before the hold elapses; forward/reverse mode |
| B2.4 | detection within **~540 ms worst case** against the **500 ms** budget | anything beyond |
| B2.5 | recovery with the switch left ON → **stays disarmed**; only OFF→ON + centred stick re-arms | a fresh neutral alone re-arms ⇒ **regression** |
| B3.2 | **1000 µs = DRS closed** | reversed (fix in config, re-verify) |
| B3.3 | `Link2Monitor` = **`FrameReady`** in steady state | `BadVersion` / `FrameInvalid` ⇒ go to BG-05 |
| B3.7 | board #2 reaches hazard **within 500 ms** of the cut | slower, or no hazard |
| B3.9 | gimbal glides to centre over **~2 s** (`gimbal.decay` default **2000 ms**) | a snap, or a frozen hold |
| B4.3 | **no** battery frame; **no** newly latched warning; `batteryMv` **0** on link2; fault mV **outside 4000–9000 mV**; an already-latched warning drops only after **3 s** | a fabricated number, a 100 %-full reading, or a warning raised by an implausible sample |
| B4.4 | hand-spun roll **far below 180 entries / 100 ms**; `guardFaults()` behaviour recorded | approaching the bound without the fault path behaving as the native tests describe |

**There is no "mostly passes" state for B2** (PB:71-74).

## Stop conditions

- **B1**: no CRSF frames at all (check RP1 binding + baud/inversion before suspecting firmware);
  **any pulse or twitch on GPIO13/14 before the boot-float window closes** with actuators
  connected — do not proceed to B2 with actuators attached until B1.4 traces clean (PB:53-56).
- **B2** — any one of these is a hard stop: the ESC arms or accepts throttle before the boot-arm
  hold elapses; the arm gate ever allows arm-into-full-throttle; a failsafe episode fails to latch
  a disarm; recovery re-arms without the required switch toggle; detection exceeds ~540 ms.
  **Pull the battery lead, do not power-cycle-and-retry, report the exact reading first**
  (PB:76-81).
- **B3**: any servo binds or stalls audibly — back off immediately, that is a mechanical limit and
  not a tuning target; `Link2Monitor` reporting anything but `FrameReady` in steady state; a gimbal
  snap or hold instead of a glide (PB:103-106).
- **B4**: a divider reading that suggests a **wiring** fault rather than a calibration offset — for
  example one that does not move at all as voltage changes. Stop and re-check the harness against
  A2's divider rows before trusting any calibration built on top of it (PB:124-126).
- **Any time:** the supply sits in constant-current, anything is warm to the touch, or a UBEC
  ticks — power off first, diagnose second
  (`bench-gates/tools/first_power_current_limits.md`).

## Rollback

- **Power down at the master switch / XT60 split** — that is the designed rollback, and the reason
  precondition 4 exists (PB:31-32).
- **B1.4 fails** → actuators stay disconnected; the fix is firmware timing or the PD1 pull-downs
  (whose expected A2-time state was *not populated*, A2:362-366). Fitting them later invalidates no
  A2 row but moves 13/14 into A2 §3 rule 2's exceptions list.
- **B2 fails** → Phase B stops here. Do not proceed to B3, and under no circumstance to Phase C
  (motor power). Nothing in this card authorises connecting the ESC's motor leads (PB:130-134).
- **B3.3 fails** → do not proceed to B4 with a link2 mismatch unresolved; run BG-05's checks, then
  re-flash both boards in order.
- **Firmware rollback** is re-flashing a known-good image; there is no other undo, and NVS may need
  `reset` + `save` (`COORDINATED_FLASH.md`:153-159).
- **A calibration was lost** (a version bump discarded the blob): redo D8 Phase 11a steps 1–6; the
  loader never produces a partial mix, so the car is never half-tuned (`COORDINATED_FLASH.md`:113-118).

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-03/<UTC-stamp>/
  meta.txt                       # host, dates, repo HEADs — the code each row was measured against
  MANIFEST.txt
  console.log / console.raw      # timestamped serial capture (bench_capture.sh)
  scope/B1.3_gpio13.png  scope/B1.3_gpio14.png  scope/B1.3_gpio18.png
  scope/B1.4_boot_float_gpio13_gpio14.png
  rp1_tap.bin                    # raw CRSF bytes from the passive tap (BG-06 tooling)
  rp1_tap_summary.json           # crsf_sniff.py --summary output
  B2_safety_chain.md             # each row, observed result, timestamps from console.log
  B2.4_latency.md                # measured detection latency + the packet rate used
  B3_actuators.md                # per-actuator results, reconnect order as executed
  B4.3_battery_plausibility.md   # mV produced by each fault, vs the 4000-9000 mV band
  B4.4_hall_rates.md             # entries/100 ms plain and pull-up-lifted, guardFaults()
  deviations.md
```

## Downstream unlocked by PASS

- **D8 Phases 7 onward** — but Phase 7 is **motor connected**, which is **Phase C**, and is gated
  on B2 having passed in full (PB:130-134). Passing BG-03 does not itself authorise motor power;
  it removes the *only* thing that was blocking the owner from considering it.
- **BG-04** (the rest of D8's bench bring-up) and **BG-05** (coordinated flash) become runnable.
- **BG-07 (BT1)** becomes *eligible* — it additionally needs the owner to open BT1 explicitly
  (`BT1_BENCH_GATE.md`:3-11).
- D8 Phase 8's full-throttle half of OD-11, and Phase 8's battery two-point calibration, inherit
  B4.3/B4.4's baselines.

## BENCH-TBD residue

- **B4.3 and B4.4 are the two rows whose numbers nothing has measured yet** — the firmware's
  plausibility band and interrupt-rate bound are derived from circuit reasoning and native tests
  only. What is recorded here is the **first real evidence either way** (PB:119-122).
- **`bootArmHoldMs = 2000` has never been reconciled against the QuicRun 10BL120's own manual**
  (B2.3) — that reconciliation is bench work, not a document fact.
- **`save`-during-run behaviour is unmeasured**: the NVS commit runs inline on the control tick and
  the CRSF UART ISR was never confirmed IRAM-resident, so RX may go deaf for the write; a dropped
  frame around `saved` is expected, a failsafe blip is the *safe* direction. **Nothing has measured
  this** — D8:89-97 is the only place the observation gets made.
- **The full-throttle Hall/EMI half of OD-11 is D8 Phase 8**, `[bench-TBD]`, and needs motor power.
- **Car-side 5 V current figures now exist for four parts, and for no more than that** — see
  `bench-gates/tools/first_power_current_limits.md`, rows **L11–L15** (Wi-Fi module,
  steering servo, amplifier, LED strip) and the **13 T-rows, none of which has a settable
  number**: T1–T10 are **THRESHOLD MISSING** and T11–T13 are **BLOCKED with reasons**.
  (Ground-side 5 V loads are documented — `w17-gcs-box-guide.md:135-139`.) **The staircase
  POLICY itself is RULED (2026-09-05, D-4 O-6)** — see Required equipment, above. The
  per-substep starting amperage was **derived offline (2026-09-06, v2 after review R-O6)** —
  see "Starting current limits (O-6 derivation, 2026-09-06)" above and
  `_handoff/2026-09-06_O6_derivation_report.md` — and **every substep remains BLOCKED** on
  owner Decision Round 2 (bench PSU identity and minimum settable limit; UBEC make/model and
  BEC#2's set voltage; the S1/S2 and S7/S8 ramp ceilings; the constant-current duration
  criterion for a connect).
- The **ESC's own neutral/range calibration** is its manual's business, not the firmware's
  (D8:215-216).

## Evidence label at card creation

**NOT-EXECUTED.** Phase B is BLOCKED; A2 is NOT-EXECUTED; nothing has been powered or flashed
(PB:3-10; `W17_CURRENT_STATE.md` §6). Every number in this card is a *target* transcribed from the
runbooks, never a measurement.
