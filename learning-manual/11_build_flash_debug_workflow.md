# 11 — Build, Flash, Debug Workflow

How to actually run everything: host tests, ESP32 builds, the Wokwi simulator, the
tuning console, the ground station, and CI. This is the hands-on chapter — do each
section once.

## 1. PlatformIO in five minutes

**PlatformIO** ("pio") is the build system both firmware repos use — think "npm for
embedded": `platformio.ini` declares *environments* (toolchain + board + flags), and
`pio run -e <env>` builds one. It downloads compilers/frameworks automatically on first
use. Install: VS Code extension, or `pipx install platformio` for the CLI.

The environments (**[C]** both `platformio.ini` files):

| Repo | Env | What it is |
|---|---|---|
| control | `esp32dev` | the real/gift firmware (default) |
| control | `esp32dev_sim` | + `-DW17_SIM_CRSF_FEEDER` (Wokwi scripted demo) |
| control | `esp32dev_tuning` | + `-DW17_TUNING_CONSOLE` (bench console + NVS) |
| control | `native` | host build for unit tests (HAL libs excluded via `lib_ignore`) |
| soundlight | `esp32dev` / `esp32dev_sim` / `native` | same pattern (`-DW17_SIM_LINK2_FEEDER` for the bench demo) |

A subtlety documented in the control `platformio.ini` itself: a child env's
`build_flags` **replaces** the parent's, so the sim/tuning envs re-interpolate
`${env:esp32dev.build_flags}` — keep that if you ever add flags.

## 2. Run the unit tests (no hardware — do this first)

```bash
cd w17-control-fw    && pio test -e native     # expect 147 tests, all pass
cd w17-soundlight-fw && pio test -e native     # expect 40 tests, all pass
```

Useful variations:

```bash
pio test -e native -f test_failsafe      # one suite only (-f = filter)
pio test -e native -v                    # print each test name as it runs
```

**Learning technique:** open a suite (say
`w17-control-fw/test/test_gearbox/test_main.cpp`), read the test names as a spec, then
temporarily change an *expected value* in one assertion and rerun to watch it fail — the
failure message shows you exactly what the module guarantees. Revert afterwards
(`git diff` should be clean; these repos must not be modified).

## 3. Build (and flash) the real firmware

```bash
pio run -e esp32dev                      # compile only — works with no hardware
pio run -e esp32dev -t upload            # compile + flash over USB
pio device monitor                       # serial monitor @ 115200 (monitor_speed)
```

Flashing notes for when hardware exists:

- The DevKit V1 enters bootloader automatically via USB; if a board is stubborn, hold
  BOOT while the upload starts. **[A]** standard DevKit behavior — untested here.
