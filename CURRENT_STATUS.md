# W17 Current Status

**This is the only workspace-level file that carries volatile state and commit hashes**,
with a single carve-out: physical hardware *arrival / on-hand* status lives in
`HARDWARE_INVENTORY.md` (the parts delivery log, mapped to BOM v2). That file carries no
commit hashes and no gate / software / execution state, so this file stays the sole
workspace-level source for all of those and for project execution status.
Overwrite it in place when state changes; do not append history. Instruction files
(`CLAUDE.md` / `AGENTS.md`) must not duplicate anything below.

_Last updated: **2026-07-30** — two **gate-definition** changes, no code and no hardware state change:
(1) **A2 restructured into staged build gates** and its "why not executed" corrected (nothing is
soldered), plus two A2 decisions closed and A2 closure made a two-part gate — see **Hardware gates**;
(2) **FIRST_ACTIVE gained I10 / R15 / an input-provenance rule** after an adversarial review found
gamepad-device-loss uncovered, and a **related pre-existing throttle-freeze defect** on the stick path
recorded as separately tracked — see the 2026-07-30 entry under **VR-FPV batch status**. No checkpoint
hash moved; both target repos are `w17-control-fw` docs plus this file. Prior context: the 2026-07-29
hardware **arrival** entry below changed no gate or software state, and `HARDWARE_INVENTORY.md` remains
the carve-out owner for arrival detail. The 2026-07-27 bookkeeping **delta** below is otherwise current
— see that entry and the corrected Checkpoints table. The 2026-07-25 sync ran before three sessions
finished, so the tables were stale again; that pass updated them and did not re-do still-correct work. The dated entries
that follow are preserved as an as-of log — **read the Checkpoints table and the newest entry for
current truth**, and treat any bare present-tense claim inside an older dated entry as as-of that date.

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
`2b8031a`; GPL-3.0-or-later; registered in `WORKSPACE_MAP.md`; push disabled — **⚠ true only
as of 2026-07-15; the fork has had a PUBLIC `origin` since 2026-07-25, see the Checkpoints
row for `w17-mapper` and the 2026-07-27 entry**; git-ignored in the manual repo). Go toolchain installed here (`brew install go`, go1.26.5). New
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

2026-07-27: **Workspace bookkeeping delta (docs-only, no hardware) — A2 still NOT-EXECUTED,
Phase B still BLOCKED.** The 2026-07-25 sync (`05157b2`) ran *before* three sessions finished, so
the tables above were stale again. This is a delta, not a re-run: the audit-findings closure, the
CI run list, the test counts and the staleness warning from that pass were re-checked and kept.

- **Live 13" pass (prompt 8) — DONE.** Three items closed, two defects opened.
  - **BATT ordering RESOLVED toward the code** (owner, 2026-07-25): shipped order stands — BATT
    above the merged pill row, `BOOST · OVERTAKE · DRS` within it. The decisive measurement is
    not aesthetic: both stacks occupy an **identical envelope** (y 643→782 at 1280×800), but the
    mockup order terminates the right column's bottom edge — the HUD's strongest horizontal
    alignment line, registering against the bottom-left R-STK panel — with a **99 px chip leaving
    a 184 px notch**, versus a full-width **283 px** block.
  - **`.revwrap` centering CONFIRMED** — offset from viewport centre **0.00 px**, holding under a
    forced 30-char driver name, a 52-char team string, a long clock, and tiny values. `e01eb9f`
    did exactly what it set out to.
  - **`#addrStatus:empty` reserve works as designed** — empty ⇒ height 0; after CHECK ⇒ 33.6 px
    with the hint shifting down by exactly that. The one-time shift is a deliberate, code-commented
    trade.
  - **Viewer-only disclaimer verified genuinely once per session** — visible on boot GARAGE (36 px,
    in normal flow, crossing nothing), hidden on every later screen, still hidden after a full
    CHANGE SETUP → back-to-GARAGE round trip; both homes carry byte-identical copy.
  - Clean at all four sizes × both paths: rail `01..05`, GRID reads 05, solo shows `02 PIT WALL`
    struck through as `SKIPPED · DESKTOP`, zero horizontal overflow, no wrap. Invariants held in
    every screenshot (HEAD TRACKING LOCKED · SAFETY GATE NOT COMPLETE, ACTIVE AUTHORITY NOT
    REPORTED BY MAPPER, violet `STICK INPUT · PAD`, `ARM / FAILSAFE · NOT REPORTED BY CAR`).
- **Prompt 12 phase A — DONE, GS `1a6f9f2`** (CI `30150690390` green, 1090/1090 in 56 files,
  `responsiveLayout` 34 assertions). `17ec1be` rail comments · `2c96eb1` SETUP → one centred
  column · `1a6f9f2` `#gamepadPanel` rhythm.
  - **D1 overflow — record what it actually is, or it reads as a shipped defect.** Stacked SETUP
    exceeds the viewport at three of four sizes (30 / 72 / 95 px at 1280×800 · 1366×768 ·
    1024×640) and **every pixel of it is the `--gate-toast-reserve`** (121.6 px of `.gate` bottom
    padding held for the `position:fixed` `.radioLog`) — **not content**. All content plus
    BACK/NEXT stays visible unscrolled at every size (worst case nav bottom 95.8% of a 640 px
    viewport); an all-elements intersection sweep found **zero** hits against the radio band.
    `.gate` already had `overflow-y:auto` + `justify-content:safe center`. Owner chose scroll.
  - **Two premise corrections, now test-pinned:** the dead left column was **~191 px, not
    ~300 px**; and **SEAT FIT stays split** — a test asserts `.cols.seatcols` never gets `.stack`,
    because its right column is the *taller* one (1.31–1.38 : 1) and the original "SEAT FIT reads
    empty" assumption was **inverted**.
  - **D2** reproduced before fixing (all six row boundaries measured exactly 0 px, then 11.2 px).
    Uses a new `--col-gap` token on `:root` consumed by both `.col` and `#gamepadPanel` so they
    cannot drift. One boundary reads 16.79 px because `.errdetail` has a pre-existing
    `margin-top:.35em`, deliberately left since `.errdetail` is shared with the PIT WALL error panes.
  - **19 injected regressions** (9 for A1, 10 for A2) each proven to fail the intended assertion,
    including the silent-pass modes: `minmax(0,56ch)` vs `min(100%,56ch)`, the gap re-guessed as a
    literal `.7em`, `--col-gap` deleted or zeroed, and the rows wrapped in an inner `<div>`
    (satisfies every CSS assertion while collapsing the gap to 0).
