# W17 Vision Audit Report — 2026-08-16

> Dated point-in-time snapshot (18-agent orchestrated audit, run 2026-08-16 against
> `W17_PRODUCT_VISION.md`). Synthesized from 4 suite runs + 6 vision auditors + adversarial
> verification. Suite commits audited: control-fw `3f4f9b7`, soundlight `5919685`,
> ground-station `92cd894`, mapper `432a809` (w17-headtrack). Not a status file — current
> truth lives in `CURRENT_STATUS.md`; the vision lives in `W17_PRODUCT_VISION.md`.

## 1. Executive summary

The workspace is healthy where it matters most: all seven safety boundaries hold with zero drift (cross-repo audit returned an empty gap list), and every runnable suite is green — w17-control-fw 229/229 native plus both ESP32 builds, w17-soundlight-fw 94/94 plus both builds, ground station 1185/1185 vitest plus proto:check, w17-mapper build/vet/test/race clean. The GS smoke:electron 0/4 is environment-blocked in the agent shell (byte-identical dist; the user's own binary wedges too), not a repo defect. Six defects were CONFIRMED, all medium: four in w17-mapper (switch channels latch on gamepad dropout; default endpoints 0/1984 mean a default config cannot arm; a droppable device-removal alert can leave stale values transmitting; unguarded InputRead recursion crashes the process) and two in workspace docs asserting push states git contradicts. The dominant vision gap is the giftee-operability cluster (done-bar 8): no saved mapper profile, unproven installer, no low-battery HUD banner, hobbyist wording, no glovebox booklet, no one-action bring-up. Board-2 decision-16 additions (ignition animation, DRS tell) and video profiles are the other concrete misses. All hardware items remain correctly gate-blocked.

## 2. Vision gap matrix

Statuses merged from all six auditors; no material inter-auditor disagreements were found (entries were complementary). The two nuances: decision 8 is MISSING **by design** (post-v1.0), and decision 2's ambiguity is inside the vision doc itself (labeled "Core" but absent from the done bar — workspace auditor, low finding 9).

### Decisions 1–18

| # | Topic | Status | Next action |
|---|---|---|---|
| 1 | Done bar definition | PARTIAL (aggregate) | Track via done-bar rows below; no action on the definition itself. |
| 2 | Showcase mode | MISSING (both boards; `esp32dev_sim` proves the sound/light half on bench builds only) | Owner one-sentence gating call (Core vs core-if-cheap), then design the demo-state mechanism (board-1 disarmed feed vs board-2 trigger). |
| 3 | Venue (indoor + smooth outdoor) | BLOCKED_BY_GATE | Provable only in Phase-B driving; software prerequisites (gentle tunable defaults) are in place. |
| 4 | Speed tunable, gentle defaults | DONE (control-fw gear tables + NVS console) | Optional: make TRAINING-mode throttle shape NVS-tunable (today compile-time fixed, main.cpp:89). |
| 5 | Driver figure vs cockpit cam | BLOCKED_BY_GATE | Revisit at first cockpit test footage, per the vision's own open point. |
| 6 | FPV screen: laptop + iPhone per session | DONE (GS side: HUD, W2 send-only bridge, per-session GARAGE choice; iPhone app is Codex territory) | Real-device mDNS verification on the Windows bench (recorded validation debt). |
| 7 | Video profiles (drive / showpiece) | MISSING (single fixed mediamtx path, WHEP pinned to min latency) | CB5 wave: two presets through camera → mediamtx → WHEP plus a settings knob. |
| 8 | Recording/replay | MISSING by design (post-v1.0) | None for v1.0. |
| 9 | Head tracking | BLOCKED_BY_GATE (log-only chain DONE, live-validated, byte-identity dead-end proof green; arbiter deliberately design-only, FIRST_ACTIVE = NO-GO) | Conditional wave CW-A: branch-only U4 arbiter per the 2026-08-16 owner amendment; R1–R16 + bench evidence remain the gate. |
| 10 | Driving input (DualShock v1.0; wheel later) | PARTIAL (mapper maps raw SDL joysticks so wheels should enumerate; but no shippable profile exists and a default config cannot arm; hats direction-blind) | Ship the W17 profile (Wave 1); wheel bench check stays hardware-gated; decode hat directions before the D-pad deadman validation. |
| 11 | Gimbal on link loss: decay to center | PARTIAL (today deliberate hold-last, main.cpp:580-584; no decay shaping exists) | Implement decay-to-center in control-fw, carrying the formal re-review owed on unlock-plan decision #3/U8. |
| 12 | No-laptop options | MISSING (ELRS handset not procured/bound/documented; BT show-off not started) | Procure + bind + document the ELRS backup handset; BT show-off as conditional wave CW-B. |
| 13 | Charging UX (flap, interlock, state light) | BLOCKED_BY_GATE (hardware build; PDB guide already carries the interlock design) | Execute at build time under gates; reference the loose PDB guide from the manual. |
| 14 | DRS functional in v1.0 | PARTIAL (firmware channel, failsafe-closed, link2 bit all DONE and tested; flap mechanics = Codex dependency; board-2 tell missing) | Codex flap mechanics; soundlight DRS-open tell (Wave 3); bench proof gate-blocked. |
| 15 | Engine voice: V10 default, selectable profiles | PARTIAL (V10 default DONE, synth fully parameterized so V6 fits; no alternate profile defined, no selection mechanism anywhere) | Owner picks the mechanism (board-2 NVS vs link2 v2 vs build flag), then add the V6-hybrid config pair. |
| 16 | Lights: current set + ignition animation + DRS tell | PARTIAL (indicators steering-driven DONE, low-batt pulse DONE; ignition animation and DRS tell MISSING — plug-in points verified to exist) | Board-2 compositor wave: plumb ignition state into lights; consume the drsOpen bit. |
| 17 | Manual: stranger-rebuild + teaching depth | PARTIAL (teaching depth strong for the three original repos; zero mapper/head-intent coverage; no rebuild-track chapters; progress stale since 2026-07-09) | Manual waves: mapper track, rebuild chapters, refresh vs current code. |
| 18 | Publicness after finalization + gifting | DONE as policy (GPL mapper fork already public) | Nothing until gifting; fix the stale "push disabled" map row (defect 6). |

### Done-bar items 1–8

| # | Item | Status | Next action |
|---|---|---|---|
| 1 | Gentle FPV driving | BLOCKED_BY_GATE (firmware ready and 229/229 tested; driving evidence needs A2/Phase B) | Execute A2 when the owner opens the bench. |
| 2 | Showpiece finish (shell, cassette) | BLOCKED_BY_GATE (build-time mechanical; largely Codex territory; outside this audit's software scope) | Build per the recorded packaging architecture. |
| 3 | Sound + light fully running | PARTIAL (core stack DONE at 94/94; decision-16 additions and profile selector outstanding) | Wave 3 board-2 features. |
| 4 | Onboard USB-C charging | BLOCKED_BY_GATE (hardware; interlock designed in the PDB guide) | Build-time under gates. |
| 5 | Functional actuated DRS | PARTIAL (firmware half DONE; mechanics Codex; hardware unproven) | Track the Codex dependency; bench under gate. |
| 6 | Both HUDs usable per session | DONE (software side; W2 bridge send-only and test-pinned) | Windows-bench validation of mDNS + smoke on real hardware. |
| 7 | Active head-tracked gimbal | BLOCKED_BY_GATE (FIRST_ACTIVE NO-GO, hardware-evidence blockers) | Conditional CW-A arbiter branch; gate semantics unchanged. |
| 8 | Giftee-operable ("user friendly af") | MISSING (booklet, saved profile, proven installer, low-batt banner, plain wording, one-action bring-up all open) | The Phase-C giftee cluster: Waves 1–2 plus the booklet in Wave 4. |

## 3. Confirmed defects, ranked

All six verified findings returned verdict CONFIRMED. There are **no UNCERTAIN findings and no unverified overflow**.

**CONFIRMED (medium):**

1. **w17-mapper — switch channels latch on gamepad dropout (RESIDUAL A).** `pkg/config/input_channel.go:117-121` — Failsafe defaults to 992, which decodes inside the firmware ±250 hysteresis band, so on dropout arm/DRS/gear stay latched and resume armed on reconnect. Fix: carry `failsafe: 172` on the six decodeSwitch channels in the W17 profile, plus a profile lint asserting it.
2. **w17-mapper — droppable neutralization tick / no eval heartbeat (RESIDUAL C).** `pkg/devices/controller.go:106-114` — the removal alert is a non-blocking send on an unbuffered channel with competing receivers, and all 25 ms tickers live inside streaming RPCs; with no gRPC subscriber a dropped alert leaves stale values transmitting at full rate. Fix (reviewed slice): subscriber-independent eval heartbeat, or a buffered/retried removal alert.
3. **w17-mapper — default endpoints 0/1984 sit outside the firmware plausibility band (100/1900): a default config cannot arm.** `pkg/config/input_channel.go:97-105`, `pkg/util/util.go:21-22`. Fix: bake crsf_min 172 / crsf_max 1811 into the W17 profile; add a load-time band warning.
4. **w17-mapper — InputRead._Eval unguarded recursion: a schema-valid read cycle kills the process by stack overflow** (empirically demonstrated; consequence is a failsafe stop, not runaway). `pkg/config/input_read.go:31-44`. Fix: visited-set or depth bound plus a config-load cycle check.
5. **Workspace — CURRENT_STATUS.md checkpoints assert push states git contradicts** (control-fw :795, mapper :797, 3d-codex :800, header :44-59 "ahead 31 UNPUSHED" vs actual ahead 2). Fix: one reconciliation entry recording the F17/F18 merge to 3f4f9b7 and the completed pushes; note the ahead-count moved 1→2 during the audit as a later commit landed.
6. **Workspace — WORKSPACE_MAP.md:22 still claims mapper "Push disabled until owner approves a remote"**, false since 2026-07-25 (public fork, push URL enabled, fully pushed); contradicted twice by CURRENT_STATUS itself. Fix: replace with the current control (tracked pre-push hook + FORK-NOTICE push-review rule).

**UNCERTAIN:** none.

**Low findings (10):**

7. w17-control-fw — `CLAUDE.md:37-41` link2 summary omits 4 of 12 payload fields; extend or point at `docs/link2_protocol.md`.
8. w17-control-fw — stale "arm gate not yet built" comments in `FailsafeStateMachine.hpp:50-54` and `EscOutput.hpp:30-33`; point both at the implemented `channels::ArmGate`.
9. w17-soundlight-fw — `LightRenderer.cpp:70-81` NeverConnected shows a calm teal breathe forever (a pre-first-frame wire cut never escalates to hazard); the :67-69 comment is factually wrong. Fix: escalate to hazard after a short grace window or write a protocol-doc exception; correct the comment either way.
10. w17-ground-station — the giftee NSIS installer has never been built: CI runs `--dir` only (`ci.yml:51`) while the vision reads as installer-proven. Fix: add an unsigned NSIS build + artifact upload; correct the vision sentence.
11. w17-ground-station — GRID failure hints use hobbyist vocabulary (`shared/checklist.mjs:18,29,41`), off the operator-model bar. Fix: plain-language wording pass.
12. w17-mapper — `FORK-NOTICE.md:62,67` cites "R1–R14" where the checklist is R1–R16; a literal reviewer could pass the gate without R15/R16. Fix: two-line edit.
13. w17-mapper — hat inputs are direction-blind (`pkg/devices/device.go:45-47`), breaking the recorded D-pad-DOWN deadman plan. Fix: decode the hat bitmask per direction before Alt-C binding validation.
14. Workspace — CURRENT_STATUS.md:795 claims branch `docs/a2-revision-pass` still exists; it has been deleted. Fold into the reconciliation entry.
15. Workspace — vision doc decision 2 says "Core" but the done bar omits showcase mode; needs one owner sentence.
16. Workspace — vision doc :120-122 cites JoystickOpen in the wrong file (it is `pkg/devices/util.go:27`); correct the citation.

## 4. Phase-C implementation plan

Ground rules baked in: hardware gates are absolute — nothing in these waves powers or flashes anything; branch-per-wave in worktrees **outside** the workspace per the concurrent-sessions rule; mapper branches fork off `w17-headtrack`; iPhone_rc receives handoff docs only.

**Wave 0 — truth and hygiene (workspace, mapper, control-fw; 1 short session each).**
- Workspace `docs/status-reconciliation-2026-08`: CURRENT_STATUS reconciliation entry (defects 5, 14; 224→229 note; AGENTS.md commit-or-remove decision), WORKSPACE_MAP mapper row (defect 6), vision-doc citation fix (16) and the owner's decision-2 gating sentence (15).
- w17-mapper `docs/fork-notice-r16`: R1–R14 → R1–R16 (defect 12).
- w17-control-fw `docs/comment-drift-fixes`: stale safety-header comments + CLAUDE.md link2 summary (defects 7, 8).

**Wave 1 — mapper config + robustness (the giftee-critical unblocking wave).**
- `feat/w17-profile`: the shipped W17 profile (crsf 172/1811 per channel, failsafe 172 on all six decodeSwitch channels, device binding) plus a load-time profile lint (band check + switch-failsafe check) — closes defects 1 and 3. Confirm with the owner that the old "hand-build, don't commit" stance is superseded by the gift-kit decision.
- `fix/eval-heartbeat`: subscriber-independent eval tick or buffered removal alert (defect 2) — reviewed slice.
- `fix/inputread-cycle-guard`: depth/visited guard + config-load cycle check (defect 4).
- `feat/hat-directions`: per-direction hat decode (defect 13).

**Wave 2 — GS giftee UX + packaging (depends on Wave 1's profile for orchestration).**
- `feat/low-batt-banner`: unmissable HUD banner + threshold (audio cue optional); coordinate with control-fw `feat/lowbatt-uplink` so the HUD gets the calibrated flag rather than re-deriving from voltage.
- `feat/giftee-wording`: plain-language pass over GRID hints and failure states (defect 11).
- `feat/race-day-orchestration`: one-action bring-up of hotspot + mapper(saved profile, headless `-config-file-path`) + bridge, extending the GARAGE fast-path.
- `ci/nsis-installer`: unsigned NSIS build on windows-latest + artifact (defect 10); mapper side `ci/w17-release` for a packaged binary.
- `feat/video-profiles` (CB5): drive/showpiece presets.

**Wave 3 — firmware features, native tests only, nothing flashed.**
- w17-soundlight-fw `feat/ignition-lights`, `feat/drs-tell`, `fix/neverconnected-hazard` (defect 9; coordinate the protocol-doc exception with control-fw as owner of link2).
- w17-control-fw `feat/gimbal-decay-center` (decision 11, carrying the owed formal re-review), `feat/training-tunable`, `feat/lowbatt-uplink`.
- Owner-decision-first items: sound-profile mechanism (then `feat/sound-profile-selector`; if link2 wins, control-fw `feat/link2-v2-profile`), showcase-mode design (`design/showcase-mode`, then implementation split per chosen mechanism).

**Wave 4 — documentation (parallel-capable, continuous).**
- learning-manual: `docs/manual-mapper-track` (mapper + head-intent coverage), refresh of stale deep-dives, S-review pass, G5a/G5b, rebuild-track chapters (assembly/BOM/harness — pull the loose PDB guide in); glovebox booklet drafted here, finalized only after hardware behavior is proven.
- Gift-kit docs: giftee install guide, GCS-box contents/wiring/BOM (power measurement itself is bench-gated).
- iPhone_rc (Codex-owned, handoff only): a dated `_handoff/` snapshot covering W2 bridge expectations, mDNS TXT contract, and HUD low-battery banner parity.

**Conditional waves (owner policy; not scheduled until confirmed current).**
- CW-A: U4 head-tracking arbiter on a never-merged, never-pushed w17-mapper branch (`feat/u4-arbiter-branchonly`), flags default-off, constants fail-closed — per the recorded 2026-08-16 amendment; R1–R16 + bench evidence stay the activation gate; propagate the amendment into the unlock plan when control-fw is next touched.
- CW-B: BT show-off mode — design doc first (`design/bt-showoff`), then a default-off compile-flagged prototype branch (`proto/bt-showoff-flagged`), native tests only, nothing merged or bench-run before the owner reads the design.

**Hardware-gated backlog (absolute; listed, not scheduled):** A2 execution → Phase B, ESC/PWM/ADC/Hall validation, config-swap window bench check, wheel bench check, real-device mDNS, GCS-box power budget, giftee-PC end-to-end install test, smoke:electron on real Windows.

## 5. Not covered / limits of this audit

- **smoke:electron 0/4 is environment-blocked**, not a repo defect: the Electron binary cannot boot from the agent shell at all (the user's own known-good binary wedges identically; dist byte-identical). Re-run once from an interactive terminal to confirm 4/4.
- **No hardware evidence anywhere** — A2 unexecuted, Phase B blocked; every hardware-class absence was classified BLOCKED_BY_GATE, never audited or exercised. Nothing was powered or flashed.
- **Codex-owned repos** (iPhone_rc, w17-rc-print-codex, w17-3d-codex) were checked only for git-state truthfulness of status rows; mechanical/print/shell, charging hardware, and the iPhone app itself were not audited.
- **No network operations**: ahead/behind counts use local remote-tracking refs without fetch; the mapper fork's PUBLIC visibility is taken from CURRENT_STATUS, not re-verified.
- **w17-design-system** received only a git-state check; **learning-manual** was audited for coverage, not line-level content correctness.
- **Windows-side paths** (hotspot lifecycle, elrs detect, installer) are unit-tested against canned output on macOS only; the giftee-PC story is untested end to end.
- **Live-session dirt untouched**: dirtyCount 1 in four trees (the four untracked AGENTS.md, mtime 2026-08-11) may belong to live sessions; flagged for a commit-or-remove decision, not inspected further. The workspace ahead-count moved (1→2) mid-audit as a session landed a commit.
- The recorded go1.26-cgo serial-enumerator failure did not reproduce on this platform; treated as platform/point-release specific, unresolved.
- **Brief-vs-vision tension**: this audit's brief treats the arbiter and BT show-off as pending explicit owner policy answers, while the vision doc records 2026-08-16 amendments approving branch-only work; both are therefore planned strictly as conditional waves keyed to re-confirming those amendments.
