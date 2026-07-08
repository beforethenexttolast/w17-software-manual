> # HISTORICAL AUDIT SNAPSHOT — NOT CANONICAL
>
> This is the read-only instruction/workspace-structure audit performed on **2026-07-09**.
> It is **rationale and context only** — a record of why the workspace docs are shaped the
> way they are. It is **not** a source of truth and **not** required reading for normal
> Claude Code sessions.
>
> Current truth after the cleanup lives in:
> - `projects/CLAUDE.md` (shared workspace guidance)
> - `projects/WORKSPACE_MAP.md` (stable map + canonical-vs-copy registry)
> - `projects/CURRENT_STATUS.md` (checkpoints, gates, pending validations — the only place
>   canonical commit hashes belong)
> - repo-local `CLAUDE.md` / `AGENTS.md` files
>
> Any hashes quoted below are either (a) evidence of a *stale* hash found inside another doc
> at audit time, or (b) illustrative — the authoritative checkpoint registry is
> `CURRENT_STATUS.md`, not this snapshot.

---

# W17 Instruction-Structure & Workspace Audit — 2026-07-09

Checkpoints at audit time are recorded in `CURRENT_STATUS.md` (control-fw, ground-station,
soundlight, iPhone_rc, print repo, and the manual repo). Everything below is based on
reading every instruction-bearing file in both workspace roots; nothing was modified,
created, or committed during the audit.

## A. Executive verdict: NEEDS CLEANUP

Not RISKY — the safety boundaries (no iPhone→CRSF, no iPhone→servo, W3 log-only, firmware
iPhone-unaware, pan/tilt gated) are stated redundantly and without a single contradiction
across all doc sets. The problems are structural:

1. **The parent `projects/CLAUDE.md` was manual-only in content but workspace-wide in
   effect.** Claude Code loads `CLAUDE.md` from the working directory and every parent
   directory, so a firmware session started in `w17-control-fw/` inherited Hard Rule #1
   ("Never modify source code in the three repos") alongside the firmware brief. Every dev
   session in any repo started inside a rule written for manual sessions. This was the
   single biggest governance defect.
2. **`iPhone_rc` has no AGENTS.md.** Its real agent instructions live in
   `docs/W17_WINDOWS_BRIDGE_HANDOFF.md` ("What Not To Do", "Notes For Future Codex
   Sessions") — a handoff doc that also carries a stale ground-station hash (`9e57a2e` vs the
   then-current ground-station checkpoint) and W2/W3 "implemented and pushed" claims that
   `ROADMAP_AND_DECISIONS.md` and `current_state_onboarding.md` contradict.
3. **`w17-ground-station` has no CLAUDE.md at all** — a session there got only the inherited
   manual-session rules.
4. **`w17-control-fw/CLAUDE.md` is a frozen initial build brief**, not maintenance rules:
   §8 still says "First deliverable — stop and show me after this," the pin map is labeled
   "STARTING PROPOSAL," and the A2/Phase-B hardware gates it should carry appear nowhere in it.
5. Minor: duplicated untracked docs at the projects root, one stale handoff, stale hashes in
   several task docs.

## B. Current instruction-file inventory (as found 2026-07-09)

Key files and verdicts:

- `projects/CLAUDE.md` (35 ln) — loaded workspace-wide; content was manual-session-only;
  Rule 1 ("never modify source") is dangerous when inherited by dev sessions. **Reverse
  leak:** manual rules leaked into firmware repos.
- `w17-control-fw/CLAUDE.md` (111 ln) — firmware-specific ✅ but a frozen build brief: §8
  "first deliverable", pin map "STARTING PROPOSAL", no A2/Phase-B gate. Camera note (line 40)
  is current and good.
- `w17-soundlight-fw/CLAUDE.md` (51 ln) — best-shaped instruction file on the Claude side;
  current; clean of iPhone/UDP (grep-verified).
- `w17-ground-station/CLAUDE.md` — **MISSING**; session inherits manual rules only.
- `iPhone_rc/AGENTS.md` — **MISSING**; de-facto instructions scattered in README (505 ln) +
  the handoff doc.
