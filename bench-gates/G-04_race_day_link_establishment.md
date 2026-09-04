# G-04 — RACE DAY link establishment and timing (the 5 s window)

> One press has to bring the whole laptop side up, and the DRIVE PROGRAM line has to tell
> the truth about the **radio**, not just about a process
> (`w17-ground-station/README.md:247-258`). The wait before that decision,
> `LINK_UP_WAIT_MS = 5000`, is **not validated** — *"nothing in this chain has run on any
> machine"* (`main/raceDayOrchestrator.js:89-96`, `README.md:260-264`,
> `docs/GIFTEE_FIRST_LAUNCH.md:134-143`).
>
> **The purpose of this gate is to SETTLE that constant.** A FAIL here is a datum about
> the number as much as a verdict about the rig.
>
> **Evidence label: NOT-EXECUTED.**

---

## Prerequisites

- **Un-gated by A2/Phase B, but a live-TX bench procedure under
  `w17-windows-vm-validation-runbook.md`:370-397: car UNPOWERED or RP1 UNBOUND, no bound RX
  powered in range, attended, discharges nothing (RESIDUAL A); requires explicit owner
  authorization like every other gate.** Success on this card means the COM port opens and
  CRSF starts going out over the ELRS TX. That is a live transmitter, and on gamepad loss
  it *"still transmits at full rate … fail-to-neutral, not fail-silent"* (RESIDUAL A,
  `w17-windows-vm-validation-runbook.md`:393-397).
- Real Windows. The whole chain is Windows behaviour and is unproven until the WS3
  session (`W17_CURRENT_STATE.md:61`).
- Prior WS3 steps staged: `10-install-gs.ps1` (GS installed) and `20-mapper-stage.ps1`
  (racePrep written into `settings.json`) against the **same** `-UserDataDir`
  (`w17-windows-vm-validation-runbook.md:355-362`).
- A **filled, W17-marked** profile. The headless bring-up refuses a profile with
  `REPLACE-WITH-` placeholders and refuses one that does not declare `"w17_profile": true`
  — both **before** the RPC and before `StartLink`
  (`w17-mapper/pkg/client/grpc_client.go:128-156`, `:101-115`).
- Read G-03 first if the pad has never been enumerated on this machine: the profile's
  `gamepad.id` must match the transport in use.
- **This gate is not R15 and moves no FIRST_ACTIVE row** (`CURRENT_STATUS.md:1384-1385`).

## Required equipment

| Item | Why |
|---|---|
| Real Windows PC + `pwsh` 7 | `w17-windows-vm-validation-runbook.md:170` |
| GS installed build + mapper binary + filled profile | the real artefacts, not a dev tree |
| The GCS box (FT232 / ELRS TX) on a COM port the profile names | the port that must open |
| **The car unpowered, or the RP1 unbound** (`w17-windows-vm-validation-runbook.md`:384 — not optional) | so an open port and live CRSF reach nothing. **Leave the TX module's antenna attached**; an antenna detach is not the sourced mitigation and drives the module's PA into an open port |
| DualShock 4 | the mapper enumerates SDL at boot |
| `bench-gates/tools/raceday_timing.py` | the parser; python3, stdlib only |

## Topology

