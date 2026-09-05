# G-03 — Windows gamepad hot-plug: the pad drops, comes back, and control resumes

> The booklet promises the giftee *"reconnect the controller, then do the two-step"*
> (`w17-mapper/pkg/devices/hotplug.go:22-23`). Before MAP-6 was fixed, that sentence
> could not work: the SDL registry was built once at boot and every add/remove event
> body was thrown away, so a pad that dropped never resolved again and nothing short of
> restarting the drive program brought it back (`w17-mapper/pkg/devices/hotplug.go:9-21`).
>
> The fix is on the trunk (`w17-mapper` `w17-headtrack` @ `b859af1`, `w17-mapper/pkg/devices/hotplug.go`).
> **Its tests inject a fake SDL event pump on purpose** — *"no unattended session may plug
> a gamepad in and out on demand"* (`w17-mapper/pkg/devices/hotplug.go:50-52`). This gate is the one thing those
> tests deliberately cannot be: a real hand, on a real cable, on real Windows, against the
> real SDL/OS device-removal path.
>
> **Evidence label: NOT-EXECUTED.**

---

## Prerequisites

- **Run B is un-gated by A2/Phase B, but is a live-TX bench procedure under
  `w17-windows-vm-validation-runbook.md`:370-397: car UNPOWERED or RP1 UNBOUND, no bound
  RX powered in range, attended, discharges nothing (RESIDUAL A); requires explicit owner
  authorization like every other gate.** Leave the TX module's antenna attached — an
  antenna detach is not the sourced mitigation.
  A mapper that is actually driving was started with `-tx-serial-port-name` (or its
  profile's own `tx.port`), which means the COM port is open and CRSF is being
  transmitted (`w17-windows-vm-validation-runbook.md:370-384`,
  `w17-ground-station/scripts/windows-validation/60-hid-transition.ps1:31-49`).
  Why it matters concretely: on gamepad loss the mapper **still transmits at full rate**
  — fail-to-neutral, not fail-silent — so the firmware's radio-loss failsafe does **not**
  fire, and switch channels latch downstream (**RESIDUAL A**,
  `CURRENT_STATUS.md:1380-1385`). Pulling the pad on a live transmitter with a powered
  car is exactly the situation that residual describes.
- Real Windows. An ARM64 VM under x64 emulation stands in for the *software*, not for
  the giftee's actual PC (`w17-windows-vm-validation-runbook.md:454-455`).
- A human physically present. *"nothing in this suite can automate a hand pulling a USB
  cable"* (`60-hid-transition.ps1:7-11`).
- A filled controller profile — `w17-mapper/configs/w17-ds4.json` ships
  `REPLACE-WITH-DS4-ID` / `REPLACE-WITH-COM-PORT` placeholders and the load path now
  refuses an unfilled profile outright (`w17-mapper/pkg/devices/inventory.go:8-10`).
- **This gate is not R15 and discharges nothing on the FIRST_ACTIVE ladder.** R15 is
  *device loss ⇒ **arbiter** disarm*, in arbiter code that is parked on `u4-arbiter` and
  unmerged; R15 stays NO-GO after a green run here
  (`60-hid-transition.ps1:13-29`, `CURRENT_STATUS.md:1384-1385`,
  `w17-windows-vm-validation-runbook.md:385-391`).

## Required equipment

| Item | Why |
|---|---|
| Real Windows PC (ideally the giftee's; otherwise the WS3 VM, labelled as such) | the OS HID stack is the thing under test |
| The DualShock 4 the car ships with, **and its USB cable** | |
| The mapper build under test, on that machine | `w17-mapper` `w17-headtrack` @ `b859af1` or later |
| The filled controller profile (`w17-ds4.json`, no placeholders) | |
| A serial port the profile names — or none | see Topology; the safest run has **no ELRS TX attached at all** |
| A terminal that can timestamp the mapper's stdout | the mapper prints with bare `fmt.Printf`; see Exact commands |
| `pwsh` 7 if using `60-hid-transition.ps1` | required on the guest (`w17-windows-vm-validation-runbook.md:170`) |

## Topology

Two configurations. **Run A first.** Only run B if the owner explicitly wants the
process-continuity half against a driving mapper, and only with the car unpowered.

```
RUN A — SAFEST, and it answers the registry question on its own
  DS4 ──USB──► Windows HID/SDL ──► mapper (no -tx-serial-port-name,
                                           profile with no transmitter OR
                                           TX module physically detached)
                                     │
                                     └─► stdout: (devices): gamepad connected / disconnected
  no COM port open · no CRSF on any wire · no radio · car may be anywhere

RUN B — process-continuity half (60-hid-transition.ps1's question)
  DS4 ──USB──► Windows HID/SDL ──► mapper started BY HAND, driving
                                     │
                                     └─► COM port OPEN, CRSF transmitting
  ⚠ CAR UNPOWERED or RX UNBOUND.  ⚠ RESIDUAL A applies: pad loss = fail-to-NEUTRAL at
     full rate, not fail-silent; switch channels latch downstream.
```

## Exact procedure

**Phase 0 — the id, before anything moves.**

1. With the DS4 plugged in **over USB**, run `-list-devices` and record the derived `id`,
   the raw `guid`, the decoded `bus`, and the axis/button/hat counts. It opens no port
   and no server and then exits (`w17-mapper/pkg/devices/inventory.go:15-16`).
2. Unplug the DS4, pair it over **Bluetooth**, and run `-list-devices` again.
   **The derived id is expected to be different**: SDL packs the bus into the GUID's
   first two bytes, so the same pad reads `0300…` on USB and `0500…` on Bluetooth, and
   `DeriveGamepadId` is an md5 of `guid + name`
   (`w17-mapper/pkg/devices/inventory.go:84-88`, `w17-mapper/pkg/devices/util.go:32-37`). Record both ids.
   This is the trap the profile placeholder warns about, and it decides which id the
   saved profile must carry.
3. Confirm which id the shipped profile actually names, and that it matches the transport
   the car will be used on.

**Phase 1 — run A, the registry question.**

4. Start the mapper with the timestamping capture (Exact commands), DS4 plugged in.
   Confirm one `(devices): gamepad connected: … (id …)` line, with the id from step 1.
5. **Unplug the DS4.** Expect exactly one
   `(devices): gamepad disconnected: … (id …)`, with the **same** id.
6. Wait 5 s. **Replug the DS4.** Expect exactly one
   `(devices): gamepad connected: … (id …)`, with the **same** id again — the id was
   freed on removal, so the first holder's id is available to the pad when it returns
   (`w17-mapper/pkg/devices/hotplug.go:125-137`).
7. Repeat steps 5–6 **five times**, at varying intervals (immediate replug, 1 s, 5 s,
   30 s), and once with the pad replugged into a **different USB port**.
8. Start the pad **absent** and plug it in only after the mapper is up. Expect a
   `connected` line — a pad switched on after start-up never appeared at all before the
   fix (`w17-mapper/pkg/devices/hotplug.go:12`).
9. Watch for `(devices): a gamepad was plugged in at index N but could not be opened`
   (`w17-mapper/pkg/devices/hotplug.go:102`). It is a real outcome, not an error to be ignored, and it means
   the pad is present to Windows but not openable by SDL.

**Phase 2 — control resumes, and the two-step really is needed.**

10. With the pad connected and the profile loaded, confirm the node graph resolves the
    pad again after a replug — read it through the mapper's own read-only surfaces, not
    by driving the car. `-list-devices` cannot answer this (it exits); use the web UI's
    device page or the `GetGamepads` / `GetGamepadStream` RPC on loopback.
11. Confirm the arm chain did **not** silently re-arm across the gap: `reset_on_nan`
    requires a fresh TRIANGLE press after the dropout, and hot-plug does not weaken that
    (`w17-mapper/pkg/devices/hotplug.go:19-21`, `:40-42`). Verify a fresh press is required.
12. Record whether the **booklet's sentence is now true**: reconnect the controller, do
    the two-step, and control is back without restarting the drive program.

**Phase 3 — run B, process continuity (optional, only with the car unpowered).**

13. Start the mapper by hand, driving, and run `60-hid-transition.ps1` against it. It
    tracks the process by image name and never spawns or stops anything mapper-side
    (`60-hid-transition.ps1:51-60`). Record the pid before, during and after.

## Exact commands

Phase 0 — zero-risk, opens nothing:

```powershell
# On the Windows machine, in the mapper's folder.
.\elrs-joystick-control.exe -list-devices | Tee-Object -FilePath .\G-03_inventory_usb.json
# ... unplug, pair over Bluetooth, then:
.\elrs-joystick-control.exe -list-devices | Tee-Object -FilePath .\G-03_inventory_bt.json
```

Phase 1 — run A, with every line timestamped as it arrives (the mapper stamps nothing
itself; every line it prints comes from a bare `fmt.Printf`):

```powershell
$log = ".\G-03_hotplug_runA_$(Get-Date -Format yyyyMMdd-HHmmss).txt"
& .\elrs-joystick-control.exe -config-file-path C:\W17\w17-ds4-noTX.json 2>&1 |
  ForEach-Object { '{0} {1}' -f (Get-Date).ToUniversalTime().ToString('o'), $_ } |
  Tee-Object -FilePath $log
# Ctrl-C to stop. Then, for the transitions only:
Select-String -Path $log -Pattern '\(devices\): gamepad (connected|disconnected)|could not be opened'
```

Phase 3 — run B, **only** with the car unpowered / RX unbound:

```powershell
# 1) start the mapper by hand, driving, in its own window, redirecting its output:
#    (this opens the COM port — read the safety precondition again first)
& .\elrs-joystick-control.exe -config-file-path C:\W17\w17-ds4.json *>&1 |
  Tee-Object -FilePath .\G-03_mapper_runB.txt

# 2) in a SECOND, interactive session (`ssh -t`, not a one-shot `ssh`):
pwsh -File .\scripts\windows-validation\60-hid-transition.ps1 `
     -MapperExe elrs-joystick-control.exe `
     -MapperLogPath .\G-03_mapper_runB.txt `
     -ResultsDir .\G-03-results
```

**Commands that must NOT be run:** anything that powers the car; anything that binds the
mapper's ports to all interfaces (`-bind-all` prints its own warning at
`w17-mapper/cmd/elrs-joystick-control/main.go:141-143` and this card never needs it); and any
attempt to reach FIRST_ACTIVE build tags or the `-first-active-arm` flag, which do not
exist in a default build and are not this gate's business.

## Expected evidence

| Marker | Where it comes from | When |
|---|---|---|
| `(devices): gamepad connected: <name> (id <id>)` | `w17-mapper/pkg/devices/hotplug.go:145` | boot enumeration and every plug-in |
| `(devices): gamepad disconnected: <name> (id <id>)` | `w17-mapper/pkg/devices/hotplug.go:182` | every unplug |
| `(devices): a gamepad was plugged in at index N but could not be opened` | `w17-mapper/pkg/devices/hotplug.go:102` | a plug-in SDL refused |
| `-list-devices` JSON: `id`, `name`, `guid`, `bus`, `axes`, `buttons`, `hats` | `w17-mapper/pkg/devices/inventory.go:35-49` | phase 0 |

> ### Stale-doc finding to correct as part of this gate
> `w17-ground-station/scripts/windows-validation/60-hid-transition.ps1:69-84` (at GS
> `main` `379cf29`) says MAP-6 is present, that *"there is no add/remove log line to
> grep for today"*, and that `-MapperLogPath`'s tail is *"expected to show nothing
> related to the pad transition"*. **All three are now false** at mapper `b859af1`:
> `w17-mapper/pkg/devices/hotplug.go` handles both events and prints the three lines above.
> The script's OS-level measurement is unaffected; only its narration is stale. Record
> the correction as an owner-facing doc fix — it is a `w17-ground-station` change and
> therefore a different repo and a different session.

## PASS / FAIL criteria

| # | Criterion | PASS | FAIL |
|---|---|---|---|
| 1 | Unplug is seen | exactly **one** `disconnected` line per unplug, id matching | zero lines (the OS event never reached SDL), or more than one |
| 2 | Replug is seen | exactly **one** `connected` line per replug | zero lines |
| 3 | **The id is stable across the cycle** | the `connected` id after a replug is **byte-identical** to the id before the unplug | any different id, and in particular any `<id>_<n>` suffixed form — the suffix means the bare id was still taken, which is the two-identical-pads limit at `w17-mapper/pkg/devices/hotplug.go:130-137` and must not appear on a single-pad rig |
| 4 | Repeatable | **5 of 5** unplug/replug cycles satisfy 1–3, including a different USB port | any cycle that does not |
| 5 | Cold-absent start works | a pad plugged in **after** the mapper started produces a `connected` line and resolves | no line, or a line whose id does not match the profile |
| 6 | No re-arm across the gap | a fresh TRIANGLE press is **required** before the arm chain is live again | the toggle re-arms itself after a dropout |
| 7 | Control resumes | the node graph resolves the pad after replug, with no drive-program restart | control does not come back — the booklet's promise is still false |
| 8 | Bus/id trap documented | USB and Bluetooth ids both recorded, and the shipped profile names the right one | not recorded |
| 9 | (run B) Process continuity | the mapper's pid is unchanged before/during/after | the process died or was restarted by the transition |

Criterion 3 is the one that actually decides whether MAP-6 is fixed on real hardware —
the fix's whole mechanism is "the id was freed when the pad was removed, so the first
holder's id is available again" (`w17-mapper/pkg/devices/hotplug.go:125-137`).

## Stop conditions

Stop immediately if:

- the car is or becomes powered, or the RX is bound, during run B;
- an unplug produces **no** `disconnected` line but the pad's values keep changing — that
  would mean a detached handle is still being read, which the retire-don't-close design
  exists to prevent (`w17-mapper/pkg/devices/hotplug.go:148-170`), and it is a serious finding;
- the mapper crashes on unplug or replug (record the stdout tail; it is the evidence);
- the arm chain re-arms itself without a fresh press (criterion 6) — that is a safety
  finding, not a nuisance;
- anyone proposes reading this gate as R15 evidence, or as unlocking any FIRST_ACTIVE
  row. It is not, and it does not.

## Rollback

Nothing persistent is changed. Stop the mapper (Ctrl-C in its window, or STOP RACE DAY /
Task Manager for a managed child). Retired SDL handles are released at `Quit`, by design
— the cost is *"one SDL_Joystick object … per unplug, held until Quit"*, a bounded leak
(`w17-mapper/pkg/devices/hotplug.go:161-166`), so a long run with many cycles should end with a restart rather
than being left running.

If run B was performed, confirm no mapper process survives, and confirm no serial port is
left held.

## Outputs to save

```
bench-gates/evidence/G-03/
  inventory_usb.json            # -list-devices over USB
  inventory_bt.json             # -list-devices over Bluetooth
  id_decision.md                # both ids, which one the profile names, and why
  hotplug_runA_<stamp>.txt      # the timestamped capture, all 5 cycles + cold-absent start
  transitions.txt               # the Select-String extract, one line per event
  arm_chain_reset.md            # criterion 6: what was pressed, what happened
  control_resumed.md            # criterion 7, and whether the booklet sentence is now true
  runB/                         # 60-hid-transition.ps1 result JSON + mapper stdout, if run
  doc_fix_owed.md               # the 60-hid-transition.ps1:69-84 staleness, for the GS session
```

## Downstream unlocked by PASS

- Establishes on real hardware that **MAP-6 is fixed**, which the fake-pump unit tests
  deliberately cannot (`w17-mapper/pkg/devices/hotplug.go:50-52`).
- Makes the booklet's recovery sentence — *"reconnect the controller, then do the
  two-step"* — a verified claim rather than an intention (`w17-mapper/pkg/devices/hotplug.go:22-24`).
- Settles the USB-vs-Bluetooth derived-id question for the gift-kit profile, which the
  install step depends on.
- Supplies the correction owed to `60-hid-transition.ps1`'s header.

**It does not unlock:** R15 or any FIRST_ACTIVE row (all still NO-GO), A2, Phase B, or
anything about CRSF reaching the receiver over RF.

## BENCH-TBD residue

- **Which Windows joystick backend SDL binds the DS4 through** (HIDAPI vs
  XInput/RawInput/DirectInput). `DecodeGUIDBus` is explicitly *"a HINT, not an
  authority… it has not been checked on Windows/HIDAPI against a real DualShock 4 —
  `[bench-TBD]`"* (`w17-mapper/pkg/devices/inventory.go:90-94`). The backend determines the GUID,
  the GUID determines the derived id, and the profile names an id — so this is not
  trivia. **Record the raw GUID, never only the decoded bus hint.**
- **Whether control resumes** after a replug was, before this gate, explicitly
  unsettleable by the WS3 suite — *"the mapper's own gamepad registry is not
  independently queryable without a control-path probe this suite deliberately does not
  build"* (`w17-windows-vm-validation-runbook.md:439-441`). Phase 2 step 10 answers it
  through the mapper's own read-only surfaces; if the owner declines that, criterion 7
  stays BENCH-TBD.
- **RESIDUAL A** is untouched by this gate and stays open: pad loss ⇒ fail-to-neutral at
  full rate, switch channels latch downstream, firmware radio-loss failsafe does not fire
  (`CURRENT_STATUS.md:1380-1385`).
- **Two identical pads.** `w17-mapper/pkg/devices/hotplug.go:130-137` records a real limit: with two identical
  pads, "first holder keeps the id" holds only while that holder is attached. The W17 rig
  is single-pad, so this cannot arise on race day — but a rig that ever gains a second
  identical pad must not rely on which one a bare id lands on.
- **Bluetooth dropout under battery dip**, which is the failure the fix was written for
  (`w17-mapper/pkg/devices/hotplug.go:14-16`), is not reproducible on demand and is not tested by this card.

## Evidence label

**NOT-EXECUTED.** Nothing on this card has been run. Windows behaviour remains unproven
until the WS3 VM session (`W17_CURRENT_STATE.md:61`), and a green run here moves no gate.
