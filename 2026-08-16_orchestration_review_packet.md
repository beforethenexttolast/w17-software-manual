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
| `w17-soundlight-fw` | `feat/audit-wave3-board2` (`1c19260`) | ignition starter-comet + crossfade to armed teal (Cranking/Running-keyed); steady-green DRS tell on the rear-bar edge pixels (brake/hazard always win); NeverConnected: 5 s grace then honest hazard; named synth profiles `v10()` (byte-pinned default) + `v6TurboHybrid()` — no runtime selector (your mechanism decision pending) | 94→107; both builds; link2 byte-untouched | |
| `w17-ground-station` | `feat/audit-wave2a-giftee` (`53471fd`) | low-battery HUD banner (warn 7.0 V amber / critical 6.6 V red-pulsing, ⚙-tunable, hysteresis, no new IPC); plain-language GRID hints; unsigned NSIS installer job in CI | 1185→1255; proto:check OK; preload pinned at 24 keys | NSIS proof = next CI run (needs a push) |
| `w17-mapper` | `w17-audit-wave1` (`c383972`, off `w17-headtrack`) | all 4 confirmed defects fixed: read-cycle load guard (crash → safe load error), subscriber-independent 25 ms eval heartbeat (dead pad neutralizes with zero gRPC subscribers), per-direction hat decode, FORK-NOTICE R1–R16; **`configs/w17-ds4.json`** W17 profile + plausibility lint | 137→175; race green; proto/headintent/hook byte-untouched | Profile: ch1 steer LX · ch3 throttle R2/L2 · ch5 arm TRIANGLE (liveness-gated `and(seq, probe)`) · ch6 DRS SQUARE · ch7/8 gears R1/L1 · ch9/10 pan/tilt right stick · ERS pinned off · mode pinned TRAINING; switch failsafes 172; SHARE/OPTIONS/D-pad test-pinned **unbound** (reserved for head-tracking Alt-C) |

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
8. **Interactive `smoke:electron` run** (one command in a normal terminal — agent shells
   can't boot Electron; suite itself is 1255-green).
9. **NSIS CI proof**: next push to GS triggers the new installer job; artifact should appear.
10. **U4 / BT execution**: both were **started on your standing approvals** from this
    morning's answers (branch-only / design+prototype). Say stop if you want them paused.

## 5. In flight right now

- **U4 arbiter** implementation agent — branch `u4-arbiter` off `w17-headtrack`, per blueprint;
  flags default-off, fail-closed, never merged/pushed before R1–R16.
- **BT show-off prototype** agent — branch `proto/bt-showoff-flagged` off control-fw `94b3615`;
  design doc committed into the branch, default-off compile flag, quarantined env, native
  tests; recommended options as pending-owner defaults.

## 6. Proposed next waves (after your review)

Race-day one-action orchestration in the GS (now unblocked by the committed mapper profile) →
video profiles (CB5 config side) → manual waves (mapper/head-intent track, rebuild chapters,
booklet placement) → showcase-mode design (after decision 1) → sound-profile selector + volume
(after decisions 2/3) → ELRS backup handset procurement + binding doc → GCS-box
contents/wiring/BOM doc.

## 7. Standing hardware-gated ledger (unchanged)

A2 execution → Phase B; F12 caliper pair; F20 matrix extension; wheel bench check; pad
GUID/COM pin; GCS-box power budget; real-Windows validation set (hotspot/Pixel, mDNS, NSIS
install, smoke); BT bench gate BT1; FIRST_ACTIVE R-review hardware evidence.
