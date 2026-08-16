# W17 Orchestration Review Packet — 2026-08-16

Dated snapshot for the owner's return. Everything below happened locally in one orchestrated
pass (vision lock → 18-agent audit → Wave-0 truth fixes → five parallel workers). **Nothing was
pushed anywhere; no hardware was powered, flashed, or connected; A2 stays NOT-EXECUTED and
Phase B stays BLOCKED.** Current truth lives in `CURRENT_STATUS.md`; the vision in
`W17_PRODUCT_VISION.md`; the audit in `2026-08-16_vision_audit_report.md`.

## 1. Landed on mains (done, no review needed)

| Repo | Commits | Content |
|---|---|---|
| workspace | `c6d4988`, `981a549`, `be41d8e`, + this pass's status/packet commit | vision doc + policy amendments, audit report, push-state truth reconciliation, status entries |
| `w17-control-fw` | `main` `3f4f9b7` → **`94b3615`** (ff of `docs/comment-drift-fixes`, branch deleted) | stale arm-gate comments now point at `channels::ArmGate`; CLAUDE.md link2 field list → pointer to the protocol doc; unlock plan carries the 2026-08-16 branch-only arbiter amendment |

## 2. Feature branches awaiting your review (merge candidates)

| Repo | Branch (tip) | Content | Tests | Notes |
|---|---|---|---|---|
| `w17-control-fw` | `feat/gimbal-decay-center` (`acce76e`) | decision 11: failsafe pan/tilt decays to center over `gimbal.decay` (default 2000 ms, NVS-tunable, console-wired); Settings blob v1→v2 with authentic-v1 migration tests; steering/ESC/DRS failsafe µs test-pinned unchanged; unlock plan #3/U8 amended (re-review still owed) | 229→253; both builds; delivery ELF console-free | Based on `3f4f9b7`; needs a trivial rebase onto `94b3615` at merge (both touch the unlock plan in different sections) |
| `w17-soundlight-fw` | `feat/audit-wave3-board2` (`1c19260`) | ignition starter-comet + crossfade to armed teal (Cranking/Running-keyed); steady-green DRS tell on the rear-bar edge pixels (brake/hazard always win); NeverConnected: 5 s grace then honest hazard; named synth profiles `v10()` (byte-pinned default) + `v6TurboHybrid()` — no runtime selector (your mechanism decision pending) | 94→107; both builds; link2 byte-untouched | **MERGED 2026-08-17** (MERGE_CLEAN review incl. an independent 5.2M-check priority sweep); branch + worktree removed |
| `w17-ground-station` | `feat/audit-wave2a-giftee` (`53471fd`) | low-battery HUD banner (warn 7.0 V amber / critical 6.6 V red-pulsing, ⚙-tunable, hysteresis, no new IPC); plain-language GRID hints; unsigned NSIS installer job in CI | 1185→1257 incl. review fixup `abaddbd`; proto:check OK; preload pinned at 24 keys | **MERGED + PUSHED 2026-08-17** (review: 3 minor — the critical→ok ratchet skip and the boolean→1 V banner-disarm fixed pre-merge in `abaddbd`; the third is a stale test count in an old commit message, recorded not rewritten). NSIS proof: CI triggered by the push, result pending |
| `w17-mapper` | `w17-audit-wave1` (`c383972`, off `w17-headtrack`) | all 4 confirmed defects fixed: read-cycle load guard (crash → safe load error), subscriber-independent 25 ms eval heartbeat (dead pad neutralizes with zero gRPC subscribers), per-direction hat decode, FORK-NOTICE R1–R16; **`configs/w17-ds4.json`** W17 profile + plausibility lint | 137→175; race green; proto/headintent/hook byte-untouched | Profile: ch1 steer LX · ch3 throttle R2/L2 · ch5 arm TRIANGLE (liveness-gated `and(seq, probe)`) · ch6 DRS SQUARE · ch7/8 gears R1/L1 · ch9/10 pan/tilt right stick · ERS pinned off · mode pinned TRAINING; switch failsafes 172; SHARE/OPTIONS/D-pad test-pinned **unbound** (reserved for head-tracking Alt-C) |

