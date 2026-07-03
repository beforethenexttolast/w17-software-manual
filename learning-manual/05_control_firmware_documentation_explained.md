# 05 — The Control Firmware's Documentation, Explained In Depth

`w17-control-fw/docs/` (plus two root-level files, `diagram.json` and `wokwi.toml`) is
the documentation home for the whole project. This chapter walks each document in
detail: what it's for, every important design decision recorded in it, the hardware and
software concepts it relies on, and exactly where it connects to source code.

Conventions as always: **[C]** confirmed (cited), **[I]** inferred (evidence given),
**[A]** assumption (verify). Cross-references point to other manual chapters so concepts
are explained once and reused.

Reading order for this chapter: it mirrors the list below. Each section stands alone.

| § | Document | One-line role |
|---|---|---|
| 1 | `docs/ROADMAP.md` | Decision journal: review findings A1–A13 + build log |
| 2 | `docs/00_BUILD_SHEET.md` | One-page operational build plan + the 7 bench fixes |
| 3 | `docs/bill_of_materials_v2.md` | Verified buy-list + why-v2 changelog |
| 4 | `docs/D8_BENCH_BRINGUP.md` | The 11-phase hardware bring-up runbook |
| 5 | `docs/link2_protocol.md` | Normative board#1→#2 protocol spec |
| 6 | `docs/SIMULATION.md` | Wokwi virtual-car runbook (validation Stage 2) |
| 7 | `docs/print_spec_v2.md` | 3D-printing spec: materials, settings, part selection |
| 8 | `docs/w17_wiring_assembly_atlas.html` | Visual wiring + assembly atlas |
| 9 | `diagram.json` + `wokwi.toml` (repo root) | The Wokwi virtual circuit + sim config |
| 10 | `CLAUDE.md` (root) and `docs/f1_hud.html` | The founding brief; the HUD design mockup |

---

## 1. `docs/ROADMAP.md` — the decision journal

### 1.1 What it is for

**[C]** Two documents fused: **Part A** records the verdict of an *adversarial review*
of the first deliverable (13 findings, A1–A13, each with file/line, severity, verdict,
and action), and **Part B** is the build log — every work package from D1.5 to D8 plus
Phase-2 (B2, items 1–6) and Phase-3 (B3, items 7–8), each entry recording what was
built, which design decisions changed mid-flight and why, and the test count after.
It closes with the deferable list, a 19-day calendar sketch, and a risk register.

*Adversarial review* is the software practice of having a reviewer actively try to
prove the code wrong — hunting for the inputs and timings under which it misbehaves —
rather than confirming it looks right. Part A is the written output of such a review;
its honesty is notable: it even records which reviewers *didn't finish* ("the
build-config reviewer and part of the test-gaps reviewer did not complete"), so the
reader knows which areas got one pass instead of two. **[C]** Part A coverage note.

**Why this document matters most:** code shows *what*; this file is the only place that
systematically records *why* — and, crucially, *what almost went wrong*. When any code
in the repo looks overbuilt, the explanation is usually a finding here.

### 1.2 Part A — the findings, each explained

**A1 [CRITICAL] — failsafe Active at boot with zero frames received.**
The single most instructive item in the repo. The mechanism, step by step **[C]**:

1. The state machine judged "link valid" purely as `nowMs − lastFrameMs < 500`.
2. `lastFrameMs` is a variable, and variables start at 0 — so at boot, with `nowMs`
   also small, the link *looked* fresh for the first 500 ms even though **no radio
   frame had ever arrived**.
3. The re-arm window therefore opened on the first loop pass; at ~t=155 ms the machine
   declared Active.
4. `main.cpp` then read the *zero-initialized channel array* (16 channels, all raw
   value 0). Normalization maps raw 172→−1000 and 992→0; raw 0 is far below the
   minimum and computes to −1211, clamped to −1000 — i.e. **full left**.
5. The steering servo was commanded 500 µs — hard full lock, stalling a 35 kg·cm servo
   against a 3D-printed steering rack — until real logic took over at t=500 ms.
6. The ESC received full-brake/reverse in the same window and was saved *only* because
   the unrelated 2-second boot hold happened to cover it — "an unrelated tunable, not a
   designed guard."
7. Worst of all: a unit test (`test_climbs_to_active_after_full_rearm_window_from_boot`)
   had **codified the buggy behavior** — the test suite was green while the car would
   have slammed its steering on every power-up.

The fix **[C]** (D1.5, now visible in `lib/failsafe/FailsafeStateMachine.hpp`): frame
arrival became an explicit input (`frameArrivedThisTick`) and an `everReceivedFrame_`
latch makes the link *unconditionally invalid until the first real frame ever* —
"timestamps alone can never make the link look healthy." New regression test: no frame
ever fed ⇒ Safe at every timestamp.

Lessons a beginner should extract: (a) **absence of evidence must never satisfy a
safety check**; (b) default-initialized values (0) are data too, and code will happily
act on them; (c) tests encode their author's assumptions — a wrong assumption produces
a green test for wrong behavior, so *review the tests as hard as the code*; (d) safety
must never depend on an unrelated parameter accidentally covering the gap.

**A2 [MAJOR] — no arm gate on the live throttle pass-through.** The placeholder main
loop drove the ESC from raw channel 3; a transmitter powered on with throttle held high
would go straight to the motor once the ESC's 2 s hold expired. Fix strategy is worth
noting: a **minimal neutral-latch stopgap** landed immediately in `main.cpp` (throttle
forced 0 until the decoded channel is seen near center 992 once), with the full
arm-*switch* gate following in the channels module (D2). Staged safety: never leave the
gap open while the proper mechanism is being built. **[C]**

**A3 — re-arm snaps throttle to current stick position.** After link recovery, throttle
resumed wherever the stick happened to be. Fix: the fresh-neutral rule — after *any*
failsafe episode the `ArmGate` requires the stick to return to neutral before power
flows again (chapter 10 §2). **[C]**

**A4 — `Esp32LedcPwm::begin()` left the PWM duty at 0.** Until the first explicit
command, the pin output no pulses at all; whether that's "safe" depended on caller
ordering. Fix: `begin(initialPulseMicros)` — attaching a channel *immediately* commands
its safe position (servo center / ESC neutral / DRS closed). Concept: **initialization
ordering hazards** — never let "safe" depend on who calls what first. **[C]**

**A5 — ESC boot hold timed from static initialization.** C++ constructs global objects
("static initialization") *before* `setup()` runs; the 2 s ESC hold was being measured
from that moment, not from when PWM pulses actually start. The gap is milliseconds in
practice ("real but small") but the fix — anchor the hold to the first `setThrottle()`
call — makes the guarantee structural rather than coincidental. **[C]**

**A6 — a documented API contract violated.** `main.cpp` read `lastFrame()` every tick,
though the function was documented "valid only immediately after FrameReady." Currently
harmless, fixed by copying channels out on the FrameReady event. Lesson: honor
documented contracts *before* they bite; "works today" is not compliance. **[C]**

**A7 — interleaved telemetry frames reported as corruption.** ELRS receivers interleave
LINK_STATISTICS (0x14) frames with RC frames; the deliverable-1 assembler only knew
0x16 and flagged everything else `FrameInvalid`. Fix (D4): the assembler was
generalized to *framing + CRC only* — any CRC-valid type is a frame; per-type payload
validation moved up to the facade. Concept: **separate the framing layer from the
interpretation layer**. **[C]**