```
  [ giftee presses RACE DAY ]                                              ── t0 (marker)
        │  IPC 'raceday:start'   (appWiring.js:338 -> raceDay.start())
        ▼
  RaceDayOrchestrator  STEP_ORDER = hotspot -> mapper -> telemetry -> bridge
        │                                     (raceDayOrchestrator.js:76)
        ├─ (a) hotspot        via the existing hotspot lifecycle
        │
        ├─ (b) mapper: MapperRunner.start()  spawn <exe> -config-file-path <profile>
        │        │        argv whitelist is EXACTLY that one flag (js:44)
        │        │        stdin 'ignore'; stdout/stderr -> a 200-line RING only
        │        │        (mapperRunner.js:39-40,167)
        │        │                                                        ── t_spawn
        │        ▼
        │   mapper boots: SDL enumerate -> gRPC :10000 (loopback default) -> web UI
        │        └─ client.Init() headless bring-up (grpc_client.go:76)
        │              read+refuse profile -> SetConfig -> selfStartLink   ── t_bringup
        │                    └─ StartLink -> PortLoop: open COM<n>          ── t_open_try
        │                          └─ "(port-loop)(initial) port COMn opened"── t_open_ok
        │                                └─ send loop: CRSF frames out      ── t_send
        │
        │   ◄── MapperLinkStateClient subscribes the READ-ONLY link-state stream
        │        _awaitLink(5000 ms, poll 100 ms)  (raceDayOrchestrator.js:492)
        │        up == (supervisor_state == SupervisorActive AND
        │               port_state == PortConnected)   (shared/mapperTelemetry.js:111-115)
        │
        ├─ (c) telemetry      OD-4: after the drive program, reads its read-only stream
        └─ (d) bridge         W2 phone telemetry per settings
```

## Exact procedure

> ### The instrumentation gap this procedure works around
> No artefact the shipped software produces carries the instants this gate needs:
> * the GS main-process log is bare `console.log(m)` — **no timestamp**
>   (`w17-ground-station/main/main.js:62`);
> * the mapper prints with bare `fmt.Printf` — **no timestamp**
>   (`w17-mapper/pkg/link/port.go:47-49`, `pkg/client/grpc_client.go:298`);
> * under RACE DAY the mapper's stdout is piped **only** into a bounded 200-line ×
>   400-char in-memory ring, never echoed and never written to a file
>   (`main/mapperRunner.js:39-40,144-151,167`);
> * **nothing logs the button press at all** — `appWiring.js:338` calls `raceDay.start()`
>   and `start()` (`raceDayOrchestrator.js:273-301`) logs nothing on entry.
>
> So the run is split in two, and both halves are stamped by the capture wrapper.
> **Part A** measures the number (mapper launched with race day's exact argv, its own
> stdout captured); **Part B** presses the real button and records which of the four
> outcome kinds the giftee is shown. Part A is where the constant is settled; Part B is
> where the wording is checked.

**Part A — cold-start link latency, five runs.**

1. Reboot Windows. This is a *cold* measurement: the question is how long a cold Go
   binary takes to enumerate SDL and open the FTDI port **behind an AV scan**
   (`raceDayOrchestrator.js:89-92`). A second run on a warm machine is a different number
   and must be labelled as one.
2. Confirm the exact argv race day would use, from race day's own pure builder — never
   re-derived by hand. `mapperArgv()` emits `-config-file-path <trimmed absolute path>`
   and has no branch that appends anything else (`raceDayOrchestrator.js:44-71`).
3. Emit the `W17-RACEDAY-T0` marker and launch the mapper with that argv, through the
   timestamping pipe (Exact commands). The marker and the launch are one command, so the
   press-to-spawn leg is machine-measured, not hand-timed.
4. Let it run until the send loop is up, or 30 s, whichever is first. Ctrl-C.
5. Run `raceday_timing.py` over the capture. Record `spawn -> port OPEN`.
6. Repeat **five times**, rebooting between runs. Then run it **once more warm** (no
   reboot) and label that run separately.
7. Repeat once with the **GCS box unplugged**, to see the failure shape: expect
   `(port-loop)(initial) error opening port` and backoff, and no `opened` line.

**Part B — the real press, and what the giftee is shown.**

8. Start the GS from a timestamping capture too (Exact commands), so the `[mapper]
   started managed (pid …)` line is stamped and the two halves can be laid side by side.
9. Press **RACE DAY ▸ BRING EVERYTHING UP**. Record, in order: CAR WI-FI, DRIVE PROGRAM,
   PHONE LINK — the checklist at `docs/setup_flow_bench_checklist.md:210-233`.
