# BG-07 — BT1: Bluetooth show-off / Showcase bench gate

*Card for `w17-control-fw/docs/BT1_BENCH_GATE.md` (cited as **BT1**), whose design source is
`w17-control-fw/docs/bt_showoff_design.md` §5/§7/§9.*

> **Gate, verbatim:** BT1 is a Phase B item — it can only begin once powered bench work is legal at
> all (A2 closed, Phase B approved) and it runs **car on stand, wheels off the ground**.
> **No BT code runs on powered hardware before BT1 is opened by the owner** (BT1:3-11). Opening it
> is an explicit owner act, not something a passing Phase B implies.

## Prerequisites

1. **`A2-CLOSED` + `PHASE-B-OPEN`**, and then **BT1 opened by the owner** — three states, not two
   (BT1:3-11; `bt_showoff_design.md` §9).
2. **A2's §S4c selector rows recorded** (continuity/isolation for GPIO27/GPIO32), **or** the
   selector recorded NOT-ASSEMBLED — in which case **this gate is deferred until it is wired**
   (BT1:32-35). `esp32dev_simbt` is the one exception: it needs no physical switch and may be
   exercised independently, because it boots straight into BT_SOLO with **no strap read at all**.
3. **D8 Phase 3b is BT1 item 0** — not a precondition BT1 waits on, but **its first action**, done
   under this same gate. Do the rest of the gate only after Phase 3b passes (BT1:37-40).
4. Wheels off the ground; car on a stand; observer present; battery lead pullable at the master
   disconnect — the same rules as every other Phase B item (BT1:41-42).
