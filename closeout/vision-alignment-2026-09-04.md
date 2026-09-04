# Close-out vision-alignment / readiness audit — 2026-09-04 (part B, READ-ONLY)

Auditor: Opus 5, independent of every implementer, reviewer and verifier in the fix wave.
Successor of `2026-08-16_vision_audit_report.md`. Brief: `<SP>/briefs/CLOSEOUT-audit.md` part (B).

## VERDICT

**READY-EXCEPT-ASSEMBLY-AND-BENCH: no — conditionally yes on two named closures.**

Every Tier-A / gift-blocking finding in the grand verdict is closed in code with evidence at the
current trunks, and **I found no outstanding software defect**. Two things stand between here and
"the only remaining work is assembly and bench":

1. **The mapper's CI is RED at its trunk** (`w17-headtrack` `ebf89fa`, run 33840857908), so OD-14
   ("CI green at trunk joins the ready definition") is unmet for one of the six repos. A fix
   branch is in flight; the re-run is the proof. **PENDING — do not record as closed.**
2. **Three shipped runbooks still instruct their reader that closed blockers are open.** The
   giftee-PC install guide tells the operator not to run its own final stages; the master
   sequence's §0 blocker table is stale in 12 of 14 rows; the booklet's editorial notes still say
   the phone video path "is still a stub today". The vision's own definition of ready-before-
   assembly names "runbooks, install guides, handover checklist" as deliverables that must be
   "complete and reviewed" — these are not. This is bookkeeping, not engineering, but it is
   inside the ready definition, so it is named rather than waived.

If the mapper CI goes green and the stale-blocker sweep lands, the answer becomes **yes**: no code
change would be required, and every remaining item is owner-, measurement-, or bench-gated.

---

## 0. Scope, trunks and read-only attestation

Audited at the following heads, all confirmed by `git rev-parse` and all **clean before and after**
this audit (`git status --porcelain` = 0 lines at each, verified twice):

| repo | trunk | SHA | CI at HEAD (re-checked live, not read from a doc) |
|---|---|---|---|
| w17-control-fw | main | `39a4f3c` | run 33814317181 **success** |
| w17-soundlight-fw | main | `7220c08` | run 33814343711 **success** |
| w17-ground-station | main | `263e69a` | run 33818863341 **success** |
| iPhone_rc | main | `7aaf2cf` | run 33816071199 **success** |
| w17-mapper | `w17-headtrack` (NOT main) | `ebf89fa` | run 33840857908 **FAILURE** — **PENDING** |
| w17-3d-codex | main | `5dddedb` | no CI configured (no `.github/workflows/`) |
| workspace | main | `e08339a` at audit close (`488ac7f` at open; another session is landing state commits) | no CI configured |

Nothing was flashed, powered, built, committed, checked out or pushed. No serial port was opened.
The only writes this session made are this file.

---

## 1. Definition of done — v1.0 (`W17_PRODUCT_VISION.md` items 1–8)

