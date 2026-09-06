# BG-04 — D8 bench bring-up (Phases 0–9, plus 10/11/11a as the tail)

*Card for `w17-control-fw/docs/D8_BENCH_BRINGUP.md` (cited as **D8**). BG-03 is the
safety-ordered *why* for Phases 1–6; this card is the wrapper around the checkbox-level runbook,
including the phases BG-03 deliberately does not cover: Phase 0, Phase 3b, Phases 7–11a.*

> **D8 Phase -1 is a HARD STOP**: A2 CLOSED and Phase B APPROVED, or stop. As of this card neither
> is true (D8:3-13). **Re-check `CURRENT_STATUS.md` immediately before Phase 1 and again before
> Phase 3** — gate state can move between sessions (D8:8-10).

## Prerequisites

1. `A2-CLOSED` **and** `PHASE-B-OPEN` recorded and dated (BG-02, then the owner). Re-read them at
   the two points D8 names, not once at the start.
2. **BG-03 passed** — in particular **B2, the safety chain**. D8 Phase 7 (motor) is gated on it.
3. Wheels off the ground; observer present; battery pullable at the master switch.
4. Both PlatformIO projects present and building: `w17-control-fw` and `w17-soundlight-fw`.
5. For Phase 3b only: the **SP3T selector physically wired** (A2 §S4c) **and** BT1 open — Phase 3b
   *is* BT1's first item, not a precondition BT1 waits on (D8:101-108; `BT1_BENCH_GATE.md`:37-40).
   On the three delivery-lineage builds Phase 3b is **N/A by design** (they resolve Drive at
   compile time, `src/main.cpp:147-157`); record it that way rather than leaving it blank
   (D8:110-117).
6. For Phase 10: the ground station on Windows. That half belongs to the ground track — see
   `w17-windows-vm-validation-runbook.md` and the ground bench-gate cards.

## Required equipment

- Everything BG-03 lists, plus:
- **The motor and its sensor cable** for Phase 7 — and the discipline that Phase 7 does not start
  until Phase 5 passes (D8:17-19).
