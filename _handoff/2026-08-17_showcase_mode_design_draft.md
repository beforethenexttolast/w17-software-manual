> Rescued 2026-08-17 from the orchestration session scratchpad. DRAFT, owner unreviewed.
> Intended homes after the owner read: w17-control-fw + w17-soundlight-fw docs (split per repo).
> Non-canonical dated snapshot per _handoff convention. Decisions D1-D9 pend the owner.

# Showcase mode — design draft (owner review required)

**Status: DESIGN ONLY — no code, no branch, nothing scheduled.** Commissioned against
vision decision 2 (`W17_PRODUCT_VISION.md`): showcase mode is **core-if-cheap**, built in a
normal wave, **not** on the v1.0 done bar. Gating settled 2026-08-16. This draft settles the
audit's open mechanism question ("board-1 disarmed demo feed vs board-2 local trigger",
`W17_PRODUCT_VISION.md` backlog + Open points) and adds the third obvious candidate.

Repo state studied: `w17-control-fw` main @ `9f00f2e`; `w17-soundlight-fw` main @ `1c19260`
(wave-3 board-2 features merged: ignition halo animation, DRS tell, NeverConnected 5 s
grace → hazard); pending branches read in their scratchpad worktrees —
`feat/link2-v2-voice-volume` (`dfd0f23`, link2 v2 spec: soundProfile + volume),
`feat/link2-v2-consume` (`37ad050`), `proto/bt-showoff-flagged` (`138a674`,
`docs/bt_showoff_design.md`). Every firmware claim cites its file. A2 stays NOT-EXECUTED,
Phase B stays BLOCKED (`CURRENT_STATUS.md`); nothing here changes any gate.

---

## 1. Purpose & giftee story

**What it is (vision decision 2):** a stationary demo — lights + engine sound + live
camera, drive disarmed — reachable by the non-hobbyist giftee without a hobbyist ritual:
"look at her" on a shelf or table. The operator model gives it teeth: *"Showcase mode
reachable without expertise; a no-laptop variant needs design care so failsafe indication
stays unambiguous"* (`W17_PRODUCT_VISION.md`, operator model).

### Scene 1 — shelf demo, no laptop

The giftee lifts the engine cover, slides the mode selector to **SHOW**, and inserts the
XT90 loop key (the labeled "ignition key", operator model). Within a couple of seconds the
halo runs the starter-comet sweep, flashes the "engine catches" moment (the wave-3 ignition
animation, `w17-soundlight-fw/lib/lights/LightRenderer.hpp` ignition block), and settles
into a slow showcase breathe with the tail lamps glowing. The V10 cranks (600 ms starter
whir, `lib/enginesim/include/enginesim/EngineSim.hpp` `crankMs`) and falls into an idle
burble with the existing idle wobble, plus an occasional gentle blip — curated, seeded,
never a screaming rev. **No video** — there is no laptop, so nothing hosts the hotspot the
camera joins and nothing consumes the stream (`W17_PRODUCT_VISION.md` decision 7: camera →
mediamtx → GS; gift kit: the hotspot adapter lives in the GCS box). The wheels never move:
throttle authority is structurally off (§3). Key out ends it. If the pack runs low first,
the show ends itself and the halo pulses red — the booklet line is "she's asking for the
charger."

### Scene 2 — table demo, laptop + camera

Selector to **SHOW**, key in, and the giftee also runs the normal one-action ground-station
bring-up (GCS box + installer, operator model) — but never arms. Everything from scene 1,
plus: the camera joins the hotspot and the cockpit view is live on the HUD; the right stick
aims the gimbal (pan/tilt is deliberately not safety-gated — `w17-control-fw/src/main.cpp`
"aiming the camera is harmless armed or disarmed"); the steering stick turns the front
wheels and blinks the indicators (steering is live while disarmed by existing design —
`docs/link2_protocol.md` byte 2, and `src/main.cpp` "Steering stays live while disarmed").
Sound, lights, live camera, steerable wheels — and the throttle path is dead by
construction, not by restraint.

### Scene 3 — cold display, powered off

Key out. Nothing is lit, nothing drains: she is a static showpiece indefinitely — that is
the normal shelf state, and the booklet says so. (Charging in place via the hidden USB-C
flap shows the charge-state light and the hard charge/run interlock keeps the car
un-runnable while plugged — decision 13, separate feature; showcase adds nothing to it.)

