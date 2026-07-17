# Codex handoff — VR FPV cross-review consolidation (2026-07-14)

**Transfer snapshot — not canonical.** Canonical sources: the Codex-owned docs named per
item below (`iPhone_rc/docs/…`), and on the Claude side
`w17-control-fw/project-review/head_tracking_unlock_plan.md`,
`w17-ground-station/docs/camera_aim_display_semantics.md`,
`w17-ground-station/docs/video_topology_baseline.md`,
`w17-3d-codex/CAMERA_GIMBAL_PLACEMENT.md`.

Delivery note: the workspace convention delivers Claude→Codex transfers into
`iPhone_rc/docs/`, but this pass was explicitly barred from writing into `iPhone_rc`.
The owner delivers this file to Codex.

**Constraints honored:** produced read-only against `iPhone_rc`. The uncommitted,
simulator-validated Batch 1 VR-calibration work in the `iPhone_rc` working tree
(including `FPVHUDApp/VR/VRCalibrationStore.swift`) was left untouched and is **not**
described as committed. Nothing here asks Codex to discard or supersede it.

**Process (two-stage sync):** Codex applies accepted items to the canonical docs, then
replies with the canonical commit hash per revision. Claude mirrors accepted contract
revisions into `w17-ground-station/docs/windows_bridge_contract.md` only afterwards, and
both sides record the canonical revision used.

Classifications used: `owner-decision propagation` / `safety-design clarification` /
`safety review required` / `consistency` / `sequencing clarity` / `contract
clarification` / `process` / `wording precision` / `architecture propagation`.

---

## H1 — Approved Batch 0 video baseline (simultaneity is required, not an optimization)

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` — "Network Topology" and "Batch 0".
- **Current wording:** "Simultaneous Windows+iPhone video is an optimization, not the
  primary requirement" and "If simultaneous mode worsens iPhone latency or reliability,
  ship an operator-selected video target with iPhone priority." Batch 0 exit gate does
  not mention the Windows viewer.
- **Proposed replacement:** State the owner-approved baseline that Batch 0 must verify:
  (1) one H.264 1280×720 60 fps encoder configuration; (2) direct low-latency H.264
  RTP/UDP **unicast to the iPhone**, if supported; (3) **RTSP retained simultaneously**
  for the Windows MediaMTX/WHEP path; (4) **simultaneous usable video on both iPhone and
  Windows is required**. If the exact topology is unsupported, record the measured
  limitation and return the trade-off to the owner — do **not** silently substitute
  iPhone-RTSP, H.265-only, RTP-push-only, or selected-receiver operation. Dual stream
  (H.265 main → iPhone + H.264 substream → Windows) remains an **experiment only** and
  must not replace the baseline without evidence and an owner decision. Add to the
  Batch 0 exit gate: "Windows-viewer impact of the chosen camera configuration is
  recorded (Windows WHEP is H.264-only and ingests RTSP via MediaMTX —
  `w17-ground-station/docs/SETUP.md` §1–2)."
- **Reason:** Owner decision 2026-07-14. The current plan text allows quietly dropping
  the Windows viewer; the Windows H.264/RTSP constraint appears nowhere in the plan.
- **Classification:** owner-decision propagation.
- **Dependencies:** none (verification happens in Batch 0). Claude-side record:
  `w17-ground-station/docs/video_topology_baseline.md`.
- **Schema/example change:** no.

## H2 — Pin "center", virtual-center lifecycle, anti-windup, transition rate limits

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` §6 ("Hybrid Mapping", "Recenter",
  "Stale And Fault Behavior"); echo in `docs/FUTURE_HEAD_TRACKING_TO_PAN_TILT_SAFETY.md`
  "Fail-Safe Behavior".
- **Current wording:** "First active milestone: return to center at a controlled rate."
  (which center is ambiguous once `virtualCameraCenter` has drifted); "set the virtual
  camera center to the current authoritative gimbal position"; "Mechanical limits clamp
  the final target at all times."
