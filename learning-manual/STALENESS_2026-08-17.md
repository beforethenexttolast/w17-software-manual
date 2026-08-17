# Manual Staleness Report — 2026-08-17

**A repair list — now with the repairs recorded.** Wave 1 (docs/manual-wave1) catalogued;
**wave 2 (docs/manual-wave2, same day) repaired**: every HIGH and MEDIUM finding below is
FIXED, LOW findings are fixed where their file was already open and explicitly deferred
otherwise — the per-claim disposition table sits right below the headline counts, and
each row names its commit. Findings text below the table is left as written (it is the
evidence trail); trust the table for current status. Dated snapshot — reconcile against
`../CURRENT_STATUS.md` before acting on it later.

**Method.** Every pre-wave manual file was walked against the source repos at the
mains current when the walk ran: `w17-control-fw` `94b3615`, `w17-soundlight-fw`
`5919685`, `w17-ground-station` `92cd894`, `w17-mapper` `w17-headtrack` @ `432a809`,
workspace `f0201c4` — plus the recorded owner decisions in `../W17_PRODUCT_VISION.md`
/ `../CURRENT_STATUS.md`. Suite counts quoted below are the 2026-08-16 audit's
(`../2026-08-16_vision_audit_report.md` §1: control 229 native, soundlight 94, GS 1185
vitest, mapper 137), which audited these same commits; they were not re-run here.

**Mid-wave supersession (2026-08-17, workspace `0542e29`) — read before using the
numbers.** While this report was being written, the post-reset merges landed:
**soundlight main → `1c19260`** (wave-3 board-2 features; 94 → **107** tests) and
**GS main → `abaddbd`** (giftee wave + two review fixes; **1257** tests; the unsigned
NSIS CI job now on main, GS pushed under the GS-only exception to run it).
Control-fw and mapper mains are unchanged. Consequence: former watch items **W1 and
W2 are LIVE staleness now** — folded into chapters 07/08/11/glossary below as S37/S38
and updated fix targets. Where a finding cites a soundlight/GS count, repair to the
post-merge values (control 229 / soundlight 107 / GS 1257 / mapper 137).
*(Superseded again by wave-2's own check: GS main had moved to `ca1cb86` — the
video-profile wave — and **1324**; control-fw main to `9f00f2e` (docs-only, 229). The
actual repairs used 229 / 107 / **1324** / 137. Two supersessions in one day is the
count-chasing lesson in miniature — hence every repaired count is as-of-dated or
replaced by "run the suite".)*

**Severity scale.** **HIGH** = misleads action or contradicts a recorded owner
decision / resolved defect. **MEDIUM** = concrete claim about current state that is
now false (counts, names, structure). **LOW** = dated-but-labeled, cosmetic, or a gap
rather than a falsehood.

**Headline counts: 21 files checked · 38 stale claims (6 HIGH / 19 MEDIUM / 13 LOW)
· 3 files fully clean · 3 remaining watch items (2 landed mid-wave).** (The files this
wave created — 14, 15, 16–22, this report — are excluded from their own audit.)

## Wave-2 disposition (2026-08-17, branch docs/manual-wave2)

