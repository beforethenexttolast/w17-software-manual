# Session prompt — W17 A2 no-power checklist execution (the Phase-B gate)

Paste into a Claude Code session started at `~/Documents/projects`, **only after** the harness is
assembled (parts-arrival build session done). This is the gate that unblocks Phase B.

---

The W17 harness is built (loose modules are now wired per the connector map). I want to **execute the A2
no-power checklist** — the Phase-B gate. Guide me line by line; I probe, you record.

**Golden rules:** battery stays disconnected and out of reach. **No USB, no bench PSU, nothing flashed.**
**Multimeter only** (continuity + resistance + diode mode). If any reading is suspicious → **stop,
photograph, report** — never "try again with power."

Read + follow: `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` (the canonical
checklist), cross-referenced with `w17-pdb-build-and-connector-guide.md` and
`w17-control-fw/lib/config/include/config/PinMap.hpp`.

Walk every section and fill the §11 table:
- §2 visual (solder bridges, polarity, connector orientation, ESC red-wire isolated, divider, Hall pull-up)
- §3 pin continuity + adjacency (C1–C13, board #1) + the WS2812 level path (board #2)
- §4 battery divider resistances (≈10k / ≈27k / ≈37k)
- §5 Hall pull-up to **3V3** (not 5 V) + cap
- §6 ESC BEC **red-wire isolation** (hard gate)
- §7 common-ground star (beep to every module GND)
- §8 WS2812 level path (330 Ω, 1N5819 diode-mode, bulk cap)
- §9 servo/ESC signal sanity + §10 photo set

Record real readings + PASS/FAIL in the §11 table, note any PASS-with-note deviations, and capture the
exact reading + photo for anything hitting a §13 hard stop. Then **paste the filled table back for
review** — A2 is closed and Phase B gated open **only** on a clean review. Update `CURRENT_STATUS.md`.
Show diffs before committing; branch off main. **Still NO POWER** — A2 is entirely a multimeter exercise;
powering is Phase B, which comes only after A2 is reviewed and approved.
