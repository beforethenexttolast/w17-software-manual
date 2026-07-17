# W17 VR-FPV / Head-Tracking — Claude-side Master Implementation Plan

**Stable batch definitions + session prompts. NO status here** — live batch status is the
"VR-FPV batch status" table in `CURRENT_STATUS.md`; update it there at the end of every
session. Created 2026-07-14 after the plan-consolidation pass (canonical contract sync
revision `84532ed`).

Goal: driver-POV VR FPV — camera on the pan/tilt gimbal, aimed by the right stick today
and by iPhone head tracking later, gated behind the reviewed safety milestone. The Codex
side (iPhone app) runs its own plan (`iPhone_rc/docs/VR_FPV_IMPLEMENTATION_PLAN.md`,
Batches 0–9) and tracker; this plan covers the **Claude-owned** work and the
cross-side/owner gates.

## Standing constraints (apply to every batch/session)

- One repo per session; show diffs; commit only when Vitaliy approves.
- **No hardware powered/flashed** unless the batch explicitly says Phase B *and* A2 has
  passed (`CURRENT_STATUS.md` hardware gates).
- **Never edit `iPhone_rc`** or any Codex-owned repo. iPhone-side changes go through a
  dated `_handoff/` document.
- Contract changes are **two-stage** (Codex revs canonical → Claude mirrors, hashes
  recorded on both sides). Never edit the Windows contract copy unilaterally.
- `w17-ground-station` stays viewer/config/visualization/log-only;
  `test/noControlPath.test.js` is unbreakable — if a change trips it, the change is wrong.
- Two owner decisions are OPEN and must not be resolved implicitly: **UDP 5602
  mapper/diagnostic topology** and **active video-loss response**
  (`w17-control-fw/project-review/head_tracking_unlock_plan.md §2.3 / §4`).
- Constants canon: stale authority 300 ms receive-time (299/300 fresh, 301 stale);
  decay target = commanded center CRSF 992; camera values are commanded mirrors, never
  measured; future active motion freshness ≤ 250 ms (Codex side).

## Reference documents (read before the relevant batch)

| Topic | Source of truth |
|---|---|
| Unlock sequencing + mapper boundary | `w17-control-fw/project-review/head_tracking_unlock_plan.md` |
| Firmware readiness + 7 blockers | `w17-control-fw/project-review/iphone_pan_tilt_firmware_readiness.md` |
| Bridge contract (canonical / mirror) | `iPhone_rc/docs/windows_bridge_contract.md` / `w17-ground-station/docs/windows_bridge_contract.md` |
| Display semantics | `w17-ground-station/docs/camera_aim_display_semantics.md` |
| Video baseline | `w17-ground-station/docs/video_topology_baseline.md` |
| Placement | `w17-3d-codex/CAMERA_GIMBAL_PLACEMENT.md` |
| Codex plan/tracker | `iPhone_rc/docs/VR_FPV_IMPLEMENTATION_PLAN.md`, `…_TRACKER.md` (read-only) |

## Status vocabulary (for the CURRENT_STATUS table)

`NOT_STARTED` · `IN_PROGRESS` · `BLOCKED_DECISION` (waiting on an owner call) ·
`BLOCKED_HARDWARE` · `BLOCKED_EXTERNAL` (Codex / upstream) · `DONE` (exit gate met, with
evidence).

---

## Batch definitions

### CB0 — Mapper feasibility investigation (elrs-joystick-control)  ← NEXT

- **Repo:** none (read-only investigation; findings appended to the unlock plan).
- **Work:** clone upstream `elrs-joystick-control` **read-only** into
  `_vendor/elrs-joystick-control` (reference clones live in `_vendor/`, never edited,
  own-git-repo so untracked here). Determine: input architecture (how gamepad axes enter
  channel mixing), whether a UDP/virtual-axis/plugin ingest path exists or is feasible,
  where right-stick-wins arbitration could live, how a diagnostics republish could work,
  and the effort/shape of a fork. Map each §2.3 topology option (a)/(b)/(c) onto the real
  codebase with evidence.
