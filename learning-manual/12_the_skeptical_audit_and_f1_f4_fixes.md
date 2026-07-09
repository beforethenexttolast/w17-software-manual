# 12 — The Skeptical Audit and the F1–F4 Fixes

By early July 2026, every earlier chapter's story was true: 147 + 40 firmware tests green,
all builds passing, protocols pinned by golden tests, a reviewed safety chain. And yet the
project then commissioned an **independent skeptical audit** of all three repos — and that
audit found 22 verified risks, four of them High. This chapter explains why that is not a
contradiction, what the audit actually did, what the four approved fix batches (F1–F4)
changed, and — most importantly for a beginner — **why "all tests green" and "proven" are
different things**.

Everything here is documented in `w17-control-fw/project-review/` — the audit's own
output folder (summary, ten dimension reviews, risk register, validation plan, triage,
fix contract, verification results, progress tracker, and the A2 checklist). This
chapter is the guided tour; citations point into it.

> **Reading prerequisites:** chapters 06–11 (you need to know what the failsafe chain,
> link2, the HUD, and the CI setup *are* before reading about how they were attacked).

---

## 1. Why audit a project whose tests all pass?

### 1.1 The two failure classes tests cannot catch

Everything the manual praised in chapters 06–11 is real — and it is all
**software-evidence**: source reading, native tests, builds, CI, simulation scripts. The
audit existed to hunt the two failure classes that this kind of evidence structurally
cannot catch:

1. **Hardware truths the code assumes but cannot enforce.** The firmware *assumes* the
   ESC arms after a 2 s neutral hold, *assumes* ELRS relays its telemetry frames,
   *assumes* the camera speaks H.264, *assumes* motor EMI won't fake Hall pulses. No unit
   test can verify an assumption about a physical device that has never been powered.
2. **Gaps that green CI actively hides.** A test suite proves what it tests — and
   silently says nothing about what it doesn't. The audit's summary put it in one line:
   **"everything green is software-green. Not one line has run on real silicon."** [C]
   `project-review/00_review_summary.md`.

### 1.2 What a "skeptical audit" is

An audit here means: an independent review that treats **all code as guilty until proven
correct, regardless of who wrote it** [C] (`00_review_summary.md` scope line). This is
the same *adversarial review* idea chapter 05 §1 described for ROADMAP Part A (a reviewer
actively tries to prove the code wrong), but scaled up: applied to all three repos at
once, pre-hardware, with the explicit goal of producing a **risk register** — a ranked
list of what could still go wrong — rather than a pass/fail verdict.

The distinction worth internalizing: **confidence is a feeling supported by evidence;
proof is evidence that covers the actual question.** 147 green tests give high confidence
in the decode/state-machine/scaling math — and prove *nothing* about whether the QuicRun
ESC arms in 2 seconds. The audit's job was to sort every belief in the project into
"proven by what we have" vs "assumed until the bench says so." Its honest confidence
statement: **high** that the math is correct, **low** that the assembled firmware behaves
correctly on real silicon [C] (`08_simulation_test_review.md`).

## 2. How the audit was run (and why its own findings got audited)

**[C]** Method, from `00_review_summary.md` and `review_progress.md`:

1. **Ten dimension investigations**, one per risk area (the list in §3), across all three
   repos, read-only, with a confirmed baseline first (control 147/147 + 3 env builds;
   soundlight 40/40 + builds; ground station 21/21 vitest at audit time).
2. **Cross-dimension dedupe** — the same root issue found by four investigators becomes
   *one* register entry, not four findings.