- **Proposed replacement:** (a) "Center" for stale/disarm/fault decay is **CRSF 992 —
  the authoritative *commanded* center** (matches the firmware-side blocker:
  `w17-control-fw/project-review/iphone_pan_tilt_firmware_readiness.md §8.3`); its
  physical safety still requires the endpoint bench validation. (b) `virtualCameraCenter`
  is **discarded** on stale, disarm, fault, and manual override; re-arming requires an
  explicit recenter, which re-seeds it from the mapper's **authoritative final commanded
  value** (never a claimed measured servo position — no position feedback exists
  anywhere). (c) Add **anti-windup**: bound `virtualCameraCenter` so that
  `virtualCenter + positionGain × maxAcceptedHeadAngle` can never exceed the configured
  limits — clamping only the final target lets the integrator run past the limit and
  produces rubber-band lag when the head returns to neutral. (d) The output rate limiter
  applies across **every authority transition** (arm, disarm, override engage, stale
  decay), so no transition can step the command.
- **Reason:** removes the one ambiguity that could make Windows and firmware docs
  disagree at the failsafe boundary; prevents two concrete first-bench failure modes.
- **Classification:** safety-design clarification.
- **Dependencies:** H3 (timeout number used by the stale transition).
- **Schema/example change:** no.

## H3 — One stale number: 300 ms receive-time, with deterministic test boundaries

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` §6 and Batch 6 deliverables.
- **Current wording:** §6 names no stale number. (`FUTURE_…SAFETY.md` and
  `FIRST_ACTIVE_PAN_TILT_MILESTONE.md` already say "target `<= 300 ms`"; the canonical
  contract §3 says "> about 300 ms".)
- **Proposed replacement:** State once: the mapper's stale authority is **300 ms of
  receive-time silence** (fixed). Add deterministic boundaries to the Batch 6 test
  vectors: **299 ms = fresh; 300 ms = fresh; 301 ms = stale**. Note that the 400 ms
  figure in older Claude-side readiness docs is superseded (supersession notes added
  there 2026-07-14).
- **Reason:** four values currently coexist across the doc set (250 advisory / ~300
  contract+implementation / 400 readiness docs); the mapper handoff needs exactly one,
  with pinned boundaries for deterministic tests.
- **Classification:** consistency.
- **Dependencies:** none.
- **Schema/example change:** no.

## H4 — Motion-sample freshness vs mapper authority (factual safety issue — review required)

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` §6 (filtering/stale) and
  `docs/FUTURE_HEAD_TRACKING_TO_PAN_TILT_SAFETY.md` (preconditions); code review of the
  sender path when a code change is separately approved.
- **Current behavior (verified read-only, 2026-07-14):**
  - Local motion staleness is **500 ms**: `FPVHUDApp/Models/MotionState.swift:82`
    (`staleAfter: TimeInterval = 0.5`); `canSend` permits sending while the sample is
    younger than that.
  - Packets are stamped at **send time**, not sample time:
    `FPVHUDApp/Models/HeadTrackingPacket.swift:40`
    (`timestampMs ?? UInt64(Date().timeIntervalSince1970 * 1000)`).
  - `timeout_ms` is sent as an **advisory hint**, app default 250 ms (contract §3).
  - The authoritative mapper timeout is **300 ms receive-time** (H3).
- **The issue:** a frozen Core Motion sample aged 300–500 ms is still emitted inside
  freshly-timestamped packets, so the mapper sees a live stream and frozen motion can
  remain **authoritative beyond the 300 ms mapper timeout** (up to ~500 ms).
- **Proposed action (deliberate review, NOT an implementation directive — do not modify
  iPhone code under this handoff):** review and record decisions on:
  1. whether local motion freshness must be 300 ms or tighter;
  2. whether `timestamp_ms` remains send time;
  3. whether sensor-sample age needs separate representation in the packet;
  4. how to guarantee frozen motion cannot remain authoritative beyond 300 ms.
  Keep the three timeout domains explicitly distinct in the docs: iPhone local
  motion-sample freshness / packet `timeout_ms` advisory hint / mapper receive-time
  authority (300 ms, fixed).
