# Session prompt — W17 parts-arrival: caliper new boards + build PDB/harness (no-power)

Paste into a Claude Code session started at `~/Documents/projects`, **after** the ordered electrical
parts arrive (MH-ET boards, cap kits, XT90-S, IP2326, battery, connectors).

---

The ordered W17 electrical parts have arrived. This is a **no-power build + measure** session — no
battery, no USB, no PSU, no flashing, nothing energized. Guide me; I do the hands-on, you record.

Read first: `w17-pdb-build-and-connector-guide.md`, `w17-batch1-measurements-for-codex.md`,
`w17-codex-batch1-recalc-prompt.md`, and `w17-control-fw/lib/config/include/config/PinMap.hpp`.

Do these:

0. ⚠ **FIRST, BEFORE ANY JOINT — the socket-stack caliper. This is a precondition, not a to-do.**
   Measure the **female header** you intend to fit on the PDB, stacked with the boards' pre-soldered
   male pins, and compare the total against the ZK cassette clearance **`S0` ≥ 9.82 mm**. (Note: that
   `S0` is the ZK clearance figure. The A2 gate formerly called S0 was **renamed SF** on 2026-08-04
   precisely to end that collision — there is no gate S0.)

   **Why it gates everything after it:** the owner's F12 decision is *socketed*, and it was recorded
   with this verification explicitly owed and a stated reopening condition. If the stack breaks the
   clearance, socketing reopens, the boards go **hard-wired**, and §3 rule 2's unseat-for-isolation
   method stops being runnable — which changes how the isolation rows execute across **S2, S4b and
   S8**. In other words this measurement decides *which version of the checklist the bench is
   running*. **Caliper first, then the first joint — not "start SF and measure as you go."**

   If it fails: **stop, report, and do not solder.** Reopening F12 is a document change before it is
   a build change.

1. **Caliper + weigh the MH-ET D1-Mini boards** (both): bare L×W×H, height with headers, USB-C plug
   protrusion, which short edge carries USB-C, mounting-hole span. → closes ZK **CAS-03** + firms the
   CG. The **MH-ET adjacency list** (§2 call-outs, currently an explicit OWED placeholder) is derived
   here too — read the pairs off the silkscreen. Its fallback, "inspect every joint," stays valid but
   slower, so this is a to-do rather than a precondition.
2. **Measure the actual 1000 µF cap** you'll use on Rail B (diameter + length) → confirm the **flat-mount
   ~8–10 mm** assumption; fold the real number into the PDB-height line of the recalc prompt.
3. **Confirm you have** JST-XH 3/4/5-pin + XT30 for the rail branches (the only connector gaps).
4. **Assemble the PDB + harness** per the build guide §5 build order: XT60 in, **single star ground**,
   both UBECs → Rail A/B, **C1 1000 µF across Rail B (stripe→GND, flat)**, 27k/10k divider → GPIO34 with
   **C3 100 nF at the pin**, output headers (genders per §2), **ESC red +5 V wire CUT + insulated**,
   IP2326 wired (2S jumper set, ≤1.5 A). Colour + label every connector.
5. **Update** `w17-batch1-measurements-for-codex.md` + `CURRENT_STATUS.md` with the real board dims/mass
   and "harness assembled — ready for A2." Hand the board dims to Codex (do not edit `w17-3d-codex`).

**STOP at "ready for A2."** Do NOT power, flash, connect a battery, or run A2 in this session — building
the harness is not the A2 gate. Show diffs before committing; branch off main.