3. **Adversarial re-check of every High/Medium finding** — the lead auditor re-read the
   cited code for each claim and issued a verdict: **CONFIRMED** (evidence holds),
   **ADJUSTED** (real but mis-stated — severity or mechanism corrected), **REFUTED**
   (claim doesn't hold), or **PLAUSIBLE** (legitimate, but only provable on hardware)
   [C] `_verification_results.md`.

Step 3 is the part beginners should study. The initial investigation produced one
"Critical" and several inflated Highs — and verification **downgraded or refuted them**:
the "critical" unpinned-platform finding was demoted to *latent* High (it builds fine
today — the danger is a future toolchain release); a claimed WheelSpeed "collapse to
near-zero" was **refuted outright** by re-deriving the arithmetic (the real behavior is a
benign ~40 rpm resolution floor, R21); a "LEDC at its limit" claim was mostly refuted
(16-bit sits well under the ~20.6-bit ceiling at 50 Hz) [C] `00_review_summary.md`,
`_verification_results.md`. **Audit findings are claims too, and claims get tested.**
The final headline: **no Critical risks survived verification** — nothing found could
damage hardware, cause uncontrolled motion, or block basic operation on its own [C].

## 3. The risk model — ten ways a project like this can fail

The audit sliced the project into ten *dimensions* — each a different answer to "what
kind of wrong could this be?" Files `01–09` plus a safety dimension. One paragraph each:

| Dimension (file) | The question it asks | One-line verdict [C] |
|---|---|---|
| **Spec vs implementation** (`01`) | Does what was built match what was promised — and what the owner *believes* they have? | Delivers far more than the spec; but every "DONE" is software-DONE, and the HUD would show a live-looking *simulation* during a real link loss (→ R01) |
| **Architecture** (`02`) | Are the repo boundaries and seams sound? Where can copies drift? | HAL seam genuinely clean (grep-verified: zero hardware includes in pure logic); weakness = three hand-synced copies of wire truth with **no drift guard** (→ R06, R07) |
| **Hardware/electronics** (`03`) | Are the pins, voltages, and currents right on paper? | Pin maps consistent and electrically sound; the real risks are bench-only classics: boot-window floating pins, WS2812 level margin, Hall EMI (→ R04, R20, R18) |
| **Control firmware** (`04`) | Is the safety-critical code actually safe? | The layered safety chain was traced end-to-end **and holds**; residual concerns are hardware-gated, not logic bugs (→ R09, R04) |
| **Soundlight firmware** (`05`) | Is the dual-core/audio design sound? | Cross-core contract "airtight"; dead-man real and boot-safe; this board has **no motion-safety role** — its failures are UX (→ R11, R22) |
| **Ground station** (`06`) | Can the viewer app mislead or fail its one job? | Genuinely viewer-only (verified); but the link-loss indicator was demo-only, and the packaged `.exe` would ship telemetry-disabled (→ R01, R03) |
| **Protocols** (`07`) | Do the bytes agree on every wire, end to end? | Wire layer "unusually disciplined" — byte order verified on every pair; defects live at the *semantic* layer: gear counts 4/6/8, label drift, and the one open wire question, ELRS relay (→ R05, R19, R13) |
| **Simulation & tests** (`08`) | What do the green suites actually prove? | Pure-logic suites genuinely strong; but every `*_hal_esp32` file untested, and (at audit time) the Wokwi sim had **never actually been run** (→ R11, R16) |
| **Build/deploy** (`09`) | Will it build tomorrow, on another machine, into the thing that ships? | One latent time-bomb (unpinned platform + an API removed in newer cores) and CI that tests everything *except* the two deliverables: the bench firmware and the `.exe` (→ R02, R17) |
| **Runtime safety** (merged into the above) | Can anything move the car wrongly? | The strongest area: failsafe→arm-gate→boot-arm chain verified sound; residual risk is hardware configuration truths (ESC mode, endpoints, brownout) |

The lesson in the shape of this list: **"is the code correct?" is only one of ten
questions.** A hobby project fails on gear-label mismatches, unpinned toolchains, and
unshared COM ports at least as often as on logic bugs.

## 4. The risk register — the audit's key deliverable

A **risk register** is a numbered, ranked list of everything that could still go wrong,
each entry carrying: severity, confidence, a verification verdict, whether hardware is
required to close it, and when to fix it. This project's has **22 entries (R01–R22): 4
High, 13 Medium, 5 Low**, plus ~30 carried low findings [C] `10_risk_register.md`.
The IDs are stable — repo commit messages and CI job names reference them.

