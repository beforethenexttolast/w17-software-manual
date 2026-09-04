# W17 handover checklist

**Purpose:** the single day-of checklist for the moment everything else in the readiness program
converges — car built, bench-proven, ground side installed, booklet printed — and Silberpfeil
goes to Lola. This file has no gate token of its own beyond **HANDOVER**
(`w17-parts-to-gift-master-sequence.md` stage 16); everything on it is a closing check against
work that happened elsewhere, cited by path, never re-derived here.

**Status: nothing on this list can be checked off yet.** A2 is NOT-EXECUTED, Phase B is BLOCKED,
and the ground-side code blockers in the master sequence's §0 are open. This file exists so the
day it *can* be run, nobody has to reconstruct what "done" means from six other documents under
time pressure.

**Rule for using this list:** every item is either a fact you observe and date-stamp, or a
pointer to the document that is the actual source of truth. Do not fill in a value here that
should live in `CURRENT_STATUS.md`, the booklet, or a settings field — write it there, then check
the box here.

---

## 1. Firmware — the exact image that shipped

- [ ] **Ship-image decision recorded.** `w17-parts-to-gift-master-sequence.md` stage 8,
  `OWNER-DECISION(SHIP-IMAGE)`: plain `esp32dev` (no tuning console, no BT/strap code) or
  `esp32dev_btshowoff` (adds the SP3T boot-mode selector + Bluetooth "quick show off" mode,
  gated on its own BT1 bench pass, `w17-control-fw/docs/BT1_BENCH_GATE.md` — being written).
  Record the choice and the commit hash flashed in `CURRENT_STATUS.md`.
- [ ] **ELF spot-check re-run and recorded** on the exact binary that shipped (D8 Phase 11a step
  7): `xtensa-esp32-elf-nm -C .pio/build/esp32dev/firmware.elf | grep -c -E
  "console::|btpad|luepad|btstack"` prints `0` for a plain `esp32dev` ship — if
  `esp32dev_btshowoff` shipped instead, record that this check does **not** apply and cite the
  BT1 gate's own evidence instead.
- [ ] **Calibration values recorded** — the D8 Phase 11a `get` readback (`steer.min`/`max`,
  `steer.center`/`trim`, `batt.ppt`, per-gear `max`/`expo`) is the authoritative record of what
  this specific car shipped with. Copy them into `CURRENT_STATUS.md`, not just this checklist.
- [ ] **Safe-state checks re-confirmed on the delivery firmware** (D8 Phase 11a step 9): TX-off
  boot sits in failsafe; arm gate holds neutral until arm-ON + fresh neutral; mid-run TX-off →
  failsafe; **after a failsafe episode, the car stays disarmed even with the arm switch left ON —
  re-arm requires the switch observed OFF then ON again on a proven link, plus a fresh neutral
  throttle reading** (the invariant, not D8's own step-9 wording, which predates it:
  `w17-control-fw/lib/channels/src/ArmGate.cpp:13-28`,
  `w17-control-fw/lib/channels/include/channels/ArmGate.hpp:48-59`, OWNER-RATIFIED 2026-08-20 —
  see §8 below, which drills this exact behavior on the finished car). These are the same Phase 5
  checks, re-run because tuning calibration must not have changed safety behavior.
- [ ] **SP3T boot-mode selector physically in DRIVE (center position)** before the car leaves the
  bench — regardless of which image shipped. Center = LAPTOP/Drive on both pins' internal
  pull-ups (`w17-control-fw/lib/config/include/config/PinMap.hpp`); any ambiguous reading also
  fails safe to Drive, but there is no reason to rely on that fallback at handover — verify the
  physical switch position by eye. If `esp32dev` (plain) shipped, the switch reads nothing in
  firmware at all and this line is a physical/mechanical check only (don't ship it in an odd
  position that looks wrong to Lola).

## 2. Sound + light tuning