- `iPhone_rc/README.md` (505 ln) — product README doubling as agent spec; too long for that job.
- `iPhone_rc/docs/W17_WINDOWS_BRIDGE_HANDOFF.md` (258 ln) — best safety text in the repo,
  wrong container; stale hash (line 16); "W2/W3 implemented+pushed" (lines 17-18) contradicts
  ROADMAP:16/:37 and onboarding:357; contains the only two absolute paths in Codex land
  (lines 12, 244 — print-repo do-not-touch).
- `iPhone_rc/references/firmware_ROADMAP.md` (279 ln) — a *firmware* roadmap inside the iPhone
  repo; "push pending" claims from 2026-07-02; **the one real firmware-assumption leak into
  Codex territory.**
- `Codex/w17-rc-print-codex/AGENTS.md` (104 ln) — exemplary: authority order, hard safety
  rules, isolated; zero electronics/bridge content (verified). Keep unchanged.
- `learning-manual/README.md` + `00_START_HERE.md` (12 + 81 ln) — entry point ✅, current.
- `learning-manual/soundlight_fw_s5_handoff.md` (217 ln) — stale: "do not start S5" but S5 is
  complete; dead hashes.
- `learning-manual/control_fw_completion_handoff.md` (123 ln) — historical, harmless if
  understood as archive.
- `_handoff/windows_bridge_contract_from_iphone_side_original.md` (576 ln) — byte-identical
  (md5-verified) 3rd copy of the iPhone contract; will rot silently.
- `iphone_pan_tilt_firmware_readiness.md` (305 ln, projects root) — byte-identical duplicate
  of the tracked `w17-control-fw/project-review/` copy (diff-verified).
- `w17-ground-station/docs/windows_bridge_contract.md` (702 ln) — explicitly self-labels
  "Windows implementation copy… authoritative contract lives with the iPhone app" ✅.
- `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` (182 ln) — the A2 gate
  source: "STATUS — NOT EXECUTED… Phase B remains blocked"; problem is no auto-loaded file
  points to it.
- Repo READMEs — all current, no hash/TODO rot (grep-verified).
- `.claude/settings.local.json` — allowlist full of one-off `sed -i` commands from a past
  session (cosmetic).

Also verified: no global `~/.claude/CLAUDE.md`, no `CLAUDE.local.md` anywhere, no `.cursorrules`.

## C. Problems found

- **P1 — Inheritance conflict (the big one).** From `w17-control-fw/`, the session got the
  parent manual rules + the firmware build brief together; ground-station got only the manual
  rules. "Unless explicitly asked" was the only escape hatch.
- **P2 — Missing files.** No `w17-ground-station/CLAUDE.md`, no `iPhone_rc/AGENTS.md`.
  Ground-station matters most: the W3-log-only boundary is enforced in code
  (`main/HeadTrackingReceiver.js` is a structural dead end guarded by
  `test/noControlPath.test.js`) yet no instruction file states it.
- **P3 — Build-brief fossilization.** control-fw CLAUDE.md §8 and "STARTING PROPOSAL"
  describe day 1; the binding gates (A2 NOT EXECUTED, Phase B blocked) live only in
  `project-review/13_…checklist.md`, which nothing auto-loads.
- **P4 — Codex instruction fragmentation.** iPhone safety rules live in a handoff doc mixing
  durable boundaries, canonical-ownership declarations, and status/checkpoints that age at
  different speeds (the stale hash already did; "W2/W3 implemented" disagrees with the repo's
  own ROADMAP and onboarding).
- **P5 — Untracked duplicate transfer copies at the projects root.**
  `_handoff/…original.md` (3rd copy of the bridge contract) and root
  `iphone_pan_tilt_firmware_readiness.md` (2nd copy of a tracked file).
- **P6 — Stale task docs.** `soundlight_fw_s5_handoff.md` ends "do not start S5" while the
  manual README records S5 complete; dead hashes in it, in `review_progress.md`, and in the
  iPhone handoff; ground-station test counts disagree between docs (21/21 vs 118/118);
  `iPhone_rc/references/firmware_ROADMAP.md` is a stale foreign firmware doc.
- **P7 — Self-stale meta-claim.** The readiness doc says control-fw's CLAUDE.md gimbal table
  is stale — but CLAUDE.md was since updated, so the staleness claim is now the stale thing.

**Not problems:** the safety boundaries themselves (fully consistent, often enforced in
code/tests); bridge-contract ownership (explicitly assigned — iPhone_rc canonical,
ground-station implementation copy); the print repo (exemplary isolation); absolute-path
hygiene (near-zero).

