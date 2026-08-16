# W17 Final Product Vision

**Canonical product definition** — what the finished W17 *is*, as aligned with the owner in the
2026-08-16 vision Q&A (18 questions, all answered; decision numbers below match that Q&A).
This file carries **no status** (that lives in `CURRENT_STATUS.md`) and **no process rules**
(`CLAUDE.md`); it changes only when the owner changes the vision. Feature work should be scoped
against this file.

## The product in one paragraph

A 1/10-scale, 3D-printed **Mercedes W17 Formula 1 showcar driven in first person**. It drives
gently — indoors and on smooth pavement — and looks, sounds and feels like the real thing: a
cockpit FPV camera on a head-trackable pan/tilt gimbal, a procedurally synthesized engine note
with gear shifts and overrun crackle (V10 by default, selectable profiles desired), working F1
lighting, a functional actuated **DRS**, a race-engineer ground station on the laptop, and an
iPhone that doubles as a wearable HUD. It is a **showpiece first and an RC car second**: build
quality, FPV immersion and cosmetic fidelity outrank speed and race performance. All
electronics live inside the unmodified shell; the pack charges in place through a hidden USB-C
flap without opening the car. The finished car is a **gift for a non-hobbyist operator** — owner's bar, verbatim:
"user friendly af" — and the project goes public (write-up / repos where licensing allows)
only after finalization and gifting.

## Definition of done — v1.0 (answer 1: "C, ideally D")

v1.0 is ALL of:

1. Gentle FPV driving, indoor + smooth outdoor; speed **tunable with gentle defaults**, no
   fixed numeric target (answers 3, 4).
2. Showpiece finish: shell preserved, all electronics inside, lift-out cassette packaging.
3. Sound + light fully running (decisions 15–16).
4. **Onboard USB-C charging**: hidden flap/port, hard charge/run interlock, charge-state light
   (answer 13).
5. **Functional actuated DRS** — owner: "A strongly" (answer 14).
6. Ground-station HUD on the laptop **and** the iPhone HUD usable, chosen per session
   (answer 6).
7. **Active head-tracked gimbal** — the gated FIRST_ACTIVE safety milestone passed, stick
   pan/tilt retained as fallback (answers 1, 9).
8. **Giftee-operable** (confirmed 2026-08-16): a non-hobbyist can charge, start, drive, show
   off and park the car with the glovebox quick-start booklet alone — no hobbyist knowledge,
   no mapper UI, no debugging. Owner's bar: "user friendly af."

"Ideally" also inside v1.0: the **manual complete enough that a stranger could rebuild the
car** (answers 1 "D" and 17). The short glovebox booklet is *not* part of the "ideally" — it
is required by item 8.

Explicitly **post-v1.0**: session recording/replay (answer 8); public write-up (answer 18).

Sequencing note: item 7 structurally comes last — the FIRST_ACTIVE blockers are
hardware-evidence class, so the expected path is build → A2/Phase B → stick-gimbal FPV
driving → head-tracking activation review. An interim driveable stick-gimbal car is a planned
state, not scope creep.

## Decisions (numbered as in the 2026-08-16 Q&A)

| # | Topic | Decision |
|---|---|---|
| 1 | Done bar | v1.0 = full list above incl. head tracking + DRS; stranger-rebuildable manual "ideally" in |
| 2 | Showcase mode | **Core**: stationary demo — lights + engine sound + live camera, drive disarmed ("if we're close — why not") |
| 3 | Venue | Both indoor and smooth outdoor |
| 4 | Speed | Tunable, gentle defaults, no fixed target |
| 5 | Driver figure vs cockpit cam | Decide on first cockpit test footage; leaning camera-wins |
| 6 | FPV screen | Both laptop HUD and iPhone (incl. headset use), per session |
| 7 | Video | Two **configurable** profiles: low-latency drive / high-quality showpiece |
| 8 | Recording/replay | Post-v1.0 |
| 9 | Head tracking | In the final product once the gated milestone passes (reality check below) |
| 10 | Driving input | DualShock for v1.0; sim-wheel driving as a later showpiece option (likely already mappable — see backlog) |
| 11 | Gimbal on link loss (driving) | **Decay to center** — vision-level; the formal re-review owed on unlock-plan decision #3/U8 still happens at implementation |
| 12 | No-laptop options | Keep a plain ELRS handset bound to the RP1 as backup (laptop-required main chain accepted). New gated idea: Bluetooth show-off mode (backlog) |
| 13 | Charging UX | Hidden flap + hard charge/run interlock + charge-state light |
| 14 | DRS | Functional in v1.0, strong requirement; flap mechanics are Codex territory (cross-repo dependency) |
| 15 | Engine voice | V10 default; selectable profiles (V6-turbo-hybrid) desired if feasible |
| 16 | Lights | Current set stands; **add** ignition-on animation + DRS-open tell. (Indicators are already steering-driven by design — see reality check) |
| 17 | Manual | Publishable, stranger-could-rebuild **and** full teaching depth |
| 18 | Publicness | Public after finalization **and gifting**; GPL-forced parts (mapper) already public |