| # | Done-bar item | Verdict | Evidence |
|---|---|---|---|
| 1 | Gentle FPV driving, indoor + smooth outdoor; speed tunable, gentle defaults | **OPEN (bench)** | Gearbox/tuning envelope exists and is native-tested; no car exists. A2 NOT-EXECUTED ⇒ Phase B BLOCKED. Nothing in software can close this. |
| 2 | Showpiece finish: shell preserved, electronics inside, lift-out cassette | **OPEN (owner + bench)** | Parametric designs exist and render: `w17-3d-codex/11_cad/{esp_tray,second_floor_cage,gcs_box,fit_check_coupons}.scad`, `render.sh --table` = 17 rendered / 0 failed. Every load-bearing dimension is measurement-gated: `11_cad/w17_params.scad:26-34` (MEASURED/DERIVED/ESTIMATED discipline), `:345-347` (nothing in the ESTIMATED block is a measurement). Owner residue = measurement session M-00…, then fit-check coupons, then production prints. |
| 3 | Sound + light fully running (decisions 15–16) | **CLOSED BY CONSTRUCTION (software) / OPEN (bench) for the visual + audio judgement rows** | link2 v2 carries the engine voice + operator volume end to end: `w17-control-fw/docs/link2_protocol.md:112-113`, consumed at `w17-soundlight-fw/lib/link2/include/link2/Link2Frame.hpp:128-129` and composed into the synth at `w17-soundlight-fw/src/main.cpp:288-297`. Indicator minimum-on implemented (`lib/lights/include/lights/LightRenderer.hpp:275-282`), loop watchdog armed (`src/main.cpp:247`), throttle clamped at ingress (`lib/enginesim/src/EngineSim.cpp:23`). 150/150 native, both envs build, CI green. Halo/floor visibility in daylight and the ~70 ms audio lag stay Phase-B rows. |
| 4 | Onboard USB-C charging: hidden flap, hard charge/run interlock, charge-state light | **OPEN (owner)** | The interlock is architecturally real, not a story: the XT90-S loop key sits inline on the pack lead, off the PDB, by decision F9b — `w17-pdb-build-and-connector-guide.md:54-56`. But the **2S balancing charge module is still unselected and marked a BLOCKER**: `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md:81` (OP-49) — "zero fit confidence until module selection and measurements", and a charge-safety specification must close before any powered test. Flap + state-light placement is measurement-gated (`AA_electronics_placement_study.md:169`, `:546`, `:580-584`). **This item is not on the workspace-level owner-residue shopping list — see §5.** |
| 5 | Functional actuated DRS | **OPEN (bench)** | Firmware channel + the DRS-open light tell exist (`w17-soundlight-fw/lib/lights/src/LightRenderer.cpp` `kDrsGreen`); the flap linkage is a measurement-gated mechanical design (`w17-3d-codex/10_assembly_architecture/B_component_envelope_register.md:36` SRV-DRS "fit-check TO MEASURE"). |
| 6 | Laptop HUD **and** iPhone HUD usable, chosen per session | **CLOSED BY CONSTRUCTION (software) / OPEN (VM + bench)** | Laptop: 1685/1685 vitest, 73 files, CI green; the HUD now has a telemetry source that can coexist with the drive program (§2 rank 2). Phone: OD-16 WHEP/WebRTC in a bundled `WKWebView` is landed and tested — `iPhone_rc/FPVHUDApp/Video/WhepVideoView.swift`, `PhoneVideoEndpoint.swift:128-129`, `Resources/whep.{html,js}`; 156/156 tests, CI green. Glass-to-glass latency is `[bench-TBD]`; nothing has run on real Windows. |
| 7 | Active head-tracked gimbal (FIRST_ACTIVE passed), stick pan/tilt retained | **OPEN (gated — by design)** | FIRST_ACTIVE NO-GO stands. `u4-arbiter` parked at `4e445c9`; `git ls-remote --heads origin` on w17-mapper returns **only** `w17-headtrack`, so the branch has never been pushed, as required. R1–R16 + bench evidence owed; R15 needs a gamepad + Windows box. Structurally last per the vision's own sequencing note. |
| 8 | Giftee-operable by the glovebox booklet alone | **OPEN (VM + owner editorial)** | Materially advanced: race day now walks to the GRID on success and auto-fires the last press **only on a positive link claim** (`w17-ground-station/renderer/setupFlow.js:305-322`, OD-19 addendum), and the drive program actually starts the radio (§2 rank 1). Two things keep it open: the printed clause at `learning-manual/14_glovebox_owners_booklet.md:117` still says RACE DAY "checks her camera, the controller, the radio" when it checks hotspot / mapper / telemetry / bridge (`main/raceDayOrchestrator.js:76`) — camera and controller are still not checked; and the **only** proof of "one action is one action" is the WS3 Windows-VM run, which has never happened. |

"Ideally" (stranger-rebuildable manual): **deferred by owner decision A1** to post-gift. Not a v1.0
blocker. The manual's truth pass against current code did land (ch. 11 env table at
`learning-manual/11_build_flash_debug_workflow.md:20-27` matches all seven shipped envs).

