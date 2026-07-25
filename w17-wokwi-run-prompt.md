# Session prompt — 4b. Run the Wokwi sim (upload APPROVED; no physical hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-control-fw`.

**Upload is approved** (owner, 2026-07-25): every Wokwi route uploads the firmware image to Wokwi's servers,
and that is fine for this firmware. Recorded as a knowing decision, not an assumption.

Setup, before the session can do anything:

```
npm i -g wokwi-cli
export WOKWI_CLI_TOKEN=…        # from your Wokwi dashboard / CI token page
```

**If the CLI token isn't available on the current plan**, don't fight it — the VS Code extension is already
installed and licensed (3.6.0). Drive `Wokwi: Start Simulator` yourself (an agent cannot start it) and paste
the serial log in; this prompt then becomes "classify the log I paste," and every item below still applies to
that log. Prefer the CLI where possible: it's repeatable and can go into CI later, which the extension can't.

---

The 2026-07-25 batch established that `esp32dev_sim` **builds clean but has never been loaded**. The open
question was retagged `[HW]` → `[OWNER/tooling]`: the blocker is a credential, not the bench.
`SIMULATION.md` now leads with a run-status table with **every box unchecked** — this session earns the
ticks or reports honestly why it can't.

**No physical hardware.** A virtual ESP32 needs no gate: A2 stays NOT-EXECUTED, Phase B stays BLOCKED,
nothing is flashed, powered, or connected.

## 1. Answer the question that has never been answered

Does the sim reach a **live link — `failsafe=0`** over the 420000-baud CRSF loopback? `open_questions.md`
(→ R16) has carried this open since the audit. Run it and say plainly whether it does. If the harness can't
feed valid CRSF frames, that's the finding — report it rather than working around it silently.

## 2. Capture the watchdog cycle

The stall injector **already exists** — `W17_SIM_WDT_STALL` in `src/main.cpp` busy-spins past the single
`esp_task_wdt_reset()` feed. It compiles, and its marker string appears once in the stall ELF and **zero**
times in `esp32dev`, `esp32dev_tuning` and `esp32dev_sim`. No code is needed; just build and run it.

Capture: stall → **2 s TWDT fires** → panic → reboot → `reset=TASK_WDT`. Report the raw serial output, and
what the RTC-retained diagnostics say — the retained-session counter increment has never been exercised,
because real hardware has only ever shown `POWER_ON` / `retained=no` (3 boards, 2026-07-22). A crash-class
reset actually incrementing that counter would be the first evidence for it.

## 3. Tick only what you earned, and respect the limits section

`SIMULATION.md` already names what a green sim **cannot** settle: reboot-to-safe-output timing,
GPIO13/GPIO14 state across the `reset → ledcAttachPin` window, and real ESC signal-loss behaviour. Those
stay **Phase-B evidence**. Do not promote any of them, and do not upgrade the **2 s TWDT timeout from
provisional** — a sim confirming the mechanism fires says nothing about whether 2 s is the right number
under real load.

Tick a box only for what the run actually demonstrated. A partially-green sim honestly reported is worth
more than a fully-ticked one that overstates; this workspace's recurring failure mode is evidence
overstatement, so the bar is: every tick traceable to output you pasted.

## Finish

`pio test -e native` (**expect 225/225**) still green; all three ESP32 envs still build. Update
`SIMULATION.md`'s run-status table and the R16 entry in `open_questions.md` with what the run settled. Show
diffs; docs-only commits unless the run exposes a real firmware defect — in which case stop and tell me
before fixing. **Do not touch `CURRENT_STATUS.md`** (prompt 2 is the single writer) or any sibling repo.
