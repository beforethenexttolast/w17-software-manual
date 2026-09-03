# W17 ELRS backup handset — requirements, model setup, binding

**Date:** 2026-08-17 · **Owner:** Claude Code (radio/firmware side). Procurement is the **owner's**
act — this doc defines requirements and setup; it orders nothing.
**Canonical:** this file at the workspace root is the **single source** for the backup-handset
requirements and model setup; no copies exist as of this date, and any future copy must name this
file as canonical in its own header (`WORKSPACE_MAP.md` canonical-vs-copy rule). **Docs only — no
hardware was touched or powered.** Binding and every verification step involving the real RP1 are
powered activities and stay behind the project's gates (attended sessions only; A2 / Phase B
discipline for anything touching the car harness — `w17-control-fw/CLAUDE.md`, hardware gates);
each such step below is marked `[bench-TBD]`.

---

## 1. Why a backup handset exists at all

Vision decision **12** (`W17_PRODUCT_VISION.md`, 2026-08-16 Q&A): *"Keep a plain ELRS handset bound
to the RP1 as backup (laptop-required main chain accepted)."* The backlog entry makes it work:
*"ELRS backup handset (12): procure, bind to RP1, document in the manual."*

What that buys, concretely:

- **Resilience.** The main chain is deliberately laptop-shaped: PC → mapper → FT232RL → ELRS TX
  module in the GCS box (`w17-gcs-box-guide.md`). Any single failure in it — dead laptop, installer
  trouble on the giftee PC, missing COM port, hub power fault — currently leaves the car a shelf
  piece. A bound handset is a control path with **zero PC dependencies**: handset on, car drives.
- **Guest driving** `[I — derived reading of decision 12's "no-laptop options" framing, not
  owner-verbatim]`: handing "here, try it" to a guest is a handset gesture, not a
  five-app bring-up; the FPV/HUD layer simply stays off.
- **Bench sanity tool.** During bring-up, a handset isolates "is the radio/firmware chain healthy?"
  from "is the PC chain healthy?" — one variable at a time.

The vision itself records the trade honestly: the BT show-off backlog entry notes that mode
*"dilutes 'Windows is the control authority' the same way the approved ELRS backup handset does —
acceptable per owner, gated per process."* The dilution is accepted **because the firmware, not the
transmitter, is the safety authority** — see §5.