- **Exit gate:** unlock plan §2.3 updated from UNVERIFIED to verified findings; a
  decision package (options, evidence, recommendation) presented; **owner decides**
  topology + fork ownership. No code written.
- **Depends on:** nothing. **Unblocks:** CB8.

### CB1 — Ground-station right-stick indicator (authorized depiction relaxation)

- **Repo:** `w17-ground-station` (code + tests — the deferred Plan-A D3).
- **Work:** draw the right-stick control at the SEAT-FIT pad preview's dim placeholder
  (`renderer/padPreview.js:38`, cx=275 cy=140), moving dot fed by the display-only
  gamepad mirror (`camPanAxis: 2` / `camTiltAxis: 3`), caption **"R-STICK"** (stick
  position, NOT camera aim — semantics doc §2.1); feed per-tick from `setupFlow.js`
  mirroring the `pressedRoles` pattern; style in `hud.css`; rewrite
  `test/padPreview.test.js` **both** the `:37-45` depiction ban AND the `:24-35`
  data-role/dim-placeholder assertions; update the stale comments
  (`inputPresets.mjs:72-75`, test header `:5-8`, padPreview file header); record the
  invariant change in `w17-ground-station/CLAUDE.md`.
- **Explicitly untouched:** `test/noControlPath.test.js`, head-tracking modules, any
  control path. **Note:** the repo has a large pre-existing dirty tree (setup-flow/audit
  work) — do not mix; keep this change's diff separable.
- **Exit gate:** `npm test` green incl. unchanged `noControlPath.test.js`; `npm run demo`
  shows the dot tracking the physical right stick; HUD reticle unaffected.
- **Depends on:** nothing.

### CB2 — Gimbal vision/roadmap explainer artifact

- **Repo:** none (scratchpad HTML → Artifact). The Plan-A D1 deliverable.
- **Work:** self-contained, theme-aware page: signal path (right stick → CRSF ch9/10 →
  decoder → ServoOutput → 50 Hz PWM → MG90S), placement options, what works now vs
  gated, the 7-blocker gate with live status, worked examples, the mapper architecture
  picture from the unlock plan.
- **Exit gate:** artifact renders light+dark, no horizontal scroll, every file:line cited
  re-checked. Optional batch — pure communication value.

### CB3 — Firmware doc/comment hygiene (tiny)

- **Repo:** `w17-control-fw`.
- **Work:** fix the stale comment `lib/channels/include/channels/ChannelDecoder.hpp:57-58`
  ("decoded but unwired until the gimbal deliverable" — the gimbal is wired and
  bench-noted); grep for any other stale "deferred gimbal" remnants. Code-comment-only
  diff, no behavior.
- **Exit gate:** `pio test -e native` green (no behavior change expected); diff shown.

### CB4 — Windows-side mDNS discovery (now canonically unblocked)

- **Repo:** `w17-ground-station`.
- **Work:** implement discovery of `_w17hud._udp.local.` per the canonical Discovery
  section (mirrored at rev `84532ed`): discovered HUDs appear as **user-confirmed
  suggestions** for the W2 destination, advisory only, never auto-applied. Follow the
  original proposal `docs/proposals/iphone_mdns_discovery.md` updated against the
  canonical TXT keys (`v/role/tport/feat/dev`).
- **Exit gate:** unit tests for the parser/validator; manual check against the real
  iPhone advertisement when a device is available. Optional QoL batch.

### CB5 — Video baseline verification, Windows side (hardware: camera)

- **Repo:** `w17-ground-station` (validation, likely zero code).
- **Work:** with the camera configured to the approved baseline (H.264 1280×720 60 fps,
  RTP unicast → iPhone + retained RTSP), confirm RTSP → MediaMTX → WHEP still plays;
  measure simultaneity impact with Codex Batch 0. If the baseline is unsupported,
  **report the limitation — do not substitute** (`docs/video_topology_baseline.md`).