---

## 2. Tier-A / gift-blocking findings from `grand.verdict.json`

| rank | finding cluster | Verdict | Evidence at the trunks above |
|---|---|---|---|
| 1 | MAP-1/MAP-2/SYN-2 + MAP-3/4/5/10 — RACE DAY cannot emit a CRSF frame | **CLOSED WITH EVIDENCE** (wire proof stays bench) | Unwrap-before-wrap: `w17-mapper/pkg/client/grpc_client.go:50-65` (`configPayload`). Self-start from the profile's own `tx.port` after SetConfig: `:200-203` → `selfStartLink` `:268-310`, with the mismatch warning at `:244-256`. Placeholder refusal **before** StartLink: `:134-136`; unmarked-profile refusal on the race-day path: `:154-156` (OD-9/D2 addendum). GS side: mapper step waits for the real link and reports `link-not-yet` rather than claiming "running" (`main/raceDayOrchestrator.js:84-88`, `renderer/setupFlow.js:1774`). |
| 2 | giftee-ux-6 + ip:correctness-1 — no screen can tell Lola the battery is low | **CLOSED WITH EVIDENCE** | GS: `mapper-grpc` source shipped (`shared/settings.js:32-33`), race day gained a telemetry step (`main/raceDayOrchestrator.js:76` `STEP_ORDER`, `:525-595`), the one permitted write is credential-safe (`main/settingsStore.js:360-378`; `raceDayOrchestrator.js:116` `CREDENTIAL_UNSAFE_STATES = {undecryptable, session-only}` — matching the OD-19 refinement exactly), and the path is read-only by construction (`main/mapperTelemetryGrpcConnect.js:20` names only `getTelemetryStream`; pinned by `test/noControlPath.test.js`). Phone: the demo seed is gone — `FPVHUDApp/Networking/UDPTelemetryReceiver.swift:16` and `:45` now seed `TelemetryState.unknown` (`Models/TelemetryState.swift:244`). |
| 3 | boundaries-1 + correctness-3/4 — the gift build has no video relay | **CLOSED WITH EVIDENCE** | `.github/workflows/ci.yml:81` fetches mediamtx with `--require-pin`, `:87` asserts the packaged contents, `:100` builds the NSIS installer; `electron-builder.yml:21` packages `proto/**` and `:25-28` the mediamtx resource; the windows_amd64 digest is recorded in `scripts/mediamtx-pin.json`. Root cause was the shadowing `build` field in package.json, removed and pinned by a test (`electron-builder.yml:1-6`). Spawn-`error` handlers exist at all three sites: `main/mediamtx.js:76`, `main/elrsLauncher.js:75`, `main/mapperRunner.js:198`. **Residual (recorded, not a blocker):** the NSIS installer is built from the asserted `--dir` output but is never unpacked and inspected on its own. |
| 4 | SYN-1 + giftee-ux-2 — windowless zombie, and the booklet's own recovery path wedges | **CLOSED WITH EVIDENCE** | Close interception: `main/main.js:194` → `main/appWiring.js:473`; single-instance lock at `main/appWiring.js:510`; already-on hotspot with the **saved** SSID becomes `ok('external')` while a different or unnameable one still fails: `main/raceDayOrchestrator.js:336-345` (OD-7). A `W17_SINGLE_INSTANCE=1` smoke:electron scenario runs in CI (`ci.yml:59`). |
| 5 | Proof infrastructure — three trunks with no usable CI signal (OD-14) | **PARTIALLY CLOSED — mapper PENDING** | control-fw, soundlight, GS and iPhone_rc are all green at their exact trunk SHAs (re-checked live; run ids in §0). **The mapper is not**: see §3 below — its CI has now run four times, once green (`21834fe`), then red at `6e99d51` (four failures) and red at `ebf89fa` (three). |
| 6 | Printed truth — the booklet promises what HEAD does not do | **PARTIALLY CLOSED / DRIFTED** | Genuinely closed and verified against code: the MAP-6 controller row (`booklet:252` "Reconnect the controller — she picks it right back up"), the showcase/shelf-show rows rewritten for the `esp32dev` ship image, the DRS-open tell row, the honest 7-day phone paragraph. **Still open:** the `:117` camera/controller/radio clause (§1 item 8), and the editorial notes at `:370-474` which describe landed work as in-flight (§4). |
| 7 | correctness-2 — one bad write eats the gift configuration | **CLOSED WITH EVIDENCE** | Tri-state read at `main/settingsStore.js:95-110`, corrupt-file quarantine at `:115-121`, `.bak` restore, GARAGE recovery line via `recoveryStatus()` `:390-392`. |
| 8 | cf sensor honesty (fault-injection-3, correctness-3, timing-1) | **CLOSED WITH EVIDENCE** (Phase-B rows residual) | Two-sided implausibility band with a symmetric dwell: `lib/telemetry/include/telemetry/BatteryMonitor.hpp:52-53`, `:113`, `src/BatteryMonitor.cpp:35-64`; deliberate CRSF frame omission at `src/main.cpp:968`. Speedo glitch rejects to 0 with a saturating counter: `lib/telemetry/src/WheelSpeed.cpp:48-59`. Hall rate guard as a pure native-testable helper with a compile-time 20× margin: `lib/telemetry/include/telemetry/PulseRateGuard.hpp:53-54`. 360/360 native; registration and delivery-shape checks wired into CI (`ci.yml:35`, `:48-56`, `:81`). |
| 9 | sl lights truth, WDT, clamp | **CLOSED WITH EVIDENCE** (bench visual judgement residual) | See §1 item 3. Sim/real separation is enforced by marker (`platformio.ini:40`, `src/main.cpp:19/48/182/253/260/313`) plus `tools/delivery_shape_check.sh` in CI with a positive control. |
| 10 | MAP-6 hot-plug, MAP-8 bind policy, boundaries-3/4/5 | **CLOSED WITH EVIDENCE** (Windows/HIDAPI half `[bench-TBD]`) | Hot-plug: `pkg/devices/hotplug.go:89-92` handles `JoyDeviceAdded`/`JoyDeviceRemoved`, `:181` retires rather than closes the handle; id survives an unplug by construction (`pkg/devices/util.go:20-32`); the CPU-spin is gone (`pkg/devices/controller.go:199-200`). Bind policy: `pkg/server/controller.go:35-43` (`DefaultBindHost = "127.0.0.1"`), `pkg/http/controller.go:96`, flags at `cmd/elrs-joystick-control/main.go:85-89`, pprof gated. Env scrub at both GS spawn sites: `shared/childEnv.js:32`, `main/mapperRunner.js:125`, `main/elrsLauncher.js:55`. Fail-closed hook enum check incl. the header-tail hole: `.githooks/pre-push:245-259`. `-list-devices` JSON: `cmd/elrs-joystick-control/main.go:117`, `:244`. |
| 11 | Artefact contents asserted by CI, not prose | **CLOSED WITH EVIDENCE** | cf `ci.yml:81` + `:98/:117` (two-tier link2 checker), sl delivery-shape check, GS `scripts/assert-packaged.js` (mediamtx executable, `mediamtx.yml`, and both runtime protos at `:36-42`) and the hermetic contract-mirror job (`ci.yml:26-33`). |
| 12 | WS3 — nothing has ever run end to end on Windows | **OPEN (owner + bench)** | Unchanged and unchangeable from this Mac. The scripts and the VM runbook exist (`w17-ground-station/scripts/windows-validation/`, `w17-windows-vm-validation-runbook.md`); the owner installs VMware Fusion + Windows 11 ARM; ~30 of 40 checks additionally gate on the unbought 5 GHz AP adapter. This is the **only** acceptance gate the review cannot substitute for, and the only proof of done-bar item 8. |

