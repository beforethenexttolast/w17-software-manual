# 20 — Rebuild: Firmware Flashing (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

Getting both firmwares onto both boards, as a stranger: toolchain install
(PlatformIO), cloning the repos, running the native suites first (the "verify your
lab" ritual from 00_START_HERE), building the right environment for each board —
**delivery `esp32dev`** for the gift car (console-free, loads validated NVS tuning;
`esp32dev_tuning` only for bench tuning) — flashing over USB, and the post-flash
smoke checks that prove the flash took, before any car wiring is involved.

## Prerequisites

Stub 19's cassette need not exist yet — bare boards flash on a desk. Chapters 11
(build/flash/debug workflow) and 13 (bare-board smoke test) are the teaching
foundation; this stub narrows them from "explore everything" to "do exactly this."

## Existing sources to build from (cite, don't copy)

- **[C]** Chapter [11_build_flash_debug_workflow.md](11_build_flash_debug_workflow.md)
  — commands, environments, gotchas (test counts there are stale; see
  `STALENESS_2026-08-17.md`).
- **[C]** Chapter [13_bare_board_smoke_test.md](13_bare_board_smoke_test.md) + its
  evidence file — the project's own first flash, including the boot-log expectations
  a stranger can compare against.
- **[C]** `w17-control-fw/docs/D8_BENCH_BRINGUP.md` Phase 11a — the canonical delivery
  runbook (delivery build reads validated NVS but is console-free and read-only).
- **[C]** `w17-control-fw/CLAUDE.md` "Delivery vs tuning builds" — the three-way
  separation (load / console / mutation) the flashing instructions must preserve.
- **[A]** Flashing the **MH-ET Live D1-Mini** boards specifically: chapter 13's
  evidence covers DevKit V1 clones only; MH-ET flash behavior (auto-boot circuitry,
  port naming) is assumed-similar and must be verified when the real boards flash.

## Written when

After the cassette boards (the MH-ET pair) have been flashed at least once and the
exact `pio` invocations, port names, and expected output are captured from that
session. USB-powered bare-board flashing sits inside the chapter-13 owner-approved
scope; anything beyond bare USB belongs to stub 22's gates, and this chapter will say
so in its first paragraph.