Owner scope statement (answers 14, 17): **maximum thoroughness** — depth is not to be traded
away for effort economy on this project.

## Operator model (confirmed 2026-08-16)

The car is a gift; **the operator is not the owner and not a hobbyist**. "User friendly af"
is therefore a product requirement with teeth. Derived implications (Claude's derivation from
the requirement — individually challengeable, not owner-ratified item by item):

- **One-action race day**: hotspot + mapper (saved profile) + ground station + iPhone bridge
  come up together; the mapper's node-graph UI is a build-time tool the giftee never sees.
  The GS GARAGE fast-path / start-lights flow is the pattern to extend.
- **Plain-language failures**: every giftee-reachable failure state gets an honest,
  non-technical screen (the GS already trends this way — honest hotspot readiness, auth-error
  UX, the required degraded-video state).
- **Unmissable low battery**: lights pulse + HUD banner (+ consider an audio cue). The
  warn-never-auto-cut safety invariant stands, so UX carries the entire burden.
- **Car-like power ritual**: the XT90 loop key is the labeled "ignition key"; USB-C charging
  with an idiot-legible state light (charging / done / fault).
- **Guided arming**: deliberate but prompted on the HUD (start-lights sequence), never hidden
  button lore.
- **Glovebox booklet**: a short printed owner's quick-start (charge, start, light legend,
  "what it does when it fails safe") ships with the car — separate from the big teaching
  manual; required by done-bar item 8.
- **Showcase mode reachable without expertise**; a no-laptop variant needs design care so
  failsafe indication stays unambiguous (see backlog).

**Gift kit (decided 2026-08-16):** the giftee runs the laptop side on **their own Windows
PC** via an installer + guide, and all ground-side hardware ships in a **3D-printed one-cable
GCS box**: ELRS TX, the hotspot Wi-Fi adapter and a USB hub in one enclosure, a single USB
cable to the PC, with an optional 12 V adapter if the USB power budget falls short. Box
mechanics/print = Codex territory; contents, wiring and BOM = Claude side — the same split as
the car's cassette.

"User friendly" never means removing the arm gate, the failsafe, or the warning-only battery
invariant — friendliness is delivered by UX, never by relaxing safety.

## Reality checks recorded at lock time (2026-08-16)

- **Head tracking (9):** the log-only pipeline is implemented and live-validated end to end
  (iPhone → mapper ingest → gRPC diagnostics → GS display). The **active** layer — U4
  shaping/arbitration — is deliberately design-only: full spec + test matrix + R1–R16 review
  checklist exist, **no arbiter code**, FIRST_ACTIVE = NO-GO with hardware-evidence blockers.
  (`w17-control-fw/project-review/head_tracking_unlock_plan.md`.)
  **Owner amendment 2026-08-16: branch-only implementation approved** — the U4 arbiter and
  its Groups A/B/C test matrix may be written on a `w17-mapper` feature branch with both
  FIRST_ACTIVE flags default-off and every shaping constant fail-closed (no invented
  calibration values); the branch is **never merged or pushed** before R1–R16 pass. This
  supersedes the blanket "no arbiter code committed" wording of 2026-07-15; propagating the
  amendment into the unlock plan's own text is owed when `w17-control-fw` is next touched.
  Activation semantics unchanged: two flags + R-review + bench evidence.