Safety boundaries 1–7 re-verified independently, all holding: firmware carries no iPhone/UDP/JSON
awareness (grep over `w17-control-fw/{src,lib}` and `w17-soundlight-fw/{src,lib}` returns nothing
outside comments); W3 stays a log-only consumer (`w17-ground-station/main/HeadTrackingReceiver.js:2`,
`main/HeadIntentDiagnosticsClient.js:14-15`); the GS opens no control path (`test/noControlPath.test.js`
sweeps every runtime module under `main/`, `shared/`, `renderer/`, so a new module cannot bypass it);
FIRST_ACTIVE NO-GO; `u4-arbiter` never pushed.

---

## 3. The one live software gap: the mapper's CI (OD-14)

**State it plainly, and correct two documents while doing so.**

`gh run list --repo beforethenexttolast/w17-mapper` returns **four** runs, not zero:

| run | head | conclusion |
|---|---|---|
| 30143587470 | `f0a18f3` | success (a Dependabot graph update — not a build) |
| 33780678866 | `21834fe` | **success** — the B7 release workflow's first real run |
| 33810821415 | `6e99d51` (mapper A) | **failure** — 4 tests in `pkg/link` |
| 33840857908 | `ebf89fa` (mapper B, trunk) | **failure** — 3 tests in `pkg/link` |