- [ ] **Voice / volume set-and-forget** (booklet §6, owner decision 2026-08-20: "a good level out
  of the box, no volume controls taught"). Confirm the shipped `w17-soundlight-fw` tune is at the
  level the owner wants heard on handover day — this is the one deliberately owner-only tuning
  knob the booklet mentions (`2026-09-02_readiness_program.md` §3 workstream 6, "optional
  shipped-tune compile pin (sl idle/max rpm)").
- [ ] **Gimbal decay tunable confirmed** (`gimbal.decay`, default 2000 ms full-deflection-to-
  center — `w17-control-fw/lib/failsafe/include/failsafe/GimbalDecay.hpp:23`, not CLAUDE.md) —
  matches the on-car feel from D8 Phase 7b; re-check after any late re-tune.
- [ ] **Drive-mode switch physically in TRAINING (detent 0)** before handover — matches the
  booklet's race-trim story (booklet §3 step 7, §6): TRAINING is day-one truth, the gear blip /
  rain light / boost whine are framed as unlockable "race trim." Drive mode is a **live 3-position
  switch on channel 13** (D8 Phase 4), not a firmware-shipped default — verify the physical
  position by eye, the same way §1 verifies the SP3T selector. The three positions are **TRAINING
  / GEARBOX / ERS** (`w17-control-fw/docs/D8_BENCH_BRINGUP.md:72`) — there is no "RACE" mode.

## 3. Ground station settings

- [ ] **START LIGHTS switched ON.** `startLightsEnabled` defaults to **false**
  (`w17-ground-station/shared/settings.js`) — the booklet's section-3 five-red-lights moment does
  not happen without this being flipped on in the ⚙ menu. This is the one handover item the
  booklet itself calls out by name (`learning-manual/14_glovebox_owners_booklet.md:291-294`).
  **Verify it is ON, not just that you clicked it once** — confirm on a fresh relaunch that the
  toggle held.
- [ ] **Video profile set** (`shared/videoProfiles.mjs` profile ids `drive` / `showpiece`) — pick
  the one that matches how the car will actually be shown at handover and record which.
- [ ] **Hotspot name and password copied into the booklet's printed blanks** (or into whatever
  final artifact replaces the booklet's `[TBD-at-bench]` Wi-Fi markers) — the values you set in
  `w17-giftee-pc-install-guide.md` §5.1, not re-typed from memory.
- [ ] **RACE DAY fields point at the real, final install paths** (`w17-giftee-pc-install-guide.md`
  §5.3 `setMapperPath` / `setProfilePath`) — re-verify after any late reinstall. Two distinct
  failures show on the race-day card, neither silent: an **unset** path reads "its location is not
  set — set it once in ⚙ (RACE DAY)" (`not-configured`,
  `w17-ground-station/main/raceDayOrchestrator.js:247`); a **typo'd or relative** path reads "the
  saved controller setup location looks wrong — fix it in ⚙ (RACE DAY)" (`bad-profile-path`,
  same file:60-69) — both are plain-language reasons rendered by
  `w17-ground-station/shared/raceDayView.mjs:66-68`, not a blank or generic failure.
- [ ] **Code blockers closed** — do not check off this whole section until every id in
  `w17-parts-to-gift-master-sequence.md` §0's table shows closed in `CURRENT_STATUS.md`. The
  derivation rule: **every `gift_blocking:true` finding in the 2026-09-02 v2 review reports, plus
  `MAP-8` by orchestrator escalation pending the owner's ruling on its disputed worst case** — 14
  ids total (`MAP-1`, `MAP-2`/`SYN-2`, `MAP-3`, `MAP-4`, `MAP-5`, `MAP-6`, `MAP-9`, `SYN-1`,
  `boundaries-1`, `correctness-2`, `correctness-4`, `giftee-ux-2`, `giftee-ux-5`, `MAP-8`).

## 4. Mapper profile

- [ ] **Both placeholders filled with values read off the actual giftee PC**
  (`w17-giftee-pc-install-guide.md` §5.3): `REPLACE-WITH-DS4-ID` and `REPLACE-WITH-COM-PORT` in
  the deployed `w17-ds4.json` — not copied from the owner's bench profile.
