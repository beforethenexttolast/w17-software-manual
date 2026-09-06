# W17 OWNER PHOTO / LABEL INTAKE — one sitting, car fully unpowered, battery disconnected (Decision Round 2, 2026-09-06)

**Why one packet.** Five Decision Round 2 items (DR2-3 PSU · DR2-4 UBEC · DR2-6 MH-ET regulator · DR2-9 blower · DR2-10 MG90S) and two
residuals (DR2-8 speaker impedance · DR2-14 heatsink clearance) are BLOCKED on things only your eyes and a phone camera can supply. The owner
instruction is to ask once, not seven times. Everything below is **no power**: battery out of the car, bench PSU **unplugged from the car**
(you may plug the PSU into the wall to photograph its display — it must not be connected to anything). Nothing here opens, weakens or
executes any gate; A2 stays NOT-EXECUTED, Phase B stays BLOCKED.

**How to deliver.** Phone photos are enough. Name each file `<item>-<view>.jpg` (e.g. `2-ubecA-top.jpg`). Where a label is small, take one
overview and one close-up with the text filling the frame, in focus, no glare. If a label or marking is absent or unreadable, a photo that
*shows* it is absent is a first-class answer — say "none" rather than guessing. Put the files anywhere and tell the next Director session
where they are; also paste the readable text of every label into the reply so it is searchable.

**What happens when the packet arrives.** A worker extracts every defensible fact (exact part identities, manufacturer figures), updates the
component identities in `HARDWARE_INVENTORY.md`-adjacent state, and re-runs the O-6 starting-current-limit derivation (v3) on a new branch:
Opus derive → Opus adversarial review → fix → fresh verify. Numbers that still cannot be derived from what you send stay BLOCKED and come
back to you as the smallest specific question. Nothing is powered as a result of this packet.

## The seven items

| # | Photograph / read | Views needed | Facts extracted | Closes / unblocks |
|---|---|---|---|---|
| **1** | **Bench PSU** | (a) front panel with the unit on and its display showing the current-limit setting at the LOWEST value you can set (output OFF, nothing connected); (b) the model/spec label (usually the back or bottom: model, input, output V/A range); (c) the current-limit control — knob, buttons or menu — and, if it has a coarse/fine knob or a digit display, one photo showing how fine the setting goes (e.g. "0.01 A" steps) | exact model · output voltage and current range · minimum reliably settable current limit and its resolution · whether CC mode is indicated (a "CC" lamp/legend) | **DR2-3** → S0's first number and every later PSU setting; the CC-duration STOP (DR2-11, 500 ms) is observable only if the CC indication exists |
| **2** | **UBEC(s)** — both units | (a) top side, (b) bottom side, (c) the voltage-selection mechanism close-up — jumper header with its current position, solder pad, DIP switch, or a printed "5V/6V" label — for EACH unit; (d) the input/output wire labels if printed | exact make/model · manufacturer continuous and peak current · efficiency curve/figure if the datasheet publishes one · **BEC #2's actual setting, 5 V or 6 V** (the jumper as fitted) | **DR2-4** → the pack-side ↔ rail-side conversion (η) for every S1–S9 limit; the servo stall column (1.9 A @ 5 V / 2.1 A @ 6 V) for S9/B3.1; D8-1c's "light load" |
| **3** | **MH-ET LIVE D1-mini ESP32 board** (one board is enough if both are the same article; say so) | (a) top side, (b) bottom side, (c) close-up of the small 3-pin/SOT-223 voltage regulator near the USB connector with its marking readable (it may be laser-etched and faint — angle a light across it), (d) the USB-port area showing whether the connector is USB-C or micro-USB | regulator part marking → its manufacturer datasheet's rated output current → the S1 ramp ceiling · USB port type (resolves `HARDWARE_INVENTORY.md`:96 vs `bill_of_materials_v2.md`:66) | **DR2-6** (S1; S2 is examined in the same derivation — there is no regulator to read on the RP1) · the USB-port doc conflict |
| **4** | **Blower fan** | the label on the fan hub or frame (model, voltage, current if printed); the connector/lead colours | exact article · manufacturer rated/max current | **DR2-9** → S6 |
| **5** | **MG90S servos** (the three fitted: DRS, pan, tilt) | the case marking/branding of each (top of the case and the label sticker if any); if you kept the listing/packaging, a photo or the listing link | branding/article → a manufacturer figure if one exists for THAT article; if only "MG90S" is printed with no maker, that is the answer and the row stays BLOCKED | **DR2-10** → S7/S8. Smallest specific question if unbranded: none — an unbranded MG90S has no defensible ceiling and is characterised at the bench under the rail's own protection only after A2/Phase B open |
| **6** | **Speaker** | the label/print on the magnet or frame (impedance "4Ω", power "3W"), and the listing if kept | impedance and rated power from the article itself (today every "4 Ω 3 W" traces to one BOM line the inventory marks "a bench spec-check") | **DR2-8** residual → S4's output-driven term |
| **7** | **Wi-Fi module + fitted heatsink + clearance** (the batch-1 photos `w17-3d-codex/images_of_parts/batch_1/BL-M8812EU2 {top,bottom,side}.jpg` already show the part; what is missing is numbers) | (a) top-down on the heatsink face with calipers/rule alongside: the heatsink footprint against the four PCB edges — margin left on each side, and the distance from the heatsink edge to the two U.FL jack roots and to the solder-pad edge (USB D+/D−/5V/GND); (b) side view with calipers: total stack height base-to-fin-tip, and PCB thickness separately (the batch-1 note says the fins look taller than the nominal 3 mm — the recorded stack is 32.4 × 32.0 × 7.0 mm); (c) the module seated where it will live (or the bench if the rear-stem structure is not printed yet), photographed from directly above and from the side with a rule: the free height above the fin tips to the nearest real obstruction and what that obstruction is (steering rod at full lock? shell inner skin? cage member?), and the free distance from each heatsink edge to the nearest wall/rib; (d) say whether the heatsink is stuck with a thermal pad/tape and whether a spare 28×28 is still on hand (inventory says 2 pcs) | the largest footprint and the maximum height a replacement can have without touching the U.FL pigtail reserves, the pad edge, the lift-out path or the steering sweep — today the CAD records only **3 mm** above the 7 mm stack to a PROVISIONAL keepout (`ZK_electronics_cassette_fit_study.md`:100), which the sitting's M-02a/b/c rows will replace with a measured figure | **DR2-14** → the procurement row's size envelope (≥ 32×32 mm footprint; height ≤ the current stack until (c) is measured); also the first real number for the Wi-Fi bay clearance, which the measurement pack has no row for (proposed M-31) |

## Per-item "what I do NOT need"
- No powered readings of any kind. No battery in the car. No USB cable into any ESP32 board.
- No disassembly beyond what is needed to see the labels; if a UBEC label is hidden under heat-shrink, photograph the heat-shrink print and say so.
- No guesses: "MG90S, no brand" or "UBEC label says 5A only" are complete answers.

## Cross-references
DR2 rulings verbatim: `2026-09-06_offline_decision_round_2.md`. Questions as originally posed: `W17_OWNER_ACTIONS.md` (Decision Round 2) and
`_handoff/2026-09-06_O6_derivation_report.md` §5. The rows each item unblocks: `bench-gates/BG-03_phase_b_first_power.md` § Starting current
limits; `bench-gates/tools/first_power_current_limits.md` T11–T13. Heatsink recommendation: BL-M8812EU2 datasheet §6.4 (≥ 32×32 mm), §3.1.