Both failures are Windows-only timing failures in `pkg/link`
(`TestStopReturnsWhileParkedOnATelemetryFrame`, `TestStopReturnsWhileParkedOnTheKeepalive`,
`TestReadErrorsAreCountedEvenWhenNotPrinted`; the fourth at `6e99d51`,
`TestKeepaliveStaysQuietWhileTelemetryFlows`, was already fixed by mapper B). Every other package
passes and the binary builds. **The mapper's CI cell is PENDING, not closed.**

Two corrections that follow from this, neither of which changes the verdict but both of which
should be carried into the close-out bookkeeping:

- `<SP>/closeout/baseline-2026-09-04.md` records "**no CI runs exist for this repo at all**
  (`gh run list` empty on both branches, and unfiltered)". That is an artefact of `gh` failing to
  resolve the repo from that working directory — `gh run list --repo beforethenexttolast/w17-mapper`
  returns the four runs above. The baseline's mapper CI cell should read "RED at `ebf89fa`", not
  "none".
- `W17_CURRENT_STATE.md` §6 says "mapper's first-ever CI run = the release-workflow dispatch after
  mapper B lands". The first-ever run was in fact `21834fe` on 2026-09-03 and it was **green**; the
  red run at `6e99d51` (mapper A's own landing) is recorded nowhere.

**The in-flight fix is not test-only.** `<SP>/wt-mapper-fixB`'s successor worktree
`<SP>/wt-mapper-wintests` is at `ca87cb8` and touches `pkg/link/recv.go` as well as two test files:
commit `6b7751f` changes the recv loop from `case <-ticks: currentTickTime = clock.Now()` to
`case currentTickTime = <-ticks:`, removing a second racy clock read. On the real `wallClock` the
two instants are a scheduling hair apart, so the change is behaviour-neutral in production and
removes a genuine race under the injected clock — I concur with the fix on reading it, but the
brief's description of the branch as "test-only" is inaccurate and the re-verify should treat
`recv.go` as production code under review.

---

## 4. Drift register — superseded behaviour still described in shipped text

Every item below is a document describing behaviour the code no longer has. None is a code defect.
Ordered by who gets hurt.

**(a) A giftee-facing runbook that stops itself on closed blockers**

- `w17-giftee-pc-install-guide.md:22-26` — "**Do not run this guide's final stages (§6–§7) yet.**
  Fourteen 2026-09-02 grand-review findings … mean the RACE DAY button does not work end to end
  today". Superseded: MAP-1/MAP-2 landed at mapper `6e99d51`, the GS half at `263e69a`.
- `:250-251` and `:297-298` — the troubleshooting table still tells the operator that the mapper
  "panics on its own committed profile" (MAP-1) and that RACE DAY "never starts the radio link"
  (MAP-2/SYN-2), and to "not proceed past §5.3 until `CURRENT_STATUS.md` shows it closed".

**(b) The master sequence's §0 blocker table — 12 of 14 rows stale**

`w17-parts-to-gift-master-sequence.md:35-49`. Two rows were refreshed to "**Closed in code**"
(MAP-8 at `:42`, MAP-6 at `:45`); the other twelve still read as live defects with pre-fix
citations — e.g. `:36` cites `grpc_client.go:57-62` for MAP-1 (now `:50-65`, and fixed), `:37`
cites `raceDayOrchestrator.js:44` + `grpc_client.go:35` for MAP-2/SYN-2, `:38` cites `main.js:308`
for SYN-1, `:39` cites `ci.yml:53` for boundaries-1. The gate token **CODE-BLOCKERS-CLOSED**
(`:276`) is therefore not marked achieved, and `w17-handover-checklist.md:91-96` — which correctly
defers to this table rather than duplicating it — inherits the staleness.

**(c) The booklet's editorial notes (source-only, never printed)**

`learning-manual/14_glovebox_owners_booklet.md`:

- `:375-391` `[fix-wave: phone-video]` — "**Verified at HEAD the video path is still a stub
  today** — `VideoSurface.swift` literally renders 'NO VIDEO / APFPV RTP / H.265 PIPELINE
  STUBBED'". False at iPhone_rc `7aaf2cf`: the WHEP/WebRTC path is landed
  (`FPVHUDApp/Video/WhepVideoView.swift`, `PhoneVideoController.swift`, `Resources/whep.html`).
- `:392-409` `[fix-wave: GS giftee-ux-3]` — cites `raceDayOrchestrator.js:73` for a
  hotspot/mapper/bridge `STEP_ORDER`; the constant is now at `:76` and carries a fourth,
  `telemetry`, step. The OD-6 auto-GRID/auto-START it calls "an in-flight fix" landed at GS
  `263e69a` (`renderer/setupFlow.js:305-322`).
- `:456-474` `[fix-wave: SYN-2 / MAP-2]`, filed under "**OWNER-GATED, NOT fixed here … these three
  have no ruling yet**" — "today RACE DAY does not start the radio link", citing
  `grpc_client.go:35-36`. Both halves are wrong now: OD-5 ruled it, and `selfStartLink` at
  `grpc_client.go:200-203`/`:268-310` does it.

**(d) Ground-station docs that still call mediamtx localhost-only** (superseded by OD-16, which
deliberately did *not* widen anything because a bare `:8889` already bound every interface, and by
the ICE-candidate list now shipping `192.168.137.1`):

- `w17-ground-station/docs/iphone_bridge_readiness.md:93-94` — "mediamtx is deliberately
  **localhost-only** (`webrtcAdditionalHosts: [127.0.0.1]`, `mediamtx.yml:19`)". At HEAD:
  `mediamtx/mediamtx.yml:41` = `webrtcAdditionalHosts: [127.0.0.1, 192.168.137.1]`, with `:13-21`
  explaining the phone pull.
- `:306` — "**Do not change yet:** `mediamtx.yml` stays localhost-only".
- `docs/video_topology_baseline.md:52` — same claim, by reference.
- `docs/iphone_bridge_readiness.md:252` — "(Today the repo has no control path at all to touch)".
  Still true in effect (the mirrored proto declares no mutating RPC) but stale in wording: the GS
  now runs two read-only gRPC consumers and manages the mapper **process**. The OD-1 guardrail
  sentence in `CLAUDE.md` is the accurate formulation; this line predates it.

**(e) The Windows-VM runbook on the mapper's exposure**

`w17-windows-vm-validation-runbook.md:399-401` — "the mapper's gRPC `:10000` is up,
unauthenticated, **on all interfaces** with reflection on … the ground station has no client that
could [call StartLink]". Superseded by OD-8 / mapper `5d4e12d`: both listeners bind `127.0.0.1` by
default. The safety conclusion the paragraph reaches is now stronger than it claims, but the stated
premise is false, and "no client" is stale (there are two read-only ones).

**(f) `CURRENT_STATUS.md` header — the live section, stale by one fix-wave**

`CURRENT_STATUS.md:11-37` still records GS main `439f09f` (actual `263e69a`), iPhone_rc `85ce486`
(actual `7aaf2cf`), mapper `6e99d51` (actual `ebf89fa`), test counts of 1525/72 and 84 (actual
1685/73 and 156), and lists GS branch B, mapper branch B and phone live video as "**In flight**"
when all three have landed. This is the file the close-out step is already scheduled to rewrite
(`W17_CURRENT_STATE.md` §7.6), so it is expected — recorded here so the rewrite is not skipped.

**(g) `W17_PRODUCT_VISION.md` — three places the vision text has been overtaken by its own program**

- `:118` — the head-tracking reality check still states flatly "**no arbiter code**" before the
  2026-08-16 amendment at `:120-126` corrects it. Arbiter code exists on the parked, never-pushed
  `u4-arbiter` branch (`4e445c9`). The paragraph contradicts itself in reading order.
- `:128` — the wheel reality check cites `w17-mapper/pkg/devices/util.go:27` for `JoystickOpen`;
  at `ebf89fa` line 27 is a comment and `JoystickOpen` lives at `util.go:47` /
  `pkg/devices/inventory.go:135`. (`controller.go` `JoystickEventState` at `:216`/`:263` still
  holds.) The claim is intact; the citation drifted.
- `:151-156` — the backlog still lists "**Sound profile selector + volume**" and "**Ignition-on
  animation + DRS-open tell**" as "recorded, not scheduled". Both are **built and shipped** (§1
  item 3). A backlog that lists delivered features understates what v1.0 already contains.