- **Wheel (10):** the mapper reads devices through SDL's joystick API
  (`w17-mapper/pkg/devices/util.go:27` `JoystickOpen`; `controller.go` `JoystickEventState`),
  the level at which sim wheels enumerate; wheel/pedal axes should therefore map to CRSF channels like
  any stick. Owed: one bench check with the real wheel. (GS-side wheel support is display/HUD
  mirroring only — the GS never drives.)
- **Indicators (16):** already steering-fed by design — `link2` byte 2 `steeringPercent`,
  "Left/right for turn indicators. Live even while disarmed"
  (`w17-control-fw/docs/link2_protocol.md`). Ignition animation + DRS tell are board-2-local
  additions (enginesim ignition state and the DRS bit already exist).

## Backlog seeded by this pass (recorded, not scheduled; no gate touched)

- **BT show-off mode** (12; scope clarified + commissioned 2026-08-16): DualShock paired
  directly to ESP32 #1 Bluetooth so the car drives like a **basic RC car at close range with
  no PC available** — the "look what I have here" scenario. Owner approved **design + a
  default-off, compile-flagged branch prototype in one pass** (design doc first, prototype on
  a feature branch, native tests only; nothing merged and nothing bench-run before the owner
  reads the design). Non-negotiables carried into the design: BT-loss failsafe identical in
  effect to CRSF failsafe, boot-time hard mutual exclusion with CRSF (never runtime-switched),
  the arm gate and ESC boot sequence unchanged, a gentler demo throttle envelope, RAM/latency
  budget proven at the bench later. It dilutes "Windows is the control authority" the same way
  the approved ELRS backup handset does — acceptable per owner, gated per process.
- **Wheel-driving bench check** (10): enumerate the wheel in the mapper, map axes/pedals,
  drive the bench rig; expected zero code.
- **Sound profile selector** (15): synth already parameterized (firings/rev, partial stack,
  ERS whine); selection mechanism TBD — board-2 NVS vs link2 vs build flag.
- **Ignition-on animation + DRS-open tell** (16): board-2 lights compositor.
- **Showcase mode** (2): small demo-state feature (board-1 disarmed demo feed or board-2
  local trigger); `esp32dev_sim` already proves the sound/light half. A no-laptop variant
  must keep failsafe indication unambiguous (hazard semantics) — design care owed.
- **One-action race-day startup** (operator model): orchestrated bring-up of hotspot +
  mapper with saved profile + GS + bridge; the giftee never opens the mapper UI. Targets the
  giftee's own Windows PC (gift-kit decision) — needs a real installer (the electron-builder
  target already runs in CI), a packaged mapper binary + saved profile, and driver notes for
  the GCS-box adapters.
- **GCS box** (gift kit): 3D-printed enclosure for the laptop-side hardware — ELRS TX,
  hotspot Wi-Fi adapter, USB hub — one USB cable to the PC, optional 12 V input. Bench
  measurement owed: TX at output power + AP-mode adapter draw vs one USB port's budget
  (decides whether the hub must be powered). Print/mechanics with Codex; contents/wiring/BOM
  on the Claude side.
- **Glovebox owner's booklet** (operator model; v1.0 via done-bar item 8): short printed
  quick-start — charge, start, light legend, failsafe behavior — derived from the manual but
  its own artifact.
- **Unmissable low-battery UX** (operator model): lights already pulse; add a HUD banner and
  consider an audio cue; auto-cut stays banned (safety invariant).
- **ELRS backup handset** (12): procure, bind to RP1, document in the manual.
- **Video profiles** (7): drive/showpiece presets in the camera → mediamtx → GS chain (CB5
  territory).
- **Charge flap + state light** (13): shell/flap placement is Codex territory; the PDB guide
  already carries the interlock.
- **DRS mechanism** (14): firmware channel exists; actuated-flap mechanics with Codex.

## What this vision does NOT change

Safety boundaries 1–7 (`CLAUDE.md`) are untouched. Head-tracking activation stays behind the
FIRST_ACTIVE two-part flag and the R1–R16 review; W3 stays log-only until that milestone;
firmware stays iPhone-unaware forever; the ground station stays viewer-only; the A2 / Phase B
gates govern all hardware work.

## Open points

- **5** — driver figure: revisit at first cockpit footage.
- **GCS box power budget** (gift kit): powered hub (12 V) or bus-powered — measure on the
  bench (see backlog).
- Mechanisms TBD when scheduled: sound-profile selection, showcase-mode trigger, BT show-off
  design.
