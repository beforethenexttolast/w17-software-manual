# W17 PROCUREMENT AND PHYSICAL ACTIONS

> **Owner rulings applied 2026-09-06 (Decision Round 1):** D-1 — the 5 GHz AP-capable USB Wi-Fi adapter is GIFT-KIT / production GCS equipment (one unit, no ARM-VM duplicate): **BUY NOW**, x64-only driver reality unchanged; validate on a real x64 Win11 PC when available AND re-check on the giftee PC at handover. D-2 — OP-49: the two on-hand IP2326 boards are the **adopted candidate**; remaining identification / envelope / interface / interlock / isolation / thermal / fault / charge-safety evidence is still required before any powered charge test; the no-power board-marking inspection stays. Must-not-lose list: adapter · 2S car battery · GCS-box USB 3.x hub · boot-mode selector · OP-49 closure + charge-path parts · TX16S internal-RF check → backup-handset decision · coupon C-1 · Windows ARM VM · measurement sitting.


> **Decision Round 2 additions (2026-09-06, Director):** (1) **identify the bench PSU** (model, minimum settable current limit) and (2) **identify the UBECs** (make/model + BEC#2's output-voltage setting) — no document names either, and the whole first-power current-limit staircase is BLOCKED on exactly these two facts (`W17_OWNER_ACTIONS.md` DR2-3/DR2-4; row 8 below); (3) **Wi-Fi module heatsink — RULED DR2-14 (2026-09-06 evening): BUY a ≥ 32×32 mm part if mechanical clearance permits** (BUY NOW row 6 below; the fitted part is 28×28×3 mm, `HARDWARE_INVENTORY.md`:76; the size envelope waits on photo/label packet item 7); (1)–(2) are now photo/label packet items 1–2 in `W17_OWNER_PHOTO_LABEL_INTAKE.md` (DR2-3/DR2-4 BLOCKED on them, `2026-09-06_offline_decision_round_2.md`); (4) row 8's A2 citation corrected to `:116`.

**Date:** 2026-09-05 · **Worker:** D1 (Sonnet 5), readiness program `offline/procurement`. Replaces
the v0.1 director seed. **Docs only — no hardware touched, powered, or ordered to write this
file.** Every claim below cites a path; status marks follow the workspace legend (`HARDWARE_INVENTORY.md`
✅/⬜/🏠/⏳) plus the program's evidence labels (OBSERVED / VERIFIED / INFERRED / ASSUMED /
BENCH-TBD / BLOCKED / NOT-EXECUTED). Buying and physical sorting move no gate: **A2 stays
NOT-EXECUTED, Phase B stays BLOCKED**, regardless of anything in this file.

Buckets: **BUY NOW** (blocks foreseeable work) · **CHECK IF I ALREADY HAVE** · **OPTIONAL** ·
**WAIT** (resolve requirement first). Fields per row: requirement/spec · why · unlocks ·
evidence/source (`path:line`) · exact model necessary? · status.

---

## BUY NOW