10. Record which DRIVE PROGRAM kind appeared, verbatim, and whether the sequence
    continued or halted:

    | kind | operator wording | citation | halts? |
    |---|---|---|---|
    | `running` | `running` | `shared/raceDayView.mjs:71` | no |
    | `already-running` | `already running` | `:72` | no |
    | `external` | `already running (started outside RACE DAY)` | `:75` | no |
    | `link-unknown` | `started (could not double-check the radio on this computer)` | `:79` | no |
    | `link-not-yet` | `running — the radio is not on yet, give it a moment` | `:86` | **no** (OD-5: a first bring-up never accuses a cable) |
    | `link-down` | `started, but the radio is not transmitting — check the cable to the little radio box, then press RACE DAY again` | `:100` | **yes** |

11. **The unplugged-serial variant** (`setup_flow_bench_checklist.md:220-230`): with the
    GCS box's serial link deliberately unplugged, confirm the line is **not** plain
    `running`. On a **first** bring-up expect `link-not-yet` (green, sequence carries on);
    after a run in which the radio HAS come up this session, expect `link-down` and the
    sequence halting.
12. Confirm the `link-not-yet` line **upgrades itself** to `running` the moment the radio
    answers, without a second press (`raceDayOrchestrator.js:451-453`).
13. Press RACE DAY again while everything is up: idempotent re-run, nothing restarted
    (`setup_flow_bench_checklist.md:231-233`).
14. Press **STOP RACE DAY**: the button must disappear **on the press**, not on the
    child's exit, and the process must actually go (`README.md:209-218`).
15. Kill the managed process externally (Task Manager). The card must mirror the death
    honestly — *"stopped on its own — press RACE DAY to bring it back"* — with no press
    (`setup_flow_bench_checklist.md:248-250`).

## Exact commands

Part A — cold-start measurement. One command emits the marker and launches, so the
press→spawn leg is real:

```powershell
$prof = 'C:\W17\w17-ds4.json'
$log  = ".\G-04_partA_cold_$(Get-Date -Format yyyyMMdd-HHmmss).txt"
$stamp = { process { '{0} {1}' -f (Get-Date).ToUniversalTime().ToString('o'), $_ } }

& {
  'W17-RACEDAY-T0 part A cold run, argv = -config-file-path ' + $prof
  & .\elrs-joystick-control.exe -config-file-path $prof 2>&1
} | ForEach-Object -Process $stamp | Tee-Object -FilePath $log
```

Confirm the argv against race day's **own** builder rather than trusting the line above.
Do not re-derive it by hand and do not read it out of this card: run the existing WS3
step, which captures `mapperArgv()` / `MAPPER_ARG_WHITELIST` directly from the function
under test (`lib/race-day-probe.js:182-187`, result fields `mapperArgWhitelist` and
`argvCheck` at `:239-240`):

```powershell
pwsh -File .\scripts\windows-validation\50-race-day.ps1 `
     -InstallDir $InstallDir -UserDataDir $UserDataDir -ResultsDir .\G-04-results
# then read data.* / the RACEDAY_PROBE_RESULT line in the saved result JSON.
```

That step also drives `raceDay.start()` for real under `ELECTRON_RUN_AS_NODE=1`, so it
answers the *outcome* question; it carries **no timing fields** (`:232-251`), which is
why Part A above exists.

Part B — the GS under a timestamping capture, so its `[mapper] started managed` line is
stamped:

```powershell
$gslog = ".\G-04_partB_gs_$(Get-Date -Format yyyyMMdd-HHmmss).txt"
$env:ELECTRON_ENABLE_LOGGING = '1'
& "$InstallDir\W17 Ground Station.exe" 2>&1 |
  ForEach-Object { '{0} {1}' -f (Get-Date).ToUniversalTime().ToString('o'), $_ } |
  Tee-Object -FilePath $gslog