## D. Recommended final structure (endorsed target)

```
projects/
├── CLAUDE.md                REWRITE   Shared workspace rules only (~60-90 ln). Safe to
│                                      inherit from ANY subdirectory.
├── WORKSPACE_MAP.md         CREATE    Stable map + canonical-vs-copy registry.
├── CURRENT_STATUS.md        CREATE    All volatile state; the only file with hashes.
├── learning-manual/CLAUDE.md CREATE   Manual-session rules moved here (~25-40 ln).
├── w17-control-fw/CLAUDE.md REWRITE   Maintenance brief + A2/Phase-B gate block. Drop §8.
├── w17-ground-station/CLAUDE.md CREATE  Windows=authority; viewer-only; W2 5601; W3 5602
│                                      LOG-ONLY (dead-ended); contract is a copy.
└── w17-soundlight-fw/CLAUDE.md KEEP   +2 lines: "no control authority; link2 consumer only".

Codex/
├── iPhone_rc/AGENTS.md      CREATE    Distilled boundaries + canonical ownership (~80-120 ln).
└── w17-rc-print-codex/AGENTS.md KEEP UNCHANGED.
```

Amendments beyond the original draft: add `learning-manual/CLAUDE.md` (makes the parent
rewrite safe); add `CURRENT_STATUS.md` as the single home for everything that rots;
formalize `_handoff/` as a transfer inbox.

## E. Minimal edit plan (all SAFE class)

1. Split parent CLAUDE.md → shared rules stay; manual rules move to `learning-manual/CLAUDE.md`.
2. Create `w17-ground-station/CLAUDE.md`.
3. Create `iPhone_rc/AGENTS.md`.
4. Rewrite `w17-control-fw/CLAUDE.md` (drop §8/"STARTING PROPOSAL"; add A2/Phase-B gate block).
5. Create `CURRENT_STATUS.md` + `WORKSPACE_MAP.md`.
6. Dedupe untracked root copies.
7. Mark stale handoffs superseded.
8. iPhone_rc doc hygiene (stale hash, W2/W3 claims, foreign roadmap) — in a Codex session.
9. Optional: prune the one-off `sed` entries from `.claude/settings.local.json`.

**Import-vs-duplicate rule:** repo instruction files state their own boundaries in full but
reference everything else (gates by pointer, contracts by pointer, status by pointer to
CURRENT_STATUS.md). Never copy the contract body or checkpoint hashes into instruction files.

## F. Safety-critical lines that must appear

In shared `projects/CLAUDE.md` — all seven: (1) no active iPhone-derived pan/tilt until the
separate reviewed milestone; (2) no iPhone→CRSF; (3) no iPhone→servo/gimbal/ESC; (4) firmware
never parses iPhone JSON / receives iPhone UDP; (5) W3 (UDP 5602 on Windows) is LOG-ONLY;
(6) firmware is the only producer of final hardware outputs, from arbitrated inputs only;
(7) Windows is the control/integration authority, iPhone is a thin HUD client.

Repo additions — control-fw: A2 NOT EXECUTED / Phase B blocked; failsafe-first; arm gate;
ESC motor power disconnected until failsafe+arm proven live; no unattended flashing/powering.
ground-station: boundaries 5+7 plus "keep `noControlPath.test.js` green." soundlight: no
control authority; link2 consumer only; local 500 ms failsafe. iPhone AGENTS.md: boundaries
1-5,7 from the iPhone side + "sending gated on tracking enabled + centered." print AGENTS.md:
keep its existing "no electronics assumptions" isolation.

## Governance notes (H–K, condensed)

- **Context-loading:** Claude loads CLAUDE.md from cwd + every ancestor + `~/.claude/`
  (none exists). The two-root split (projects vs Codex) is the actual isolation mechanism
  between Claude and Codex context — keep it.
- **Hierarchy:** L1 workspace (`projects/CLAUDE.md`) = rules true for every session; L2 repo
  (`*/CLAUDE.md`, `*/AGENTS.md`) = architecture invariants + repo safety + gate pointers;
  L3 task (`CURRENT_STATUS.md`, `_handoff/*`, `project-review/13_*`) = volatile, dated;
  L4 session prompt = capsule. Safety boundaries are the one thing deliberately duplicated
  (L1 + relevant L2). Everything else lives at one level and is referenced.