- The **tie-rod / steering linkage** for Phase 6 (fitted *after* the servo is centred in firmware).
- The camera pod + two MG90S for Phase 7b.
- Speaker + MAX98357A for Phase 9; the WS2812 strip.
- **`xtensa-esp32-elf-nm`** on PATH for the Phase 11a ELF spot-check (D8:337).
- A ground-station PC for Phase 10 (out of this card's scope; listed so it is not a surprise).

## Topology (ASCII)

```
  PHASE ORDER IS A DEPENDENCY CHAIN — each phase is the next one's safety gate (D8:16-19)

   -1  GATE: A2 CLOSED + Phase B APPROVED ........................ or STOP
    0  pre-power electrical fixes (no battery)   <-- the A2 build fixes, re-verified
    1  power-rail smoke   [FIRST BATTERY]        BEC#1 ~5 V, BEC#2 ~5-6 V under light load
    2  ELRS link          [no actuators]         420000 8N1 not inverted; failsafe = "No Pulses"
    3  control board      [FIRST USB / FIRST FLASH]  esp32dev_tuning; boot-safe with TX off
   3b  boot-mode selector [BT1 GATE]             SOLO/CENTER/SHOW -> BtSolo/Drive/Showcase
    4  channel map + switch thresholds           every 2-pos switch crosses +/-250 both ways
    5  FAILSAFE + ARM GATE PROOF  ***THE GATE***  no ESC power until every box passes
    6  steering servo                            centre in firmware BEFORE fitting the linkage
    7  ESC + motor        [WHEELS OFF GROUND]    <-- Phase C territory; BG-03 does not cover it
   7b  camera gimbal                             ~2 s glide to centre on link loss
    8  telemetry sensors                         battery 2-point cal; Hall EMI at full throttle
    9  link2 -> board #2                         FrameReady; cut wire -> hazard within 500 ms
   10  ground station (Windows)                  codec, mediamtx, telemetry port  [ground track]
   11  on the car                                re-confirm Phase 5 ON THE CAR
  11a  DELIVERY HAND-OFF                         calibrate on _tuning -> ship plain esp32dev
```

## Exact procedure (numbered)

1. **Phase 0 — pre-power electrical fixes, before ANY battery** (D8:33-47). These are the A2 build
   fixes read back as a checklist: ESC red wire isolated; divider **27 kΩ / 10 kΩ** on GPIO34;
   **100 nF GPIO34 → GND**; A3144 **VCC = 5 V, 10 kΩ pull-up to 3.3 V**, open-collector out to
   GPIO35; WS2812 **330 Ω series + 1000 µF + 1N5819**; **1000 µF on the servo rail**; all grounds
   common; rail membership as built.
2. **Phase 1 — power-rail smoke.** **Re-confirm the Phase -1 gate first — this is the first battery
   connection of the bring-up** (D8:51-53). Battery → XT60 Y-split → ESC + BEC#1 + BEC#2. Confirm
   **BEC#1 ≈ 5 V** and **BEC#2 ≈ 5–6 V under a light load, before connecting the ESP32s**. Confirm
   no rail sag/brownout when a servo moves. **Note (O-6 derivation v2, 2026-09-06 — see BG-03's
   "Starting current limits" subsection and `_handoff/2026-09-06_O6_derivation_report.md`):**
   (a) a battery has **no settable current limit**, so this phase has no current-limit
   protection at all (§3.3). **RESOLVED — DR2-5 RATIFIED 2026-09-06 (owner Q3):** the earlier
   "open doc conflict" between BG-03's *Required equipment* (bench PSU) and this line/D8:55
   (battery) is not a conflict — DR2-5 rules bench-PSU-first, with the ESC feed physically
   separated, for the S0–S9 staircase; **this Phase 1 battery connection is the first battery
   connection and follows that staircase**, it does not replace it. (b) **Record
   BEC#2's measured output voltage here**, not just its pass/fail: it selects the DS3235SG
   stall column used as the never-exceed for BG-03's Rail-B substeps — **2.1 A at 6 V** vs
   **1.9 A at 5 V** (owner **Q2** — DR2-4, still BLOCKED on photo/label packet item 2 — can
   supply it from the label beforehand). (c) **RULED — DR2-11 2026-09-06 (owner Q9):** the
   constant-current criterion for the pack connect: "continuous PSU constant-current operation
   lasting more than 500 ms after connection = STOP" (500 ms is a STOP threshold, not a
   permission — record the actual observed CC duration here regardless of whether it trips);
   note that C1 and C2 are **5 V-side** capacitors, so what a pack-side supply would see here is
   the UBECs' input capacitance and soft-start, not C1/C2. **No gate state here changes.**
3. **Phase 2 — ELRS link, no actuators.** Bind RP1 + ES24TX Pro (+ TX16S backup) at the **same
   major.minor and the same bind phrase**. **Set RP1 failsafe mode to "No Pulses"** — "Set Position"
   defeats the frame-timeout failsafe (D8:63-64). Serial-dump the CRSF output: **420000 8N1, not
   inverted, sync 0xC8, type 0x16** arriving. **Characterise link loss**: the LQ=0 LINK_STATISTICS
   burst on disconnect (count + timing), the ~100 ms stats cadence while connected, the
   disconnect-declaration latency at your packet rate, and that the RX emits **no RC frames before
   first connection**.
4. **Phase 3 — control board, actuators disconnected.** **Re-check the gate; this is the first USB
   and the first flash** (D8:74-77). Flash `esp32dev_tuning`. Confirm CRSF reception on `status`.
   Confirm **boot is safe with the TX off** — no spurious "active" (this is the bug that used to
   slam steering to full lock; verify it is gone on real hardware). Record what `save` actually
   does to the link (D8:89-97) — nothing has measured it.
