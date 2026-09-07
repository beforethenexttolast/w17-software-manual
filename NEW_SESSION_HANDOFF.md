> **UPDATED 2026-09-07 morning after the DR4 grant was EXECUTED and CONSUMED** (landing record `W17_OFFLINE_READINESS.md` §1d): everything §1 lists as unpushed is now ON ITS TRUNK — workspace main **0d39a2c**, control-fw main **98ec2ef**, 3d-codex main **88c9a61**; §2's grant is consumed and no branch is awaiting a grant; all session worktrees are removed (branches kept). Read §0's expected trunks as ws 0d39a2c · cf 98ec2ef · 3d 88c9a61 (sl 7220c08 · GS 809976c · iPhone 7aaf2cf · mapper aa7fb7d unchanged). Owner instruction with the grant: **no further autonomous review wave; wait for the photo/label packet** (consume it per `bench-gates/tools/O6_V3_PACKET_BRIEF.md`) and for the DR3-3 instrument answer (an owner inventory fact — assume no probe until then). Everything else below stands.

# NEW_SESSION_HANDOFF — W17 OFFLINE READINESS / BENCH PREPARATION (r4, written 2026-09-06 night by the Fable Director session 82158128)

Boot without chat history. Read in this order: (1) workspace `CLAUDE.md` (safety 1–7, one session per tree); (2) this file; (3) `W17_OFFLINE_READINESS.md`
(§1a/§1b/§1c = the three consumed grants' landing tables, §3 = workstream rows, §4a = rulings summary, §6 = change log); (4) `2026-09-05_offline_decision_round_1.md`,
`2026-09-06_offline_decision_round_2.md` and **`2026-09-06_offline_decision_round_3.md`** (verbatim owner rulings); (5) `W17_OWNER_ACTIONS.md` — **Decision Rounds 1–3 are RULED;
the ONE open owner question is DR3-3 (temperature instrument on hand?); five DR2 items stay BLOCKED on the photo/label packet** — `W17_OWNER_PHOTO_LABEL_INTAKE.md` (the ONE packet)
and `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`; (6) `bench-gates/INDEX.md`, `G-INDEX.md`, `MISSING_THRESHOLDS.md`, `BG-03_phase_b_first_power.md` § Starting current limits + § Thermal
check at S5, **`bench-gates/tools/O6_V3_PACKET_BRIEF.md`** (launch text for the packet); (7) `_handoff/2026-09-06_O6_derivation_report.md` + `_R-O6_review.md`,
`_handoff/2026-09-06_O6_addendum_report.md` + `_R-ADD_review.md`, **`_handoff/2026-09-06_DR3-2_9dB_derivation.md` + `_R-DR3-2_review.md`** (the amp at the confirmed 9 dB gain).
Everything in (3)–(7) at its CURRENT state lives on workspace branch **program/offline-readiness-r4** — main carries the state up to 20acc8f only (DR3-grant landing + its record).
Session scratchpad: `SP4 = /private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/82158128-4da4-4094-9719-eda374787712/scratchpad` (worktrees `wt-ws-r4`, `wt-ws-dr3`, `wt-ws-brief`,
`wt-cf-atlas`, `wt-3d-ufl`; `reports/`: DR3-APPLY, DR3-2_9dB_derivation (+_v2), O6-V3-BRIEF, DOCNITS-2, V-DOCNITS-2, R-DR3, R-DR3-2, FIX-DR3, V-DR3). If SP4 is gone, every deliverable is in the branches below.

## 0. First commands (read-only)
```
for r in . w17-control-fw w17-soundlight-fw w17-ground-station iPhone_rc w17-mapper w17-3d-codex; do git -C /Users/vitaliykhomenko/Documents/projects/$r worktree list; git -C /Users/vitaliykhomenko/Documents/projects/$r status --short | head -3; done
```
Expected: trunks clean, local == origin, at workspace main **20acc8f** · cf **631dee2** · sl 7220c08 · GS 809976c · iPhone 7aaf2cf · mapper w17-headtrack aa7fb7d · 3d 8889323.
Worktrees: SP4/wt-ws-r4 (program/offline-readiness-r4 — `git rev-parse --short program/offline-readiness-r4` is authoritative; the tip after the closing state commit of 2026-09-06 night), SP4/wt-cf-atlas
(cf offline/docfix-atlas-wifi-station **98ec2ef**), SP4/wt-3d-ufl (3d offline/docfix-placement-ufl **88c9a61**); SP4/wt-ws-dr3 (offline/dr3-apply 5ded125) and SP4/wt-ws-brief (offline/o6-v3-brief a9bc926) are merged into r4 and safe to `git worktree remove`.
Every prior session's worktree was removed this session (branches kept). `u4-arbiter` 4e445c9 parked elsewhere — `git show` only.
If a trunk moved, another session landed something: re-read `CURRENT_STATUS.md` and `W17_OFFLINE_READINESS.md` before anything else.

## 1. Branch state — PUSH GRANT CLOSED (D-6, DR2-1 and DR3 grants were each one-time and are all CONSUMED); nothing below is pushed
| repo | branch | tip | worktree | chain | content |
|---|---|---|---|---|---|
| workspace | **program/offline-readiness-r4** | `git rev-parse --short program/offline-readiness-r4` (authoritative) | SP4/wt-ws-r4 | DR3-APPLY (Sonnet) + O6-V3-BRIEF (Sonnet) + DR3-2-DERIVE (Opus, report only) → **R-DR3 (Opus) FIX_REQUIRED 5B/12N** + **R-DR3-2 (Opus) FIX_REQUIRED 7B/10N** → FIX-DR3 (Opus, one pass for both + card application of the surviving derivation) → **V-DR3 (Opus, fresh) — see readiness §3 for the verdict** | DR3 rulings verbatim; DR3-1 applied (30-min streaming soak = the S5 thermal-soak characterisation, six samples, re-anchored to the first camera bring-up session where streaming is reachable, S5 PSU limit unchanged, INCOMPLETE until run — never PASS, never a fault); DR3-2 applied (9 dB CONFIRMED; pre-solder GAIN net check = unpowered resistance measurement + "any resistor/jumper ⇒ do not solder"; 12 dB spec point labelled not shipped; three M-PEAK relabels; ISTNDBY 400 µA max; ±1.6 A AMR as a damage threshold, never an allowance; P(4) BLOCKED on named blockers; 9 dB tightens nothing — output stays supply-limited at every gain band edge); DR3-3 = the one OPEN owner check; `O6_V3_PACKET_BRIEF.md`; `_handoff/` DR3-2 derivation v2 + review; state files |
| w17-control-fw | offline/docfix-atlas-wifi-station | **98ec2ef** | SP4/wt-cf-atlas | DOCNITS-2 (Sonnet) → DOCNITS-2b fix (Sonnet) → V-DOCNITS-2 (Sonnet, fresh) PASS | `docs/w17_wiring_assembly_atlas.html`:170 mermaid edge + note: car module = 5 GHz station (the last stale AP claim in that repo) |
| w17-3d-codex | offline/docfix-placement-ufl | **88c9a61** | SP4/wt-3d-ufl | same chain, PASS | `J_component_placement_matrix.md`:26: U.FL roots fwd at the X+1 edge (ZK:103, AA:154); USB pad edge stated as NOT RECORDED (was a pre-measurement guess); residual same-day "aft" wording in `T_cad_task_spec.md`:14 / `K_printable_support_spec.md` PS-13 flagged, untouched |

## 2. The grant to request next (exact scope, one-time) — NOT granted yet
(a) workspace `program/offline-readiness-r4` at its final tip → main (ff); (b) cf `offline/docfix-atlas-wifi-station` 98ec2ef → cf main (ff; docs-only; CI must be observed green);
(c) 3d `offline/docfix-placement-ufl` 88c9a61 → 3d main (ff; docs-only; no CAD touched, `11_cad/render.sh --table` as the repo check). Landing rule per repo as `W17_OFFLINE_READINESS.md` §1a–§1c.
Request (a)–(c) only once V-DR3 has PASSed on the exact tip named; if content changes after a verify, re-verify the changed portion first.

## 3. Rulings in force
D-1…D-6 · DR2-1…DR2-14 (as r3 §3) · **Decision Round 3 (`2026-09-06_offline_decision_round_3.md`): DR3-1** 30 min continuous streaming in the shipped 5 GHz-station mode = the S5 thermal-soak
CHARACTERISATION; samples at 0/5/10/15/20/30 min; NOT a claim of equilibrium; sensory STOP active; temperature only with a suitable contact instrument, never from touch; no execution authorised ·
**DR3-2** 9 dB GAIN CONFIRMED as the intended shipped MAX98357A configuration; verify the generic board's GAIN net against the exact article/datasheet before soldering; the 12 dB spec point is NOT the shipped configuration ·
**DR3-3** owner CHECK (contact probe or K-type-input meter on hand?) — **OPEN**; until answered, quantitative heatsink-temperature evidence stays BLOCKED and procurement row 14 stays CHECK.

## 4. Next autonomous actions (in order; none powered)
1. **When the next grant is given:** land (a), (b), (c) per §2; record in readiness §1d + `CURRENT_STATUS.md`; say CONSUMED.
2. **When the photo/label packet arrives:** run `bench-gates/tools/O6_V3_PACKET_BRIEF.md` exactly (EXTRACT Sonnet → DERIVE v3 Opus on `offline/o6-v3` → R-O6-3 Opus fresh → FIX Opus → V-O6-3 fresh → state pass → grant request). Expect the first review to fail; it has every time (v1 7B, v2 1B, DR2 apply 3B, addendum 3B, DR3 apply 5B, DR3-2 derivation 7B).
3. **When DR3-3 is answered:** instrument identity → procurement row 14 (record or BUY) + BG-03 S5 evidence capture; if "none", row 14 becomes BUY and the thermal rows stay BLOCKED. Small branch, fresh grant.
4. VM track when the owner reports disk/Fusion/ISO ready (host re-observed 2026-09-06 night: **8.7 GiB free** on the Data volume — down from 17 GB — no Fusion, no ISO, no pwsh): runbook §1.0 → `scripts/vm/host-vm.sh doctor` → bootstrap → snapshot → stage → suite → evidence.
5. Measurement track when the owner returns the CSV (unchanged from r3 §4 item 5; M-31 Wi-Fi bay free volume + the USB-pad edge are the two rows the packet's item 7 / the placement matrix now wait on).
6. Windows x64 session when the owner provides the PC + FT232RL + DS4 (unchanged).
7. Queued doc nits (fresh grant each): `HARDWARE_INVENTORY.md`:96 vs BOM:66 USB port type (resolves with packet item 3); 3d-codex `T_cad_task_spec.md`:14 / `K_printable_support_spec.md` PS-13 "aft" stub wording (flagged by DOCNITS-2; needs the owner's/Director's read of whether the dummy block's stub direction was ever meant to follow the U.FL edge).
8. Keep `W17_OWNER_ACTIONS.md` current; surface the queue only when something becomes newly actionable.

## 5. Dependency graph (delta from r3)
DR3-1 → the thermal characterisation now depends on the **camera bring-up session** (CB5) — not on the first-power staircase — and on DR3-3 for any temperature number · DR3-2 → the pre-solder GAIN-net check (procurement physical action 11) gates soldering the amp strap · DR3-3 → procurement row 14 + BG-03 S5 temperature rows.
Everything else as r3 §5: packet items 1+2 → O-6 v3 S0/S1–S9 · item 3 → S1 ceiling · items 4/5 → S6/S7/S8 or BLOCKED · item 6 → S4 · item 7 → heatsink BUY envelope + M-31 + the USB-pad edge; disk → Fusion → ISO → VM suite; adapter + x64 PC → hotspot; DS4 → ds4_precheck; FT232RL + x64 PC + owner go (D-3) → BG-06 T1 + G-04 Part A; coupon C-1 → sitting → CSV → ingest; shopping + OP-49 evidence (D-2) → BG-01 → … ; FIRST_ACTIVE NO-GO.

## 6. Physical gates — all NOT-EXECUTED; each needs the owner's explicit go
Unchanged. BG-03 remains BLOCKED on A2 + packet items 1–2. Nothing was powered, flashed or connected this session.

## 7. Model policy and the rule that keeps proving itself
Fable = Director/adjudication only. Opus = adversarial review, safety-bearing derivation and fixes. Sonnet = workforce, research, ordinary verification. Every agent names its model;
reviewer ≠ implementer ≠ fresh verifier. This session: the DR3 application failed its first review (5B — the soak was anchored where streaming cannot happen; a continuity check that cannot see a
100 kΩ strap), and the 9 dB derivation failed its first review (7B — every "lower bound" was built from upper-edge inputs and was ~7× high; a fault-diagnosis band that a correctly working amp would
"fail"). Keep the chain mandatory; prefer BLOCKED over a plausible number.