- **Exit gate:** evidence (screenshots/logs) recorded; owner informed of any trade-off.
- **Depends on:** camera hardware present; coordinates with Codex Batch 0.

### CB6 — Real-device W2/W3 bridge validation (U1, blocker 5 closure)

- **Repo:** `w17-ground-station` (validation only; debug/validation setup adjustments
  allowed, source changes need explicit approval — repo CLAUDE.md).
- **Work:** run the log-only validation runbook (contract appendix) against the **real
  iPhone** on a non-isolated bench network (hotspot / RT5370 SoftAP — see
  `CURRENT_STATUS.md` pending validations): W2 telemetry on the phone, W3 states
  (`active_log_only`, `not_centered`, `inactive`, `stale` at ~300 ms), malformed
  rejection, counters. Capture evidence per step.
- **Exit gate:** blocker 5 marked validated-with-real-device in the unlock plan; W3
  remains LOG-ONLY throughout.
- **Depends on:** iPhone on hand + working bench network.

### CB7 — Placement decision support (fabrication)

- **Repo:** `w17-3d-codex`.
- **Work:** support the halo-occlusion dry-fit check (Option A decider), fill
  `CAMERA_GIMBAL_PLACEMENT.md` §5 answers as they arrive, record the **owner's placement
  decision** there, and derive the mount work items (roll trim, stiffness, duct reach,
  hard-stop geometry deliverables for CB9).
- **Exit gate:** placement decision recorded; print-side work items queued in the repo's
  own gates/logs.
- **Depends on:** printed halo/body parts for the dry fit; owner decision.

### CB8 — Mapper implementation (U4) — **BLOCKED_DECISION until CB0 resolves**

- **Repo:** the fork/host chosen by the owner after CB0 (likely an owned
  `elrs-joystick-control` fork — a new repo registered in `WORKSPACE_MAP.md`).
- **Work (multiple sessions):** head-intent ingest per the chosen topology; validation
  gauntlet (reuse contract semantics + golden vectors); shaping (deadband, low-pass,
  slew); stale decay to commanded 992 with 299/300/301 boundary tests;
  `virtualCameraCenter` hybrid with anti-windup; right-stick-wins arbitration, no
  auto-restore; nine-state machine; one-way diagnostics republish for Electron; test
  vectors from `iPhone_rc` fixtures.
- **Exit gate:** Codex-plan Batch 7 equivalent — every safety transition proven with
  physical output disconnected/simulated. **No servo output in this batch.**
- **Depends on:** CB0 + owner topology decision; Codex Batch 5 (real axis data) for final
  signs/ranges.

### CB9 — Gimbal endpoints + tuning console (U3) — **HARD GATE: A2 + Phase B**

