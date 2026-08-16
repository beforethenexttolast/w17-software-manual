# Manual Staleness Report — 2026-08-17

**A repair list, not repairs.** This wave (docs/manual-wave1) deliberately changed no
existing chapter beyond indexing its own new content; every finding below is *recorded
for a later refresh pass*, per the 2026-08-16 vision audit (decision-17 row: "refresh
vs current code"). Dated snapshot — reconcile against `../CURRENT_STATUS.md` before
acting on it later.

**Method.** Every pre-wave manual file was walked against the source repos at their
current mains: `w17-control-fw` `94b3615`, `w17-soundlight-fw` `5919685`,
`w17-ground-station` `92cd894`, `w17-mapper` `w17-headtrack` @ `432a809`, workspace
`f0201c4` — plus the recorded owner decisions in `../W17_PRODUCT_VISION.md` /
`../CURRENT_STATUS.md`. Suite counts quoted below are the 2026-08-16 audit's
(`../2026-08-16_vision_audit_report.md` §1: control 229 native, soundlight 94, GS 1185
vitest, mapper 137), which audited these same commits; they were not re-run here.

**Severity scale.** **HIGH** = misleads action or contradicts a recorded owner
decision / resolved defect. **MEDIUM** = concrete claim about current state that is
now false (counts, names, structure). **LOW** = dated-but-labeled, cosmetic, or a gap
rather than a falsehood.

**Headline counts: 21 files checked · 36 stale claims (5 HIGH / 19 MEDIUM / 12 LOW)
· 3 files fully clean · 5 watch items.** (The files this wave created — 14, 15, 16–22,
this report — are excluded from their own audit.)

## The four systematic drifts (each shows up in many chapters)

1. **Suite counts.** The manual's recurring 147 (control) / 40 (soundlight) /
   118 (GS) all predate a year of growth: **229 / 94 / 1185**, plus the mapper's 137
   which the manual never counted at all. Every count is flagged per file below.
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

- **S16** · :227 · env table: "40 unit tests". **MEDIUM** · 94.
- **S17** · :32 · "review pass pending" for S1–S5. **LOW** — still true, which is itself the news (pending since 2026-07-06). · Keep, add the date.
- *(NeverConnected calm-teal at :145–157 is **currently accurate** on main — see watch item W1 before "fixing" it.)*

### 08_ground_station_architecture.md

- **S18** · whole chapter · describes the pre-redesign app: **no setup flow at all** (zero hits for GARAGE/PIT WALL/SEAT FIT/SETUP/GRID — drift 4), no hotspot lifecycle, no GRID checklist engine, no mDNS discovery (CB4, `92cd894`), no HUD-discovery/W2-finalization story. **HIGH** — a reader building a mental model of today's app gets 2026-07-09's app. · Substantial refresh: either new sections per setup step (sources: `shared/setupSteps.mjs`, `shared/checklist.mjs`, `main/HudDiscovery.js`, README §Quick tour) or an explicit "architecture as of 2026-07-09" re-scope plus a delta chapter. Coordinate with the G-campaign resumption (S34/S35) so chapter and deep-dives move together.
- **S19** · :167 · "implemented + unit-tested (118/118 vitest)". **MEDIUM** · 1185; the surrounding W2/W3 honesty statements (real-device validation pending, W3 log-only) remain true and must survive.

### 09_communication_protocols.md

- **Verified current** on its core claims: the link2 field table (:130–140) matches `w17-control-fw/docs/link2_protocol.md` (11-byte payload, same rows) — **no drift**; CRSF telemetry types (0x08/0x02/0x21) match `CrsfFrame.hpp`. One gap:
- **S20** · producer side · the chapter explains CRSF byte format but predates the mapper story (who *produces* RC_CHANNELS_PACKED on the PC, endpoints, the plausibility band's counterpart). **LOW** · One cross-reference paragraph to ch15 §4/§7 closes it.

### 10_algorithms_state_machines_timing.md

- **Spot-checked clean** on failsafe/arm/ESC/battery/staleness claims (:47–:84, :125, :160–:163 verified against current sources).
- **S21** · gimbal failsafe · the chapter never states what pan/tilt do on failsafe; today's truth is deliberate hold-last (`w17-control-fw/src/main.cpp:580–584`), and vision decision 11 (decay-to-center) sits on the unmerged `feat/gimbal-decay-center`. **LOW** (gap, and a moving target — see W3) · Add the section only after the owner's merge decision.

### 11_build_flash_debug_workflow.md

- **S22** · :31 · "expect 147 tests" (and the soundlight/GS expectations in the same §2 block). **MEDIUM** · 229/94/1185.
- **S23** · :123, :171 · "118 tests as of 2026-07-09" / CI "the 118 vitest tests". **MEDIUM** · 1185; CI job *structure* on GS main (test + Windows package-smoke) is still as described.
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

- **S29** · :91 · GS "ci.yml has two [jobs]: `test` (the 118 vitest tests…)". **MEDIUM** · 1185; jobs still two on main (NSIS job exists only on the unmerged wave-2a branch — W2).
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
| W1 | 07 (NeverConnected :145–157; lights list; synth) | `w17-soundlight-fw` `feat/audit-wave3-board2` merges | calm-teal-forever → 5 s grace then hazard; + ignition animation, DRS tell, named `v10()`/`v6TurboHybrid()` profiles; 94 → 107 tests |
| W2 | 08, 11, glossary :91 | `w17-ground-station` `feat/audit-wave2a-giftee` merges | low-battery HUD banner, plain-language GRID hints, NSIS CI job; 1185 → 1255 |
| W3 | 10 (S21), 06 | `w17-control-fw` `feat/gimbal-decay-center` merges | pan/tilt failsafe: hold-last → decay-to-center (2000 ms, NVS-tunable); 229 → 253; Settings blob v1→v2 |
| W4 | 15 (already branch-aware by construction) | `w17-mapper` `w17-audit-wave1` merges | ch15 §6/§11 "unmerged" wording flips; defects 2/4 rows close |
| W5 | 09, 07 | control-fw lands the decided link2 **v2** field (sound profile + volume — packet §7½.4) | link2 tables gain a field; both repos' protocol copies re-sync |

**Merge-order caveat:** per the owner's pre-reset answers (packet §7½.1), soundlight
and GS branches may merge before control-fw/mapper ones — so W1/W2 can flip while
W3/W4 stay pending. Re-check branch state before acting on any watch item.
