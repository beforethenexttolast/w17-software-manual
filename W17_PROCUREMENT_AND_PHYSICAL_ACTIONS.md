# W17 PROCUREMENT AND PHYSICAL ACTIONS

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
| 1 | 5 GHz-capable USB Wi-Fi adapter | Dual-band 802.11ac, USB-A, driver must **host** Windows Mobile Hotspot on 5 GHz (client-only 5 GHz adapters do not qualify); external antenna preferred; proven chipset families RTL8812BU/RTL8812AU-class | Camera radio (BL-M8812EU2) is 5.8 GHz-only — the giftee PC must host a 5 GHz hotspot for the iPhone HUD to reach it; also gates ~30 of 40 WS3 Windows-validation checks | GCS box §1 "one-cable promise"; `30-hotspot.ps1` + hotspot half of `40-mdns-udp.ps1`; race-day hotspot | `w17-gcs-box-guide.md` Addendum 2026-08-17 (APPROVED for box BOM); `w17-windows-vm-validation-runbook.md:19-33` (§0 box); `CURRENT_STATUS.md:24` | **Chipset research is A3's job — see `$SP/reports/A3.md` before buying.** Owner-approved spec only names the chipset family, not a SKU | ⬜ not sourced — **WAIT→BUY after A3** (unchanged from seed) |
| 2 | In-envelope 2S LiPo car pack | Hard fail >75×45×25 mm; target ≤70×40×22 mm; 2S, soft-case, ≥25C (30C+ preferred), JST-XH balance, XT60 main lead preferred (or re-terminable) | The car has **no battery that fits it** — the only pack on hand (5200 mAh, 138×47×37 mm) is bench-only, 3.9× over volume | Phase B on-car power; the only line in the whole workspace that blocks the car ever moving under its own power | `HARDWARE_INVENTORY.md:207,221-227,259-297` (§D/§E + "Not on hand yet" #1 + the 2026-07-31 sourcing spec); `w17-battery-sourcing-check-prompt.md` (repeatable GO/NO-GO vetting session per candidate listing) | No — shop **to the envelope**, not to a capacity number or the old ZEEE SKU | ⬜ not sourced; owner reports difficulty finding one (2026-07-31) |
| 3 | USB 3.x hub for the GCS box | ≥3 downstream ports, uplink cable long enough for desk placement; **self-powered-capable strongly recommended** (DC barrel input) so the 12 V fallback (row 5) is a cable, not a redesign | The box's whole giftee-facing promise is "plug ONE USB cable into the PC" — FT232RL + ELRS TX module + the row-1 Wi-Fi adapter all live behind this hub | GCS box build (`w17-gcs-box-guide.md` §1 "one-cable promise"); doubles as the exact hardware WS3's `30-hotspot.ps1` bench-tests, since that suite is validating this same three-device chain | `w17-gcs-box-guide.md:38` (§2 row 4: *"No hub exists in the inventory — no row in any section"*) | No — any USB 3.x hub meeting the port/power spec; record its datasheet current draw at selection (§4 table) | ⬜ **not sourced.** See "Baseline note" below — this is a different claim from the seed doc's "hub attached now" row |
| 4 | Boot-mode selector switch (SP3T or SPDT centre-off) | Common + 3 throws (SP3T) **or** ON-OFF-ON SPDT centre-off (3 terminals) — either satisfies the truth table (one beep per position, OPEN at center); no listing chosen | Drive/Solo/Show boot-mode selection (D3-SHOW-SELECT, OWNER-RATIFIED 2026-08-20); wires to GPIO27 (SOLO) / GPIO32 (SHOW) | A2 gate §S4c; D8 Phase 3b; BT1 bench gate (stage 9) — all three are moot if the selector is never wired (recording it NOT-ASSEMBLED is a valid A2 pass) | `w17-control-fw/docs/bill_of_materials_v2.md:35-49` (§2, `[owner-shopping]`, "No listing chosen yet... `[bench-TBD]` until the part is in hand"); confirmed **not** in `HARDWARE_INVENTORY.md` (no SP3T/SPDT row exists) | No — either part family; terminal map must be read with a meter after purchase (datasheets for cheap slide switches don't reliably label common vs. throw) | ⬜ **moved here from "CHECK IF I ALREADY HAVE" in the seed — BOM and inventory both show it was never ordered, not merely unconfirmed.** See "Baseline note" below |
| 5 | ELRS backup handset (gift-kit unit) | Class per owner ergonomic pick — see the 3-way table in `w17-elrs-backup-handset.md` §3: gamepad-style (LiteRadio-class), full-size EdgeTX (TX12/Boxer-class), or surface/pistol-grip (MT12-class); must expose a latching switch for ch5 (arm) | Vision decision 12: *"Keep a plain ELRS handset bound to the RP1 as backup"* — a zero-PC control path independent of the whole laptop chain | Master-sequence stage 12 (ELRS-BACKUP-BIND); handover checklist §8's live drill (handset re-arm proof) | `w17-elrs-backup-handset.md:1-40` (§1, "procure, bind to RP1, document in the manual"); `w17-parts-to-gift-master-sequence.md:307-322` (stage 12, "Not started") | No — brand names in §3's table are examples only, not endorsements; final model is the owner's ergonomic call `[TBD-procure]` | ⬜ **not sourced, and not on the CURRENT_STATUS.md residue list — see Baseline note below.** This is a distinct device from the owned TX16S (§2.1 open question: is the TX16S's internal RF even ExpressLRS?) |

### Baseline note — three corrections to the seed doc / residue list

1. **SP3T switch was mis-bucketed.** The v0.1 seed put it in "CHECK IF I ALREADY HAVE" with
   status "unknown." Both `HARDWARE_INVENTORY.md` (no SP3T/SPDT row in any section) and the BOM
   itself (`[owner-shopping]`, "no listing chosen yet") agree it was **never ordered** — this is
   not a stock-check question, it is an unstarted purchase. Moved to BUY NOW.
2. **"Powered USB hub" conflates two different claims.** `CURRENT_STATUS.md`'s residue line and
   the seed doc's "CHECK IF I ALREADY HAVE" row cite `w17-windows-vm-validation-runbook.md` §1.8
   for a hub — but §1.8 itself (read in full this pass) only says *"enable passthrough"* for
   three USB devices in Fusion's VM settings; it names no hub requirement at all. The **actual**,
   clearly-sourced hub requirement is the GCS box's own BOM gap (`w17-gcs-box-guide.md` §2 row 4:
   *"No hub exists in the inventory — no row in any section"*). The seed's "a USB3.2 hub is
   attached now (OBSERVED)" is **not corroborated by any doc this session read** — `HARDWARE_INVENTORY.md`
   carries no hub row anywhere, so that observation cannot be independently verified from disk;
   this session did not touch hardware and cannot confirm it either way. **Practical read:**
   buy the one hub the GCS box needs (row 3); if a spare hub already sits on the owner's desk,
   it can double as the bench article for WS3's USB-passthrough validation before the box is
   built — one purchase, two uses — but the box's own requirement stands regardless of what is
   sitting on the desk today.