**What is already owned:** a **RadioMaster TX16S** (`HARDWARE_INVENTORY.md` §2: *"Transmitters
(DualShock via PC + TX16S) — 🏠 owned"*; BOM §2: *"TX16S (bench/backup) — owned"*), and
`learning-manual/01_total_system_overview.md` §6 already names it *"RadioMaster TX16S handset as
backup transmitter (same bind phrase)"*. Two unresolved facts keep this doc from just saying "the
TX16S is the backup" `[TBD-owner-confirm ×2]`:

1. **Is the TX16S's internal RF module ExpressLRS?** BOM open confirmation #4, verbatim: *"TX16S
   internal module = ExpressLRS (EdgeTX → Model → Internal RF). If MULTI-only, move the ES24TX Pro
   to it for the backup role."* That fallback **collides with the gift kit** decided later
   (2026-08-16): the ES24TX now lives permanently in the GCS box, so a MULTI-only TX16S has no
   ELRS path without unboxing the kit — exactly what the *procured* plain handset resolves.
2. **Does the TX16S ship with the gift, or stay the owner's bench radio?** Decision 12 says
   "plain" handset and the backlog says "procure" — which reads as a giftee-side unit separate
   from the owner's TX16S `[I]` — but the vision text does not settle where the TX16S itself ends
   up.

Until both are answered, the working model is: **TX16S = owner-side interim backup (if its RF
allows), procured plain handset = the gift-kit backup this doc specifies.**

## 2. Requirements

### 2.1 Radio-level

| Req | Value | Source |
|---|---|---|
| Link | **ExpressLRS, 2.4 GHz** | The receiver is fixed: RadioMaster **RP1** (`HARDWARE_INVENTORY.md` §2, on hand, *"CRSF input source for w17-control-fw"*); ELRS is the recorded 2.4 GHz system (`learning-manual/01…` §4 step 2). A 900 MHz ELRS TX cannot bind to it. |
| ELRS version | **Same major version as the RP1's flashed firmware** (ELRS binds only within a major line) — the actual flashed versions of RP1 / ES24TX are **recorded nowhere** `[TBD-owner-confirm: read versions off both at the first bench session and record them in CURRENT_STATUS.md]` | generic ELRS binding rule + workspace search came up empty |
| Bind | Same **bind phrase** as the system (`learning-manual/01…` §6). The phrase itself is owner-private and never appears in a doc. | |
| Model match | Enabled, matching the RP1's stored model-match ID — §4. | vision 12: "bound to the RP1" |
| Channels | CRSF carries 16 channels regardless of handset; what matters is **physical controls** for the tier chosen in §2.3. | `w17-control-fw/lib/crsf` (16 × 11-bit, 172–1811, center 992) |
| Failsafe config | **None on the TX side.** Do not program RX "hold position" failsafe values; the firmware failsafe state machine is the authority and reacts to link loss / RX-failsafe flag on its own (§5). Verify the RP1 is at its default failsafe behavior `[bench-TBD]`. | `w17-control-fw/CLAUDE.md` failsafe module |

### 2.2 Channel map — mirror of the committed W17 profile

The firmware's channel semantics and the mapper's committed profile are the same table seen from
two ends. Handset model setup mirrors **`configs/w17-ds4.json`** on the mapper's `w17-audit-wave1`
branch (read 2026-08-17; profile summary also in `2026-08-16_orchestration_review_packet.md` §2),
against the decode in `w17-control-fw/lib/channels/include/channels/ChannelDecoder.hpp` (0-based
indices; chN = index N−1; normalized −1000‥+1000 at CRSF anchors 172/992/1811; switches ON above
+250 / OFF below −250 with hysteresis).

| CH | Function | Mapper profile (DS4) | Handset control | Profile failsafe | Firmware decode |
|---|---|---|---|---|---|
| 1 | Steering | left stick X (deadzone 2000/32767) | steering stick/wheel | 992 (center) | analog |
| 2 | — | absent from the profile | leave default | — | not mapped |
| 3 | Throttle | R2 − L2 mix ("half-pull is half-throttle") | throttle stick/trigger | 992 (center) | analog, gated by ArmGate + failsafe |
| 4 | — | absent | leave default | — | not mapped |
| 5 | **Arm** | TRIANGLE toggle **AND pad-liveness** — dropout drives 172; re-press once after a dropout to re-sync | **latching 2-pos switch**, OFF = down/away | **172 (disarmed)** | 2-pos switch; see §2.4 |
| 6 | DRS | **hold** SQUARE — release (or dropout) closes | momentary switch preferred; 2-pos acceptable | 172 (closed) | 2-pos switch |
| 7 | Gear up | R1, momentary | momentary switch | 172 | edge-detected (consume-on-read) |
| 8 | Gear down | L1, momentary | momentary switch | 172 | edge-detected |
| 9 | Gimbal pan | right stick X | second stick X (or pot) | 992 | analog; stick-driven CRSF only — **not** the head-tracking path (boundary text) |
| 10 | Gimbal tilt | right stick Y | second stick Y (or pot) | 992 | analog, same note |
| 11 | ERS boost | **pinned OFF rail** | **fixed mixer value −100 %** | 172 | held switch |
| 12 | ERS overtake | **pinned OFF rail** | **fixed mixer value −100 %** | 172 | held switch |
| 13 | **Drive mode** | **pinned LOW rail = TRAINING** ("gentle default; RACE=mid, ERS=high, rebind later") | **fixed mixer value −100 % = TRAINING** | 172 | tri-state: < −333 → TRAINING · middle → **RACE** · > +333 → ERS |

(The DS4's SHARE / OPTIONS / D-pad-DOWN reservation in the profile label is a mapper-side
head-tracking affordance — no handset equivalent exists or is needed.)

**The one silent trap — pin ch13, do not leave it unassigned.** An unassigned EdgeTX output sits
at **center (992)**, and the firmware's stateless tri-state reads center as **drive mode 1 =
RACE**, not TRAINING (`ChannelDecoder.hpp`: *"< −333 → 0, > +333 → 2, else … → 1"*; *"default/absent
= 1"*). A lazily configured handset therefore hands a guest the RACE envelope. The profile pins
ch13 LOW for exactly this reason — the handset model must pin it to −100 % the same way. Same
hygiene for ch11/12 (pin −100 %), even though their center-read merely leaves the held-switch state
OFF.

### 2.3 Two viable control tiers

- **Minimum viable backup** (gamepad-class handsets): **ch1 steer + ch3 throttle + ch5 arm**, with
  ch6–13 pinned per the table. Consequences, all safe-by-design: DRS stays closed, gears never
  shift, gimbal parks at center, mode is TRAINING. The car drives gently and nothing else moves.
- **Full mirror** (full-size/surface radios): all rows above on physical controls — indistinguishable
  from the DS4 chain from the firmware's point of view.

### 2.4 Arm ch5 — semantics the handset must respect

From `w17-control-fw/lib/channels/include/channels/ArmGate.hpp` (the *"no arm-into-full-throttle"*
gate, safety priority #2) and `ChannelDecoder.hpp`:

- Arming requires **switch ON _and_ throttle observed at neutral** (|normalized| ≤ 60) at least
  once since the last disarm. Flipping arm with the throttle displaced keeps the motor off until
  the stick returns to neutral.
- **Any** disarm (switch off, failsafe episode) clears the latch — neutral must be re-seen before
  power flows again. A link recovery mid-stick-input cannot snap the motor on.
- **The re-arm invariant (OWNER-RATIFIED 2026-08-20) — corrected here, this doc previously
  described the pre-2026-08-20 behavior.** A failsafe episode observed while the arm switch is ON
  **latches a disarm that outlives the episode**: link recovery with the switch left ON can
  **never** re-arm the car by itself. Re-arming after a failsafe episode additionally requires the
  switch to be seen **OFF, then ON again**, on a proven link, on top of the ordinary fresh-
  neutral-throttle condition above (`w17-control-fw/lib/channels/include/channels/ArmGate.hpp`,
  the `switchToggleRequired_` latch, cleared only by observing the switch OFF). A boot with the
  switch already ON is treated the same way — it demands one deliberate OFF→ON toggle before the
  first arm.
- Mapper-vs-handset difference worth knowing: the DS4 profile's ch5 is a **software toggle with a
  liveness gate** (pad dropout → 172, re-press to re-sync — the mapper's own `reset_on_nan`
  already returns the toggle to DISARMED on a dropout, so it independently agrees with the
  invariant above); a handset ch5 is a **physical latch**, so the toggle above is on the human,
  not on software. Concretely: if the physical arm switch is left ON through a link outage,
  recovery alone will **not** re-arm the car — cycle the switch OFF then ON, with the stick at
  neutral, only after the link is confirmed back. **Operational rule for humans: arm switch OFF
  on any failsafe event; cycle it OFF→ON again, stick neutral, only when ready to resume.** Exact
  recovery timing on the real link: `[bench-TBD]`.
- Handset-side guards that mirror the profile's boots-disarmed stance: enable the radio's
  **switch warning** (refuses to start with arm ON) and **throttle warning** — standard EdgeTX
  model settings on full radios; gamepad-class equivalents vary `[TBD-procure: check per candidate]`.

### 2.5 Gentle rates

The real gentleness is firmware-side — TRAINING mode's envelope (per-gear cap + curve live in
`w17-control-fw/lib/gearbox`) plus the pinned ch13. Handset rates are a second, cosmetic layer:
conservative steering rate/expo on ch1 (e.g. EdgeTX rate ≈ 70 % / expo ≈ 30 % as a starting point
`[A — taste values, tune at the bench]`) so a guest's first wiggle is not a wall-to-wall slam. Do
**not** compensate with throttle curve tricks on the handset — the vision's speed answer is
"tunable, gentle defaults" (decision 4) and that tuning belongs to the firmware settings blob, one
authority, not two.

## 3. Candidate classes — classes are the decision, brands are examples

Decision 12 says *"plain."* Three shapes qualify; the named models are **examples only, not
procurement decisions** — verify current-generation ELRS variants and stock at purchase time
`[TBD-procure: final model = owner's ergonomic call]`.

| Class | Fits decision 12 because | Examples (examples only) | Watch out |
|---|---|---|---|
| **Gamepad-style ELRS** | Cheapest, smallest, most "plain"; a non-hobbyist guest already knows the shape. Covers the §2.3 minimum tier. | BetaFPV **LiteRadio 3** (2.4 GHz ELRS); RadioMaster **Pocket** (ELRS variant) | Few physical switches — confirm it exposes a **latching switch for ch5** and enough spares for ch6; channel-pinning happens in its config app, less flexible than EdgeTX `[TBD-procure: verify per model]` |
| **Full-size EdgeTX radio** | Full mirror tier; EdgeTX gives exact mixer control over every pin in §2.2. | RadioMaster **TX12** / **Boxer** (ELRS variants) — and the owned **TX16S** if its internal RF turns out to be ELRS (§1) | Overkill for "plain"; menu-diving is hostile to the giftee; if this class wins, ship it with the model locked |
| **Surface / pistol-grip ELRS** | The car-native shape: wheel = steering, trigger = throttle — the most natural guest-driving ergonomics for a **car** | RadioMaster **MT12** (ELRS surface radio) | Fewer aux controls than a stick radio; check ch9/10 (gimbal) can sit on pots/absent per the minimum tier |

Owner questions this table cannot answer: which ergonomics the giftee gets (gamepad familiarity vs
car-native pistol grip), and whether the backup handset is also meant to be the **guest** handset
(argues for surface style) or a glovebox emergency tool (argues for the smallest gamepad).

## 4. Binding + model match — generic ELRS procedure

Generic ExpressLRS steps, deliberately version-agnostic; **every step that needs the real RP1
powered is `[bench-TBD]` and lives inside an attended, gated bench session** (the RP1 powers from
Rail A of the car harness — nothing here happens before the harness's own gates pass; a standalone
USB-bench powering of the RP1 is still a powered activity requiring owner-attended approval per
the workspace no-unattended-powering rule).

1. **Flash/confirm the handset's ELRS TX firmware** with the system's **bind phrase** (ExpressLRS
   Configurator). Match the **major version** to the RP1's — which is unrecorded until the bench
   reads it `[TBD-owner-confirm: record ELRS versions, §2.1]`.
2. **Bind.** With a shared bind phrase, ELRS binds automatically on first contact — no button
   ceremony. Fallback (phrase mismatch/unknown): put the RP1 in bind mode (classic ELRS receiver
   convention: three rapid power cycles → bind LED pattern — confirm against the RP1 manual for
   its flashed version `[bench-TBD]`) and use the TX's Bind action from its ELRS menu/Lua.
3. **Model match.** In the TX's ELRS settings, enable **Model Match** and set the model ID; the
   RP1 stores the match on the next connect. The GCS-box module and the handset must then use the
   **same model-match ID** to talk to the same RP1 — record the chosen ID in `CURRENT_STATUS.md`
   when it is set `[bench-TBD]`. (Model match protects against the *wrong model profile* on a
   multi-model radio driving the car; it does **not** arbitrate between two live transmitters —
   §5.)
4. **Verify the map before anything actuates** — the same no-power-first discipline as the car
   build: with the car's drive power absent per its gate state, watch decoded channels (tuning
   console `status`, or bench telemetry) while exercising every handset control against the §2.2
   table: arm ON/OFF, throttle sweep, ch13 reading TRAINING (**not** RACE — the §2.2 trap),
   gears edge-firing once per press `[bench-TBD]`.
5. **Failsafe drill, every session it's touched:** handset off mid-"drive" (bench rig) → firmware
   neutralizes throttle / centers steering / closes DRS; handset back on → confirm the §2.4
   re-arm behavior `[bench-TBD]`.

## 5. Safety notes — why a second transmitter changes nothing that matters

- **The firmware is the safety authority, source-agnostically.** Arm gate ("throttle stays neutral
  until the arm switch is ON *and* throttle has been seen at neutral once"), failsafe FSM
  ("link loss or RX failsafe → throttle neutral, steering center, DRS closed; latch until link
  returns and a re-arm condition is met"), ESC boot sequence, warn-only battery — all live in
  `w17-control-fw` (`CLAUDE.md` safety priorities 1–4) **downstream of any transmitter**. The
  handset is just another CRSF producer behind the same RP1; workspace boundary 6 ("firmware is
  the only producer of final hardware outputs") is untouched.
- **Gimbal ch9/10 stays stick-driven and source-agnostic** — workspace boundary 4's own wording.
  A handset's right stick on ch9/10 is the *same* path the DS4 uses; nothing here touches the
  head-tracking gate, W3 log-only status, or FIRST_ACTIVE.
- **One live transmitter at a time — operational rule.** Two TXs (GCS box module + handset) bound
  with the same phrase and model ID are both *entitled* to the RP1; ELRS connects one link, but a
  handset left on while the laptop chain drives invites a takeover race on link drop
  `[I — generic ELRS behavior; exact contention behavior deliberately not relied on]`. Rule:
  power on the second source only after the first is provably off. Worth a line in both the
  glovebox booklet and chapter 21.
- **The handset never relaxes the giftee posture:** boots with arm OFF (switch warning, §2.4),
  drive mode pinned TRAINING (§2.2), ERS pinned off. "User friendly never means removing the arm
  gate, the failsafe, or the warning-only battery invariant" (`W17_PRODUCT_VISION.md`, operator
  model) — that sentence governs this device too.
- **Binding sessions are powered sessions** — attended only, gates respected (§4 preamble). This
  document authorizes zero powered work.

## 6. Manual pointer stubs (ch21 / ch22)

For the manual waves proposed in `2026-08-16_orchestration_review_packet.md` §6:

- **`learning-manual/21_rebuild_ground_side_install.md`** — add, alongside its GCS-box section:
  *"No-laptop backup path: a plain ELRS handset bound to the RP1 (vision decision 12) — 
  requirements, channel map and binding in `../w17-elrs-backup-handset.md`. The handset is the
  ground side's degraded mode: drive without HUD/FPV, firmware safety unchanged."* Written when
  the chapter itself is written (its stub's "Written when" gate).
- **`learning-manual/22_rebuild_first_power_up.md`** — the §4 verification and §5 failsafe drill
  belong inside its Phase-B staged order ("receiver link and failsafe proven before the ESC's
  motor power is ever connected" — the stub's own sequencing); the handset makes a good *first*
  link-proving TX precisely because it removes the whole PC chain from the variable set. Add the
  drill as a line item when that chapter is written post-A2/Phase-B.

## 7. Cross-references

- `W17_PRODUCT_VISION.md` — decision 12, backlog "ELRS backup handset", operator model.
- `HARDWARE_INVENTORY.md` §2 — RP1 on hand; TX16S owned; ES24TX arrival row.
- `w17-control-fw/docs/bill_of_materials_v2.md` — §2 radio lines; open confirmation #4 (TX16S RF).
- `configs/w17-ds4.json` (mapper `w17-audit-wave1` branch) — the mirrored profile of §2.2.
- `w17-control-fw/lib/channels/` (`ChannelDecoder.hpp`, `ArmGate.hpp`) — decode + arm semantics.
- `w17-gcs-box-guide.md` — the main-chain hardware this handset is the backup for.
- `learning-manual/01_total_system_overview.md` §6 — the pre-vision "TX16S as backup" record.