```

> If the packaged GUI build writes nothing to the parent console on this Windows build,
> **that is itself the finding** — record it, and fall back to the WS3 probe path
> (`50-race-day.ps1`, which drives the real orchestrator under `ELECTRON_RUN_AS_NODE=1`
> and prints `RACEDAY_PROBE_RESULT: {...}` — `lib/race-day-probe.js:252`). Note that the
> probe's result object carries **no timing fields at all** (`:232-251`), so it answers
> the *outcome* question and not the *timing* one. Part A remains the measurement.

Reduce:

```sh
cd /Users/vitaliykhomenko/Documents/projects

python3 bench-gates/tools/raceday_timing.py \
  bench-gates/evidence/G-04/partA_cold_run1.txt \
  --json bench-gates/evidence/G-04/partA_cold_run1.json
echo "exit=$?"      # 0 = inside the window, 1 = outside / never claimed, 2 = unusable capture

# merged view: GS spawn line + the mapper's own lines, sorted by their stamps
sort -m bench-gates/evidence/G-04/partB_gs.txt \
        bench-gates/evidence/G-04/partB_mapper.txt \
  | python3 bench-gates/tools/raceday_timing.py - \
      --json bench-gates/evidence/G-04/partB_merged.json
echo "exit=$?"

# to test a candidate replacement for the constant without editing any code:
python3 bench-gates/tools/raceday_timing.py \
  bench-gates/evidence/G-04/partA_cold_run1.txt --window-ms 12000
