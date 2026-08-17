# W17 GCS box — contents, wiring, power budget, driver story

**Date:** 2026-08-17 · **Owner:** Claude Code (contents / wiring / BOM side of the gift-kit GCS box,
per `W17_PRODUCT_VISION.md` "Gift kit": *"contents, wiring and BOM = Claude side — the same split as
the car's cassette"*). Box print / mechanics / mounting geometry are **Codex** territory (see §6).
**Canonical:** this file at the workspace root is the **single source** for the box's contents and
wiring; no copies exist as of this date, and any future copy must name this file as canonical in its
own header (`WORKSPACE_MAP.md` canonical-vs-copy rule). **Docs only — no hardware was touched,
powered, or ordered for this document**; every physical claim below cites the inventory, a repo
doc, or a vendor spec, and everything unverifiable without a bench carries a `[bench-TBD]`,
`[TBD-caliper]`, `[TBD-procure: …]`, or `[TBD-owner-confirm: …]` marker.

---

## 1. Purpose — the one-cable promise

The finished W17 is a gift, and the giftee runs the ground side on **their own Windows PC** via an
installer + guide. All ground-side radio hardware therefore ships pre-assembled in one 3D-printed
enclosure — the **GCS box** — and the giftee's entire physical setup step is:

> **plug ONE USB cable from the box into the PC.**

Decided 2026-08-16 (`W17_PRODUCT_VISION.md`, "Gift kit"): the box contains the **ELRS TX module**,
the **hotspot Wi-Fi adapter**, and a **USB hub**, with a **single USB cable to the PC** and an
**optional 12 V adapter only if the USB power budget falls short** — that budget is a recorded
bench measurement still owed (vision "Open points"), so this guide designs for both outcomes and
marks the fork `[bench-TBD]` (§4). The box is what makes "hotspot + TX exist" at race time; the
software half of the same promise is the one-action bring-up wave (§7).

Not in the box: the **DualShock** (pairs to the PC directly — vision decision 10), the **iPhone**
(thin HUD client on the hotspot), and everything car-side. The **BL-M8812EU2** USB Wi-Fi module is
explicitly **not** a box part — it is the *camera's* 5.8 GHz video-link radio on the car
(`HARDWARE_INVENTORY.md` §1: *"camera's 5.8 GHz video-link radio"*; BOM §1: *"provides the WiFi AP
(camera has no radio)"*).

## 2. Contents inventory — exact on-hand parts vs to-procure

Sourced row-by-row from `HARDWARE_INVENTORY.md` (arrival evidence) and
`w17-control-fw/docs/bill_of_materials_v2.md` (part identity; the BOM wins on what a part *is*).

| # | Module | Exact part | Status / source row |
|---|---|---|---|
| 1 | ELRS TX module | **HappyModel ES24TX Pro** per the BOM §2 buy line — but the inventory row is deliberately *"ES24TX Pro (or nano)"* and the arrival wording was just **"ELRS TX"** (`CURRENT_STATUS.md` 2026-07-17; `HARDWARE_INVENTORY.md` §2, arrived 2026-07-17). The BOM lists a fanless ~250 mW nano (ES24TX Slim / BetaFPV Micro / Ranger Nano) as an *equal pick*, so the delivered variant is **not uniquely recorded anywhere**. `[TBD-owner-confirm: read the label on the physical module — Pro vs nano/Slim; §6 envelope and §4 draw both depend on it]` |
| 2 | PC ↔ TX serial bridge | **FT232RL USB-UART, Type-C board variant** — on hand (`HARDWARE_INVENTORY.md` §1, arrived 2026-07-21, "ftdi"); its BOM §1 line already names this exact duty: *"PC↔ELRS-module CRSF link (set 3.3 V jumper)"* |
| 3 | Hotspot Wi-Fi adapter | **Ralink RT5370 USB Wi-Fi** — on hand (`HARDWARE_INVENTORY.md` §D: *"RT5370 USB Wi-Fi (GS bench SoftAP) ✅ on hand (owner-confirmed 2026-07-22)"*). It was in the 07-17 "still awaited" list and cleared by the 07-21/07-22 pass. Standing caveat carried on its own row: **"AP-mode support on Win 10/11 still to verify on the bench"** `[bench-TBD]`. If that verification fails, this slot becomes `[TBD-procure: USB Wi-Fi adapter whose Windows 10/11 driver supports hosted-network/Mobile-Hotspot AP mode]` |
| 4 | USB hub | **No hub exists in the inventory** — no row in any section. `[TBD-procure: USB 3.x hub, ≥3 downstream ports, uplink cable long enough for desk placement, and — strongly recommended (§4) — a self-powered mode with a DC barrel input so the 12 V option is a cable, not a redesign]` |
| 5 | Optional 12 V adapter | Contingent on the §4 measurement. `[TBD-procure: only if the powered-hub decision falls that way — a 12 V (or hub-matching voltage) mains adapter for the hub's DC input]` |
| 6 | Single USB uplink cable | Covered by BOM §D build-from-stock/consumables (not delivery-tracked); type follows the hub choice. |

## 3. Internal wiring / topology

The control-signal chain is the recorded one (`learning-manual/01_total_system_overview.md` §3–§4):
PC (mapper) → USB serial → FT232RL → **CRSF** → ELRS TX module → 2.4 GHz ELRS air link → RP1 on the
car; telemetry rides the same shared serial back. Wiring mechanics below follow the mapper fork's
own setup doc (`w17-mapper/README.md`, "Connecting with an FTDI Adapter" + "How to power the ELRS
transmitter module").

```
                GCS BOX (3D-printed enclosure — Codex)                giftee's Windows PC
  +--------------------------------------------------------------+
  |                      USB hub  [TBD-procure]                   |
  |     +-----------+--------------+-----------------+           |
  |   port 1      port 2         port 3            uplink -------+---- ONE USB cable ---> PC
  |     |           |              |                              |     (USB 3.x port
  |  FT232RL     RT5370       (b) module-power                    |      preferred, §4)
  |  USB-UART    Wi-Fi        USB pigtail 5V/GND                  |
  |  (COM port)  (hotspot     --> ES24TX JR-bay VCC/GND           |
  |     |         host)       [alt to (a); pick ONE]              |
  |     |                                                         |
  |     | TX pin --- inverted half-duplex CRSF ---> CRSF/S.PORT   |
  |     |                                            pin          |
  |     | (a) 5V + GND -----------------------> JR-bay VCC/GND    |
  |     |                                      ES24TX ELRS TX     |
  |     |                                      module             |
  |     |                                        | antenna        |
  |     |                                        v                |
  |     |                                   outside the box       |
  |                                                               |
  |  optional: 12 V DC barrel ---> hub DC-in (powered-hub mode    |
  |            ONLY — see the hard rule below)     [bench-TBD]    |
  +--------------------------------------------------------------+
```

Wiring notes, each with its source:

- **FT232RL → module:** FTDI **TX pin → the module's CRSF pin**; common **GND**. The FTDI must be
  reprogrammed once with **FT_Prog** for the module's **inverted half-duplex UART** framing —
  `w17-mapper/README.md`: *"the ELRS transmitter I/O pin works as an inverted half-duplex UART."*
  This is **owner build-time prep, never a giftee step**. Set the FTDI board's **3.3 V jumper**
  (BOM §1 line). Serial runs at **921600 baud** (`learning-manual/15…` §diagram); the mapper opens
  the FTDI's virtual COM port — the `"REPLACE-WITH-COM-PORT"` placeholder in `configs/w17-ds4.json`
  (mapper `w17-audit-wave1` branch) is **this** port on the giftee PC `[bench-TBD: pin the COM
  identity on the real machine — packet §4 item 7]`.
- **Module power, option (a):** from the FTDI header's 5 V/GND pins — the fork README documents
  exactly this (*"You can also power the ELRS TX module using the Ground and 5 Volts output
  pins"*). Cost: the module's whole draw rides the FTDI's hub port (§4).
- **Module power, option (b) — recommended on paper:** a sacrificial USB pigtail from its **own hub
  port** to the JR-bay **VCC/GND** (module spec accepts 5 V: *"Power supply voltage: 5v~10v"*,
  happymodel.cn ES24TX Pro page, fetched 2026-08-17). Spreads the load across two hub ports so no
  single port carries FTDI + module together. Decide (a) vs (b) at the bench with the ammeter
  `[bench-TBD]`.
- **HARD RULE — no raw 12 V to the module.** The ES24TX Pro input spec is **5–10 V** (vendor page
  above). The optional 12 V adapter feeds **only the hub's DC input**; every device still sees USB
  5 V. (The fork README's JR-bay note says *most* modules take 5–12 V — the vendor's own 5–10 V
  spec is narrower and wins.)
- **One power tree, no second source.** `w17-mapper/README.md` warns, verbatim: *"your ELRS TX is
  in a circuit with your computer's motherboard. Do not connect any external power source (such as
  a LiPo Battery) to the ELRS TX."* Both options (a) and (b) keep the module inside the single
  USB/hub power tree with a common ground, which is the configuration that warning permits; a
  powered hub keeps this true (the 12 V enters through the hub's regulated rail, not the module).
  Confirm no ground-loop/backfeed surprises at the powered-hub bench pass `[bench-TBD]`.
- **RF output pinned low.** The BOM §2 line records the operating intent: *"run at low power
  (25–100 mW)"* — which is also what keeps the USB budget plausible (§4) and is more than enough
  for a 1/10-scale car that drives *"gently — indoors and on smooth pavement"* (vision ¶1).
- **Antenna outside the print.** The module's stock antenna (vendor: 4.18 dBi) must exit/mount
  through the shell — connector type on the physical unit `[TBD-owner-confirm: RP-SMA vs fixed]`,
  placement/keep-out = Codex (§6).
- **Maintenance port (proposal, not a decision):** route the module's own firmware-flash USB
  connector to hub port 3 (or a blanked internal pigtail) so future **ExpressLRS** updates don't
  require opening the box. The fork README's "Connecting with USB cable" section is about using
  USB *as* the CRSF path — the W17 route is the FTDI, so this port would be flash-only.

## 4. USB power budget — the powered-hub decision

The vision left exactly one open electrical question here: *"powered hub (12 V) or bus-powered —
measure on the bench"* (`W17_PRODUCT_VISION.md`, Open points + backlog "GCS box"). That measurement
is **owed and not done** — everything below is the paper budget the measurement will confirm or
overturn. **The real number is `[bench-TBD]`: TX at its configured output power + RT5370 in AP mode
under load, summed on the ammeter.**

Per-device 5 V draw estimates, worst-case-leaning:

| Device | Estimate | Basis (citation) |
|---|---|---|
| ES24TX Pro @ ≤100 mW RF | **~300–500 mA** `[A — no vendor mA figure exists]` | Vendor spec page publishes voltage (5–10 V) and RF power only, **no current figure** (happymodel.cn ES24TX Pro page, fetched 2026-08-17). Upper bound is corroborated in-repo: `w17-mapper/README.md` states USB(-class 5 V) power sustains roughly **≤100 mW RF** before the module *"brown-outs and reboots"* — i.e. the ≤100 mW operating point lives within a ~500 mA USB2-class budget. A 1000 mW setting would blow both this budget and that bound — RF stays pinned low (§3). |
| RT5370 Wi-Fi (AP mode) | **≤160 mA** | Dongle datasheet: *"DC 5.0V ± 5% / <160 mA"* max (FX-5370E RT5370 dongle datasheet, cctvdi.com PDF, fetched 2026-08-17); idle is far lower. AP mode with continuous HUD/bridge traffic ≈ the max figure — treat 160 mA as the planning number. |
| FT232RL board | **~15–50 mA** | FTDI FT232R datasheet operating current **15 mA typical**; board LEDs/regulator overhead on the breakout add a little `[I]`. |
| USB hub (own controller) | **~100 mA** `[A]` | Class-typical allowance; actual figure comes with the procured hub's datasheet `[TBD-procure: record it at selection]`. |
| **Worst-case sum** | **≈ 775–810 mA** | — |

Against the port budgets a giftee PC can actually be assumed to have:

- **USB 2.0 port: 500 mA** → the sum **fails on paper**. Bus-powered operation off a USB 2.0 port
  is out unless the bench measures dramatically under the estimates.
- **USB 3.x port: 900 mA** → the sum fits with **~10–15 % margin** — thin, and margin-eating
  peaks (module TX bursts, Wi-Fi ramp) are exactly what an average-reading ammeter hides.
- Per-port limits inside the hub matter too: with option (a) one hub port carries FTDI + module
  together (~350–550 mA) — inside a hub's per-port allowance only if the hub honors 900 mA-class
  ports; option (b) sidesteps this (§3).

**Decision criteria for the powered hub (12 V option), stated now so the bench session just
applies them:**

1. If the giftee PC offers **only USB 2.0** ports → powered hub. (Gift-kit reality: the PC is not
   under our control; the install guide must say "use a blue/USB 3 port" and the box must survive
   the giftee ignoring that only if the bench says it can.)
2. If the measured sustained draw exceeds **~700 mA** (i.e. <25 % margin on a 900 mA port) →
   powered hub.
3. If the bench shows **any** brown-out, re-enumeration, or module reboot during a full
   hotspot + TX + telemetry session → powered hub, regardless of the average reading.

Recommendation (proposal, owner's call): procure the hub **self-powered-capable** from the start
(§2 row 4) — if bus power passes the bench, ship without the adapter and the one-cable promise
holds; if it fails, the fix is adding the 12 V adapter, not re-buying the hub. Bandwidth is a
non-issue either way: RT5370 is USB 2.0 / 150 Mbps class and the FTDI is full-speed — the USB 3.x
preference above is **about the 900 mA power budget, not data**.

## 5. Driver story on the giftee PC

What actually has to install on a stranger's Windows machine, per device class — the gift-kit
"needs a real installer … and driver notes for the GCS-box adapters" backlog line
(`W17_PRODUCT_VISION.md`, one-action race-day startup item):

| Device | Windows behavior | Action needed on the giftee PC |
|---|---|---|
| FT232RL | FTDI VCP driver ships via **Windows Update** on Win 10/11 as a rule; device appears as a numbered **COM port**. The fork README's FT_Prog reprogramming (§3) is **already done at build time** — never on the giftee PC. | Usually none `[I — class behavior; verify on the real machine, bench-TBD]`. The one-action orchestration must **discover/pin the COM port** — the saved-profile placeholder from packet §4 item 7. |
| RT5370 | In-box/Windows-Update Ralink/MediaTek driver expected on Win 10/11 `[I]`. The load-bearing question is **AP capability**, not the driver install: the GS hosts the hotspot itself, *"Mobile Hotspot backend preferred; legacy `hostednetwork` fallback targets the RT5370, needs elevation"* (`CURRENT_STATUS.md`, pending-validations, in-app setup flow). | The §D verification: **AP-mode support on Win 10/11** `[bench-TBD]`. If the legacy fallback path is the one that works, the install guide inherits an elevation prompt to explain in giftee language. |
| ES24TX module | **No PC driver at all** — the PC sees only the FTDI serial port; the module hangs off it. (Its own USB connector is ELRS-flash-only, §3.) | None. |
| USB hub | Generic class driver. | None. |
| Ground station | Not a driver, but the same install story: **unsigned NSIS installer** built in CI since the 2026-08-17 GS merge (`learning-manual/21_rebuild_ground_side_install.md` sources; first artifact still unconfirmed at that stub's writing). | Run the installer; expect the SmartScreen-style unsigned-app friction — chapter 21's problem to document. |
| Mapper | Packaged binary loading `configs/w17-ds4.json` headless (`--config-file-path`, no editor UI — chapter 21 stub). Two Windows-bench placeholders live in that profile: pad id + **the box's COM port**. | None beyond the packaged install; placeholders pinned at the bench `[bench-TBD]`. |

**PC prerequisites the box does NOT cover** — for the install guide's checklist:

- **A 5 GHz-capable internal Wi-Fi adapter.** The video path is the camera's own 5.8 GHz AP
  (BL-M8812EU2, car side — §1 here; BOM §1) which the PC joins while the RT5370 hosts the 2.4 GHz
  hotspot for the iPhone `[I — derived: the recorded design gives the PC both roles at once
  (`learning-manual/01…` §4 step 8 video-to-laptop + the GS-hosted hotspot above), and one adapter
  cannot be a 5.8 GHz station and the hotspot host simultaneously — this is precisely why the box
  carries a dedicated hotspot adapter]`. A giftee PC without 5 GHz Wi-Fi cannot show video —
  surface this as an owner decision: accept it as a stated PC requirement, or grow the box by a
  5.8 GHz-capable adapter `[TBD-owner-confirm]`.
- **One free USB 3.x port** (§4 criterion 1).
- Windows 10/11 — everything above is unvalidated on real hardware today: *"Windows specifics …
  are unit-tested against canned output on macOS only — recorded validation debt"*
  (`learning-manual/21…` stub, citing `CURRENT_STATUS.md`) `[bench-TBD]`.

## 6. Box mechanics — the Codex split, and what Codex needs from this doc

Per the vision's gift-kit paragraph the enclosure — print, mounting bosses, cable strain relief,
venting, lid/service access — is **Codex** (`w17-3d-codex` side), the same split as the car's
cassette. This section is the Claude-side input package for that work, in the same spirit as
`w17-electrical-inputs-for-codex.md` was for the cassette.

Per-module envelope inputs:

| Module | Dimensions | Source / confidence |
|---|---|---|
| ES24TX Pro | **70 × 49 × 32.5 mm, 51 g** (without antenna) | Vendor spec (happymodel.cn ES24TX Pro page, fetched 2026-08-17). **Only valid if the on-hand unit is the Pro** — `[TBD-owner-confirm: variant (§2 row 1)]`, then `[TBD-caliper: confirm on the physical unit; vendor dims are pre-antenna and may exclude the JR hook]`. If the unit is a nano/Slim the envelope shrinks and this row is re-measured, not scaled. |
| FT232RL board (Type-C variant) | unrecorded | `[TBD-caliper]` — no measurement exists anywhere in the workspace. |
| RT5370 dongle | unrecorded | `[TBD-caliper]` — inventory row records existence, not size. |
| USB hub | unknown until procured | `[TBD-procure: record dims at selection]`, then `[TBD-caliper]` as-built with cables seated. |
| 12 V adapter / barrel jack | contingent (§4) | dims follow the hub decision. |

Non-dimensional requirements Codex should design to (from §3/§4 above):

1. **Antenna exits the enclosure** — RF does not transmit from inside a closed box pressed against
   a hub PCB; connector/keep-out after `[TBD-owner-confirm: antenna connector type]`.
2. **Venting near the module** — the module is the box's only meaningful dissipator (RF chain;
   Pro variants carry active cooling per vendor listings `[TBD-owner-confirm on the unit]`); at the
   pinned 25–100 mW it should run mild, but a sealed print is the wrong default. Vent sizing
   sanity-check at the power bench `[bench-TBD]`.
3. **Port cutouts:** single uplink exit, optional DC barrel (blanked if unused), and the proposed
   flash-access port (§3, proposal — Codex may ignore until the owner adopts it).
4. **One-cable ergonomics:** the uplink cable gets strain relief; internal pigtails are captive.
   Cable lengths are **proposals for Codex to finalize against the print**, per the same rule as
   the PDB guide's connector table (`w17-pdb-build-and-connector-guide.md` §2).

## 7. Relationship to the race-day one-action flow

The operator model's first derived implication (`W17_PRODUCT_VISION.md`): *"One-action race day:
hotspot + mapper (saved profile) + ground station + iPhone bridge come up together."* That flow is
a **planned software wave** — *"Race-day one-action orchestration in the GS (now unblocked by the
committed mapper profile)"* is the first proposed next wave in
`2026-08-16_orchestration_review_packet.md` §6 — and this box is its **hardware precondition**: the
one action can only *start* a hotspot and *open* a TX COM port if the adapter and the module are
already plugged in, powered, and enumerated. Box in, cable in, one action — that is the whole
giftee ritual; until the orchestration wave lands, `learning-manual/21…` documents the same
bring-up as a numbered manual sequence (its stub says exactly this).

The dependency also runs backwards: the orchestration wave should **fail in giftee language** when
the box is absent (no COM port, no AP-capable adapter) — plain-language failures are a vision
requirement, and "the box is unplugged" will be the most common failure a giftee ever produces.

## 8. Cross-references

- `W17_PRODUCT_VISION.md` — gift kit decision, GCS-box backlog entry, power-budget open point.
- `HARDWARE_INVENTORY.md` §1, §2, §D — the on-hand rows cited in §2.
- `w17-control-fw/docs/bill_of_materials_v2.md` §1–§2 — part identities (BOM wins on identity).
- `w17-mapper/README.md` — FTDI wiring, FT_Prog inversion, module power options, the
  no-external-power warning (fork of the upstream elrs-joystick-control docs).
- `configs/w17-ds4.json` (mapper `w17-audit-wave1` branch) — the saved profile whose COM-port
  placeholder this box's FTDI fills.
- `w17-elrs-backup-handset.md` — the no-laptop backup TX that bypasses this box entirely.
- `learning-manual/21_rebuild_ground_side_install.md` — the manual chapter that will consume this
  guide once the giftee-PC end-to-end test exists.
- `w17-pdb-build-and-connector-guide.md` — style/precedent for this doc class; its "reconcile
  against the source before building" rule applies here to every vendor figure `[bench-TBD]`.

## Addendum 2026-08-17 — owner decisions on the open questions

- **5.8 GHz hotspot adapter: APPROVED for the box BOM** (owner; replaces the "giftee-PC
  requirement" alternative). Purchase spec: dual-band 802.11ac USB adapter whose
  **Windows 10/11 driver supports HOSTING Mobile Hotspot on the 5 GHz band** (the Wi-Fi
  Direct GO / SoftAP path — client-only 5 GHz adapters exist and do not qualify); USB-A;
  external antenna preferred for AP duty; proven chipset families: RTL8812BU / RTL8812AU
  class (examples, not endorsements: TP-Link Archer T3U Plus, ASUS USB-AC53 Nano).
  Verify at purchase: explicit 5 GHz AP/hotspot support in the driver notes. Verify at
  bench [bench-TBD]: Windows Mobile Hotspot pinned to 5 GHz; the camera's RTL8812EU joins
  it; sustained-bitrate soak. The RT5370 demotes to spare / 2.4 GHz fallback.
- **Backup handset class: gamepad-style ELRS** (LiteRadio-class; §3's requirements table
  applies unchanged).
