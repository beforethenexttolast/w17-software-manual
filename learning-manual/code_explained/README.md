# code_explained/

Line-by-line source explanations, one markdown file per batch (see
`../source_code_explanation_plan.md` for the batch definitions and
`../source_code_progress.md` for status).

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
