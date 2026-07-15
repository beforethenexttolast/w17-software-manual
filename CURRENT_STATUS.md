# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes.**
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: 2026-07-15. Control-firmware remediation through R5-b is complete:
validated delivery NVS loading, configurable steering endpoints, console parsing
hardening, a provisional 2-second control-loop Task Watchdog, and RTC-retained
reset diagnostics. Native tests: 224/224; all ESP32 environments build. Live
watchdog-cycle observation and physical reset-path validation remain pending.
A2 remains unexecuted and Phase B remains blocked.

2026-07-14: VR/head-tracking plan-consolidation pass (documentation only, uncommitted)
— see "Head-tracking / VR consolidation" under Pending validations.

2026-07-14: VR-FPV batch CB0 (mapper feasibility) DONE — read-only investigation of
upstream elrs-joystick-control (`_vendor/`, uncommitted); unlock plan §2.3 updated to
verified findings; owner decision #1 (5602 topology + fork ownership/license) now
actionable. No code changed in any W17 repo.

2026-07-15: **Owner decision #1 RESOLVED — topology (a)** (unlock plan §2.3.7). Owned
elrs-joystick-control fork owns UDP 5602; Electron stays viewer/config/log-only with a
read-only head-intent diagnostic snapshot via the mapper's existing gRPC; no Electron
control relay; Electron and mapper receiver modes are mutually exclusive (Electron closes
5602 when mapper ingest is on). `_vendor/` stays untracked, read-only, pinned to upstream
`2b8031a`.

2026-07-15: **CB8 slice 1 (mapper log-only head-intent ingest) IMPLEMENTED** in the new
owned fork **`w17-mapper`** (owner-approved name; branch `w17-headtrack` off upstream
`2b8031a`; GPL-3.0-or-later; registered in `WORKSPACE_MAP.md`; push disabled; git-ignored
in the manual repo). Go toolchain installed here (`brew install go`, go1.26.5). New
self-contained package `pkg/headintent` (validator + state machine + non-blocking UDP
receiver, all with injectable seams); diagnostics **in-process only** this slice (Electron
transport deferred — owner picks gRPC vs localhost-HTTP later per unlock plan item 14).
Evidence: go build/vet green, `go test -count=1` + `-race` all green (299/300/301 boundary,
invalid-preserves-last-valid, seq diagnostics, fault, real-UDP accept, UDP port exclusivity),
`go list -deps` proves no config/link/crossfire/serial/devices dependency, and no existing
file imports the package (existing build/output unchanged). See unlock plan §2.3.8.

2026-07-15: **CB8 slice 2 (cmd wiring behind a disabled-by-default flag) IMPLEMENTED** in
`w17-mapper` (uncommitted). `cmd/elrs-joystick-control/main.go` gains `-headtrack-ingest`
(default from env `W17_HEADTRACK_INGEST`; off by default) + `-headtrack-port` (default 5602);
when on it starts a `headintent.Receiver` and **nothing else** (not wired into grpc/devices/
config/serial/link/server/client), bind failure logged-and-ignored; when off no socket is bound.
New test `pkg/headintent/pack_deadend_test.go` proves the gamepad→CRSF `crsf.PackChannels` output
(12 frames / 312 bytes) is **byte-for-byte identical** flag-off vs flag-on under valid/stale/
invalid UDP traffic (`bytes.Equal` + empty shell `diff` of hex dumps; receiver proven non-vacuous).
`go build`/`vet`/`test -count=1`/`test -race` on `./pkg/headintent/` green; `go list -deps` still
reaches no control/output package (crossfire is test-only); only `cmd` now imports `headintent`.
**New host finding:** `go build ./...` on this macOS + go1.26.5 host now clears SDL and the web-UI
embed but **fails only in third-party `go.bug.st/serial/enumerator` v1.5.0** (go1.26 cgo rule) —
pre-existing, unrelated to this change (fails on pristine `main.go` too); a temporary bump to
`go.bug.st/serial v1.7.1` makes `go build ./...` fully green and was then reverted (that dep is in
the CRSF send path → owner decision). See unlock plan §2.3.9.
**Not committed.** No hardware, no active pan/tilt — log-only ingest only.