- **Prompts 12 phase B + 13 — DONE, `w17-design-system` `26ec870`**, pushed. §11(f) resolves the
  right-column order toward the code; §14(d) records the single-column SETUP; the twice-superseded
  "Adoption path" entry is gone. The `~300 px` → **`~191 px`** correction landed with the
  41.8% / 71.6% column-end figures beside it **because they derive it**:
  **(0.716 − 0.418) × 640 = 190.7 px** — independent arithmetic corroboration that ~191 is right
  and ~300 was an estimate. `screens/05-hud.html` was **finally rendered** (served over `127.0.0.1`,
  since the browser pane refuses `file://` outside the project folder) and **measured rather than
  eyeballed**: BATT 649→688, pillrow 696→727, ERS 735→786, all **283 px** wide — reproducing
  §11(f)'s own arithmetic, **283 − 99 = 184**, the notch the ruling rests on. The ruling is backed
  by geometry the rendered screen actually has.
- **Prompt 6 (CB1 + CB4) — DONE and PUSHED, GS `92cd894`, CI `30263115532` GREEN.** At report time
  these were unpushed and CI-unverified; both were checked this pass rather than assumed, and CB4
  touches **main-process startup**, so that Windows CI run is the first real check of the surface.
  - **CB1 was already shipped** on 2026-07-16 with the SEAT FIT slice — the `NOT_STARTED` row was
    stale bookkeeping, not open work. `92a0dce` is the closeout only.
  - **`/code-review high` found 7 real defects, two self-introduced**, all fixed: a socket error
    handler missing the identity guard (a dead socket's late error would tear down its live
    replacement); a comment claiming the backwards-pointer rule *alone* prevents DNS decompression
    loops — it does not, the jump cap is load-bearing, and the comment invited deleting it; and a
    plain multicast send following the routing table, which on a deliberately multi-homed bench
    host would never reach the hotspot subnet (now sends on every local IPv4 interface).
    **Mutation-testing the fixes then caught two tests that didn't bite**, one guarding already-dead
    code (`·` is U+00B7, above the printable-ASCII ceiling, so the extra check was unreachable).
- **Control-fw zero-hardware batch + this pass — `main` = `8d0309e`, pushed.** Native **225/225**,
  all three envs build. **CB3 DONE** (anchor had drifted one line). **R05** closed: 4 gears
  canonical; the phantom "6" was `Gearbox::kMaxGears` (array capacity) misread as a count, and the
  only fix needed was the stale mock at `docs/f1_hud.html:286`. **R19** closed: TRAINING/RACE/ERS is
  canonical for display, and the wire enum `TRAINING/GEARBOX/GEARBOX_ERS` **deliberately differs**
  — recorded as a decision, not drift; one stale comment at `Link2Sender.hpp:21`. **R06** closed:
  the link2 copy is **permanent-but-guarded** — `tools/link2_copy_check.sh` (`--strict`; exit 1
  drifted / 2 could-not-check; verified to bite on an injected `kPayloadLen` change and a deleted
  file) plus a hermetic feel-constant pin. R06's conflation of wire format vs feel constants is now
  recorded as **two separate guards**. **R01** decided: armed/failsafe stay **simulated but must be
  labelled** — adding `A1F0` to FLIGHTMODE was rejected because 15 chars exactly fits, R13 is
  unproven, and mid-token truncation could show a *wrong* armed state; the label itself was the
  ground-station follow-up, implemented in `16d3d0a`.
  **The cross-repo link2 guard is now ENFORCED, not advisory** (soundlight `2d22f85`) — that caveat
  is dropped wherever it appeared.
- **`feelConstants` drift guard (GS `9c2d723`) — scope went beyond the brief, correctly.** All
  **four** firmware-derived constants are bound, not the three in `ErsSystem.hpp`: `GEARS`'s
  "matches the firmware gearbox `numGears=4`" was an unguarded claim of exactly the same kind, so it
  binds to `Gearbox.hpp`; `TOP_SPEED_KMH` stays unbound with a test asserting that positively. Exit
  codes **1/2/3** match `link2_copy_check.sh` and **deliberately differ** from `proto:check`'s 2/3 —
  stated in the script header so nobody silently "harmonizes" them. `--strict` /
  `W17_FEEL_CHECK_STRICT=1` makes an absent sibling exit 2, as does a renamed firmware member —
  never a silent pass. Every new assertion was verified to **bite on an injected regression** first
  (16 injections across four test files), and `../w17-control-fw` was verified clean after each.
- **Viewer-only disclaimer restored (GS `769003b`) — the constraint is worth keeping.** It lives in
  the ⚙ settings panel, shown once per app session via a module-level `viewerNoteShown` flag driving
  `updateViewerNote()` from `showStep()`, and deliberately has **no dismiss button**: a focusable in
  GARAGE would enter the document order that finding 6's boot-only focus depends on, and
  `test/viewerOnlyNotice.test.js` asserts `boot()` still focuses `fastPathBtn`. A `settings.json`
  key was rejected because it would have to pass `normalizeSettings` and would break
  `settings.test.js`'s 12-key persisted-shape pins.
