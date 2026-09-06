# NEW_SESSION_HANDOFF — W17 OFFLINE READINESS / BENCH PREPARATION (r2, written 2026-09-06 ~16:30 Kiev by the Fable Director session 8d5a99ff)

Boot without chat history. Read in this order: (1) workspace `CLAUDE.md` (safety 1–7, one session per tree); (2) this file; (3) `W17_OFFLINE_READINESS.md`
(§1a = the D-6 landing table, §3 = workstream rows, §6 = change log); (4) `2026-09-05_offline_decision_round_1.md` (D-1…D-6, verbatim);
(5) `W17_OWNER_ACTIONS.md` — **DECISION ROUND 2 is OPEN** (DR2-1…DR2-14) — and `W17_PROCUREMENT_AND_PHYSICAL_ACTIONS.md`; (6) `bench-gates/INDEX.md`,
`G-INDEX.md`, `MISSING_THRESHOLDS.md`; (7) `_handoff/2026-09-06_O6_derivation_report.md` (v2 after review) + `_handoff/2026-09-06_R-O6_review.md`.
The previous handoff (pre-grant) is preserved verbatim as `_handoff/2026-09-06_NEW_SESSION_HANDOFF_r1_pre-grant.md`.
Everything in (3)–(7) at its CURRENT state lives on workspace branch **program/offline-readiness-r2** — main carries the post-grant state up to f1028ba only.
Session scratchpad (worktrees + reports): `SP2 = /private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/8d5a99ff-1ad4-47ef-bff4-7ad4920c9bce/scratchpad`
(`SP2/reports/`: BG07_item9_build_evidence.md, O6_derivation.md (v1, REJECTED), O6_derivation_v2.md, R-O6.md, V-O6-2.md, V-O6-3.md). If SP2 is gone, every deliverable is in the branches below.

## 0. First commands (read-only)
```
for r in . w17-control-fw w17-soundlight-fw w17-ground-station iPhone_rc w17-mapper w17-3d-codex; do git -C /Users/vitaliykhomenko/Documents/projects/$r worktree list; git -C /Users/vitaliykhomenko/Documents/projects/$r status --short | head -3; done
```
Expected (2026-09-06 16:30): trunks clean, local == origin, at workspace main **f1028ba** · cf **1d17c6b** · sl 7220c08 · GS **809976c** · iPhone 7aaf2cf · mapper w17-headtrack **aa7fb7d** · 3d **8889323**
(these are the post-D-6 trunks; the landing table with CI run ids is `W17_OFFLINE_READINESS.md` §1a). Worktrees under SP2: `wt-ws-r2` (program/offline-readiness-r2),
`wt-ws-d4` (offline/d4-thresholds c428196, merged into r2), `wt-ws-o6` (offline/o6-derivation, merged into r2). Elsewhere: `u4-arbiter` 4e445c9 parked in another
session's scratchpad — read with `git show` only, never checkout/merge/push. The prior session's fifteen merged worktrees were removed 2026-09-06 (branches kept).
If a trunk moved, another session landed something: re-read `CURRENT_STATUS.md` and `W17_OFFLINE_READINESS.md` before anything else.