- **Repo:** `w17-control-fw`.
- **Work:** wire `gimbalConfig` into the tuning console (readiness §4.9); bench-measure
  per-axis mechanical endpoints on the real mount (from CB7's geometry); set real
  `ServoConfig` values; record the **deg ↔ CRSF-count conversion table** in
  `project-review/`; add endpoint/clamp unit tests; decide/implement the optional
  defense-in-depth slew limiter; record the failsafe hold-vs-center re-decision (U8,
  owner).
- **Exit gate:** blocker 1 green with bench evidence; native tests green.
- **Depends on:** **A2 closed + Phase B approved** (do not start the powered part
  before); CB7 mount printed/assembled.

### CB10 — Integration + bench milestone (U6/U7) — **GATED: FIRST_ACTIVE milestone**

- **Repos:** mapper host + `w17-control-fw` bench.
- **Work:** end-to-end simulated-output integration with real iPhone packets (Codex
  Batch 7), then — only after the Codex-owned `FIRST_ACTIVE_PAN_TILT_MILESTONE.md`
  checklist passes review — the bench-only servo sweep (wheels off, tiny limits, slow
  rate, observer present).
- **Exit gate:** the milestone doc's go/no-go table, filled with evidence.
- **Depends on:** CB8, CB9, Codex Batches 5–7, owner decisions #1–#3.

### Owner decisions tracked alongside (not batches)

1. UDP 5602 topology + fork ownership (after CB0).
2. Active video-loss response (unlock plan §4).
3. Firmware failsafe hold-vs-center (in CB9).
4. Camera placement (in CB7).
5. First head-tracked driving protocol / spotter (before any Codex Batch 9 driving).

---

## How to run a session (workflow)

1. Paste the batch prompt (below) into a fresh Claude Code session started in
   `~/Documents/projects`.
2. The session reads `CURRENT_STATUS.md` (batch table + gates) and this plan, then works
   **one batch, one repo**.
3. Closeout, every session: update the batch row in `CURRENT_STATUS.md` (status +
   one-line evidence), show diffs, **do not commit unless asked**, and print the
   next-session prompt.

## Session prompts (copy-paste)

### CB0 prompt

> Continue the W17 VR-FPV effort per `VR_FPV_MASTER_PLAN.md`, batch **CB0 — mapper
> feasibility investigation**. Read `CURRENT_STATUS.md` (VR-FPV batch table + hardware
> gates) and `w17-control-fw/project-review/head_tracking_unlock_plan.md` (§2 process
> boundary, §2.3 blocker) first. Clone upstream elrs-joystick-control read-only into
> `_vendor/elrs-joystick-control` and answer with evidence (file:line): how do gamepad
> axes enter channel mixing; is there any UDP/network/plugin/virtual-axis ingest path;
> where could right-stick-wins arbitration live; how could a one-way diagnostics
> republish work; what would a minimal fork look like. Map topology options (a) mapper
> takes 5602 + diagnostics republish, (b) iPhone dual-destination send, (c) fan-out
> relay onto the real codebase and give a recommendation. Update unlock plan §2.3 from
> UNVERIFIED to findings, present the owner-decision package, update the CB0 row in
> `CURRENT_STATUS.md`. Constraints: read-only investigation — no code changes in any
> W17 repo, never edit `_vendor/` contents or `iPhone_rc`, no hardware, no commits,
> do not choose the topology yourself — it is an owner decision. End with the
> next-session prompt.

### CB1 prompt

> Continue the W17 VR-FPV effort per `VR_FPV_MASTER_PLAN.md`, batch **CB1 —
> ground-station right-stick indicator**. Read `CURRENT_STATUS.md`,
> `w17-ground-station/docs/camera_aim_display_semantics.md` (§2 rules), and the CB1
> definition. Work only in `w17-ground-station`; the repo has a large pre-existing
> dirty tree — keep this change's diff cleanly separable and touch nothing unrelated.
> Implement the SEAT-FIT right-stick indicator per CB1 (display-only gamepad mirror,
> caption "R-STICK", never "camera aim"), rewrite `test/padPreview.test.js` (both the
> depiction-ban test AND the data-role/dim-placeholder assertions), update the stale
> boundary comments, record the invariant change in the repo `CLAUDE.md`.
> `test/noControlPath.test.js` and all head-tracking modules stay untouched. Verify:
> `npm test` fully green, then `npm run demo` and confirm the dot tracks the right
> stick and the HUD reticle still works. Show diffs, do not commit unless I approve,
> update the CB1 row in `CURRENT_STATUS.md`, end with the next-session prompt.

### Generic prompt template (CB2–CB10)

> Continue the W17 VR-FPV effort per `VR_FPV_MASTER_PLAN.md`, batch **CB<N> — <name>**.
> Read `CURRENT_STATUS.md` (batch table + hardware gates) and the batch's reference
> docs first; verify the batch's dependencies and gates are met before starting — if a
> gate is not met (A2/Phase B, owner decision, hardware), STOP and report instead of
> proceeding. Work only in the batch's named repo; show diffs; no commits without
> approval; never edit `iPhone_rc`; contract changes only via the two-stage handoff;
> `noControlPath` stays green; no hardware power unless the batch explicitly says
> Phase B and A2 has passed. Close out by updating the batch row in
> `CURRENT_STATUS.md` and printing the next-session prompt.