5. **Phase 3b — boot-mode selector**, only if wired **and** BT1 is open. Flash `esp32dev_btshowoff`
   (**`esp32dev_simbt` cannot be used** — it forces `BtSolo` and skips the strap read entirely,
   `src/main.cpp:711-715`). Then: **CENTER → Drive**; **SOLO → BtSolo** with the **CRSF UART never
   opened** (`src/main.cpp:770-772`); **SHOW → Showcase**, which **cannot arm by any input**.
   Then two fault cases only reproducible by wiring around the part: **both throws grounded with
   jumpers → must resolve Drive**; **from SOLO or SHOW, disconnect the grounded throw → must
   resolve Drive**. Disconnecting the **idle** throw changes nothing, by design — do not treat that
   as a finding. Finally **record which physical throw is SOLO and which is SHOW** — A2 proves the
   wires, this phase proves the labels (D8:119-155).
6. **Phase 4 — channel map + switch thresholds.** Confirm `ChannelMapConfig` matches the actual TX
   mapping (steering ch1, throttle ch3, arm ch5, DRS ch6, gearUp ch7, gearDown ch8, boost ch11,
   overtake ch12, drive-mode ch13). Confirm **every 2-position switch crosses both ±250 hysteresis
   thresholds — especially the ARM switch's OFF direction**. Confirm the drive-mode 3-position
   switch hits all three detents (D8:157-165).
7. **Phase 5 — failsafe + arm gate PROOF. THE GATE.** Seven checks, all of which BG-03's B2 covers
   at the *why* level; run them here as checkboxes (D8:167-188), including the **re-arm invariant**
   and the hold-position case (LQ=0 while frames still arrive → still drops to safe).
8. **Phase 6 — steering servo.** **Centre the servo in firmware BEFORE attaching the linkage**;
   *then* fit the tie-rod so the wheels are straight at neutral. Trim with `set steer.center` /
   `set steer.trim`, then `save`. **Calibrate endpoints conservatively from centre outward** —
   start around centre ±200 µs and widen in small steps only while the linkage moves freely;
   **stop at the first sign of binding or servo buzz** and back off. The console rejects any
   endpoint outside **500–2500 µs**, out of order, or excluding centre(+trim). `save`,
   power-cycle, confirm the read-back, re-check both locks (D8:190-208).
9. **Phase 7 — ESC + motor, wheels OFF the ground.** ESC in **sensored** mode and **forward/brake**
   (not forward/reverse); sensor cable plugged. ESC neutral/range calibration per its own manual.
   Power-on arm sequence; gears cap throttle; brake below neutral; ERS in mode 2. **Wheels on the
   ground only after all of it feels right** (D8:210-223).
10. **Phase 7b — camera gimbal.** Map right stick X→ch9, Y→ch10 in elrs-joystick-control; fit both
    MG90S; confirm centring, tracking, non-inversion; **~2 s glide to centre on link drop**
    (`gimbal.decay`, default **2000 ms**), and a glide back on recovery; no bind at the extremes
    (D8:225-236).
11. **Phase 8 — telemetry sensors.** Battery **two-point calibration** at ~6.5 V and ~8.4 V, set
    `batt.ppt`, `save`; log the eFuse cal type. Hall wheel speed by hand, then **scope GPIO35 near
    the motor at full throttle** for EMI double-counts. **OD-11's full-throttle half**: log
    `isrEntries()` / `lastWindowEntries()` / `guardFaults()` over a full-throttle pass, then with
    the pull-up lifted; expect **≲ 9 entries / 100 ms** in normal running against the guard's
    **180 / 100 ms** bound; a window that ran more than 10× long is judged only when it carries
    **≥ 10×** the elapsed-scaled allowance (a 2 s stall: **36 000** entries) — the 10× factor is
    the source's, `D8_BENCH_BRINGUP.md`:254-256, and dropping it makes the rule stricter than the
    firmware and inconsistent with the 36 000 quoted beside it. Use `npm run demo:low-battery` on
    the ground station to confirm the HUD's warning UI **before** trusting a real low reading, so a
    HUD bug and a hardware defect are never diagnosed as the same thing (D8:238-262).
12. **Phase 9 — link2 → board #2.** Flash soundlight; wire GPIO25 → GPIO16, **common ground**,
    115200 8N1. MAX98357A GAIN strap (start 9 dB floating). WS2812 behaviours. **Cut the UART
    mid-run → board #2 goes to its own local failsafe within 500 ms** (D8:264-277). Two-board order
    detail is **BG-05**.