```

## Expected evidence

Markers the parser keys on, each with the line that prints it:

| Marker | Printed by |
|---|---|
| `W17-RACEDAY-T0` | the capture wrapper above (nothing in the app logs the press) |
| `[mapper] started managed (pid N): <exe> <argv>` | `w17-ground-station/main/mapperRunner.js:225` |
| `(bring-up) starting the radio link on COMn at 921600 baud, from the saved profile` | `w17-mapper/pkg/client/grpc_client.go:298` |
| `(port-loop)(initial) opening port COMn` | `w17-mapper/pkg/link/port.go:47` |
| `(port-loop)(initial) port COMn opened` | `port.go:49` — **the radio claim** |
| `(port-loop)(initial) error opening port COMn` | `port.go:54` |
| `(port-loop)(backoff) port COMn re-opened` | `port.go:91` |
| `(send-loop) starting, refresh rate …` | `w17-mapper/pkg/link/send.go:218` |
| `[raceday] the drive program has not raised the radio yet — reporting "not yet", not a fault` | `main/raceDayOrchestrator.js:481` |
| `[mapper] exited (N)` | `main/mapperRunner.js:222` |
| `(bring-up) the saved profile declares no transmitter …` / `… tx.port … is empty …` | `grpc_client.go:279-290` |

Plus: five cold `spawn -> port OPEN` figures, one warm figure, the unplugged-serial
failure shape, screenshots of each DRIVE PROGRAM wording, and whether each sequence
halted.

## PASS / FAIL criteria

**The gate measurement is `t(port OPEN) − t(mapper spawn)`, against
`LINK_UP_WAIT_MS = 5000` (`main/raceDayOrchestrator.js:97`).**

| # | Criterion | PASS | FAIL |
|---|---|---|---|
| 1 | Cold link latency | **all five** cold runs `≤ 5000 ms` | any cold run `> 5000 ms` — the constant is too small for this machine; report the max and the spread |
| 2 | Margin | worst cold run leaves **≥ 1000 ms** headroom (i.e. `≤ 4000 ms`) | headroom under 1000 ms ⇒ the constant is technically met but marginal; recommend a value, do not choose one |
| 3 | Spread | max − min across the five cold runs `≤ 2000 ms` | a wider spread means one number cannot characterise this machine; report the distribution |
| 4 | Warm run | recorded and labelled separately | quoted as if it were the cold number |
| 5 | Truthful wording, radio up | DRIVE PROGRAM reads plain `running` (`raceDayView.mjs:71`) only when `up == true` | plain `running` while the port is shut |
| 6 | Truthful wording, first bring-up with the serial unplugged | `link-not-yet` — *"running — the radio is not on yet, give it a moment"*, green, **sequence carries on** | `link-down` on a first bring-up (accuses a cable that is fine), or plain `running` |
| 7 | Truthful wording, after the radio has been up this session | `link-down` — *"started, but the radio is not transmitting — check the cable …"*, and the **sequence halts** (OD-5) | anything softer |
| 8 | Self-upgrade | a `link-not-yet` line becomes `running` when the radio answers, with **no second press** | it stays `link-not-yet` |
| 9 | Idempotent re-press | each step re-verifies / no-ops; nothing is restarted | anything restarts |
| 10 | STOP | button disappears **on the press**; the process is gone (Task Manager) | the button lags the child's exit, or an idle-looking card sits over a live process |
| 11 | External kill | the card mirrors the death with no press | it keeps claiming the drive program is up |
| 12 | Argv | exactly `-config-file-path <profile>`, from race day's own builder | any additional flag, ever |

> **The verdict this gate hands the owner is a number, not only a colour.** Whether
> `LINK_UP_WAIT_MS` stays 5000, grows, or the first-bring-up asymmetry is kept as the
> permanent design, is the owner's call on this data. `50-race-day.ps1` is named as the
> place the real port-open latency gets recorded
> (`raceDayOrchestrator.js:94-96`, `README.md:263-264`), and this card is how a human
> reads the same latency in a form that can be argued about.

## Stop conditions

Stop immediately if:

- the car is powered, or the RX is bound, at any point;
- the DRIVE PROGRAM line reads plain `running` while the serial link is unplugged — that
  is the one claim the giftee acts on, and a false one is a stop-the-line finding, not a
  note;
- STOP RACE DAY leaves a live process behind an idle-looking card
  (`README.md:216-218`: *"A stopped-looking card over a live process is the one thing
  race day must never draw"*);
- the mapper panics or exits on its own during bring-up — capture the stdout tail and
  stop; that is MAP-1-shaped and belongs in a report, not in a retry loop;
- the parser exits **2** ("no line carries a timestamp"): fix the capture before
  collecting more runs, or the whole session produces nothing measurable.

## Rollback

- Ctrl-C the Part-A mapper; confirm no `elrs-joystick-control` process survives and no
  COM port is held.
- STOP RACE DAY, then quit the GS (teardown disposes the managed child —
  `main/main.js:421`).
- The hotspot is **not** race day's to wind back: it stays with PIT WALL / the quit
  policy (`README.md:205-207`). Leave it as the owner had it.
- Race day may have written **one** settings key, `telemetry.source`, once per app
  session, through the narrow `patchTelemetrySource()` — never any other key and never
  the encrypted Wi-Fi credential (`README.md:233-238`, OD-19). If the pre-existing value
  matters, record it before the run and restore it after.
- On the WS3 VM, `vmrun revertToSnapshot clean-giftee-pc` returns everything.

## Outputs to save

```
bench-gates/evidence/G-04/
  rig_record.md                 # machine, AV product, GS build, mapper build, profile hash
  argv_check.json               # mapperArgv() output, from race day's own builder
  partA_cold_run1..5.txt        # timestamped captures
  partA_cold_run1..5.json       # raceday_timing.py --json
  partA_warm.txt / .json
  partA_serial_unplugged.txt    # the failure shape
  latency_summary.md            # five cold figures, min/median/max, spread, recommendation
  partB_gs.txt / partB_mapper.txt / partB_merged.json
  partB_wordings.md             # each DRIVE PROGRAM kind seen, verbatim, + halt or not
  partB_screenshots/            # GARAGE card in each state
  stop_and_kill.md              # criteria 10 and 11