## 1. Branch state — nothing pushed since the D-6 grant was consumed; PUSH GRANT CLOSED
| repo | branch | tip | worktree | chain | content |
|---|---|---|---|---|---|
| workspace | **program/offline-readiness-r2** | `git rev-parse --short program/offline-readiness-r2` is authoritative | SP2/wt-ws-r2 | integrates the two rows below + this session's state commits | state files (readiness §1a/§3/§6, owner queue with DR2, procurement DR2 note), this handoff, the two `_handoff` snapshots |
| workspace | offline/d4-thresholds | c428196 | SP2/wt-ws-d4 | D4-APPLY (Sonnet) → V-D4 FIX_REQUIRED (1: G-02's command wired the 150 ms *desired* figure as a FAIL bound) → FIX (Director, exit codes proven on synthetic captures) → V-D4-2 PASS | D-4 rulings applied: G-02 (O-1), G-04 (O-2…O-5), BG-08 (O-7, shipped 110 stated), BG-03 + tools T11 (O-6 policy), MISSING_THRESHOLDS §1/§4 |
| workspace | offline/o6-derivation | 56a563e | SP2/wt-ws-o6 | O6 (Opus) → apply (Sonnet) → V-O6 transcription (4 staleness) + **R-O6 adversarial (Opus) FIX_REQUIRED 7 BLOCKING / 11 NON-BLOCKING** → FIX (Opus, v2) → V-O6-2 (Opus) FIX_REQUIRED 1 BLOCKING (P(5) must be the rated 1800 mA, not the 1510 mA RF-test peak) + 8 → FIX-2 (Opus) → V-O6-3 (Opus) FIX_REQUIRED 0 BLOCKING / 2 NON-BLOCKING (two `_handoff` snapshot-note slips) → FIX-3 (Director, 2 lines) → **V-O6-4 (Sonnet, scoped) PASS — final tip 56a563e, merged into r2** | BG-03 `### Starting current limits (O-6 derivation)` inside *Required equipment*; tools T11–T13 replaced, L11–L15 added; MISSING_THRESHOLDS/INDEX/BG-04 notes; `_handoff/` report v2 + review. **All 15 substeps BLOCKED** on DR2-3/DR2-4; no amperage invented |

## 2. The grant being requested (DR2-1) — exact scope, when the owner grants it
Scope = **program/offline-readiness-r2 → workspace main**, at the tip named in the grant request, nothing else; no nested-repo push. Landing rule: in the MAIN checkout only,
after `git worktree list` + `git branch --show-current` + a HEAD re-check: `git merge --ff-only program/offline-readiness-r2` (or `--no-ff` if main moved) →
`scripts/check_readiness_runbook_links.sh` exit 0 AND `--workspace-root /Users/vitaliykhomenko/Documents/projects` exit 0 → push → record in `CURRENT_STATUS.md` top entry +
`W17_OFFLINE_READINESS.md` §6 → say the grant is CONSUMED. If the branch content changes materially after the request, independently verify the changed portion first (owner rule, D-6).

## 3. Rulings in force
D-1…D-5 as in `2026-09-05_offline_decision_round_1.md` (summary: readiness §4a). **D-6 EXECUTED and CONSUMED 2026-09-06** (readiness §1a). **Decision Round 2 — OPEN**
(`W17_OWNER_ACTIONS.md`): DR2-1 fresh grant (above) · DR2-2 ratify margin policy M-PEAK (manufacturer Max/peak, LED model upper bound, no percentage) · DR2-3 bench PSU
identity + minimum settable current limit · DR2-4 UBEC make/model + BEC#2 output voltage (5 or 6 V) · DR2-5 PSU-first energisation + ESC feed separation (A2-S6 re-run if so) ·
DR2-6 S1/S2 ramp ceilings (read the MH-ET regulator marking; else rule numbers) · DR2-7 Wi-Fi RF mode (allowance = rated 1800 mA until named) · DR2-8 `sound.volume` + 4 Ω ·
DR2-9 blower label · DR2-10 MG90S branding / rule S7–S8 ceiling · DR2-11 rule the constant-current duration criterion at a connect · DR2-12 withdrawn (DS3235SG identity is on
the datasheet photo) · DR2-13 O-7 shipping question (Director recommends keeping shipped 110 until BG-08) · DR2-14 Wi-Fi heatsink 28×28 fitted vs ≥ 32×32 recommended.
Plus five no-power label checks (owner file, AT THE CAR — NO POWER).

## 4. Next autonomous actions (in order; none powered)
1. **When DR2-1 is granted:** land r2 per §2. Until then, keep committing state to r2; never to main.
2. **When DR2-3 + DR2-4 are answered:** O-6 v3 on a new branch — S0 gets the PSU's minimum settable limit; the pack-side form `I_pack ≤ 5 A × V_rail / (V_pack × η)` gets η from the UBEC datasheet; S9 selects the servo column from BEC#2's set voltage; every remaining BLOCKED row is re-examined against the other DR2 answers. Mandatory chain: Opus derive → Opus adversarial review → fix → fresh re-verify (this session needed two fix loops on a safety artifact; assume the third version will still fail its first review).
3. **When DR2-13 is ruled 180-now:** soundlight branch changing `LightRenderer.hpp:152` 110 → 180 (build must still pass `valid()`: 540 ≤ 900), native tests, review, fresh grant. If ruled keep-110: nothing to do until BG-08.
4. **Queued doc nits (one small branch, fresh grant):** cf `.github/workflows/ci.yml` comment "356/356" → 360; tools file :107 "How to derive T1–T12" → T13; `HARDWARE_INVENTORY.md`:96 USB-C vs `bill_of_materials_v2.md`:66 micro-USB (needs the owner's look); BG-03:40 "PSU or battery" vs `D8_BENCH_BRINGUP.md`:55 battery-only (resolves with DR2-5); `bench-gates/INDEX.md` "run the tools from the branch's own worktree" sentence is stale now that bench-gates/ is on main.
5. VM track when the owner reports disk/Fusion/ISO ready: runbook §1.0 → `scripts/vm/host-vm.sh doctor` → bootstrap → snapshot → stage → suite (hardware gates off) → evidence.
6. Measurement track when the owner returns the CSV: `w17-3d-codex/11_cad/tools/ingest_measurements.py --dry-run <csv>` → review → `--apply` → render → C-2/C-3 → fit ladder.
7. Windows x64 session when the owner provides the PC + FT232RL + DS4: `run-all.ps1 -HardwareExpected -ElrsVidPid 0403:6001`, 31 under Windows PowerShell 5.1, `netsh wlan show hostednetwork`; G-03; G-04 Part A only after the owner's explicit go per D-3. The DS4 macOS pre-check is on the mapper trunk now: `w17-mapper/tools/host-precheck/ds4_precheck.sh`.
8. Keep `W17_OWNER_ACTIONS.md` current; surface the queue only when something becomes newly actionable.

## 5. Dependency graph (delta from r1: first power now also needs Decision Round 2)
DR2-3 (PSU) + DR2-4 (UBEC, BEC#2 volts) → O-6 v3 (S0/S1 limits, pack-side conversion) → with DR2-2/5/6/10/11 ruled and DR2-14 decided → BG-03 becomes *runnable once A2 closes and Phase B opens*.
Everything else unchanged: disk → Fusion → ISO → VM suite (never physical for hotspot); adapter + x64 PC → hotspot + giftee PC re-check (D-1); DS4 → ds4_precheck (now) → x64 PC → G-03;
FT232RL + x64 PC + owner go (D-3) → BG-06 T1 + G-04 Part A; coupon C-1 → measurement sitting → CSV → ingest → coupons → fit prints; shopping + OP-49 evidence (D-2) → BG-01 → BG-02 → BG-03 → BG-04 → …; FIRST_ACTIVE NO-GO.

## 6. Physical gates — all NOT-EXECUTED; each needs the owner's explicit go
BG-01 A2 staged (no power) · BG-02 A2 closure · BG-03 Phase B first power (BLOCKED: A2 + Decision Round 2) · BG-04 D8 · BG-05 coordinated flash · BG-06 CRSF on the wire (live-TX gated, D-3) ·
BG-07 BT1 (item 9 build-only evidence collected 2026-09-06: both builds ok, delivery ELF clean, 360/360 native) · BG-08 halo (cap 180) · G-01 FIRST_ACTIVE (NO-GO) · G-02 phone latency (150 desired / 200 max, exit code asserts 200) ·
G-03 Windows hot-plug (x64 PC + DS4) · G-04 race-day link (x64 PC + FT232RL; D-3; 1000 ms headroom, 2000 ms spread, five runs, STOP lag ≤ 250 ms).

## 7. Model policy and the rule that keeps proving itself
Fable = Director/adjudication only. Opus = adversarial review, safety-bearing verification and fixes, difficult derivation. Sonnet = workforce. Every agent names its model.
This session: the D-4 application failed its first verify (1 defect found only by running the tool); the O-6 derivation failed its first adversarial review on safety direction
(7 BLOCKING) and its fix failed the re-verify on one residual (the Wi-Fi allowance). Keep review + independent re-verify mandatory; prefer BLOCKED over a plausible number.