- **Staleness:** hashes, gate state, pending validations, deadlines → `CURRENT_STATUS.md`
  only. Instruction files carry zero facts that change weekly.
- **Canonical vs copies:** iPhone owns bridge contract/schemas/examples; ground-station holds
  a labeled implementation copy; link2 owned by control-fw; A2 checklist single-source;
  every new copy must carry a "canonical: <path>" header.
- **Move/rename risk:** DEFER ALL. Builds have zero absolute-path coupling (package.json,
  platformio.ini, wokwi.toml, scripts all repo-relative). Renaming `iPhone_rc` is RISKY (git
  remote, Xcode paths, ~15 cross-doc refs); renaming `projects/` or extracting
  `learning-manual` is MEDIUM with no payoff. Folder moves are doc-breaking, not
  build-breaking — still not worth it now.

## Risk ranking

- **Must do before more AI work:** split parent CLAUDE.md (+ learning-manual/CLAUDE.md);
  ground-station CLAUDE.md; iPhone_rc AGENTS.md; gates into control-fw CLAUDE.md. (All SAFE.)
- **Useful soon:** CURRENT_STATUS + WORKSPACE_MAP; dedupe untracked root copies; mark stale
  handoffs; iPhone doc hygiene (do in a Codex session). (SAFE.)
- **Optional:** settings.local.json prune; archive `learning-manual/plan/`; 300-vs-400 ms
  clarifying note; projects-root README pointer. (SAFE.)