**A8 — a receiver configured with "Set Position" failsafe defeats the timeout.** ELRS
receivers have configurable failsafe behaviors: with "No Pulses" they go silent on link
loss (our timeout catches that); with "Set Position" they **keep emitting RC frames**
holding preset values — the firmware would see a perfectly fresh stream and never
trip. Mitigations: an operational rule (bench checklist: RP1 MUST be "No Pulses") *and*
a code defense (D4's latched LQ=0 flag, below). Lesson: **the failure mode of a
component's configuration is part of your system's attack surface**. **[C]**

**A9 — assembler discards buffered bytes on CRC failure.** If a sync byte 0xC8 occurs
*inside* a corrupted frame, it won't be rescanned; cost analysis showed ≤1 extra lost
frame per corruption at 50–250 Hz frame rates → **accepted** as a known limitation.
Lesson: not every finding needs a fix; quantify the cost, decide, and write the
decision down. **[C]**

**A10 — `millis()` wraps at 49.7 days.** True, irrelevant for an RC car; accepted with
a comment. **A11 — trim past an endpoint silently inverts steering** (needs absurd
config; later closed by validation in `ServoConfig::valid()`, per B2.6). **A12 — loop
free-runs instead of fixed cadence** (spec said ≥50 Hz *fixed*; fixed-tick scheduler
landed with D6). **A13 — the crsf module didn't expose `linkUp`/`lastFrameMicros`** as
CLAUDE.md §2.1 specified (an undocumented deviation; the `CrsfReceiver` facade in D4
closed it). **[C]**

### 1.3 Part B — the build log, decision by decision

Each entry below names the decisions a learner should understand (all **[C]** from the
respective ROADMAP entries):

- **D1.5 (safety fixes):** everything from A1/A2/A4/A5/A6 above; 29 native tests.
- **D2 (`channels` + full arm gate):** the channel map as a *config table* (defaults
  ch1 steering … ch13 drive mode — explicitly placeholders until the bench);
  "piecewise-exact ±1000 normalization" (the two half-ranges 172–992 and 992–1811 have
  different widths, so each is scaled separately — otherwise center wouldn't map to
  exactly 0); switch **hysteresis** at +250/−250; **first-decode level seeding** — the
  first frame *sets* switch levels without generating OFF→ON edges, so boot can't
  produce phantom gear shifts; instant disarm on switch-off or failsafe.
- **D3 (`gearbox`):** expo-then-**scale** (not clip) so full stick travel maps onto
  each gear's whole range; brake/reverse passes through unshaped; gear survives
  failsafe/disarm. Plus a design-review catch worth memorizing: shift edges are
  consumed **inside the frame-arrived block** — a bare check in the loop body would
  re-fire one button press on every tick (~50×/s).
- **D4 (LinkStatistics + facade):** decode 0x14; the assembler generalization (A7);
  and the **latched RX-failsafe flag**: uplink-LQ==0 sets it, and *only* a stats frame
  with LQ>0 clears it — never RC frames, never the passage of time — so hold-position
  RC frames during an outage can't re-arm the car (the A8 code defense). The facade
  reports `linkUp()` for observability but "the FSM stays the actuation authority" —
  reporting and actuation deliberately separated.
- **D5 (`telemetry`):** two subtle **seam-placement** decisions. (1) The voltage seam
  is `IVoltageSensor` returning *calibrated pin-millivolts*, not a raw-ADC-counts
  interface: the ESP32's ADC nonlinearity is handled *below* the seam by the chip's
  factory calibration (`analogReadMilliVolts`), while the board-specific divider math
  stays *above* it in pure code. Rule of thumb: put chip quirks below the seam, board
  design above it. (2) The wheel seam reports ISR-timestamped **pulse periods**, not
  just counts — counting per 20 ms tick at ≤55 Hz pulse rates would quantize speed and
  "flap 2:1 at top speed." Also: EMA seeded from the first sample (no boot
  false-warning), warn 3 s-sustained <7.0 V / clear >7.4 V, EMI clamp 5000 rpm,
  graceful decay + 1.5 s hard zero, ISR with 2 ms lockout (~9× margin).
- **D6 (`link2`):** the wire format decisions (see §5); CRC code **deliberately
  duplicated** into the lib (so board #2 can lift the folder wholesale; a test
  cross-checks it against the crsf CRC); UART1 TX-only with **mandatory pin remap**
  (ESP32 UART1's default pins overlap the flash chip's — using them crashes the
  firmware; remapping to GPIO25 avoids it); main.cpp restructured to fixed cadences
  (closing A12); and another review catch: **no early-return in the Safe branch** —
  link2 keeps transmitting during failsafe, because board #2 needs to *know*.
- **D7 (Wokwi):** see §6/§9.
- **D8:** consolidated into the runbook, §4.
- **B2.1 (CI):** GitHub Actions runs the native tests + both ESP32 builds on every
  push — the guarantee that "compiles for the chip" and "logic still correct" are
  checked together.
- **B2.2 (ERS + drive modes):** the energy model (chapter 10 §4) — and a spec change
  argued in the open: the originally-planned raw **"Direct" mode was dropped** because
  gearbox top gear already *is* full power under scale-not-clip; Direct would only have
  removed the shifts between a bumped switch and full throttle. Training mode (fixed
  400 cap + expo, shifts inert) replaced it. Also: link2 v1 was **amended without a
  version bump** (payload 10→11 bytes, +ersPercent +driveMode, flags bit6) — legitimate
  *only* because board #2's firmware didn't exist yet; once a receiver ships, format
  changes require a version bump.
- **B2.3 (board #2)** and **B2.4 (ground station):** the sibling repos (chapters 07,
  08). B2.4 records two review course-corrections: the telemetry serial-port conflict
  (the FT232 is held exclusively by elrs-joystick-control — flagged at review time,
  finally resolved in B2.5 via com0com/forwarding rather than WiFi) and the
  H.265→WebRTC codec check being the #1 bench risk.
- **B2.5 (telemetry uplink):** why the ELRS backchannel won: the ESP32-WROOM radio is
  2.4 GHz-only while the video AP is 5.8 GHz (so ESP-NOW/WiFi to the laptop would need
  new hardware or crowd the control band), the two-way ELRS link already exists, and
  ELRS relays *standard sensor frames* — hence battery 0x08 out GPIO17 at ~5 Hz
  (voltage real, percent a coarse 2S estimate), LQ needing **no firmware at all** (the
  ground TX module reports LINK_STATISTICS natively).
- **B2.6 (tuning console + NVS):** the **never-brick guard chain** (length → CRC →
  version → `valid()` → apply; *any* failure ⇒ compiled defaults); `set` gated on
  DISARMED and re-validated per-field; `set` is RAM-only, only `save` writes flash;
  the whole console **compiled out of the gift firmware** (`-DW17_TUNING_CONSOLE`
  opt-in) so the delivered car has no serial command surface.
- **B3.7 (gimbal):** deliberately **not safety-gated** — "aiming a camera is harmless
  armed or disarmed" — and it *holds last position* on failsafe (the decoded `controls`
  freeze). A good example of scaling the safety machinery to the actual hazard.
- **B3.8 (real speed/gear/mode/ERS to the HUD):** why *send* gear/ERS rather than let
  the HUD mirror the same gamepad inputs: two independent computations drift (a dropped
  shift edge desyncs them forever; the HUD model even used a different gear count).
  Wheel speed rides the GPS frame's groundspeed field (km/h·10 = mm/s·36/1000); gear/
  mode/ERS ride a FLIGHTMODE status string `"G3 M2 E55"`; the ground source **merges**
  frame types into one snapshot so a battery frame can't blank speed.

The closing sections: the *deferable list* (code-signing, BX100 buzzer, gear-curve
tuning — "ship conservative defaults") is explicitly the schedule's pressure valve; the
calendar's governing rule is "firmware must NOT be the long pole"; risks include
budgeting one bench session *purely* for ESC characterization.

### 1.4 Connections to source code