- Which build to flash when (**[C]** `docs/D8_BENCH_BRINGUP.md` preamble): bench =
  `esp32dev_tuning`; the delivered gift = plain `esp32dev` (no console surface). *C10
  caution: the NVS-saved tuning survives the reflash **in flash only** — the plain build
  has **no load path**, so the delivered firmware runs compiled-in defaults (open
  question #49; `code_explained/control_fw/10_main_integration.md` §8).*
- Board #2: `cd w17-soundlight-fw && pio run -e esp32dev -t upload`.

## 4. The tuning console (bench build only)

Flash `esp32dev_tuning`, open the monitor, and you get a serial console on USB
(UART0). **[C]** ROADMAP B2.6 + D8 phases 6/8:

```
status                       # live decoded channels, failsafe/arm state, sensors
get steer.center             # read a tunable
set steer.trim -12           # RAM-only change (gated: only while DISARMED,
                             #   re-validated by the module's valid() rules)
set gear.2.max 550           # gear feel table
set batt.ppt 1012            # battery calibration (parts-per-thousand trim)
save                         # ONLY this writes to NVS flash
load / reset                 # reload saved / return to compiled defaults
```

The guard chain worth knowing: settings load from flash only if length → CRC → version
→ `valid()` all pass; any failure means compiled defaults — a corrupt blob can never
brick the board (chapter 06 §2.8).

## 5. The Wokwi simulator — the whole car with zero hardware

**Wokwi** simulates an ESP32 well enough to run the real compiled firmware against a
virtual circuit (`diagram.json`: servos on GPIO13/14/18, a potentiometer on GPIO34 as
the "battery", a button on GPIO35 as the Hall sensor, and a UART2 loopback wire that
lets the firmware feed *itself* the scripted CRSF stream).

```bash
cd w17-control-fw
pio run -e esp32dev_sim
# then: VS Code Wokwi extension (free license) → "Wokwi: Start Simulator"
# or:   wokwi-cli .   (needs WOKWI_CLI_TOKEN)
```

Watch the serial monitor narrate the ~25 s loop (`docs/SIMULATION.md` has the phase
table): boot-safe silence → steering-while-disarmed → arm blocked at 60% throttle →
arm at neutral → driving with gear shifts + DRS + an ERS deploy → **three distinct
failsafe demonstrations** (never-received, pure timeout, and the LQ=0-while-frames-flow
hold-position case) → fresh-neutral recovery. Interactive: turn the pot below ~57% and
hold 3 s → low-battery latch; click the button rhythmically → wheel rpm (and ERS
harvest eligibility).

Soundlight equivalent: `pio run -e esp32dev_sim` there builds the 14 s scripted
sound/light demo — but it needs a real board + speaker/LEDs to be interesting
(`w17-soundlight-fw/docs/SIMULATION.md`).

## 6. The ground station

```bash
cd w17-ground-station
npm install
npm run setup        # repairs Electron if postinstall was blocked; fetches mediamtx v1.9.3
npm test             # 20 vitest specs
npm run demo         # the app with replay telemetry — no car, no camera
npm start            # the real thing (needs the camera pipeline configured)
npm run build        # package the Windows .exe
```

Gotchas (**[C]** README Troubleshooting): don't run `electron .` from VS Code's
integrated terminal (it leaks `ELECTRON_RUN_AS_NODE=1`; the npm scripts strip it);
telemetry needs `W17_TELEMETRY_SOURCE=crsf-serial W17_TELEMETRY_PORT=<port>` and
`npx electron-rebuild` for the native `serialport` module — without it the app still
runs, just simulated.

Offline video rehearsal without the camera (**[C]** SETUP.md §5):

```bash
./mediamtx/mediamtx mediamtx/mediamtx.yml
ffmpeg -re -stream_loop -1 -i demo.mp4 -c:v libx264 -tune zerolatency -f rtsp rtsp://127.0.0.1:8554/cam
npm run demo
```

## 7. CI — the safety net

Both firmware repos carry `.github/workflows/ci.yml`: native tests + both ESP32 builds
on every push (**[C]** ROADMAP B2.1; the control repo's workflow is explained
line-by-line in C10 §9 — note it builds `esp32dev` + `esp32dev_sim` but **not**
`esp32dev_tuning`; **S5 diffed soundlight's workflow: byte-identical to control's**, so
C10 §9 covers both — each repo's PlatformIO cache is keyed on its own `platformio.ini`
hash; open question #46 closed. One soundlight-specific build fact worth knowing from S5:
its `platformio.ini` pins `platform = espressif32 @ ~7.0.1` **deliberately** — that is
the last platform line shipping Arduino core 2.0.17 / IDF 4.4, whose legacy `driver/i2s.h`
the audio HAL depends on; an unpinned platform bump would delete that API).
The ground station's cross-platform claim is likewise "proven by CI + the pure-core
tests" (README). Practical meaning for you: if `pio test -e native` and `pio run -e
esp32dev` pass locally, you've reproduced CI.

## 8. Debugging techniques this project is built for

1. **Test-first reproduction** — the pure-logic design means most "why does it do X?"
   questions can be answered by writing (or reading) a native test with fabricated time
   — no hardware, no reflashing. This is *the* intended workflow (`CLAUDE.md` §4
   Stage 1).
2. **Wokwi before bench** — Stage 2: end-to-end behavior, virtual scope on PWM pins.
3. **Serial narration** — the sim builds print `[sim] phase:` + 2 Hz `[state]` lines;
   the tuning console's `status` is the bench equivalent.
4. **Bench last, gated** — Stage 3 = `docs/D8_BENCH_BRINGUP.md`, in phase order, with
   the golden rule: wheels off the ground and no ESC power until failsafe + arm gate
   are proven live (Phase 5).

## Confirmed vs inferred

**Confirmed [C]:** all commands/envs/flags from the two `platformio.ini` files,
`package.json` scripts, and the cited docs; test counts from ROADMAP/READMEs; console
grammar from ROADMAP B2.6.

**Inferred [I]:** `pio test` filter/verbosity flags and monitor invocation are standard
PlatformIO usage (not project-documented); expected first-run downloads.

**Assumed [A]:** flashing behavior of the physical DevKit V1 boards (§3 note) — nothing
has been flashed to real hardware yet in this project's history.

## Questions to check your understanding

1. Why does `[env:native]` exist at all, and why does it `lib_ignore` the five
   `*_hal_esp32` libraries instead of just not referencing them?
2. What is the difference between `set gear.1.max 500` and editing the default in
   `Gearbox.hpp`, in terms of (a) persistence, (b) validation, (c) what the gift
   firmware contains?
3. You suspect the failsafe re-arm window is too short. Which of the four workflow
   stages (native test / Wokwi / tuning bench / car) lets you verify a change fastest,
   and what would you write?
4. Why is the delivered gift firmware built *without* the tuning console — and what does
   the C10 finding (open question #49) say about whether the tuned values actually
   *reach* the delivered car?
5. In the Wokwi demo, why does the ERS store only recharge while you click the Hall
   button? Which two modules' rules combine to cause that?
6. `npm run demo` shows a working HUD with plausible speed. Name every real component
   that this proves nothing about (list at least four).