- **RETRACTION — the preload surface IS hermetically pinned.** An earlier instruction claimed
  `test/ipcSurface.test.js` asserts only symmetry plus `exposedKeys.length > 15`, leaving the exact
  24 pinned solely by `smoke:electron` (which cannot run on this host). **That was false.**
  `test/ipcSurface.test.js:153` asserts the **exact sorted 24-name key set** — and has since
  `e0a5cdc` (2026-07-15). The `length > 15` at `:90` is a separate vacuity sanity-check, not the
  pin. Verified 2026-07-26 by injecting an extra key (2 failures incl. the exact-set pin) and a
  rename `probeHost → probeHostX` (3 failures), both hermetically, no Windows CI involved.
  **The error's shape matters more than the fact:** the claim entered via a session report that read
  `:90` and missed `:153`, and was accepted without opening the file — because it confirmed a
  suspicion already held. Staleness in this workspace runs toward **over-reporting open work**; this
  one ran toward **inventing** it. The countermeasure is the same either way: **open the file.**
- **Durable backups now exist** (2026-07-25, outside any scratchpad, both verified present
  2026-07-27): **`~/Documents/w17-backups/w17-mapper-allrefs-2026-07-25b.bundle` — use this one.**
  It caps at `0e11d6b` (clone-tested 2026-07-25 13:02; `.githooks/pre-push` + `FORK-NOTICE.md`
  present). The earlier `w17-mapper-allrefs-2026-07-25.bundle` caps at `8fc1915` and therefore does
  **not** contain the pre-push guard — i.e. it is missing the very commit that replaced the "no
  remote" safety accident. It is kept only as a second copy. Also
  `~/Documents/w17-backups/spent-gs-artifacts-2026-07-25.tgz` (SHA-256 matches the scratchpad
  original, 15 entries; copied not moved, so the scratchpad copy can expire on its own).
  **Honest limit: same physical disk** — this protects against repo deletion and session cleanup,
  **not** drive failure. GitHub now covers that axis for the mapper.
- **Branch cleanup:** `w17-batch1-measurements` (`c5d32c7`) confirmed fully merged into `main`
  (`git branch --merged` + empty `main..branch`) and deleted local and on origin.
  `w17-control-fw`'s redundant `docs/bom-cassette-electrical` was already gone from both.
- **Codex item — RAISED AND CLOSED 2026-07-27 at `w17-3d-codex` `0386b2f`** (committed by Codex;
  **1 commit unpushed** as of this writing). `2325fd9` had added two *new* rows asserting the ESC
  is **44.2 × 37 × 24.2 mm** as "DOCUMENTED owner physical ground truth" (`DRV-ESC-CURRENT`) and
  that its envelope is "closed" (`OP-01`) — but the 2026-07-24 caliper measured
  **44.2 × 33.7 × 34.0**, and 24.2 is precisely the documented figure that measurement
  *superseded*. The same commit's ZK study carried the correct 34.0, so the repo contradicted
  itself and **the stale half wore the strongest confidence tag.** Handoff:
  `w17-codex-esc-groundtruth-fixup.md` (workspace root, not `_handoff/`).
  **Fixed in `0386b2f`:** envelope corrected to 44.2 × 33.7 × 34.0 tagged VERIFIED, the superseded
  44.2 × 37 × 24.2 retained with the cooling-stack explanation, `OP-01` reworded (measured, but
  station FAIL-STATION pending re-derivation, not "closed"), the placement matrix reconciled to
  **L−60.5…−26.8 / body Z1.5…35.5 / intake plane Z45.5**, validator paths relativised, and the
  cassette + wire-schedule artifacts regenerated. Validation **cassette 57/57, wire schedule
  36/36**, tree clean. **No gate or print-authorization change** — GATE P1 still not passed.
  Its wire validator had gone 35/36 because the pinned `w17-control-fw` PinMap hash moved
  `6afc… → bf6c…`; that drift is **benign and expected** — caused by `37ebe46` (CB3), which is
  **comment-only** (verified by diff: three comment lines, zero pin values; the validator's own
  pin-token checks passed throughout). Re-pinned to `bf6c…` citing `37ebe46`. This is the first
  time any of this project's three cross-repo guards has fired on a live change, and it behaved
  correctly: it refused to accept a changed upstream file silently. Everything else
  cross-checks clean — note that the "2 commits unpushed" half of that same prompt-13 finding
  **had already gone stale by 2026-07-27** (Codex pushed them; verified by `git ls-remote`, not
  by the local tracking ref, which can lag). The inconsistency below is the part that survived.
  Other cross-checks clean (MH-ET board
  decision, DS3235SG side-on, §E ⏳ rows treated as not-in-hand). The DS3235SG **1.5 vs 1.7 mm** is
  **not** a contradiction — the study predicted, the caliper refined, and this file already records
  it as "predicted ~1.5 mm — confirmed".

**Staleness audit for this pass (the rule from `05157b2`, applied explicitly).** Every
`PENDING` / `NOT_STARTED` / `BLOCKED` line kept above was re-checked rather than carried:
A2 unexecuted and Phase B blocked (unchanged, no hardware touched this pass); CB2 `NOT_STARTED`
(optional, genuinely untouched); CB5/CB6/CB7/CB9 `BLOCKED_HARDWARE` and CB10 `BLOCKED_EXTERNAL`
(no parts arrived, no bench network — §E rows still ⏳); CB8 `IN_PROGRESS` (U4 still design-only and
gate-held); the Wokwi observation (re-verified as credential-blocked, not bench-blocked); real-iPhone
W2/W3 and the Windows real-OS matrix (no device, no non-isolated network); CB4's real-device leg (byte
fixtures only). Newly **closed** this pass rather than carried: CB1, CB3, the mDNS "NOT BUILT" line,
the GS "uncommitted WIP" claim, the audit §3 staleness, and the design-system "1 unpushed commit".
**Over-reporting open work is now the documented failure mode of this file — eleven instances:** the
nine audit findings, R05, R19, the `loopTask` watchdog question, this file itself, the design-system
"1 unpushed commit", the "Windows CI not re-verified" claim, the `~300 px` dead-column figure, CB1's
`NOT_STARTED` row, the mDNS "Windows side NOT BUILT" line, and — found *during* this pass —
`w17-3d-codex`'s "2 commits unpushed", which Codex had already pushed. **The `ipcSurface` retraction
above is the one instance that ran the other way** — inventing open work — and it is the more
dangerous direction, because nothing forces a recheck. Several of these were caught by sessions
*refusing to act on a stale instruction* rather than by this file being right. The eleventh is worth
the extra sentence because of **how** it was caught: the recorded hashes were re-checked against the
repos one by one before commit, and the `git ls-remote` disagreed with the local tracking ref. Cheap
mechanical verification beat careful reading of a confident instruction — which is the same lesson as
`ipcSurface`, arriving from the opposite direction.