| ROADMAP item | Code it shaped |
|---|---|
| A1 | `lib/failsafe/FailsafeStateMachine.{hpp,cpp}` (`everReceivedFrame_`), regression tests in `test/test_failsafe/` |
| A2/A3 | `lib/channels/ArmGate.{hpp,cpp}` + `main.cpp` neutral-latch history |
| A4/A5 | `lib/outputs_hal_esp32/Esp32LedcPwm` (`begin(initialPulseMicros)`), `lib/outputs/EscOutput` (arm-hold anchor) |
| A7/A8/A13 | `lib/crsf/CrsfFrameAssembler` (framing-only), `CrsfReceiver` (facade + latched LQ flag) |
| A11 | `ServoConfig::valid()` in `lib/outputs/ServoOutput.hpp` |
| A12/D6 | `src/main.cpp` fixed cadences |
| D2 | `lib/channels/ChannelDecoder.{hpp,cpp}` |
| D3 | `lib/gearbox/Gearbox.{hpp,cpp}` |
| D5 | `lib/telemetry/*`, `lib/hal/IVoltageSensor.hpp`, `IWheelPulseSensor.hpp`, `lib/telemetry_hal_esp32/*` |
| D6 | `lib/link2/*`, `lib/link2_hal_esp32/Esp32Link2Uart` |
| B2.2 | `lib/ers/ErsSystem.{hpp,cpp}`; link2 payload v1 amendment in `lib/link2/Link2Frame.hpp` |
| B2.5/B3.8 | `lib/crsf/CrsfFrameBuilder.hpp` (battery/GPS/flightmode builders), `Esp32CrsfUart::write` |
| B2.6 | `lib/settings/*`, `lib/console/*`, `lib/settings_hal_esp32/*` |

### 1.5 Confirmed vs inferred (this section)

Everything above is **[C]** from ROADMAP.md itself, cross-checked against the headers
read (failsafe, gearbox, ers, ArmGate, CrsfFrame, Link2Frame). **[I]**: the −1211
arithmetic explanation (§1.2 A1 step 4) reconstructs the documented number from the
documented mapping; the "lessons" paragraphs are my distillations.

---

## 2. `docs/00_BUILD_SHEET.md` — the one-page build plan

### 2.1 What it is for

**[C]** A deliberately compressed single page that a builder can work from during build
week: the locked configuration, the print plan (order/filament/settings), the measured
packing layout, the seven pre-power bench fixes, a pre-build checklist, and the paint
sequence. It cross-references "runbooks 02–06" for detail — **[I]** those numbered
runbooks are not in the repo (see open_questions); the build sheet plus BOM/print-spec
appear to be their surviving distillation.

### 2.2 Design decisions recorded

- **The locked config line:** RC-01 chassis · oil-shock suspension (original floor +
  arms) · 2024 body with W17 livery · belt drive, sensored 17.5T · F104 rubber tyres on
  printed rims · 2× ESP32 · OpenIPC FPV + ELRS. This is the "no more re-deciding"
  declaration that lets every other doc assume a fixed target. **[C]**
- **Print order strategy:** (1) a *fit test first* — one tyre-slot + one hub, printed
  at full strength, to **measure the 8×12×3.5 mm bearing seat and the F104 tyre fit
  before committing to the rest** (3D printers vary; a seat 0.1 mm tight ruins every
  wheel); (2) structural chassis parts print *while parts ship* (schedule overlap);
  (3) the body starts early because **paint is the long pole** — cure times dominate;
  (4) functional bits (DRS arm) last. **[C]**
- **Packing layout (measured):** battery forward in the ~84×60 mm central floor tub
  (mass balance; explains the ≤75 mm battery envelope), **two ESP32s stacked** in the
  ~50×40 mm rear engine-cover cavity, BEC/amp/RP1 in the sidepod pockets, camera in the
  nose pod, speaker in a sidepod. Wiring rails: A (clean) and B (servo) with all
  grounds common — the physical mirror of the electrical design (chapter 03 §3). **[C]**
- **The hybrid-rear option** is conditional on a slicer check (does the revised rocker
  seat the 68 mm coilover?) — a decision deferred to evidence, mirrored in
  print_spec_v2 (§7.3). **[C]**
- **Finish sequence:** prime (grey; **white** under silver/turquoise — light colors need
  a bright base) → cured paint → **gloss clear → decals → final clear**. Gloss before
  decals prevents *silvering* — trapped micro-air under a decal on a matte surface reads
  as silvery haze. The final clear seals decals and sets sheen. **[C]** (mechanism [I],
  standard modeling practice.)

### 2.3 The seven bench fixes — each explained

**[C]** list; explanations expand chapter 03:

1. **ESC throttle RED wire isolated** — the ESC's built-in ~6 V BEC would back-feed the
   servo rail/ESP32 and "6 V BEC back-feed = ESC damage." Signal + GND only.
2. **Divider 27k/10k, not 20k/10k** — with 20k/10k the ratio is 10/30 ≈ 0.333, so a
   full 8.4 V pack puts ~2.80 V on the pin — beyond the ~2.5 V linear ceiling of the
   ADC at 11 dB attenuation, so *the entire top half of the 2S voltage range reads the
   same clipped value*. 27k/10k gives ratio 10/37 ≈ 0.270 → 8.4 V ≈ 2.27 V, safely
   linear. This is why "v2" of the BOM exists (§3).
3. **A3144 VCC = 5 V, output pulled to 3.3 V** — the open-collector trick, chapter 03 §5.
4. **WS2812 supply diode (1N5819) or 74AHCT125 shifter** — brings the strip's logic
   threshold (~0.7 × supply) down to ~3.0 V so 3.3 V data reads reliably (chapter 03 §8).
5. **1000 µF on the servo rail** — the DS3235SG's stall-current spikes (chapter 03 §3).
6. **ELRS: same major.minor firmware + same bind phrase** on RP1, ES24TX Pro, *and* the
   TX16S backup module — ELRS only binds across matching minor versions; the shared
   phrase is what makes the TX16S a drop-in backup transmitter.
7. **ESC in sensored mode, sensor cable plugged** — the smooth-low-speed reason the
   10BL120 was chosen at all.

### 2.4 Connections to source code

The divider values (fix 2) become the `BatteryMonitor` config's divider constants and
the sim's expected `batt≈8400mV`; fix 6 becomes D8 Phase 2 checklist items; the ESC
mode (fix 7) is *assumed* by `Gearbox`'s brake-pass-through design
(`Gearbox.hpp` note) and checked at D8 Phase 7; the packing layout constrains nothing
in code but explains the battery envelope in the BOM. **[C/I]** as marked.

---

## 3. `docs/bill_of_materials_v2.md` — the buy-list and its reasoning

### 3.1 What it is for

**[C]** The consolidated, verified purchasing list: an AliExpress order (~17,400 ₴
≈ $425), an rcMart tyre order (~$28), work-printed parts (free), locally sourced items,
five open confirmations, and a "key build reminders" recap. Status header: verified
against a saved cart (40 lines parsed), camera already owned + flashed, *nothing
printed yet*. All-in ≈ $500.

### 3.2 The "changes since v1" section — why versioned docs matter

**[C]** v2 exists because five things changed, and the doc says *why* each changed:

- **Battery envelope corrected to ≤75×45×25 mm** — the 2024-body decision shrank the
  pack bay, and *both v1 files still carried the stale 2023-body number*. Lesson: when
  a decision changes upstream (body choice), every downstream doc quietly becomes
  wrong; versioning + changelogs are how you catch it.
- **Tyres resolved** — genuine Tamiya F104 (54198 front / 51400 rear) on printed rims,
  replacing an unresolved generic wheel line.
- **Camera cooling added** (blower + paste) — postdated v1.
- **Divider 27k/10k** (see §2.3 fix 2).
- **A stray non-build item removed** from the cart snapshot.

### 3.3 Component selections worth understanding (with the concepts)

**[C]** items; concept explanations **[I]** where marked:

- **Video:** the camera "has no radio" — the **BL-M8812EU2 USB WiFi module** provides
  the 5.8 GHz AP; it "runs hot" → dedicated heatsink *fitted before first power-on*.
  The **FT232RL USB-UART** is dual-purpose: camera console/flash *and* the PC↔ELRS-TX
  CRSF link (set its 3.3 V jumper — FT232 boards can output 5 V or 3.3 V logic;
  everything here is 3.3 V).
- **Radio:** RP1 receiver; **ES24TX Pro** TX module run at low power (25–100 mW — a
  desk-to-driveway link needs little; the doc notes a cheaper fanless ~250 mW nano as
  an "equal pick"). Transmitters *owned*: DualShock (via PC) for gift day, TX16S for
  bench/backup.