13. **Phase 10 — ground station (Windows).** Out of this card's scope; the ground bench-gate cards
    and `w17-windows-vm-validation-runbook.md` own it. Listed here only so the chain stays visible
    (D8:279-291).
14. **Phase 11 — on the car.** Mount both boards, camera and battery centrally; **re-confirm Phase 5
    on the car**; short low-gear shakedown; re-trim and `save` (D8:293-299).
15. **Phase 11a — delivery hand-off.** The single canonical delivery procedure, nine steps
    (D8:301-383): flash `_tuning` → calibrate → `save` (must print `saved`) → **`get` every key
    back** (`status` is *not* a substitute: it prints only gear 1) → record those values as the
    shipped tune, including `sound.volume` → power-cycle and confirm `[tune] loaded settings from
    flash` → flash plain `esp32dev` → **ELF spot-check must print `0`** → verify the tuning is live
    on the plain build → **re-run Phase 5's safe-state checks on the delivery firmware**.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# Phase -1, and again before Phase 1 and Phase 3 (D8:8-10):
#   STOP if any line says "Phase B stays BLOCKED", or no dated "PHASE-B-OPEN" line
#   appears: the rest of this card is not runnable.
grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN" CURRENT_STATUS.md | head

bench-gates/tools/bench_capture.sh BG-04 --no-serial --note "D8 bench bring-up, phase <N>"

# Phase 3 — bench firmware (the first flash of the project):
cd w17-control-fw && pio run -e esp32dev_tuning -t upload

# Phase 3b — the ONLY build that reads the selector:
pio run -e esp32dev_btshowoff -t upload     # BT1 must be open first

# Phase 9 — board #2 (its only delivery env):
cd ../w17-soundlight-fw && pio run -e esp32dev -t upload

# Phase 11a step 7 — the delivery ELF spot-check. MUST print 0:
cd ../w17-control-fw
pio run -e esp32dev
xtensa-esp32-elf-nm -C .pio/build/esp32dev/firmware.elf \
  | grep -c -E "console::|btpad|luepad|btstack"

# Positive controls, so a 0 is never a vacuous 0:
pio run -e esp32dev_tuning
xtensa-esp32-elf-nm -C .pio/build/esp32dev_tuning/firmware.elf \
  | grep -c -E "console::"                    # expect 6 at the cited revision
pio run -e esp32dev_btshowoff
xtensa-esp32-elf-nm -C .pio/build/esp32dev_btshowoff/firmware.elf \
  | grep -c -E "console::|btpad|luepad|btstack"   # expect 216 at the cited revision

# Phase 11a steps 4-5 — the shipped tune, read back key by key (console):
#   get steer.min · get steer.max · get steer.center · get steer.trim
#   get batt.ppt · get gimbal.decay · get sound.profile · get sound.volume
#   get gear.<N>.max · get gear.<N>.expo      (for EVERY gear — status shows only gear 1)

# Console capture for any phase:
bench-gates/tools/bench_capture.sh BG-04 --port /dev/tty.usbserial-XXXX \
  --baud 115200 --seconds 900 --note "D8 phase <N>"