5. **A pad: genuine Sony DualShock-class hardware is the spec.** Clone controllers are known-flaky
   (design §5, bluepad32 issue #127), and **a clone failing this gate is not evidence the firmware
   is wrong** (BT1:43-45).

## Required equipment

- The physical **SP3T boot-mode selector**, wired per A2 §S4c — **still on the owner's shopping
  list as of this card** (`CURRENT_STATUS.md` top entry).
- A **genuine DualShock-class pad**, charged. If only a clone is on hand, note it explicitly and
  treat the whole gate as **provisional** (BT1:68).
- Jumper wires, for the two fault cases Phase 3b reproduces by wiring **around** the switch.
- Serial console at 115200 for heap/boot logging.
- **A current meter** for "3.3 V rail draw with BT active vs inactive" (BT1:66).
- An oscilloscope or an instrumented tick counter for "control-tick jitter with BT active"
  (BT1:58).
- `pio` with the custom core the `esp32dev_btshowoff` env pins (Bluepad32/BTstack, core 3.10.2,
  `huge_app.csv` partition — BT1:22-24).

## Topology (ASCII)

```
   ONE physical selector, TWO boot modes, ONE gate
   ----------------------------------------------

     SP3T slide switch          common ------> STAR GROUND
        |  |  |                 SOLO throw --> GPIO27
     SOLO CTR SHOW              SHOW throw --> GPIO32
                                CENTER throw -> EMPTY, no wire at all
                                no resistor anywhere (internal pull-ups, src/main.cpp:718-719)

     resolved mode (BootMode.hpp:125-136, combineStrapPins):
        27 low , 32 open   -> BtSolo     (pad drives the car; CRSF UART NEVER OPENED)
        27 open, 32 open   -> Drive      (byte-identical to a plain esp32dev boot)
        27 open, 32 low    -> Showcase   (CANNOT ARM by any input)
        both low           -> Drive      (harness fault -> fail toward Drive)
        any tie            -> Drive

     builds:
        esp32dev_btshowoff  real Bluepad32/BTstack + real pad + the physical switch  <-- THE gate build
        esp32dev_simbt      scripted SimPadFeeder, stock core, NO Bluetooth at all;
                            forces BtSolo unconditionally and SKIPS the strap read
                            (src/main.cpp:711-715) -> proves NOTHING about the selector
        esp32dev / _tuning / _sim   never read GPIO27/32 (src/main.cpp:147-157) -> Phase 3b is N/A by design

     Car state throughout:  wheels off ground, ESC motor power rules unchanged by anything here.
```

## Exact procedure (numbered)

**Item 0 — D8 Phase 3b, the boot-mode-resolution slice** (BT1:37-40; `D8_BENCH_BRINGUP.md`:99-155):

1. Flash **`esp32dev_btshowoff`** — the only build that reads the selector. **`esp32dev_simbt`
   cannot substitute** (it forces `BtSolo` and skips the strap read entirely).
2. **CENTER (LAPTOP)** → resolves to **Drive**, byte-identical to a plain `esp32dev` boot; the CRSF
   UART opens normally.
3. **SOLO** (GPIO27 grounded, GPIO32 open) → resolves to **BtSolo**. Confirm the **CRSF UART is
   never opened** (`crsfUart.begin()` skipped — `src/main.cpp:770-772`): the RP1 stays powered but
   nothing reads it. Arming requires the pad ritual, not the CRSF arm switch.
4. **SHOW** (GPIO32 grounded, GPIO27 open) → resolves to **Showcase**. Confirm the car **cannot arm
   by any input** — `armSwitchInput()` structurally returns `false`, so the arm gate's neutral-seen
   latch can never set and the ESC never leaves neutral, regardless of handset or pad.
5. **Ground both throws with jumpers** (bypassing the switch itself) → **must resolve Drive**. This
   is the harness-fault case the SP3T part cannot produce on its own.
6. **From SOLO or SHOW, disconnect the grounded throw's wire and re-boot → must resolve Drive.**
7. **Disconnecting the IDLE throw changes nothing, by design.** Do not treat "it didn't switch to
   Drive" as a finding here (`D8_BENCH_BRINGUP.md`:149-153).
8. **Record which physical throw is SOLO and which is SHOW** — A2 proves the wires, this proves the
   labels (A2:451-454).

**The bench-only list — these ARE the gate items** (BT1:47-68). Record **PASS / FAIL / NOT-RUN plus
evidence** for each; this table is the gate's own ledger:

9. **Actual flash fit** — `pio run -e esp32dev_btshowoff` size report; run once and record.
10. **Free-heap watermark** — log free heap at boot, during pairing, while driving, and through a
    **pad disconnect storm** (rapid connect/disconnect).
11. **Control-tick jitter with BT active** — scope or instrument the **50 Hz** control tick while
    `BP32.update()` runs on core 0.
12. **TWDT margin on both cores** — confirm `esp_task_wdt_init(2, true)`'s **2 s** deadline is never
    approached: core 0 under BT load, core 1 under the control loop.
13. **Pairing / reconnect reliability** — multiple pair/unpair/reconnect cycles.
14. **`enableNewBluetoothConnections(false)` lockout** — confirm the post-pairing-window lockout
    actually holds. There is a **filed upstream report of it not functioning** in at least one
    Bluepad32 version (design §5, bluepad32 #130), so this is library behaviour under test, not
    this firmware's code.
15. **Real disconnect → outputs-safe latency** — both the walk-away case **and** the
    pad-power-off case.
16. **DS4 idle report-rate assumption** — confirm the pad's actual idle cadence matches design
    §3.1's assumption.
17. **DS4 auto-sleep behaviour** — what happens to arming/failsafe when the pad auto-sleeps
    mid-session.
18. **Reconnect-without-input probe (review F1, 2026-08-17)** — power the pad back on, or walk back
    into range, and **touch nothing**. The car must stay in failsafe until genuine post-connect
    reports flow: the wrapper seeds its freshness baseline at connect time, so **a bare stack
    reconnect claim alone must yield zero drive-affecting frames**. Design §7 calls this the one
    item needing hardware proof specifically (BT1:65).
19. **3.3 V rail draw with BT active vs inactive** — a real electrical measurement.
20. **ELRS-RX-powered coexistence** — the RP1 stays powered on the UBEC rail even in BT mode
    (nothing reads it, but it is transmitting/receiving); confirm no RF interference with the BT
    radio at 2.4 GHz close range.
21. **Genuine-vs-clone note** — if only a clone pad was used, say so, and mark the gate provisional.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# Gate check: A2 closed, Phase B approved, AND BT1 opened by the owner.
grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN\|BT1" CURRENT_STATUS.md | head

bench-gates/tools/bench_capture.sh BG-07 --no-serial --note "BT1: item 0 (Phase 3b) then the bench-only list"

# Item 9 — flash fit, measured at build time (host-only; safe before the gate opens):
cd w17-control-fw
pio run -e esp32dev_btshowoff        # record the RAM/Flash size report verbatim
pio run -e esp32dev                  # the comparison build

# Item 0 — the only build that reads the selector (GATE MUST BE OPEN):
pio run -e esp32dev_btshowoff -t upload

# Boot/heap/pairing capture, per selector position and through the disconnect storm:
cd /Users/vitaliykhomenko/Documents/projects
bench-gates/tools/bench_capture.sh BG-07 --port /dev/tty.usbserial-XXXX \
  --baud 115200 --seconds 900 --note "BT1 item <N>: <what you are doing>"

# ELF quarantine spot-check — the positive control that keeps D8 Phase 11a's
# `0` from being a vacuous 0 (host-only, no hardware):
xtensa-esp32-elf-nm -C w17-control-fw/.pio/build/esp32dev_btshowoff/firmware.elf \
  | grep -c -E "console::|btpad|luepad|btstack"      # expect 216 at the cited revision
xtensa-esp32-elf-nm -C w17-control-fw/.pio/build/esp32dev_btshowoff/firmware.elf \
  | grep -c -E "console::"                            # expect 0 — _tuning's flag is never set here
```

## Expected evidence

- **Phase 3b's resolution table**: each selector position → resolved mode, plus both jumper fault
  cases, plus the **label record** (which throw is SOLO, which is SHOW).
- A console capture showing, for SOLO, that **the CRSF UART was never opened**.
- A console capture showing, for SHOW, that **arming never completes** under any input attempted.
- **Free-heap numbers** at boot / pairing / driving / disconnect-storm, as a series, not a single
  reading.
- A **tick-jitter measurement** with BT active, and the **TWDT headroom** on both cores.
- Pair/unpair/reconnect **cycle counts and outcomes**.
- The **lockout** result, explicitly stated as holding or not (this is the item with a known
  upstream bug report against it).
- **Disconnect → outputs-safe latency**, for both the walk-away and the power-off case.
- The **reconnect-without-input probe** result: zero drive-affecting frames on a bare reconnect.
- **3.3 V rail current, BT active vs inactive**.
- Whether the pad was **genuine or a clone**.

## PASS/FAIL criteria (objective numbers)

| Item | PASS | FAIL |
|---|---|---|
| Phase 3b: CENTER | resolves **Drive**, CRSF UART opens | any other mode |
| Phase 3b: SOLO | resolves **BtSolo**, **`crsfUart.begin()` never called** | CRSF UART opened in BtSolo |
| Phase 3b: SHOW | resolves **Showcase**, **cannot arm by any input** | any input path that arms |
| Phase 3b: both throws grounded | resolves **Drive** | anything else ⇒ **bench finding, stop, do not proceed** |
| Phase 3b: grounded throw disconnected | resolves **Drive** | anything else ⇒ same |
| Flash fit | RAM **26.6 %** (87076/327680 B), Flash **23.6 %** (742305/3145728 B of the `huge_app.csv` 3 MB slot) at the cited revision (BT1:72-74) | a build that no longer fits its partition |
| ELF positive control | combined count **216** (`btpad` alone **27**), and `console::` **0** (BT1:77-81) | a zero combined count ⇒ the check is vacuous, not clean |
| TWDT margin | the **2 s** deadline never approached on either core under load | any approach ⇒ report, do not tune it away |
| Control tick | **50 Hz** maintained with `BP32.update()` running on core 0 | jitter that breaks the tick |
| Reconnect-without-input | **zero** drive-affecting frames on a bare stack reconnect | any drive-affecting frame ⇒ the whole BT mode is unsafe as built |
| Lockout | `enableNewBluetoothConnections(false)` **holds** | it does not ⇒ an upstream-library finding, recorded as such |
| Pad provenance | genuine DualShock-class | clone ⇒ gate is **provisional**, and a clone FAIL is **not** evidence against the firmware |

> **THRESHOLD MISSING — owner/bench decides:** *the acceptable free-heap watermark*, *the
> acceptable control-tick jitter*, *the acceptable disconnect → outputs-safe latency*, and *the
> acceptable 3.3 V draw with BT active*. BT1 lists all four as things to **observe and record**;
> it fixes a number for **none** of them (BT1:54-68). The first run is what sets them, and the
> owner rules on whether each is acceptable. Do not import a number from elsewhere.
>
> **What to expect (not a threshold — a planning envelope, non-canonical, do not treat as a
> standard):** `_handoff/2026-08-16_bt_showoff_design_draft.md`:296-299 estimates Bluedroid
> Classic BT at **≈140 KB of heap** (≈70 KB base reservation + ≈70 KB on stack start), leaving
> **≈150 KB free** worst-case on a WROOM-32's 520 KB SRAM; and `:119` carries forward the CRSF
> failsafe's own **same 500 ms staleness timeout, ≈540 ms worst-case detection including tick
> quantization** as the BT-mode disconnect path, since it is the identical `FailsafeStateMachine`
> instance. The draft itself says at `:283-284` these are *"planning envelopes from cited
> sources, not measurements of this firmware — the bench gate (§9) owns the real numbers,"* and
> `_handoff/README.md` marks the whole folder non-canonical. This row's own THRESHOLD MISSING
> claim stands unchanged; the envelope is only a sanity check for what BG-07's first run should
> land near.

## Stop conditions

- **BT1 not explicitly opened by the owner** → nothing below runs. Flashing a `W17_BT_SHOWOFF`
  image and booting SOLO brings up the pad stack, which is BT code on powered hardware
  (`D8_BENCH_BRINGUP.md`:101-108).
- **Either Phase 3b jumper fault case resolving to anything but Drive** → **stop and report**; this
  is a bench finding, not a documentation gap (`D8_BENCH_BRINGUP.md`:139-148).
- **A drive-affecting frame on a bare reconnect** (item 18) → stop. That is the single item the
  design says needs hardware proof specifically, and a failure there is a safety failure, not a
  polish item.
- **Showcase arming under any input** → stop; the mode's entire premise is that it structurally
  cannot arm.
- **Only a clone pad available** → not a stop, but the gate is **provisional** and must be labelled
  so wherever it is cited.
- Standing Phase B stops apply unchanged: wheels off the ground, ESC motor-power rules untouched by
  anything in this gate (BT1:5-7).

## Rollback

- **Re-flash `esp32dev_tuning` or plain `esp32dev`** — neither reads GPIO27/32, so the selector goes
  electrically inert and the car returns to the delivery-lineage behaviour
  (`src/main.cpp:147-157`).
- **The `esp32dev_btshowoff` build uses `huge_app.csv` with no OTA slot, by design** (BT1:72-74) —
  moving back to a default-partition build is a full re-flash, not a partial one.
- **NVS**: v2 carries `btpad::BtPadConfig` tunables (`COORDINATED_FLASH.md`:110-112). A same-version
  re-flash round-trips the blob; a version change discards it entirely and needs a recalibrate +
  `save`.
- **If BT1 fails**: the ship image stays plain **`esp32dev`** — which is the OD-2 **default**
  anyway. Nothing about a BT1 failure blocks the gift; it only forecloses the upgrade
  (`D8_BENCH_BRINGUP.md`:344-355).

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-07/<UTC-stamp>/
  meta.txt   MANIFEST.txt   console.log   console.raw
  item0_phase3b_matrix.md        # position -> mode, both jumper cases, LABEL record
  item0_solo_no_crsf_uart.log
  item0_show_cannot_arm.log
  flash_fit.txt                  # pio size report, verbatim
  elf_positive_control.txt       # 216 combined / 27 btpad / 0 console::
  heap_watermark.md              # boot / pairing / driving / disconnect storm
  tick_jitter.md                 # 50 Hz tick with BP32.update() on core 0
  twdt_margin.md                 # both cores vs the 2 s deadline
  pairing_cycles.md              # counts and outcomes
  lockout_result.md              # enableNewBluetoothConnections(false)
  disconnect_latency.md          # walk-away AND power-off
  reconnect_without_input.md     # THE probe: zero drive-affecting frames
  rail_3v3_draw.md               # BT active vs inactive
  pad_provenance.txt             # genuine or clone — and if clone, "PROVISIONAL"
```

## Downstream unlocked by PASS

- **`BT1` (master sequence stage 9)** closes (`w17-parts-to-gift-master-sequence.md`:261-274).
- It makes the **`OWNER-DECISION(SHIP-IMAGE)` upgrade path available**: under **OD-2** the ship
  image is **plain `esp32dev` by default**, and upgrading to `esp32dev_btshowoff` is **conditional
  on BT1 having PASSED before handover**, with **the PASS date and evidence recorded** at D8 Phase
  11a step 7 — not on the owner's say-so alone (`D8_BENCH_BRINGUP.md`:344-368).
- If the upgrade is taken, D8 Phase 11a step 7's **single combined grep becomes the wrong check**:
  split it into `console::` **must be 0** and the BT-pattern count, now **expected non-zero**, as
  the new positive control.
- **BT1 passing proves the mode works, not that it ships** (BT1:83-89).

## BENCH-TBD residue

- **The SP3T switch is not in hand.** Until it is, A2 §S4c closes NOT-ASSEMBLED and **this gate is
  deferred** (BT1:32-35; `CURRENT_STATUS.md` shopping list).
- **All four acceptance numbers are unset** (heap, jitter, disconnect latency, BT rail draw) — see
  the THRESHOLD MISSING note above.
- **The upstream lockout bug** (bluepad32 #130) may reproduce; if it does, the finding is upstream
  library behaviour, and what this gate produces is evidence, not a fix.
- **Clone-pad flakiness** (bluepad32 #127) can make a genuine-firmware PASS look like a FAIL.
- If the ship image stays `esp32dev` (the OD-2 default) **and** the selector is wired into the
  delivered car, **the switch is electrically inert on the delivered car — by design under OD-2**,
  not an oversight to flag (BT1:85-89; `D8_BENCH_BRINGUP.md`:352-355).

## Evidence label at card creation

**NOT-EXECUTED.** BT1 has never been opened; A2 is NOT-EXECUTED, Phase B is BLOCKED, and the SP3T
selector is not yet purchased (BT1:3-11; `CURRENT_STATUS.md`). The flash-fit and ELF numbers quoted
above are **INFERRED from BT1's own recorded build measurements**, not measured in this session.