- **Drive:** the QuicRun 10BL120 + Rocket 540 **17.5T sensored combo** — motor included,
  ~⅓ of the whole budget. "17.5T" is the winding turn count; more turns = gentler,
  more controllable — a spec-racing class choice, matching the smoothness goal. **[I]**
- **Brains/audio/light:** 3× ESP32 DevKit V1 (**one spare** — cheap insurance),
  MAX98357A, 4 Ω 3 W speaker, **WS2812B 1 m / 30 LED / IP30** strip "driven by one
  ESP32 GPIO (no separate controller)".
- **Power/telemetry:** 2× 5 A UBEC (the two rails); XT30 pairs (low-current taps) vs
  **XT60** (battery↔ESC main link) — with a checkout warning since one listing sells
  both; **BX100 voltage buzzer** as an *optional independent* low-voltage alarm —
  independence meaning it monitors the pack directly, working even if every
  microcontroller is dead; a 600-piece resistor kit that covers exactly the three
  values the design needs (330 Ω, 10 kΩ, 27 kΩ).
- **Servos:** DS3235SG (ships a 25T horn — "25T" = 25 splines on the output shaft;
  horns must match the spline count **[I]**); 3× MG90S "positional, NOT 360°
  continuous" — continuous-rotation servos take speed commands, not angles, and would
  be useless for DRS/gimbal.
- **Speed sensor:** A3144 ×10 (they're fragile and cost pennies) + **3×1 mm N35
  neodymium magnets** for the axle ("N35" is a magnet strength grade **[I]**).
- **Drivetrain:** the designer's exact belt set (⚠ "stock runs low" — supply risk
  noted); **pinion 28T 48DP / spur 75T 48P** — *both 48-pitch*, "the one mesh-killer if
  mismatched" (gear pitch = tooth size; different pitches don't mesh); spur is **POM**
  (acetal/Delrin — a slippery, wear-resistant plastic **[I]**).
- **Bearings:** MR128ZZ 8×12×3.5 (fronts ×4) and 6801ZZ 12×21×5 (rear axle ×2) — "ZZ"
  = double metal shields **[I]**. These sizes are why the fit-test print matters (§2.2).
- **Suspension/steering:** 52 mm front oil shocks (target 51 — eye-to-eye length is the
  fit dimension), one central 68 mm rear; M4 rods/rod-ends + **turnbuckles** (adjustable
  links that set toe), king pins, M3 ball studs, tie-rod ends.
- **Fasteners:** countersunk M3 kit, **heat-set brass inserts** (chapter 03/atlas
  MECH-05), **D5×M3 metal sleeves** replacing wear-prone printed guide rods, and an
  aluminium tube to be cut into **14 mm rear-axle spacers so printed parts don't ride
  (and melt) on the hot axle**.
- **Cooling:** 5 V blower "powers off Rail B / decoupled 5 V (never the clean camera
  rail)" — fans are electrically noisy; the doc keeps that noise off the video rail.