2026-07-15: **Owner decision — Electron diagnostics transport RESOLVED (gRPC; item 14)**
(unlock plan §2.3.10). Read-only server-streaming `WatchHeadIntentDiagnostics(Empty) returns
(stream HeadIntentDiagnostics)` on the **existing** :10000 gRPC (no second HTTP API, no new port,
no bind/security change this slice); subscriber-only Electron consumer in the main/preload layer;
snapshot-on-subscribe + immediate state transitions, ~10 Hz value updates, latest-value/bounded
1-item buffer, strictly non-blocking (a slow/dead client cannot affect UDP/eval/mix/CRSF); enum
state, server-computed `receive_age_ms`, full counters/seq/rate/angles, last-valid preserved
when invalid/stale. **Recorded, NOT built** (CB8 slice 3). Blockers before building: proto
toolchain absent here (`protoc`/`protoc-gen-go`/`protoc-gen-go-grpc`/`buf`) — needs install
approval or Windows-host codegen; consumer lands in `w17-ground-station` (separate repo).
**Recorded fact:** gRPC :10000 binds `[::]` (externally reachable, not loopback) — left unchanged
per owner; tightening it is a separate decision.

2026-07-15: **CB8 slice 3A (mapper-side gRPC diagnostics) IMPLEMENTED** in `w17-mapper`
(uncommitted; Electron consumer = slice 3B, `w17-ground-station`, later). Added
`rpc WatchHeadIntentDiagnostics(Empty) returns (stream HeadIntentDiagnostics)` + enum
`HeadIntentState` (explicit `_UNSPECIFIED`; no active-control state) to `pkg/proto/server.proto`;
regenerated Go + grpc-web stubs with a **pinned, drift-checked** toolchain (protoc 23.2,
protoc-gen-go 1.30.0, protoc-gen-go-grpc 1.3.0, protoc-gen-js 3.21.2, protoc-gen-grpc-web 1.4.2)
via the new reproducible `pkg/proto/generate.sh` (unchanged-proto regen = **zero diff**; post-change
regen idempotent; no tool binaries committed). New `headintent.Broadcaster` (read-only consumer of
the receiver snapshot: snapshot-on-subscribe, immediate transition push, ~10 Hz value updates,
per-subscriber bounded latest-value buffer, **4-stream cap**→`ResourceExhausted`, cancel/disconnect
release, nil source→`Unavailable`); wired through `pkg/server` + `cmd` (broadcaster only when
`-headtrack-ingest`, else nil). `go build ./...`/`go test ./...` green, `pkg/headintent`+`pkg/server`
`-race` green, webpack compiles the grpc-web stubs. **CRSF `PackChannels` byte-identical** off vs on
under valid/stale/invalid traffic AND with diagnostics subscribers connected/slow/disconnected.
gRPC :10000 still binds `[::]` (external) — unchanged; fan-out protection is the 4-cap + non-blocking
buffers, not the bind. Full build again needed a temporary `go.bug.st/serial`→v1.7.1 bump (go1.26 cgo),
**reverted** — deps/`go.work` pristine. See unlock plan §2.3.10 / §2.3.10.1. **Not committed.** No
Electron integration, no control path, no hardware.