- [ ] **`"w17_profile": true` present inside the `config` object** of the deployed `w17-ds4.json`
  — not merely somewhere in the file: the headless bring-up unwraps the document and sends only
  the inner `config` object onward, so a marker outside it never reaches the check
  (`w17-mapper/pkg/config/profile_document.go:97-101`). This marker is what switches on every
  arm-chain rule that stops the car re-arming itself after a controller dropout
  (`w17-mapper/pkg/config/lint.go:208-209`) — an unmarked copy gets none of them. **Race day now
  refuses to start on an unmarked profile:** pointing `-config-file-path` at a copy without the
  marker is refused at bring-up with one plain sentence, before `SetConfig` and before the radio
  link starts (`w17-mapper/pkg/client/grpc_client.go:154-159`;
  `w17-mapper/pkg/config/profile_document.go:144-153`) — the failure mode is now "the car says why
  it won't start," not "the car starts unprotected." **Cost to know:** this also means the mapper
  binary can no longer start an unmarked upstream rig's config from the command line this way —
  those configs still load fine in the mapper's own web editor, which stays permissive by design
  (`w17-mapper/FORK-NOTICE.md:82`). Confirm the marker is present and unedited before every
  handover.
- [ ] **Lint clean on the deployed copy.** The committed repo copy is test-pinned
  (`w17-mapper/pkg/config/w17_profile_test.go`), but the deployed, hand-edited copy on the
  giftee's PC escapes that pin — it is per-PC and per-bus (`MAP-9`) and its shape isn't asserted
  by anything but the test file (`MAP-12`; `w17-mapper/configs/README.md` itself carries neither
  id — those are review-tracked, not doc-cited). `(config-lint)` is a **line the mapper writes to
  its own log**, not something the web UI displays (`w17-mapper/configs/README.md:20-21`) — after
  editing, run the mapper from a terminal once more and read its console output for that line.
  **Zero findings there is weak evidence, not proof:** the lint checks endpoint bands and switch
  failsafe rails, but today it checks neither an unfilled `REPLACE-WITH-*` placeholder (`MAP-5`)
  nor the arm-chain shape that actually prevents a silent re-arm (`MAP-12`) — a clean log does not
  mean the deployed profile is correct, only that it passed what the linter currently looks for.
- [ ] **Reserved inputs still unbound.** Confirm SHARE/OPTIONS/D-pad-DOWN carry no binding on the
  deployed copy (`w17-mapper/configs/README.md` "Reserved inputs — do not bind") — these are held
  for the gated head-tracking milestone, not available for accidental reuse.

## 5. iPhone HUD

- [ ] **App installed on Lola's phone** via the free-account sideload
  (`w17-parts-to-gift-master-sequence.md` stage 14; procedure:
  `iPhone_rc/docs/GIFTEE_INSTALL.md`, being written).
- [ ] **Re-sign date recorded** in this checklist's own log (add the date below) — the app expires
  roughly 7 days after signing and must be re-signed from the owner's Mac
  (`2026-09-02_readiness_program.md` §1 row A2).
- [ ] **Standing reminder scheduled** (calendar or equivalent) for the owner to re-sign before
  each 7-day window lapses. This is a recurring pit-crew task forever, not a handover-day
  one-off — do not check this box as "done," check it as "the reminder exists."
- [ ] **Booklet's phone-HUD honesty line present** (booklet §4, "her app on your phone") reflects
  that the phone is a display-only extra and that it is set up and maintained by the pit crew —
  confirm the printed booklet still says this after any late edit.

Re-sign log (append, do not overwrite):

| Date signed | Signed by | Expires (≈7 days) |
|---|---|---|
| | | |

## 6. Booklet

- [ ] **Every `[TBD-at-bench]` marker resolved** in
  `learning-manual/14_glovebox_owners_booklet.md` (21 genuine markers as of the 2026-08-21
  adversarial review) — zero remaining before printing.