| `w17-control-fw` | `proto/bt-showoff-flagged` (`138a674`, added 2026-08-17) | BT show-off prototype per the committed design (`docs/bt_showoff_design.md` lives ON the branch): pure-logic `lib/btpad` + Bluepad32 HAL, boot-only mode select, same failsafe/arm-gate code reused, TRAINING-capped envelope, settings blob v2 `btpad.*`, quarantined `esp32dev_btshowoff` env (Bluepad32 pinned **3.10.2** — the design's 3.10.3 has no published artifact) | 229→267; all 4 envs build; delivery/sim/tuning ELF: **0 BT symbols** | **Never merges before you read the design** — 11 `OWNER-PENDING(BT-n)` tags in-tree; settings-v2 reconciliation with the decay branch expected at merge |

Recommended merge order once you approve: mapper wave-1 → control-fw decay (rebase) →
soundlight → GS. I can execute any/all on your word — merges stay local until you decide about
pushing (mapper pushes additionally governed by `FORK-NOTICE.md`).

## 3. Drafts awaiting your read (session scratchpad)

- **BT show-off design** — `scratchpad/bt_showoff_design_draft.md`: boot-only mode select
  (recommended: labeled strap switch failing toward normal CRSF mode), same failsafe/arm-gate
  code reused, TRAINING-capped envelope, Bluepad32 pinned to the 3.10.x line (4.x needs a
  newer Arduino core than the repo pins), pairing UX via board-2 lights, **11 enumerated
  decisions with recommendations**.
- **U4 arbiter blueprint** — `scratchpad/u4_arbiter_blueprint.md`: branch plan, Go build-tag
  compile gating (default builds carry zero arbiter object code), one-line choke point before
  `PackChannels`, zero proto changes, fail-closed external calibration, ~48-test matrix.
- **Glovebox booklet draft** — `scratchpad/glovebox_booklet_draft.md`: 7 sections, giftee
  voice, 26 `[TBD-at-bench]` markers; lands in `learning-manual/` after your pass.

## 4. Owner-decision queue

1. **Showcase mode gating** (vision decision 2): one sentence — is it v1.0-blocking ("Core")
   or core-if-cheap? The done bar currently omits it.
2. **Sound-profile selection mechanism**: board-2 NVS console vs a link2 v2 field vs build
   flag. My lean: a link2 v2 field serving profile + the new **volume/quiet-mode** need in one
   mechanism (see 3) — but link2 changes are control-fw-owned and deserve their own mini-design.
3. **Volume control** (new gap the booklet surfaced): the engine has no user-facing volume.
   Quiet mode / volume steps for indoor showpiece use? Rides mechanism from (2).
4. **AGENTS.md files** (untracked in workspace root, control-fw, soundlight, GS; mtime
   2026-08-11): commit, or remove? Not created by any Claude pass.
5. **BT design decisions 1–11** (in the draft; each has a recommendation).
6. **Booklet**: does the car get a name + dedication line; your "ping me" contact line;
   iPhone helmet view in the booklet or your in-person reveal; sound-loudness stance.
7. **W17 profile stance ack**: committed profile supersedes the old hand-build-don't-commit
   stance (gift-kit consequence). Two placeholders need the Windows bench: the physical pad's
   device id and the ELRS TX COM port.
8. **`smoke:electron` on this Mac — diagnosed 2026-08-17 as a machine issue, not a repo
   defect**: a node/npm security layer (`allow-scripts`, not stock npm) kills electron's
   postinstall mid-extraction, leaving partial signature-broken bundles that macOS SIGKILLs;
   something additionally reaps app bundles under `~/Documents`. Canonical boot proof =
   Windows CI (green at `92cd894`; re-proving + first NSIS artifact on the 2026-08-17 push).
   Optional owner-side unlock for local smoke: `npm approve-scripts electron` (a security
   policy — owner's call).
9. **NSIS CI proof**: next push to GS triggers the new installer job; artifact should appear.
10. **U4 / BT execution**: both were **started on your standing approvals** from this
    morning's answers (branch-only / design+prototype). Say stop if you want them paused.

## 5. Conditional waves — BOTH LANDED (2026-08-17); hold in force

- **U4 arbiter** — COMPLETE: `u4-arbiter` @ `93be341`, 4 slices, +5375/−0 over `432a809`.
  One-line seam before `PackChannels`; default builds carry ZERO arbiter object code (nm
  evidence committed); all 10 identity dumps share one SHA-256; proto/headintent/deps/hook
  byte-untouched; 51 new tests green in both build modes; `W17_FIRST_ACTIVE_ARM` runtime
  gate; 9 recorded deviations + the bench-residual list in `docs/u4-branch-README.md`.
  **Never merges/pushes before R1–R16 + bench evidence** (and the tip trips the pre-push
  hook by construction). Review = the R-review, not a normal merge review.
- **BT show-off prototype** — COMPLETE; see its row in §2.
- **HOLD:** no merges, no new waves, nothing further until the owner announces the session
  reset. Next session executes per §7½ + §6.

## 6. Proposed next waves (after your review)

Race-day one-action orchestration in the GS (now unblocked by the committed mapper profile) →
video profiles (CB5 config side) → manual waves (mapper/head-intent track, rebuild chapters,
booklet placement) → showcase-mode design (after decision 1) → sound-profile selector + volume
(after decisions 2/3) → ELRS backup handset procurement + binding doc → GCS-box
contents/wiring/BOM doc.

## 7½. Pre-reset owner answers (2026-08-16, recorded live)

1. **Merge authority — split by risk:** the next session may review + merge
   `feat/audit-wave3-board2` (soundlight) and `feat/audit-wave2a-giftee` (GS) itself;
   `feat/gimbal-decay-center` (control-fw) and `w17-audit-wave1` (mapper) wait for the
   owner's personal diff review. U4/BT branches never merge pre-gate regardless.
2. **Push scope:** GS may be pushed to origin — only repo, only purpose: trigger the Windows
   CI NSIS proof after the local merge. Everything else stays unpushed. *(Executed
   2026-08-17: `92cd894..abaddbd` pushed; CI run pending.)*
3. **Showcase mode:** core-if-cheap — normal wave, NOT on the v1.0 done bar.
4. **Sound mechanism:** link2 v2 field carrying voice profile + volume/quiet level;
   control-fw first (protocol owner), soundlight consumes; volume control is now a
   requirement (decisions queue items 2/3 are thereby answered).

## 7. Standing hardware-gated ledger (unchanged)

A2 execution → Phase B; F12 caliper pair; F20 matrix extension; wheel bench check; pad
GUID/COM pin; GCS-box power budget; real-Windows validation set (hotspot/Pixel, mDNS, NSIS
install, smoke); BT bench gate BT1; FIRST_ACTIVE R-review hardware evidence.
