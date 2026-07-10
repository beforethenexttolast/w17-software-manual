# Manual Standardization Audit

> **Latest pass: 2026-07-09 — see §7** (post-S5, post-audit-F1–F4 standardization
> sweep; §§1–6 below are the 2026-07-05 after-C10 audit, kept as the dated record —
> read their verdicts as "as of C10").

## After C10 (2026-07-05)

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

## 6. Bottom line (as of 2026-07-05)

**The control-firmware manual is internally consistent and ready to continue.** Every
chapter now agrees with the C1–C10 deep dives; every C10-resolved PROVISIONAL is
reflected where it was first claimed; the one factual error found anywhere ("gift build
still loads NVS tuning") is corrected at every occurrence and tracked as design question
#49; chapters and batches are cross-linked both ways. The one outstanding quality item —
the **C2 review pass** — is now **done** (2026-07-05; a servo-`static_assert` overclaim
was the one fix, and all C1–C10 batches are `reviewed`). Nothing blocks starting **S1**.
*(S1–S5 have since been completed — see §7.)*

---

## 7. Standardization pass — 2026-07-09 (post-S5, post-audit-F1–F4)

Context since §§1–6: the soundlight explanation phase completed (S1–S5, 2026-07-06);
the source repos then received the **skeptical-audit fix round F1–F4** (2026-07-07/08),
iPhone-bridge work **W1–W3** (ground station), a **rewritten `w17-control-fw/CLAUDE.md`**
(2026-07-09), and hardware-gate documentation (A2 checklist committed, NOT executed;
Phase B blocked — `../CURRENT_STATUS.md`). This pass re-checked the manual against the
current repos and applied bounded consistency patches.

### 7.1 Facts re-verified against the repos this pass

- The two firmware `ci.yml` files **differ** (diff run 2026-07-09): control builds
  `esp32dev_tuning` (F1/R17a); both carry a link2 contract-drift-guard job (F3).
- The `lib/link2` copy (4 shared files) **and** `docs/link2_protocol.md` remain
  **identical** across the two firmware repos post-F4 (md5 compared) — the do-not-fork
  discipline holds; S1's cross-repo conclusions stand.
- Control native tests still **147** (RUN_TEST count; F4's commit records 147/147 pass).
- Ground station: **118 vitest tests / 8 suites** (was 20/7) and 7 new source files
  from F2/F3 + W1–W3. `w17-ground-station` inventory in the plan/progress files marked
  stale (re-inventory gate before G1).
- Ch09's link2 payload table already matches F4's doc alignment (gear 1…4;
  TRAINING/RACE/ERS labels) — no drift there.

### 7.2 Patches applied this pass (2026-07-09)

1. `00_START_HERE.md` — S1–S5 marked complete in both status bullets; 2026-07-09 status
   update (audit F1–F4 + W1–W3 exist; audit/iPhone manual chapters deliberately not yet
   written; A2 committed-not-executed / Phase B blocked; source/build/test ≠ hardware
   proof); global citation caveat for the rewritten control `CLAUDE.md`.
2. `02_repository_map.md` — soundlight deep-dive pointer block added (parity with the
   control section's); ground-station tree annotated with the 2026-07-09 inventory note
   (new F2/F3+W files, 118 tests, W3 log-only + validation pending).
3. `05_control_firmware_documentation_explained.md` — §10 update note: the founding
   brief was rewritten as a maintenance guide; §N citations refer to the pre-rewrite
   revision.
4. `07_soundlight_firmware_architecture.md` — §7 update note: ci.yml byte-identity
   ended by F1/F3 (link2 copy still identical).
5. `10_algorithms_state_machines_timing.md` — §6 recap now carries the two standing
   warnings inline: silence = `volume 0` (not rpm 0), and the dead-man branch has
   **never executed anywhere** (bench #57).
6. `11_build_flash_debug_workflow.md` — ground-station test count 20 → 118 (dated).
7. `glossary.md` — added **HUD link states** (sim/live/LINK LOST/TELEMETRY LOST), the
   audit-F2 concept ch08 already teaches.
8. `open_questions.md` — #46 post-closure drift note; new **#58** (iPhone-bridge W1–W3
   real-device validation PENDING; W3 log-only; treat as implemented+unit-tested, not
   validated).
9. `source_code_progress.md` — repo-drift note at top (ci.yml divergence; F4-touched
   files; CLAUDE.md rewrite; link2 copies still identical; G inventory stale; statuses
   unchanged).
10. `source_code_explanation_plan.md` — G-repo stale-inventory note (re-verify before
    G1; new files need batch placement).
11. `code_explained/soundlight_fw/05_soundlight_main_integration.md` — post-batch drift
    note at top (byte-identical ci.yml claim historical; protocol conclusions stand).

### 7.3 Standing warnings spot-checked (all still present where relevant)

- Silence means `volume = 0`, not `rpm = 0` — ch07 §6, glossary (Volume map), S3/S5
  docs, now also ch10 §6.
- The soundlight dead-man has **never executed** in any test — ch07 §6, glossary
  (Dead-man), S5 doc, #57, now also ch10 §6.
- 40/40 green does **not** cover `main.cpp` dead-man runtime behavior
  (`test_build_src = no`) — ch07 §1/§6, S5 doc, progress file.
- Soundlight bench wedge-test still required — #57(a).
- Source/build/test confidence ≠ hardware proof — 00 status, ch03/ch11 [A] blocks,
  hardware-gate wording (A2 not executed, Phase B blocked).
- Audit F1–F4 fixes exist but hardware-validation gates remain separate — 00 status,
  `CURRENT_STATUS.md`.
- iPhone bridge W3 pending unless proven — #58, ch02 note.

### 7.4 Remaining issues (recorded, NOT fixed this pass)

1. **~37 "`CLAUDE.md` §N" citations across 16 files** (ch01/02/03/04/05/10/11 + eight
   control-fw batch docs) now point at section numbers that no longer exist in the
   rewritten file. Mitigated by the global caveat in `00_START_HERE.md` and notes in
   ch05/progress; a per-citation re-anchor (or "(pre-rewrite)" suffix) is a follow-up
   decision — recommend leaving as-is, since the underlying facts were code-verified in
   C1–C10 and the old revision is in git history.
2. **S1–S5 review pass** still pending (C-batch parity) — unchanged from the S5 close.
3. ~~**Skeptical-audit (F1–F4) manual chapter not written**~~ — **DONE 2026-07-09**:
   `12_the_skeptical_audit_and_f1_f4_fixes.md` (new chapter 12), written from the
   `w17-control-fw/project-review/` corpus (read in full this session). The scattered per-fix references
   (ch08 §3 R01/F2, ch11 §7 F1/R02 + F1/R17a + F3/R06, glossary R19, open q #46) now
   cross-link to it; glossary gained *Skeptical audit*, *Risk register*, *Validation
   gate*, *Drift guard*; 00's reading order includes chapter 12.
4. **iPhone-bridge (W1–W3) manual chapter not written** — out of scope; gated on #58's
   validation status staying honestly "pending".
5. ~~**G1–G4 re-inventory** before the ground-station campaign starts (§7.1)~~ —
   **DONE 2026-07-09** (see §8): inventory re-verified file-by-file, plan rewritten to
   G1–G5b, and batch G1 written.
6. Batch-doc line-number references into F4-touched files (control `main.cpp`,
   `ChannelDecoder.hpp`, `Link2Frame.hpp`) may be off by a few lines — harmless;
   re-check opportunistically during the next review pass, not worth a sweep.
7. Older batch docs (C1–C8) still use the pre-close-out structure — accepted stylistic
   drift (unchanged verdict from §2).

### 7.5 Bottom line (2026-07-09)

The manual is consistent with the repos as of audit-F4 + W3: no file claims hardware
proof, W3 completion, or ci.yml identity anymore; the S-batch campaign is fully
reflected; unfinished work (S review pass, audit + iPhone chapters, G re-inventory) is
tracked here and in `open_questions.md` rather than implied done. Next recommended
batch: **G1 after re-inventory**, or the **audit F1–F4 chapter** if narrative freshness
matters more than campaign order. *(Update, later on 2026-07-09: the audit chapter was
chosen and written — see §7.4 item 3. Remaining from that list: S1–S5 review pass,
iPhone-bridge chapter, G1–G4 re-inventory. Next recommended batch: **G1 after
re-inventory**, with the iPhone-bridge chapter gated on #58's validation status.)*

---

## 8. G0 re-inventory + G1 — 2026-07-09 (same day, later session)

Closed §7.4 item 5. What ran:

- **G0 re-inventory:** the current `w17-ground-station` tree (`dab3039`) verified
  file-by-file (`wc -l`); the old plan table matched the 2026-07-03 tree (`b5ed803`)
  *exactly*, so all drift = audit F2/F3/F4 + iPhone-bridge W1–W3. 13 new files, 10
  grown files, suite 20→**118 vitest tests / 8 files** (run: 118/118 PASSED). One
  original-inventory omission found and fixed: the ground station's `ci.yml` existed
  since the initial commit but was never batched — now in G4 (the firmware repos'
  ci.ymls were batched in C10/S5, so this restores parity). Repo now ≈3,770
  project-authored lines (was ~1,770).
- **Plan rewritten** (Repo-3 section): batches now **G1–G5b**; the iPhone-bridge files
  form G5a (W2 telemetry-out) + G5b (W3 LOG-ONLY head-tracking + the noControlPath
  guards), deliberately last and gated on the deferred iPhone-bridge chapter decision
  (#58). G1 absorbed `linkState.mjs` (audit F2) + `crsf_golden.json` (audit F3) + the
  linkState suite.
- **G1 written:** `code_explained/ground_station/01_shared_pure_core.md` (the manual's
  first JS batch; opens with the JS-for-C++-readers primer the plan promised). G1
  suites 32/32; golden-fixture values cross-checked against the firmware builder tests
  (read-only) and the battery CRC re-computed independently. New open question **#59**
  (2 doc-consistency notes).
- **Consistency patches:** ch02 §4 tree + inventory note refreshed (+deep-dive
  pointer); ch08 gained the G1 pointer and a new §7 recording the bridge's existence
  with the #58 honesty gates; ch11 §7 now describes the ground station's own CI
  (incl. F2's Windows package-smoke); progress file G-table rewritten (G1 `explained`,
  the rest `not started`); glossary +3 (CommonJS/ESM, JSDoc, Regular expression);
  `code_explained/README.md` layout line updated; `README.md` status line updated;
  `00_START_HERE.md` (support-files list, conventions bullet, 2026-07-09 status update)
  now carries the G0/G1 milestone — this was the batch's interrupted last step,
  completed in the recovery session.
- **Standing warnings kept intact:** no hardware claims anywhere (118 green vitest =
  source/test evidence only); W3 stays *implemented + unit-tested, NOT real-device
  validated* (#58); ELRS LQ→0 behavior remains bench-pending (#27) even though the
  ground code is built around it.

Remaining from §7.4: S1–S5 review pass (item 2), iPhone-bridge chapter (item 4),
CLAUDE.md §N citations (item 1, recommend leave), C1–C8 style drift (item 7, accepted).
**Next recommended batch: G2 (main process + telemetry sources).** *(Done — §9.)*

---

## 9. G2 — 2026-07-09 (later session, same day as §8)

- **G2 written:** `code_explained/ground_station/02_main_process_and_telemetry_sources.md`
  — the Electron main process (`main/main.js`, `preload.cjs`, `mediamtx.js`,
  `CrsfSerialSource.js`), the replay source, and `test/replay.test.js`. Verified:
  replay suite 7/7, full suite 118/118, tree unchanged at `dab3039`, all six line
  counts re-checked against the plan's table (exact). The session brief's `src/`
  paths were a slip (real layout: `main/` + `shared/`) — noted in the batch doc §0,
  no plan change needed (the plan's table already had the right paths).
- **Full Standard-B skeleton present** (scope/prereqs/where-this-fits/line-by-line/
  concepts-on-first-use/tests/what-proves-what/labels/questions), with one structural
  emphasis new to this batch: §8 explicitly tables the **untested-I/O-shell** parity
  across all three repos, because G2 is the first batch whose VERIFIEDs are mostly
  source+doc-verified rather than test-pinned — the label section says so in as many
  words.
- **Consistency patches:** ch02 (deep-dive pointer + the "what preload exposes awaits
  the code pass" note closed); ch08 (deep-dive pointer; Inferred block updated — §1
  anatomy now code-confirmed, #47 input half settled); ch11 §6 (how the env knobs +
  graceful degradation actually work, one paragraph); `code_explained/README.md`
  layout line; progress file (new Last-updated block, G2 batch-log entry, G-table
  rows → explained); plan (G2 row → DONE); `README.md` + `00_START_HERE.md` status
  lines; glossary +5 (Preload/contextBridge, Child process/spawn, Promise/async-await,
  Environment variable, Keyframe/lerp); open questions: **#47 partially answered**
  (input half), new **#60** (macOS activate re-registration [I]; import-comment nit;
  supervisor no-backoff observation).
- **Standing warnings kept intact:** no hardware claims (7/7 + 118/118 vitest =
  source/test evidence about a laptop, §8 of the batch doc spells out that the four
  `main/` files have no tests at all); iPhone bridge still implemented + unit-tested,
  **NOT real-device validated** (#58); W3 LOG-ONLY; camera codec/serial sharing/ELRS
  LQ behavior remain bench (#25/#27/#28).

Remaining from §7.4 (unchanged): S1–S5 review pass, iPhone-bridge chapter (gated on
#58 + the chapter-vs-batch-doc decision), CLAUDE.md §N citations (leave), C1–C8 style
drift (accepted). **Next recommended batch: G3 (the renderer — HUD + video), which
closes #47's remaining half.** *(Done — §10.)*

---

## 10. G3 — 2026-07-09 (later session, same day as §§8–9)

- **G3 written:** `code_explained/ground_station/03_renderer_hud_and_whep.md` — the
  renderer (`renderer/index.html`, `hud.css`, `hud.js`, `whep.js`; 618 lines).
  Verified: full suite 118/118 (renderer files have **no** unit tests of their own —
  the batch doc's §9 makes the coverage asymmetry explicit: `hud.js` is the repo's
  third untested shell but *not* thin; the precedence logic is source-verified only,
  with linkState's 9 G1 tests + the feel-constants guard as the only test-backed
  pieces). Tree unchanged at `dab3039`; line counts re-checked against the plan's
  table (exact).
- **Full Standard-B skeleton present** (scope/prereqs/where-this-fits/line-by-line/
  concepts-on-first-use/tests/what-proves-what/labels/questions), with a browser
  primer (part 3: DOM, events, Gamepad API, requestAnimationFrame, CSP, WebRTC/SDP)
  continuing G1/G2's primer numbering.
- **Open question #47 CLOSED** (renderer half): the per-widget/per-field precedence
  table (G3 §6.2); F2's four-state display and F4's gear/label alignment located in
  the shipped code; the command mirror explained with the safety framing intact.
- **Consistency patches:** ch02 + ch08 deep-dive pointers extended to G3; ch08's
  Inferred block updated (#47 closed); **one real drift fixed** — ch09 §3's
  reliability table still described the *pre-F2* HUD ("falls back to simulation after
  1 s") → corrected to the hold-dimmed four-state model; ch09's deep-dive pointer now
  names G1/G3; `code_explained/README.md` layout line; progress file (new
  Last-updated block, G3 batch-log entry, 4 renderer rows → explained); plan (G3 row
  → DONE); `README.md` + `00_START_HERE.md` status lines; glossary +7 (Command
  mirror, CSP, DOM, Event listener, Gamepad API, requestAnimationFrame, SDP
  offer/answer) + WHEP cross-link; open questions: #47 closure note, new **#61**
  (5 display-layer observations, incl. the git-verified demo-DRS dead branch left
  behind by F4's 8→4 gear cut).
- **Standing warnings kept intact:** no hardware claims (118 green vitest say nothing
  about video/camera/serial/radio — #25/#27/#28 all bench); the command mirror is a
  display mirror, not control, and not end-to-end proof; iPhone bridge stays
  implemented + unit-tested, **NOT real-device validated** (#58); W3 LOG-ONLY (the
  renderer verifiably imports nothing from it — the noControlPath module-graph scan).

Remaining from §7.4 (unchanged): S1–S5 review pass, iPhone-bridge chapter (gated on
#58 + the chapter-vs-batch-doc decision), CLAUDE.md §N citations (leave), C1–C8 style
drift (accepted). **Next recommended batch: G4 (scripts + packaging + CI) — the last
non-bridge batch, completing the viewer-app story before the G5a/G5b gate decision.**

## 11. G4 — 2026-07-09 (later session, same day as §§8–10)

- **G4 written:** `code_explained/ground_station/04_scripts_packaging_and_ci.md` — the
  deployment story: `package.json`, `scripts/run.js`, `scripts/ensure-electron.js`,
  `scripts/fetch-mediamtx.js`, `electron-builder.yml`, `mediamtx/mediamtx.yml`,
  `.github/workflows/ci.yml` (303 lines of source/config across 7 files). This is the
  **last non-bridge ground-station batch** — G1–G4 now tell the complete viewer-app arc
  (shared core → main process → renderer → build/package/CI). Verified: full suite
  `npx vitest run` → **118/118 PASSED**, which reproduces CI's own `test` job (not its
  packaging job). Tree unchanged at `dab3039`; all seven G4 line counts re-checked
  against the plan's table (exact).
- **Full Standard-B skeleton present** (scope/prereqs/where-this-fits/tooling primer/
  line-by-line/concepts-on-first-use/what-CI-proves/coverage line/labels/questions),
  with a tooling primer (npm, packaging, CI) continuing the batch-primer convention.
- **Coverage honesty is the batch's spine:** its §9 makes explicit that **none of the
  seven G4 files is unit-tested** — they are scripts/config, verified by *running* the
  tools (CI's packaging job + a human's `npm run setup`/`start`/`build`), none of which
  this manual has done. So G4 is the widest source/test-verified-but-NOT-runtime-verified
  gap in the campaign; every VERIFIED label is source-read + cross-check, never
  test-pinned. §8.4/§10 keep packaging/download/launch/video all PROVISIONAL → real run /
  bench.
- **Consistency patches:** ch02 + ch08 deep-dive pointers extended to G4; ch11 §7's CI
  overview now cross-links the line-by-line read (G4 §8); `code_explained/README.md`
  layout line (`01_…`–`04_…`); progress file (new Last-updated block, G3 block demoted,
  G4 batch-log entry, 7 G4 rows → explained); plan (G4 row → DONE); `README.md` +
  `00_START_HERE.md` status lines; glossary additions; open questions: new **#62**.
- **New open question #62** (small, works-as-designed): `ensure-electron.js` extracts
  Electron from the **download cache** — it does **not** download; a fully script-blocked
  install where the binary was never fetched needs a manual `node
  node_modules/electron/install.js` first. Documented in the script's own error message.
- **Standing warnings kept intact:** no hardware/video/serial/device claims — **"CI
  green" ≠ "the ground station works"**, it = "the logic is sound and the box packs"
  (#25/#27/#28 all bench); packaging assembles files, it does not run the UI or the
  installer (the smoke job is `--dir`, no NSIS/sign/publish); iPhone bridge stays
  implemented + unit-tested, **NOT real-device validated** (#58); W3 LOG-ONLY (the
  noControlPath tests that enforce it run inside the 118 but are a structural guarantee,
  not a device test).

Remaining from §7.4 (unchanged): S1–S5 review pass, iPhone-bridge chapter + batches
G5a/G5b (gated on #58 + the chapter-vs-batch-doc decision), CLAUDE.md §N citations
(leave), C1–C8 style drift (accepted). **Next recommended batch: G5a (iPhone bridge W2,
telemetry-out) — gated on the #58 chapter-vs-batch-doc decision; must not claim W3
real-device validation.**