2026-07-29: **Hardware delivery (owner) — arrival only, NO GATE CHANGE.** The 2026-07-24 §E
electrical order landed almost complete, together with the last mechanical/consumable ⏳ lines from
the 2026-07-22 in-transit set. Owner's words: *"new smaller ESPs, 3 servos for gimbal and drs,
thermal paste, XT60 and XT30 connectrs, remaining shock observers, both capasitor packs, USB
charging boards and one battery."* Mapped to: MH-ET D1-Mini ESP32 (**3 on hand** vs ×2 recorded as
ordered), MG90S ×3 (pan/tilt/DRS), thermal paste, XT60/XT30 connector units, rear 68 mm oil shock,
ceramic + electrolytic cap kits, IP2326 charger (**2 on hand** vs ×1 recorded as ordered), ZEEE
1500 mAh 2S LiPo. **Still in transit:** neodymium magnets (§7), Amass XT90-S master switch +
XT60→XT90 adapter (§E), Tamiya tyres (§B). Full arrival detail and per-line mapping confidence are
in `HARDWARE_INVENTORY.md` (the carve-out owner) — not duplicated here.
- **No status in this file moves.** **A2 stays NOT-EXECUTED, Phase B stays BLOCKED**; parts arriving
  is not powering, and the harness must still be built and A2 run first. CB5/CB6/CB7 stay
  `BLOCKED_HARDWARE` on their own blockers (camera bench, iPhone + non-isolated network, printed
  dry-fit) — **none of them was waiting on anything in this delivery** — and CB9 stays gated on
  A2 + Phase B. The no-unattended-powering rule stands; the LiPo also still needs owner
  re-termination to XT60 before it is usable at all.
- **What it does unblock is measurement, not power:** the MH-ET caliper + weight, the actual 1000 µF
  electrolytic, and the MG90S / rear-shock fit checks are now performable. Those are **`w17-3d-codex`
  inputs** and were not touched from here (one repo at a time; that repo is Claude-owned but separate).
- Note for the next bookkeeping pass: the 2026-07-27 staleness-audit paragraph above says
  *"no parts arrived … §E rows still ⏳"*. That was true as of 2026-07-27 and is preserved as an
  as-of statement per this file's header rule — **do not read it as current**.

## Checkpoints