The four Highs, in beginner terms:

- **R01 — the HUD's link-loss alarm could never fire on the real path.** The HUD keyed
  "LINK LOST" off `armed`/`failsafe` telemetry fields **the car never transmits** — only
  the demo replay source fills them. On a genuine link loss the serial goes silent and the
  HUD showed "Telemetry: sim" while continuing to animate — a live-looking display at the
  exact moment a warning was needed. Crucially [C]: this is an *expectations/display* gap,
  **not** a vehicle-safety defect — the ground station is viewer-only and the car's own
  failsafe is independent and verified sound.
- **R02 — the build worked by luck.** Control-fw's `platformio.ini` pinned no platform
  version while its LEDC HAL uses the channel API **removed in Arduino-ESP32 core 3.x**.
  It built only because the unpinned platform *currently* resolves to 7.0.1/core 2.0.17.
  A future platform release would have broken the gift build on a fresh checkout —
  "potentially days before the deadline." *Latent, not live* — the exemplary contrast
  being soundlight's own `~7.0.1` pin (chapter 11 §7).
- **R03 — the shippable `.exe` was broken in a way the graceful degrade hides.** The
  Windows build never rebuilt the native `serialport` module for Electron's ABI (the
  referenced `app:rebuild` script **did not exist**), so the packaged app would silently
  run telemetry-disabled — and green CI proved nothing because CI never packaged the app.
- **R04 — the one High that touches the vehicle, and it is hardware-gated.** From reset
  until `escPwm.begin()` runs in `setup()`, the ESC signal pin (GPIO14) floats undriven
  for tens of milliseconds. Whether a powered QuicRun misreads that float is **only
  provable with an oscilloscope** (plan B1.4). Software got a micro-mitigation (§6/F1);
  the definitive answer stays on the bench.

Worth equal attention: **R21 (REFUTED)** — the register keeps the refuted finding, marked
as such, instead of deleting it. And **R22 (accepted trade-off)** — board #2 breathing
calmly forever when board #1 never connects was judged intentional and benign. A good
register records *decisions about* risks, not just risks.

## 5. From findings to fixes: the owner triage

The audit **deliberately changed nothing** — "fix-approval triage, not automatic fixes"
[C] `00_review_summary.md`. Every register item was classified in
`fix_approval_triage.md` into: *approve-now software* / *owner decision required* /
*hardware-validation only* / *defer* / *reject*. The owner then locked in the decisions
(2026-07-07) [C] `12_recommended_fixes.md`:

- **R01 → Option A**: derive link-loss on the ground from LQ + staleness; the car
  transmits nothing new. (The alternative — encoding real armed/failsafe into the
  FLIGHTMODE string — was declined.)
- **R05 → 4 gears everywhere** — the firmware (the physical authority) wins over the
  protocol doc's 6 and the HUD's 8.
- **R19 → TRAINING / RACE / ERS labels everywhere** — the HUD's user-facing names win;
  naming-only.
- **R06 → CI drift-guard**, not a git submodule — cheap, keeps repos independent.
- **R10 → no console-tunable steering endpoints** before the bench; edit+reflash accepted.
- **R04 → software micro-mitigation only**; the pull-down/RC decision stays bench-gated.
- **R21 rejected** (refuted) · **R22 accepted** as designed — no fix.

Teaching point: several items needed a *decision* before any code was possible. "Which
gear count is true?" is not a bug — it's an authority question only the owner can answer.

## 6. The four fix batches, F1–F4

The approved fixes were implemented as four batches — each independently buildable,
testable, committable, and revertible, one commit per touched repo, full test suites
before every commit [C] `12_recommended_fixes.md`, `review_progress.md`. All four were
**committed, pushed, and CI-green by 2026-07-08** [C] (control `b9cdac5`→`8ce670a`,
soundlight `74b59f4`/`f175bce`, ground `b880be6`→`b6d00f6`).