- `:197-199` — the amendment says the showcase-mode trigger is DECIDED as the board-1 SP3T boot
  strap "firmware on control-fw main", which is true, but does not note that under OD-2's ship
  image (`esp32dev`) the selector is never read: `w17-control-fw/src/main.cpp:147` pins
  `kBootStrapReading = Floating` and `:148` gates the physical read behind `W17_BT_SHOWOFF`. The
  booklet already says this correctly; the vision does not. (Showcase mode is explicitly *not* on
  the done bar — decision 2, "core-if-cheap" — so this is a truth gap, not a scope gap.)

---

## 5. Residual list

### Owner residue (nothing here is Claude-actionable)

1. **Shopping list**, incl. the **5 GHz / 5.8 GHz AP-capable Wi-Fi adapter** that gates roughly 30
   of the 40 WS3 validation checks, plus the powered USB hub, SP3T switch, ELRS TX label and TX16S
   RF check (`CURRENT_STATUS.md:86-87`).
2. **The 2S balancing USB-C charge module is still unselected** —
   `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md:81` (OP-49) marks it a
   **BLOCKER** for done-bar item 4, and a charge-safety specification must close before any powered
   charge test. **It is not named on the workspace-level owner-residue shopping list** — add it.
3. **Measurement session M-00…** (`w17-3d-codex/w17-mechanical-measurement-session-prompt.md`) —
   gates every production print, the cage/tray geometry, the DRS linkage and the charge-flap
   placement; done-bar items 2, 4 and 5 all wait on it.