---

## 2. The mechanism candidates

First, the two facts every candidate must answer to:

- **Engine sound today is keyed to `armed`.** The enginesim ignition state machine is
  "driven by the `armed` flag from board #1: Off = disarmed → silence; Cranking on armed
  0→1; Running after crankMs; failsafe (effective armed == false via the monitor) drops
  back to Off" (`w17-soundlight-fw/lib/enginesim/include/enginesim/EngineSim.hpp` lines
  9–14; enforced in `src/EngineSim.cpp`, `if (!state.armed) ignition_ = Off`). Volume
  follows ignition: Off → 0, Cranking → 70, Running → 90..255
  (`lib/audiodecision/include/audiodecision/AudioDecision.hpp` `synthVolumeFor`). **A
  disarmed car is a silent car** — the vision's "engine sound with drive disarmed" does
  not exist today under any input.
- **The receiver's honesty mandate.** "No CRC-valid frame for 500 ms ⇒ local failsafe —
  engine to silence, hazard blink" is MANDATORY (`w17-soundlight-fw/CLAUDE.md`;
  `docs/link2_protocol.md` timing rule), and a link that has **never** delivered a frame
  breathes calmly for at most 5 s before escalating to the same hazard
  (`lib/lights/include/lights/LightRenderer.hpp` `neverConnectedGraceMs`, audit defect 9).

### The candidates

- **A1 — board-1 fictional demo feed** (the backlog wording taken literally): in showcase,
  board 1 scripts a pretend drive into the real frame — `armed=1`, burbling
  `throttlePercent` — while its outputs stay safe. Board 2 is **unchanged**.
- **A2 — board-1 showcase state, truthful feed + `showcase` flag** (refinement of A1):
  board 1 enters a deliberate boot-selected SHOWCASE state, keeps every existing field
  truthful (`armed=0`, real battery, real steering), sets a new `showcase` flag bit, and
  suppresses the drive-failsafe bit only where no drive link ever existed (§4). Board 2
  keys ignition to `armed || showcase` and runs a small curated idle script locally.
