# 13 — Bare-Board Smoke Test: Your First Real ESP32 Power-Up

**What this chapter is:** a complete, do-this-then-that manual for powering up and
testing the three newly delivered ESP32 boards **bare** — no wires, no servos, no ESC,
no battery, nothing connected to any pin, just one board at a time on a USB cable.
You will flash the bench (`esp32dev_tuning`) firmware, watch it boot, talk to its
serial console, and physically validate the NVS settings save/load path that until
today was only proven in simulation.

**Why it exists / authority:** the firmware repo's standing rule
(`w17-control-fw/CLAUDE.md`, "Hardware gates") forbids *any* powered bring-up —
including USB — before the A2 no-power checklist passes. A2, however, checks the
**assembled car harness**, which does not exist yet (servos, receiver, UBECs still in
transit). **Vitaliy (owner) approved this bare-board exception on 2026-07-17**, scoped
exactly as this chapter describes. The A2 and Phase B gates for the *car harness*
remain fully in force and are not touched by anything here.

**The scope rules (read these twice):**

1. **Nothing is ever connected to any pin.** No jumper wires, no servos, no LEDs, no
   "just one little test wire." The board touches only the USB cable.
2. **One board at a time**, on a non-conductive surface (wood desk, silicone mat, the
   anti-static bag it shipped in — foam side). Not on a metal laptop lid, not on a
   pile of resistor legs.
3. **Attended only.** You sit with it while it is plugged in; unplug before walking
   away.
4. **No battery, no bench PSU, no ESC, ever, in this session.** USB from the Mac is
   the only power source.
5. When you are done, the board gets returned to compiled defaults (§9) and unplugged.

---

## 1. What you need

- **One** of the three delivered ESP32 boards (we will do all three, §10 — but one at
  a time).
- A **micro-USB data cable**. ⚠️ Many micro-USB cables are *charge-only* (two wires
  inside instead of four) and will power the board but never show a serial port. If in
  doubt, use a cable that has previously synced data on some device. This is the
  single most common "it doesn't work" cause.
- The Mac with this workspace (PlatformIO already installed and proven — the native
  test suite ran 224/224 on it on 2026-07-17).
- A marker or three small stickers to label the boards **1 / 2 / 3** (§10).
- This chapter open, plus a place to write results (a text file or paper — §11 has
  the template).

Nothing else. No multimeter needed (nothing is powered beyond USB), no soldering.

## 2. Identify the board before plugging anything in

The project is designed around the **ESP32-WROOM-32 DevKit V1**
(**[C]** `w17-control-fw/CLAUDE.md` "MCU: ESP32-WROOM-32 DevKit V1"). Confirm each
delivered board matches:

- A rectangular **metal-canned module** occupying one end, silkscreened
  **ESP32-WROOM-32** (the can is the radio shield; the antenna is the exposed PCB
  zig-zag at the tip).
- A **micro-USB** socket at the other end.
- **Two push buttons** beside the USB socket, labelled **EN** (reset) and **BOOT**
  (bootloader select). Some clones label them RST/IO0 — same functions.
- Two rows of pin headers (30 or 38 pins total, both are fine).
- Between the USB socket and the module, a small square **USB-to-serial chip**. Read
  its marking with your phone's macro camera: **CP2102** (or CP2104) and **CH340**
  are the two common ones. Either works; which one you have only matters for the
  driver check in §4. **[I]** — DevKit V1 boards ship with either chip depending on
  the batch; the project docs don't pin one.

**If a board is something else entirely** (USB-C with a big "ESP32-S3" or "C3"
marking, a bare module with no USB at all, only one button): **stop, photograph it,
and report before flashing.** The firmware's pinned platform targets the original
ESP32; a different chip family will fail in confusing ways. Do not guess.

While you are looking: check for **bent header pins** and for solder blobs bridging
adjacent pins (hold the board so light rakes across the pin rows). Delivered boards
are usually fine; thirty seconds of looking is cheap.

## 3. First plug-in (nothing flashed yet)

1. Sit the board on its non-conductive surface, pins not touching anything.
2. Connect micro-USB → board, USB-A/C → Mac.
3. Expected: a small **red power LED** lights near the USB socket. Some boards also
   have a second (usually blue) LED on GPIO2 that may flicker or stay dim — anything
   it does right now is meaningless (the chip ships with a factory test program or
   nothing at all).