- [ ] **One-press-vs-three-press wording resolved** (`giftee-ux-3` in the 2026-09-02 grand
  review): the booklet currently promises one press; the shipped app needs RACE DAY → STRAIGHT TO
  THE GRID → START. This is an owner-gated product decision (fix the code to auto-advance, fix
  the booklet's wording, or both) — do not print until it is resolved one way or the other.
- [ ] **Every value in the booklet traces to a real source**, listed here so a reviewer doesn't
  have to hunt for it:
  - Hotspot name/password → §3 of this checklist / `w17-giftee-pc-install-guide.md` §5.1.
  - Charge time, drive time per charge, charger wattage, key/flap locations, controller pairing
    method, restart-ritual feel, lift points, part-charge storage guidance → D8 bench bring-up
    (§Phase 6–8) and the owner's own hands-on time with the finished car; none of these are
    inventable, all are `[TBD-at-bench]` in the booklet until observed.
  - Rear-wing tell, charge-light meanings, quick-show/shelf-show switch ritual → the finished
    car's actual sound/light behavior, confirmed on the bench, not from this program's docs.
- [ ] **Print run ordered/confirmed** only after the two boxes above are both checked.

## 7. Physical kit

- [ ] **Spare battery pack present** (if the owner is shipping one) or explicitly decided against
  — record which; do not leave this ambiguous at handover.
- [ ] **Charger present**, USB-C, confirmed against whatever minimum-wattage figure the bench
  session settles on (booklet §2 `[TBD-at-bench]`).
- [ ] **The "ignition key" loop plug present**, plus a spare if one is decided (booklet §2, "the
  key" — `[TBD-at-bench]` whether a spare ships).
- [ ] **GCS box, DualShock controller, and this guide's install artifacts all physically in the
  kit** — cross-check against `w17-giftee-pc-install-guide.md` §1's contents table.

## 8. Live drill — the last thing you do before wrapping the box

Do this on the finished, mounted car, immediately before handover, not from memory of the bench
session weeks earlier:

- [ ] **Failsafe drill:** with the car armed and idling (wheels off ground or on a safe surface),
  power off the transmitter mid-"drive" → confirm throttle neutral, steering centers, DRS closes,
  halo goes to the amber safe-stop pattern (booklet §7 / D8 Phase 5, re-run once more here).
- [ ] **Re-arm drill, the actual invariant:** with the arm switch left ON through the outage,
  confirm the car does **NOT** re-arm on link recovery alone — the re-arm invariant
  (`w17-control-fw/lib/channels/include/channels/ArmGate.hpp`, OWNER-RATIFIED 2026-08-20) requires
  the switch to be seen OFF, then ON again, on a proven link, plus a fresh neutral throttle
  reading. Cycle the switch OFF→ON with the stick at neutral and confirm the car arms only then.
  This is exactly the booklet's §7 promise ("she deliberately won't move until you restart her
  engine") — prove it here, on the real car, one more time.
- [ ] **Handset backup bind confirmed live** (if the ELRS backup handset, stage 12 of the master
  sequence, is part of the gift kit): the failsafe drill above, repeated with the handset as the
  transmitter (`w17-elrs-backup-handset.md` §4 step 5).

## 9. The contact ritual

- [ ] **Pit-crew hotline framing delivered** — the booklet's contact line is deliberately
  channel-free ("Vitaliy — you know where to find me," booklet §9) per the owner's 2026-08-20
  decision; confirm no phone number or handle was accidentally printed anywhere in the final
  booklet or kit materials (`vitaliy-contact-info` memory note: never printed in giftee
  materials).
- [ ] **In-person handover moment planned** — how and when the car is actually given, and who
  walks Lola through booklet §3 (start routine) for the first time live, so the first drive is
  not unsupervised reading.

## 10. Post-gift pit-crew schedule

Record the recurring obligations that outlive handover day — these are not one-time boxes, they
are a standing schedule:

| Task | Cadence | Owner |
|---|---|---|
| Re-sign the iPhone app | ~7 days | the car's owner (Vitaliy), from his Mac |
| Check in on the car / answer questions | as needed | pit crew (contact ritual, §9) |
| Battery storage check-ins if unused for a month+ | as needed | pit crew (booklet §8) |
| Re-tune volume/rates on request | as needed | pit crew (booklet §6, "ping the pit crew") |

---

## Cross-references

- `w17-parts-to-gift-master-sequence.md` — stage 16 (this file is that stage in full); all
  gate tokens referenced above are defined there.
- `w17-giftee-pc-install-guide.md` — sources for §3–§4 of this checklist.
- `w17-elrs-backup-handset.md` — source for §8's handset drill line.
- `w17-control-fw/lib/channels/include/channels/ArmGate.hpp` — the re-arm invariant this
  checklist's live drill (§8) verifies.
- `learning-manual/14_glovebox_owners_booklet.md` — the artifact §6 closes out (read-only; this
  program does not edit `learning-manual/`).
- `CURRENT_STATUS.md` — record every dated fact this checklist produces there, not only here.