```

## Expected evidence

- **Every checkbox in Phases 0–9 checked with an observed result, not an assumed one**
  (`w17-parts-to-gift-master-sequence.md`:216-217).
- Phase 1: the two BEC voltages under light load, written down.
- Phase 2: the link-loss characterisation — burst count and timing, stats cadence, declaration
  latency, and the "no RC frames before first connection" observation.
- Phase 3: the boot-safe observation with the TX off, and the `save`-during-run observation
  (currently unmeasured anywhere).
- Phase 3b: a table of **selector position → resolved mode**, including the two jumper fault cases,
  and the **label record** (which throw is SOLO, which is SHOW).
- Phase 6: the final `steer.min` / `steer.max` / `steer.center` / `steer.trim` — **hardware
  calibration evidence for this specific car**, not values software can prove safe (D8:206-208).
- Phase 8: the eFuse cal type, the `batt.ppt` value, the Hall scope trace, and the OD-11 numbers.
- Phase 11a: the read-back `get` values as the **shipped tune**, and the ELF spot-check output with
  both positive controls.

## PASS/FAIL criteria (objective numbers)

| Phase | PASS | FAIL |
|---|---|---|
| 1 | **BEC#1 ≈ 5 V**, **BEC#2 ≈ 5–6 V** under light load, before the ESP32s are connected | outside those, or measured with the boards already attached |
| 2 | **420000 baud, 8N1, NOT inverted**; sync **0xC8**; type **0x16** frames arriving; RX failsafe mode = **"No Pulses"** | any other baud/inversion; "Set Position" left configured |
| 3 | boot with TX off sits in failsafe — **no** spurious "active" | any spurious active state |
| 3b | CENTER→**Drive**, SOLO→**BtSolo** (CRSF UART **never opened**), SHOW→**Showcase** (**cannot arm by any input**); both-grounded→**Drive**; grounded-throw-disconnected→**Drive** | any other resolution ⇒ bench finding, stop, do not proceed to Phase 4 |
| 4 | every 2-position switch crosses **both ±250** thresholds; 3-position hits **all three** detents | an ARM switch that never goes below −250 (ARM becomes impossible to turn off) |
| 5 | all seven boxes pass, including the **re-arm invariant** | any single box ⇒ no ESC power |
| 6 | endpoints inside **500–2500 µs**, ordered, centre(+trim) included; read back after a power-cycle | binding or servo buzz at an endpoint |
| 7 | ESC **sensored** + **forward/brake**; arms after the neutral hold | forward/reverse mode; arming before the hold |
| 7b | glide to centre over **~2 s** (`gimbal.decay` default **2000 ms**) | snap or hold |
| 8 | normal-running Hall **≲ 9 entries / 100 ms** against the **180 / 100 ms** guard bound | approaching the bound without the documented fault path behaviour |
| 9 | `FrameReady` on board #2; cut UART → hazard **within 500 ms** | `BadVersion` / `FrameInvalid`; slower hazard |
| 11a | ELF spot-check prints **`0`**; positive controls **non-zero** (`_tuning` `console::` = **6**, `btshowoff` combined = **216** at the cited revision) | anything but 0 on the delivery ELF ⇒ **do not ship** |

**Resource numbers at the cited revision** (re-run if code changed): `esp32dev` RAM **7.0 %**
(22948/327680 B), Flash **23.2 %** (304013/1310720 B); `esp32dev_btshowoff` RAM **26.6 %**
(87076/327680 B), Flash **23.6 %** (742305/3145728 B of the `huge_app.csv` 3 MB slot)
(D8:348-351, `BT1_BENCH_GATE.md`:70-81).

## Stop conditions

- **Phase -1 not clear** — A2 not closed or Phase B not approved. Stop; this is the whole runbook's
  precondition, re-checked before Phase 1 and Phase 3 (D8:3-13).
- **Phase 5 incomplete** → no ESC power, full stop. That is the golden rule the whole runbook exists
  to protect (D8:17-19).
- **Phase 3b resolves a mode it should not** (either jumper fault case) → **bench finding, not a
  documentation gap**: stop and report rather than proceeding to Phase 4 (D8:139-148).
- **Phase 6**: mechanical binding or servo stall at an endpoint → back the endpoint off; do not
  widen to "make it reach".
- **Phase 9**: anything other than `FrameReady` in steady state → BG-05 before continuing.
- **Phase 11a**: the ELF spot-check prints anything but `0` on the delivery ELF → **do not ship**
  (`w17-parts-to-gift-master-sequence.md`:258-259).
- Any smell, heat, or audible stress from a servo or a UBEC → power off first.

## Rollback

- **Per-phase**: a phase that fails does not advance. The chain is a dependency chain, and skipping
  forward removes the gate the next phase relies on.
- **Firmware**: re-flash a known-good image. There is no other undo (`COORDINATED_FLASH.md`:153-158).
- **Calibration wipe**: flash `esp32dev_tuning`, `reset` (RAM only) then `save` (writes the defaults
  blob), or erase the `w17tune` NVS namespace. The delivery `esp32dev` build has **no** reset or
  save by design — rolling back tuning requires temporarily returning to `_tuning` (D8:387-391).
- **Return to bench**: re-flash `esp32dev_tuning` at any time; it reads the same NVS blob, so the
  car comes back on its saved calibration with the console enabled (D8:392-394).
- **A corrupt blob is self-healing**: any build boots on complete compiled defaults rather than a
  partial mix (D8:395-397).
- **Phase 11 on-car**: if Phase 5 does not re-confirm on the car, the car comes back to the bench.
  Mounting is not a reason to accept a weaker safety result.

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-04/<UTC-stamp>/
  meta.txt   MANIFEST.txt   console.log   console.raw
  phase0_prepower_fixes.md
  phase1_rails.md               # BEC#1 and BEC#2 volts under light load
  phase2_elrs_linkloss.md       # burst count+timing, stats cadence, declaration latency
  phase3_boot_safe.md           # TX-off boot; the `save`-during-run observation
  phase3b_bootmode_matrix.md    # position -> mode, both jumper fault cases, LABEL record
  phase4_channel_map.md
  phase5_failsafe_arm_proof.md  # seven boxes, with console timestamps
  phase6_steering_calibration.md# steer.min/max/center/trim as calibrated
  phase7_esc.md   phase7b_gimbal.md
  phase8_telemetry.md           # eFuse cal type, batt.ppt, Hall scope, OD-11 numbers
  scope/phase8_hall_gpio35_fullthrottle.png
  phase9_link2.md
  phase11a_delivery_handoff.md  # the nine steps, each with its observed result
  phase11a_shipped_tune.txt     # every `get` value = the authoritative shipped record
  phase11a_elf_spotcheck.txt    # the 0, plus both positive controls
  deviations.md
```