```

## Downstream unlocked by PASS

- **Settles `LINK_UP_WAIT_MS`** — the `[bench-TBD]` at `raceDayOrchestrator.js:89-96`,
  `README.md:260-264` and `docs/GIFTEE_FIRST_LAUNCH.md:134-143` can be replaced by a
  measured number, and the first-bring-up asymmetry can be kept on purpose rather than
  as insurance against an unknown.
- Discharges the RACE DAY block of `docs/setup_flow_bench_checklist.md:204-250`, and the
  bring-up half of WS3 (`w17-windows-vm-validation-runbook.md:459-464`).
- Confirms on real Windows that MAP-1 and MAP-2/SYN-2 are actually closed at the shipped
  artefacts (they are recorded as LANDED at mapper `6e99d51`,
  `W17_CURRENT_STATE.md:61`, but *"Windows behaviour is unproven until the WS3 VM
  session"*).
- Makes the booklet's *"press the one big RACE DAY button"*
  (`learning-manual/14_glovebox_owners_booklet.md:122`) and its recovery cue at `:220`
  and `:251` verified rather than intended.

**It does not unlock:** A2, Phase B, R15, or any FIRST_ACTIVE row — all unchanged
(`W17_CURRENT_STATE.md:61`, `w17-windows-vm-validation-runbook.md:465-468`).

## BENCH-TBD residue

- **CRSF frames actually reaching the receiver over RF.** An open COM port is not a bound
  link. No script in the WS3 suite opens a serial port by design
  (`w17-windows-vm-validation-runbook.md:437-438`); this card opens one via the mapper's
  own bring-up and still proves only that the port opened and the send loop started.
  On-the-wire proof stays bench (`W17_CURRENT_STATE.md:61`) and is C1's CRSF card.
- **The hotspot step.** `50-race-day.ps1` stubs it out and `30-hotspot.ps1` drives
  `hotspot.js`/`hotspotVerify.js` directly, so `main/hotspotLifecycle.js` — the module
  race day actually calls — is exercised by **nothing**; `[win-TBD]`
  (`w17-windows-vm-validation-runbook.md:448-453`). If the saved network plan is the
  hotspot, step (a) of this sequence is measured here for the first time, and the
  AP-capable 5 GHz adapter is not bought yet (`:470-472`).
- **The giftee's actual x64 PC.** An ARM64 VM under x64 emulation is a software stand-in;
  the real machine gets its own pass at handover (`:454-455`).
- **AV interference**, which is explicitly the reason the constant is unknown
  (`raceDayOrchestrator.js:90-92`) and which varies by machine: five runs on one PC
  characterise that PC.
- **A lag on STOP** (criterion 10) is asked to be *recorded* by the checklist
  (`setup_flow_bench_checklist.md:239`) with no threshold attached.

## THRESHOLD MISSING — owner/bench decides

| Missing number | Where the gap is | What this card does instead |
|---|---|---|
| The **acceptable** cold link latency (as distinct from the current 5000 ms *window*) | nothing states what is acceptable to a giftee; 5000 is explicitly unvalidated (`raceDayOrchestrator.js:89-96`) | measures against 5000, reports headroom and spread, and recommends nothing |
| Minimum headroom | not recorded anywhere | criterion 2 proposes **1000 ms** as a *review* trigger, not as a standard; it is this card's suggestion and must be ratified or replaced |
| Acceptable spread across cold runs | not recorded anywhere | criterion 3 proposes **2000 ms** on the same footing |
| Acceptable STOP-button lag | `setup_flow_bench_checklist.md:239` says "record any lag", no number | recorded, not judged |
| How many cold runs constitute a characterisation | not recorded anywhere | five, chosen by this card; say so when reporting |

## Evidence label

**NOT-EXECUTED.** Nothing on this card has been run. `LINK_UP_WAIT_MS = 5000` remains
`[bench-TBD]`, Windows behaviour remains unproven until the WS3 session, and FIRST_ACTIVE
stays NO-GO.