| Repo / folder | Checkpoint | Notes |
|---|---|---|
| `projects` (manual repo, `w17-software-manual`) | — | contains this CURRENT_STATUS.md; do not self-record its own exact hash — use `git HEAD` for the current commit |
| `w17-control-fw` | `fa07690` (`main`) | **On `main`, 2 commits AHEAD of `origin/main` and UNPUSHED** as of 2026-07-30: `e5abc20` (A2 restructured into staged build gates + the WS2812/link2-RX decisions + the two-part closure gate) and `fa07690` (FIRST_ACTIVE I10 / R15 / input-provenance rule). **Docs only in `project-review/` — no code, no test, and no build state changed by either**, so every native-test and build claim below still stands as last re-run 2026-07-27. Previously `8d0309e`, which was level with origin: **On `main`, level with `origin/main`, nothing unpushed.** The `docs/bom-cassette-electrical` branch problem is **resolved and gone**: `main` was fast-forwarded `fbf22f0 → 34eba89` (16 files, no merge commit) on 2026-07-25, so the electrical BOM (`78e1e88`, `1834852`) is on `main`; the redundant branch has been deleted local and on origin (verified absent 2026-07-27). Since then, the 2026-07-25 zero-hardware batch and this pass: CB3 comment fixes, owner decisions R05/R19, the R06 link2 drift guard, honest Wokwi run-status, then `d6395c8` (link2 doc: the cross-repo guard is enforced, not "not built yet"; control-fw-local statements marked for the receiver) and `8d0309e` (unlock plan: serial bump recorded as shipped at **v1.6.0**, and the false "push remains disabled" claim corrected). Firmware behaviour unchanged by any of it — docs + comments only. **Native `pio test -e native` 225/225** (was 224; +1 with the R06 guard), `esp32dev` + `esp32dev_tuning` + `esp32dev_sim` all build, `tools/link2_copy_check.sh --strict` exit 0 — all re-run 2026-07-27. Live watchdog-cycle observation and physical reset-path validation still pending. |
| `w17-ground-station` | `92cd894` | **Windows CI GREEN at this HEAD: run `30263115532` (2026-07-27)**, both the ubuntu `test` job and the windows-latest `package-smoke` job. Suite **1185/1185 across 59 files**; `proto:check` OK, `feel:check` OK; `noControlPath` + `ipcSurface` green at the pinned **24-key** preload surface. `main` level with `origin/main`, nothing unpushed. **The 7-file WIP recorded here previously is long since reviewed, split, and shipped** — do not read this row as carrying uncommitted work. The chain since `3119180`: `42319ad` (SETUP split out of SEAT FIT — five steps, `garage → pitwall → seatfit → setup → grid`, solo `garage → seatfit → setup → grid`, rail `01..05` with GRID = 05) · `e01eb9f` (HUD `.revwrap` viewport-centred, BATT above the merged pill row) · `0950298` (viewer-only footnote overlay removed — isolated deliberately so it was revertable alone) · `e09369b` (GRID `wide`, `#addrStatus:empty` reserve collapse) → CI `30128883953`; then `769003b` (viewer-only disclaimer **restored** in the ⚙ settings panel, once per app session) · `12896fb` (the four unasserted CSS rules pinned, `responsiveLayout` 22 → 26) · `7c29a6b` (audit annotated, 91 insertions / 0 deletions) · `16d3d0a` (**R01 implemented** — armed/failsafe labelled as simulated) · `9c2d723` (**`feelConstants` drift guard made real** — hermetic snapshot + `scripts/check-firmware-feel.js`) → CI `30144513077`, 1082/1082 in 56 files; then `17ec1be` (stale rail comments, own CI `30149835990`, branch deleted) · `2c96eb1` (SETUP → one centred column) · `1a6f9f2` (`#gamepadPanel` rhythm) → CI `30150690390`, 1090/1090 in 56 files, `responsiveLayout` 34; then `92a0dce` (CB1 closeout) · `92cd894` (**CB4** iPhone HUD mDNS discovery) → CI `30263115532`, 1185/1185 in 59 files. **All 9 findings of the 2026-07-17 setup-flow audit are CLOSED, and the audit's own §3 staleness is fixed too** (`7c29a6b`) — that artifact is no longer stale. Real-OS/Windows-hardware paths remain bench-unvalidated. |
| `w17-mapper` | `0e11d6b` | owned fork (`w17-headtrack` off upstream `2b8031a`); CB8 slices 1–3A: LOG-ONLY UDP 5602 head-intent ingest + read-only gRPC diagnostics. Since `59d1739`: `f0a18f3` (`go.bug.st/serial` v1.5.0 → **v1.6.0** — `go build ./...` now **fully green**, the go1.26 × cgo blocker cleared; **not** the approved v1.7.1, which would have bumped the `go` directive 1.20 → 1.25.0 in both `go.mod` and `go.work` and with it go1.22 loop-var semantics for the whole module — reasoning in `w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.12.9 item 2) · `8fc1915` (fork notice: provenance, GPL-3.0-or-later election, GPL §5(a) modification notice, safety boundary) · `0e11d6b` (tracked `.githooks/pre-push` + the written push-review rule). **⚠ "push disabled" is NO LONGER TRUE — do not rely on it.** The fork has `origin` = `github.com/beforethenexttolast/w17-mapper`, created 2026-07-25T04:11Z, **PUBLIC**, with `origin/w17-headtrack` carrying all of the above (`upstream`'s push URL remains disabled). The accidental "no remote, so push is impossible" protection is **gone** — and it was never a control, only an accident of setup. What replaced it: a tracked **`.githooks/pre-push`** (enable per clone with `git config core.hooksPath .githooks`; refuses a `w17_first_active` build tag, a `FIRST_ACTIVE` identifier in Go/proto, or an active head-intent enum; verified to pass a clean HEAD and bite on all three injections) as the **accident guard**, plus the push-review rule in `FORK-NOTICE.md` as the **control**. What is published distributes **no control path**: proto still ends at `ACTIVE_LOG_ONLY = 8`, no `FIRST_ACTIVE` in tracked Go or proto source, upstream licence files unmodified — re-verified read-only 2026-07-27. `go vet ./...` is **not** green and that is **not a regression** — see the same §2.3.12.9 item 2. |
| `w17-soundlight-fw` | `5919685` | **PUSHED, level with origin.** Through `ec5ddf8` (`4f25856..ec5ddf8`, 11 commits): audio-decision centralization, graceful audio-startup/runtime-write failure handling, wrap-safe engine effect timers, exact synth-smoothing convergence, signed engine inertia preserved, widened noise multiplication, low-battery period validation, UART0 diagnostics gated by firmware mode, README host-test count corrected 40→94. Then 2026-07-25: **`2d22f85`** (CI enforcement — see below) and **`5919685`** (link2 protocol-doc re-sync). Native **94/94 across 8 suites**, `esp32dev` + `esp32dev_sim` both build, canonical guard re-run exit 0. **`2d22f85` matters beyond bookkeeping:** this repo already had a `link2-drift` job (`74b59f4`) with a hand-rolled inline diff loop that treated `docs/link2_protocol.md` as **fatal** — so a control-fw doc edit turned soundlight's `main` CI **red for a non-bug**. Verified by replaying the old logic (flags the doc and nothing else, exit 1), not assumed. `2d22f85` replaces it with a single source of truth: the job anonymously shallow-clones control-fw into `$RUNNER_TEMP` (outside `GITHUB_WORKSPACE`, so the sibling never enters soundlight's source tree) and runs *control-fw's* `tools/link2_copy_check.sh --strict`. Exit codes fully disambiguated — 0 pass (plus a `::warning` when the doc tier reports, so the non-fatal tier is never invisible), 1 DRIFT, 2 COULD-NOT-CHECK, 3 CI-bug/usage, anything else unexpected. **Trap recorded in-file:** GitHub's default `bash -e` would collapse every exit code into one anonymous red X, so `set +e` is load-bearing and commented as such. Verified by watching it fail — the step's real `run:` body extracted from the YAML and run against throwaway fake siblings across **7 scenarios** (clean, injected `kPayloadLen`, deleted shared file, sibling missing `lib/link2`, checker absent, exit 3, exit 42). The doc re-sync was **one-sided, not three-way** (soundlight's copy was byte-identical with zero local content, so purely additive); upstream prose corrected to receiver POV. |
| `w17-design-system` | `26ec870` | **PUSHED, clean, level with origin** (verified 2026-07-27 — the earlier "1 unpushed commit" reading was itself over-reporting). `6a59c96` synced the shipped setup flow; then `d53e6c4` (§1/§2/§9/§11/§14 amendment — §11(d)'s pill-row merge is **not** a supersede: the mockup always drew one `.pillrow` and the app carried two, so the merge brought the *app to the bundle*; §11(e) records `.revwrap` as an intentional improvement, since in the mockup its position is residue of the RUSSELL-plate/clock widths plus `.top`'s `right:calc(var(--gap) + 3em)` ⚙ inset and so *cannot* be top-centre); then `1415686` (§11's OPEN DECISION → **§11(f)**, right-column order resolved toward the code — BATT → pillrow → ERS, `BOOST · OVERTAKE · DRS` — old table kept as canonical-vs-superseded, the GS test pin's "provisional" note corrected to a guard backed by a ruling; `screens/05-hud.html` reordered; new **§14(d)** single-column SETUP with (a)/(b)/(c) amended in place; the twice-superseded "Adoption path" entry removed with a dated parenthetical); then `26ec870` (the `~300 px` → **`~191 px`** dead-column correction at `DESIGN_NOTES.md:208`). |
| `w17-3d-codex` | `0386b2f` | **1 commit ahead of origin** (`0386b2f`, the 2026-07-27 ESC ground-truth correction — see the Codex item above; `2325fd9` and earlier are pushed). (`git ls-remote` 2026-07-27 shows `refs/heads/main` = `2325fd9`; working tree clean apart from ignored files). Prompt 13 recorded these as *2 commits unpushed* with `origin/main` at `ae42b5f`; Codex has pushed them since, so **that reading is stale — do not re-open it as owed work.** `59a1634` (2026-07-22) is the owed arrival-tracking cleanup (2 files, +48/−26; asserts no new physical facts). `2325fd9` is large (107 files, +20,130): fit studies, wire schedule + connection-joint register, ~7,000 lines of evidence generators, ~30 self-contained HTML visualisations, a 1,135-line manual expansion. **Inspected read-only 2026-07-27; not edited, not pushed** (Codex-owned). It asserts **no unearned hardware facts** — checked specifically: the `*_output_validation` PASS tables validate *generated artifacts* ("HTML exists", "inline-only CSP present", "link resolves"), **not physical parts**, despite commit subjects that read like hardware validation; where it does touch hardware the hedging is disciplined (VERIFIED / DERIVED / DOCUMENTED / ASSUMPTION per row; "Physical scales own the result"; "NO PRINT AUTHORIZATION — GATE P1 NOT PASSED"; MG90S official dimensions "do not prove the purchased clones"). **One real inconsistency, flagged not fixed — see Open Codex items below.** Nothing sensitive blocks a push (no credentials, keys, tokens, prices, order numbers, or binaries); one minor item: `p0_d36_wire_schedule_validation.md` adds three lines carrying the absolute path `/Users/vitaliykhomenko/…`, a small deanonymisation vector against a pseudonymous account — near-zero marginal exposure, since `01_inventory/build_inventory.py` already contains it and is already public, so it blocks nothing but is trivially relativisable. |
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
- **A2 no-power bench checklist: NOT EXECUTED, and RESTRUCTURED 2026-07-30.** No measurements
  recorded; A2 is not closed. Canonical checklist:
  `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`.
- **Why A2 has not run — corrected 2026-07-30.** Previous revisions of this file left A2
  reading as owner-owed bench work. It is not: **nothing is soldered** (owner-confirmed
  2026-07-30 — the ESP32 boards arrived with pre-soldered pin headers, and the 3D-printed
  parts on hand are test/measurement-quality prints, not build parts). A2 as written assumed a
  finished harness, so there was nothing for it to measure. There is **no untracked assembly
  gate and no A1.7** — the restructure below makes A2 *be* the build order.
- **A2 is now staged, not a single pass.** Eight gates run on isolated subassemblies as the
  harness is built — S1 divider → S2 Hall → S3 link2 → S4/S4b CRSF + actuator leads and
  cross-signal isolation → S5 WS2812 → S6 attach UBECs → S7 whole-harness ground sweep → S8
  ESC red-wire isolation. Only S7/S8 are true whole-harness gates. **Driver for the change:
  several expected values are only valid while the subassembly is isolated** — the worked case
  is the divider's `batt+ → GND ≈ 37 kΩ`, which after S6 is measured in parallel with two UBEC
  input stages and would false-FAIL a correctly-built car against the old §13 hard stops.
- **Two A2 decisions taken 2026-07-30** (both previously unfalsifiable "per your build" rows
  that made the old PASS criterion unsatisfiable): **WS2812 supply = option A, the 1N5819
  diode** (on hand; no 74AHCT125 in inventory or BOM v2; 74AHCT125 stays the documented
  fallback — recorded honestly as a ~10 mV nominal V<sub>IH</sub> margin), and **link2 RX
  (GPIO26) = do not wire**, since the firmware hard-disables it (`Serial1.begin(..., rxPin=-1,
  txPin_)`); the row is now falsifiable as "verify no wire present."
- **A2 closure is a two-part gate (2026-07-30).** Part 1 = reviewer check (completeness, gate
  attribution, tolerance, cross-reference, **plus mandatory direct inspection of the §10
  photos** — the one part that is independent observation rather than trust in transcription).
  Part 2 = owner attestation that the measurements were physically performed. **A2 closed means
  the record is complete, coherent, and photo-corroborated — NOT that the hardware is safe.**
  Opening Phase B is the owner's call, informed by A2, not a reviewer verdict.
- **Phase B (powered) is BLOCKED** until A2 is filled in, pasted back, reviewed, and approved.
  Also still outstanding: the ZEEE pack's main lead is **not** re-terminated to XT60, and the
  XT90-S master switch + XT60→XT90 adapter were in transit as of 2026-07-29
  (`HARDWARE_INVENTORY.md` §E). S7's "probe from battery −" reference depends on the XT60.
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
  - Native tests: **225/225 passing** (was 224; +1 with the R06 link2 drift guard). Re-run 2026-07-27.
  - All ESP32 environments build successfully.
  - **Live Wokwi stall → watchdog panic → reboot observation: PENDING — `[OWNER/tooling]`,
    NOT hardware-blocked.** Retagged from `[HW]` 2026-07-25, and the distinction is the point:
    `esp32dev_sim` **builds but has never been run**, and what blocks the run is a **Wokwi
    credential** (`wokwi-cli` absent, `WOKWI_CLI_TOKEN` unset), not the bench. Every route
    uploads the firmware to Wokwi's servers, so it is an owner decision, not an A2/Phase-B gate.
    The stall injector already existed (`W17_SIM_WDT_STALL`; marker present once in the stall
    ELF, absent from all three shipping envs) — nothing was owed there.
    `w17-control-fw/SIMULATION.md` leads with a run-status table, **every box unchecked**.
    **Nothing has been promoted to PASS; the 2 s TWDT timeout stays provisional.**
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
| CB1 | GS right-stick indicator | `DONE` | 2026-07-25: this row was STALE — the batch actually shipped **2026-07-16** with the SEAT FIT slice (`renderer/padPreview.js` draws both stick wells with live `data-stick` dots fed by `setupFlow.js` seatfitTick; captions `RIGHT STICK · PAN / TILT` + `CAMERA · STICK INPUT`; `test/padPreview.test.js` rewritten to pin the relaxed boundary; recorded in `docs/camera_aim_display_semantics.md` §5). Closed out at GS `92a0dce`: invariant recorded in the repo `CLAUDE.md` guardrails + stale `inputPresets.mjs` comment corrected. Display-only; `noControlPath` unchanged |
| CB2 | Gimbal explainer artifact | `NOT_STARTED` | optional |
| CB3 | Firmware comment hygiene | `DONE` | 2026-07-25 in `w17-control-fw`: the anchor had **drifted one line** — the real target was `ChannelDecoder.hpp:58`, not 57-58. Also retired a vacuous `PinMap.hpp` comment by naming the real declared-but-unwired `kBoard2UartRxPin` (`Serial1.begin(..., rxPin=-1, ...)`). Comments only; no behaviour change |
| CB4 | Windows mDNS discovery | `DONE (real-device validation PENDING)` | 2026-07-25 at GS `92cd894`: `_w17hud._udp.local.` discovery — `shared/dnsWire.js` (wire codec) + `shared/hudDiscovery.js` (contract policy) + `main/HudDiscovery.js` (node:dgram transport); **no new dependency**, **no new IPC/preload key** (rides `setup:addr-hint`; preload still 24). Advisory hints only: offered on the PIT WALL chip, filled only on an explicit click, GRID ping still ground truth; demand-driven (queries only while PIT WALL is active, never under `W17_WIFI_SIM`). Hardened against hostile multicast (bounded name decompression, capped counts/labels, sender/address match, TTL-0 goodbye retires the entry); query sent out every local IPv4 interface (multi-homed bench host). 1185/1185 in 59 files; proto:check + feel:check exit 0. **PENDING: no iPhone observed — byte fixtures only**; `smoke:electron` unverified locally (macOS Gatekeeper), relies on Windows CI. Residual limits in `docs/proposals/iphone_mdns_discovery.md` "As built" |
| CB5 | Video baseline verification (Windows) | `BLOCKED_HARDWARE` | needs camera; pairs with Codex Batch 0 |
| CB6 | Real-device W2/W3 validation | `BLOCKED_HARDWARE` | needs iPhone + non-isolated bench network |
| CB7 | Placement decision support | `BLOCKED_HARDWARE` | needs printed halo/body dry-fit; owner decision #4 |
| CB8 | Mapper implementation | `IN_PROGRESS` | decision #1 RESOLVED (topology (a), §2.3.7). **Slice 1 DONE 2026-07-15:** `w17-mapper` fork (`w17-headtrack` @ `2b8031a`, GPL-3.0) — new pure-Go `pkg/headintent` log-only UDP 5602 ingest + in-process diagnostics; go build/vet/test/-race all green; `go list -deps` proves no config/link/crossfire/serial dep; no existing file imports it (output unchanged); 299/300/301 + port-exclusivity proven. **Slice 2 DONE 2026-07-15:** `cmd` wired behind disabled-by-default `-headtrack-ingest`/`W17_HEADTRACK_INGEST` (+`-headtrack-port`) — starts receiver and nothing else; `pack_deadend_test.go` proves `crsf.PackChannels` byte-identical flag-off vs on (valid/stale/invalid); host `go build ./...` blocked only by pre-existing go1.26×`go.bug.st/serial` cgo incompat (temp `v1.7.1` bump builds green, reverted — send-path dep = owner decision). **Slice 3A DONE 2026-07-15:** mapper-side gRPC diagnostics — read-only `WatchHeadIntentDiagnostics` stream (enum state, server-computed age, 4-stream cap→ResourceExhausted, nil→Unavailable, bounded latest-value buffers); stubs regenerated with pinned drift-checked toolchain via `pkg/proto/generate.sh`; `go build`/`test ./...` green, webpack compiles; CRSF byte-identical with subscribers connected/slow/disconnected; :10000 still `[::]` (unchanged). **Slices 1–3A COMMITTED 2026-07-15** in `w17-mapper` @ `59d1739`. **Slice 3B DONE** (GS Electron subscriber @ `03f43e2`). **Slice 3C DONE 2026-07-15** (GS @ `dce91f8`): hermetic proto-drift guard (`test/protoDrift.test.js` vs a live-mapper-generated canonical snapshot, regen zero-diff, bites on drift) + real cross-process run vs live mapper gRPC :10000 (every HeadIntentState, ingest-off→UNAVAILABLE, 4-cap→RESOURCE_EXHAUSTED, restart→bounded reconnect, byte-identical CRSF, topology-(a) mutual exclusivity); GS 746/746; validation-only serial bump reverted (modules pristine). Evidence: `w17-ground-station/docs/2026-07-15_cb8_slice3c_integration_evidence.md`. **Slice U4 DONE 2026-07-15 (DESIGN ONLY, SAFETY-GATED):** shaping/arbitration model + 9 safety invariants + Group A/B/C test matrix + two-part FIRST_ACTIVE flag + FIRST_ACTIVE review checklist R1–R14 written to `head_tracking_unlock_plan.md §2.3.11`; **no code** (deliberate — gated behind the review), `w17-mapper` clean at `59d1739`, no active enum value, PackChannels byte-identity + GS 746/746 + proto:check unchanged. Next (GATED): **first U4 implementation slice — only if/after FIRST_ACTIVE review approved** |
| CB9 | Gimbal endpoints + console | `BLOCKED_HARDWARE` | HARD GATE: A2 + Phase B; needs CB7 mount |
| CB10 | Integration + bench milestone | `BLOCKED_EXTERNAL` | needs CB8, CB9, Codex Batches 5–7, FIRST_ACTIVE review |

**2026-07-30 — FIRST_ACTIVE gate strengthened: I10 + R15 + an input-provenance rule** (adversarial
review of the §2.3.11.6 checklist; documentation only, no code). The gate had a hole: **nothing in
R1–R14, I1–I9, or Groups A/B/C/D covered the *gamepad itself disappearing*.** D15 tests deadman
*release* (a value transition); the Group D "Disconnect/reconnect" row is about the **iPhone/UDP
5602** stream. Device *disappearance* was never distinguished from value *release*.

**The defect that makes it matter is confirmed present in the fork**, traced 2026-07-30:
`pkg/config/input_button.go:77` returns `nan=true` when the gamepad is absent from the device
registry, and `pkg/config/output_tx.go:43` does `if nan || ch < 1 || ch > 16 { continue }` over a
**persistent `*[16]util.CRSFValue` struct field that is never reset to neutral at the top of a
tick** — so `continue` means the channel **retains its previous tick's value indefinitely**. Hold-last
semantics at the channel level. Failure it would produce: deadman held in `ACTIVE`, gamepad drops,
the deadman channel **latches**, head intent still fresh/centered/enabled ⇒ arbiter reads
`armed == true` and stays ACTIVE; the C1 right-stick override is dead too (same frozen array). Added:
**I10** (device loss ⇒ disarm, identical to release), **R15** (demonstrated by physically unplugging,
from `ARMING`/`ACTIVE`/`OVERRIDDEN`, reconnect proves no restore), **Group D rows D19–D22**, and an
**input-provenance rule in §2.3.11.1** — the arbiter must source arm/deadman/override from a signal
carrying explicit validity, never from the hold-last channel array. R15 is hardware-*procedure* class,
**not** Phase-B class. Overall FIRST_ACTIVE verdict unchanged: **NO-GO / BLOCKED**.

**⚠ Related pre-existing defect, NOT closed by the above and outside CB8's scope.** The same hold-last
behaviour affects **every** gamepad-driven channel today, **including throttle and steering**, with no
head tracking involved. A USB gamepad dropout while driving through the mapper freezes the last
throttle command, and **the firmware's failsafe does not fire** — this is not radio loss, the mapper
keeps transmitting well-formed CRSF at full rate with stale payload (link up, CRC valid, throttle
frozen). Sits directly under the "failsafe first" priority in `w17-control-fw/CLAUDE.md`. **Tracked as
a separate item; not yet investigated or fixed.** Residual uncertainty deliberately recorded: whether
`AlertDeviceChan` / device-removal handling elsewhere invalidates the config or zeroes the array
before the next tick was **not** traced — the *mechanism* is confirmed, the *end-to-end outcome* is
PLAUSIBLE and needs a test. Also open: `EvalNoData` is `{0,…,0}`, i.e. below the valid CRSF 172–1811
range, so what the firmware decoder does with an all-zeros payload is a second unanswered question.

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
- **ELRS TX enumeration on real Windows (`go.bug.st/serial` v1.6.0): UNVALIDATED.**
  The v1.6.0 bump (`w17-mapper` `f0a18f3`) was cleared on timing grounds on this macOS
  host — `Write`/`Read` byte-identical v1.5.0 → v1.6.0 in both `serial_unix.go` and
  `serial_windows.go`, delta confined to enumeration / `Open` error wrapping / an
  uncalled `Drain()` / cgo wrappers, and `crsf.PackChannels` byte-identical (12 frames /
  312 bytes, one SHA across off / on-valid / on-stale / on-invalid). The one residual is
  **real Windows enumeration of the ELRS TX**, which no macOS host can exercise. Runs
  with the other Windows-hardware unknowns above (netsh/WinRT, camera→mediamtx→WHEP,
  real iPhone W2/W3, Windows DPAPI). Evidence ledgers, not duplicated here:
  `w17-ground-station/docs/setup_flow_bench_checklist.md` + the matrix in
  `w17-ground-station/docs/audits/2026-07-12-pre-hardware-hardening-audit.md`;
  `w17-control-fw/project-review/11_hardware_validation_plan.md`.
- **`npm run smoke:electron` CANNOT RUN on this macOS host — machine limitation, not a code
  gap.** Gatekeeper denies the `node_modules` Electron binary ("library load denied by system
  policy"). Reproduced at a clean `e09369b` **before** any change, which is what makes it the
  machine and not the code. **Windows CI covers it and passes** (the `package-smoke` job).
  Recorded so no future session reports a failed local smoke as a regression, or treats its
  absence as an untested surface.
  - Also for test authors: **vitest scans an entire test file for the environment docblock
    token, including inside prose.** Writing it in a comment silently switched
    `responsiveLayout.test.js` to jsdom and broke its `import.meta.url` file reads. There is
    now a warning note in that file.
- **mDNS discovery of the iPhone HUD: BUILT 2026-07-25 (CB4) — real-device validation PENDING.**
  The canonical contract carries a Discovery section (`_w17hud._udp.local.`, advisory
  user-confirmed hints only; canonical 2026-07-10, mirrored at rev `84532ed`
  2026-07-14) and the iPhone advertises since `1e332ef`. **The Windows side is no longer
  unbuilt** — it shipped at GS `92cd894` with no new dependency and no 25th preload key
  (hand-rolled `node:dgram`: `shared/dnsWire.js` wire codec + `shared/hudDiscovery.js`
  contract policy + `main/HudDiscovery.js` transport; discovered HUDs ride the **existing**
  `setup:addr-hint` channel, which already answers "what could the iPhone's address be?",
  so the surface stays at 24). Queries only while PIT WALL is active, **never** under
  `W17_WIFI_SIM`; advisory user-confirmed hints only; **W3 stays LOG-ONLY**.
  **Still PENDING: real-device verification.** Every test is a byte fixture — no advertising
  iPhone has ever been seen by this code. Residual limits recorded in
  `w17-ground-station/docs/proposals/iphone_mdns_discovery.md`: subnet-broadcast addresses,
  wall-clock timing, the QU-bit assumption. That proposal's "nothing is implemented on either
  side" header was itself the real contract drift and is corrected; the service definition
  matched the mirrored section exactly, and contract §1–§7 + Discovery were **not** touched.
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
