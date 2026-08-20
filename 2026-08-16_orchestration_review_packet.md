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
| `w17-control-fw` | `feat/gimbal-decay-center` (`acce76e`) | decision 11: failsafe pan/tilt decays to center over `gimbal.decay` (default 2000 ms, NVS-tunable, console-wired); Settings blob v1→v2 with authentic-v1 migration tests; steering/ESC/DRS failsafe µs test-pinned unchanged; unlock plan #3/U8 amended (re-review still owed) | 229→254; both builds; delivery ELF console-free | **MERGED 2026-08-17** after delegated review (2 minors fixed pre-merge: three live docs still teaching hold-last; a re-entry regression pin) + owner digest delivered |
| `w17-soundlight-fw` | `feat/audit-wave3-board2` (`1c19260`) | ignition starter-comet + crossfade to armed teal (Cranking/Running-keyed); steady-green DRS tell on the rear-bar edge pixels (brake/hazard always win); NeverConnected: 5 s grace then honest hazard; named synth profiles `v10()` (byte-pinned default) + `v6TurboHybrid()` — no runtime selector (your mechanism decision pending) | 94→107; both builds; link2 byte-untouched | **MERGED 2026-08-17** (MERGE_CLEAN review incl. an independent 5.2M-check priority sweep); branch + worktree removed |
| `w17-ground-station` | `feat/audit-wave2a-giftee` (`53471fd`) | low-battery HUD banner (warn 7.0 V amber / critical 6.6 V red-pulsing, ⚙-tunable, hysteresis, no new IPC); plain-language GRID hints; unsigned NSIS installer job in CI | 1185→1257 incl. review fixup `abaddbd`; proto:check OK; preload pinned at 24 keys | **MERGED + PUSHED 2026-08-17** (review: 3 minor — the critical→ok ratchet skip and the boolean→1 V banner-disarm fixed pre-merge in `abaddbd`; the third is a stale test count in an old commit message, recorded not rewritten). NSIS proof: CI triggered by the push, result pending |
| `w17-mapper` | `w17-audit-wave1` (`c383972`, off `w17-headtrack`) | all 4 confirmed defects fixed: read-cycle load guard (crash → safe load error), subscriber-independent 25 ms eval heartbeat (dead pad neutralizes with zero gRPC subscribers), per-direction hat decode, FORK-NOTICE R1–R16; **`configs/w17-ds4.json`** W17 profile + plausibility lint | 137→175; race green; proto/headintent/hook byte-untouched | Profile: ch1 steer LX · ch3 throttle R2/L2 · ch5 arm TRIANGLE (liveness-gated `and(seq, probe)`) · ch6 DRS SQUARE · ch7/8 gears R1/L1 · ch9/10 pan/tilt right stick · ERS pinned off · mode pinned TRAINING; switch failsafes 172; SHARE/OPTIONS/D-pad test-pinned **unbound** (reserved for head-tracking Alt-C). **MERGED 2026-08-17** (`w17-headtrack` = `9cb501e`) after delegated review found 2 blockers — the HIDAPI/raw-HID button-layer mismatch (gear-down would have landed on reserved SHARE) and silent re-arm on pad reconnect — both fixed (buttons renumbered to driver truth; re-arm now requires a fresh deliberate press) and independently re-verified. The old hand-build-don't-commit profile stance is formally superseded. |