### F1 — Pre-power reproducibility (control-fw)

- **Pinned the platform** (`espressif32 @ ~7.0.1`) with a comment mirroring soundlight's —
  closes R02. Verified: still resolves to 7.0.1/core 2.0.17; 147/147; all three envs build.
- **Reordered `setup()`** so all five PWM `begin()` calls (and their safe initial
  commands) run *first*, before the UART/ADC/Hall begins — shrinking R04's float window
  by four `begin()` calls. A pure reorder; the audit-approved contingency ("if any hidden
  dependency is found — stop and report") was not triggered [C] `review_progress.md`.
- **CI now builds `esp32dev_tuning`** (R17a) — the env D8 actually flashes for the whole
  bench bring-up could previously rot undetected. *(This is the change that ended the
  two repos' `ci.yml` byte-identity that batch S5 had verified — see chapter 11 §7 and
  open question #46.)*
- **Docs hygiene**: the stale D8 "gimbal decoded, unwired" line fixed; a new control-fw
  `README.md` with per-OS flash commands and the bold **"the gift ships plain `esp32dev`
  — never `_sim`/`_tuning`"** warning (mirrored in this manual's chapter 11 §3).

### F2 — Ground-station packaging + telemetry truthfulness

- **Wired the serialport rebuild** (R03): a real `app:rebuild` script chained into
  `build`. *Honest implementation note kept in the record [C]:* during validation it
  turned out electron-builder 24 **also** auto-rebuilds native deps at package time, so
  R03's "ships unbuilt" was **partially overstated** — the explicit chain remains
  valuable for the dev-run path, CI proof, and belt-and-suspenders. Even fixes get the
  skeptical treatment.
- **Honest link-loss display** (R01 Option A): a new pure module `shared/linkState.mjs`
  implements the four-state model — **sim / live / LINK LOST / TELEMETRY LOST** — driven
  by link quality and staleness, with its own test file (9 tests, including the demo's
  LQ=0 window and sticky staleness). The HUD now holds last real values *dimmed* instead
  of silently resuming simulation. Chapter 08 §3 describes the states; the glossary has
  the entry. `TELEMETRY.md` now marks `armed`/`failsafe` as demo-only.
- **CI packaging smoke** (R17b): a `windows-latest` job packages the app
  (`electron-builder --dir`) so the deliverable is finally exercised by CI.

### F3 — Protocol agreement + drift guards

- **Shared CRSF golden fixture** (R07): `test/fixtures/crsf_golden.json` in the ground
  station — exact on-wire hex for BATTERY (7.9 V/72 %), GPS (36.1 km/h), FLIGHTMODE
  ("G3 M2 E55"), LINK_STATISTICS — loaded by the JS tests (+9 cases), with the
  overstating `crsf.js` "golden vectors are reused" comment corrected and a traceability
  comment added firmware-side. The C++↔JS agreement is now machine-pinned, not
  human-remembered.
- **link2 CI drift-guard** (R06): both firmware repos' CI gained a job that clones the
  sibling repo and **fails if the four link2 contract files differ**. A deliberate
  protocol change now requires pushing both repos back-to-back — a brief red on one side
  is expected and desired [C]. (This is the second reason the two `ci.yml` files are no
  longer byte-identical.)

### F4 — Owner-decision alignment: gears + labels

- **4 gears everywhere** (R05): ground `FEEL.gears` 8→4, demo timeline clamped to ≤4
  (with its test expectations updated), and the link2 protocol doc's "1…6" → "1…4"
  **identically in both firmware repos** — made *after* F3.2 so the new drift guard
  polices the paired edit.
- **TRAINING / RACE / ERS** (R19): comment/doc alignment in both repos' protocol doc and
  `Link2Frame.hpp`, control's `ChannelDecoder.hpp` and `main.cpp` comments — verified
  **comment-only** (no code token changed, no wire change, no enum renamed) [C]
  `review_progress.md`. Chapter 09 §2.2's table and the glossary already carry the
  canonical labels.

**Evidence class for all of F1–F4 [C]:** source diffs, full native suites (147/147,
40/40, ground 39/39 after the fixture additions), all builds, CI green including the
three new gates. **What F1–F4 are NOT:** hardware proof. Not one of the four batches
moved anything from "software-verified" to "bench-verified" — by design, none of them
could.

### One software-simulation gate did close: A1.6

Separate from F1–F4 but part of the same audit close-out: on 2026-07-08 the owner ran
the control-fw **Wokwi simulation end-to-end for the first time** (plan item A1.6 — at
audit time its checklist boxes were all unchecked, meaning chapter 11 §5's Stage-2 story
rested on an *unexecuted* sim). Verdict **PASS-with-note** [C]
`_verification_results.md` ("A1.6 closure"): the 420,000-baud loopback decoded, DRIVING
was reached with `failsafe=0 armed=1`, both failsafe demonstrations dropped correctly,
the ArmGate held, and a clean second cycle ran. The note: the battery pot/ADC preset
behaved oddly at boot, so **the battery ADC path is explicitly *not* validated by the
run** and stays a bench item. The scope statement is a model of evidence honesty — it
lists what the pass does *not* prove (real ADC, PWM on silicon, ESC, Hall, I2S, WS2812).

## 7. What remains hardware-gated — and what a gate is

A **validation gate** is a rule of the form "activity X is forbidden until check Y has
passed and been recorded." Gates are how the project keeps *confidence* from quietly
being treated as *proof*. The audit's `11_hardware_validation_plan.md` organizes ~63
bench items into three phases, complementing the firmware's own D8 runbook:

- **Phase A — before powering anything**: the software items A1.1–A1.6 are **complete**
  [C] (A1.1/A1.2 were F1/F2; A1.3 was F4; A1.4 was R17; A1.5 was the R01 decision; A1.6
  was the Wokwi run). The physical half, **A2** (multimeter-only: pin continuity vs
  PinMap, ESC BEC red-wire isolation, common ground, WS2812 level path, the pull-down
  decision), exists as a committed step-by-step checklist
  (`project-review/13_phase_a_a2_no_power_checklist.md`) but **has NOT been executed —
  no measurements are recorded, A2 is not closed** [C] `../CURRENT_STATUS.md`.
- **Phase B — first power, logic only** (ESC motor power still disconnected) is
  **BLOCKED** until A2 is filled in, reviewed, and approved. Its core is the live safety
  chain: no-CRSF-safe, arm-into-throttle blocked, fresh-neutral rearm, the boot-float
  scope check (R04), link2 on the real wire (R06's on-wire proof), I2S + WS2812
  coexistence (R11).
- **Phase C — later**: motor-connected tests (brownout coast, Hall EMI at load, battery
  calibration) and the ground-side chain (camera codec CG1, COM-port sharing CG2, **ELRS
  relay CG3 — the single most important telemetry bench question**, live JS decode CG4,
  a real link drop observed on the HUD CG5, live gear/label sweep CG6).

Still open, by register ID [C]: **R04** (boot float + pull-down decision), **R08** (pin
continuity), **R09** (ESC arm-hold + forward/brake mode), **R10** (steering endpoints),
**R11** (all `*_hal_esp32` bring-up), **R12** (brownout coast), **R13** (ELRS relay),
**R14** (FT232 COM sharing), **R15** (camera codec), **R18** (Hall EMI), **R20** (WS2812
level), plus **CG5** (does the fixed HUD actually show LINK LOST on a real drop). If it
is in this list, no file in any repo — and no chapter of this manual — is entitled to
claim it works.

The audit also names the **unknown-unknowns** — hardware truths the code *assumes* and
cannot test at all: ELRS relaying `0xC8`-addressed frames, the QuicRun's arming and
signal-loss behavior, LEDC's true 16-bit @ 50 Hz on silicon, the camera's codec,
shared-rail power integrity, real Hall EMI [C] `11_hardware_validation_plan.md`. These
are the audit's candidates for "what bites first on the bench."

*(Related but separate: the iPhone-bridge work (W1–W3) that landed in the ground station
after the audit is **not** part of F1–F4 and is not covered here — its real-device
validation is still pending, tracked as open question #58, and it will get its own
chapter. The iPhone/pan-tilt safety boundary itself is unchanged: firmware stays
iPhone-unaware, W3 is log-only.)*

## 8. Where the audit already touched this manual

The F-batches updated the manual as they landed, so several chapters carry audit results
inline. This chapter is the story that connects them:

- **Chapter 08 §3** — the four HUD link states (`shared/linkState.mjs`, F2/R01).
- **Chapter 09 §2.2** — the link2 table's gear range 1…4 and TRAINING/RACE/ERS labels
  (F4/R05/R19).
- **Chapter 11 §3** — the "gift ships plain `esp32dev`" flash warning (F1 hygiene).
- **Chapter 11 §7** — the pinned platform, the tuning-env CI build, and the end of the
  two repos' `ci.yml` byte-identity (F1/R02, F1/R17a, F3/R06).
- **Glossary** — *HUD link states*, the drive-mode canonical-label note (R19), and this
  chapter's new entries (*skeptical audit*, *risk register*, *validation gate*, *drift
  guard*).
- **`open_questions.md` #46** — the post-S5 `ci.yml` divergence note (F1/F3).

## 9. Confirmed vs inferred

**Confirmed [C]:** the audit's method, baseline, dimension verdicts, all R## contents
and verdicts, the owner decisions, the F1–F4 change lists with their validation evidence
and commit hashes, the A1.6 result and its scope statement, and the A2/Phase-B gate
state — all from the `project-review/` files (primarily `00_review_summary.md`,
`_verification_results.md`, `10_risk_register.md`, `fix_approval_triage.md`,
`12_recommended_fixes.md`, `review_progress.md`, `11_hardware_validation_plan.md`) and
`../CURRENT_STATUS.md`. The ended `ci.yml` byte-identity and the intact link2 copies were
independently re-verified by this manual on 2026-07-09 (diff/md5).

**Inferred [I]:** the pedagogical framings — "confidence vs proof," "ten questions,"
"decisions vs fixes," and the claim that R21's refutation is the most instructive entry —
are this manual's synthesis of the documents, not statements the documents make.

**Assumed [A]:** nothing in this chapter should be assumed-and-unstated; where a fact is
bench-pending it is listed in §7 as bench-pending. The chapter's one standing assumption
is inherited from the whole manual: descriptions of hardware behavior remain "as
designed," not "as built," until the gates close.

## Questions to check your understanding

1. The project had 208 green tests across the three repos before the audit (147 + 40
   firmware, 21 ground) — and the audit still found four High risks. Name the two failure classes (§1.1) those tests structurally cannot
   catch, and give one R## example of each.
2. What is the difference between a CONFIRMED and a PLAUSIBLE verdict in the register?
   Why does R04 carry *both*?
3. R21 was refuted during verification. Reconstruct what the original claim was, what the
   re-check found, and why keeping a refuted finding in the register is better than
   deleting it.
4. Why did R05 (gear count) require an *owner decision* before any fix could be written,
   while R02 (platform pin) did not?
5. Batch F4 was deliberately implemented *after* F3.2. What does that ordering buy?
   (Hint: which new CI job polices F4's paired doc edits?)
6. The F2 record notes that electron-builder 24 auto-rebuilds native deps, making R03
   "partially overstated." Why was the explicit `app:rebuild` chain kept anyway — and
   what does this episode teach about fixes in general?
7. The A1.6 Wokwi run passed. List three things its own scope statement says it does
   *not* prove, and name the gate that must close before any powered bench work (Phase B)
   may start.
8. A friend reads chapter 06 and says "the failsafe chain is proven." Using §4's R-list
   and §7's gate list, give the precise, honest version of that sentence.