- **B — board-2 local trigger**: a button/GPIO on board 2 starts a local sound+light demo
  with no board-1 involvement — essentially compiling the `esp32dev_sim` bench feeder
  (`src/SimLink2Feeder.cpp`, today deliberately "compiled ONLY in [env:esp32dev_sim]; the
  whole module vanishes from the real firmware") into delivery.
- **C — no new mechanism**: define showcase as "powered, link up, deliberately unarmed"
  and curate only what that state already shows.

### Comparison

| | **A1 fictional feed** | **A2 truthful feed + flag (recommended)** | **B board-2 local trigger** | **C no mechanism** |
|---|---|---|---|---|
| Giftee does | selector→SHOW, key in | selector→SHOW, key in | key in + press a button on the car (new physical control) | key in **and** bring up a radio link (laptop chain or ELRS backup handset), don't arm |
| Board 1 | outputs safe; sends **fabricated** armed/throttle | outputs safe, arm input hard-pinned false; sends truthful state + `showcase` bit | not involved (may be absent/faulted — that's the problem) | unchanged |
| Board 2 | unchanged (sound rides the fiction) | ignition keys on `armed \|\| showcase`; small seeded idle script; showcase halo look | new trigger input + a demo player that must **override** the staleness mandate | unchanged |
| Engine sound | full fake drive | curated idle + gentle blips; crank/catch animation comes free (keyed to the real ignition machine) | scripted, even when board 1 is dead or faulted | **none** — `armed=0` ⇒ ignition Off ⇒ silence (EngineSim.cpp). Fails decision 2's own definition |
| Camera | laptop session only (hotspot + GS = the only consumer) | same | same | same |
| Lights | armed teal + fake activity — **shows an armed car that isn't** | distinct showcase look; hazard/low-battery overrides untouched | demo pattern with no relationship to vehicle truth | dim-white disarmed halo (`LightRenderer.cpp` `kDimWhite`), indicators on stick |
| Failsafe honesty | wire itself lies: `armed`/`throttlePercent` violate their documented semantics ("what the ESC is actually commanded", state matrix `docs/link2_protocol.md`); staleness→hazard still works | **fully honest**: every fault display preserved; hazard semantics unchanged (§4) | **broken by design**: playing a demo while frames are absent directly violates the 500 ms mandate and re-opens audit defect 9 (never-connected must escalate, not entertain) | honest but hazard-blinks the no-laptop shelf (no link ⇒ board-1 FSM Safe ⇒ `failsafe=1`), and silent everywhere |
| Protocol impact | none on paper, but the state matrix becomes false in showcase | one flag bit (ride the pending v2 — §5, decision D2) | none (that's the trap: board 2 stops *needing* board 1) | none |
| Native testability | fine | fine (pure resolver, script, renderer cases) | fine, but tests would pin dishonest behavior | n/a |
| Verdict | rejected — smallest diff, bought with a lie on the one wire that defines truth | **recommended** | **rejected** — violates the receiver's non-negotiable obligations (`w17-soundlight-fw/CLAUDE.md`) | rejected as *the* mechanism; it is the zero-cost fallback and the table-demo posture is subsumed by A2 |

---

## 3. Recommendation

**A2: showcase is a deliberate board-1 boot state, expressed over a truthful link2 frame
via one new `showcase` flag; board 2 owns the curated presentation.**

Rationale:

1. **The sound has to come from somewhere, and board 2 must stay obedient to the link.**
   C proves a no-code showcase is silent; B proves a board-2-only showcase must break the
   staleness mandate. The only honest place to *authorize* engine sound while disarmed is
   board 1 — the arbiter — over the existing 20 Hz frame, so every existing failure
   indication (500 ms staleness, NeverConnected grace, low-battery pulse) keeps working
   untouched.
2. **Truthful wire beats small diff.** A1's fiction re-defines `armed` and
   `throttlePercent` in exactly the document that exists to prevent drift. A2 costs one
   flag bit and a ~dozen-line board-2 script, and the state matrix stays true.
3. **Deliberate entry, boot-only, mirroring the BT precedent.** Showcase reuses the BT
   show-off doctrine (`docs/bt_showoff_design.md` §2, branch `proto/bt-showoff-flagged`):
   mode resolved **once** in `setup()`, no runtime switching, physical selector, fails
   toward the normal drive mode on any wiring fault. Auto-entry ("no link for N s ⇒ start
   the show") is **explicitly rejected**: a car that entertains when its radio died is the
   precise calm-pretty-lights-during-a-fault trap this design exists to exclude.
4. **Board 2 owns aesthetics, board 1 owns authority — same split as today.** The curated
   idle script is sound design; it belongs next to the synth profiles, not on the safety
   board. Board 1's whole diff is: read selector, pin the arm input false, set a bit,
   apply the failsafe-bit policy (§4).
5. **Is showcase just BT-mode-minus-driving? No.** BT show-off is *interactive close-range
   driving* on a quarantined Bluepad32 core with its own bench gate (BT1) and real RF/RAM
   risk (`bt_showoff_design.md` §4.3/§5/§9). Showcase is *stationary presentation*: no new
   stack, no RF, no new core — it fits the delivery build and the "core-if-cheap" budget.
   They should share the **physical boot selector and the doctrine, nothing else**
   (decision D3); showcase must never depend on the Bluepad32 env. If BT is approved the
   selector becomes 3-position (LAPTOP ◂ SHOW ▸ SOLO); if not, 2-position.

What board 1 does in SHOWCASE, concretely (all existing code paths, one pin, one bit):

- Full normal init; CRSF stack stays live (telemetry + gimbal + steering work when a link
  exists — scene 2). Failsafe FSM runs unchanged.
- `armGate.update(/*armSwitchOn=*/false, …)` — the decoded arm switch is structurally
  ignored, so `armed` can never assert, so `baseCommanded` is 0 by the existing line
  `(active && armed) ? modeShaped : 0` (`src/main.cpp`), so the ESC never leaves neutral.
  No new ESC/steering/DRS code; no scripted actuator motion of any kind (non-goal 4).
- `controlSnapshot.showcase = true`; `armed`/battery/steering/gear all stay truthful; the
  failsafe bit follows the §4 policy. The Safe branch already keeps link2 transmitting
  during failsafe ("that flag is its whole purpose", `src/main.cpp`) — unchanged.

What board 2 does on `showcase` (effective, post-staleness — the monitor zeroes the bit
when the link is not Up, same command-class treatment as `armed`,
`lib/link2monitor/src/Link2Monitor.cpp`):

- `enginesim`: ignition condition becomes `armed || showcase` — crank → catch → idle, the
  same machine, so the wave-3 ignition halo animation triggers for free.
- A small seeded showcase script (deterministic LFSR, house rule "Deterministic (seeded
  LFSR noise)" — `CLAUDE.md` soundsynth) supplies throttle to enginesim **locally**:
  mostly 0 (idle wobble already exists), occasional gentle blips ≤ ~30 %. The limiter
  (needs throttle ≥ 95) and overrun crackle (needs a 40-point drop from ≥ 60 % rpm,
  `EngineSim.cpp`) are unreachable by construction, not by tuning.
- `lights`: a showcase base-halo look distinct from solid armed teal, dim-white disarmed,
  and the halo-only NeverConnected grace breathe (decision D6). Compositor priority is
  untouched: DRS tell, brake, indicators, low-battery pulse and the hazard override all
  still outrank it (`LightRenderer.hpp` priority comment).
- Volume: the pending v2 `volume` byte already rides every frame and "scales sound only,
  never lights" (v2 spec byte 12) — showcase loudness is therefore already owner-tunable,
  and **volume 0 gives a silent, lights-only shelf mode for free** (decision D7).

---

## 4. Failsafe-honesty analysis — what the lights say in every failure during showcase

Design invariant, stated once: **amber hazard is reserved for real faults in every mode;
showcase never uses amber or red in its base look; nothing in showcase can mask an
override layer.** The one deliberate semantic choice needing owner sign-off is the
drive-failsafe bit (D4): in SHOWCASE boot mode there is no drive authority to lose, so
"link never existed" must not hazard the shelf — but "link existed and died" should still
be told. Recommended policy: `snapshot.failsafe = (FSM == Safe) && everLinkedThisBoot` —
the exact NeverConnected-vs-Lost distinction board 2 already applies to link2
(`lib/link2monitor/include/link2monitor/Link2Monitor.hpp`), applied one level up.

| # | State during showcase | What the bystander sees / hears | Honest? |
|---|---|---|---|
| 1 | Healthy shelf showcase (no CRSF ever this boot) | ignition sweep + catch, then showcase breathe + tail; idle burble. No hazard: nothing that matters is lost (throttle authority structurally off; battery honestly monitored) | yes — D4 policy |
| 2 | Healthy table showcase (CRSF up) | scene 1 + live steering/indicators/gimbal/camera | yes |
| 3 | CRSF was up, then lost mid-showcase | board 1 asserts `failsafe` (everLinked) ⇒ board 2 hazard blink + engine to silence (effective armed/showcase zeroed by the failsafe flag path). Recovers automatically when the link returns (FSM re-arm, 150 ms good) | yes — "something she had is gone" reads as exactly that |
| 4 | link2 wire cut / board-1 wedge mid-show | frames stop ⇒ monitor Lost at 500 ms ⇒ effective showcase bit zeroed (command-class) ⇒ ignition Off, silence; renderer hazard. The protocol mandate, untouched | yes |
| 5 | Board 2 powered, board 1 never comes up | calm breathe ≤ 5 s (`neverConnectedGraceMs`), then hazard — the wave-3 escalation, untouched. Note the grace breathe is bounded and halo-only; D6 keeps the showcase look visually distinct from it | yes |
| 6 | Board-2 control loop wedges mid-show | audio dead-man ramps to silence ≤ ~500 ms (`kAudioDeadmanMs`, `src/main.cpp` + `AudioDecision.hpp`); lights freeze — a frozen frame, never a *reassuring animated* lie | yes (same class as today) |
| 7 | Low battery mid-show | `lowBattery` is board-1's real, 3 s-qualified judgment in every mode (`docs/link2_protocol.md` byte 7–8 note) ⇒ red halo pulse overrides the showcase base; D5 recommends the show also ends (silence) so the pulse is unmissable. Warn-only invariant untouched — nothing here is traction power | yes |
| 8 | Giftee flips the handset arm switch during showcase | nothing: arm input pinned false; halo never shows the solid armed teal; ESC at neutral through the untouched gate + boot-arm chain (`lib/channels/include/channels/ArmGate.hpp`, `lib/outputs` ESC boot sequence) | yes — and un-hearable as "armed" because showcase sound ≠ armed lights |
| 9 | Line noise / corrupted frames | CRC rejects; sustained corruption is indistinguishable from silence ⇒ staleness ⇒ hazard (validation order, `docs/link2_protocol.md`) | yes |
| 10 | Selector mis-wired / strap floats | resolver fails toward LAPTOP/CRSF drive mode (BT §2.2-A pattern): the car is *less* entertaining, never *more* armed | yes |
| 11 | DRIVE boot, disarmed in the pits (not showcase) | unchanged today's behavior: dim-white halo, silence. The `arm = engine start` metaphor survives everywhere outside SHOW — no showcase leakage into drive sessions | yes |
| 12 | Charging | hard charge/run interlock (decision 13) keeps the car un-runnable; showcase adds nothing and claims nothing | out of scope |

Row 3 is the only place a *calmer* alternative exists (never assert failsafe in showcase);
it is rejected in the recommendation because it makes a dead radio invisible at the table,
and the cost of honesty is one boolean.

---

## 5. What each repo changes (minimal diff, native-first)

Ordering note: the `showcase` bit should ride the **pending, unflashed link2 v2 bump**
(`feat/link2-v2-voice-volume`, spec: 16-byte frame, soundProfile + volume) so the
"coordinated flash of both boards" happens **once**, not twice (v2 spec §v1→v2). That makes
showcase's protocol cost near-zero if D2 lands before v2 merges.

### w17-control-fw (protocol owner — changes land here first)

1. `docs/link2_protocol.md` + `lib/link2` (on the v2 branch, pre-merge): assign flags
   **bit7 = `showcase`** (or the D2 alternative byte); update `VehicleState`, encoder,
   golden-frame test (`test_golden_frame_bytes`) and the copy-check flow
   (`tools/link2_copy_check.sh`).
2. Boot-mode selector: a pure `strap level(s) → BootMode {DRIVE, SHOWCASE[, BTPAD]}`
   resolver — shared with `lib/btpad`'s `BootModeResolver` if the BT branch merges,
   otherwise its own ~30-line lib. Pin per BT-2's candidates (GPIO27/32/33), reconciled
   against `lib/config/include/config/PinMap.hpp` + the wiring atlas at implementation.
3. `src/main.cpp`: resolve mode once in `setup()`; in SHOWCASE — pin `armSwitchOn=false`
   into the existing `armGate.update` call, set `controlSnapshot.showcase`, apply the D4
   failsafe-bit policy (one `everLinked` boolean latched off the FSM). Everything else —
   failsafe timing, ESC boot-arm, steering-live-while-disarmed, gimbal, telemetry, link2
   cadence — byte-identical paths.
4. Native tests: resolver truth table (float ⇒ DRIVE); showcase-never-arms (gate fed
   false across arm-switch sequences); D4 policy table; encode/decode + golden variant.

### w17-soundlight-fw (consumer — after control-fw, per link2 ownership)

1. `lib/link2` verbatim re-sync (v2 + showcase bit) + its own wire tests; CI `link2-drift`
   job already enforces the copy.
2. `lib/link2monitor`: classify `showcase` as command-class in the Lost projection
   (zeroed), next to `armed` (`src/Link2Monitor.cpp` per-field table).
3. `lib/enginesim`: ignition condition `armed` → `armed || showcase` (one line + tests:
   showcase 0→1 cranks; staleness kills it; showcase+failsafe stays Off).
4. New pure `lib/showscript` (or an enginesim-adjacent module): seeded curated throttle
   pattern, active only when effective `showcase && !failsafe`; tests pin determinism and
   the envelope (throttle ≤ 30, limiter/overrun unreachable).
5. `lib/lights`: showcase base-halo branch in the base layer only (D6 look); tests:
   showcase+Lost ⇒ hazard, showcase+lowBattery ⇒ pulse wins, showcase never renders amber,
   distinct from the grace breathe.
6. `src/SimLink2Feeder.cpp` (`esp32dev_sim`): add a showcase phase to the 14 s script —
   the existing bench demo then proves the whole feature standalone, no hardware
   (`W17_PRODUCT_VISION.md` backlog: "esp32dev_sim already proves the sound/light half").

### w17-ground-station / learning-manual / booklet

- GS: **no required change** (viewer only). Optional later garnish: a "SHOWCASE" chip if
  the owner wants it surfaced; the CRSF FLIGHTMODE string (`"G%u M%u E%u"`) is out of
  scope for v0.
- Booklet/manual: the SHOW selector position, the light legend rows (showcase breathe;
  "hazard always means she needs attention"; red pulse = charger), and the honest line
  that video needs the ground-station kit.

### Gates

Everything above is native-testable; the sim env is the bench-free integration proof. No
new gate class is warranted (no RF, no new stack, no new power draw class) — first powered
showcase run is a normal Phase B bench item, **after** A2 closes; the strap pin joins the
A2 continuity-matrix scope question already tracked as F20 (same note as BT-2,
`docs/bt_showoff_design.md` §2.2). Nothing is flashed or powered before then.

---

## 6. Open owner decisions

| # | Decision | Recommendation |
|---|---|---|
| D1 | Mechanism: A1 fictional feed / **A2 truthful feed + flag** / B board-2 trigger / C nothing | **A2** (§3). B should be rejected on the record, so it stops reappearing |
| D2 | Wire encoding: fold `showcase` into the **pending** v2 as flags bit7, or append a `modeFlags` byte (length 13→14) carrying showcase + future bits | **bit7 in the pending v2** — v2 is unflashed, so it's free and keeps one coordinated flash. Note the collision: BT §6.3 proposed the same bit7 for `awaitingController` (DOC-ONLY, OWNER-PENDING BT-7); if both features are wanted, the appended-byte option serves both — decide jointly |
| D3 | Selector hardware: dedicated 2-position (LAPTOP/SHOW) vs shared 3-position with BT's SOLO (ties to BT-1/BT-2) | one physical selector for however many boot modes are adopted, center/float ⇒ LAPTOP; share the resolver code only if the BT branch merges — **showcase never depends on the Bluepad32 env/core** |
| D4 | Failsafe bit in showcase: never assert vs **assert only after a link existed this boot** | the latter — shelf never hazards, a dead table radio is still told (§4 rows 1/3) |
| D5 | Low battery mid-show: lights-only vs **end the show** (silence + red pulse) | end the show — unmissable, drains less, and touches no invariant (warn-only concerns traction power, which showcase never has) |
| D6 | Showcase halo look | slow teal-family breathe **with the dim red tail lit** — distinct from solid armed teal, dim-white disarmed, and the halo-only ≤ 5 s grace breathe; exact look is board-2 aesthetic territory, bench-tuned |
| D7 | Volume: reuse the single v2 `volume` (0 = silent lights-only showcase) vs a separate `sound.showcaseVolume` key | single knob for v0; add a showcase-specific level only if bench listening says shelf demos need to differ from drive volume |
| D8 | Script character: **gentle idle + rare ≤ 30 % blips** vs a richer show (gear shifts, high revs) | gentle v0 — limiter/crackle stay structurally unreachable; richer is a later tuning pass, gated on the owner actually hearing it |
| D9 | Steering + gimbal live in showcase when a CRSF link is up | **yes** — both reuse existing disarmed-safe behavior (`src/main.cpp`), and they make the table demo; shelf demo has no link so the point is moot there |

---

## 7. Explicit non-goals

1. **No board-2 local trigger, ever, in delivery firmware.** The `esp32dev_sim` feeder
   stays a bench tool that "vanishes from the real firmware" (`SimLink2Feeder.hpp`).
2. **No auto-entry.** Showcase is never inferred from link loss, boot timing, or "no
   handset found" — deliberate physical selection only. A fault must look like a fault.
3. **No runtime mode switching** in either direction; changing mode = key cycle (BT
   doctrine, `bt_showoff_design.md` §2.1).
4. **No scripted actuator motion**: ESC, steering, DRS and gimbal are never driven by the
   show (a "DRS flex" display was considered and dropped — it would make firmware produce
   an output from a non-arbitrated script, worth its own owner conversation if ever).
5. **No arm-gate, failsafe-timing, ESC-boot, or warn-only changes** — showcase pins an
   input to the existing gate; it does not add a parallel path.
6. **No video-path changes and no pretense of one**: the no-laptop showcase has no video,
   and the booklet says so plainly.
7. **No iPhone anything; no new RF; no BT dependency** (workspace boundaries 1–4 untouched;
   showcase is not BT-mode-minus-driving).
8. **No new hardware gate class and no bench work now** — native + sim only until A2 /
   Phase B open powered work; not on the v1.0 done bar (decision 2 gating).
9. **No GS features required** — the GS stays a viewer.