4. Nothing gets warm. A board that gets *hot* (uncomfortable to hold a finger on) in
   the first seconds: unplug immediately, mark it suspect, report.

## 4. Find the serial port

In a terminal:

```bash
ls /dev/tty.usb*
```

Expected: one new entry appeared that wasn't there before you plugged in —
typically `/dev/tty.usbserial-0001` (CH340/CP2102) or `/dev/tty.SLAB_USBtoUART`
(older CP2102 driver). Cross-check with PlatformIO's own scanner:

```bash
pio device list
```

which prints each port with its USB description (e.g. "CP2102 USB to UART Bridge
Controller").

**If no port appears:**

1. **Try a different cable first** (the charge-only trap from §1 — this is it).
2. Try the Mac's other USB socket.
3. Only then think drivers: recent macOS includes Apple-supplied drivers for both
   CP210x and CH340, so on this machine a missing driver is *unlikely* but possible
   **[I]** — macOS has bundled these since ~10.14/11; if genuinely absent, the
   vendor drivers are "Silicon Labs CP210x VCP driver" / "WCH CH34x driver". Ask in a
   session before installing anything — a driver install is a system change.

Note the port name down; you'll want it if more than one serial device is ever
plugged in at once (with a single board attached, PlatformIO auto-detects and you
never need to type it).

## 5. Build the firmware (board can stay plugged in; this step doesn't touch it)

```bash
cd /Users/vitaliykhomenko/Documents/projects/w17-control-fw
pio run -e esp32dev_tuning
```

What this builds: the **bench/tuning** variant — the normal firmware **plus** the
UART0 serial console and settings-mutation commands, enabled by the
`-DW17_TUNING_CONSOLE` build flag (**[C]** `platformio.ini` `[env:esp32dev_tuning]`).
Chapter 11 §3–4 explains the three variants; the one-line refresher:

| env | what | when |
|---|---|---|
| `esp32dev` | delivery build — console-free, silent | the gift car |
| `esp32dev_tuning` | + serial console, settings set/save | **the bench — today** |
| `esp32dev_sim` | + fake scripted CRSF feeder | Wokwi simulator only — never a real car |

First build on this machine downloads the ESP32 toolchain (a few minutes, one time).
Expected ending:

```
================== [SUCCESS] Took … seconds ==================
```

If it fails instead: nothing is wrong with your board (it wasn't involved) — copy the
error into a session and stop.

## 6. Flash it

```bash
pio run -e esp32dev_tuning -t upload
```

What you'll see, in order (**[I]** — standard esptool output for this platform;
exact percentages/addresses vary):

```
Looking for upload port...
Auto-detected: /dev/tty.usbserial-0001
Connecting....
Chip is ESP32-D0WD-V3 (revision …)
...
Writing at 0x00010000... (n %)
...
Hash of data verified.
Hard resetting via RTS pin...
```

- **"Connecting........_____...." repeating then "Failed to connect":** hold the
  **BOOT** button down, restart the upload command, keep holding until "Writing"
  appears, then release. (**[A]** in chapter 11 §3, standard DevKit behavior —
  today you get to confirm it; most boards auto-enter the bootloader and never
  need this.)
- A brand-new board may pause noticeably at "Connecting" once — normal.

"Hard resetting" at the end means the board rebooted straight into *your* firmware.
It is now running the W17 control code with no radio, no actuators, and nothing on
its pins — which the firmware treats exactly as designed: outputs parked safe,
failsafe engaged (link has never been up), waiting forever for a CRSF radio frame
that won't come. That is the correct, safe idle state.

## 7. Watch it boot — the serial monitor

```bash
pio device monitor
```

(115200 baud comes from `monitor_speed` in `platformio.ini` — you don't type it.
Exit the monitor later with **Ctrl+C**.)

You've likely missed the boot lines (the board booted when the flasher reset it), so
**press the EN button once** to reboot while the monitor is attached. Expected, from
the top:

1. A burst of ROM chatter — `rst:0x1 (POWERON_RESET)`, `configsip`, `clk_drv`,
   partition lines, maybe odd characters. This is the mask-ROM bootloader talking at
   a different baud; ignore everything before our first `[boot]` line.
2. **The reset-diagnostics line** (**[C]** `src/main.cpp` `formatBootLine()`):

   ```
   [boot] reset=POWERON boots=1 retained=no
   ```

   - `reset=POWERON` — the chip's own hardware register says this boot came from a
     power-cycle/EN reset, not a crash. The full label set (PANIC, TASK_WDT,
     BROWNOUT, SW…) is the R5-b diagnostics work from chapter 12.
   - `boots=…, retained=…` — the RTC-retained session counter. After a *power-on*
     the retained memory is untrusted, so expect a fresh session (`retained=no`).
     **[I]** whether an EN-button press also reads as POWERON with a fresh session
     (vs. retaining) is exactly the kind of real-hardware truth this session
     records — write down what you actually see.
3. **The settings-load line** (**[C]** `lib/console/src/ConsoleRunner.cpp`):

   ```
   [tune] using defaults (no valid saved settings)
   ```

   on a virgin board — its NVS flash has never held our settings blob, the guard
   chain (length → CRC → version → valid()) rejects whatever is there, and the
   firmware falls back to complete compiled defaults. This line is the guard chain
   from chapter 06 §2.8, seen working on real silicon for the first time.

Then… silence. No banner spam, no periodic prints — the console speaks only when
spoken to. The board is running its 50 Hz control loop, feeding the 2-second task
watchdog after every completed tick (chapter 12; `src/main.cpp` setup tail). If you
ever see the monitor spontaneously print a panic + reboot with
`reset=TASK_WDT` — that's a real finding: photograph/copy it and report. It should
**not** happen on a healthy bare board.

## 8. Talk to it — console exercise script

Type each command in the monitor and press Enter. Expected responses are exact
(**[C]** `lib/console/src/Console.cpp`):

**`help`**

```
commands: help | status | get <key> | set <key> <val> | save | load | reset
keys: steer.min steer.max steer.center steer.trim batt.ppt gear.<N>.max gear.<N>.expo
note: set/save/load/reset only while DISARMED; channels are read-only
```

**`status`**

```
armed=0
steer.center=1500 steer.trim=0 [1000..2000]
batt.ppt=1000
gears=6  g1.max=… g1.expo=… ...
channels(read-only): steer=0 thr=2 arm=4 drs=5
```

- `armed=0` — of course: no radio, the arm gate has never been satisfiable.
- The steering/battery/gear numbers are the compiled defaults (your values may
  differ from the illustration above except center=1500 — read them, don't force
  them).
- ⚠️ **The `channels(...)` line is a placeholder, not live data.** In the current
  code those four numbers are hard-coded constants in the formatter
  (**[C]** `Console.cpp`, the `status` handler passes literal `0u, 2u, 4u, 5u`) —
  chapter 11 §4's "live decoded channels" over-promised. Live channel display on
  real hardware arrives with the radio bench phase (D8 Phase 3), not today. Don't
  burn time wondering why the numbers don't change.

**`get steer.center`** → `1500` (compiled default; µs at servo-pulse center).

**The NVS persistence proof** — this sequence turns "224 tests pass" into "the
physical flash chip on this exact board stores and reloads settings," which
`CURRENT_STATUS.md` has carried as an open physical-validation item since CF-1:

```
set steer.trim 5        → ok (RAM only)
get steer.trim          → 5
save                    → saving to flash   +   saved
```

Now **press EN** (hard reset). After the boot chatter you should see:

```
[boot] reset=POWERON boots=… retained=…
[tune] loaded settings from flash          ← THE line — was "using defaults" before
```

then `get steer.trim` → `5`. The value crossed a full power cycle inside the NVS
flash partition, through the whole guard chain. **Record this** (§11).

**Optional, +10 minutes — settings survive a *reflash*:** flash the delivery build
(`pio run -e esp32dev -t upload`), open the monitor, press EN: **total silence** —
you have just confirmed with your own eyes that the gift firmware has no console
surface (the chapter-06 delivery invariant, on hardware). Then flash
`esp32dev_tuning` back and confirm the monitor again greets you with
`[tune] loaded settings from flash` and `get steer.trim` → `5`: the blob lives in
the NVS partition, which an application upload doesn't erase, so tuning survives
reflashing (**[I]** — expected from the partition layout; this test is the proof).

## 9. Leave the board clean

```
reset                   → reverted to defaults (RAM only; type 'save' to persist)
save                    → saving to flash  +  saved
```

`get steer.trim` → `0`. Ctrl+C out of the monitor, unplug the board, label it
(**§10**). The board now holds *defaults* in NVS (not virgin-empty — it will say
"loaded settings from flash" on future boots; that's fine and expected).

## 10. Repeat for boards 2 and 3

Run §3–§9 identically for each remaining board. Label the boards **1 / 2 / 3**
physically and record serial-port name + any oddity per board. All three get the
same test and the same tuning build — today is a *board health* test, **not** role
assignment (which board becomes control vs sound/light vs spare is decided at
harness-assembly time, and the sound/light one gets `w17-soundlight-fw` flashed
then).

## 11. Evidence template (fill one per board, keep with the bench notes)

```
Board #:            (1/2/3)          Date: 2026-07-…
Module marking:     ESP32-WROOM-32 ? (y/n)
USB-UART chip:      CP2102 / CH340 / other:
Serial port:        /dev/tty.…
Power LED on plug-in:        y/n     Anything hot? 
Flash esp32dev_tuning:       ok / needed BOOT held / failed:
[boot] line, 1st boot:       reset=…  boots=…  retained=…
[tune] line, 1st boot:       using defaults / loaded from flash
help + status as §8:         y/n (paste any deviation)
channels line = 0/2/4/5 placeholders confirmed:  y/n
set/save → EN → loaded-from-flash → value kept:  y/n
(optional) delivery build silent:                y/n/skipped
(optional) tuning reflash still has value:       y/n/skipped
Unexpected resets/panics during ~10 min powered: none / paste
Board returned to defaults + unplugged:          y/n
```

Bring the filled template back to a session: the results update
`CURRENT_STATUS.md` (the NVS physical-validation item, and a "boards smoke-tested"
note) and any deviation becomes a tracked finding.

## 12. Troubleshooting quick table

| Symptom | Most likely | Do |
|---|---|---|
| No `/dev/tty.usb*` appears | charge-only cable | different cable (§4) |
| `Failed to connect` on upload | auto-bootloader quirk | hold **BOOT** during "Connecting" (§6) |
| Monitor shows only endless garbage | wrong baud (monitor started with an override) | plain `pio device monitor` from the repo folder — it reads 115200 from `platformio.ini` |
| Boot chatter loops forever, `rst:` lines repeating | bad power (cable/hub) or a genuinely bad board | different cable/port first; if it still loops, mark board suspect, report |
| `reset=BROWNOUT` in the boot line | USB power dipped | different port, no hub; report if persistent |
| `reset=TASK_WDT` ever | control loop stalled — a real bug or a bad board | copy everything, report — this is exactly what the diagnostics exist for |
| Typing in monitor shows nothing | monitor echo off is normal — the console replies only after Enter | type the full command + Enter; if no *reply* at all, check you flashed `_tuning`, not plain `esp32dev` |

## 13. What this session did NOT do (still open, still gated)

- **No A2 items closed** — A2 is the assembled-harness multimeter checklist
  (`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`), untouched.
- **Phase B remains blocked** — CRSF radio bench (needs the ELRS **receiver**, still
  not on hand — the delivered item is the TX), scope checks of GPIO13/14 pulse
  widths, servo/ESC work: all later, per `docs/D8_BENCH_BRINGUP.md` Phases 2+.
- **Watchdog live-fire** — deliberately stalling the loop to watch the 2 s watchdog
  panic-reboot is the *Wokwi* validation task (the `W17_SIM_WDT_STALL` ad-hoc flag),
  not a bare-board exercise.
- **Battery ADC calibration** (`batt.ppt`) — needs the real divider + a multimeter:
  Phase B/C.

## Questions to check your understanding

1. Why is it safe to power this board over USB when the project forbids powering
   "the hardware" before A2? What exactly does A2 protect that a bare board lacks?
2. The first boot said `using defaults` but every later boot says
   `loaded settings from flash` — even after `reset` + `save`. Why is that not a bug?
3. Why does the `status` channels line show 0/2/4/5 no matter what?
4. The upload tool "hard resets" the board at the end, and you also pressed EN
   several times. Why did neither ever risk a servo twitch or ESC arm today — and
   what will be different the first time that statement needs real proof?
5. Why must the sound/light board *not* keep this `esp32dev_tuning` firmware when
   the car is assembled?
