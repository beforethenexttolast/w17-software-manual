# W17 parts-to-gift master sequence

**Date:** 2026-09-03 · **Owner:** Claude Code (workspace runbook layer, readiness program WS-2,
`2026-09-02_readiness_program.md`). **Status: docs only. No hardware was touched, flashed, or
powered to write this file.** It answers one question the workspace did not previously answer in
one place: *given the parts on hand, what is the single ordered sequence from "boards on the desk"
to "Lola turns the key," and which document is authoritative at each step?*

> **A2 is NOT-EXECUTED. Phase B is BLOCKED.** Nothing in this document changes that. Every stage
> below that touches hardware inherits the gate it cites; no stage here grants a gate, and no
> number in this file is measured — every hardware value is `[bench-TBD]`, every Windows-only fact
> is `[win-TBD]`. This file is the **spine that links the existing gates in build order**, not a
> new gate of its own.

---

## 0. Read this before the gate ladder — the sequence runs in parallel tracks, and one is broken today

The car-side hardware track (stages 1–9, plus stage 12's ELRS backup bind, which runs **in
parallel** with the bench sessions in stages 6–9 rather than gating them — see stage 12's own
detail), the ground-side software track (stages 10, 11, 13), and the iPhone HUD track (stage 14,
independent of both) can all run **in parallel** — nothing in the ground-station / mapper software
requires the car to exist, and nothing in the car's bring-up requires a working ground station
(D8's Phase 10 is the only overlap, and it is explicitly late). They converge at **Handover**
(stage 16, which also requires stage 15's booklet markers resolved), and Handover cannot close
until every stage above it is green.

**The ground-side track is not green today.** The 2026-09-02 grand review (`review-seeds/
w17-ground-station.v2report.json`, `review-seeds/w17-mapper.v2report.json`) found that the
one-action "RACE DAY" button — the whole giftee promise this master sequence exists to protect —
does not work end to end yet, for reasons that are pure software and have nothing to do with A2 or
Phase B:

| id | What's broken | Where |
|---|---|---|
| `MAP-1` | The mapper panics and exits on its own committed profile — `-config-file-path` double-wraps `configs/w17-ds4.json` before schema validation | `w17-mapper/pkg/client/grpc_client.go:57-62` |
| `MAP-2` / `SYN-2` | Even if MAP-1 is fixed, RACE DAY's argv whitelist cannot pass `-tx-serial-port-name`, so the mapper never calls `StartLink` — no CRSF frame ever leaves the PC | `w17-ground-station/main/raceDayOrchestrator.js:44`, `w17-mapper/pkg/client/grpc_client.go:35` |
| `SYN-1` | Cancelling the quit prompt after the window is destroyed leaves a windowless zombie process holding the hotspot | `w17-ground-station/main/main.js:308` |
| `boundaries-1` | The CI-built NSIS installer never runs `fetch-mediamtx.js`, so the shipped `.exe` has no video relay | `w17-ground-station/.github/workflows/ci.yml:53` |
| `correctness-2` | An unreadable `settings.json` resets to defaults and the next save overwrites the `.bak` nothing ever reads — the giftee's whole configuration can be silently destroyed | `w17-ground-station/main/settingsStore.js:61` |
| `MAP-5` | An unfilled `REPLACE-WITH-DS4-ID` / `REPLACE-WITH-COM-PORT` placeholder passes every check silently — the car just never arms, with no explanation | `w17-mapper/pkg/config/lint.go:56` |
| `MAP-8` | The mapper's gRPC service (with reflection enabled) and its web UI both bind every network interface, not just localhost, with no authentication — anything else on the giftee's hotspot/Wi-Fi can reach the same `StartLink`/`SetConfig`/`StopLink` controls this guide has the pit crew use from the browser; race day's argv whitelist cannot pass `-disable-web-ui` to narrow this. **`gift_blocking:false` in the mapper report — carried here by orchestrator escalation; its worst case is DISPUTED, not its exposure, which is CONFIRMED** (see `w17-giftee-pc-install-guide.md` §5.3 step 5 and §8 for the firewall-rule mitigation) | `w17-mapper/pkg/server/controller.go:81`, `w17-mapper/pkg/http/controller.go:102`, `w17-ground-station/main/raceDayOrchestrator.js:44` |
| `MAP-3` | Once `MAP-2` is fixed and the link supervisor actually runs, a blocking send from the recv loop to a dead send loop wedges the supervisor permanently — no reconnect, and `StopLink` never returns | `w17-mapper/pkg/link/recv.go:110` |
| `MAP-4` | `SetConfig`'s adoption signal is a droppable non-blocking send — a config apply can be silently ignored while the RPC still reports success | `w17-mapper/pkg/config/controller.go:220` |
| `MAP-6` | The gamepad registry is enumerated once at boot — a pad switched on late, or one that drops and reconnects, never resolves again until the mapper restarts | `w17-mapper/pkg/devices/controller.go:43` |
| `MAP-9` | The two placeholders are per-PC (and per-bus for the pad id), but the kit runs on the giftee's own PC and no handover step fills them there | `w17-mapper/configs/README.md:29` |
| `correctness-4` | A present-but-unrunnable `mediamtx.exe` (Defender quarantine, wrong-arch binary) crashes the whole Electron main process instead of the documented soft-fail — unreachable only because `boundaries-1` means no binary ships at all today; the two land together | `w17-ground-station/main/mediamtx.js:52` |
| `giftee-ux-5` | A mid-session drive-program death is invisible once the HUD gate is hidden — no banner, no radio line, and the booklet's own recovery cue never resolves | `w17-ground-station/renderer/setupFlow.js:240` |
| `giftee-ux-2` | Race day halts at the first failing step, so a hotspot already on — including one the app itself left running from a prior session — can block the drive program the phone link is only "an extra" for. **Status: PLAUSIBLE, not yet CONFIRMED** | `w17-ground-station/main/raceDayOrchestrator.js:161` |
| `giftee-ux-3` | The booklet (`learning-manual/14_glovebox_owners_booklet.md:117`) promises one press; the shipped flow is RACE DAY → STRAIGHT TO THE GRID → START (three presses), and race day's checks don't cover camera/controller/radio the booklet says it does | both repos, owner-gated |

These are **code findings, not runbook findings** — a separate fix wave (readiness WS-1) owns
them, not this document. But a parts-to-gift sequence that pretended RACE DAY already works would
be dishonest, so: **stage 13 (Giftee-PC install + dry run) and stage 16 (Handover) MUST NOT be
declared complete until every id below is closed.**

**The derivation rule (stated once, applies to every id in this section and to the table above):
every `gift_blocking:true` finding in the 2026-09-02 v2 review reports, plus `MAP-8` by
orchestrator escalation** — `MAP-8` itself reads `gift_blocking:false` in the mapper report (its
worst case is DISPUTED, not CONFIRMED), but the exposure it names is CONFIRMED and unresolved, so
it is carried here pending the owner's ruling rather than dropped. That derivation yields **14
ids**: `MAP-1`, `MAP-2`/`SYN-2` (merged — the mapper and GS reports describe the same "RACE DAY
never starts the radio link" defect from two sides), `MAP-3`, `MAP-4`, `MAP-5`, `MAP-6`, `MAP-9`,
`SYN-1`, `boundaries-1`, `correctness-2`, `correctness-4`, `giftee-ux-2` (status **PLAUSIBLE**, not
yet CONFIRMED — carried anyway per the same-severity rule, not demoted on procedural grounds), and
`giftee-ux-5`, plus `MAP-8` (`giftee-ux-3` is owner-gated product wording, not a functional
blocker, but the owner's pick must land before the booklet prints — see stage 15). Track their
closure in `CURRENT_STATUS.md`; this file only names them so nobody plans a giftee-PC dry run
against a build that cannot pass it.

---

## 1. Gate ladder (top-level view)

| # | Stage | Track | Gate token | Canonical doc | Status (2026-09-03) |
|---|---|---|---|---|---|
| 1 | Parts arrival + no-power build start | Hardware | *(build begins)* | [`w17-parts-arrival-build-prompt.md`](w17-parts-arrival-build-prompt.md) | Not started — parts not yet on hand per this file's own precondition |
| 2 | PDB + harness build order | Hardware | SF→S1…S8 (see §3) | [`w17-pdb-build-and-connector-guide.md`](w17-pdb-build-and-connector-guide.md) §5 | Not started |
| 3 | A2 staged no-power gates | Hardware | SF, S1, S2, S3, S4, S4b, S5, S6, S7, S8a, S8b | [`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`](w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md) | **NOT-EXECUTED** |
| 4 | A2 closure — two-part gate | Hardware | A2-CLOSED | same file, §12 (cross-references [`11_hardware_validation_plan.md`](w17-control-fw/project-review/11_hardware_validation_plan.md)) | Not reached |
| 5 | Phase B opens (owner's call) | Hardware | PHASE-B-OPEN | [`11_hardware_validation_plan.md`](w17-control-fw/project-review/11_hardware_validation_plan.md) §Phase B; standalone doc `w17-control-fw/docs/PHASE_B_FIRST_POWER.md` **(being written — reference by path; not yet on disk at this writing)** | **BLOCKED** |
| 6 | Bench bring-up, Phases 0–9 | Hardware | D8-P0 … D8-P9 | [`w17-control-fw/docs/D8_BENCH_BRINGUP.md`](w17-control-fw/docs/D8_BENCH_BRINGUP.md) | Not started |
| 7 | Two-board coordinated flash | Hardware | COORD-FLASH | `w17-control-fw/docs/COORDINATED_FLASH.md` **(being written)** | Not started |
| 8 | On the car + delivery hand-off | Hardware | D8-P11, D8-P11a, SHIP-IMAGE | D8 Phases 11 / 11a | Not started |
| 9 | BT show-off bench gate (only if `SHIP-IMAGE` = `esp32dev_btshowoff`) | Hardware | BT1 | `w17-control-fw/docs/BT1_BENCH_GATE.md` **(being written)**; design doc [`bt_showoff_design.md`](w17-control-fw/docs/bt_showoff_design.md) §9 | Not started; conditional |
| 10 | Code blockers closed | Ground/software | CODE-BLOCKERS-CLOSED | this file §0 + `CURRENT_STATUS.md` | **Open (14 items)** |
| 11 | Ground side assembled + validated | Ground/software | GCS-GROUND, WINDOWS-VM | [`w17-gcs-box-guide.md`](w17-gcs-box-guide.md) §5, `w17-mapper/configs/README.md`, `w17-windows-vm-validation-runbook.md` **(being written)** | Partial (parts inventory only) |
| 12 | ELRS backup handset bind | Hardware (parallel) | ELRS-BACKUP-BIND | [`w17-elrs-backup-handset.md`](w17-elrs-backup-handset.md) §4 | Not started |
| 13 | Giftee-PC install + dry run | Ground/software | GIFTEE-PC-INSTALL | [`w17-giftee-pc-install-guide.md`](w17-giftee-pc-install-guide.md) (this program) | Not started; blocked on stage 10 |
| 14 | iPhone HUD install (sideload) | Ground/software (parallel) | IPHONE-INSTALL | `iPhone_rc/docs/GIFTEE_INSTALL.md` **(being written)** | Not started |
| 15 | Booklet markers resolved | Docs | BOOKLET-RESOLVE | `learning-manual/14_glovebox_owners_booklet.md`, stubs 21/22 | 21 genuine bench-only markers open |
| 16 | Handover | Convergence | HANDOVER | [`w17-handover-checklist.md`](w17-handover-checklist.md) (this program) | Not started; requires all of the above |

---

## 2. Reconciling "flash-never-before-A2-closed" with the two things that already happened

Two facts in the workspace look, at a skim, like exceptions to "no flashing before A2 passes."
Neither is — both are scoped, dated, and already accounted for; this section says so explicitly
so a future session does not treat either as a precedent to repeat casually.

- **`learning-manual/13_bare_board_smoke_test.md` (2026-07-17).** Three bare ESP32 boards were
  flashed and USB-powered with **nothing connected to any pin** — no harness, no servos, no
  battery, attended-only, owner-approved as a one-time, narrowly scoped exception *before the A2
  checklist existed in its current staged form* (`w17-control-fw/CLAUDE.md` "Hardware gates" is
  the standing rule; the chapter itself records the approval and the scope rules that bounded it).
  It proves the boards and the NVS settings path work in isolation. **It is historical evidence,
  not a step in this sequence** — it does not need to happen again, and it does not relax A2 for
  the assembled harness, which is a different object entirely (a bare board on a USB cable has no
  rails, no divider, no actuators to short).
- **A2's own §14 already states the rule this master sequence enforces:** *"What Phase B needs
  (only after A2 is filled, reviewed, and approved)… flashing `esp32dev_tuning` — which is also
  the first moment the USB cable gets used"* (`13_phase_a_a2_no_power_checklist.md` §14). D8's
  Phase 3 ("Flash `esp32dev_tuning`") is therefore not a free-standing step — it is gated behind
  A2-CLOSED (stage 4) and PHASE-B-OPEN (stage 5), both of which are the owner's call, not a
  reviewer's. D8 itself does not restate this gate inline (it reads as a phase list once you're
  already inside Phase B); this document is what makes the dependency explicit across the two
  files.

The practical rule for stage 6: **do not open `D8_BENCH_BRINGUP.md` and start at Phase 0 until
stage 4 (A2-CLOSED) has a recorded Part 2 owner attestation and stage 5 (PHASE-B-OPEN) has a
recorded owner go-ahead in `CURRENT_STATUS.md`.** D8 Phase 0 (pre-power electrical fixes) and
Phase 1 (power-rail smoke, battery connected) are themselves the first two acts of Phase B, not a
warm-up before it — Phase 1 requires the battery, which is powered work.

---

## 3. Stage detail

Each stage: **purpose · who · gate · canonical doc · evidence this stage is done · stop
conditions.**

### Stage 1 — Parts arrival + no-power build start
- **Purpose:** caliper the new boards, confirm the socket-stack clearance precondition, build the
  PDB + harness with nothing energized.
- **Who:** owner (hands-on solder/measure), Claude Code (records, guides).
- **Gate:** none yet open — this stage is the precondition for SF.
- **Canonical doc:** [`w17-parts-arrival-build-prompt.md`](w17-parts-arrival-build-prompt.md).
- **Evidence of done:** `w17-batch1-measurements-for-codex.md` updated with real board
  dims/mass; `CURRENT_STATUS.md` says "harness assembled — ready for A2."
- **Stop conditions:** the step-0 socket-stack caliper (`S0 ≥ 9.82 mm`, the ZK cassette
  clearance — not a gate, a precondition) fails → **stop, report, do not solder**; reopening the
  socketing decision (F12) is a document change before it is a build change.

### Stage 2 — PDB + harness build order
- **Purpose:** the physical order of soldering **is** the A2 gate order — building out of order
  produces false A2 failures (F8's finding).
- **Who:** owner, hands-on.
- **Gate:** SF opens here; every gate token in §5 of the build guide names its A2 gate.
- **Canonical doc:** [`w17-pdb-build-and-connector-guide.md`](w17-pdb-build-and-connector-guide.md)
  §5 — 8 numbered build steps; step 1 is pre-solder planning and measurement and names no gate,
  steps 2–7 each name the A2 gate it closes, and step 8 is struck (see below).
- **Evidence of done:** every step 1–7 (step 8, the IP2326 charger, is struck for A2 build week —
  owner decision F9a) executed with its named gate run and passed before the next step starts.
- **Stop conditions:** any §13 hard stop in the A2 checklist (see stage 3).

### Stage 3 — A2 staged no-power gates
- **Purpose:** the executable safety checklist — continuity, isolation, polarity — run gate by
  gate on isolated subassemblies as they are built, not once at the end.
- **Who:** owner (measures), Claude Code (records, reviews Part 1).
- **Gate:** SF → S1 → S2 → S3 → S4/S4b (S8a executes inside S4) → S5 → S6 → S7 → S8b, in that
  order (`13_phase_a_a2_no_power_checklist.md` gate-order note, revised 2026-08-04).
- **Canonical doc:** [`w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`](w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md).
  Execution prompt: [`w17-a2-execution-session-prompt.md`](w17-a2-execution-session-prompt.md)
  (this program adds the SP3T boot-mode-selector rows — see its own changelog note and §4 of
  this file's cross-links).
- **Evidence of done:** the §11 measurement table filled with real readings, PASS/FAIL, gate, and
  photo # for every row (including the H5/G11/G14/PD1/CP1–CP3/E7 conditional rows, each recorded
  as present *or* explicitly N/A — never blank).
- **Stop conditions:** any of the 9 hard stops in §13 — full stop, no powering, report.
  **Two measurements are OWED before SF's first joint and gate nothing else until closed:** the
  socket-stack caliper (stage 1) and the MH-ET silkscreen adjacent-pin derivation.

### Stage 4 — A2 closure (two-part gate)
- **Purpose:** close A2 as a *record*, explicitly not as a hardware-safety verdict.
- **Who:** Part 1 = Claude Code (completeness, gate attribution, arithmetic, cross-reference,
  mandatory photo inspection); Part 2 = owner (signed attestation the measurements were
  physically performed).
- **Gate token:** A2-CLOSED.
- **Canonical doc:** `13_phase_a_a2_no_power_checklist.md` §12, cross-referencing
  [`11_hardware_validation_plan.md`](w17-control-fw/project-review/11_hardware_validation_plan.md)
  (§A2 there maps A2.1–A2.5 onto the S-gates — the two files describe the same gate from two
  angles: 13 is the runbook, 11 is the risk-register-linked ledger).
- **Evidence of done:** a Part 1 review verdict on file plus a Part 2 owner attestation line, both
  dated, both in `CURRENT_STATUS.md`.
- **Stop conditions:** **A2 closed does NOT mean the hardware is safe** — this is stated verbatim
  in the checklist and repeated here on purpose. Opening Phase B remains a separate, owner-only
  decision (stage 5), informed by but not automatic from A2-CLOSED.

### Stage 5 — Phase B opens
- **Purpose:** the owner's explicit go-ahead to connect power for the first time.
- **Who:** owner only. Not a reviewer's call (13_...§12 Part 2 note, restated).
- **Gate token:** PHASE-B-OPEN.
- **Canonical doc:** [`11_hardware_validation_plan.md`](w17-control-fw/project-review/11_hardware_validation_plan.md)
  §Phase B (B1–B4) is the risk-register-linked ledger of what Phase B must retire; the standalone
  procedural doc `w17-control-fw/docs/PHASE_B_FIRST_POWER.md` is **being written** (readiness
  WS-2, a sibling task to this one) and will be the step-by-step for this stage — **reference it
  by this path; it does not exist on disk as of this writing**, so treat `11_hardware_validation_plan.md`
  §Phase B as the interim source until it lands.
- **Evidence of done:** a dated line in `CURRENT_STATUS.md` recording the owner's go-ahead.
- **Stop conditions:** A2 not closed (stage 4); ESC motor power must stay disconnected through
  this entire stage (`w17-control-fw/CLAUDE.md` "Hardware gates").

### Stage 6 — Bench bring-up, Phases 0–9
- **Purpose:** take the firmware from "builds + passes tests" to "driving on the bench," in the
  D8 runbook's own order, each phase a dependency gate for the next.
- **Who:** owner (hands-on), Claude Code (flashes per instruction, records console output).
- **Gate tokens:** D8-P0 (pre-power fixes) … D8-P5 (failsafe + arm gate PROOF — **the** gate; no
  ESC power before it passes) … D8-P9 (link2 to board #2).
- **Canonical doc:** [`w17-control-fw/docs/D8_BENCH_BRINGUP.md`](w17-control-fw/docs/D8_BENCH_BRINGUP.md)
  Phases 0–9.
- **Evidence of done:** every checkbox in Phases 0–9 checked with an observed result, not assumed;
  Phase 5's five checks all pass **before** Phase 7 (motor power) begins.
- **Stop conditions:** D8's own golden rule: "wheels off the ground, and no ESC power, until the
  failsafe + arm gate are proven live (Phase 5)."

### Stage 7 — Two-board coordinated flash
- **Purpose:** flash ESP32 #1 (control) and ESP32 #2 (soundlight) with link2-v2-compatible
  firmware in a coordinated order, so the two boards never run mismatched protocol versions on
  the wire (D8 Phase 9's B3.3/B3.4 rows are the bench proof; this stage is the *procedure* that
  gets you there safely).
- **Who:** owner, hands-on; Claude Code guides.
- **Gate token:** COORD-FLASH.
- **Canonical doc:** `w17-control-fw/docs/COORDINATED_FLASH.md` **(being written — readiness
  WS-2 sibling task; reference by this path)**. Until it lands, the interim source is D8 Phase 9
  plus `w17-control-fw/docs/link2_protocol.md` (the payload table is the single source of truth
  for what "matching versions" means — `w17-control-fw/CLAUDE.md` "link2" module note: this repo
  owns the protocol, soundlight holds a copy, and `tools/link2_copy_check.sh --strict` is the
  drift guard).
- **Evidence of done:** `Link2Monitor` on board #2 reports `FrameReady` (not `BadVersion` /
  `Invalid`) with a live decoded frame matching sender intent (D8 B3.3/B3.4).
- **Stop conditions:** any `BadVersion`/`Invalid` report — do not proceed to on-car mounting with
  a version mismatch live.

### Stage 8 — On the car + delivery hand-off
- **Purpose:** move from "bench build, tuning firmware" to "mounted on the car, delivery
  firmware, calibration preserved."
- **Who:** owner (mounting, trim), Claude Code (delivery hand-off procedure, ELF spot-check).
- **Gate tokens:** D8-P11 (mounted, re-confirm Phase 5 on the car), D8-P11a (delivery hand-off),
  **SHIP-IMAGE** (owner decision, see below).
- **Canonical doc:** D8 Phase 11 / 11a (`w17-control-fw/docs/D8_BENCH_BRINGUP.md`).
- **OWNER-DECISION(SHIP-IMAGE):** two build environments exist —
  `esp32dev` (plain delivery image: no tuning console, no BT/strap code — the D8 P11a ELF
  spot-check asserts a zero `console::`/`btpad`/`luepad`/`btstack` symbol count) and
  `esp32dev_btshowoff` (adds the SP3T boot-mode-selector reading and the Bluetooth-pad "quick
  show off" mode, gated on its own BT1 bench pass — stage 9). **Which image ships is an owner
  decision recorded in `CURRENT_STATUS.md` at the time D8-P11a runs**, not assumed by this
  document. If plain `esp32dev` ships, stage 9 (BT1) and the SP3T switch wiring are both moot for
  this car — the strap pins are read by no delivery code path (`PinMap.hpp`: "Wired ONLY by the
  `W17_BT_SHOWOFF` prototype envs; delivery/tuning/sim builds never touch these pins").
- **Evidence of done:** D8-P11a steps 1–9 all executed (calibrate → save → ELF spot-check reads
  `0` → re-run Phase 5 safe-state checks on the delivery firmware); the calibrated `get` values
  recorded as the car's bring-up evidence.
- **Stop conditions:** the ELF spot-check (`xtensa-esp32-elf-nm … | grep -c -E
  "console::|btpad|luepad|btstack"`) prints anything but `0` on the delivery ELF — do not ship.

### Stage 9 — BT show-off bench gate (conditional on `SHIP-IMAGE` = `esp32dev_btshowoff`)
- **Purpose:** bench-prove the Bluetooth-pad "quick show off" mode and the SP3T selector before
  any of that code runs on powered hardware.
- **Who:** owner, hands-on; gated on the owner opening it explicitly (`bt_showoff_design.md` §9:
  "No BT code runs on powered hardware before BT1 is opened by the owner").
- **Gate token:** BT1.
- **Canonical doc:** `w17-control-fw/docs/BT1_BENCH_GATE.md` **(being written — readiness WS-2
  sibling task; reference by this path)**. Design source: [`bt_showoff_design.md`](w17-control-fw/docs/bt_showoff_design.md)
  §5/§7 (the bench-only item list) and §9 ("Relationship to gates").
- **Evidence of done:** the §5/§7 bench-only list executed car-on-stand first; the SP3T selector
  continuity rows (added to `w17-a2-execution-session-prompt.md` by this program — cross-link
  §4 below) verified alongside it, since the strap pins are part of the same harness.
- **Stop conditions:** BT1 can begin only when A2 is closed and Phase B rules are in force
  (stages 4–5) — it does not reopen or bypass either.

### Stage 10 — Code blockers closed
See §0 above. This stage has no bench component — it is the software fix wave (readiness WS-1)
landing all 14 ids in §0's table (`MAP-1`, `MAP-2`/`SYN-2`, `MAP-3`, `MAP-4`, `MAP-5`, `MAP-6`,
`MAP-9`, `SYN-1`, `boundaries-1`, `correctness-2`, `correctness-4`, `giftee-ux-2`, `giftee-ux-5`,
`MAP-8`). **Gate token: CODE-BLOCKERS-CLOSED.** Evidence of done: `CURRENT_STATUS.md` records each id merged, with a
green CI run on the ground station (the NSIS installer boundaries-1 fix can only be verified by an
actual CI artifact, per the v2 report's own gaps section — no local `electron-builder` run
substitutes for it).

### Stage 11 — Ground side assembled + validated
- **Purpose:** the GCS box built, wired, and power-budgeted; the mapper's saved profile filled
  in for the real hardware; the whole ground-side software path exercised on a Windows VM before
  it ever meets the giftee's real PC.
- **Who:** owner (box assembly, USB budget bench pass), Claude Code (mapper profile, VM scripts).
- **Gate tokens:** GCS-GROUND (box + driver story), WINDOWS-VM (autonomous validation pass).
- **Canonical docs:** [`w17-gcs-box-guide.md`](w17-gcs-box-guide.md) §5 (driver story — see its
  new pointer to the install guide, cross-link §4), `w17-mapper/configs/README.md` (the profile
  and its two placeholders), `w17-windows-vm-validation-runbook.md` **(being written — readiness
  WS-3 sibling task; reference by this path)**.
- **Evidence of done:** the §4 USB power-budget bench pass recorded (bus-powered vs 12 V hub
  decided per its own three criteria); `REPLACE-WITH-DS4-ID` / `REPLACE-WITH-COM-PORT` filled
  with real values read off the giftee's actual hardware (not the owner's bench — MAP-9 records
  these are per-PC/per-bus values); the WS-3 VM scripts green.
- **Stop conditions:** stage 10 not closed — do not treat a WINDOWS-VM green run against a
  pre-fix build as evidence the giftee-PC install will work.

### Stage 12 — ELRS backup handset bind
- **Purpose:** a zero-PC-dependency control path exists independent of the whole laptop chain
  (vision decision 12).
- **Who:** owner, hands-on, attended, powered session.
- **Gate token:** ELRS-BACKUP-BIND. Runs in parallel with stages 6–9 (it binds to the same RP1
  that the car's bench bring-up uses, so it is natural to do during a bench session, not a
  precondition for one).
- **Canonical doc:** [`w17-elrs-backup-handset.md`](w17-elrs-backup-handset.md) §4 (binding +
  model match) and §2.4 (arm ch5 semantics, corrected by this program to the re-arm invariant —
  see §4 below).
- **Evidence of done:** §4 steps 1–5 executed and recorded (ELRS versions, bind, model match ID
  in `CURRENT_STATUS.md`, channel map verified against §2.2 with drive power absent, failsafe
  drill run).
- **Stop conditions:** every step needing the real RP1 powered is `[bench-TBD]` and stays inside
  an attended, gated bench session (§4 preamble) — this document authorizes zero powered work by
  itself.

### Stage 13 — Giftee-PC install + dry run
- **Purpose:** prove the exact install a non-technical pit crew (or the owner, standing in for
  Lola) would perform on a real Windows machine.
- **Who:** owner (the physical PC), Claude Code (guide).
- **Gate token:** GIFTEE-PC-INSTALL. **Hard-blocked on stage 10** (§0) — do not run this stage
  against a build carrying any of §0's 14 ids: `MAP-1`/`MAP-2`/`SYN-2`/`MAP-3`/`MAP-4`/`MAP-5`/
  `MAP-6`/`MAP-9`/`SYN-1`/`boundaries-1`/`correctness-2`/`correctness-4`/`giftee-ux-2`/
  `giftee-ux-5`/`MAP-8`.
- **Canonical doc:** [`w17-giftee-pc-install-guide.md`](w17-giftee-pc-install-guide.md) (this
  program).
- **Evidence of done:** the guide's own checklist completed end to end on a real (or WS-3 VM)
  Windows machine, with every `[win-TBD]` line resolved to an observed result.
- **Stop conditions:** any step in the install guide that fails and has no documented recovery —
  stop and report rather than improvise past it (same discipline as the A2 golden rule).

### Stage 14 — iPhone HUD install (sideload)
- **Purpose:** get the thin HUD client onto Lola's phone under the owner's 2026-09-02 decision
  (free-account Xcode sideload, 7-day re-sign from the owner's Mac, laptop HUD remains primary).
- **Who:** owner (Mac + Xcode), Claude Code (guide, reminder cadence).
- **Gate token:** IPHONE-INSTALL. Independent of the car and the GCS box — can run any time after
  the app itself is ready.
- **Canonical doc:** `iPhone_rc/docs/GIFTEE_INSTALL.md` **(being written — readiness WS-2 sibling
  task, owned by the iPhone_rc repo; reference by this path)**. Decision source:
  [`2026-09-02_readiness_program.md`](2026-09-02_readiness_program.md) §1 row A2.
- **Evidence of done:** app installed on the giftee's phone; the 7-day re-sign date and the
  reminder mechanism recorded in the handover checklist (stage 16).
- **Stop conditions:** none hardware-gated — this is a pure software/Apple-account workflow. The
  honesty obligation is on the booklet, not on this sequence: the pit-crew burden must be stated
  plainly wherever the giftee experience is described.

### Stage 15 — Booklet markers resolved
- **Purpose:** every `[TBD-at-bench: …]` marker in the printed booklet becomes a plain fact once
  the bench (stages 6–9) and the ground-side dry run (stage 13) produce the real values.
- **Who:** owner (final editorial pass), Claude Code (transcribes bench results into the marker
  slots — **`learning-manual/` is out of this program's edit scope**; this stage is tracked here
  only as a dependency, the actual edits are a `learning-manual` session's job).
- **Gate token:** BOOKLET-RESOLVE.
- **Canonical doc:** `learning-manual/14_glovebox_owners_booklet.md` (21 genuine bench-only
  markers as of the 2026-08-21 adversarial review), stubs
  `learning-manual/21_rebuild_ground_side_install.md` and
  `learning-manual/22_rebuild_first_power_up.md` (both explicitly "written when" the real bench
  evidence exists — see their own "Written when" sections).
- **Evidence of done:** zero `[TBD-at-bench]` markers remain; the booklet's one-press-vs-three-press
  wording (`giftee-ux-3`, see §0) is resolved to whichever route the owner picks.
- **Stop conditions:** the booklet **does not print** with any marker unresolved (its own banner
  says so) or with the `giftee-ux-3` mismatch unresolved (the booklet is printed material — it
  cannot be quietly patched after the fact the way software can).

### Stage 16 — Handover
- **Purpose:** the single day everything above converges into "car in Lola's hands."
- **Canonical doc:** [`w17-handover-checklist.md`](w17-handover-checklist.md) (this program) —
  see that file for the full checklist; it is not duplicated here.
- **Gate token:** HANDOVER. Requires stages 1–15 all closed.

---

## 4. Cross-links

- [`w17-giftee-pc-install-guide.md`](w17-giftee-pc-install-guide.md) — stage 13 in full.
- [`w17-handover-checklist.md`](w17-handover-checklist.md) — stage 16 in full.
- [`w17-elrs-backup-handset.md`](w17-elrs-backup-handset.md) — stage 12; §2.4 corrected this pass
  to the 2026-08-20 re-arm invariant (was describing pre-invariant behavior).
- [`w17-gcs-box-guide.md`](w17-gcs-box-guide.md) §5 — now points at the giftee-PC install guide
  (this pass) instead of standing alone.
- [`w17-a2-execution-session-prompt.md`](w17-a2-execution-session-prompt.md) — SP3T boot-mode
  selector rows added to the gate table this pass (stage 9's harness prerequisite).
- `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`,
  `11_hardware_validation_plan.md` — stages 3–5 (read-only, nested repo, canonical).
- `w17-control-fw/docs/D8_BENCH_BRINGUP.md`, `bt_showoff_design.md` — stages 6–9 (read-only,
  nested repo, canonical).
- `w17-mapper/configs/README.md` — stage 11 (read-only, nested repo, canonical).
- `2026-09-02_readiness_program.md` — the program this document executes under; §1 row A2 is
  stage 14's decision source.
- `CURRENT_STATUS.md` — the only place gate *state* (closed/open/attested) is recorded; this file
  never carries a commit hash or a pass/fail verdict of its own.

**Docs referenced above that do not exist on disk at this writing** (each a sibling readiness-WS-2
or WS-3 task, named here so this sequence does not silently orphan them once they land):
`w17-control-fw/docs/PHASE_B_FIRST_POWER.md`, `w17-control-fw/docs/COORDINATED_FLASH.md`,
`w17-control-fw/docs/BT1_BENCH_GATE.md`, `w17-windows-vm-validation-runbook.md`,
`iPhone_rc/docs/GIFTEE_INSTALL.md`. When each lands, update its row in §1's status column and the
"interim source" note in its stage above — no other edit should be needed.
