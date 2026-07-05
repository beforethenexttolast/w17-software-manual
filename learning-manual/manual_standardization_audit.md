# Manual Standardization Audit — after C10 (2026-07-05)

Scope: the 12 overview chapters (Standard A) + all completed control-fw code-explained
docs (Standard B). Method: every chapter read in full this session; code-explained docs
audited structurally (headings/sections) plus the content already verified in the C10
session; all C10-resolved facts cross-checked. **Small/high-value patches were applied
immediately** (list in §3); nothing was rewritten wholesale.

Verdict key: **OK** (meets its standard as-is) · **PATCHED** (small fixes applied this
session → now OK) · **NEEDS MAJOR** (requires owner approval before doing) ·
**DEFER** (correctly waits on S/G batches or hardware).

---

## 1. Overview chapters (Standard A)

| File | Verdict | Notes |
|---|---|---|
| `00_START_HERE.md` | **PATCHED** | Was stale in 3 places: "line-by-line walkthroughs are a later phase" (they exist), support-files list missing `code_explained/` + progress/plan files, status snapshot frozen at 07-03. All fixed; added the #49 finding to the status update. |
| `01_total_system_overview.md` | **OK** | Accurate after C10 (the §4 end-to-end walk matches main.cpp's real order; "187 tests" = 147+40 still correct). Beginner-friendly, well-cited, right length. |
| `02_repository_map.md` | **PATCHED** | Accurate; added one pointer block after the module table (every lib now has a C1–C10 deep dive). The "preload.cjs awaits the code-reading phase" note is still correct (G2 pending) — left. |
| `03_hardware_and_electronics_basics.md` | **OK** | Nothing C10-affected; no unexplained terms; layered-EMI framing matches C7. No action. |
| `04_embedded_cpp_basics.md` | **PATCHED** | Added one cross-link sentence (language chapter ↔ code_explained). Content accurate. *Nit (accepted, not patched):* §11's "setup() wires HALs into modules" is loose — construction happens in static init; `setup()` attaches hardware (C10 §2–3). Chapter 06 carried the same imprecision more prominently and got the correction note; here it reads as shorthand and the chapter's §9/§10 are otherwise exact. |
| `05_control_firmware_documentation_explained.md` | **OK** (patched in the C10 session) | The Phase 11 "NVS persists" claim got its C10 caution note earlier today. Phase 10's stale wording was already flagged (open q #41). 970 lines is justified — it tours ~10 repo docs. No further action. |
| `06_control_firmware_architecture.md` | **PATCHED** (heaviest) | Five fixes across two sessions: (1) the wrong "NVS-saved tuning still loads" **[C]** claim → corrected (C10 §8, #49); (2) "deep dives come later" → they exist; (3) §3's "setup() constructs HAL objects" → static-init/attach distinction corrected; (4) "await the line-by-line pass" → confirmed-by-C10; (5) added the per-module deep-dive map at the top of §2. Now the accurate architectural companion to the C1–C10 batches. |
| `07_soundlight_firmware_architecture.md` | **OK / DEFER** | Accurate; its "awaits the code deep-dive" notes (atomic-word bit layout, open q #43) are correctly still open — they belong to S2–S5. Re-audit after S5. |
| `08_ground_station_architecture.md` | **OK / DEFER** | Accurate; "exact widget-by-widget precedence awaits the code pass" is correctly still open (#47, G3). Re-audit after G4. |
| `09_communication_protocols.md` | **PATCHED** | Added the deep-dive pointer (C3/C4/C8/C10 §4.7; G1 for the JS side). The golden-frame hand-decode remains the manual's best single teaching artifact. Everything byte-level re-verified during C8/C10 — no drift. |
| `10_algorithms_state_machines_timing.md` | **PATCHED** | Two fixes: deep-dive pointer added; the "±1 until the line-by-line pass" hedge on the gearbox example resolved (C6 confirmed 125 exact — open q #44 annotated as answered). Everything else matches the C1/C5/C6/C7 deep dives. |
| `11_build_flash_debug_workflow.md` | **PATCHED** | Three fixes: (1) §3's "NVS-saved tuning survives the reflash" → C10 caution added (survives *in flash*, unread by the gift build, #49); (2) §7's "workflow contents not yet reviewed" → control ci.yml now explained (C10 §9) incl. the tuning-env-not-in-CI gap; (3) understanding question 4 rewritten (its premise embedded the old misconception). |
| `README.md` | **PATCHED** | Added the status pointer (progress file + this audit) — CLAUDE.md says sessions start here, and it previously carried no status at all. |

**Standard A cross-cutting checks:**
- *Concepts before use / unexplained terms:* clean. Reading order holds; each chapter's
  first-use terms are defined in place and in the glossary.
- *Repeated concepts vs cross-links:* chapters repeat only one-line reminders and link
  out; no bloat found. The new deep-dive pointer blocks (02/06/09/10) close the one real
  gap — chapters predated the batches and never pointed at them.
- *Labeling systems:* chapters use **[C]/[I]/[A]**, code docs use
  **VERIFIED/INFERRED/PROVISIONAL** — parallel, consistently applied within each domain
  ([C]≈VERIFIED, [I]≈INFERRED, [A]≈PROVISIONAL). Deliberate, documented in 00 and each
  batch header; no unification needed.
- *Overview-vs-deep-dive accuracy after C10:* three real drifts existed, all corrected —
  the "NVS still loads" claim (ch06, ch11, glossary, C9b docs), the "setup() constructs"
  imprecision (ch06), and the closed hedges (ch10 ±1, ch11 CI contents).

---

## 2. Code-explained docs (Standard B)

Standard B checklist per doc: scope table · prerequisites · where-this-fits (§0/diagram) ·
line-by-line · C++ concepts on first appearance · embedded/RC concepts · tests/helpers/
assertions explained · test status · V/I/P labels · what tests prove/don't · hardware
notes · understanding questions · glossary/open-questions updates. **All 10 batch docs
have every element** (verified by heading scan + the readings this session). Deltas:

| File | Verdict | Notes |
|---|---|---|
| `01_foundations_pins_hal_failsafe.md` (C1) | **OK** | Reviewed 07-03 (2 fixes applied then). Full skeleton. |
| `02_outputs_commands_to_microseconds.md` (C2) | **REVIEWED 2026-07-05** | Review pass done. Tests re-run 10/10; all servo/ESC/LEDC arithmetic re-derived (no errors); all 10 test descriptions verified. **One factual fix:** the doc claimed main.cpp `static_assert`s the servo config — it does not (grep-confirmed); §1 corrected to the real enforcement path (tuning console per-set + tuning-build aggregate assert; gift build trusts the default). Added a C10-resolution note. Now `reviewed` in the progress table — matching C1/C3–C8. |
| `03_crsf_framing_and_channel_decoding.md` (C3) | **OK** | Reviewed 07-03 (1 fix). |
| `04_crsf_receiver_facade_and_frame_building.md` (C4) | **OK** | Reviewed 07-03 (1 fix) + C10 resolution note added 07-05. |
| `05_channels_mapping_and_arm_gate.md` (C5) | **OK** | Reviewed 07-03 (1 fix) + C10 resolution note. |
| `06_feel_gearbox_and_ers.md` (C6) | **OK** | Reviewed 07-03 (1 fix) + C10 resolution note. |
| `07_telemetry_sensors.md` (C7) | **OK** | Reviewed + narrow correction 07-03 + C10 resolution note. |
| `08_link2_outbound_protocol.md` (C8) | **OK** | Reviewed 07-03 (1 fix) + C10 resolution note. |
| `09a_settings_persistence.md` + concept notes | **OK** (unreviewed) | Written to the current best structure (structured close-out). Optional review pass later. |
| `09b_console_tuning_and_settings_store.md` + concept notes | **OK** (unreviewed; corrected) | Four C10 correction notes applied 07-05 (the gift-load-path claim). Optional review pass later. |
| `10_main_integration.md` + concept notes | **OK** (fresh) | Written 07-05 with the stricter source+build evidence labeling. Natural review moment: after the Wokwi first run (#35–39), which will test its PROVISIONAL composition claims. |

**Standard B cross-cutting checks:**
- *Early-vs-late detail gradient:* C1–C8 lack the structured close-out sections
  ("What X proves / does NOT prove / what waits for…") that 09a/09b/C10 have; their
  V/I/P summaries + cross-references cover the same ground in older form.
  **Recommendation: do NOT retrofit** — no factual gain, pure length growth (violates
  the no-bloat rule). Noted as accepted stylistic drift.
- *Concept teaching notes* exist only for 09a/09b/C10 (created on request). If you want
  the same for earlier batches, that's new content, not standardization → your call,
  deferred by default.
- *Filename consistency:* the C9 split note in `source_code_progress.md` pointed at a
  placeholder filename (`09b_console_and_tuning_hal.md`) — fixed to the real one.
- *Glossary/open-questions hygiene:* three missing glossary terms found and added
  (**Drive mode**, **PlatformIO**, **LDF**); open question **#44** was answered by C6 but
  never annotated — now closed; **#49** (gift-build tuning gap) was filed during C10.
  No other missing terms or questions found.

---

## 3. Patches applied this session (complete list)

1. `00_START_HERE.md` — support-files list (+`code_explained/`, progress/plan links);
   "later phase" convention bullet rewritten; 2026-07-05 status update added.
2. `README.md` — status pointer added (progress file + this audit).
3. `02_repository_map.md` — deep-dive pointer block after the module table.
4. `04_embedded_cpp_basics.md` — one cross-link sentence in the intro.
5. `06_control_firmware_architecture.md` — deep-dive map in §2; "deep dives come later"
   fixed; §3 static-init/attach correction + link to `10_main_integration.md`;
   "await the line-by-line pass" → confirmed-by-C10. (Plus the §2.8 NVS correction,
   applied earlier in the C10 session.)
6. `09_communication_protocols.md` — deep-dive pointer block.
7. `10_algorithms_state_machines_timing.md` — deep-dive pointer block; ±1 hedge resolved
   (#44).
8. `11_build_flash_debug_workflow.md` — §3 NVS caution (#49); §7 CI-contents update
   (+ tuning-env-not-in-CI note); understanding question 4 rewritten.
9. `glossary.md` — added **Drive mode**, **PlatformIO**, **LDF (Library Dependency
   Finder)**.
10. `open_questions.md` — #44 annotated ANSWERED (C6).
11. `source_code_progress.md` — C9b placeholder filename corrected.

(Earlier in the C10 session, and counted as part of this standardization state: the
NVS-loads corrections in ch05/ch06/glossary/C9b docs+notes, the C10-resolution notes at
the top of batch docs 04–08, and open questions #34b/#45/#46/#48/#49.)

## 4. Still needs major improvement (requires your approval — not done)

1. ~~**C2 review pass**~~ — **DONE 2026-07-05** (see §2 row). One factual fix applied
   (the servo `static_assert` claim); C2 is now `reviewed`. No items remain from this line.
2. *(Optional, lower value)* review passes for 09a/09b/C10 — 09a/09b are structurally
   strongest and were partially re-verified during C10; C10's natural review moment is
   the Wokwi first run. Not urgent.
3. *(Recommend against)* retrofitting structured close-outs / concept-notes companions
   onto C1–C8 — length without new facts.

## 5. Deferred until soundlight / ground-station batches

- Chapter **07** re-audit + its "awaits deep-dive" notes (atomic word bit layout, #43) →
  after **S2–S5**.
- Chapter **08** re-audit (+HUD precedence #47, preload.cjs details) → after **G1–G4**.
- Chapter **09**: the "third implementation" cross-links (JS decoder) → **G1**; link2
  receiver-side notes → **S1**.
- Chapter **11** §7: soundlight `ci.yml` diff → **S5**.
- Open questions #43, #46 (soundlight half), #47, #48-adjacent sim-run items (#35–39
  are hardware/Wokwi, not batch work).

## 6. Bottom line

**The control-firmware manual is internally consistent and ready to continue.** Every
chapter now agrees with the C1–C10 deep dives; every C10-resolved PROVISIONAL is
reflected where it was first claimed; the one factual error found anywhere ("gift build
still loads NVS tuning") is corrected at every occurrence and tracked as design question
#49; chapters and batches are cross-linked both ways. The one outstanding quality item —
the **C2 review pass** — is now **done** (2026-07-05; a servo-`static_assert` overclaim
was the one fix, and all C1–C10 batches are `reviewed`). Nothing blocks starting **S1**.
