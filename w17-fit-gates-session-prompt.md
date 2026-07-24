# Session prompt — W17 printed-part fit-gates (no-power, do now)

Paste into a Claude Code session started at `~/Documents/projects`.

---

I'm running the **printed-part fit-gates** for the W17 cassette — a no-power physical session. All parts
are printed (test-grade quality; measurements are MEASURED-but-provisional). Guide me step by step; I do
the hands-on, you record + track.

Context to read first:
- `w17-batch1-measurements-for-codex.md` (measured envelopes/weights so far)
- `w17-pdb-build-and-connector-guide.md` (electrical build spec)
- The measurement plan (Tracks C + D) — S0, steering sweep, tyre arch, servo dry-fit
- Codex ZK study + `p0_d09_d26_steering_servo_fit.md` for the datums/targets

Do these (datum = DAT-F: floor top Z0, X+ forward, L from centreline):
1. **S0** — seated-shell interior roof height above DAT-F at **≥4 points** over the two wall seats; compute
   `S0 = board-top 32 + 5 − roof-Z`; target **≥ 9.82 mm**. Worst point ≈ X+3/L−37 (roof Z27.18).
2. **Steering sweep** — DS3235SG in the printed `Servoholder` on the floor, pack + ESC bodies present;
   sweep the horn **by hand, unpowered, gently** neutral→L→R; min moving clearance to KO-01 (Z22), pack, ESC.
   Target ≥ 8 mm. (Confirms/updates the PDB-height recalc.)
3. **Tyre-arch clearance** — full steer + bump/droop, front ~3.5 / rear ~4 mm. (Needs tyres — if not yet
   on hand, mark BLOCKED-on-tyres.)
4. **Servo no-force dry-fit** — DS3235SG side-on into the `Servoholder` arch (42×18.5); measured servo face
   is 40.25×20.2 → ~1.7 mm interference expected. Record: seats free / light interference / won't seat.
   Also pin shaft-centre orientation (boss-forward X−46.76 vs reversed X−66.76).

Method: record each reading value + unit + datum + date + instrument, tagged **provisional (test print)**.
**Do NOT file/force** any test part. Then update `CURRENT_STATUS.md` and write the results into a Codex
handoff (feeds ASM-08, CAS-02, tyre-arch) — **do not edit the `w17-3d-codex` repo**. Show diffs before
committing; branch off main. **NO POWER** — this changes no gate; A2/Phase B stay as they are.
