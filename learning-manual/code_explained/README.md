# code_explained/

Line-by-line source explanations, one markdown file per batch (see
`../source_code_explanation_plan.md` for the batch definitions and
`../source_code_progress.md` for status).

**Reading these today (2026-09-03):** every batch below is a dated snapshot — each
file's own VERIFIED/CONFIRMED claims are tied to the source revision it was walked
against, and none has been retroactively rewritten to match later changes (that would
falsify what was actually checked at the time). Four real drifts are big enough to flag
here rather than trust every reader to notice the per-file dated notes:
- **link2 is v2, not v1** (14-byte payload / 17-byte frame, since 2026-08-17) —
  `control_fw/08_link2_outbound_protocol.md` and
  `soundlight_fw/01_link2_receiver_and_protocol_compatibility.md` both teach v1.
  Current protocol: `../09_communication_protocols.md`.
- **`ArmGate` gained a second latch 2026-08-20** (the re-arm invariant) —
  `control_fw/05_channels_mapping_and_arm_gate.md` teaches the single-latch original.
  Current behavior: `../10_algorithms_state_machines_timing.md` §2.
- **The settings blob is v2** (six sub-configs), not v1 (three) —
  `control_fw/09a_settings_persistence.md`, `09a_concept_teaching_notes.md`,
  `09b_console_tuning_and_settings_store.md`, `09b_concept_teaching_notes.md` all
  teach v1. Current shape: `../06_control_firmware_architecture.md` §2.8.
- **Test counts are all stale** — every batch quotes the suite size at its own
  writing (a legitimate historical fact); today's counts are control-fw 330,
  soundlight 137, ground-station 1447 (`../02_repository_map.md`).
Each affected file carries its own dated note at the top pointing to the current
teaching chapter; this entry exists so the pattern is visible without opening all of
them first.

## Layout

- `control_fw/` — w17-control-fw batches `01_…` to `10_…` (plan IDs C1–C10)
- `soundlight_fw/` — w17-soundlight-fw batches `01_…` to `05_…` (plan IDs S1–S5)
- `ground_station/` — w17-ground-station batches `01_…`–`04_…` so far (plan IDs
  G1–G5b; G4 = `04_scripts_packaging_and_ci.md`, done 2026-07-09; G5a/G5b are the
  iPhone-bridge batches still pending, see the plan)

## Format of each batch file

1. **Scope** — which files, with line counts, and the batch's plan ID.
2. **Prerequisites** — manual chapters/concepts assumed.
3. Per file: the code walked **top to bottom** — every line either explained
   individually or grouped into a named block (never silently skipped) — with C++/JS
   syntax explained at beginner level the first time it appears.
4. **Cross-checks** — running the module's tests; connections to docs/protocols.
5. **Confirmed vs inferred** notes and any new open questions/glossary terms
   (also propagated to the shared files).
6. **Questions to check your understanding.**
