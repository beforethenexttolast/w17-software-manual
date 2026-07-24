# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes**,
with a single carve-out: physical hardware *arrival / on-hand* status lives in
`HARDWARE_INVENTORY.md` (the parts delivery log, mapped to BOM v2). That file carries no
commit hashes and no gate / software / execution state, so this file stays the sole
workspace-level source for all of those and for project execution status.
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: **2026-07-25** (workspace bookkeeping sync — see the 2026-07-25 entry below and the
corrected Checkpoints table; the dated entries that follow are preserved as an as-of log, so read the
Checkpoints table and the newest entry for current truth).

Earlier baseline, 2026-07-17. Control-firmware remediation through R5-b is complete:
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

2026-07-15 (later): **FIRST_ACTIVE consolidation — owner decisions RECORDED (docs only,
uncommitted).** In `w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.12 +
§3.1 + §4/§5: decision **#2 video loss** resolved (sender-side suppression → ordinary
mapper stale decay; video never directly commands servo/CRSF; operator-facing
degraded-video state required); **#3/U8 radio loss** resolved FOR BENCH ONLY (hold-last
stands; MUST re-review before driving); **#5 driving** resolved (FIRST_ACTIVE bench-only,
wheels off, operator present, e-power removal, ±5 mech deg first travel; separate
driving-readiness milestone with reviewed gate + spotter). Also recorded: invalid-packet
policy (one invalid ⇒ eligibility removed + decay; repeated ⇒ latched fault; recovery =
disarm + valid-data interval + explicit recenter), GLOBAL manual-override (both axes, wins
in active AND decay, latched, no auto-restore), hybrid yaw→pan/pitch→tilt position→rate
mapping (roll ignored, no discontinuity), and the shaping-constants **derivation policy**
(deadband from measured jitter, floor 1°/cap 3°; 10°/s; 20°/s²; takeover = max(noise,
~10% half-range); missing calibration ⇒ fail closed; NO production values signed). Fork
license **GPL-3.0-or-later + provenance recorded (R11 PASS)**; `go.bug.st/serial`→v1.7.1
**approved as a future isolated mapper slice** (not mixed with anything). **Controller
affordances L1+R1 deadman / R3 recenter FAILED the conflict audit** (R1/L1 = gear up/down
in every GS SEAT-FIT preset; R3 perturbs the pan/tilt stick) — NOT adopted. **Owner-choice
RESOLVED 2026-07-15 → Alternative C (bench-only):** short-press SHARE = recenter; hold D-pad
DOWN + OPTIONS 1 s = arm; OPTIONS may then release; D-pad DOWN is the continuous held deadman
(release = disarm); the right thumb stays free for right-stick manual takeover. A and B
rejected (held two-thumb chords impede that takeover). **Live mapper node-graph binding
validation (SHARE/OPTIONS/D-pad DOWN unbound) still required; bench-only, NOT for driving**
(decision #6, §2.3.12.6). iPhone **R10 = PASS (automated only)**: 250 ms send-time gate verified
read-only in `iPhone_rc` (249/250 eligible, 251 stale; cached-active cannot bypass);
uncommitted — real-device lifecycle/axes/mount + canonical commit + mirror still pending.
U4 design addendum completed (states/transitions/guards + required test per behavior) and
the canonical execution order **A–O** recorded (§3.1). **FIRST_ACTIVE overall verdict:
NO-GO / BLOCKED** — R1/R2/R6–R9/R12/R13 remain hardware/evidence class; no missing
hardware evidence was converted to PASS.

2026-07-15 (later still): **Windows ground-station reliability slice — IMPLEMENTED on
macOS, COMMITTED as `e0a5cdc`, in `w17-ground-station` only.** Addresses five real Windows
observations: (2A) production full-screen launch (NOT kiosk; F11 restore; dev override
`W17_FULLSCREEN`); (2B) live WLAN-adapter discovery while the Network page is open
(main-process `adapterMonitor.js` bounded polling → `adapter-state` push); (2C) adapter-
disconnection transitions (join early-aborts `kind:'adapter-missing'`; a live hotspot marked
INTERRUPTED / re-verified when its adapter set changes; vanished selected adapter invalidates
the pick, no auto-switch); (2D) honest hotspot **DHCP/ICS readiness** model
(`hotspotVerify.js`: WinRT tether state + ICS `192.168.137.x` gateway + `SharedAccess`/`icssvc`
service state → `verified`/`degraded`; `idle→verifying→verified/degraded`+`interrupted`; a
start-command success is never shown as client-ready); (2E) auth-error UX (terse wrapped
summary + expandable scrollable redacted detail; no overlap; clears on new op).
`shared/redact.js` scrubs secrets from any surfaced command output. **Evidence:** `npm test`
**798/798** (46 files; +52 reliability tests; the pre-existing WIP had left the suite 5 red —
now repaired by completing the wiring), `npm run smoke:electron` **4/4** (live preload surface
24 methods, console-clean), `npm run proto:check` OK. **No** bridge schema / canonical contract
/ control path / firmware / mapper / iPhone change. **Pixel/hotspot root-cause distinction
(no overstatement):** the **proven code/UI root cause** is that a successful hotspot-start
*command* was treated as client-readiness without verifying ICS/gateway/services/DHCP; the
physical Pixel "Obtaining IP address" failure has a **leading hypothesis** (missing/broken ICS,
no subnet gateway, DHCP service down, driver/AP-mode limits, or adapter/backend behaviour) but
its **actual cause remains UNPROVEN** until the real-Windows validation captures host gateway,
ICS + `SharedAccess`/`icssvc` state, adapter/backend, and the Pixel lease result. The
verified/degraded model correctly stops a false "ready" but does not itself prove end-to-end
DHCP. **Windows/Pixel behaviour UNVALIDATED** on this macOS host (real adapter timing, ICS/DHCP
enablement, and the **Pixel IPv4-lease path** remain the next-session Windows validation).
Durable tracker + runbook: `w17-ground-station/docs/2026-07-15_windows_reliability_slice.md`.
These changes are **committed as `e0a5cdc`** and **Windows CI is GREEN at `e0a5cdc`**
(run `29440396447`).

2026-07-16: **Ground-station Batch F closed + verified (this implementation plan).** The
reliability slice landed as `e0a5cdc`, and the earlier CB8 3B/3C (`03f43e2`/`dce91f8`) plus the
2026-07-15 documentation-sync (`8c5af12`, terse msg "some chages") were pushed — `w17-ground-station`
`main` is **level with `origin/main` (0 ahead / 0 behind)**. The Batch F documentation re-sync
(audit banner/hardware-matrix CI SHA/transfer checkpoints/Batch-F section, bench-checklist baseline
746/43→798/46, reliability-slice CI note, and the README/SETUP hotspot readiness-lifecycle step) was
committed **docs-only** as **`170fd66`**. **Windows CI is GREEN for both:** app HEAD `e0a5cdc` = run
`29440396447`; docs `170fd66` = run `29473220328` — each ran ubuntu `test` + windows-latest
`package-smoke` (`npm test` **798/798, 46 files** + `npm run smoke:electron` **4/4** + `electron-builder
--dir`). Real **Windows/Pixel hardware** validation of the reliability slice is still pending. The separate SEAT-FIT / camera-mode display track named here has since grown into the
full **setup-flow redesign (Batches 0–9) — now SHIPPED, AUDITED, and PUSHED** (`8441adb`; see the
`w17-ground-station` Checkpoints row and the 2026-07-17 entry below). **Batch G not started.**

2026-07-17: **Hardware delivery (partial).** Electronics arrived: **3× ESP32 boards**,
**BL-M8812EU2 USB WiFi module** (the camera's 5.8 GHz video-link module), **ELRS TX**,
**LiPo voltage tester**, **resistor kit**. Mechanical items (MR128ZZ front bearings ×10,
3×32 mm turnbuckle, M4 rod-end linkage balls ×10, M3 tie-rod-end ball caps, steel threaded
rods, aluminium tube) are logged in `w17-3d-codex/GENERAL_PLAN.md` open-questions item 5.
Still awaited (per that item + the RT5370 note below): tyres, shocks, servos, king pins,
belt set, blower, rear 6801 bearings, RT5370 USB Wi-Fi. Delivery changes no software
status: A2 remains unexecuted, Phase B remains blocked, and no unattended
flashing/powering. CB5 (video baseline) remains gated on assembling/verifying the
camera + BL-M8812EU2 pair on a bench.

2026-07-17 (later): **Owner approved a BARE-BOARD USB smoke test** as a scoped exception to
the pre-A2 no-powered-bring-up rule (`w17-control-fw/CLAUDE.md`): one naked DevKit at a
time, USB from the Mac only, **nothing connected to any pin**, attended, no
battery/PSU/ESC/servo; A2 + Phase B stay in force for the car harness. Procedure manual:
`learning-manual/13_bare_board_smoke_test.md` (includes the physical NVS
save→reset→reload evidence steps and a per-board evidence template). All software suites
re-verified green on this machine today: control-fw native 224/224, soundlight native
94/94, ground station 976/976 (52 files — SEAT-FIT WIP has grown the suite past the
recorded 798/46), mapper `pkg/headintent` ok. Smoke test NOT yet executed; results to be
pasted back into a session.

2026-07-17 (later still): **Setup-flow redesign (Batches 0–9) SHIPPED, AUDITED, and PUSHED**
in `w17-ground-station`. The SEAT-FIT/camera-mode display track named above grew into the full
pre-race setup redesign: PIT WALL/SEAT FIT layout fixes, a generic **steering-wheel display
mirror** + assign/calibrate UI, HUD wheel mirroring, flow chrome (step rail, solid backdrop,
GARAGE fast-path card, HUD status stack), step reorder (SEAT FIT before PIT WALL; desktop skips
PIT WALL), and controller-driven UI navigation. All 11 commits `a88692d..9855cc3` are on `main`
and now PUSHED; the final audit is committed docs-only as **`8441adb`**
(`w17-ground-station/docs/audits/2026-07-17_setup_flow_redesign_audit.md`) and also pushed.
Suite **984/984 (52 files)**, smoke 4/4 (apiKeys 24), proto:check OK,
noControlPath/ipcSurface(24)/responsiveLayout green; live CDP-driven sweep at
1280×800/1366×768/1024×640/fullscreen. Audit verdict: history maps 1:1 to plan batches, all 7
invariants PASSED, and **9 findings recorded but NOT fixed at that time (deliberate — follow-up
work):** 1 HIGH (calibrated wheel profile silently dropped by `normalizeSettings`); 1 MED (HUD wheel
mirror can resolve the wrong device when the wheel is absent at START); 4 LOW UX/display defects;
1 docs gap; plus a design-bundle-§10 deviation and a readAxis-dedupe observation. **All 9 have since
been closed — see the 2026-07-25 entry below; do not read this paragraph as a list of open work.**
Windows CI at `8441adb` was not re-verified in that session (green recorded later at `3119180`, run
`29724061397`).

Ground-station pre-ride setup flow, iPhone mDNS proposal, and `w17-3d-codex`
bootstrap status remain as recorded below._

2026-07-22: **Zero-hardware suite re-verification** (read-only session, no source edits).
All green: `w17-control-fw` native **224/224**; `w17-soundlight-fw` native **94/94**
(README corrected from a stale "40" — see repo commit); `w17-ground-station` `npm test`
**1046/1046 (53 files)** — grown further past the `8441adb`-era 984/984 recorded above
(recent SEAT-FIT/wheel-support work), `npm run smoke:electron` **4/4**; `w17-mapper`
`go test ./pkg/headintent/...` all green (full `./...` still blocked only by the
pre-existing go1.26 × `go.bug.st/serial` cgo incompat, not a new failure). The 976/976 →
984/984 progression recorded above (2026-07-17) is left as-is — it's an accurate log of
what was true at each point that day; this entry just adds the next data point.

2026-07-22 (later): **BARE-BOARD USB SMOKE TEST EXECUTED — all 3× ESP32 DevKit PASS**
(attended, owner present for every plug/unplug; procedure `learning-manual/13_bare_board_smoke_test.md`;
scoped 2026-07-17 exception — A2 + Phase B untouched, nothing on any pin, USB-only). Boards are
**USB-C DevKit V1 clones** (manual §2 assumed micro-USB): silkscreen "ESP-32D", flasher-confirmed
**ESP32-D0WD-V3 rev v3.1** (classic ESP32; `ets Jul 29 2019` ROM banner), **CH340C** USB-UART
(VID:PID 1A86:7523), 30-pin. MACs: #2 `b4:bf:e9:05:61:4c`, #3 `b4:bf:e9:06:9f:d4` (#1 not captured).
Each board flashed `esp32dev_tuning` clean (no BOOT hold), booted `reset=POWER_ON boots=1 retained=no`
+ `[tune] loaded settings from flash` (non-virgin from the owner's prior flash — expected; no NOT_FOUND);
console help/status/get/set/save/reset all correct (center=1500, gears=4, channels 0/2/4/5 placeholder
confirmed). **Physical NVS persistence PROVEN on all three:** a fresh distinct write (steer.trim 5→12)
survived an EN power-cycle (`loaded settings from flash`, get=12), then reset→0→save→EN→get=0 (defaults
persisted). No panic / TASK_WDT / BROWNOUT; only mild warmth reported, none flagged hot. All three
returned to compiled defaults and unplugged/labeled 1/2/3. One §12.1 serial-port-lock recurrence during
board-3 flash (stray monitor held the port; cleared, reflashed OK). **NOT done / still open:** optional
reflash-survival + delivery-silent legs (skipped); crash-class reset classification + RTC retained-counter
increment unexercised (only POWER_ON seen, by design); board role assignment deferred to harness assembly;
A2 / Phase B unchanged. Per-board §11 evidence: `learning-manual/13_bare_board_smoke_test_evidence.md`.

2026-07-24: **Batch-1 physical measurement session (no-power) — component envelopes + weights
captured; A2 / Phase B UNCHANGED.** No power/battery/PSU/USB/flashing; harness is still loose
modules so A2 §3–§9 was not executable and was not run. Calipers + gram scale only. Results +
Codex mechanical-register handoff: **`w17-batch1-measurements-for-codex.md`** (workspace root; Claude
does not edit `w17-3d-codex`). Photos in `w17-3d-codex/images_of_parts/batch_1/`.
- **Board decision (owner):** both controllers will be **MH-ET Live D1-Mini ESP32** (frees cassette
  space; USB-C variant being sourced). This makes the ZK "FIRM" 39×31 board premise true by
  procurement — the 39 mm wall-row / `X+3…+42` seat / `S0≥9.82 mm` derivations stand. The on-hand
  USB-C DevKit V1 clones (30-pin) are **TEST/SPARE only**, not the cassette controllers. Real MH-ET
  caliper + weight pending purchase (ZK CAS-03 stays open on the physical board).
- **Two height findings on the #1 blocker (steering clearance, `KO-01 Z22 − PDB top Z19 = 3 mm`,
  5 mm short of policy):** UBEC measured **9.1 mm** (ZK assumed ~18 mm "UBEC-dominated") → PDB height
  can drop → *helps*; QuicRun ESC installed height **34 mm** (fan+heatsink on top) vs documented
  24.2 mm → ESC floor station Z1.5…25.7 too short → *reopens ESC clearance* (CAS-06/ASM-49).
- **BL-M8812EU2 = 32.4×32×7 mm, 11.2 g** → fits the ≤60×32×12 allocation → **D-06b unblocked** (was
  uncalipered/unplaced).
- **DS3235SG side face 40.25×20.2** vs 42×18.5 arch → **~1.7 mm height interference confirmed**
  (fit study predicted ~1.5 mm); physical no-force dry-fit (Track D) + steering sweep/S0/arch
  (Track C) still pending; do not file/force test-grade prints.
- Weights lighten the CG control/RF group (assumed 72.5 g); motor 156.7 g / ESC 100 g / servo 70.3 g
  dominate; four-corner scaling deferred to a rolling assembly. Details in the handoff doc.

2026-07-24 (later): **Electrical BOM FINALIZED + all items ORDERED (owner) — no gate change.** Every
remaining cassette electronic module is chosen and en route; no open sourcing decisions remain. **A2 still
NOT-EXECUTED, Phase B still BLOCKED** — ordering is not powering; the harness must still be built and A2
run before any power. Ordered: 2× MH-ET D1-Mini ESP32 (USB-C), ceramic + electrolytic cap kits (covers
1000 µF servo-rail + LED, 100 nF, opt 1–10 nF), **Amass XT90-S anti-spark master switch** + XT60→XT90
adapter, **IP2326 2S Type-C balancing charger** (18.3×31 mm, confirmed balancing), **ZEEE 1500 mAh 2S
LiPo** (69×35×18, JST-XH; owner will re-terminate to XT60); 1N5819 from office stock. (These ordered/
in-transit rows still owe an entry in `HARDWARE_INVENTORY.md` as ⏳ — left for that file's in-progress
edit; not touched here to avoid clobbering its uncommitted rewrite.) New Claude-side build docs:
**`w17-pdb-build-and-connector-guide.md`** (PDB schematic/topology, connector proposal with genders +
proposed cable lengths, capacitor placement + soldering guide, pins reconciled to `PinMap.hpp`) and the
Codex recalc handoff **`w17-codex-batch1-recalc-prompt.md`** (PDB-height re-derivation, ESC 34 mm station
reopen, Wi-Fi placement close, CG refine, dock/charge routing). Physical caliper of the MH-ET boards + the
actual 1000 µF, and the Track C/D fit-gates, still await parts/printed-part sessions.

2026-07-25: **Workspace bookkeeping sync (docs-only, no hardware) — A2 still NOT-EXECUTED, Phase B
still BLOCKED.** Nothing here touched firmware, gates, or any control path.
- **Pushed finished work.** `w17-soundlight-fw` `4f25856..ec5ddf8` (11 commits) after verifying
  native **94/94**; `w17-design-system` `b301de0..6a59c96` (1 docs commit). Workspace repo: `main`
  fast-forwarded onto the `w17-batch1-measurements` branch tip and pushed (`bb8e7e7..c5d32c7`) —
  the branch was a strict descendant, so the merge was a clean fast-forward; the branch ref is now
  redundant and retained only as a label.
- **Ground-station audit findings — ALL 9 CLOSED** (the checkpoint row and the 2026-07-17 entry are
  corrected accordingly). Finding 1 (HIGH, wheel profile never persisted) fixed in **`a04b07c`**:
  `normalizeSettings` now admits a validated `wheel.profile` subtree via conditional spread
  (`shared/settings.js:191`) with a CJS-local `normalizeWheelProfile` mirror, a parity test against
  the ESM `shared/wheelProfile.mjs`, and a hostile-corpus persistence test
  (`test/wheelProfilePersist.test.js`). Findings 2/3/4 fixed in **`5141912`** (absent wheel yields
  no mirror and an honest `INPUT · WHEEL (NO DEVICE)` tag instead of driving a gamepad through wheel
  calibration; WHEEL mode gains its own device selector; `wheelActive` gating). Findings 5/6/7 fixed
  in **`ec1baef`** (⚙ inert to the pad during the start-lights countdown; fast-path card focused on
  boot only; in-code deferral markers). **`085e1d1`** then fixed a defect that closure-verification
  of `ec1baef` itself surfaced — the BOTH-mode source tags shipped `.barsrc hidden` but `hud.css`
  had no generic `.hidden` rule, so the class was visually inert and the tags leaked into
  GAMEPAD-only and WHEEL-only modes; the jsdom class-only assertions had passed vacuously. The
  design-bundle §10 observation was resolved both ways in **`e57f587`** (Decision B), and the
  `readAxis`/`clampAxis` dedupe observation is explicitly **waived in-code** at
  `shared/wheelProfile.mjs:88`. Verified against live code this session, not taken from commit
  messages. **Consequence: the session prompt `w17-gs-audit-followups-prompt.md` is now wrong where
  it says "Findings 2–7 are still open" — a correction banner was added to it rather than deleting
  the prompt.**
- **`HARDWARE_INVENTORY.md`**: the 2026-07-24 electrical order is now recorded there as a new **§E**
  section, all rows **⏳ in transit** (2× MH-ET D1-Mini ESP32 USB-C, ceramic + electrolytic cap kits,
  Amass XT90-S master switch + XT60→XT90 adapter, IP2326 2S Type-C balancing charger, ZEEE 1500 mAh
  2S LiPo, plus the 1N5819 as 🏠 office stock). The debt that the 2026-07-24 entry recorded is
  discharged. That file still carries arrival status only — no hashes, no gate state.
- **Cross-repo follow-up closed (elsewhere):** the `w17-3d-codex` "stop tracking arrivals" cleanup
  that `HARDWARE_INVENTORY.md` listed as owed has in fact landed there as `59a1634` (2026-07-22) —
  **but that commit is unpushed.** Not edited or pushed from here.
- **Root artifact triage.** Nine spent ground-station artifacts deleted (the `a1` / `a1-a2` /
  `through-d1-d4` patches, their three audit copies, two `git status` snapshots, and the
  planning handoff). Proof before deletion, not assumption: the committed
  `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md` (2592 lines) is a
  strict superset of the 1818-line root copy and names the landing chain itself — `79fa2e0`
  ("a lot of chagnes", 62 files, +10524/−570) → `0564141` → `297ca79` → `8ceb931` → `0e85702`;
  90–96% of every patch's added lines are present verbatim at GS HEAD, and each apparent gap was
  traced with `git log -S` to `79fa2e0` followed by later refactoring in `e0a5cdc` / `8c5af12` /
  `d822c80`. The planning handoff's four changes are exactly GS `3119180` and its "FINAL, SEPARATE"
  design-system item is `6a59c96`; its named intermediate deliverable
  (`w17-ground-station-impl-plan.md`) was never written to disk, so the plan was consumed in-session.
  Live session prompts, the six Codex handoff docs, and the steering-servo fit diagram were committed
  instead. `.claude/` and `.preview-tmp/` are now git-ignored; `.preview-tmp/` was deleted.

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `1834852` (branch `docs/bom-cassette-electrical`) · `fbf22f0` (`main`) | **Checked out on a branch, not `main`.** `main` = `fbf22f0` (docs: FIRST_ACTIVE decisions + Alt-C bench controls), pushed. Branch `docs/bom-cassette-electrical` is 2 ahead and pushed to its own remote: `78e1e88` (BOM — 2× D1-Mini ESP32 on-car, IMX335 camera, cassette PDB/charge/connectors) → `1834852` (BOM — name the onboard 2S charger, IP2326 primary / BQ25887 alt). Nothing unpushed. The previously recorded `8ed0a6c` is a real ancestor of both, just 3 commits stale. Firmware unchanged by any of it (docs-only): R1–R5-b remediation complete (`72d5347`); 224/224 native tests; all ESP32 environments build; live watchdog-cycle observation and physical reset-path validation still pending. **Branch is unmerged — decide merge-vs-keep before relying on `main` for BOM content.** |
| `w17-ground-station` | `3119180` | **Windows CI GREEN at this HEAD: run `29724061397` (2026-07-20) — 1046/1046, 53 files**, both the ubuntu `test` job and the windows-latest `package-smoke` job (suite + `smoke:electron` + `electron-builder --dir`). `main` level with `origin/main`. `3119180` = setup-flow follow-through (reorder PIT WALL before SEAT FIT, DRIVE MODE display preference, SEAT FIT rebalance, start-lights off by default) — the four changes from the 2026-07-19 planning handoff. **All 9 findings of the 2026-07-17 setup-flow audit are now CLOSED** (see the 2026-07-25 entry); the audit document's own §3 still reads "none applied" and is the stale artifact. **An uncommitted 7-file WIP sits on top of this HEAD** (`renderer/hud.css`, `renderer/index.html`, `renderer/setupFlow.js`, `shared/setupSteps.mjs`, + 3 test files) splitting a new `SETUP` step out of SEAT FIT — not reviewed, not committed, and NOT covered by the CI run above. Real-OS/Windows-hardware paths remain bench-unvalidated. |
| `w17-mapper` | `59d1739` | owned fork (`w17-headtrack` off upstream `2b8031a`); CB8 slices 1–3A committed: LOG-ONLY UDP 5602 head-intent ingest + read-only gRPC diagnostics; go build/test green; push disabled. Verified unchanged 2026-07-25. |
| `w17-soundlight-fw` | `ec5ddf8` | **PUSHED 2026-07-25** (`4f25856..ec5ddf8`, 11 commits — the previously recorded `4f25856` was exactly the stale remote tip). Native `pio test -e native` **94/94 across 8 suites**, verified green immediately before the push. Content: audio-decision centralization, graceful audio-startup/runtime-write failure handling, wrap-safe engine effect timers, exact synth-smoothing convergence, signed engine inertia preserved, widened noise multiplication, low-battery period validation, UART0 diagnostics gated by firmware mode, README host-test count corrected 40→94. |
| `w17-design-system` | `6a59c96` | **PUSHED 2026-07-25** (`b301de0..6a59c96`, 1 commit, `DESIGN_NOTES.md` only): sync with the shipped setup flow (PIT WALL first, DRIVE MODE, SEAT FIT layout) — the "FINAL, SEPARATE" half of the same planning handoff that produced GS `3119180`. Newly carried in this table. |
| `w17-3d-codex` | `59a1634` | **1 commit UNPUSHED.** Recorded `80e7f74` (2026-07-10 bootstrap: 210 files classified, 37 required staged, docs + gates written, 4 human gates open, nothing printed) is a real ancestor but **8 commits stale**. The unpushed tip `59a1634` (2026-07-22, *"docs: stop this repo tracking arrivals; point to HARDWARE_INVENTORY.md"*) closes the cross-repository follow-up that `HARDWARE_INVENTORY.md` had recorded as owed — verified read-only: it touches `GENERAL_PLAN.md` + `10_assembly_architecture/B_component_envelope_register.md`. **Not pushed and not edited from this session** (repo treated as Codex-owned per the session brief). |
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
  - Physical NVS save → power-cycle → reload: **VALIDATED 2026-07-22** on 3× ESP32-D0WD-V3 DevKit
    (bare-board smoke test) — a fresh distinct write survived an EN reset and reloaded through the
    guard chain on every board. The **reflash-survival** leg (save → application reflash → reload)
    remains an optional powered-bench item (not yet exercised).
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
    (POWER_ON reset-reason path + `retained=no` fresh-session behavior confirmed on real
    hardware 2026-07-22 across 3 boards; crash-class classification, RTC counter increment,
    reboot timing, GPIO state, and ESC behavior remain.)

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

Open owner decisions: #1 UDP 5602 topology + fork ownership/license — **RESOLVED 2026-07-15
(topology (a); fork = `w17-mapper` @ GPL-3.0-or-later, §2.3.12.9)** · #2 video-loss —
**RESOLVED 2026-07-15 (sender suppression → stale decay, §2.3.12.1)** · #3 failsafe
hold-vs-center — **RESOLVED FOR BENCH ONLY 2026-07-15 (hold-last; driving re-review
required, §2.3.12.2)** · #4 camera placement (in CB7) — **still open** · #5 driving
protocol/spotter — **RESOLVED 2026-07-15 (bench-only; separate driving milestone,
§2.3.12.3)** · **#6 FIRST_ACTIVE arm/recenter affordances — owner-choice RESOLVED 2026-07-15
(Alternative C, bench-only: SHARE=recenter; hold D-pad DOWN+OPTIONS 1 s=arm; D-pad DOWN=held
deadman; right thumb free); live mapper-binding validation still required; NOT for driving
(§2.3.12.6).** ~~(superseded interim: L1+R1/R3 failed the conflict audit; A/B were the earlier options)~~

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
  - **In-app setup flow (hardened through the pre-hardware pass):** the ground station
    (now at `e0a5cdc`) scans/joins WiFi and hosts a hotspot itself (Mobile Hotspot backend
    preferred; legacy `hostednetwork` fallback targets the RT5370, needs elevation), runs
    the peer ping as a first-class GRID check, and can enable W2/W3 from persisted settings
    (`settings.json` in userData; **set env vars always win**). W3 remains **LOG-ONLY** (it
    exposes the last accepted sender's IP as a user-confirmed address suggestion — transport
    metadata only, guard-tested). Status classification:
    - **Software: COMPLETE through Batch E1** (hardening batches A1–E1: hotspot
      lifecycle/STOP + quit-ownership, adapter-pinned status/join, Wi-Fi security scope
      [open/WPA2/WPA3-transition join; WPA3-only/enterprise/unknown rejected], locale-neutral
      errors, ping classification, video-state lock, credential DPAPI-at-rest via
      safeStorage) **plus CB8 slices 3B/3C** (read-only, display-only mapper head-intent
      diagnostics subscriber — no control path) **and the `e0a5cdc` Windows reliability slice**
      (adapter live-push, hotspot readiness/interrupted, full-screen/F11, join-error UX, secret
      redaction). Suite **798/798 (46 files)**.
    - **Host verification: COMPLETE** — full suite + `npm run smoke:electron` (4/4 real
      boot scenarios) green on macOS; E1 accepted on live macOS Keychain.
    - **Windows CI: GREEN at `e0a5cdc`** (run `29440396447`: suite + Electron smoke + package
      build on windows-latest) and at the Batch F docs commit `170fd66` (run `29473220328`).
      Everything through `e0a5cdc` — CB8 3B/3C, the doc-sync `8c5af12`, and the reliability
      slice — is pushed and CI-covered.
    - **Real hardware evidence: PENDING** — the real OS layer (netsh/WinRT/ping/localized
      Windows, camera→mediamtx→WHEP, real iPhone W2/Local-Network, ELRS, Windows DPAPI) is
      **UNVALIDATED**. Runbook with evidence boxes:
      `w17-ground-station/docs/setup_flow_bench_checklist.md`; the authoritative evidence
      ledger is the matrix in `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md`.
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