2026-07-15: **CB8 slice 3B (Electron head-intent subscriber) + slice 3C (cross-process
integration validation + proto-drift guard) DONE — both repos committed.** Mapper slices
1–3A committed in `w17-mapper` @ `59d1739` (was uncommitted). GS slice 3B @ `03f43e2`
(prior); GS slice 3C @ `dce91f8`. Slice 3C adds NO runtime behavior (log-only / display-only).
**Proto-drift guard (GS, hermetic):** `test/protoDrift.test.js` proves
`proto/head_intent_diagnostics.proto` is byte-faithful (package, enum value name→number
pairs, all 22 field number/type/label tuples, `Empty` zero-field, method path + streaming
direction) to a checked-in canonical snapshot generated from the live mapper
(`proto/canonical/head_intent_canonical.descriptor.json` via `scripts/check-canonical-proto.js`;
regen is a **zero-diff**); a non-hermetic `npm run proto:check` verifies the snapshot vs a
local `../w17-mapper`. Guard verified to bite on injected drift. **Live cross-process run**
(evidence: `w17-ground-station/docs/2026-07-15_cb8_slice3c_integration_evidence.md`):
real mapper gRPC :10000 + LOG-ONLY UDP 5602, driven by the `iPhone_rc` fake sender, observed
by the shipping GS transport+consumer — captured every `HeadIntentState` live
(IDLE/INVALID/STALE/INACTIVE/NOT_CENTERED/ACTIVE_LOG_ONLY/FAULT; UNSPECIFIED/DISABLED covered
by unit tests, DISABLED not emitted in this topology by design), ingest-off ⇒ `UNAVAILABLE`,
4-stream cap ⇒ 5th subscriber `RESOURCE_EXHAUSTED`, mapper restart ⇒ bounded-backoff reconnect,
`crsf.PackChannels` byte-identical with receiver + subscribers attached (`go test
./pkg/headintent/` + `./pkg/server/`), and topology-(a) mutual exclusivity live
(`W17_MAPPER_HEADINTENT=1` ⇒ GS W3 does not bind 5602 + consumer on; unset ⇒ GS binds 5602 +
consumer off). Validation binary built with a temporary `go.bug.st/serial`→v1.7.1 bump under
`GOWORK=off`, then reverted — `go.mod`/`go.sum`/`go.work` byte-pristine vs `HEAD`. GS suite
746/746.