- **Reason:** without this, the sender's own freshness gate is looser than the mapper's
  authority window — the mapper cannot detect the difference from packets alone.
- **Classification:** safety review required.
- **Dependencies:** H3.
- **Schema/example change:** **maybe** — only if option 3 adds a sample-age field
  (schema + examples + both-side mirror; flag before implementing).

## H5 — State-list drift between the two Codex safety docs

- **Document:** `docs/FUTURE_HEAD_TRACKING_TO_PAN_TILT_SAFETY.md` "Proposed States".
- **Current wording:** seven states (`disabled`, `receiving`, `ready_not_centered`,
  `centered`, `active`, `stale`, `fault`) — no `armed`, no `manual_override`.
- **Proposed replacement:** align with the nine-state list in
  `docs/FIRST_ACTIVE_PAN_TILT_MILESTONE.md` "Required Windows States" (adds `armed`,
  `manual_override`) — or mark the FUTURE doc's list as superseded by the milestone doc.
- **Reason:** the VR plan's Batch 6 already uses the nine-state list; two canonical
  vocabularies invite implementation drift.
- **Classification:** consistency.
- **Dependencies:** none.
- **Schema/example change:** no.

## H6 — Batch 5 "Windows-side recenter calculations" sequencing

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` Batch 5.
- **Current wording:** "Exercise Windows-side recenter calculations in logs only."
- **Proposed replacement:** "Exercise recenter calculations in logs only, using the
  iPhone-repo reference harness (`scripts/reference_iphone_bridge.py`); Windows-owner
  production integration does not begin until Batch 7."
- **Reason:** as written, Batch 5 implies Windows-owner code exists two batches early.
- **Classification:** sequencing clarity.
- **Dependencies:** none.
- **Schema/example change:** no.

## H7 — Commanded-vs-measured honesty in the telemetry contract and VR HUD

- **Document:** canonical `docs/windows_bridge_contract.md` §2 (field definitions) and
  `docs/VR_FPV_IMPLEMENTATION_PLAN.md` §5 (minimal VR HUD).
- **Current wording:** `camera_yaw_deg`: "Current camera/gimbal reported yaw, not iPhone
  authority" (and the same for pitch). Plan §5 lists "camera pan/tilt position near
  gimbal limits" as a conditionally-visible HUD element.
- **Proposed replacement:** annotate in the contract that **until physical position
  feedback exists** (none exists anywhere in the system), `camera_yaw_deg` /
  `camera_pitch_deg` are **commanded/requested mirrors, not measured angles**; "near
  limit" means **command saturation**, not confirmed mechanical contact; recenter
  semantics reference the mapper's authoritative final commanded value. Decide the
  transport for the near-limit indication: the existing `warning` /
  `stale_data_warnings` fields (no schema change) vs. a new field (schema + examples
  change, mirrored on both sides) — decision, not implementation, at this stage.
- **Reason:** owner directive on telemetry honesty; prevents the VR HUD from presenting
  a command as a measurement.
- **Classification:** contract clarification.
- **Dependencies:** H2 (commanded-center semantics).
- **Schema/example change:** **maybe** — only if a dedicated near-limit field is chosen.

## H8 — Contract synchronization bookkeeping (Discovery section mirror pending)

- **Document:** canonical `docs/windows_bridge_contract.md` (process, not content).
- **Current state:** the canonical contract (Last updated 2026-07-10) added the
  **Discovery** (Bonjour/mDNS `_w17hud._udp.local.`) section; the Windows implementation
  copy (2026-07-08) does not carry it yet. The mirror is **deliberately deferred**: per
  the two-stage rule, Claude mirrors only an accepted canonical revision.
- **Proposed action:** when applying any accepted item from this handoff, reply with the
  canonical commit hash per revision; going forward, flag every canonical contract rev to
  the Windows side with its commit hash so both sides can record the revision used for
  each sync.
- **Reason:** the mirror-debt discovered in this review existed precisely because revs
  weren't being flagged with an identifiable revision.
- **Classification:** process.
- **Dependencies:** none.
- **Schema/example change:** n/a.

## H9 — iPhone-local video loss vs head authority: keep it an explicit open decision

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` §6 and
  `docs/FUTURE_HEAD_TRACKING_TO_PAN_TILT_SAFETY.md`.