| `w17-control-fw` | `proto/bt-showoff-flagged` (`138a674`, added 2026-08-17) | BT show-off prototype per the committed design (`docs/bt_showoff_design.md` lives ON the branch): pure-logic `lib/btpad` + Bluepad32 HAL, boot-only mode select, same failsafe/arm-gate code reused, TRAINING-capped envelope, settings blob v2 `btpad.*`, quarantined `esp32dev_btshowoff` env (Bluepad32 pinned **3.10.2** — the design's 3.10.3 has no published artifact) | 229→267; all 4 envs build; delivery/sim/tuning ELF: **0 BT symbols** | **MERGED 2026-08-17** (`d33dfdc`) after: all 11 decisions owner-ratified (tags → OWNER-DECIDED), 2 review minors fixed (connect-baseline seed; the `esp32dev_simbt` scripted-session env), btpad folded as the sixth blob-v2 group, and the three-mode boot unification (DRIVE/SHOWCASE/BT_SOLO, one selector seam; 315/315) — each step independently verified. NEW owner decision: **D3-SHOW-SELECT** (SP3T strap proposal; showcase = bench-selectable until decided) |

| `w17-ground-station` | `feat/video-profiles` | DRIVE/SHOWPIECE video profiles (DRIVE = today, proven at the seams) | 1324 | **MERGED 2026-08-17** after review (2 minor fixes pre-merge) |
| `w17-ground-station` | `feat/race-day-orchestration` | one-press bring-up: hotspot → mapper (managed child, `W17_*` env scrubbed, argv whitelist) → phone link; preload pin 24→28 deliberate | 1435 (67 files) | **MERGED 2026-08-17** after review found **2 blockers** (spawn-failure wedge; env bypass of the whitelist) — fixed and independently re-verified |
| `w17-control-fw` | `feat/link2-v2-voice-volume` (`dfd0f23`) | link2 protocol v2: 16-byte frame, version byte, soundProfile (V10 fallback) + volume (0–100, default 80); NVS `sound.*` + console keys; golden frame pinned in both repos | 229→239; both builds | **MERGED 2026-08-17** (cf main `2d146dc`) after MERGE_CLEAN review (independent golden-frame recomputation) + a verified unification pass: ONE settings blob v2 (steering/gearbox/battery/gimbalDecay/sound), and it fixed main's own settingsEqual gap in passing |
| `w17-soundlight-fw` | `feat/link2-v2-consume` (`37ad050`) | codec re-synced verbatim (drift check exit 0); wire-selected voice; integer volume at final gain (0 = true silence, 100 = transparent); failsafe-over-volume proven | 107→118; both builds | **MERGED 2026-08-17** (sl main `ecfec95`) — the coordinated-flash package (voice + volume + both reserved mode bits) is complete on both trunks; both boards flash together at adoption |

Remaining merge order once you approve: mapper `w17-audit-wave1` → control-fw
`feat/gimbal-decay-center` (trivial rebase onto `9f00f2e`) → the link2-v2 pair as one unit
(after your settings-v2 reconciliation call). Merges stay local; pushing is yours (mapper
pushes additionally governed by `FORK-NOTICE.md`).

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
    *(Both landed complete — see §5.)*
11. **Showcase mode D1–D9** (2026-08-17): design draft in
    `_handoff/2026-08-17_showcase_mode_design_draft.md`, each with a recommendation; decide
    **D2 together with the link2-v2 review and BT-7** so the flag rides the one coordinated
    flash.
12. **GCS procurement set** (2026-08-17): 7 questions in `w17-gcs-box-guide.md` /
    `w17-elrs-backup-handset.md` — headliners: which ELRS TX variant is actually on hand,
    the missing USB hub, the 2.4-vs-5.8 GHz hotspot/camera wrinkle.
13. **Giftee volume/voice setter** (2026-08-17): link2-v2 makes both wire-borne, but the
    only setter today is the tuning console over USB — pick the giftee-facing mechanism.
    *(Answered same day — see 17.)*

**Second live Q&A (2026-08-17, owner answers):**

14. **Firmware merge reviews DELEGATED** — adversarial review agents + orchestrator merge
    for decay, mapper wave-1, and the link2-v2 pair; compact findings digests replace the
    owner's raw-diff reads. (Supersedes the §7½ item-1 split for these branches.)
15. **Wire decision:** v2 gains a `modeFlags` byte (bit0 showcase, bit1 awaitingController,
    6 spare); flags bit 7 stays reserved; one coordinated flash covers both future modes
    (showcase D2 + BT-7 resolved jointly).
16. **Showcase D1–D9 accepted as recommended** — the build wave starts after the link2-v2
    pair merges.
17. **Volume setter: gift-time preset** (default 80, owner-retunable over USB); an in-drive
    setter is a post-v1.0 question.

**Third live Q&A (2026-08-17, owner answers):**

18. **AGENTS.md: fix + commit** — the 2026-08-11 port's ownership inversion corrected in
    all four files (Codex = guest in Claude-owned repos). *Plus an ownership-expansion ask
    from the owner: with Max x20, Claude should "take over those parts of the project and
    orchestrate the implementation" — exact scope (iPhone_rc? print/mechanical? repo
    location?) clarification pending.*
19. **BT decisions: ALL settled.** Recommendations accepted with one owner simplification:
    **BT mode is car-control only — the camera is OFF** ("a simple mode for quick showing
    off"), which makes BT-9's fixed-center gimbal moot-by-off; BT-7 rides modeFlags bit1;
    BT-8's 3.10.2 pin stands proven. The BT branch's design doc gets a camera-off
    amendment when next touched; the branch now queues for delegated adversarial review +
    merge under the expanded delegation (veto if unintended).
20. **5.8 GHz adapter: BUY** — owner asked for a reminder + spec; spec lives in the GCS
    guide's 2026-08-17 addendum; this is the top of the procurement list.
21. **Handset: gamepad-style ELRS** (LiteRadio-class).

## 5. Pipeline state (FINAL, 2026-08-17 late)

- **ALL BUILD/REVIEW PIPELINES CLOSED.** Every wave launched in this orchestration pass is
  merged to its trunk (§2 rows + CURRENT_STATUS newest entry). No agents in flight.
- **U4 arbiter** — parked COMPLETE on `u4-arbiter` @ `93be341` (off the pre-merge mapper
  base; trivial rebase at R-review time). Never merges/pushes before R1–R16 + bench
  evidence — hook-enforced; its review is the R-review, not a merge review.
- **codex-wip-vr-calibration** (iPhone_rc) — the inherited Codex WIP preserved verbatim as
  two commits; owner reviews at leisure.
- Backup refs `backup/bt-pre-rebase*-20260817` (control-fw) preserve the BT branch's
  pre-rebase states as review evidence; prunable when the owner is done with them.

## 6. Next universe (updated 2026-08-17 — Phase-C plateau)

Everything in this section's original list is DONE (merged, or on a review branch). What
remains, by gate:
- **(a) Owner reviews & decisions:** the four firmware merges (§2: decay, mapper wave-1,
  link2-v2 pair), U4 R-review, BT's 11 decisions, showcase D1–D9 (draft in `_handoff/`; D2
  jointly with link2-v2 + BT-7), the booklet's 3 questions, `AGENTS.md`, the GCS guides' 7
  procurement questions, the giftee volume/voice setter, ferrying the Codex handoff file.