- **Avoid for now:** renaming `iPhone_rc` (RISKY); renaming `projects/` or extracting
  `learning-manual` (MEDIUM, no payoff); any folder moves; merging the Codex root into
  projects (RISKY — would put Codex repos inside Claude's inheritance path).

## No-move recommendation

Defer all folder moves and renames indefinitely. The current physical layout is the best
part of the system: the two-root split is the isolation mechanism between Claude and Codex,
builds have zero absolute-path coupling, and every found problem is fixable with doc-only
(SAFE) edits.

---

# Appendix — full operational sections (restored)

These are the operational sections of the 2026-07-09 audit, restored at fuller length. They
were the most reusable output (context-loading map, hierarchy, capsules, starters,
maintenance). This is still a **historical, non-canonical snapshot** — live truth lives in
`CLAUDE.md`, `WORKSPACE_MAP.md`, `CURRENT_STATUS.md`, and repo-local instruction files.
Where a capsule below originally quoted a checkpoint hash, the hash has been replaced with
"see CURRENT_STATUS.md" to keep this file free of drifting checkpoints.

## H. Context-loading map

Claude Code loads `CLAUDE.md` from the working directory **and every ancestor directory**,
plus `~/.claude/CLAUDE.md` (none exists — verified). Sub-directory `CLAUDE.md` files load
lazily when files in that subtree are touched. Codex loads `AGENTS.md` from its repo root.

| Session start dir | Auto-loaded before cleanup | Auto-loaded after cleanup |
|---|---|---|
| `projects/` | projects/CLAUDE.md (manual-flavored) | shared rules; + learning-manual/CLAUDE.md lazily when manual files touched |
| `projects/w17-control-fw/` | parent manual rules + build brief (**conflict**) | shared rules + firmware maintenance brief |
| `projects/w17-ground-station/` | parent manual rules only | shared rules + ground-station brief |
| `projects/w17-soundlight-fw/` | parent manual rules + sound brief | shared rules + sound brief |
| `projects/learning-manual/` | parent manual rules (fit by luck) | shared rules + manual rules |
| `Codex/iPhone_rc/` | nothing (README by convention only) | AGENTS.md |
| `Codex/w17-rc-print-codex/` | AGENTS.md ✅ | unchanged |
| `Documents/` | nothing | nothing — fine for cross-repo audits; paste a capsule |

Never global context: bridge contracts (either copy), `project-review/*`, all handoffs,
`CURRENT_STATUS.md` (referenced, read on demand), anything with a hash in it. Cross-repo
instruction dependencies found: one — the firmware repos' briefs implicitly relied on the
parent for the manual read-only rule; after the split the dependency inverts healthily (repos
depend on the parent for *shared* rules only). `soundlight/CLAUDE.md` referencing the control
repo as the link2 protocol owner is correct and should stay.

## Instruction hierarchy (full)

- **L1 workspace (`projects/CLAUDE.md`)** — rules true for *every* session for months: repo
  map, ownership, the 7 safety lines, review/commit etiquette. Never: status, hashes, module
  lists.
- **L2 repo (`*/CLAUDE.md`, `*/AGENTS.md`)** — architecture invariants, repo-specific safety,
  build/test commands, gate *pointers*. Never: another repo's rules, checkpoints, session
  narratives.
- **L3 task (`CURRENT_STATUS.md`, `_handoff/*`, `project-review/13_*`)** — volatile by design,
  dated, explicitly superseded when done. The *only* level where hashes and "not executed yet"
  belong.
- **L4 session prompt** — the capsule (below): goal, 2-4 files to read, boundaries reminder.

Duplication rule: safety boundaries are the one thing deliberately duplicated (L1 + relevant
L2, same wording). Everything else lives at exactly one level and is referenced.

## Token budget

| File | At audit | Target | Verdict |
|---|---|---|---|
| projects/CLAUDE.md | 35 | 60–90 | tiny — right size, wrong content |
| w17-control-fw/CLAUDE.md | 111 | 100–150 | normal; §8 + bench-wiring detail could move to docs/ |
| w17-ground-station/CLAUDE.md | — | 60–90 | tiny |
| w17-soundlight-fw/CLAUDE.md | 51 | ~55 | ✅ the benchmark |
| learning-manual/CLAUDE.md | — | 25–40 | tiny |
| iPhone_rc/AGENTS.md | — | 80–120 | normal |
| print AGENTS.md | 104 | keep | ✅ |

Flagged too large / historical for instruction duty: `iPhone_rc/README.md` (505 — fine as a
README once AGENTS.md exists), `W17_WINDOWS_BRIDGE_HANDOFF.md` (258 — demote to L3 archive
after distillation), both bridge contracts (576/702 — correct as reference, never auto-load),
`current_state_onboarding.md` (422 — L3).

## Staleness-risk guidance

Everything found rotting was a **status claim inside a long-lived doc**: hashes (S5 handoff,
review_progress, iPhone handoff, test plan), "(19 days)" in `ROADMAP.md:3`, "implemented /
pending" contradictions (W2/W3), "do not start S5," and the meta-stale "CLAUDE.md is stale"
claim. Rule: **CLAUDE.md / AGENTS.md carry zero facts that change weekly.** Hashes, gate
states (A2 / Phase B), pending validations, deadlines-with-countdowns → `CURRENT_STATUS.md`
(single file, dated header, overwritten not appended). Gate *definitions* stay in their
checklists; instruction files carry only the pointer plus the durable sentence "Phase B is
gated on A2 review."

## Canonical truth vs copies (full table)

| Artifact | Canonical | Copies | Status at audit |
|---|---|---|---|
| Bridge contract + schemas + examples | `iPhone_rc/docs/windows_bridge_contract.md`, `schemas/`, `examples/` (ownership declared in handoff §E) | ground-station 702-ln implementation copy (correctly labeled, verbatim §1-7 + W3 notes); `_handoff/` copy (**unlabeled, dedupe/rename**) | ✅ except the third copy |
| link2 protocol | `w17-control-fw/docs/link2_protocol.md` | soundlight copy — CLAUDE.md says "control repo owns it, do not fork" | ✅ model handling |
| Pan/tilt readiness | tracked `w17-control-fw/project-review/…` | untracked root duplicate (**dedupe**) | fix |
| A2 checklist | `project-review/13_…` — single copy | — | ✅ keep single; never copy into other repos |
| Manual chapters | `learning-manual/` | none | ✅ |
| firmware ROADMAP | `w17-control-fw/docs/ROADMAP.md` | stale copy in `iPhone_rc/references/` (**remove/refresh**) | fix |

Anti-conflict rule going forward: every copy's first lines must say *"IMPLEMENTATION COPY —
canonical: `<path>` — do not edit here."* Both deliberate copies already do this; make it
mandatory for any new one.

## Cross-repo handoff mechanism (recommended)

- `projects/CURRENT_STATUS.md` — volatile state, overwritten each update.
- `projects/WORKSPACE_MAP.md` — stable map + canonical/copy registry + convention list.
- `projects/_handoff/` — dated snapshot files (`YYYY-MM-DD_topic.md`), each headed
  "SNAPSHOT — canonical: `<path>`", plus a README saying the folder is disposable. Codex→Claude
  transfers land here; Claude→Codex transfers land in `iPhone_rc/docs/` via the owner.
- `VALIDATION_GATES.md` — optional; only if gates outgrow the CURRENT_STATUS gate block. Don't
  create while A2/Phase-B fits in five lines.
- `DECISIONS.md` — skip for now; `ROADMAP_AND_DECISIONS.md` (iPhone) and `project-review/`
  (firmware) already hold decisions. Add only if cross-repo decisions start having no home.

## Session starter templates

- **Firmware (control):** *"W17 control firmware session in `w17-control-fw/`. Read CLAUDE.md,
  `projects/CURRENT_STATUS.md`, `docs/ROADMAP.md`. Task: <X>. Boundaries: A2 not executed →
  Phase B blocked, no hardware flash/power, no iPhone awareness in firmware, failsafe/arm
  invariants untouchable."*
- **Ground station:** *"W17 ground-station session in `w17-ground-station/`. Read CLAUDE.md,
  README, `docs/windows_bridge_contract.md` (implementation copy — canonical is iPhone-side).
  Task: <X>. Boundaries: W3/5602 stays log-only, `noControlPath.test.js` stays green, no
  pan/tilt mapping, don't edit the contract copy's §1-7."*
- **Sound/light:** *"W17 soundlight session in `w17-soundlight-fw/`. Read CLAUDE.md and
  `docs/link2_protocol.md` (owned by control repo — don't fork). Task: <X>. Boundaries: no
  control authority, cross-core rule, local 500 ms failsafe."*
- **Manual:** *"W17 manual session in `projects/`. Read `learning-manual/CLAUDE.md`,
  `learning-manual/README.md`, `source_code_progress.md`. Task: <X>. Source repos read-only;
  write only in learning-manual/; tag [C]/[I]/[A]."*
- **iPhone Codex:** *"iPhone_rc session. Read AGENTS.md and `docs/current_state_onboarding.md`.
  Task: <X>. Boundaries: thin HUD client — no CRSF, no servo, no control path; 5602 is
  intent-only; schemas/examples here are canonical — changing them requires updating the
  Windows copy note; never touch sibling repos."*
- **Print Codex:** *"w17-rc-print-codex session. Read AGENTS.md; authority =
  `docs/00_BUILD_SHEET_v2.md` + `print_spec_v2.md`. Task: <X>. Never modify `stl_raw/`;
  uncertain → `uncertain_review_manually`; no electronics/firmware assumptions."*
- **Cross-repo audit:** *"Read-only W17 audit from `Documents/`. Read
  `projects/WORKSPACE_MAP.md` + `CURRENT_STATUS.md` first. Treat all instruction files as
  audit targets, not binding. No edits, no commits, no hardware."*

## Safety-boundary consistency — verdict: CONSISTENT, zero contradictions

All nine checked boundaries verified present and uncontradicted; strongest statements:
no-iPhone→CRSF/servo (`windows_bridge_contract.md:79-83`, both copies §6), W3 log-only
(ground-station README:60-65, contract:606-610 + code-level guard test), pan/tilt gated
(readiness doc §7-8: "ch9/10 remain exclusively the right stick until the separate safety
milestone"), firmware iPhone-unaware (readiness:245 "ever, per the architecture"), A2/Phase-B
(checklist 13:1-8), Windows-as-hub (`iphone_bridge_readiness.md:8`). Two nuances, not
contradictions: firmware pan/tilt *hardware support* is DONE (stick-driven ch9/10) vs
iPhone-derived pan/tilt forbidden — docs separate these carefully; stale-intent thresholds
300 ms vs 400 ms are different layers (bridge receiver vs ground-station intent). The only
weakness was placement: none of this was in an auto-loaded file at audit time (except
control-fw CLAUDE.md:40).

## Anti-patterns checklist

| Anti-pattern | Found at audit? |
|---|---|
| Giant global CLAUDE.md | No — opposite problem: too narrow |
| Repo rules duplicated in workspace file | No |
| Stale hashes in auto-loaded files | No — all hashes were in task docs (discipline held) |
| Safety rules in only one repo | Partially — well-spread in docs, absent from auto-loaded files |
| Codex + Claude instructions mixed | No — physical two-root separation prevents it |
| Implementation docs as canonical contracts | No — ownership explicit; only `_handoff/` copy unlabeled |
| "Future" wording contradicting implemented state | Yes — W2/W3 in iPhone ROADMAP/onboarding vs handoff; S5 handoff; readiness doc's CLAUDE.md claim |
| Vague "continue project" prompts | Mitigated by handoff docs; capsules close it |

## Maintenance process

- **CURRENT_STATUS.md** — update at the end of any session that changes a checkpoint, gate,
  or validation state (overwrite in place). If a session didn't change state, don't touch it.
- **WORKSPACE_MAP.md** — only when a repo / canonical-file / convention is added or retired;
  expect months between edits.
- **Repo CLAUDE.md / AGENTS.md** — only when an *invariant* changes (new module class, new
  boundary, gate opens: e.g. flip the one gate line when A2 closes). Treat edits as reviewable
  events; if you're editing one weekly, something belongs in L3 instead.
- **Handoff doc** — create when transferring work across repos/tools or parking a
  multi-session effort; date it; mark HISTORICAL when consumed.
- **Don't touch instruction files** for status changes, mid-task, or to record narrative —
  that's what status/handoff files are for.

## I. New-session context capsules

Paste after a limits reset. (Checkpoints intentionally point to `CURRENT_STATUS.md` rather
than quoting a hash here.)

- **control-fw:** `W17 1/10 FPV RC F1 car. This repo = ESP32 #1 control firmware (CRSF in →
  failsafe/arm/gearbox → servo+ESC PWM out; link2 UART to board #2). Software complete through
  Phase A (A1.1-A1.6); A2 no-power bench checklist NOT EXECUTED → Phase B (powered) BLOCKED.
  Firmware is iPhone-unaware forever; pan/tilt = stick-driven ch9/10 only. Read CLAUDE.md +
  projects/CURRENT_STATUS.md. Don't flash/power hardware. Checkpoint: see CURRENT_STATUS.md.`
- **ground-station:** `W17 ground station = Electron viewer (video+HUD+telemetry) on Windows,
  the control/integration hub side. W2 = UDP 5601 telemetry→iPhone (done). W3 = UDP 5602
  head-tracking receiver, LOG-ONLY, structurally dead-ended (noControlPath.test.js guards it).
  Bridge contract in docs/ is an implementation COPY — canonical is iPhone_rc. No pan/tilt
  mapping without separate safety milestone. Read README + docs/windows_bridge_contract.md
  header. Checkpoint: see CURRENT_STATUS.md.`
- **soundlight-fw:** `W17 ESP32 #2: consumes one-way link2 UART from board #1 → V10 engine
  synth (I2S/MAX98357A) + WS2812 F1 lights. No control authority. link2 protocol owned by
  control repo (copy here — don't fork). Cross-core rule: only the atomic param word crosses
  cores. 500 ms no-frame → local failsafe. Read CLAUDE.md. Checkpoint: see CURRENT_STATUS.md
  (clean).`
- **manual:** `W17 learning manual in projects/learning-manual (repo = w17-software-manual).
  Beginner-friendly, [C]/[I]/[A] tagging, source repos READ-ONLY. Chapters 00-11 done;
  code_explained: control C1-C10 done+reviewed, soundlight S1-S5 done; next = ground station
  G1-G4. Read learning-manual/README.md + source_code_progress.md. Write only inside
  learning-manual/.`
- **iPhone Codex:** `iPhone_rc = thin FPV HUD client (SwiftUI). Receives telemetry UDP 5601;
  sends head-tracking INTENT UDP 5602 (Windows logs only). This repo owns canonical bridge
  schemas/examples/contract (docs/windows_bridge_contract.md, schemas/, examples/). Never:
  CRSF, servo commands, any control path, sibling-repo edits. Active pan/tilt = future gated
  milestone. Read docs/current_state_onboarding.md. Checkpoint: see CURRENT_STATUS.md.`
- **print Codex:** `w17-rc-print-codex = STL/SCAD print-decision project. Authority:
  docs/00_BUILD_SHEET_v2.md + print_spec_v2.md (v1 historical). Never modify stl_raw/; copy
  into print_queue/ only; uncertain → uncertain_review_manually. Isolated: no
  firmware/electronics/bridge assumptions. Read AGENTS.md.`

(Risk ranking and the no-move recommendation appear in full above, before this appendix.)