- **Current wording:** "Video loss alone does not stop fresh head intent; the video and
  head paths remain independent." / "Head tracking remains independent from the video
  receiver. A temporary video failure does not itself stop motion packet generation."
- **Proposed replacement (documentation of fact + open decision, choose nothing):** add:
  "The W3 intent packet carries no iPhone-local decoder/video-health field (fields:
  `seq`, `timestamp_ms`, `yaw_deg`, `pitch_deg`, `roll_deg`, `tracking_enabled`,
  `centered`, `timeout_ms`). Therefore the mapper cannot react to iPhone-local video loss
  from packets alone. A mapper-enforced freeze or return-to-center on video loss would
  require one of: (1) a reviewed W3 schema field; (2) a reviewed side channel; (3)
  deliberate packet suppression by the iPhone on video loss; (4) operator action only.
  This is an **open owner decision**; until it is made, the independence rule above
  stands and the active-milestone runbook must name the blind-driver case explicitly."
- **Reason:** owner directive: this active-safety decision must not be resolved silently
  by either side during plan consolidation.
- **Classification:** safety-design clarification (decision deferral).
- **Dependencies:** owner decision; option 1 interacts with H4's option 3.
- **Schema/example change:** flagged — option 1 would be a mirrored schema change.

## H10 — "Actuate" wording in the safety boundary

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` "Status And Safety Boundary".
- **Current wording:** "Windows remains the only authority that can arm, mix, limit, or
  actuate the gimbal."
- **Proposed replacement:** "Windows remains the only authority that can arm, mix, and
  limit head-derived gimbal intent; the car firmware remains the only producer of final
  hardware outputs, and only from already-arbitrated CRSF channels."
- **Reason:** "actuate" could later be read as sanctioning a Windows→servo path that
  bypasses CRSF; the corrected wording matches the authority chain in
  `FUTURE_HEAD_TRACKING_TO_PAN_TILT_SAFETY.md`.
- **Classification:** wording precision.
- **Dependencies:** none.
- **Schema/example change:** no.

## H11 — Mapper identity and the UDP 5602 topology (informational + Batch 6 targeting)

- **Document:** `docs/VR_FPV_IMPLEMENTATION_PLAN.md` Batches 6–7 (addressee), plus
  awareness for any future sender work.
- **Current wording:** Batch 6/7 deliver to "the Windows owner" generically.
- **Proposed replacement / information:** the owner has designated
  **elrs-joystick-control** (the existing DualShock→CRSF channel producer) as the
  proposed active mapper/arbiter host; the Electron ground station remains
  viewer/configuration/visualization/log-only and will never own active mapping. Address
  the Batch 6 handoff package to that mapper component, and include: the state machine
  (nine states, H5), validation rules, hybrid formula with the H2 virtual-center
  lifecycle, the H3 timeout + boundaries, the expectation of a bench-derived
  **degrees ↔ CRSF-count conversion** (your milestone limits are specified in degrees;
  the wire carries counts; the firmware owns µs endpoints), the mapping from the log-only
  monitor states (`active_log_only`, `invalid`, …) to the active-era states, and test
  vectors. **Topology fact:** the iPhone sends intent as unicast UDP to one destination,
  and the Electron log-only receiver holds an exclusive bind on 5602 when enabled — the
  mapper cannot simply co-bind. The port/ingest architecture is an **open owner decision**
  (options recorded in
  `w17-control-fw/project-review/head_tracking_unlock_plan.md §2.3`); one option would
  involve an iPhone-side dual-destination send — **review feasibility only if asked; do
  not implement** a sender change under this handoff.
- **Reason:** owner directive to make the mapper process boundary explicit on both sides.
- **Classification:** architecture propagation.
- **Dependencies:** owner decision on §2.3 options; elrs-joystick-control ingest
  investigation (Claude-side next action).
- **Schema/example change:** no (a dual-destination send would be config-level, not
  schema).
