# PROMPT — start the W17 PHYSICAL phase (new Claude Code session)

Paste into a fresh Claude Code session started in `/Users/vitaliykhomenko/Documents/projects`.

---

I'm starting the hands-on / physical phase of the W17 build. Context first:

- W17 = a 1/10 3D-printed Mercedes RC F1 car (gentle-driving showpiece, FPV realism). See your
  memory: `w17-project-intent`, `w17-packaging-architecture`, `w17-steering-servo-fit`.
- Ownership (see ./CLAUDE.md): you (Claude Code) own `w17-control-fw`, `w17-soundlight-fw`,
  `w17-ground-station`, `learning-manual`, and hardware bring-up docs. `w17-3d-codex` is the
  Codex-owned mechanical repo — READ-ONLY for you.
- Design status: the electronics packaging converged to CONDITIONAL-GO (Codex ZK study). Boards,
  camera sensor (IMX335), charger (IP2326/BQ25887) and connector map are settled in
  `./w17-electrical-inputs-for-codex.md`. What's left is PHYSICAL measurement + a no-power dry build.

HARD SAFETY GATE (non-negotiable — from w17-control-fw/CLAUDE.md):
- NO powering, flashing, battery, bench PSU, or charging until the **A2 no-power checklist** is
  filled in, reviewed, and approved (that opens Phase B). Charging the LiPo (IP2326/BQ25887) is
  powered work → Phase B only. Treat everything below as dry / no-power unless I explicitly say A2
  has passed.

WHAT I WANT THIS SESSION TO DO (guide me step-by-step; I do the hands-on, you record + track):
1. Walk the **A2 no-power checklist** — `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md`
   and `w17-control-fw/docs/D8_BENCH_BRINGUP.md`. Capture each measurement; it's the Phase-B gate.
2. Capture the **Codex fit-gate measurements** that unlock the cassette (from the ZK study /
   `w17-3d-codex/.../fit_studies/ZK_electronics_cassette_fit_study.md` and its fit-gate list):
   - **S0** — seated-shell height above the floor datum at ≥4 points (need **≥9.82 mm** for the
     mini-board stack clearance). This is the #1 unlock.
   - Full **steering sweep** with the pack + ESC present (the 8 mm moving-clearance check).
   - **Tyre arch clearance** through full steer + bump/droop (front ~3.5 mm / rear ~4 mm).
   - **Module weights** + four-corner scaling (for the real CG / balance).
3. Dry test-fits: the **DS3235SG servo side-on** in the `Servoholder` (no-force — see
   `w17-steering-servo-fit`), and mock the cassette/connector umbilical.

METHOD: record every measurement with its datum + date; separate MEASURED facts from ASSUMPTIONS;
update `w17-control-fw/CURRENT_STATUS.md` (and hand results to Codex for the mechanical registers).
Show diffs before committing anything; branch off main; don't touch the Codex repo.

Start by reading the A2 checklist + the ZK fit-gate list and giving me an ordered, printable
measurement plan (what to measure, with what, to what datum) before I pick up the calipers.
