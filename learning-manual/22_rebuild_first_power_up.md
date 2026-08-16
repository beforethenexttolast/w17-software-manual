# 22 — Rebuild: First Power-Up Under the Gate Discipline (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

The most safety-loaded chapter of the track: taking a fully built, flashed,
never-powered car to first driving, **by the same gate ladder the project itself is
bound to** — not a relaxed stranger's version. Sequence: the A2 no-power checklist
(continuity, polarity, rail isolation, connector seating — measurements recorded in
writing), review of the filled checklist, then Phase-B powered bring-up in its staged
order (receiver link and failsafe proven before the ESC's motor power is ever
connected), through to the first gentle drive and the FPV chain live.

## Prerequisites

Every prior stub complete: built cassette (19), flashed boards (20), ground side
working in demo mode (21). A multimeter and the discipline to stop on any failed line
item — the chapter will open with the project's own rule: **no unattended powered
sessions, no skipped gates, warn-only battery telemetry is not an excuse to run low.**

## Existing sources to build from (cite, don't copy)

- **[C]** `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` — the
  canonical A2 checklist. Status at this stub's writing: **committed, NOT EXECUTED**
  (`../CURRENT_STATUS.md`) — the project has never yet passed its own gate, which is
  exactly why this chapter cannot be written yet.
- **[C]** `w17-control-fw/project-review/11_hardware_validation_plan.md` — the
  bench-validation ledger (ESC behavior, PWM timing, battery ADC calibration, Hall
  ISR under real pulses) that Phase B must retire item by item.
- **[C]** `w17-control-fw/CLAUDE.md` "Hardware gates" + "Safety priorities" — failsafe
  first, arm gate, ESC boot sequence, monitoring-only battery; the ordering this
  chapter inherits verbatim.
- **[C]** Chapter [13_bare_board_smoke_test.md](13_bare_board_smoke_test.md) — the
  only powered precedent so far (bare boards over USB, owner-approved scope), useful
  as the model for how this chapter should record evidence.

## Written when

**Only after A2 has been executed and Phase B has actually run** on the project's own
car — the chapter is a cleaned-up transcript of real gate evidence (filled checklist
values, observed failsafe behavior, ESC arm sequence timings), generalized for a
stranger's build. Writing it earlier would be publishing a bring-up procedure no one
has survived; the manual's own chapter 12 lesson ("tests green ≠ proven") forbids
exactly that.