| # | Item | Requirement / spec | Why | Unlocks | Source | Exact model? | Status |
|---|---|---|---|---|---|---|---|
| 1 | 5 GHz-capable USB Wi-Fi adapter | Dual-band 802.11ac, USB-A, driver must **host** Windows Mobile Hotspot on 5 GHz (client-only 5 GHz adapters do not qualify); external antenna preferred; proven chipset families RTL8812BU/RTL8812AU-class | Camera radio (BL-M8812EU2) is 5.8 GHz-only — the giftee PC must host a 5 GHz hotspot for the iPhone HUD to reach it; gates `30-hotspot.ps1` and the hotspot-interface half of `40-mdns-udp.ps1`; `00`/`10`/`20`/`50`/`60` are unaffected and run without it (`w17-windows-vm-validation-runbook.md:29-34`) | GCS box §1 "one-cable promise"; `30-hotspot.ps1` + hotspot half of `40-mdns-udp.ps1`; race-day hotspot | `w17-gcs-box-guide.md` Addendum 2026-08-17 (APPROVED for box BOM); `w17-windows-vm-validation-runbook.md:19-33` (§0 box); `CURRENT_STATUS.md:24` | **No.** Chipset family, not SKU: RTL8812AU/RTL8812BU class, per the owner-approved purchase spec (`w17-gcs-box-guide.md:284-291`). **Buy for the giftee PC (x64), not for the ARM64 VM:** no vendor ARM64 Windows driver exists for any candidate chipset (Realtek portal `cate_id=660`/`663` list only a 2018 Win7/8.1/10 package), so `30-hotspot.ps1` must be validated on a real x64 Windows machine — the runbook's own fallback (`w17-windows-vm-validation-runbook.md:249-254`). Same adapter, different validation host; no second purchase. | ⬜ not sourced — **WAIT→BUY after chipset confirmation** |
| 2 | In-envelope 2S LiPo car pack | Hard fail >75×45×25 mm; target ≤70×40×22 mm; 2S, soft-case, ≥25C (30C+ preferred), JST-XH balance, XT60 main lead preferred (or re-terminable) | The car has **no battery that fits it** — the only pack on hand (5200 mAh, 138×47×37 mm) is bench-only, 3.9× over volume | Phase B on-car power; the only line in the whole workspace that blocks the car ever moving under its own power | `HARDWARE_INVENTORY.md:207,221-227,259-297` (§D/§E + "Not on hand yet" #1 + the 2026-07-31 sourcing spec); `w17-battery-sourcing-check-prompt.md` (repeatable GO/NO-GO vetting session per candidate listing) | No — shop **to the envelope**, not to a capacity number or the old ZEEE SKU | ⬜ not sourced; owner reports difficulty finding one (2026-07-31) |
| 3 | USB 3.x hub for the GCS box | ≥3 downstream ports, uplink cable long enough for desk placement; **self-powered-capable strongly recommended** (DC barrel input) so the 12 V fallback (row 5) is a cable, not a redesign | The box's whole giftee-facing promise is "plug ONE USB cable into the PC" — FT232RL + ELRS TX module + the row-1 Wi-Fi adapter all live behind this hub | GCS box build (`w17-gcs-box-guide.md` §1 "one-cable promise"); doubles as the exact hardware WS3's `30-hotspot.ps1` bench-tests, since that suite is validating this same three-device chain | `w17-gcs-box-guide.md:46` (§2 row 4: *"No hub exists in the inventory — no row in any section"*) | No — any USB 3.x hub meeting the port/power spec; record its datasheet current draw at selection (§4 table) | ⬜ **not sourced.** The box needs a hub that lives permanently inside the printed enclosure with its dimensions recorded at selection (`w17-gcs-box-guide.md:46,229`). A dock attached to the Mac is not that part. See "Baseline note" below |
| 4 | Boot-mode selector switch (SP3T or SPDT centre-off) | Common + 3 throws (SP3T) **or** ON-OFF-ON SPDT centre-off (3 terminals) — either satisfies the truth table (one beep per position, OPEN at center); no listing chosen | Drive/Solo/Show boot-mode selection (D3-SHOW-SELECT, OWNER-RATIFIED 2026-08-20); wires to GPIO27 (SOLO) / GPIO32 (SHOW) | A2 gate §S4c; D8 Phase 3b; BT1 bench gate (stage 9) — all three are moot if the selector is never wired (recording it NOT-ASSEMBLED is a valid A2 pass) | `w17-control-fw/docs/bill_of_materials_v2.md:35-49` (§2, `[owner-shopping]`, "No listing chosen yet... `[bench-TBD]` until the part is in hand"); confirmed **not** in `HARDWARE_INVENTORY.md` (no SP3T/SPDT row exists) | No — either part family; terminal map must be read with a meter after purchase (datasheets for cheap slide switches don't reliably label common vs. throw) | ⬜ **moved here from "CHECK IF I ALREADY HAVE" in the seed — BOM and inventory both show it was never ordered, not merely unconfirmed.** See "Baseline note" below |
| 5 | ELRS backup handset (gift-kit unit) | **Gamepad-style ELRS, LiteRadio-class** — OWNER-DECIDED 2026-08-17 (`w17-gcs-box-guide.md:292-293`; `CURRENT_STATUS.md:196-197`). 2.4 GHz ExpressLRS, same major version as the RP1's firmware. Must expose a **latching switch for ch5 (arm)** and ideally a spare for ch6; channel pinning happens in its config app, so verify per model (`w17-elrs-backup-handset.md:164`). Examples only, not endorsements: BetaFPV LiteRadio 3, RadioMaster Pocket (ELRS variant) | Vision decision 12: *"Keep a plain ELRS handset bound to the RP1 as backup"* — a zero-PC control path independent of the whole laptop chain | Master-sequence stage 12 (ELRS-BACKUP-BIND); handover checklist §8's live drill (handset re-arm proof) | `w17-elrs-backup-handset.md:1-40` (§1, "procure, bind to RP1, document in the manual"); `w17-parts-to-gift-master-sequence.md:92` (stage 12, "Not started") | No — class is OWNER-DECIDED (see spec cell); final model is the owner's ergonomic call `[TBD-procure]` | ⬜ **not sourced, and not on the CURRENT_STATUS.md residue list — see Baseline note below.** `[I]` — the "separate unit" reading (distinct device from the owned TX16S) is INFERRED (`w17-elrs-backup-handset.md:49-52`, labelled `[I]` in the source). The open owner question — does the TX16S ship with the gift, or stay the owner's bench radio? — is unresolved (`w17-elrs-backup-handset.md:41-42`, `[TBD-owner-confirm ×2]`). If the answer is "TX16S ships" **and** its internal RF is ExpressLRS, this purchase may be unnecessary — answer the TX16S check first (see that section below) |
| 6 | Wi-Fi module heatsink ≥ 32×32 mm (replaces the fitted 28×28×3 mm) | Footprint ≥ 32×32 mm (datasheet §6.4 recommendation; the module PCB itself is ~32×32 mm); **height: no taller than the fitted stack until photo/label packet item 7 measures the real gap** — the CAD records only 3 mm above the 7.0 mm measured stack to a PROVISIONAL steering-rod keepout (`w17-3d-codex/10_assembly_architecture/fit_studies/ZK_electronics_cassette_fit_study.md:100`, KO-01 Z-floor ASSUMED at `w17-3d-codex/11_cad/w17_params.scad:97`); must not cover the two U.FL jack roots or the USB solder-pad edge; thermal pad/tape included or compatible; a somewhat larger footprint is preferred if it fits without mechanical, RF or serviceability problems (owner, DR2-14) | Datasheet §3.1 requires customer-added heat dissipation (Tj < 125 °C) and §6.4 recommends ≥ 32×32 mm; the owner ruled not to ship deliberately below the manufacturer's recommendation | The project rule "heatsink fitted before first power-on" (`learning-manual/05_control_firmware_documentation_explained.md:365-366`) → BG-03 S5; the thermal validation at first power stays planned regardless of which part is fitted | `_handoff/2026-09-06_R-O6_review.md` N11 (datasheet §3.1/§6.4 quotes); `w17-batch1-measurements-for-codex.md:40` (32.4 × 32.0 × 7.0 mm measured with the fitted part); `2026-09-06_offline_decision_round_2.md` DR2-14 | No — any finned aluminium part meeting the envelope; the envelope is the deliverable of packet item 7 | ⬜ **RULED BUY (DR2-14) — order after packet item 7 fixes the height envelope**; the fitted 28×28 stays on until then |

### Baseline note — three corrections to the seed doc / residue list

1. **SP3T switch was mis-bucketed.** The v0.1 seed put it in "CHECK IF I ALREADY HAVE" with
   status "unknown." Both `HARDWARE_INVENTORY.md` (no SP3T/SPDT row in any section) and the BOM
   itself (`[owner-shopping]`, "no listing chosen yet") agree it was **never ordered** — this is
   not a stock-check question, it is an unstarted purchase. Moved to BUY NOW.
2. **"Powered USB hub" conflates two different claims — and both are true at once.**
   `CURRENT_STATUS.md`'s residue line and the seed doc's "CHECK IF I ALREADY HAVE" row cite
   `w17-windows-vm-validation-runbook.md` §1.8 for a hub — but §1.8 itself (read in full this
   pass) only says *"enable passthrough"* for three USB devices in Fusion's VM settings; it names
   no hub requirement at all (the string "hub" appears in that runbook only inside the word
   "GitHub"). The **actual**, clearly-sourced hub requirement is the GCS box's own BOM gap
   (`w17-gcs-box-guide.md` §2 row 4: *"No hub exists in the inventory — no row in any section"*).
   The seed's observation is real — a dock hub is attached to this Mac (OBSERVED, `ioreg`,
   2026-09-05: a Generic USB3.2 Hub and a Generic USB2.1 Hub, with a Realtek USB 10/100/1000 LAN
   behind the USB3.2 hub). It is simply a different article from the box hub, and inventory
   carries no row because a desk dock is not a W17 part. Both statements can be true at once.
   **Practical read:** buy the one hub the GCS box needs (row 3, must live permanently inside the
   printed enclosure with dimensions recorded at selection); the dock already attached to the Mac
   can double as the interim bench article for WS3's USB-passthrough validation before the box is
   built — one purchase, two uses — but the box's own requirement stands regardless of what is
   sitting on the desk today, and the dock itself can never become the box hub.
3. **The ELRS backup handset device itself is not on the CURRENT_STATUS.md residue list**
   (`CURRENT_STATUS.md:24-26,81-82`, which names only: 5 GHz adapter, OP-49 module, powered hub,
   SP3T switch, ELRS TX label, TX16S check). Vision decision 12 reads as requiring it to be
   procured separately from the TX16S, but that reading is `[I]` — INFERRED, not required:
   `w17-elrs-backup-handset.md:49-52` — *"Decision 12 says 'plain' handset and the backlog says
   'procure' — which reads as a giftee-side unit separate from the owner's TX16S `[I]` — but the
   vision text does not settle where the TX16S itself ends up."* The open owner question — does
   the TX16S ship with the gift, or stay the owner's bench radio? — is unresolved
   (`w17-elrs-backup-handset.md:41-42`, `[TBD-owner-confirm ×2]`). If the answer is "TX16S ships"
   **and** its internal RF is ExpressLRS, this purchase may be unnecessary; answer the TX16S check
   first (see that section below). Master-sequence stage 12 shows it "Not started"
   (`w17-parts-to-gift-master-sequence.md:92`). This reads as a genuine gap in the owner's
   shopping list, not a disagreement between sources — flagging it here rather than silently
   adding it to CURRENT_STATUS.md (out of this session's edit scope; a workspace-doc change is
   one repo/file at a time and CURRENT_STATUS.md's volatile-state edits belong to the program
   lead, not a single worker's procurement pass).

---

## CHECK IF I ALREADY HAVE

| # | Item | Requirement | Why | Source | Status |
|---|---|---|---|---|---|
| 1 | JST-XH connector sets (3/4/5-pin), **plus spare servo leads and U.FL pigtails** | For CRSF (4-pin), link2 (3-pin, RX position empty), I2S (5-pin), LED (3-pin), Hall (3-pin) signal harnesses; spare 3-pin servo leads for PWM runs; U.FL pigtails for RF (distinct from the U.FL *antennas*, which are already ✅ on hand) | Only **one** JST-XH item is confirmed arrived: the 2S 3-pin battery-balance extension (07-30). The five signal-harness JST-XH connectors above are a **named, still-open gap**. Spare servo leads + U.FL pigtails are separately named on the BOM's own to-source list and are not the same part as the on-hand antennas | `w17-pdb-build-and-connector-guide.md:62-91` (§2 connector table); `w17-parts-arrival-build-prompt.md:24` (step 3: *"Confirm you have JST-XH 3/4/5-pin + XT30 for the rail branches (the only connector gaps)"*); `HARDWARE_INVENTORY.md:206` (only the balance-lead JST-XH is ✅); `w17-control-fw/docs/bill_of_materials_v2.md:201` (to-source: "…connector kit (XT60/XT30, JST-XH sets, spare servo leads, U.FL pigtails)"); `HARDWARE_INVENTORY.md:75` (only the U.FL *antennas* are ✅ — a pigtail is a different part) | **unknown — confirm before stage-2 harness build starts; XT30 itself is already ✅ on hand (§5, arrived 2026-07-29), only JST-XH + servo leads + U.FL pigtails are open** |
| 2 | USB-C / USB-A→C / micro-USB cables for the two ESP32 boards | Data-capable (not charge-only) | Flashing (gated, later) and general bench use | `w17-control-fw/docs/COORDINATED_FLASH.md` pointer in `w17-parts-to-gift-master-sequence.md:88` (being written); MH-ET boards are USB-C per `HARDWARE_INVENTORY.md:96` | unknown |
| 3 | A spare/general-purpose USB hub already on hand | Any hub, powered or not | Could serve as the interim bench article for WS3's USB-passthrough validation before the GCS-box hub (BUY NOW #3) is bought and built in | See Baseline note #2 above | **OBSERVED 2026-09-05** (`ioreg -p IOUSB` / `ioreg -c IOUSBHostDevice` on this Mac): a Generic **USB3.2 Hub** and a Generic **USB2.1 Hub** are attached, with a Realtek USB 10/100/1000 LAN behind the USB3.2 hub — i.e. a USB-C **dock**, desk equipment in daily use, which is why no inventory row exists for it. It can serve as the interim bench article for WS3's USB-passthrough step; it cannot become the box hub |
| 4 | Multimeter with continuity beeper, resistance, and **diode mode** | Diode mode is load-bearing, not optional — it's the only check that proves the 1N5819 WS2812 supply diode is present *and* correctly oriented | A2 gate execution (every S-gate); Phase B / D8 bench bring-up; BT1's electrical-draw item | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md:109-120` (§1 Tools); `w17-control-fw/docs/PHASE_B_FIRST_POWER.md:35`; `w17-control-fw/docs/D8_BENCH_BRINGUP.md:28` | unknown |
| 5 | Oscilloscope or logic analyzer | Scope GPIO13/14/18 pulse widths + 50 Hz period; scope GPIO14/13 boot-float window | D8 Phase 3/B1.3-B1.4 (pre-ESC/servo connection proof); BT1's control-tick-jitter item | `w17-control-fw/docs/PHASE_B_FIRST_POWER.md:35`; `w17-control-fw/docs/D8_BENCH_BRINGUP.md:28`; `w17-control-fw/docs/BT1_BENCH_GATE.md` (bench-only list, "Control-tick jitter with BT active") | unknown |
| 6 | Serial monitor capable of 115200 baud | Console/telemetry reads during bench bring-up | D8/PHASE_B tool lists (same citations as rows 4-5) | unknown — likely covered by any terminal app; no dedicated hardware implied |
| 7 | A way to spin the rear axle by hand | Hall-sensor bench test | D8 Phase 8 (`w17-control-fw/docs/D8_BENCH_BRINGUP.md:28,240`) | n/a — a physical action against the assembled car, not a purchase; listed here only because the tool docs name it as a bench-session precondition |
| 7b | The `elrs-joystick-control` PC setup | Not a purchase — a software/config prerequisite named in the same tool lists as rows 4-7 | Both `PHASE_B_FIRST_POWER.md` and `D8_BENCH_BRINGUP.md`'s tool lines name it alongside the multimeter/scope/serial-monitor/axle-spin items; rows 4-7 above claimed to carry "only what these gate docs name," so omitting it was an inconsistency, not a deliberate exclusion | `w17-control-fw/docs/PHASE_B_FIRST_POWER.md:35`; `w17-control-fw/docs/D8_BENCH_BRINGUP.md:28` | unknown — a software setup step (PC-side ELRS joystick tooling), not a physical item; no hardware purchase implied |
| 8 | Bench PSU + USB cable (have them, do not connect them yet) | Explicitly named as items to have on hand for Phase B — **not to be connected during A2** | A2's own instruction: *"USB cable and bench PSU: have them, do not connect them — both are Phase B"* | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md:116` | unknown — **no current-limit spec, USB isolator, or "smoke-stopper" is named in any gate doc this session read (A2, PHASE_B_FIRST_POWER, D8, BT1); do not over-specify beyond what these four cite** |
| 9 | Mechanical-measurement tools: calipers, a rule/ruler, a depth gauge, a protractor, **four** kitchen scales | For the M-00…M-20 mechanical measurement sitting (calipers + scale + no power) — gates every production print, the cage/tray geometry, DRS linkage, and charge-flap placement | `w17-3d-codex/w17-mechanical-measurement-session-prompt.md:1-10` (this file is Codex-side but names its own tool list, found via the required workspace-doc grep sweep) | unknown — likely household/hobby items already owned; flagging because the file explicitly gates production prints on this sitting happening at all |
| 10 | Neodymium magnets 3×1 mm N35 (20 pcs) | Axle pickup magnets for the A3144 Hall sensor | Wheel-speed sensor can't be exercised without them — A3144 + ESC are already on hand | `HARDWARE_INVENTORY.md:128,228` | **⏳ ordered/in transit** (owner, 2026-07-22) — do not re-buy; just track arrival |
| 11 | Tamiya 54198 (front) + 51400 (rear) F104 tyres | 1 pack each = exactly the 4 tyres needed | Wheels can't be finished without them | `HARDWARE_INVENTORY.md:176-177,230` | **⏳ ordered/in transit** (owner, 2026-07-22, rcMart) — do not re-buy; just track arrival |
| 12 | USB-C receptacle (hidden charge-flap connector) | Panel-mount or PCB Type-C receptacle feeding the charge path | Named on the BOM's own to-source list and required by the charge path: *"Needs: 5 V from the USB-C receptacle…"* | `w17-control-fw/docs/bill_of_materials_v2.md:201` (to-source list); `w17-electrical-inputs-for-codex.md:38-39` (charge-path requirement) | unknown — absent from `HARDWARE_INVENTORY.md` (only ESP32 boards and the IP2326 show under "USB-C"). **CHECK IF I ALREADY HAVE, or BUY NOW once the OP-49 module is chosen** — the flap geometry follows whichever module wins |
| 13 | USB-C wall charger, 5 V / ≥2 A | *"A 5 V / ≥2 A USB-C source covers 0.5C charging"* | Required as a **gift-kit item** at handover; the booklet still prints the wattage as open | `w17-electrical-inputs-for-codex.md:43`; `w17-handover-checklist.md:182-183` (*"Charger present, USB-C, confirmed against whatever minimum-wattage figure the bench session settles on"*); `learning-manual/14_glovebox_owners_booklet.md:90` (`[TBD-at-bench: confirmed charger recommendation and minimum wattage]`) | unknown — likely a household item already on hand; no inventory row. Wattage confirmation is **BENCH-TBD** (settled at the bench session, not on paper) |
| 14 | **Temperature probe / thermocouple — or a multimeter with a K-type input** | A contact probe or K-type bead thermocouple for **air** and **surface** temperature. **Check the meter first:** many multimeters include a temperature function and the owner already needs a multimeter (row 4), so this is a question before it is a purchase. **An IR (non-contact) gun reads surfaces, not air** — acceptable **only** for the one-directional surface proof-of-violation reading, never for the ambient criterion; if an IR instrument is what exists, confirm its distance-to-spot ratio gives a spot smaller than the small heatsink face | **DR2-14's thermal validation at first power has no instrument.** The BL-M8812EU2 datasheet rates the module for an **ambient −20 … +70 °C** (§1.3, §3.1) and requires customer-added cooling (Tj < 125 °C), but publishes **no thermal resistance, no case-temperature limit and no dissipation figure** — so no surface PASS temperature is derivable and the step is **evidence recording**, whose two usable readings are *ambient* (needs a probe) and *surface* (either instrument). Without an instrument the step produces nothing. Unlocks BG-03 S5's "Thermal check at S5" | `_handoff/2026-09-06_O6_addendum_report.md` §3 (the derivation, and the workspace grep that found **zero** temperature instruments anywhere); `2026-09-06_offline_decision_round_2.md` **DR2-14**; `2026-09-06_offline_decision_round_3.md` **DR3-3**; `W17_OWNER_ACTIONS.md` **DR3-3** | **DR3-3 RULED as an owner CHECK (2026-09-06 night) — answer OPEN.** If the owner reports an instrument, record its exact identity here and in BG-03's S5 evidence capture (`S5_wifi_thermal.md`). If the owner reports "none," this row becomes **BUY** (a contact probe or K-type bead + a meter with K-type input) and quantitative heatsink-temperature evidence stays **BLOCKED** (DR3-3). Keep the IR-gun caveat: surfaces only, never ambient. Not a purchase until row 4's meter is confirmed to have neither a temperature function nor a bead probe, or the owner answers "none" |

---

## OPTIONAL

| # | Item | Why | Status |
|---|---|---|---|
| 1 | External SSD ≥256 GB | VM disk if internal Mac space can't be freed for the Windows-VM validation session | owner's call — not a W17 hardware item |
| 2 | A second in-envelope 2S pack | "Carry 2 — runtime insurance" (`learning-manual/05_control_firmware_documentation_explained.md:413`) — **one** pack makes the car drivable; the second only removes charge-downtime and single-point-of-failure. `HARDWARE_INVENTORY.md:182,295-297` explicitly frames buying two *at once* as the practical call **once a fitting pack is found at all**, not a separate purchase decision | tied to BUY NOW #2 — buy together if/when a fitting SKU turns up |
| 3 | Spare XT90 loop key half | *"plus a spare if one is decided"* — whether a spare ships is `[TBD-at-bench]` | `w17-handover-checklist.md:184`; one loop key is already on hand (`HARDWARE_INVENTORY.md:203`, the mated XT90-S/XT90H-M pigtail pair) | **WAIT (owner decision) whether a spare ships at all** — not omitted, just not decided; one is already on hand either way |

Note: **"ELRS TX label (printed)" from the seed's OPTIONAL bucket does not exist as a purchasable
or printable item anywhere in the workspace.** The only matching concrete action this session
could find is *reading* the label already on the on-hand ELRS TX module to settle its variant —
see "Physical actions that need no purchase" #1 below. Treating "ELRS TX label" as a print job
would be inventing a task with no source; treating it as a read-the-label check matches the one
open `[TBD-owner-confirm]` in the corpus that plausibly explains the phrase. Flagging the
resolution rather than guessing silently.

---

## WAIT (resolve requirement first)

| # | Item | Resolve first | Source |
|---|---|---|---|
| 1 | 2S balancing USB-C charge module (OP-49) | **RULED D-2 (2026-09-05): the on-hand IP2326 (2 units, ✅ arrived 2026-07-29) is the ADOPTED candidate** — no module choice remains open; `HARDWARE_INVENTORY.md` and OP-49 are to be updated to say so. What remains is OP-49's evidence list, worked against the IP2326, before any powered charge test (this row therefore means WORK, not a purchase decision). **Physical possession of the IP2326 is not the same thing as OP-49's "selected."** OP-49 additionally lists as missing, even after selection: exact SKU/datasheet on record, complete board+connector+heatsink envelope, cell-interface details, the charge/run interlock implementation, charge-state access, reverse/backfeed isolation, thermal/fault evidence, and a **separate charge-safety specification that must close before any powered charge test**. One more note, `[I]` derived, if IP2326 is adopted: `w17-electrical-inputs-for-codex.md:41-42` warns *"Verify the board is genuinely BQ25887 (balancing). Many cheap '2S USB' boards only boost + CV with NO balancing — do not use those"* — but that caution sits inside the **BQ25887 premium-reference** bullet block; it is about boards *sold as BQ25887*, not about the IP2326. The IP2326 is separately described as *"Type-C, 8.4 V, ≤1.5 A, **automatic cell balancing** + OV protection"* (`w17-electrical-inputs-for-codex.md:33-34`), and `HARDWARE_INVENTORY.md:209` records *"balancing confirmed at selection."* Keeping the visual check (physical action #8 below) is cheap and harmless; do not present it as an open canonical gap — the two lines just cited already settle it | `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md:81` (OP-49, **BLOCKER**); `HARDWARE_INVENTORY.md:209,231-241`; `w17-electrical-inputs-for-codex.md:29-42` |

---

## TX16S check — resolved to a concrete action (not a purchase)

CURRENT_STATUS.md's residue list names *"TX16S check"* without saying what the check is. This
session traced it to **BOM open confirmation #4**, verbatim: *"TX16S internal module =
ExpressLRS (EdgeTX → Model → Internal RF). If MULTI-only, move the ES24TX Pro to it for the
backup role."*

- **The check:** power on the owned TX16S, go to **EdgeTX → Model → Internal RF**, and read
  whether the internal module is ExpressLRS or MULTI-protocol. Record the answer in
  `CURRENT_STATUS.md`. This is a powered action on the TX16S itself (not on the car/RP1) — still
  falls under the workspace's attended-session norms but does not touch A2/Phase B in any way.
- **Why the BOM's stated fallback is now stale:** the BOM's own fallback ("move the ES24TX Pro to
  it") collides with the 2026-08-16 gift-kit decision, which put the ES24TX permanently inside
  the GCS box (`w17-elrs-backup-handset.md:24-31`, §1 item 1: *"That fallback collides with the
  gift kit decided later... exactly what the procured plain handset resolves"*). **So: if the
  TX16S turns out MULTI-only, no action is required beyond noting it** — the separately procured
  backup handset (BUY NOW #5) already covers the backup-transmitter role regardless of the
  TX16S's internal RF. The check still has a use even so: if the TX16S *is* ExpressLRS, it can
  serve as an **owner-side interim backup** before the gift-kit handset is bought and bound
  (`w17-elrs-backup-handset.md:36`, "working model" paragraph).

Sources: `w17-control-fw/docs/bill_of_materials_v2.md:186` (open confirmation #4);
`w17-elrs-backup-handset.md:1-40` (§1, both open questions and the working model).

---

## Physical actions that need no purchase

Things to find, label, sort, weigh, caliper, read, or photograph — no shopping involved. Powered
items are excluded (charging, flashing, connecting a battery are all Phase-B/A2-gated and out of
scope for an unattended or no-power session).

1. **Read the label on the on-hand ELRS TX module** to confirm Pro vs. nano/Slim variant. This is
   the concrete action behind the seed's ambiguous "ELRS TX label" residue item (see the OPTIONAL
   section note above) — the module's envelope (§6 of the box guide) and its USB power-budget
   line (§4) both depend on which variant it is. Source: `w17-gcs-box-guide.md:20`
   (`[TBD-owner-confirm: read the label on the physical module — Pro vs nano/Slim]`).
2. **TX16S internal-RF check** (EdgeTX → Model → Internal RF) — see the dedicated section above.
   This one *is* a powered action on the handset, listed here for completeness since it needs no
   purchase either way.
3. **Caliper the PDB socket-stack height** (female header + MH-ET male pins, seated as in the
   cassette) against the ZK cassette clearance `S0 ≥ 9.82 mm`. **Precondition, not a to-do** — the
   whole A2 build order depends on this passing before the first joint is soldered. Source:
   `w17-socket-stack-caliper-prompt.md`; `w17-parts-arrival-build-prompt.md:15-24` (step 0).
4. **Caliper + weigh both MH-ET D1-Mini boards**: bare L×W×H, height with headers, USB-C plug
   protrusion, which short edge carries USB-C, mounting-hole span. Closes ZK CAS-03 and firms the
   CG estimate. Source: `w17-parts-arrival-build-prompt.md:26-28` (step 1);
   `HARDWARE_INVENTORY.md:200` ("Physical caliper + weight still owed").
5. **Derive the MH-ET adjacent-pin list from the silkscreen** (both boards) — closes A2 review
   finding F12; its fallback ("beeper-check every joint") stays valid but slower, so this is a
   time-saver, not a blocker. Source: `w17-parts-arrival-build-prompt.md:27-28`;
   `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` (F12/F20 notes).
6. **Measure the actual 1000 µF capacitor** intended for Rail B (diameter + length) to confirm
   the "flat-mount ~8-10 mm" assumption used in the PDB-height estimate. Source:
   `w17-parts-arrival-build-prompt.md:30-31` (step 2); `HARDWARE_INVENTORY.md:202`.
7. **Weigh the on-hand 5200 mAh bench pack.** Its ~250-300 g mass is currently an *assumption*,
   not a measurement, and the file explicitly warns not to cite a CG number before weighing it.
   No power, no risk — this is a pack sitting on a scale. Source: `HARDWARE_INVENTORY.md:208`
   (*"Assumption, not measured: a 2S 5200 typically weighs ~250-300 g — weigh it before any CG
   argument cites a number"*).
8. **Inspect the on-hand IP2326 charger units** for a genuine balancing chip marking (vs. a
   boost+CV-only board with no balancing) — a no-power visual/label check, not a bench test. Note
   this caution is `[I]` derived and sits inside the BQ25887 bullet block, not the IP2326's own
   spec, which already states automatic cell balancing (see the WAIT-bucket note above); the check
   is cheap confirmation, not an open canonical gap. Feeds directly into the WAIT-bucket OP-49
   decision above. Source: `w17-electrical-inputs-for-codex.md:41-42` (caution),
   `:33-34` (IP2326 spec), `HARDWARE_INVENTORY.md:209` ("balancing confirmed at selection").
9. **The M-00…M-20 mechanical measurement sitting** (calipers, ruler, depth gauge, protractor,
   scales — no power) — fills in what has actually been printed (M-00), the S0 shell-clearance
   figure that decides the second-floor cage (M-01), and 18 more rows. This is a `w17-3d-codex`
   (Codex-territory-but-Claude-owned) session, named here only because it surfaced in the
   required grep sweep and gates BUY NOW-adjacent decisions (the cage, DRS linkage, charge-flap
   placement). Source: `w17-3d-codex/w17-mechanical-measurement-session-prompt.md`.
10. **Confirm on-hand JST-XH / XT30 connector counts against the harness build's needs** (CHECK
    IF I ALREADY HAVE #1) before the stage-2 harness-build session starts, so a mid-build supply
    gap doesn't stall a soldering sitting. Source: `w17-parts-arrival-build-prompt.md:24`.
11. **Pre-solder MAX98357A GAIN pad-mapping check (no power) — DR3-2.** Before permanently
    soldering the amp board, visually/continuity-check the `GAIN_SLOT` strap pad against the
    manufacturer's own Gain Selection table: `GAIN_SLOT` unconnected = **9 dB**, GND = **12 dB**,
    VDD = **6 dB**, 100 kΩ to GND = **15 dB**, 100 kΩ to VDD = **3 dB** (Maxim Integrated
    *MAX98357A/MAX98357B* datasheet, Gain Selection table, retrieved 2026-09-06). Confirm the
    fitted board — a generic AliExpress "MAX98357A I2S amplifier 1PCS" (`HARDWARE_INVENTORY.md`:97,
    `w17-control-fw/docs/bill_of_materials_v2.md`:69) — actually implements this pad mapping before
    assuming the Adafruit pinout; 9 dB (floating) is CONFIRMED (DR3-2) as the intended shipped
    configuration, but the pad mapping itself is unverified against this exact article. No power.
    Source: `2026-09-06_offline_decision_round_3.md` **DR3-2**.

---

## Counts per bucket

- **BUY NOW:** 6 items (5 GHz Wi-Fi adapter · in-envelope 2S pack · GCS-box USB hub · boot-mode
  selector switch · ELRS backup handset · ≥ 32×32 mm Wi-Fi heatsink, RULED DR2-14, envelope from packet item 7)
- **CHECK IF I ALREADY HAVE:** 15 rows (2 unresolved parts questions incl. spare servo
  leads/U.FL pigtails, **7** bench-tool/instrument rows named by a gate doc — row 14, the
  temperature probe, added 2026-09-06 evening for DR2-14's thermal check — 1 software-setup
  prerequisite (`elrs-joystick-control`), 1 spare-hub question, 2 already-⏳-in-transit items
  tracked for completeness not re-purchase, 2 charge-path items (USB-C receptacle, USB-C wall
  charger))
- **OPTIONAL:** 3 items (external SSD, second battery pack, spare XT90 loop key half) + 1
  resolved-terminology note
- **WAIT:** 1 item (OP-49 charge module — owner decision required before any purchase or build
  step)

## Where sources disagreed

1. **SP3T switch bucket** — the v0.1 seed called it "CHECK IF I ALREADY HAVE / unknown"; BOM v2
   and HARDWARE_INVENTORY.md agree it was never ordered. Moved to BUY NOW (see Baseline note #1).
2. **"Powered hub" citation** — the seed's `w17-windows-vm-validation-runbook.md` §1.8 citation
   does not itself name a hub requirement; the real, sourced requirement is the GCS box's own BOM
   gap. The seed's "attached now (OBSERVED)" claim is real (OBSERVED, `ioreg`, 2026-09-05 — see
   Baseline note #2) but names a different article (a desk dock) from the box's own requirement,
   which has no inventory row because a desk dock is not a W17 part. This is a bucketing gap, not
   a contradiction between two authoritative docs, so it is not filed as a BASELINE CONTRADICTION
   per COMMON.md rule 9 (no two cited sources conflict — the two claims describe two different
   physical hubs).
3. **ELRS backup handset omitted from the residue list** — `CURRENT_STATUS.md`'s residue line and
   the seed doc both skip it; `w17-elrs-backup-handset.md` and the master sequence both show it
   as a real, unstarted procurement item. Added to BUY NOW (Baseline note #3).

No BASELINE CONTRADICTION (per COMMON.md rule 9 — two authoritative sources making opposite
factual claims) was found. The three items above are gaps/mis-buckets in the seed doc and the
residue list, not disagreements between canonical sources.

---

## Cross-references

- `HARDWARE_INVENTORY.md` — arrival/on-hand status, authoritative for what has physically shown up.
- `w17-control-fw/docs/bill_of_materials_v2.md` — part identity, authoritative for what a part *is*.
- `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md` — OP-49, OP-04.
- `w17-gcs-box-guide.md`, `w17-pdb-build-and-connector-guide.md`, `w17-electrical-inputs-for-codex.md`
  — connector/module envelopes and gaps.
- `w17-elrs-backup-handset.md` — backup handset requirements + the TX16S check's real source.
- `w17-windows-vm-validation-runbook.md` §0-1 — the 5 GHz adapter's WS3 dependency.
- `w17-parts-to-gift-master-sequence.md` — stage ordering; stage 12 (handset) status.
- `w17-handover-checklist.md` §7 — physical-kit checklist at handover (spare battery, charger,
  ignition-key loop plug, GCS box + controller in the kit) — cross-checked, no new items found
  there beyond what's already listed above.
- Wi-Fi adapter chipset research (BUY NOW #1's exact spec, incl. the x64-only validation-host
  finding): `w17-gcs-box-guide.md:284-291` (owner-approved chipset family) and the Realtek
  driver-portal check (`cate_id=660`/`663`, no ARM64 Windows package for any candidate chipset,
  VERIFIED 2026-09-05) cited inline at BUY NOW row 1 above.
