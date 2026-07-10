# 00 — Start Here

Welcome. This is a learning manual for the **W17 project**: a 1/10-scale, FPV,
3D-printed RC Formula 1 car (Mercedes W17 livery) built as a gift, powered by two ESP32
boards and a laptop ground station. The manual assumes you are a **beginner programmer**
— every C++, electronics, embedded, RC, and desktop-app concept is explained when it
first appears, using this project's real files as examples.

## The three repositories

| Repo | Nickname in this manual | One-liner |
|---|---|---|
| `w17-control-fw` | **the control board** (ESP32 #1) | Radio in → safety + driving logic → servo/motor out. The main module. |
| `w17-soundlight-fw` | **the sound/light board** (ESP32 #2) | Listens to board #1, makes V10 engine sound and F1 light effects. |
| `w17-ground-station` | **the ground station** | Laptop app: live video + F1 HUD + telemetry. Viewer only — never drives the car. |

## Reading order

Read the chapters in numeric order — each one only uses concepts introduced earlier:

1. [01_total_system_overview.md](01_total_system_overview.md) — the whole system in one sitting
2. [02_repository_map.md](02_repository_map.md) — how the code is organized and why
3. [03_hardware_and_electronics_basics.md](03_hardware_and_electronics_basics.md) — the physics under the software
4. [04_embedded_cpp_basics.md](04_embedded_cpp_basics.md) — the C++ you need, taught on this codebase
5. [05_control_firmware_documentation_explained.md](05_control_firmware_documentation_explained.md) — guided tour of `w17-control-fw/docs/`
6. [06_control_firmware_architecture.md](06_control_firmware_architecture.md) — the main firmware, module by module
7. [07_soundlight_firmware_architecture.md](07_soundlight_firmware_architecture.md) — the sound/light firmware
8. [08_ground_station_architecture.md](08_ground_station_architecture.md) — the Electron app
9. [09_communication_protocols.md](09_communication_protocols.md) — CRSF, link2, and telemetry, byte by byte
10. [10_algorithms_state_machines_timing.md](10_algorithms_state_machines_timing.md) — the interesting logic, in depth
11. [11_build_flash_debug_workflow.md](11_build_flash_debug_workflow.md) — how to build, test, flash, and poke everything
12. [12_the_skeptical_audit_and_f1_f4_fixes.md](12_the_skeptical_audit_and_f1_f4_fixes.md) — the independent audit, its risk register, the F1–F4 fixes, and why "tests green" ≠ "proven"

Support files, used from any chapter:

- [glossary.md](glossary.md) — every term, alphabetical
- [open_questions.md](open_questions.md) — things only the project owner can confirm
- `code_explained/` — the **line-by-line source-code deep dives**. Control firmware
  complete + reviewed: batches C1–C10 in `code_explained/control_fw/`; sound/light
  firmware explanation complete: batches S1–S5 in `code_explained/soundlight_fw/`
  (review pass pending); ground station started: batches G1–G4 in
  `code_explained/ground_station/` (the full viewer-app story; iPhone-bridge batches
  G5a/G5b pending). Beginner concept-notes companions
  exist for C9a/C9b/C10 and S1–S5. Status:
  [source_code_progress.md](source_code_progress.md);
  inventory/order: [source_code_explanation_plan.md](source_code_explanation_plan.md)
- `plan/` — the original study plan (historical; superseded by these chapters)

## Conventions used everywhere

- **[C] Confirmed** — stated in a repo document or visible in code; the source file is cited.
- **[I] Inferred** — deduced; the evidence chain is given.
- **[A] Assumption** — plausible but unverified; treat with suspicion until bench-checked.
- File references look like `w17-control-fw/lib/failsafe/src/FailsafeStateMachine.cpp` —
  paths are relative to `/Users/vitaliykhomenko/Documents/projects/`.
- Each chapter ends with **Questions to check your understanding** (answers are always
  derivable from that chapter; no trick questions).
- Chapters describe architecture and behavior. **Line-by-line code walkthroughs live in
  `code_explained/`** — the control firmware's ten batches (C1–C10) and the sound/light
  firmware's five (S1–S5) are complete; the ground-station campaign (G1–G5b, plan
  rewritten after the 2026-07-09 re-inventory) has G1–G4 done, the iPhone-bridge
  batches G5a/G5b next.
- Citation caveat: `w17-control-fw/CLAUDE.md` was **rewritten 2026-07-09** as a
  maintenance guide without the old §0–§8 numbering. Manual references of the form
  "`CLAUDE.md` §N" point at the **pre-rewrite revision**; the underlying facts were
  independently re-verified against source in C1–C10, so the claims stand — only the
  section anchors are historical. (Tracked in `manual_standardization_audit.md`.)

## Verify your environment (10 minutes, no hardware needed)

A key property of this project: almost everything runs on your computer.

```bash
# Firmware unit tests (should report 147 and 40 passing)
cd w17-control-fw   && pio test -e native
cd w17-soundlight-fw && pio test -e native

# Ground station tests + a live-looking demo (no car, no camera)
cd w17-ground-station && npm install && npm test && npm run demo
```

If these pass, you have a working lab for the entire manual.

## Project status snapshot (as of 2026-07-03)

**[C]** All software is written and unit-tested; **no hardware bring-up has happened yet**
(parts not yet arrived/printed). Source: `w17-control-fw/docs/ROADMAP.md` (all D-items ✅
except D8 "gated on parts") and `docs/bill_of_materials_v2.md` ("Nothing printed yet").
Gift deadline: **2026-07-21**.

**Update 2026-07-05:** the control firmware's line-by-line explanation campaign is
complete (C1–C10, `code_explained/control_fw/`) — verified against 147/147 native tests
and all three firmware builds. One notable finding: the delivered gift build does **not**
load NVS-saved tuning (open question #49). Hardware status unchanged.

**Update 2026-07-09:** the sound/light explanation campaign is complete (S1–S5,
`code_explained/soundlight_fw/`, 2026-07-06; 40/40 native tests + both firmware builds
— review pass pending). Since then the source repos received a **skeptical-audit fix
round (F1–F4, 2026-07-07/08)** and iPhone-bridge work (W1–W3, ground station).
**The audit and its fixes now have their own chapter:
[12_the_skeptical_audit_and_f1_f4_fixes.md](12_the_skeptical_audit_and_f1_f4_fixes.md)**;
the iPhone-bridge chapter is still deliberately deferred (open question #58). Two
audit consequences already reflected here: the two firmware `ci.yml` files are **no
longer byte-identical** (chapter 11 §7, chapter 12 §6), and `w17-control-fw/CLAUDE.md`
was rewritten (see the citation caveat above). Later the same day the ground-station
campaign started: the repo was **re-inventoried** (grown to ≈3,770 project-authored
lines by F2–F4 + W1–W3; plan rewritten to batches G1–G5b) and **batches G1 (the shared
pure JS core), G2 (the Electron main process + telemetry sources), G3 (the
renderer — HUD, widget precedence, WHEP video, command mirror), and G4 (scripts,
Electron packaging, the `mediamtx.yml` config, and CI) were explained** — each
verified against 118/118 vitest tests (CI green ≠ hardware/video proof — packaging and
the 118 tests are logic/build evidence only). The iPhone-bridge
code itself remains **implemented + unit-tested, NOT real-device validated** (#58); its
W3 head-tracking receiver is LOG-ONLY by safety boundary. Hardware state (per
`../CURRENT_STATUS.md`): software/pre-power validation A1.1–A1.6 complete; the **A2
no-power bench checklist is committed but NOT executed**; powered bring-up (Phase B)
stays blocked behind it. **Source/build/test evidence is still not hardware proof** —
nothing has been proven on powered hardware.