## Downstream unlocked by PASS

- Phases 0–9 green ⇒ **stage 6 of the master sequence is done**
  (`w17-parts-to-gift-master-sequence.md`:208-219).
- Phase 9 green ⇒ **BG-05**'s post-flash verification has its on-the-bench half.
- Phase 11a green (ELF spot-check `0`, Phase 5 re-run on the delivery build) ⇒ **the car is
  shippable as `esp32dev`**, which is the `OWNER-DECISION(SHIP-IMAGE)` default under **OD-2**
  (D8:344-355).
- Upgrading the ship image to `esp32dev_btshowoff` is **conditional on BG-07 (BT1) having PASSED
  before handover**, with the PASS date and evidence recorded — not a free choice at flash time
  (D8:344-368).

## BENCH-TBD residue

- **`save`-during-run**: the NVS commit runs inline on the control tick; the CRSF UART ISR was
  never confirmed IRAM-resident under the pinned core; the 128-byte FIFO covers only ~3 ms at
  420 kbaud. **Nothing has measured this** — D8:89-97 is the only place it gets observed.
- **OD-11's full-throttle half** (`[bench-TBD]`, D8:246-256) and the **Hall EMI** question (whether
  a 1–10 nF cap is needed at all) are both open.
- **The `bootArmHoldMs = 2000` vs QuicRun-manual reconciliation** is unmade.
- **Phase 3b's labels** cannot be proven by A2, only by a running `esp32dev_btshowoff` — which is
  BT1-gated (A2:451-454).
- **NVS v1→v2 migration is hypothetical**: no board has ever been flashed with either blob version
  (`COORDINATED_FLASH.md`:104-107). Phase 11a step 6 is what turns that into evidence.
- **The steering endpoints are per-car hardware evidence**, not values software can prove safe
  (D8:206-208) — they cannot be pre-computed here.
- **Phase 10 is the ground track's**, and Windows behaviour is unproven until the VM validation
  session (`W17_CURRENT_STATE.md` §6).

## Evidence label at card creation

**NOT-EXECUTED.** D8's Phase -1 hard stop is unmet: A2 is NOT-EXECUTED and Phase B is BLOCKED
(D8:3-13). No phase in this card has been run; nothing has been flashed or powered.
