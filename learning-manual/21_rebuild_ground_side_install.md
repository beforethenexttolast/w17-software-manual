# 21 — Rebuild: Ground-Side Install — Mapper, Ground Station, GCS Box (SKELETON)

> Part of the rebuild track — see [16_rebuild_track_overview.md](16_rebuild_track_overview.md).

## Scope

The PC side, built the way the gift kit defines it (`../W17_PRODUCT_VISION.md`,
"Gift kit"): the ground station installed on a **normal Windows PC via an installer**
(not a dev checkout), the mapper as a **packaged binary loading the saved W17 profile
headless** (`--config-file-path`, no editor UI), and the ground-side hardware living
in the **3D-printed one-cable GCS box** (ELRS TX module + hotspot Wi-Fi adapter + USB
hub; optional 12 V input). Ends with the race-day bring-up a non-developer can
perform.

## Prerequisites

Stub 17 for the ground-side parts; chapter 15 for what the mapper *is*; chapter 08
for the ground station. Independent of the car-side stubs — this can be built and
dry-run before a car exists (the GS demo mode needs no car).

## Existing sources to build from (cite, don't copy)

- **[C]** GS packaging: `w17-ground-station/electron-builder.yml` (NSIS target) plus,
  since the 2026-08-17 merge of the giftee wave (`abaddbd`), an **unsigned NSIS CI
  job on main** — GS was pushed the same day under the GS-only push exception
  precisely to produce the first installer artifact (audit low finding 10; workspace
  `0542e29`). At this stub's writing that first artifact was **still unconfirmed**;
  verify it exists and installs before writing this chapter.
- **[C]** Mapper profile: `configs/w17-ds4.json` on the unmerged `w17-audit-wave1`
  branch, with two Windows-bench placeholders (pad id, COM port) — chapter 15 §6.
- **[C]** GCS box: contents/wiring/BOM are Claude-side, box print is Codex-side; the
  open power question (bus-powered vs 12 V hub) is a recorded bench measurement
  (`../W17_PRODUCT_VISION.md` backlog + open points).
- **[C]** Race-day orchestration ("one-action bring-up": hotspot + mapper + GS +
  bridge) is a **planned** wave, not an existing feature — the audit's done-bar-8 row.
  Until it lands, this chapter's bring-up is a numbered manual sequence.
- **[I]** Windows specifics (hotspot lifecycle, ELRS COM enumeration via
  `go.bug.st/serial` v1.6.0) are unit-tested against canned output on macOS only —
  recorded validation debt (`../CURRENT_STATUS.md`), so every Windows step here is
  unverified until the giftee-PC end-to-end test runs.

## Written when

After the giftee-PC end-to-end install test: real installer artifact installed on a
real Windows machine, mapper enumerating the real TX COM port, saved profile driving
the bench rig, GCS box assembled with its measured power budget. That test is itself
on the hardware-gated ledger — this chapter is the *documentation* of its success,
not a substitute for it.