**Outcome: 6/6 HIGH fixed · 19/19 MEDIUM fixed · LOW: 8 fixed, 4 deferred,
1 no-action-needed.** Baseline moved again mid-wave-2 — repairs were made against
**GS main `ca1cb86` (1324 tests — the video-profile wave merged after this report's
1257 figure)** and **control-fw main `9f00f2e` (the MCU-line fix S28 asked of a
control-fw session: done; docs-only, 229 unchanged)**; soundlight `1c19260` (107) and
mapper `432a809` (137) as stated above. Wave-2 commits: `d7acaf4` (#49 family),
`d383b91` (ch01), `866e773` (ch02), `c72245e` (ch07), `291c7e7` (ch08), `e50a697`
(00_START), `d13f6c0` (ch05/06), `1962803` (ch11), `12d8a09` (ch13), `3117839`
(glossary), `27fc16d` (campaign files).

| id | Status | Note |
|---|---|---|
| S1 | **FIXED** `e50a697` | six-repo table |
| S2 | **FIXED** `e50a697` | as-of counts + mapper step |
| S3 | **FIXED** `e50a697` | snapshot → pointer + dated changelog frame |
| S4 | **FIXED** `d7acaf4` | + the same claim repaired in ch06 §2.8, ch11 §3, glossary (report misses) |
| S5 | **FIXED** `e50a697` | historical verification counts kept, tagged "at the time" (a batch verified against *then-current* suites — retro-editing them would falsify the record); current counts live in the new Update 2026-08-17 block |
| S6 | **FIXED** `27fc16d` | paused-since line + ledger pointer |
| S7 | **FIXED** `d383b91` | all 5 spots + §5 paragraph |
| S8 | **FIXED** `d383b91` | iPhone row + mapper/5601/5602 arrows |
| S9 | **FIXED** `866e773` | new §6 (both suggested options blended: mapped one level deep + re-scoped intro) |
| S10 | **FIXED** `866e773` | 229 as-of |
| S11 | **FIXED** `866e773` | tree re-drawn at `ca1cb86`; 1324/63 files |
| S12 | **FIXED** `d13f6c0` | dated supersession note, Wokwi refs untouched |
| S13 | **FIXED** `d13f6c0` | toured-at-2026-07-03 note (no new docs — re-verified) |
| S14 | **FIXED** `d13f6c0` | 229 as-of |
| S15 | **FIXED** `d13f6c0` | §2.9 added now (short), deep-dive map row |
| S16 | **FIXED** `c72245e` | 107 as-of |
| S17 | **REPORT ERROR** | ch07 has no ":32 review pass pending" line (grep 2026-08-17); the phrase lives in 00_START_HERE + README — both dated in wave 2 (`e50a697`, `27fc16d`). Nothing to fix in ch07. |
| S18 | **FIXED** `291c7e7` | new §7 (setup flow) + §8 refresh (mDNS, banner, profiles); old §7 renumbered — no inbound refs existed |
| S19 | **FIXED** `291c7e7` | suite-level as-of 1324; W2/W3 honesty intact |
| S20 | **DEFERRED** | LOW in a file wave 2 didn't otherwise touch (ch09 verified current on its core claims); add the ch15 §4/§7 cross-ref on the next ch09 edit |
| S21 | **DEFERRED** | by the report's own advice — wait for the owner's `feat/gimbal-decay-center` merge decision (watch W3) |
| S22 | **FIXED** `1962803` | 229/107 as-of + trust-the-run note |
| S23 | **FIXED** `1962803` | 1324; **report correction: the NSIS build is a *step* inside `package-smoke`, not a third job** — ci.yml still has two jobs; described accurately |
| S24 | **FIXED** `1962803` | DevKit=[C] via ch13 evidence, MH-ET=[A] until first flash |
| S25 | **FIXED (pointer)** `1962803` | one-liner + ch15 §3 ref; the full §ch11 workflow section waits for the campaign, per the report's own fix |
| S26 | **DEFERRED** | LOW-only file (ch12) not otherwise edited in wave 2; date the sentence on next touch |
| S27 | **DEFERRED** | same file/rule; the forward pointer to the 2026-08-16 audit is still worth adding on next touch |
| S28 | **FIXED** `12d8a09` | note added; **the report's "citation still matches its source" aside went stale mid-wave-2** — control-fw `9f00f2e` moved the MCU line, so the [C] is re-anchored to the pre-`9f00f2e` revision |
| S29 | **FIXED** `3117839` | 1324 + real job/step shape (same correction as S23) |
| S30 | **FIXED** `3117839` | re-pointed at w17-mapper/ch15 |
| S31 | **FIXED** `3117839` | all 8 entries added; branch-only work labeled in-flight |
| S32 | **FIXED** `d7acaf4` | ANSWERED note with main.cpp:357 + CLAUDE.md invariant; #34b re-superseded note |
| S33 | **FIXED** `d7acaf4` | #58 narrowed to the GS-side deep-dives |
| S34 | **FIXED** `27fc16d` | paused-campaign entry; counts at *today's* mains (GS 1324, not the audited 1185/1257) |
| S35 | **FIXED** `27fc16d` | scope note + Repo-4 axes recorded; full section on resume |
| S36 | **VERIFIED-CURRENT** | re-checked 2026-08-17; accurate as-is, no action (as the report said) |
| S37 | **FIXED** `c72245e` | grace-window semantics + monitor-vs-renderer note + dated S4-blockquote update |
| S38 | **FIXED** `c72245e` | ignition halo, DRS tell (8th field), voice profiles; link2-v2 labeled in-flight |

**Wave-2 catches beyond this report** (same class as the findings, found while
repairing): the #49 stale claim also lived in **ch06 §2.8**, **ch11 §3 + question 4**,
and the **glossary W17_TUNING_CONSOLE entry** (all `d7acaf4`); **ch01 :145 "187 unit
tests"** (drift-1 instance, `d383b91`); ch02's module tables were missing
**`lib/reset_diag`**, the **`console_hal_esp32`/`settings_hal_esp32` split**, and
soundlight's **`audiodecision`/`audiostartup`**, and both `main.cpp` line counts had
drifted (`866e773`); the glossary **Breathe** entry carried the S37 semantics
(`3117839`).

## The four systematic drifts (each shows up in many chapters)

1. **Suite counts.** The manual's recurring 147 (control) / 40 (soundlight) /
   118 (GS) all predate a year of growth: audited at **229 / 94 / 1185**, and after
   the mid-wave merges **229 / 107 / 1257** — plus the mapper's 137 which the manual
   never counted at all. Every count is flagged per file below.
2. **"Three repositories."** Since the manual's frame was set, the Claude side gained
   `w17-mapper` (owned fork — now taught in chapter 15), `w17-design-system`, and
   `w17-3d-codex` (`../WORKSPACE_MAP.md`). Chapters 00/01/02 still teach a three-repo
   world and call the mapper "an external tool."
3. **The board decision.** Owner decision 2026-07-24 (`../CURRENT_STATUS.md` :570):
   the cassette controllers are **MH-ET Live D1-Mini ESP32 (USB-C)**; the DevKit V1
   clones the manual describes everywhere are **TEST/SPARE only**
   (`../HARDWARE_INVENTORY.md` §4/§E).
4. **The GS setup-flow redesign.** The ground station now boots into a five-step
   flow — GARAGE → PIT WALL → SEAT FIT → SETUP → GRID
   (`w17-ground-station/shared/setupSteps.mjs`; SETUP split out of SEAT FIT
   2026-07-20 per `w17-design-system/DESIGN_NOTES.md` §14) — plus hotspot lifecycle,
   the GRID checklist engine, mDNS HUD discovery (CB4), and W2 bridge finalization.
   Chapter 08 contains **zero** occurrences of any stage name.

## Per-file findings

Format: **id** · location · stale claim · severity · suggested fix.

### 00_START_HERE.md

- **S1** · :9–15 · "The three repositories" table — three-repo world (drift 2). **MEDIUM** · Rewrite as "the repositories" listing all Claude-side repos, one-liners each; point at ch15 for the mapper.
- **S2** · :74–81 · verify-your-environment block: "should report 147 and 40 passing"; no mapper step. **MEDIUM** · Update counts (229/94/1185 at the audited mains; re-run when editing), add `w17-mapper`: `go build ./... && go test ./...` (137).
- **S3** · :85–90 · "Project status snapshot (as of 2026-07-03)" incl. "Gift deadline: **2026-07-21**". **MEDIUM** · The deadline is long past and the vision (decision 18) sets sequence, not a date. Replace the snapshot with a one-line pointer to `../CURRENT_STATUS.md` + the vision doc.
- **S4** · :92–95 · "the delivered gift build does **not** load NVS-saved tuning (open question #49)". **HIGH** — now false: delivery `esp32dev` loads the validated blob via `settings::loadOrDefault` (`w17-control-fw/src/main.cpp:357`, the non-console branch; `w17-control-fw/CLAUDE.md` "Delivery vs tuning builds": "Loading validated NVS tuning happens in **every** build"). · Correct the note and close #49 (see S32).
- **S5** · :96–119 · the 2026-07-09 update block's counts (147/147, 40/40, 118/118). **MEDIUM** · Refresh counts; the A2-not-executed and W3-log-only statements in the same block are still true and should survive the edit.

### README.md

- **S6** · :4–10 · campaign status reads as current but is frozen at 2026-07-09 (G1–G4 done, "next G5a/G5b" — nothing has moved since; the audit calls the progress file stale). **LOW** · Add "campaign paused since 2026-07-09" honesty line; counts move with S34.

### 01_total_system_overview.md

- **S7** · :23, :37, :80, :152, :161 · the mapper is "**elrs-joystick-control** (external tool)". **HIGH** — since 2026-07-15 it is the **owned GPL fork `w17-mapper`** carrying W17 safety fixes and the head-intent receiver (`../WORKSPACE_MAP.md` mapper row; chapter 15). The "external tool" framing understates both ownership and safety relevance. · Rename in all five spots; add one paragraph + pointer to ch15.
- **S8** · §2 component table / §3 data-flow · no mapper node-graph stage, no iPhone HUD component, no head-intent (log-only) arrow. **MEDIUM** · Extend the diagram with the mapper box and a clearly-marked log-only 5602 branch; iPhone app itself stays Codex-attributed.

### 02_repository_map.md

- **S9** · :3 ("all three repos") and the whole document · the manual's *repository map* maps three of six Claude-side repos — `w17-mapper`, `w17-design-system`, `w17-3d-codex` absent. **HIGH** for this chapter's stated purpose. · Add sections (mapper: point at ch15 §2–§4 for anatomy; design-system: reference-only repo; 3d-codex: fabrication) or explicitly re-scope the chapter to "the three original repos" with a pointer to `../WORKSPACE_MAP.md`.
- **S10** · :98 · "**[C]** 147" native tests. **MEDIUM** · 229.
- **S11** · :161, :172–173 · "8 vitest suites, 118 tests" / "grew … to 118 (run this session: 118/118)". **MEDIUM** · Now **61 test files, 1185 tests** at `92cd894`; the tree sketch around :161 needs re-drawing against the current `test/` and `shared/` listing.

### 03_hardware_and_electronics_basics.md

- **Clean.** Physics/electronics teaching holds; no board-name or count claims found (checked for DevKit/WROOM/charging/battery claims). Nothing to repair.

### 04_embedded_cpp_basics.md

- **Clean.** Spot-checked all `lib/…` citations (`lib/gearbox`, `lib/ers`, `lib/config`, `lib/crsf`, `lib/link2`, `lib/failsafe`) — all match the current module layout. Timeless content otherwise.

### 05_control_firmware_documentation_explained.md

- **S12** · :365 · BOM tour: "**Brains/audio/light:** 3× ESP32 DevKit V1 (**one spare**…)". **MEDIUM** — superseded by the MH-ET decision (drift 3); the DevKits on hand are test/spare. · Add a dated supersession note in the chapter's own style (it already models this pattern for other decisions); Wokwi DevKit references (:850, :870–873) are simulation-context and stay.
- **S13** · whole chapter · tours `docs/` as of 2026-07-03; no *new* docs were added since (verified via git), but several toured docs were edited in place (link2 re-syncs; `CLAUDE.md` rewrite — already caveated in 00_START_HERE). **LOW** · One blanket "toured at revision X" note would end the ambiguity.

### 06_control_firmware_architecture.md

- **S14** · :176 · env table: native = "The 147 unit tests". **MEDIUM** · 229.
- **S15** · module walk · `lib/reset_diag` (boot-reset diagnostic) postdates the chapter and is unmentioned; the deep-dive map (:57–59) is otherwise complete. **LOW** · Add a short §2.x when refreshed.

### 07_soundlight_firmware_architecture.md

- **S16** · :227 · env table: "40 unit tests". **MEDIUM** · 107 (94 at the audited `5919685`; wave-3 merge `1c19260` added 13).
- **S17** · :32 · "review pass pending" for S1–S5. **LOW** — still true, which is itself the news (pending since 2026-07-06). · Keep, add the date.
- **S37** · :145–157 (and :65 "NeverConnected never…") · "**NeverConnected** instead shows a calm teal 'waiting' breathe" *forever*, "pinned by" test. **HIGH** — became false mid-wave: since `1c19260` NeverConnected gets a **5 s grace window, then escalates to an honest hazard** (audit low finding 9's fix, merged). The manual currently teaches a failure-indication semantics the firmware no longer has. · Rewrite the NeverConnected paragraphs + the pinned-test citation against the merged code.
- **S38** · lights list (:137–145) and synth sections · the wave-3 additions are absent: ignition starter-comet + crossfade-to-armed-teal, steady-green DRS tell on the rear-bar edge pixels (brake/hazard win), and the named voice profiles `v10()` (byte-pinned default) / `v6TurboHybrid()` (no runtime selector yet — link2 v2 mechanism decided but not built). **LOW** (gaps, not falsehoods) · Add when ch07 is refreshed; source: the wave-3 merge commit set on `w17-soundlight-fw` main.

### 08_ground_station_architecture.md

- **S18** · whole chapter · describes the pre-redesign app: **no setup flow at all** (zero hits for GARAGE/PIT WALL/SEAT FIT/SETUP/GRID — drift 4), no hotspot lifecycle, no GRID checklist engine, no mDNS discovery (CB4, `92cd894`), no HUD-discovery/W2-finalization story — and, since the mid-wave `abaddbd` merge, no low-battery HUD banner / plain-language GRID hints either. **HIGH** — a reader building a mental model of today's app gets 2026-07-09's app. · Substantial refresh: either new sections per setup step (sources: `shared/setupSteps.mjs`, `shared/checklist.mjs`, `main/HudDiscovery.js`, README §Quick tour) or an explicit "architecture as of 2026-07-09" re-scope plus a delta chapter. Coordinate with the G-campaign resumption (S34/S35) so chapter and deep-dives move together.
- **S19** · :167 · "implemented + unit-tested (118/118 vitest)". **MEDIUM** · 1257 (1185 at the audited `92cd894`); the surrounding W2/W3 honesty statements (real-device validation pending, W3 log-only) remain true and must survive.

### 09_communication_protocols.md

- **Verified current** on its core claims: the link2 field table (:130–140) matches `w17-control-fw/docs/link2_protocol.md` (11-byte payload, same rows) — **no drift**; CRSF telemetry types (0x08/0x02/0x21) match `CrsfFrame.hpp`. One gap:
- **S20** · producer side · the chapter explains CRSF byte format but predates the mapper story (who *produces* RC_CHANNELS_PACKED on the PC, endpoints, the plausibility band's counterpart). **LOW** · One cross-reference paragraph to ch15 §4/§7 closes it.

### 10_algorithms_state_machines_timing.md

- **Spot-checked clean** on failsafe/arm/ESC/battery/staleness claims (:47–:84, :125, :160–:163 verified against current sources).
- **S21** · gimbal failsafe · the chapter never states what pan/tilt do on failsafe; today's truth is deliberate hold-last (`w17-control-fw/src/main.cpp:580–584`), and vision decision 11 (decay-to-center) sits on the unmerged `feat/gimbal-decay-center`. **LOW** (gap, and a moving target — see W3) · Add the section only after the owner's merge decision.

### 11_build_flash_debug_workflow.md

- **S22** · :31 · "expect 147 tests" (and the soundlight/GS expectations in the same §2 block). **MEDIUM** · 229/107/1257.
- **S23** · :123, :171 · "118 tests as of 2026-07-09" / CI "the 118 vitest tests… two jobs". **MEDIUM** · 1257; and since `abaddbd` (mid-wave) the GS workflow gained a **third job — the unsigned NSIS installer build** — so the "two jobs" structure claim is stale too; describe test + package-smoke + NSIS.
- **S24** · :58–59, :200 · flashing notes assume "the physical DevKit V1 boards" ([A]). **MEDIUM** — cassette boards are MH-ET (drift 3); ch13's evidence retired the [A] for DevKit clones only. · Re-scope: DevKit = test/spare (evidence exists), MH-ET = the delivery target, flash behavior **[A]** until first MH-ET flash (rebuild stub 20 tracks this).
- **S25** · coverage · no mapper (Go) build/test/run workflow. **LOW** · ch15 §3 carries the basics; add a §here when the mapper enters the campaign (S35).

### 12_the_skeptical_audit_and_f1_f4_fixes.md

- **Clean as history** — its counts (:3, :62, :176, :232–233, :333) are explicitly at-audit-time and stay correct as written.
- **S26** · :123 · "the unpinned platform *currently* resolves to 7.0.1/core 2.0.17" — "currently" = 2026-07-08. **LOW** · Date the sentence; re-verify resolution when next touched.
- **S27** · framing · a reader can leave believing F1–F4 is the latest audit; the 2026-08-16 vision audit (18 agents, 6 confirmed defects — all in *other* repos/docs than F1–F4 touched) now exists. **LOW** · Add a forward pointer (`../2026-08-16_vision_audit_report.md`).

### 13_bare_board_smoke_test.md (+ evidence file)

- **S28** · :51–52 · "The project is designed around the **ESP32-WROOM-32 DevKit V1** (**[C]** `w17-control-fw/CLAUDE.md`…)". **MEDIUM** — the citation still matches its source, but the workspace-level truth moved (drift 3): the smoke-tested DevKit clones are the test/spare boards, not the cassette controllers. · Add a dated note; keep the [C] (it was true of its source). *Found in passing, outside manual scope:* `w17-control-fw/CLAUDE.md` ("MCU: ESP32-WROOM-32 DevKit V1") itself now contradicts the recorded owner decision — a one-line repair for a **control-fw** session, not a manual session.
- **13_bare_board_smoke_test_evidence.md** — **clean**: dated evidence record; exempt by design.

### glossary.md

- **S29** · :91 · GS "ci.yml has two [jobs]: `test` (the 118 vitest tests…)". **MEDIUM** · 1257, and **three jobs** since the mid-wave `abaddbd` merge (test, package-smoke, NSIS installer).
- **S30** · :108 · "…elrs-joystick-control drives the…" — external-tool framing (drift 2). **MEDIUM** · Re-point at `w17-mapper`/ch15.
- **S31** · coverage · no entries for: w17-mapper, node graph, plausibility band, head intent, FIRST_ACTIVE, ACTIVE_LOG_ONLY, GCS box, MH-ET D1-Mini. **LOW** · Add alongside a ch15 vocabulary pass.

### open_questions.md

- **S32** · :97–105 + :207–212 (question **#49**) · "the plain `esp32dev` build has **no load path at all**" — **HIGH**: resolved in source since; delivery loads the validated blob (`main.cpp:357`; CLAUDE.md invariant, cf. S4). The question's premise and its (a)/(b)/(c) remedies are moot. · Mark #49 ANSWERED with the citation, noting it was true when written (C10, 2026-07-05).
- **S33** · #58 (iPhone-bridge chapter deferral) · still formally open, but chapter 15 now teaches the head-intent half of the bridge story; only G5a/G5b (GS bridge code deep-dive) remain deferred. **LOW** · Narrow #58's wording accordingly.

### source_code_progress.md

- **S34** · header + "Last updated: 2026-07-09" block · presents 118/118 and the G-campaign as the live frontier; no mapper repo exists anywhere in the campaign. **MEDIUM** · Add a dated entry: campaign paused 2026-07-09; counts at the audited mains 229/94/1185/137; decision needed on a Repo-4 (`w17-mapper`) batch series before G5a/G5b or after (audit decision-17 row expects a "mapper track").

### source_code_explanation_plan.md

- **S35** · whole file · inventories Repos 1–3 only; `w17-mapper` (~the fourth code repo, GPL fork, Go) has no batch plan. **MEDIUM** · Add a Repo-4 section when the campaign resumes — natural batch axes: `pkg/devices`+`pkg/config` nodes / eval+send loops / `pkg/headintent`+server stream / `cmd`+webapp. G5a/G5b definitions (:104–105) are still valid as written.

### code_explained/README.md

- **S36** · layout section · accurate today (G1–G4 "so far", G5a/G5b pending); will need a `mapper/` folder line when Repo 4 starts. **LOW** · No action yet.

## Watch items — NOT stale today; they flip when review branches merge

| # | Chapter(s) affected | Becomes stale when… | What changes |
|---|---|---|---|
| ~~W1~~ | ~~07~~ | **LANDED mid-wave** (`1c19260`, 2026-08-17) | folded into findings S16/S37/S38 above |
| ~~W2~~ | ~~08, 11, glossary~~ | **LANDED mid-wave** (`abaddbd`, 2026-08-17; tests 1257, not the branch-time 1255) | folded into S18/S19/S23/S29 above |
| W3 | 10 (S21), 06 | `w17-control-fw` `feat/gimbal-decay-center` merges (awaits the owner's personal diff review) | pan/tilt failsafe: hold-last → decay-to-center (2000 ms, NVS-tunable); 229 → 253; Settings blob v1→v2 |
| W4 | 15 (already branch-aware by construction) | `w17-mapper` `w17-audit-wave1` merges (same personal-review gate) | ch15 §6/§11 "unmerged" wording flips; defects 2/4 rows close |
| W5 | 09, 07 | control-fw lands the decided link2 **v2** field (sound profile + volume — packet §7½.4) | link2 tables gain a field; both repos' protocol copies re-sync |

**Merge-order caveat, proven mid-wave:** per the owner's pre-reset answers (packet
§7½.1), soundlight and GS merged first — W1/W2 flipped while this report was being
written — and control-fw/mapper still await the owner's personal diff review. Re-check
branch state before acting on any remaining watch item.