2026-07-15: **CB8 slice U4 (head-intent shaping/arbitration) — DESIGN ONLY, SAFETY-GATED,
DONE.** No active output, no runtime-behavior change in any repo. Design written as
`w17-control-fw/project-review/head_tracking_unlock_plan.md §2.3.11`: the shaping/arbitration
model (deadband in deg via the U3 deg↔count table; rate/accel slew; **active freshness gate
≤250 ms** distinct from the **300 ms** log-only diagnostic boundary; center/enable/arm
preconditions; failsafe **decay-to-commanded-992**, reconciled with the firmware radio-loss
hold-vs-center owner decision #3/§5-2/U8 which it de-risks but does not resolve); **arbitration
authority = mapper-only, single post-node-graph choke point** before `crsf.PackChannels`
(supersedes the earlier in-graph-node sketch §2.3.3/§2.3.5); 9 safety invariants (I1–I9); the
exact test matrix (Groups A/B/C) the gated code must prove; the two-part **FIRST_ACTIVE flag**
(compile-tag + runtime, both default off, both required); and the **FIRST_ACTIVE review
checklist R1–R14** that must all pass before any arbiter code is committed. **No code
scaffolded** in `w17-mapper` (deliberate — shaping code would bake in unreviewed constants +
a control-path stage): `w17-mapper` clean at `59d1739`, `go test ./pkg/headintent/` green
(the standing `pack_deadend_test.go` PackChannels byte-identity proof unchanged), proto still
ends at `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` (**no active enum value**), GS 746/746 +
`npm run proto:check` clean (no proto change). Firmware still iPhone-unaware; no
iPhone→CRSF/servo/gimbal/ESC. Next (GATED): **first U4 implementation slice — only if/after
the §2.3.11.6 FIRST_ACTIVE review is approved.**

Ground-station pre-ride setup flow, iPhone mDNS proposal, and `w17-3d-codex`
bootstrap status remain as recorded below._

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `8ed0a6c` | R1–R5-b remediation complete (`72d5347`); 224/224 native tests; all ESP32 environments build; live watchdog-cycle observation and physical reset-path validation pending. `8ed0a6c` = docs-only: U4 head-intent shaping/arbitration DESIGN (`head_tracking_unlock_plan.md §2.3.11`) — no firmware/behavior change |
| `w17-ground-station` | `dce91f8` | CB8 slice 3B head-intent subscriber (`03f43e2`) + slice 3C proto-drift guard & integration evidence (`dce91f8`); 746/746 tests; OS paths bench-unvalidated |
| `w17-mapper` | `59d1739` | owned fork (`w17-headtrack` off upstream `2b8031a`); CB8 slices 1–3A committed: LOG-ONLY UDP 5602 head-intent ingest + read-only gRPC diagnostics; go build/test green; push disabled |
| `w17-soundlight-fw` | `4f25856` | clean |
| `w17-3d-codex` | `80e7f74` | bootstrapped 2026-07-10: 210 files classified (37 required staged), docs + gates written; 4 human gates open, nothing printed |
| `iPhone_rc` (Codex) | `84532ed` | VR FPV plan consolidation (H1–H11 applied; canonical contract sync revision); Batch 1 VR-calibration work remains uncommitted in its working tree |
| `w17-rc-print-codex` (Codex) | `75b408c` | has existing untracked reports |

> Checkpoints drift as work continues. Re-verify with `git -C <repo> rev-parse --short HEAD`
> before relying on any hash here.
>
> `CURRENT_STATUS.md` may record hashes for other repos, but should not try to record the
> exact hash of the repo that contains it (that would go stale on every commit that touches
> this file).

## Hardware gates

- **A1.1–A1.6 software / pre-power validation: COMPLETE.**
- **A2 no-power bench checklist: committed but NOT EXECUTED.** No measurements recorded; A2
  is not closed. Canonical checklist:
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`.
- **Phase B (powered) is BLOCKED** until A2 is filled in, pasted back, reviewed, and approved.
- Golden rule: ESC motor power stays disconnected until the failsafe + arm chain is proven
  live (Phase A → B).

## Firmware freeze status

- **CF-1 delivery tuning persistence: RESOLVED.**
  - Delivery `esp32dev` loads the complete validated NVS settings object at boot.
  - Missing, corrupt, outdated, or invalid settings fall back atomically to complete compiled defaults.
  - Tuning console and settings mutation remain available only in `esp32dev_tuning`.
  - Native tests: **153/153 passing**.
  - `esp32dev`, `esp32dev_tuning`, and `esp32dev_sim` build successfully.
  - Physical NVS save → reflash → reload behavior remains a powered-bench verification item.
- CF-2 steering endpoint tuning: RESOLVED.
  - `steer.min` and `steer.max` are available in `esp32dev_tuning`.
  - Endpoint updates are atomically validated and persisted through the existing settings blob.
  - The settings layout and blob version remain unchanged.
  - Delivery `esp32dev` remains console-free.
  - Native tests: 168/168 passing.
  - All ESP32 environments build successfully.
  - Actual endpoint values remain Phase-B hardware calibration evidence.
- Console parsing hardening: COMPLETE.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - Native tests: 195/195 passing.
  - All ESP32 environments build successfully.
  - Delivery and simulation remain console-free.
- **Control-firmware software remediation through R5-b: COMPLETE.**
  - Delivery loads validated NVS tuning while remaining application-console-free.
  - Steering minimum and maximum endpoints are configurable in the tuning build.
  - Numeric setting values are checked before narrowing.
  - Gear indexes are parsed without signed-overflow risk.
  - The Arduino `loopTask` is directly subscribed to the global Task Watchdog with a
    provisional 2-second timeout.
  - The watchdog is fed exactly once after each completed 50 Hz actuator-control tick.
  - All watchdog API failures are handled fail-fatally.
  - RTC-retained reset diagnostics classify every reset reason in the pinned ESP-IDF
    version.
  - Tuning and simulation builds print the boot reset reason and retained-session count;
    delivery remains silent.
  - Native tests: 224/224 passing.
  - All ESP32 environments build successfully.
  - Live Wokwi stall → watchdog panic → reboot observation: PENDING.
  - Physical reset reason, RTC retention, panic/reboot-to-safe-output timing,
    GPIO13/GPIO14 reset state, and real ESC signal-loss behavior remain Phase-B evidence.

## VR-FPV batch status (Claude side)

Batch definitions + session prompts: `VR_FPV_MASTER_PLAN.md` (stable). Update this table
at the end of every VR-FPV session; one-line evidence only.

| Batch | Name | Status | Evidence / blocker |
|---|---|---|---|
| CB0 | Mapper feasibility investigation | `DONE` | 2026-07-14: upstream `elrs-joystick-control` (`2b8031a`) read read-only in `_vendor/`; unlock plan §2.3 = verified findings (no UDP/plugin/virtual-axis ingest — fork needed; diagnostics republish already exists over gRPC; minimal-fork shape + dual GPL/Fair-Source license documented); decision package + options (a)/(b)/(c) presented → **owner decision #1 now actionable** (topology + fork ownership + fork license) |
| CB1 | GS right-stick indicator | `NOT_STARTED` | authorized; code+tests in w17-ground-station |
| CB2 | Gimbal explainer artifact | `NOT_STARTED` | optional |
| CB3 | Firmware comment hygiene | `NOT_STARTED` | tiny; ChannelDecoder.hpp:57-58 |
| CB4 | Windows mDNS discovery | `NOT_STARTED` | optional; canonically unblocked at `84532ed` |
| CB5 | Video baseline verification (Windows) | `BLOCKED_HARDWARE` | needs camera; pairs with Codex Batch 0 |
| CB6 | Real-device W2/W3 validation | `BLOCKED_HARDWARE` | needs iPhone + non-isolated bench network |
| CB7 | Placement decision support | `BLOCKED_HARDWARE` | needs printed halo/body dry-fit; owner decision #4 |
| CB8 | Mapper implementation | `IN_PROGRESS` | decision #1 RESOLVED (topology (a), §2.3.7). **Slice 1 DONE 2026-07-15:** `w17-mapper` fork (`w17-headtrack` @ `2b8031a`, GPL-3.0) — new pure-Go `pkg/headintent` log-only UDP 5602 ingest + in-process diagnostics; go build/vet/test/-race all green; `go list -deps` proves no config/link/crossfire/serial dep; no existing file imports it (output unchanged); 299/300/301 + port-exclusivity proven. **Slice 2 DONE 2026-07-15:** `cmd` wired behind disabled-by-default `-headtrack-ingest`/`W17_HEADTRACK_INGEST` (+`-headtrack-port`) — starts receiver and nothing else; `pack_deadend_test.go` proves `crsf.PackChannels` byte-identical flag-off vs on (valid/stale/invalid); host `go build ./...` blocked only by pre-existing go1.26×`go.bug.st/serial` cgo incompat (temp `v1.7.1` bump builds green, reverted — send-path dep = owner decision). **Slice 3A DONE 2026-07-15:** mapper-side gRPC diagnostics — read-only `WatchHeadIntentDiagnostics` stream (enum state, server-computed age, 4-stream cap→ResourceExhausted, nil→Unavailable, bounded latest-value buffers); stubs regenerated with pinned drift-checked toolchain via `pkg/proto/generate.sh`; `go build`/`test ./...` green, webpack compiles; CRSF byte-identical with subscribers connected/slow/disconnected; :10000 still `[::]` (unchanged). **Slices 1–3A COMMITTED 2026-07-15** in `w17-mapper` @ `59d1739`. **Slice 3B DONE** (GS Electron subscriber @ `03f43e2`). **Slice 3C DONE 2026-07-15** (GS @ `dce91f8`): hermetic proto-drift guard (`test/protoDrift.test.js` vs a live-mapper-generated canonical snapshot, regen zero-diff, bites on drift) + real cross-process run vs live mapper gRPC :10000 (every HeadIntentState, ingest-off→UNAVAILABLE, 4-cap→RESOURCE_EXHAUSTED, restart→bounded reconnect, byte-identical CRSF, topology-(a) mutual exclusivity); GS 746/746; validation-only serial bump reverted (modules pristine). Evidence: `w17-ground-station/docs/2026-07-15_cb8_slice3c_integration_evidence.md`. **Slice U4 DONE 2026-07-15 (DESIGN ONLY, SAFETY-GATED):** shaping/arbitration model + 9 safety invariants + Group A/B/C test matrix + two-part FIRST_ACTIVE flag + FIRST_ACTIVE review checklist R1–R14 written to `head_tracking_unlock_plan.md §2.3.11`; **no code** (deliberate — gated behind the review), `w17-mapper` clean at `59d1739`, no active enum value, PackChannels byte-identity + GS 746/746 + proto:check unchanged. Next (GATED): **first U4 implementation slice — only if/after FIRST_ACTIVE review approved** |
| CB9 | Gimbal endpoints + console | `BLOCKED_HARDWARE` | HARD GATE: A2 + Phase B; needs CB7 mount |
| CB10 | Integration + bench milestone | `BLOCKED_EXTERNAL` | needs CB8, CB9, Codex Batches 5–7, FIRST_ACTIVE review |

Open owner decisions: #1 UDP 5602 topology + fork ownership — **RESOLVED 2026-07-15
(topology (a); owned-fork path/name + license still to approve before source)** · #2 active
video-loss response · #3 failsafe hold-vs-center (in CB9) · #4 camera placement (in CB7)
· #5 head-tracked driving protocol/spotter.

## Pending validations

- **Real iPhone ↔ Windows bridge validation: PENDING (in progress).**
  - **Windows GS host stood up (2026-07-09):** fresh clone of `w17-ground-station` at
    checkpoint `dab3039`, `npm install` done, `npm test` green (118/118) on Windows —
    identical to macOS. No source/schema/firmware/dependency drift.
  - **Blocker — network client isolation:** the office guest Wi-Fi (`SE-Guest`, Public
    profile) isolates clients — laptop↔laptop ping fails both ways — so direct LAN UDP for
    W2/W3 cannot pass. Real cross-device validation needs a **non-isolated** network; this
    is a network limitation, not a bridge bug.
  - **Approach:** spare-phone (Android) Mobile Hotspot now; **Ralink RT5370 USB Wi-Fi as a
    PC-hosted SoftAP** as the permanent bench network (ordered — AP-mode support on Win
    10/11 to be verified on arrival); FPV **camera AP** for a later field-representative
    pass. Gate every attempt on a peer-to-peer ping before any UDP test.
  - Not yet run end-to-end against a real iPhone (no device on hand yet).
  - **New since 2026-07-10 — in-app setup flow supersedes manual network setup:** the
    ground station (checkpoint `3c16954`) now scans/joins WiFi and hosts a hotspot
    itself (Mobile Hotspot backend preferred; legacy `hostednetwork` fallback targets
    the RT5370, needs elevation), runs the peer ping as a first-class GRID check, and
    can enable W2/W3 from persisted settings (`settings.json` in userData; **set env
    vars always win**). Orchestration logic is unit-tested against canned command
    output (217/217); the **real OS layer is UNVALIDATED** — runbook with evidence
    boxes: `w17-ground-station/docs/setup_flow_bench_checklist.md`. W3 remains
    LOG-ONLY (new: it exposes the last accepted sender's IP as a user-confirmed
    address suggestion — transport metadata only, guard-tested).
- **mDNS discovery of the iPhone HUD: ADOPTED canonically, Windows side NOT BUILT.**
  The canonical contract carries a Discovery section (`_w17hud._udp.local.`, advisory
  user-confirmed hints only; canonical 2026-07-10, mirrored at rev `84532ed`
  2026-07-14) and the iPhone advertises since `1e332ef`. The Windows-side
  implementation remains unbuilt; the proposal
  (`w17-ground-station/docs/proposals/iphone_mdns_discovery.md`) can proceed as
  ordinary reviewed work against the canonical section.
- **Active iPhone-derived pan/tilt: BLOCKED** behind a separate, reviewed safety milestone.
  Until then: no iPhone → CRSF, no iPhone → servo/gimbal, firmware stays iPhone-unaware, and
  the Windows W3 (UDP 5602) receiver is LOG-ONLY.
- **Head-tracking / VR consolidation (2026-07-14, documentation only, uncommitted):**
  - New docs: `w17-control-fw/project-review/head_tracking_unlock_plan.md` (unlock
    sequencing + mapper process boundary; proposed mapper host = elrs-joystick-control),
    `w17-3d-codex/CAMERA_GIMBAL_PLACEMENT.md` (placement source of truth),
    `w17-ground-station/docs/camera_aim_display_semantics.md`,
    `w17-ground-station/docs/video_topology_baseline.md` (approved H.264 720p60
    dual-consumer baseline). Stale-timeout canon ratified at **300 ms** (supersession
    notes added to both 400 ms readiness references).
  - **CB0 investigation COMPLETE (2026-07-14, read-only):** upstream `elrs-joystick-control`
    (`github.com/kaack/elrs-joystick-control`, HEAD `2b8031a`) cloned read-only into
    `_vendor/elrs-joystick-control` and read. Findings (unlock plan §2.3, now verified): the
    app is an SDL-gamepad node-graph mixer with **no UDP / plugin / virtual-axis ingest** (only
    gRPC:10000 + HTTP:3000) — head-intent ingest needs a **source-code fork** (new UDP source
    package + head-intent/arbitration nodes; send path untouched); a one-way read-only
    diagnostics republish to Electron **already exists** via the gRPC streaming RPCs; upstream
    is dual-licensed **GPL-3.0-or-later OR Fair Source 0.9** (1-user limit on the FS option).
    UDP 5602 remains an exclusive bind. Topology options (a)/(b)/(c) mapped with evidence;
    evidence leans (a) (smallest surface) but topology + fork ownership + fork license are
    **open owner decision #1** — not chosen here.
  - **Codex handoff DELIVERED and APPLIED:**
    `_handoff/2026-07-14_codex_handoff_vr_fpv_cross_review.md` (11 items, H1–H11)
    applied by Codex in canonical commit
    `84532ed870ee9dc4563217a78ae112ccd0f1c8f6` ("Consolidate VR FPV integration
    plans") across the VR plan, both safety docs, and the canonical contract.
    Codex outcomes: video baseline ratified (H.264 720p60, simultaneous iPhone
    RTP + Windows RTSP/WHEP); mapper host = owned/forked elrs-joystick-control;
    992 = commanded center; stale boundary 299/300 fresh, 301 stale; future
    active motion-sample freshness ≤ 250 ms (current 500 ms is log-only-grade);
    camera_yaw/pitch = commanded mirrors; near-limit = coarse `warning` text
    only in v1 (no new schema field).
  - **Contract mirror COMPLETE and ACCEPTED (2026-07-14):** canonical revision
    `84532ed` mirrored into `w17-ground-station/docs/windows_bridge_contract.md`
    (sections 1–7 + Discovery byte-identical to canonical; Windows appendix
    retained, stale mDNS-proposal note corrected). Both sides record `84532ed`
    as the sync revision; **Codex confirmed acceptance of the mirror 2026-07-14**.
    No further contract changes requested; Codex continues iPhone Batch 1
    optical/HUD calibration without schema or control-path changes. UDP 5602
    mapper/diagnostic topology and active video-loss response remain explicitly
    open owner decisions.