4. **VMware Fusion + Windows 11 ARM install** (A4) — the WS3 session cannot start without it; it is
   the only proof of done-bar item 8.
5. **Booklet editorial pass** — the `:117` camera/controller/radio clause; whether "one press" is
   printed with or without the positive-link-claim hedge; the 21–22 `[TBD-at-bench]` markers; the
   name/contact free-texts.
6. **Ship-image decision** (OD-2 `esp32dev` unless BT1 passes before handover) and the
   `giftee-ux-3` printed-wording pick.
7. **Vision-text refresh** (§4(g)) — the vision is an owner-owned file; it changes only when the
   owner changes it, so the four drifts above are reported, not edited.

### Bench / hardware gates (unchanged, all still open)

- **A2 NOT-EXECUTED ⇒ Phase B BLOCKED.** Nothing flashed, nothing powered.
- **BT1** bench gate (decides whether `esp32dev_btshowoff` may ship at all).
- **FIRST_ACTIVE NO-GO** — R1–R16 + bench evidence for the head-tracked gimbal; R15 needs a gamepad
  and a Windows box, not Phase B.
- **Dim-light / daylight halo judgement** at the raised floors (soundlight #55).
- **Latency**: phone glass-to-glass `[bench-TBD]` (OD-16); the ~70 ms audio lag.
- **Hot-plug on real Windows** — that a DS4 raises `JOYDEVICEADDED`/`REMOVED` under HIDAPI at all,
  and that its GUID is byte-identical across a re-plug (`w17-mapper/configs/README.md:353-356`).
- **The link window** — race day's 5 s wait for the mapper's positive link claim is `[bench-TBD]`;
  WS3 script 50 records the real port-open latency.
- **CRSF on the wire** — not one frame has ever been observed leaving the mapper.
- Phase-B measurement rows opened by this wave: both battery-divider legs lifted in turn, the Hall
  edge-storm rate and per-edge ISR cost (which sets OD-11's constant), the GCS-box USB power budget.

### Software (the whole list — two items, no code defect)

1. **Mapper CI at trunk is RED** (`ebf89fa`, run 33840857908; three Windows-only `pkg/link` timing
   tests). Fix branch `fix/link-tests-windows-timer` @ `ca87cb8` is in flight; it touches
   `pkg/link/recv.go` as well as tests, so it needs a production-code re-verify, not a test-only
   one. **OD-14 is unmet for one repo until that run is green.**
2. **Stale-blocker documentation sweep** — §4(a)–(f): the giftee-PC install guide's §6–§7 stop
   order and troubleshooting rows; the master sequence's §0 table (12 of 14 rows) and its
   CODE-BLOCKERS-CLOSED token; the booklet's three stale editorial notes; the four
   mediamtx-localhost-only lines; the VM runbook's all-interfaces paragraph; the
   `CURRENT_STATUS.md` header.

**No software defect found.** I spot-read the landed code behind every Tier-A closure rather than
the reports — `configPayload`/`selfStartLink`/`explicitPortMismatch`, the pre-push enum awk, the
hot-plug retire path, `patchTelemetrySource` + `writeAtomic`, the credential-unsafe state set, the
auto-START arming condition, the tri-state settings read, the packaging assertion's required-file
list, the battery band and dwell, the pulse-rate guard, the indicator min-on state, the WHEP
endpoint's origin checks — and found nothing wrong. Two recorded residuals that are *not* defects:
the NSIS installer is asserted only via the `--dir` output it is built from (never unpacked and
inspected), and `w17-ground-station/docs/iphone_bridge_readiness.md:93-94`'s "localhost-only" was
already known to overstate.

---

## 6. Bookkeeping corrections owed at close-out

1. Baseline part A's mapper CI cell: "no CI runs exist" → "RED at `ebf89fa`, run 33840857908"; and
   its mapper row is pre-B (`6e99d51`), so a post-B re-run is still owed despite
   `W17_CURRENT_STATE.md` §3 recording it as done.
2. `W17_CURRENT_STATE.md` §6: the mapper's first-ever CI run was `21834fe` (green, 2026-09-03), not
   the post-mapper-B dispatch; the red run at `6e99d51` is unrecorded.
3. `W17_CURRENT_STATE.md` §1 workspace row: HEAD moved `488ac7f` → `e08339a` during this audit
   (another session is landing state commits) — expected per the concurrency rule, noted so the
   final commit re-reads HEAD before writing.
4. The push grant (A7) stays open until the mapper's CI run is green and the doc sweep lands.

## File written

`/private/tmp/claude-501/-Users-vitaliykhomenko-Documents-projects/9a131be5-75e5-4b91-9d54-0fedf52c1bf8/scratchpad/closeout/vision-alignment-2026-09-04.md`
