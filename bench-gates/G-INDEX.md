# G-INDEX — ground-side bench-gate cards

Ground side = laptop, Windows, mapper, phone video, and the FIRST_ACTIVE request.
The firmware/bench side is `INDEX.md` and its un-prefixed cards (same folder).
Every card here is **NOT-EXECUTED**. Writing a card executes no gate.

| Card | Gate | State today | Class |
|---|---|---|---|
| [`G-01`](G-01_first_active_request_preconditions.md) | FIRST_ACTIVE — preconditions to even *request* the review | **NO-GO / BLOCKED** — 10 R rows NO-GO, 1 PARTIAL, ≥ 8 Layer-1 items not real-device validated, roadmap step **L** does not exist | desk work only; unlocks nothing by design |
| [`G-02`](G-02_phone_video_glass_to_glass_latency.md) | Phone video real glass-to-glass latency, and the phone-vs-laptop delta | **BENCH-TBD** — every latency figure in the repos is a simulator/loopback figure | Phase B / CB5 |
| [`G-03`](G-03_windows_gamepad_hotplug.md) | Windows gamepad hot-plug: unplug, replug, control resumes | **BENCH-TBD** — the MAP-6 fix's tests inject a fake SDL pump on purpose | real Windows + a hand on a cable; car unpowered |
| [`G-04`](G-04_race_day_link_establishment.md) | RACE DAY link establishment and timing; the 5 s window | **BENCH-TBD** — `LINK_UP_WAIT_MS = 5000` is explicitly unvalidated | real Windows; car unpowered / RX unbound |

## The ladder

```
  owner acts                          this folder                       what it settles
  ─────────                           ───────────                       ───────────────

  (nothing needed) ─────────────────► G-01  request packet ───────────► how far FIRST_ACTIVE is.
                                       │                                UNLOCKS NOTHING.
                                       ▼
                                    hand to owner ─┐
                                                   │
  install Windows / VM ─────────────► G-03  pad hot-plug ─────────────► MAP-6 fixed on real SDL;
     + a DS4 + a hand                  │                                which derived id the
                                       │                                profile must name;
                                       │                                "reconnect + two-step"
                                       ▼                                is a true sentence
  GCS box on a COM port,            G-04  RACE DAY link + timing ─────► LINK_UP_WAIT_MS settled;
  car UNPOWERED / RX unbound          │                                 MAP-1 / MAP-2 / SYN-2
                                      │                                 confirmed on real Windows;
                                      │                                 the giftee wording is true
                                      ▼
  A2 no-power inspection ──► Phase B approval ──► camera powered
                                                       │
                                                       ▼
                                    G-02  phone video latency ────────► the phone-vs-laptop delta;
                                                                        DRIVE vs SHOWPIECE for the
                                                                        phone; whether fallbacks
                                                                        (b)/(c) come off the shelf
```

**G-03 and G-04 need no A2 and no Phase B** — they need real Windows, a pad, a COM port,
and a car that is not powered. **G-02 needs Phase B**, because a streaming camera is a
powered camera. **G-01 needs nothing and unlocks nothing**; it exists so the distance to
FIRST_ACTIVE can be read in one place instead of reconstructed each time.

Suggested order if a Windows session opens: **G-03 → G-04**. G-03's phase 0
(`-list-devices`) settles the derived gamepad id, and G-04's profile has to carry the
right one.

## Standing rules that bind every card here

1. **FIRST_ACTIVE is NO-GO / BLOCKED.** No card runs, prepares or rehearses it
   (`head_tracking_unlock_plan.md:1366-1385`, `W17_CURRENT_STATE.md:61`).
2. **A2 is NOT-EXECUTED ⇒ Phase B is BLOCKED.** G-02 waits (`W17_CURRENT_STATE.md:61`).
3. **The car is unpowered, or its RX is unbound**, on every card that can put CRSF on a
   wire — G-03 run B and all of G-04
   (`w17-windows-vm-validation-runbook.md:370-384`).
4. **No card is R15 evidence.** R15 is *device loss ⇒ **arbiter** disarm*, against arbiter
   code parked on `u4-arbiter`, and it stays NO-GO after a green run of anything here
   (`60-hid-transition.ps1:13-29`, `CURRENT_STATUS.md:1384-1385`).
5. **`u4-arbiter` is read with `git show` only.** Never checked out, never merged, never
   pushed.
6. **No threshold is invented.** Where a number is missing, the card says
   *THRESHOLD MISSING — owner/bench decides* and lists it. G-02 and G-04 both have one.
7. **A procedure existing is not a PASS.** Every card starts and stays NOT-EXECUTED until
   someone runs it and saves the evidence the card names.

## Tooling

`tools/` (host-side, no hardware needed to write or test it):

| File | For | Notes |
|---|---|---|
| `latency_rig.html` | G-02 | offline, self-contained: full-screen flash + 7-digit ms counter + 12-bit binary flash-id strip. No network, no external asset |
| `latency_from_frames.py` | G-02 | frame indices → latency; random bound = one capture frame; systematic bias itemised and reported separately. Targets are opt-in. `exit 0/1/2` |
| `raceday_timing.py` | G-04 | timestamped capture → press/spawn/claim deltas; PASS/FAIL against `LINK_UP_WAIT_MS`. Refuses an unstamped capture (`exit 2`) rather than inventing a zero. Every marker carries its own `path:line` |
| `tests/run_tests.py` | both | synthetic fixtures, 52 checks. `python3 bench-gates/tools/tests/run_tests.py` → exit 0 |

Fixtures are `*_capture.txt`, not `*.log`, because the workspace `.gitignore:30` ignores
`*.log`.

## Where the evidence goes

```
bench-gates/evidence/G-01/   G-02/   G-03/   G-04/
```

Each card's *Outputs to save* section names its own files. An empty folder is the honest
state today.