- **Local:** 2S LiPo ×2 ("carry 2" — runtime insurance), soft-case, ≤75×45×25, XT60;
  the XT60 Y-split is *built from stock* (one battery feeding ESC + both BECs);
  1000 µF caps; optional 1N5819s; paint set (black ~TS-14, silver ~TS-17, Petronas
  turquoise ~#00A19C); waterslide decal paper with a trademark caution for logos/fonts.
- **Key build reminders** repeats the §2.3 fixes and adds the camera↔WiFi solder map
  (D+→DP, D−→DM, GND→GND, 5 V→VDD5.0 from Rail A) and WiFi tuning values
  (`bitrate_max=12, bitrate_min=2, dbm_threshold=-52`) — **[A]** these tune the
  OpenIPC/WiFi driver for range-vs-bitrate behavior; their exact semantics live in the
  camera ecosystem, outside these repos.

### 3.4 The five open confirmations

**[C]** §"Open confirmations": spur↔belt-pulley bolt pattern; king-pin bore = 3 mm
(measure the STL); XT60 variant at checkout; **TX16S internal module type** (if it's
already ELRS, the ES24TX Pro's role changes); test-fit one rim + tyre before gluing
four. All copied into `open_questions.md`.

### 3.5 Connections to source code

Divider values → `BatteryMonitor` config; one axle magnet → `magnetsPerRev = 1` in
`WheelSpeed` (`CLAUDE.md` §7); 30 LEDs → `LightRenderer`'s pixel count + power budget
(soundlight); 4 Ω 3 W speaker → the synth's "fundamental in a small speaker's band"
range choice; 2S pack → the 7.0/7.4 V thresholds and the battery frame's "coarse 2S
percent estimate." **[C]**

---

## 4. `docs/D8_BENCH_BRINGUP.md` — the bring-up runbook

### 4.1 What it is for

**[C]** The single ordered checklist taking the firmware from "builds + passes tests"
to "driving on the car," once hardware arrives. Eleven phases, each a
safety/dependency gate for the next; the golden rule threading through: **wheels off
the ground, and no ESC power, until failsafe + arm gate are proven live (Phase 5).**
It also consolidates *every* bench-verify doubt accumulated by the design reviews —
making it the project's inventory of remaining assumptions.

The header pins the tooling: bench firmware = `esp32dev_tuning`; gift firmware = plain
`esp32dev`; board #2 = its own `esp32dev`; ground station on `npm run demo` until the
camera is wired. Tools list includes an oscilloscope/logic analyzer and "a way to spin
the rear axle by hand."

*Bring-up* as a concept: hardware is validated in dependency order — power before
signals, signals before logic, logic before actuation, actuation before motion — so
that each test can trust everything below it, and a failure implicates the one new
layer. **[I]** framing; the phase structure embodies it.

### 4.2 Phase-by-phase, with the concepts

**Phase 0 — pre-power fixes.** The §2.3 fixes plus review additions (100 nF on GPIO34;
330 Ω/1000 µF/1N5819 for the strip; rails + common ground). Done *before any battery*
because "getting these wrong risks hardware on first power." **[C]**

**Phase 1 — power rails smoke.** A *smoke test*: apply power and verify nothing
misbehaves before connecting the expensive loads. Check BEC outputs ≈5 V / 5–6 V
*under a light load* (regulators can read fine unloaded and sag loaded), confirm no
rail sag/brownout when a servo moves ("that's what the 1000 µF is for"). **[C]**

**Phase 2 — ELRS link, no actuators.** Flash/bind all radio parts (same major.minor +
bind phrase); **set RP1 failsafe to "No Pulses"** (the A8 operational mitigation);
serial-dump the receiver's output to confirm 420,000 baud 8N1 non-inverted, sync 0xC8,
0x16 frames. Then **characterize link loss** — power the TX off and *measure*: the
LQ=0 stats burst (count + timing), the ~100 ms connected stats cadence, the
disconnect-declaration latency at the chosen packet rate, and that the RX emits no RC
frames before first bind. This phase exists to convert D4's design assumptions into
data — "note anything that diverges." **[C]**

**Phase 3 — control board, actuators disconnected.** Flash the tuning build; `status`
shows decoded channels moving with the sticks; and the **live A1 regression**: power on
with the TX off — the board must sit in failsafe ("this is the bug that used to slam
steering to full-lock; verify it's gone on real hardware"). Unit tests prove logic;
this proves the *integration*. **[C]**

**Phase 4 — channel map + thresholds.** Verify the ch1…ch13 defaults against the real
transmitter (remap in `lib/channels/ChannelDecoder.hpp` + reflash if needed). The
subtle trap called out: every 2-position switch must cross *both* hysteresis thresholds
(±250) — **especially the ARM switch's OFF direction**: a transmitter *mix* (the TX's
own channel-shaping math) that never outputs below −250 would make ARM impossible to
turn off. The 3-pos mode switch must hit all three detents. **[C]**

**Phase 5 — failsafe + arm-gate proof. THE GATE.** "Do not power the ESC until every
box here passes." Each checkbox maps to a specific design guarantee: arm OFF ⇒ neutral
regardless of stick (ArmGate); arm ON with throttle high ⇒ still neutral until a fresh
neutral (A2/§6.2); TX off mid-drive ⇒ steering centers, throttle neutral, DRS closed
(FSM timeout); recovery ⇒ blocked until the stick centers (A3 fresh-neutral); and the
hold-position case if reproducible (LQ=0 while frames flow ⇒ still drops — A8/D4
latch). **[C]**

**Phase 6 — steering servo.** **Center the servo in firmware BEFORE attaching the
linkage** (atlas MECH-02 note): a servo linked while off-center makes "straight ahead"
impossible to trim. Then trim over the console (`set steer.center`, `set steer.trim`,
`save`) — with the note that the firmware rejects trim past an endpoint (A11's
validation). Confirm full lock doesn't bind or stall against the stops. **[C]**

**Phase 7 — ESC + motor, wheels OFF.** ESC configured sensored + **forward/brake**
("NOT forward/reverse — the gearbox doesn't govern reverse; brake/reverse PWM is
indistinguishable below neutral"); the ESC's own neutral/range calibration ("it's the
ESC's own config; firmware just emits 1000–2000 µs"); watch the 2 s boot hold arm the
ESC; feel the gear caps, brake behavior, ERS deploy/harvest — all before wheels touch
the ground. **[C]**

**Phase 7b — gimbal.** Map the DualShock right stick → ch9/ch10 in
elrs-joystick-control; verify pan (GPIO19) / tilt (GPIO23); flip `invertPan`/
`invertTilt` in `ChannelMapConfig` if reversed; confirm the camera **holds aim on link
drop** (deliberately not safety-gated). **[C]**

**Phase 8 — sensors.** **Two-point calibration** of the battery ADC: measure the real
pack at ~6.5 V and ~8.4 V with a multimeter, compare to the console, correct with
`set batt.ppt`, `save`. Two points because a divider+ADC error has both an offset and a
slope; one point can't distinguish them. **[I]** rationale. Log **which eFuse cal type**
the ADC reports — ESP32s carry factory calibration burned into on-chip *eFuses*; older
units fall back to a default reference voltage with worse accuracy, worth knowing.
Hall: spin the axle by hand for sanity, then **scope the line at full throttle near the
motor** for EMI double-counts (add 1–10 nF across the sensor output if the edge is
ugly; the 2 ms lockout absorbs mild bounce). **[C]**

**Phase 9 — link2 → board #2.** Wire GPIO25→GPIO16 + common ground; MAX98357A GAIN
strap starting at floating (9 dB); verify sound follows throttle, lights follow state —
and the protocol's mandatory rule live: **cut the UART mid-run ⇒ board #2 in local
failsafe within 500 ms** (engine silent, hazard blink). **[C]**

**Phase 10 — ground station.** The **#1 risk first**: check `majestic.yaml`
`.video0.codec` — Chromium WebRTC generally can't decode H.265; reconfigure to H.264 or
transcode (VLC survives H.265 regardless). Set the real RTSP URL in
`mediamtx/mediamtx.yml`; confirm WHEP video; validate the zero-code fallback; then the
telemetry serial-sharing problem (forward flag or com0com; `W17_TELEMETRY_*`;
`npx electron-rebuild`). Speed/gear/ERS "stay gamepad-simulated by design" *in this
phase's wording* — **[I]** written before B3.8 extended telemetry; the runbook's Phase
10 text slightly lags the final feature set (flagged in open_questions). **[C]** for
the rest.

**Phase 11 — on the car.** Mount with mass central, re-confirm Phase 5 *on the car*,
short low-gear shakedown, re-trim over the console, and — before gifting — optionally
reflash plain `esp32dev` (console-free; NVS tuning persists). **[C]**

### 4.3 Connections to source code

Phases 3–9 exercise, in order: `FailsafeStateMachine` (boot-safe), `ChannelDecoder`
(map + hysteresis), `ArmGate`, `ServoOutput` (center/trim/endpoint validation),
`EscOutput` (boot hold), `Gearbox`/`ErsSystem`, gimbal outputs, `BatteryMonitor` +
`Esp32BatteryAdc` (`batt.ppt`), `WheelSpeed` + `Esp32HallPulseCounter` (lockout),
`Link2Sender` → soundlight `Link2Monitor` (staleness), and the console/`Settings`
stack. It is, in effect, the integration-test suite that can't be automated. **[C/I]**

---

## 5. `docs/link2_protocol.md` — the protocol specification

*(Byte-level drill: chapter 09 §2. Here: the document as a spec, and its decisions.)*

### 5.1 What it is for

**[C]** The **normative** definition of the one-way board#1→board#2 link: physical
layer, framing, payload semantics, timing, and — unusually and importantly — explicit
**receiver obligations** written in MUST language. This repo owns it; the soundlight
copy is a mirror.

### 5.2 Design decisions, one by one

**[C]** unless marked:

- **One-way by design.** Sender TX GPIO25 → receiver RX; GPIO26 "reserved for a future
  ack channel and is not driven — do not connect anything to it yet." Keeping the
  channel one-way makes board #2 incapable of influencing board #1 (a safety property)
  and keeps both firmwares simpler; the reserved pin keeps the door open.
- **115200 baud** — modest and deliberate: v1 traffic is 14 bytes × 20 Hz = 280 B/s
  against ~11,520 B/s capacity (~2.4% utilization). Slow standard rates are robust to
  wiring imperfections and leave 40× headroom for protocol growth. **[I]** (arithmetic
  mine; rate choice documented.)
- **"Both boards power from the same UBEC rail, so they come up together; avoid
  driving the line into an unpowered board #2 for long periods."** The concept is
  *parasitic powering*: a driven input pin on an unpowered chip leaks current through
  the chip's protection diodes, half-powering it — stressful and flaky. Shared rail
  makes the situation transient only. **[I]** mechanism; rule documented.
- **A liftable reference implementation** — the spec names `lib/link2/` as "liftable
  wholesale … no dependencies beyond a byte-sink interface," which is why the CRC is
  duplicated there rather than shared from `lib/crsf` (ROADMAP D6). Spec + portable
  reference implementation + golden test = the full package for the receiving repo.
- **CRC-8/DVB-S2 (poly 0xD5), same as CRSF**, with the catalog *check value* stated:
  CRC of ASCII `"123456789"` = `0xBC`. A check value is the standard fingerprint used
  to verify you implemented the right CRC variant — run it once against your
  implementation and compare. Choosing CRSF's exact CRC meant free cross-validation
  (the repo tests link2's CRC against crsf's).
- **Validation order pinned: start → length → CRC → version.** Because CRC is verified
  *before* version, `BadVersion` provably means "well-formed frame from a newer
  sender," never corruption — so a receiver can choose to ignore-but-count it instead
  of treating it as line noise.
- **Hard-reject unsupported length immediately** — a corrupted length byte of 0xFF
  would otherwise make the receiver buffer 255 garbage bytes, swallowing ~1 s of good
  frames. Bounding *time-to-resync* is a real-time concern ordinary protocols ignore.
- **Payload semantics** (each a decision, per field): throttle = **as-commanded, not
  stick** (0 in disarm/failsafe — the engine sound must track the motor, not the
  driver's wishes); negative throttle = braking, "never reverse motion"; steering live
  even disarmed (indicators should work at rest); braking pre-hysteresis-filtered by
  the sender (one authority for the threshold — two boards filtering independently
  would disagree at the boundary); `reverse` reserved always-0 ("do not key anything
  off it"); bit7 "sender writes 0, **receivers must mask, never reject**" — the
  forward-compatibility rule letting a future sender use bit7 without breaking old
  receivers; rpm is **wheel** rpm (~≤5000), explicitly *not* engine rpm — the receiver
  derives engine revs (chapter 07 §3); batteryMv is "display garnish" while the
  lowBattery *flag* is "the authoritative judgment" (calibrated, 3 s-qualified,
  latched on board #1 — don't re-derive it worse downstream); ersPercent **frozen, not
  zeroed** outside ERS mode; unknown driveMode → treat as 1 (fail to the default
  behavior, not to a special case).
- **The state matrix** (failsafe / disarmed / driving rows) pins the invariant that
  telemetry (rpm, battery) stays live in every state — only *commands* zero out.
- **Timing:** nominal 20 Hz; "receivers must tolerate jitter and must not phase-lock
  to the rate" — i.e. never build logic that *depends* on 50 ms spacing; and the
  **mandatory 500 ms staleness rule** (10 missed frames ⇒ local failsafe), because "on
  a one-way link, a cut wire is otherwise indistinguishable from 'the last state
  persists forever'."
- **A worked example pinned by a test** — the spec's example frame *is* the golden test
  vector (`test_golden_frame_bytes`), so documentation and implementation cannot drift
  silently.

### 5.3 Connections to source code

`lib/link2/Link2Frame.hpp` (constants + flag masks + `VehicleState` — note its
boot-safe defaults: `failsafe = true`, "never report a phantom Active"),
`Link2Codec.{hpp,cpp}` (encode/decode/assembler), `Link2Sender` (20 Hz shaping + brake
hysteresis), `lib/link2_hal_esp32/Esp32Link2Uart` (UART1 TX-only, remapped);
receiver side: soundlight's verbatim `lib/link2` + `Link2Monitor` (the 500 ms
obligation); test: `test/test_link2/test_main.cpp`. **[C]**

---

## 6. `docs/SIMULATION.md` — the Wokwi runbook

### 6.1 What it is for

**[C]** Validation **Stage 2** (of CLAUDE.md §4's three): after native unit tests
(Stage 1) and before hardware (Stage 3), run the *real compiled firmware* end-to-end in
the Wokwi ESP32 simulator with a virtual circuit. What this stage uniquely catches:
integration behavior — "the genuine UART driver, parser, failsafe, arm gate, gearbox,
and outputs all run unmodified" — i.e. the glue that unit tests, by design, don't touch.

### 6.2 Design decisions

- **The self-feeding loopback.** The scripted CRSF source (`SimCrsfFeeder`) doesn't
  inject bytes into the parser in software — it *transmits real UART bytes out TX2*,
  which a virtual wire loops back into RX2, so the actual ESP32 UART driver at 420,000
  baud is part of the test. Maximal realism for minimal machinery. **[C]**
- **`esp32dev_sim` = the real firmware + one flag.** The env differs from the gift
  build only by `-DW17_SIM_CRSF_FEEDER` (compiling in the feeder + status prints) — so
  what you watch is what ships, plus a narrator. **[C]** `platformio.ini`.
- **The ~25 s script demonstrates every safety behavior *distinctly*** — the phase
  table maps almost one-to-one onto requirements and findings:

| t (s) | Phase | Proves (requirement/finding) |
|---|---|---|
| 0–2 | SILENT | boot-safe: never-received latch (A1) on cycle 1, outage on later cycles |
| 2–5 | DISARMED_STEERING | steering live while disarmed; throttle gated (§6.2 split) |
| 5–6.5 | ARM_BLOCKED | arm ON at 60% throttle ⇒ neutral — genuinely the ArmGate ("the ESC's own 2 s boot hold expired long ago") (A2) |
| 6.5–8 | ARM_NEUTRAL | fresh-neutral arms |
| 8–15 | DRIVING | gear caps visibly rise on shifts; DRS opens; 13–14.5 s: mode→Gearbox+ERS, boost past the gear cap, store draining ~26 %/s |
| 15–17.5 | TIMEOUT_OUTAGE | pure silence, no LQ=0 ⇒ the ~0.5 s *delayed* drop — the frame-timeout path in isolation |
| 17.5–19 | RECOVERY_1 | stats **lead** the recovery — the LQ latch clears only on good stats; ~150 ms re-arm window |
| 19–21 | HOLD_POSITION_FAILSAFE | LQ=0 stats **while RC frames keep flowing at 50% throttle** ⇒ *instant* drop — "the most valuable thing this sim demonstrates" (A8) |
| 21–23 | RECOVERY_2 | link good but stick at 50% ⇒ blocked until centered (A3) |
| 23–25 | COOLDOWN | gear-down ×2 so each cycle restarts from gear 1 — *because* gear deliberately survives failsafe (D3), the script must undo it for loop idempotency |

  Note the pairing of phases 15–17.5 and 19–21: the two failsafe *triggers* (timeout vs
  LQ latch) are demonstrated separately, one slow, one instant — you can tell them
  apart on sight. **[C]** table; pairing observation **[I]**.
- **Interactive instruments** map to the real electronics: the pot preset ≈69% ≈ 2.27 V
  pin ≈ 8.4 V battery (exactly the divider's tap voltage, §2.3); lowering below
  ≈1.9 V pin for 3 s trips the low-battery latch, raising above ≈2.0 V clears —
  hysteresis made visible. The button counts on **release** because release is the
  *rising* edge through the pull-up, "exactly like the real A3144 wiring"; ERS harvest
  only charges while you click — the rpm>0 harvest gate made visible. **[C]**
- **Cosmetic quirks documented with a do-not-"fix" warning:** the `wokwi-servo` maps
  ~544–2400 µs to 0–180°, so the steering's 500–2500 µs endpoints visually clamp —
  "Cosmetic only — do not 'fix' `ServoOutput`." A documented guard against a future
  reader "correcting" firmware to match a simulator artifact. **[C]**
- **The first-run verify checklist** — five *low-confidence platform facts* (pin label
  names, 420 k baud over loopback, pot `value` preset, plain-bin boot vs merged image,
  bounce vs the 2 ms lockout) listed for the first interactive run. Epistemic honesty:
  the doc separates "what the firmware guarantees" from "what we assume about Wokwi."
  Copied into `open_questions.md`. **[C]**
- **Future hook:** `wokwi-cli` scenario YAML + serial assertions could turn this exact
  script into automated Stage-2 CI regression — noted, not built. **[C]**

### 6.3 Connections to source code

`src/SimCrsfFeeder.{hpp,cpp}` (the script; compiled only under the flag);
`crsf/CrsfFrameBuilder.hpp` — frame construction *lifted out of the tests* and shared
with the feeder ("zero duplication, still pure"); `[env:esp32dev_sim]` in
`platformio.ini`; the circuit itself in `diagram.json` (§9). The `[state]` line's
fields mirror the modules' public accessors. **[C]**

---

## 7. `docs/print_spec_v2.md` — the manufacturing spec

### 7.1 What it is for

**[C]** Slicer settings **and print order** for every printed part, organized by
material group, plus part *selection* (which upstream model folders to print vs skip),
finishing, and safety. Supersedes v1; the changelog records: wheels resolved to printed
rims + bought tyres, the brake-light diffuser admitted as a light-transmitting
exception, the camera-cooling duct added, and the part selection locked (original
oil-shock + generic 2024 body).

### 7.2 The engineering ideas (explained for a non-printer)

- **The golden rule — anisotropy.** FDM prints are stacks of fused layers; the bond
  *between* layers is far weaker than the plastic *within* a layer, so "a part fails
  between layers." Orienting each stressed part so load runs **along** the layers
  "often beats going 40% → 100% infill" — geometry beats density. **[C]** rule; physics
  **[I]** standard FDM knowledge.
- **Vocabulary:** *layer height* (0.2 mm default; 0.12–0.16 mm on visible bodywork —
  finer = smoother = less sanding); *walls/perimeters* (solid outlines per layer — 4–5
  on structural parts because walls carry most load); *infill* (interior fill %) and
  its *pattern*: **gyroid** (a wavy 3D surface, strong in all directions) as default,
  **rectilinear only at 100%** (at full density you just want complete material).
  **[C]** settings; explanations **[I]**.
- **The material ladder** maps each part group to load + heat: PLA (easy, stiff, soft
  above ~55 °C) for the cosmetic shell; PETG (tougher, more heat-tolerant) for
  floor/front/wheel parts and the camera duct ("PLA would creep" against the hot
  camera — creep = slow permanent deformation under load+warmth); **ASA** (high-temp,
  UV-stable, but warps in drafts and emits **styrene** fumes — print enclosed *and*
  ventilated) mandatory for the rear axle/drivetrain — "the documented failure point
  (motor/drivetrain heat softens PLA; the metal axle sleeves exist for the same
  reason)." **[C]** assignments; material properties **[I]**.
- **The brake-light diffuser — the exception that proves the firmware.** The
  `rearbacklightdiffuser` must *glow*, so it breaks the body rules: white/natural
  translucent material, 1–2 perimeters over the lens, lens left unpainted (masked
  during body paint). The punchline is a firmware connection: "**Let the WS2812 produce
  red in firmware** — a clear/white lens then also lets the same LEDs do amber/white
  for other effects." The hazard blink (amber) and any future effect work through the
  same window precisely because the *plastic* isn't red. **[C]**
- **Part selection decisions:** print the generic 2024 body and paint the W17 livery
  (skip the Ferrari/McLaren team-shaped folders); print the *original* oil-shock front
  (skip the entire revision ball-joint steering folder — incompatible); rear has an
  **open verification**: only if the slicer check shows `Spring_mount_2_REVISION_1`'s
  rocker seats the 68 mm coilover may the hybrid rocker be used, else original rear.
  A parametric duct starter (`camera_blower_duct.scad`) is "provided separately" —
  **[I]** it is *not in the repo* (flagged in open_questions). **[C]**
- **Sequence:** test coupons → one rim + hub + tyre test-fit **before printing the
  other three** → ASA rear → PETG front → floor → body (slow, fine) → diffuser →
  duct last (measure real parts first). Fail-fast ordering: the cheapest prints that
  can invalidate the most downstream work go first. **[C]**

### 7.3 Connections to source code

Only two, but real: the diffuser ↔ `LightRenderer` color decisions (red produced in
firmware; amber hazard shares the lens), and the duct/blower ↔ nothing in code (Rail B
power only). Everything else is mechanical context for why the electronics bay is
shaped as it is. **[C/I]**

---

## 8. `docs/w17_wiring_assembly_atlas.html` — the visual atlas

### 8.1 What it is for, and how to read it

**[C]** A self-contained HTML page ("W17 Build — Wiring & Assembly Atlas") rendering
twelve Mermaid diagrams: Part A electrical (ELEC-01…06), Part B mechanical
(MECH-01…06), each with a prose explanation and amber "note" callouts for the traps.
Open it in a browser; diagrams render on load. **[I]** One practical note: it loads
Mermaid from a CDN (`cdnjs.cloudflare.com`), so first viewing needs internet.

Its legend defines arrow semantics — → feed/signal, ⇢ power, ⇒ wireless, — mechanical
join/shared GND — a small formality that keeps twelve diagrams unambiguous. **[C]**

### 8.2 Card-by-card

**[C]** content; commentary **[I]** where marked:

- **ELEC-01 System overview** — the two-radio-links picture (chapter 01 §3), with the
  key sentence: control and video "share nothing but the battery — that's why TX power
  never affects video range."
- **ELEC-02 Power distribution** — battery → XT60 Y → ESC + BEC#1 (clean: camera, WiFi,
  both ESP32s, RX, LEDs) + BEC#2 (servos), and the critical note: every GND tied
  together. Note the LEDs sit on the *clean* rail — **[I]** consistent with the strip's
  own smoothing (1000 µF) and the firmware's brightness/power cap keeping its draw
  bounded.
- **ELEC-03 Control signal chain** — DualShock → PC ("maps buttons to channels") →
  FT232 (3.3 V) → TX module (own 5 V feed, "set 25–100 mW") ⇒ RP1 → ESP32 #1. The
  TX16S "binds to the same RX with the same bind phrase, so it's a drop-in backup
  transmitter — only one transmits at a time."
- **ELEC-04 ESP32 #1 I/O** — one CRSF stream in, PWM fan-out (one signal wire per
  actuator, shared 5 V + ground), UART to board #2 — and the conceptually important
  sentence: gear/boost/overtake channels "have no wire of their own — they're handled
  in firmware (virtual gearbox / ERS) and passed to ESP32 #2." *Virtual channels*: RC
  channels that terminate in software state rather than a physical output. Two
  provenance tells here: pins are labeled "CH1/CH2…" with a note that real numbers
  live in `esp32_car_control.ino` — a file that **does not exist**; the firmware is
  PlatformIO C++ with pins in `PinMap.hpp`. **[I]** The atlas predates the firmware
  (corroborated by the footer: "pin numbers are illustrative — your firmware defines
  the real ones").
- **ELEC-05 ESP32 #2 outputs** — the 3-wire UART in, I2S (BCLK/LRC/DIN) to the amp,
  one data line through ~330 Ω to the LEDs; "brake-red and halo are just different
  pixels in code."
- **ELEC-06 Camera ↔ WiFi** — the four solder joints (D+→DP, D−→DM, GND, 5 V→VDD5.0
  from Rail A), the FT232 doubling as camera console, and the two protect-the-module
  rules (antennas before power; heatsink first).
- **MECH-01 Drivetrain** — motor 3.175 mm shaft → pinion 28T ⟶(mesh 48P)⟶ spur 75T →
  drive pulley → belt → rear-axle pulley → axle in two 12×21×5 bearings, spaced by the
  14 mm metal sleeves, to 12 mm-hex wheels. "The pinion and spur must be the same
  48-pitch or the teeth won't mesh — the one mechanical mistake that stops everything."
- **MECH-02 Steering** — servo → 25T horn → M4 rod → tie rods + 32 mm turnbuckles →
  ball studs → knuckles pivoting on king pins → wheels. Turnbuckles set **toe**
  (wheels' inward/outward angle) and "are the bits that snap in a crash" (sacrificial
  part concept). Note: "Centre the servo in firmware **before** you attach the
  linkage" — the origin of D8 Phase 6's first checkbox.
- **MECH-03 One front corner** — the four jobs at each wheel: A-arm (up/down, damped by
  the 51 mm shock), king pin (steering pivot), two 8×12×3.5 bearings (spin), tie rod
  (steering input). "Build each corner as a unit."
- **MECH-04 Rear axle** — printed holders hold the bearings; pulley + spur ride the
  axle; **one central 68 mm damper — the F1 layout** (contrast with the front's two).
- **MECH-05 Fasteners** — heat-set brass inserts ("a steel M3 bolt bites metal
  threads, not plastic"), thread-lock only metal-to-metal ("never into plastic" — it
  attacks many plastics **[I]**), D5×M3 sleeves replacing wear-prone printed guide
  rods.
- **MECH-06 Whole-chassis layout** — front (steering + 2 shocks) / middle (battery,
  ESP32s, BECs, gimbal — "mass kept central for balance") / rear (motor, drivetrain,
  1 shock, wheels).

### 8.3 Connections to source code

Topology-level only: ELEC-04's I/O set matches `PinMap.hpp` signal-for-signal (with
illustrative pin names); ELEC-03 is the physical layer under `lib/crsf`; ELEC-05 under
`lib/link2` + the soundlight HALs; MECH-02's center-before-linkage note became a D8
step that uses the console (`lib/console`). Trust rule stands: **topology from the
atlas, pin numbers from `PinMap.hpp`.** **[C/I]**

---

## 9. `diagram.json` + `wokwi.toml` — the virtual circuit

### 9.1 What they are for

**[C]** The two files the Wokwi simulator reads: `wokwi.toml` points at the firmware
images to load (`.pio/build/esp32dev_sim/firmware.bin` + `.elf` — the `.bin` is the
flashable image; the `.elf` carries debug symbols), and `diagram.json` describes the
virtual breadboard: which parts exist and how they're wired.

### 9.2 Reading `diagram.json` (the format, then the circuit)

The format: a `parts` array (each part = a `type` from Wokwi's catalog, an `id`, canvas
position, and `attrs`) and a `connections` array — a **netlist**, i.e. a list of
"this pin connects to that pin" records, each `[from, to, wireColor, waypoints]`.
`$serialMonitor` is a pseudo-part: the simulator's serial console. **[C]** file read
in full; format semantics **[I]** standard Wokwi.

The circuit, part by part, each mapped to what it *stands for*:

| Virtual part | attrs | Stands for | Wiring |
|---|---|---|---|
| `wokwi-esp32-devkit-v1` (`esp`) | — | the real DevKit V1 | — |
| `servoSteering` | horn **cyan** | DS3235SG steering | PWM→`D13`, V+→`VIN`, GND→`GND.1` |
| `servoEsc` | horn **red** | the ESC (needle = PWM visualizer: center 1500 µs, right = forward) | PWM→`D14` |
| `servoDrs` | horn **yellow** | DRS MG90S | PWM→`D18` |
| `potBattery` | `value: "69"` | the 27k/10k divider tap | SIG→`D34`, VCC→`3V3`, GND→`GND.2` |
| `btnHall` + `rHallPullup` | 10 kΩ | the A3144 + its pull-up | resistor `3V3`↔`D35`; button `D35`↔`GND.2` |
| loopback wire | gold | the RP1's CRSF output | `TX2` → `RX2` |
| `$serialMonitor` | — | your terminal | `TX0`/`RX0` |

Details worth noticing:

- **The pot preset is exact:** `value: "69"` = 69% of the 3.3 V VCC = **2.277 V** at
  D34 — matching the real divider's 8.4 V × 0.270 ≈ 2.27 V tap voltage (§2.3 fix 2),
  which is why SIMULATION.md expects `batt≈8400mV` at boot. The simulated *pot*
  replaces the divider because both are just "a voltage between 0 and something on an
  ADC pin." **[C]** value; equivalence **[I]**.
- **The Hall stand-in is electrically faithful:** button to GND + external 10 kΩ to
  3.3 V = open-collector-with-pull-up, so *releasing* the button makes the rising edge
  — same polarity and mechanism as the real sensor; even contact bounce lands inside
  the ISR's 2 ms lockout like real-world noise would. **[C]** per SIMULATION.md.
- **Servos' V+ goes to `VIN`** (the DevKit's 5 V-ish input pin). Wokwi doesn't
  simulate current draw, so this is cosmetic wiring — the real car powers servos from
  Rail B, never from the DevKit. **[I]** — do not copy this wiring to hardware.
- **`GND.1`/`GND.2`** are just the two distinct ground pins on the DevKit silkscreen —
  the diagram must name pins exactly as the board defines them (SIMULATION.md's
  checklist: wrong names "fail fast at diagram load").
- **The gold `TX2`→`RX2` wire is the whole trick:** `SimCrsfFeeder` transmits real
  CRSF bytes out UART2-TX, the wire delivers them to UART2-RX (GPIO16 — the same pin
  the RP1 drives in reality), and the production `Esp32CrsfUart` receives them. The
  firmware cannot tell it isn't a receiver. **[C]**
- **What's absent** (compare `PinMap.hpp`): no pan/tilt servos (GPIO19/23), no link2
  UART partner (GPIO25/26), no CRSF telemetry-out consumer (GPIO17). **[I]** The
  diagram was built at D7 (2026-07-02), *before* the gimbal (B3.7) and telemetry-out
  (B2.5) landed on 07-03 — the sim demonstrates the D7-era feature set plus whatever
  needs no extra parts. Whether to extend the diagram is an open question.

### 9.3 Connections to source code

`wokwi.toml` ↔ `platformio.ini [env:esp32dev_sim]` (build first, then simulate);
`diagram.json` pin choices ↔ `lib/config/PinMap.hpp` (D13/D14/D18/D34/D35 all match);
the loopback ↔ `src/SimCrsfFeeder.cpp` + `lib/crsf_hal_esp32/Esp32CrsfUart`; the pot ↔
`BatteryMonitor` expectations; the button ↔ `Esp32HallPulseCounter`'s edge/lockout
logic. **[C]**

---

## 10. The remaining two files, briefly

**`CLAUDE.md` (repo root) — the founding brief.** The project's constitution: context
(§0), pin map (§1), the 8-module functional spec (§2), behavior defaults (§3), the
3-stage validation plan (§4), architecture rules (§5), the four non-negotiable safety
priorities (§6), bench wiring notes (§7), first-deliverable scope (§8). Written
*before* the code ("STARTING PROPOSAL", "stop and show me"); superseded in details by
ROADMAP + code (examples: link2 payload grew from §2.7's sketch; `CrsfReceiver` arrived
late as A13's fix; "Direct mode" dropped in B2.2). **[C/I]** as in §1.

**`docs/f1_hud.html` — the HUD design mockup.** A standalone Mercedes-palette dashboard
over a placeholder video background. **[I]** The design prototype for
`w17-ground-station/renderer/` — and quietly a *numbers contract*: `lib/ers/
ErsSystem.hpp` cites it by name for the feel rates ("docs/f1_hud.html: deploy 26%/s,
harvest 11%/s, boost ceiling ×1.18"), which also live in the ground station's
`shared/feelConstants.js`. Treat as historical intent + the origin of the shared
constants, not as current UI truth.

---

## 11. Trust ordering — when sources disagree

**[I]** Derived from the documents' own supersession notes and the golden-test
structure:

1. **Code + unit tests** (protocols pinned byte-exactly)
2. **ROADMAP.md** (what actually landed and why)
3. **Protocol docs** (`link2_protocol.md` — kept in lockstep by golden tests)
4. **Operational docs** (D8, SIMULATION — current but with self-declared verify lists)
5. **CLAUDE.md** (original intent)
6. **Wiring atlas** (pre-firmware topology; pins illustrative)
7. Anything superseded (v1 docs, `f1_hud.html` as UI truth)

## 12. Confirmed vs inferred — chapter summary

**Confirmed [C]:** all nine documents were read in full (f1_hud.html in part — style/
structure verified, full JS not analyzed); every quoted rule, number, finding, phase,
and wire cites its source inline above.

**Inferred [I], the load-bearing ones:** the 20k/10k clipping arithmetic (§2.3);
the 115200-baud utilization math (§5.2); the atlas and diagram provenance/dating
(§8.2, §9.2 — from internal references and ROADMAP dates); the pot-value equivalence
(§9.2); the D8 Phase-10 wording lagging B3.8 (§4.2); the missing "runbooks 02–06"
(§2.1); `camera_blower_duct.scad` not being in the repo (§7.2).

**Assumed [A]:** WiFi tuning values' semantics (§3.3); everything hardware-behavioral
remains bench-pending per the repos' own checklists (tracked in `open_questions.md`).

## Questions to check your understanding

1. Reconstruct bug A1 without looking: which variable's default value, combined with
   which formula, produced the false "link healthy," and which servo behavior resulted?
   Why didn't the test suite catch it?
2. Findings A9 and A10 were *accepted*, not fixed. What did the reviewers weigh in each
   case, and why is writing down an accepted defect valuable?
3. The BOM changed the divider from 20k/10k to 27k/10k. Show with arithmetic what a
   full 8.4 V pack reads at the ADC pin under both, and state which one the 11 dB
   linear ceiling (~2.5 V) rejects.
4. Why does D8 Phase 5 forbid ESC power until failsafe is proven, when Phase 3 already
   verified boot-safe behavior? What class of bug does Phase 5 catch that Phase 3
   can't?
5. link2's `BadVersion` result "means a well-formed frame from a newer sender, not
   corruption." Which two spec decisions make that sentence provably true?
6. In the Wokwi script, phases TIMEOUT_OUTAGE and HOLD_POSITION_FAILSAFE both end in
   Safe. Describe the input difference and the observable timing difference, and name
   the code mechanism behind each.
7. The print spec forbids painting the brake-light lens and forbids red plastic. What
   firmware capability does this preserve, and in which module does the color actually
   get decided?
8. In `diagram.json`, why does the Hall button count on *release*, and which two
   components of the virtual wiring make that the rising edge?
9. The atlas says the ESC is on "CH2 PWM"; `PinMap.hpp` says GPIO14. Explain the
   discrepancy using each document's provenance, and state the rule for which to trust.
10. Name three places where a *document sentence* is enforced by a *unit test* (hint:
    one protocol example, one safety example, one cross-repo example).