- **(b) Implementation those answers unlock:** showcase-mode build (per the accepted D-set),
  the sound-setter UX, the settings-blob-v2 reconciliation at the firmware merges.
- **(c) Bench/hardware-gated:** the §7 ledger, unchanged — A2 → Phase B before anything
  powers on.
- **(d) Codex-side:** DRS flap mechanics, GCS-box mechanics, shell/charge-flap work, and the
  three asks in `_handoff/2026-08-17_iphone_side_sync.md`. *(Asks 1–2 discharged in-house
  2026-08-17 after the iPhone_rc transfer: acceptance policy canonical + mirrored 5/5;
  banner parity merged. Ask 3 = the booklet question, still the owner's.)*
- **(e) Review-observation micro-backlog — CLEARED 2026-08-20** (3 builders → adversarial
  reviews → guarded ff merges; sl `a80adb0`, GS `945977e`, cf `cd9988b`): hudDiscovery
  comments ✅; FSM single-frame ~340 ms Active window ✅ (link proof: ≥150 ms + ≥5 frame
  ticks, gap >60 ms discards; **D4 amendment owner-ratified 2026-08-20** — everLinkedThisBoot
  latches on the first PROVEN link); race-day quit honesty prompt ✅; low-battery replay
  demo ✅ (`npm run demo:low-battery`); limiter `95` literal → `limiterThrottlePct` ✅.
  Still open by design: GS-vs-iPhone dead-stream banner-policy divergence (laptop holds a
  dimmed banner, phone clears with placeholders — owner someday-call).
  **New drift-watch notes from this wave's reviews (all non-blocking):** sl
  `test_enginesim/test_main.cpp:253-254` locally duplicate the defaults `blipMs=130` /
  `overrunMs=900` (same drift pattern, different literals); sl negative-throttle safety
  silently rides `uint16_t`→int promotion (widening `limiterThrottlePct` to `uint32_t`
  would flip semantics for negative throttle); sl `EngineSimConfig` valid() new bounds not
  negatively tested and no definition-site static_assert (enforcement lives in main.cpp:37,
  pre-existing idiom); cf link-proof qualifying floor is a sustained ~16.7 Hz source (an
  honest link; noise can't plausibly fake it); cf shared-FSM means a completed *pad* proof
  in BT_SOLO also sets the everLinked latch (harmless — only showcase reads it, boot mode
  fixed per boot); GS quit dialog defaults to QUIT AND STOP on Enter (house style, deliberate).

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
   requirement (decisions queue items 2/3 are thereby answered). *(Implemented 2026-08-17
   as the link2-v2 branch pair — §2; awaiting owner review.)*
5½. **D4 amendment ratified (owner, 2026-08-20, via in-session question):** the D4
   showcase wire-failsafe term `everLinkedThisBoot` latches on the first PROVEN link
   (the new 5-frame/150 ms proof), no longer on the first lone CRC-valid frame. Reviewer
   ruling that prompted the ask: "faithful to D4's plain meaning, but meaning-adjacent —
   ratify, don't merge silently." Ratified as built; merged in cf `cd9988b`.

5. *(Orchestrator extension, flagged for owner ack.)* The split-by-risk rule was applied to
   branches created after these answers: GS/docs branches get adversarial review +
   orchestrator merge (video-profiles, race-day, manual wave, handoff snapshot — all merged
   so); firmware/mapper branches join the owner queue (the link2-v2 pair). Say the word to
   tighten or loosen either direction.

## 7. Standing hardware-gated ledger (unchanged)

A2 execution → Phase B; F12 caliper pair; F20 matrix extension; wheel bench check; pad
GUID/COM pin; GCS-box power budget; real-Windows validation set (hotspot/Pixel, mDNS, NSIS
install, smoke); BT bench gate BT1; FIRST_ACTIVE R-review hardware evidence.