3. **The ELRS backup handset device itself is not on the CURRENT_STATUS.md residue list**
   (`CURRENT_STATUS.md:24-26,81-82`, which names only: 5 GHz adapter, OP-49 module, powered hub,
   SP3T switch, ELRS TX label, TX16S check). Vision decision 12 requires it to be procured
   separately from the TX16S (`w17-elrs-backup-handset.md` §1: *"procure, bind to RP1"*), and
   master-sequence stage 12 shows it "Not started." This reads as a genuine gap in the owner's
   shopping list, not a disagreement between sources — flagging it here rather than silently
   adding it to CURRENT_STATUS.md (out of this session's edit scope; a workspace-doc change is
   one repo/file at a time and CURRENT_STATUS.md's volatile-state edits belong to the program
   lead, not a single worker's procurement pass).

---

## CHECK IF I ALREADY HAVE

| # | Item | Requirement | Why | Source | Status |
|---|---|---|---|---|---|
| 1 | JST-XH connector sets (3/4/5-pin) | For CRSF (4-pin), link2 (3-pin, RX position empty), I2S (5-pin), LED (3-pin), Hall (3-pin) signal harnesses | Only **one** JST-XH item is confirmed arrived: the 2S 3-pin battery-balance extension (07-30). The five signal-harness JST-XH connectors above are a **named, still-open gap** | `w17-pdb-build-and-connector-guide.md:24-46` (§2 connector table); `w17-parts-arrival-build-prompt.md:24` (step 3: *"Confirm you have JST-XH 3/4/5-pin + XT30 for the rail branches (the only connector gaps)"*); `HARDWARE_INVENTORY.md:206` (only the balance-lead JST-XH is ✅) | **unknown — confirm before stage-2 harness build starts; XT30 itself is already ✅ on hand (§5, arrived 2026-07-29), only JST-XH is open** |
| 2 | USB-C / USB-A→C / micro-USB cables for the two ESP32 boards | Data-capable (not charge-only) | Flashing (gated, later) and general bench use | `w17-control-fw/docs/COORDINATED_FLASH.md` pointer in `w17-parts-to-gift-master-sequence.md:88` (being written); MH-ET boards are USB-C per `HARDWARE_INVENTORY.md:96` | unknown |
| 3 | A spare/general-purpose USB hub already on hand | Any hub, powered or not | Could serve as the interim bench article for WS3's USB-passthrough validation before the GCS-box hub (BUY NOW #3) is bought and built in | See Baseline note #2 above | unknown — this session found no corroborating inventory row either way |
| 4 | Multimeter with continuity beeper, resistance, and **diode mode** | Diode mode is load-bearing, not optional — it's the only check that proves the 1N5819 WS2812 supply diode is present *and* correctly oriented | A2 gate execution (every S-gate); Phase B / D8 bench bring-up; BT1's electrical-draw item | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md:109-120` (§1 Tools); `w17-control-fw/docs/PHASE_B_FIRST_POWER.md:35`; `w17-control-fw/docs/D8_BENCH_BRINGUP.md:28` | unknown |
| 5 | Oscilloscope or logic analyzer | Scope GPIO13/14/18 pulse widths + 50 Hz period; scope GPIO14/13 boot-float window | D8 Phase 3/B1.3-B1.4 (pre-ESC/servo connection proof); BT1's control-tick-jitter item | `w17-control-fw/docs/PHASE_B_FIRST_POWER.md:35`; `w17-control-fw/docs/D8_BENCH_BRINGUP.md:28`; `w17-control-fw/docs/BT1_BENCH_GATE.md` (bench-only list, "Control-tick jitter with BT active") | unknown |
| 6 | Serial monitor capable of 115200 baud | Console/telemetry reads during bench bring-up | D8/PHASE_B tool lists (same citations as rows 4-5) | unknown — likely covered by any terminal app; no dedicated hardware implied |
| 7 | A way to spin the rear axle by hand | Hall-sensor bench test | D8 Phase 8 (`w17-control-fw/docs/D8_BENCH_BRINGUP.md:28,240`) | n/a — a physical action against the assembled car, not a purchase; listed here only because the tool docs name it as a bench-session precondition |
| 8 | Bench PSU + USB cable (have them, do not connect them yet) | Explicitly named as items to have on hand for Phase B — **not to be connected during A2** | A2's own instruction: *"USB cable and bench PSU: have them, do not connect them — both are Phase B"* | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md:114` | unknown — **no current-limit spec, USB isolator, or "smoke-stopper" is named in any gate doc this session read (A2, PHASE_B_FIRST_POWER, D8, BT1); do not over-specify beyond what these four cite** |
| 9 | Mechanical-measurement tools: calipers, a rule/ruler, a depth gauge, a protractor, **four** kitchen scales | For the M-00…M-20 mechanical measurement sitting (calipers + scale + no power) — gates every production print, the cage/tray geometry, DRS linkage, and charge-flap placement | `w17-3d-codex/w17-mechanical-measurement-session-prompt.md:1-10` (this file is Codex-side but names its own tool list, found via the required workspace-doc grep sweep) | unknown — likely household/hobby items already owned; flagging because the file explicitly gates production prints on this sitting happening at all |
| 10 | Neodymium magnets 3×1 mm N35 (20 pcs) | Axle pickup magnets for the A3144 Hall sensor | Wheel-speed sensor can't be exercised without them — A3144 + ESC are already on hand | `HARDWARE_INVENTORY.md:128,228` | **⏳ ordered/in transit** (owner, 2026-07-22) — do not re-buy; just track arrival |
| 11 | Tamiya 54198 (front) + 51400 (rear) F104 tyres | 1 pack each = exactly the 4 tyres needed | Wheels can't be finished without them | `HARDWARE_INVENTORY.md:176-177,230` | **⏳ ordered/in transit** (owner, 2026-07-22, rcMart) — do not re-buy; just track arrival |

---

## OPTIONAL

| # | Item | Why | Status |
|---|---|---|---|
| 1 | External SSD ≥256 GB | VM disk if internal Mac space can't be freed for the Windows-VM validation session | owner's call — not a W17 hardware item |
| 2 | A second in-envelope 2S pack | "Carry 2 — runtime insurance" (`learning-manual/05…:395`) — **one** pack makes the car drivable; the second only removes charge-downtime and single-point-of-failure. `HARDWARE_INVENTORY.md:182,295-297` explicitly frames buying two *at once* as the practical call **once a fitting pack is found at all**, not a separate purchase decision | tied to BUY NOW #2 — buy together if/when a fitting SKU turns up |

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
| 1 | 2S balancing USB-C charge module (OP-49) | **Owner decision:** either formally adopt the on-hand IP2326 (2 units, ✅ arrived 2026-07-29) as the selected module and work through OP-49's remaining list against it, or select a different module (e.g. the premium BQ25887/MikroE Balancer 5 Click reference) and update both `HARDWARE_INVENTORY.md` and OP-49 together. **Physical possession of the IP2326 is not the same thing as OP-49's "selected."** OP-49 additionally lists as missing, even after selection: exact SKU/datasheet on record, complete board+connector+heatsink envelope, cell-interface details, the charge/run interlock implementation, charge-state access, reverse/backfeed isolation, thermal/fault evidence, and a **separate charge-safety specification that must close before any powered charge test**. One more open question if IP2326 is adopted: `w17-electrical-inputs-for-codex.md:35` warns *"Verify the board is genuinely BQ25887 (balancing). Many cheap '2S USB' boards only boost + CV with NO balancing — do not use those"* — the on-hand IP2326 units have not been verified to actually balance, only selected-by-presence | `w17-3d-codex/10_assembly_architecture/OPEN_PROBLEMS_AND_QUESTIONS.md:81` (OP-49, **BLOCKER**); `HARDWARE_INVENTORY.md:209,231-241`; `w17-electrical-inputs-for-codex.md:29-36` |

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

Sources: `w17-control-fw/docs/bill_of_materials_v2.md:104` (open confirmation #4);
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
   boost+CV-only board with no balancing) — a no-power visual/label check, not a bench test.
   Feeds directly into the WAIT-bucket OP-49 decision above. Source:
   `w17-electrical-inputs-for-codex.md:35`.
9. **The M-00…M-20 mechanical measurement sitting** (calipers, ruler, depth gauge, protractor,
   scales — no power) — fills in what has actually been printed (M-00), the S0 shell-clearance
   figure that decides the second-floor cage (M-01), and 18 more rows. This is a `w17-3d-codex`
   (Codex-territory-but-Claude-owned) session, named here only because it surfaced in the
   required grep sweep and gates BUY NOW-adjacent decisions (the cage, DRS linkage, charge-flap
   placement). Source: `w17-3d-codex/w17-mechanical-measurement-session-prompt.md`.
10. **Confirm on-hand JST-XH / XT30 connector counts against the harness build's needs** (CHECK
    IF I ALREADY HAVE #1) before the stage-2 harness-build session starts, so a mid-build supply
    gap doesn't stall a soldering sitting. Source: `w17-parts-arrival-build-prompt.md:24`.

---

## Counts per bucket

- **BUY NOW:** 5 items (5 GHz Wi-Fi adapter · in-envelope 2S pack · GCS-box USB hub · boot-mode
  selector switch · ELRS backup handset)
- **CHECK IF I ALREADY HAVE:** 11 rows (2 unresolved parts questions, 6 bench-tool/instrument
  rows named by a gate doc, 1 spare-hub question, 2 already-⏳-in-transit items tracked for
  completeness, not re-purchase)
- **OPTIONAL:** 2 items (external SSD, second battery pack) + 1 resolved-terminology note
- **WAIT:** 1 item (OP-49 charge module — owner decision required before any purchase or build
  step)

## Where sources disagreed

1. **SP3T switch bucket** — the v0.1 seed called it "CHECK IF I ALREADY HAVE / unknown"; BOM v2
   and HARDWARE_INVENTORY.md agree it was never ordered. Moved to BUY NOW (see Baseline note #1).
2. **"Powered hub" citation** — the seed's `w17-windows-vm-validation-runbook.md` §1.8 citation
   does not itself name a hub requirement; the real, sourced requirement is the GCS box's own BOM
   gap. Both the seed's "attached now (OBSERVED)" claim and any hub requirement from §1.8 are
   **not corroborated by any doc this session could read** — see Baseline note #2. This is a
   sourcing gap, not a contradiction between two authoritative docs, so it is not filed as a
   BASELINE CONTRADICTION per COMMON.md rule 9 (no two cited sources conflict — one claim simply
   has no citation this session could find).
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
- `$SP/reports/A3.md` — Wi-Fi adapter chipset research (owns BUY NOW #1's exact spec).
