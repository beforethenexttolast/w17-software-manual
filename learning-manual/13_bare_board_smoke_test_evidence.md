# 13 — Bare-Board Smoke Test: Evidence Sheets

Filled §11 evidence templates from the bare-board USB smoke test. Companion to
`13_bare_board_smoke_test.md`. Session: **2026-07-22**, attended (owner present for every
plug/unplug), USB from the Mac only, nothing connected to any pin. A2 + Phase B untouched.

**Result: 3 / 3 boards PASS.** Summary recorded in `../CURRENT_STATUS.md` (2026-07-22 "later"
entry + CF-1 NVS bullet). All boards flashed `esp32dev_tuning`, physical NVS persistence proven
with a fresh distinct write surviving a power cycle, then returned to compiled defaults.

## Cross-board facts

- **Board type:** USB-C DevKit V1 clones (chapter 13 §2 assumed micro-USB — cosmetic deviation).
  Silkscreen "ESP-32D"; flasher-confirmed **ESP32-D0WD-V3 rev v3.1** (classic ESP32, `ets Jul 29
  2019` ROM banner). **CH340C** USB-UART (VID:PID `1A86:7523`), 30-pin.
- **Serial port:** all three enumerated as `/dev/cu.usbserial-1120` (same physical USB location,
  so macOS reused the name — one board attached at a time).
- **First cable was charge-only** (LED on, no serial port) — swapped to a data cable per §4.
- All boards were **non-virgin** (owner flashed them days earlier), so each booted
  `[tune] loaded settings from flash` (not `using defaults`) with no `NOT_FOUND` line — expected.
- `status` on every board: `armed=0`, `steer.center=1500`, `steer.trim=5` (pre-existing saved),
  `batt.ppt=1000`, `gears=4  g1.max=400 g1.expo=50`, `channels 0/2/4/5` (placeholder confirmed).
  Numbers differ from the manual's *illustration* as §8 permits; `center=1500` is the anchor ✓.

---

## Board 1

```
Board #:            1                              Date: 2026-07-22
Module marking:     ESP-32D  → ESP32-WROOM-32 / D0WD (y) *
USB-UART chip:      CH340C   (USB VID:PID 1A86:7523)
Serial port:        /dev/cu.usbserial-1120
Power LED on plug-in:        y      Anything hot?  mildly warm (no explicit finger-check returned)
Flash esp32dev_tuning:       ok (no BOOT hold needed)
[boot] line, 1st boot:       reset=POWER_ON boots=1 retained=no
[tune] line, 1st boot:       loaded from flash  (non-virgin — expected)
help + status as §8:         y  (values differ from illustration as allowed; center=1500 ✓)
channels line = 0/2/4/5:     y (placeholder confirmed)
set/save → EN → kept:        y  — clean delta 5→12 survived power cycle; then reset→0 survived
(optional) delivery silent:  skipped
(optional) reflash keeps val: skipped
Unexpected resets/panics:    none
Returned to defaults+unplug: y
* connector is USB-C, not micro-USB (§2 assumed micro-USB) — cosmetic; chip family confirmed
  classic ESP32 by the `ets Jul 29 2019` ROM banner. MAC not captured (flash log truncated).
```

## Board 2

```
Board #:            2                              Date: 2026-07-22
Module marking:     ESP32-D0WD-V3 (rev v3.1) — flasher-confirmed;  MAC b4:bf:e9:05:61:4c
USB-UART chip:      CH340C   (USB VID:PID 1A86:7523)
Serial port:        /dev/cu.usbserial-1120
Power LED on plug-in:        y      Anything hot?  not flagged
Flash esp32dev_tuning:       ok (no BOOT hold)
[boot] line, 1st boot:       reset=POWER_ON boots=1 retained=no
[tune] line, 1st boot:       loaded from flash (non-virgin — expected)
help + status as §8:         y  (trim was 5 saved; center=1500 ✓; gears=4)
channels line = 0/2/4/5:     y
set/save → EN → kept:        y  — 5→12 survived power cycle; reset→0 survived
(optional) delivery silent:  skipped
(optional) reflash keeps val: skipped
Unexpected resets/panics:    none (one benign 'unknown key' = mistyped input, handled correctly)
Returned to defaults+unplug: y
```

## Board 3

```
Board #:            3                              Date: 2026-07-22
Module marking:     ESP32-D0WD-V3 (rev v3.1) — flasher-confirmed;  MAC b4:bf:e9:06:9f:d4
USB-UART chip:      CH340C   (USB VID:PID 1A86:7523)
Serial port:        /dev/cu.usbserial-1120
Power LED on plug-in:        y      Anything hot?  not flagged
Flash esp32dev_tuning:       ok (no BOOT hold; 1 retry — §12.1 port lock from a stray monitor, cleared)
[boot] line:                 reset=POWER_ON boots=1 retained=no
[tune] line:                 loaded from flash (non-virgin — expected)
help + status as §8:         y (trim was 5 saved; center=1500 ✓; gears=4)
channels line = 0/2/4/5:     y
set/save → EN → kept:        y — 5→12 survived power cycle; reset→0 survived
(optional) delivery silent:  skipped
(optional) reflash keeps val: skipped
Unexpected resets/panics:    none (benign 'unknown command'/'usage'/'unknown key' = typos, handled)
Returned to defaults+unplug: y
```

---

## Notable in-session events

- **§4 charge-only cable trap:** board 1 lit its LED but no serial port appeared until the USB-C
  cable was swapped for a data-capable one. First thing to suspect on "no port," USB-C included.
- **§12.1 serial-port lock (3rd recorded occurrence):** board-3 flash failed with `port is busy`;
  `lsof /dev/cu.usbserial-1120` showed a leftover `pio device monitor` (Python) holding it. The
  process exited on its own before a kill was needed; reflash succeeded. Habit reinforced: one
  monitor window per session, Ctrl+C it before flashing.
- **Console robustness:** several mistyped inputs across boards 2/3 produced `unknown command` /
  `usage: set <key> <integer>` / `unknown key (try 'help')` — the parser rejecting bad input
  gracefully, with the correct following command always succeeding. Not faults.

## Still open after this session

- Optional **reflash-survival** and **delivery-build-silent** legs (§8 optional): skipped.
- **Crash-class reset classification** (PANIC / TASK_WDT / BROWNOUT) and **RTC retained-counter
  increment**: never triggered — only `POWER_ON` seen, which is correct for healthy boards.
- **Board role assignment** (control vs sound/light vs spare): deferred to harness assembly (§10).
- **A2 no-power checklist** and **Phase B**: untouched, still in force for the car harness.
