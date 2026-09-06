# NEW_SESSION_HANDOFF — W17 OFFLINE READINESS / BENCH PREPARATION (r3, written 2026-09-06 late evening by the Fable Director session 719f19ec)

Boot without chat history. Read in this order: (1) workspace `CLAUDE.md` (safety 1–7, one session per tree); (2) this file; (3) `W17_OFFLINE_READINESS.md`
(§1a/§1b = the two consumed grants' landing tables, §3 = workstream rows, §4a = rulings summary, §6 = change log); (4) `2026-09-05_offline_decision_round_1.md`
and **`2026-09-06_offline_decision_round_2.md`** (verbatim owner rulings); (5) `W17_OWNER_ACTIONS.md` — **Decision Round 2 is RULED; five items are BLOCKED on the
photo/label packet; Decision Round 3 (three small items) is OPEN** — `W17_OWNER_PHOTO_LABEL_INTAKE.md` (the ONE packet) and `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`;
(6) `bench-gates/INDEX.md`, `G-INDEX.md`, `MISSING_THRESHOLDS.md`, `BG-03_phase_b_first_power.md` § Starting current limits; (7) `_handoff/2026-09-06_O6_derivation_report.md`
+ `_handoff/2026-09-06_R-O6_review.md` (v2) and `_handoff/2026-09-06_O6_addendum_report.md` + `_handoff/2026-09-06_R-ADD_review.md` (the photo-independent addendum).
Everything in (3)–(7) at its CURRENT state lives on workspace branch **program/offline-readiness-r3** — main carries the state up to ca84c91 only (DR2-1 landing + its record).
Session scratchpad: `SP3 = /private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/719f19ec-91ce-4075-b6dc-10a895535bc5/scratchpad` (worktrees `wt-ws-r3`, `wt-cf-docnits`;
`reports/`: DR2-7_wifi_mode, DR2-8_sound, DR2-14_heatsink, DR2-APPLY-1, R-DR2, V-DR2, O6_addendum_v1/v2, R-ADD, ADD-FIX-APPLY, V-ADD, CF-DOCNITS, V-CF-DOCNITS). If SP3 is gone, every deliverable is in the branches below.

## 0. First commands (read-only)
```
for r in . w17-control-fw w17-soundlight-fw w17-ground-station iPhone_rc w17-mapper w17-3d-codex; do git -C /Users/vitaliykhomenko/Documents/projects/$r worktree list; git -C /Users/vitaliykhomenko/Documents/projects/$r status --short | head -3; done
```
Expected: trunks clean, local == origin, at workspace main **ca84c91** · cf **1d17c6b** · sl 7220c08 · GS 809976c · iPhone 7aaf2cf · mapper w17-headtrack aa7fb7d · 3d 8889323.
Worktrees: SP3/wt-ws-r3 (program/offline-readiness-r3 `git rev-parse --short program/offline-readiness-r3` (authoritative; the tip after the closing state commit of 2026-09-06 late evening)), SP3/wt-cf-docnits (cf offline/docfix-ci-count-and-wifi-topology 631dee2); the prior session's SP2 worktrees
(wt-ws-r2 4ae3536 = now main's ancestor, wt-ws-d4, wt-ws-o6 — all merged) may still exist and are safe to `git worktree remove`. `u4-arbiter` 4e445c9 parked elsewhere — `git show` only.
If a trunk moved, another session landed something: re-read `CURRENT_STATUS.md` and `W17_OFFLINE_READINESS.md` before anything else.

## 1. Branch state — PUSH GRANT CLOSED (D-6 and DR2-1 both one-time, both CONSUMED); nothing below is pushed
| repo | branch | tip | worktree | chain | content |
|---|---|---|---|---|---|
| workspace | **program/offline-readiness-r3** | `git rev-parse --short program/offline-readiness-r3` (authoritative; the tip after the closing state commit of 2026-09-06 late evening) | SP3/wt-ws-r3 | DR2-APPLY-1 (Sonnet) → R-DR2 (Opus) FIX_REQUIRED 3B/9N → FIX (Director) → V-DR2 (Sonnet) PASS · research ×3 (Sonnet) → O-6 addendum v1 (Opus) → R-ADD (Opus) FIX_REQUIRED 3B/10N → FIX+APPLY v2 (Opus) → V-ADD (Opus) FIX_REQUIRED 1B (a learning-manual cite shifted by the manual edit) + 6N → FIX (Director) → V-FINAL (Sonnet, scoped) — see readiness §3 for the verdict | DR2 rulings verbatim; DR2 applied into BG-03/BG-04/BG-08/tools/MISSING_THRESHOLDS/INDEX; `W17_OWNER_PHOTO_LABEL_INTAKE.md`; addendum applied (S4/S5 load states, thermal check at S5, capture list, T7/L13/L16, Rail-A sizing sum); Decision Round 3; procurement rows (≥ 32×32 heatsink BUY, temperature probe CHECK); `_handoff/` addendum + review; state files |
| w17-control-fw | offline/docfix-ci-count-and-wifi-topology | **631dee2** | SP3/wt-cf-docnits | CF-DOCNITS (Sonnet) → V-CF-DOCNITS (Sonnet, fresh) PASS | `ci.yml` comment 356 → 360 (native 360/360 re-run); BOM:22 car module = 5 GHz STATION (was "provides the WiFi AP") |

## 2. The grant to request next (exact scope, one-time) — NOT granted yet
(a) workspace `program/offline-readiness-r3` at `git rev-parse --short program/offline-readiness-r3` (authoritative; the tip after the closing state commit of 2026-09-06 late evening) → main (ff); (b) cf `offline/docfix-ci-count-and-wifi-topology` 631dee2 → cf main (ff; docs-only; CI must be observed green).
Landing rule per repo as in `W17_OFFLINE_READINESS.md` §1a/§1b: MAIN checkout only, `git worktree list` + `git branch --show-current` + HEAD re-check, `--ff-only`, workspace link checks exit 0
both modes (cf: CI run observed to completion), push, local == origin, record in `CURRENT_STATUS.md` + readiness §1c, say CONSUMED. If content changes materially first, independently verify the changed portion.

## 3. Rulings in force
D-1…D-6 (`2026-09-05_offline_decision_round_1.md`; D-6 consumed). **Decision Round 2 (`2026-09-06_offline_decision_round_2.md`):** DR2-1 CONSUMED · DR2-2 M-PEAK RATIFIED ·
DR2-3 PSU / DR2-4 UBEC / DR2-6 MH-ET regulator / DR2-9 blower / DR2-10 MG90S **BLOCKED on the photo packet items 1/2/3/4/5** (no numbers may be ruled or inferred for them) ·
DR2-5 PSU-first + ESC feed separated for S0–S9 RATIFIED (A2 S6 topology-change rule: re-run P2/P4/P5 before and after) · DR2-7 shipped Wi-Fi = 5 GHz station, P(5) stays 1800 mA
until the camera config is captured at bring-up (stress row on paper only) · DR2-8 volume default 80 / acceptance = NVS value at D8 Phase 11a / ceiling 100; speaker → packet item 6 ·
DR2-11 **CC > 500 ms after connect = STOP** (a STOP, never a permission; unexplained CC = STOP regardless; record the duration) · DR2-13 shipped `maxBrightness` 110 KEPT, 180 = ceiling only,
no firmware branch · DR2-14 ≥ 32×32 mm heatsink BUY if it fits (envelope from packet item 7; Z-clearance is the binding constraint: 3 mm to a PROVISIONAL keepout).
**Decision Round 3 (OPEN, small):** DR3-1 streaming-soak duration for S5 · DR3-2 confirm the 9 dB GAIN strap before soldering · DR3-3 temperature probe / K-type input on hand?

## 4. Next autonomous actions (in order; none powered)
1. **When the next grant is given:** land (a) then (b) per §2; record; say CONSUMED.
2. **When the photo/label packet arrives** (`W17_OWNER_PHOTO_LABEL_INTAKE.md`, 7 items): extract every defensible fact → update component identities → **O-6 v3** on a new branch
   (S0 = PSU minimum settable limit; η from the UBEC datasheet for the pack-side form `I_pack ≤ 5 A × V_rail / (V_pack × η)`; S9 column from BEC#2's set voltage; S1 ceiling from the
   regulator's datasheet; S6/S7/S8 from labels or stay BLOCKED; S4 from the speaker label; heatsink envelope from item 7) → Opus derive → Opus adversarial review → fix → fresh
   verify (every safety artifact this program produced failed its first review: v1 7B, v2 1B, DR2 application 3B, addendum 3B — assume v3 will too).
3. **When DR3-1/2/3 are answered:** apply into BG-03 S5 thermal check / BG-04 Phase 9 / procurement; small branch, fresh grant.
4. VM track when the owner reports disk/Fusion/ISO ready (host re-observed this evening: 17 GB free, no Fusion, no ISO, no pwsh): runbook §1.0 → `scripts/vm/host-vm.sh doctor` → bootstrap → snapshot → stage → suite → evidence.
5. Measurement track when the owner returns the CSV: `w17-3d-codex/11_cad/tools/ingest_measurements.py --dry-run <csv>` → review → `--apply` → render → C-2/C-3 → fit ladder. Proposed new row M-31 (Wi-Fi bay free volume) is described in `reports/DR2-14_heatsink.md` §3 and in intake item 7 — add it to the pack only on a reviewed 3d-codex branch (the delivered sheet must not silently change under the owner).
6. Windows x64 session when the owner provides the PC + FT232RL + DS4 (unchanged from r2 §4 item 7).
7. Queued doc nits (fresh grant each): `docs/w17_wiring_assembly_atlas.html`:170 (cf, still says the car module hosts the AP); learning-manual 03:220-221 / 05:361 — FIXED on r3 (fdca9f7, station role, guide cited; V-ADD confirmed it obeys `learning-manual/CLAUDE.md`); `HARDWARE_INVENTORY.md`:96 vs BOM:66 USB port type (resolves with packet item 3); 3d-codex placement-doc wording (AA §4.1 U.FL at X+1 vs `J_component_placement_matrix.md`:26 "U.FL aft").
8. Keep `W17_OWNER_ACTIONS.md` current; surface the queue only when something becomes newly actionable.

## 5. Dependency graph (delta from r2)
Photo packet items 1+2 (PSU, UBEC) → O-6 v3 S0/S1–S9 absolute limits · item 3 → S1 ceiling · items 4/5 → S6/S7/S8 or BLOCKED · item 6 → S4 · item 7 → heatsink BUY envelope → "heatsink fitted before first power-on" → BG-03 S5.
DR3-1 → S5 soak PASS/INCONCLUSIVE bookkeeping · DR3-2 → BG-04 Phase 9 (amp gain) · DR3-3 → the thermal evidence rows. Everything else unchanged: disk → Fusion → ISO → VM suite; adapter + x64 PC → hotspot;
DS4 → ds4_precheck; FT232RL + x64 PC + owner go (D-3) → BG-06 T1 + G-04 Part A; coupon C-1 → sitting → CSV → ingest; shopping + OP-49 evidence (D-2) → BG-01 → BG-02 → BG-03 → BG-04 → …; FIRST_ACTIVE NO-GO.

## 6. Physical gates — all NOT-EXECUTED; each needs the owner's explicit go
Unchanged from r2 §6. BG-03 remains BLOCKED on A2 + packet items 1–2 (and the heatsink decision's execution). Nothing was powered, flashed or connected this session.

## 7. Model policy and the rule that keeps proving itself
Fable = Director/adjudication only. Opus = adversarial review, safety-bearing derivation and fixes. Sonnet = workforce, research, ordinary verification. Every agent names its model;
reviewer ≠ implementer ≠ fresh verifier. This session: the DR2 application failed its first review (3B — two of them in the Director's own intake prose), the addendum failed its first
review (3B — sourcing, an unread datasheet section, an S4/S5 asymmetry). Keep the chain mandatory; prefer BLOCKED over a plausible number.
