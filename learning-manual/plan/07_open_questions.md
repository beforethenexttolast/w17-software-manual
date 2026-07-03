# 07 — Open Questions (need your answers)

Grouped; none block Phase A/B of the learning order, but answers will shape the manual's
emphasis and let me mark more claims [C] instead of [A].

## Hardware & project state
1. **Where does the physical build stand today (2026-07-03)?** The BOM (v2) says "nothing
   printed yet" and D8 is "gated on parts." Have parts started arriving? Anything already
   bench-tested? (This decides whether part 7 — the bench companion — should be written
   early or last.)
2. **Do you currently have any ESP32 on hand to flash**, even bare (no car)? If yes, the
   manual can add "flash it and watch the serial monitor" exercises early; if no, we lean
   on Wokwi + native tests.
3. **Is the Wokwi setup licensed/working on your machine** (it needs a free license per
   `docs/SIMULATION.md`)? Have you ever run `esp32dev_sim` interactively?
4. **The TX-side channel mapping** (steering ch1, throttle ch3, arm ch5, … mode ch13) is
   marked "placeholders, verify at bench" in ROADMAP D2. Has any of it been confirmed in
   elrs-joystick-control yet, or is that still open?

## Intent & history
5. **Who wrote the code?** ROADMAP reads like an AI-assisted build (adversarial reviews,
   "Claude Code handoff" in CLAUDE.md's title). Were you the reviewer for all of it, and
   are there parts you already understand well that the manual can compress (e.g., the
   electronics, given your stated strength there)?
6. **Ground station target machine:** docs say the .exe/Windows is the target and video
   is verified "on the target machine." Is your daily driver this Mac, with a separate
   Windows laptop for gift day? (Affects which platform the manual's run-it exercises
   assume — note `npm run build` is `--win`.)
7. **elrs-joystick-control**: have you already used it with the DualShock, or is that
   also waiting for the bench? Should the manual include a chapter on that external tool's
   setup, or is it out of scope?
8. **The `f1_hud.html` mockup**: is my inference right that it was the design prototype
   for the ground-station renderer, and it's now historical? Or is it still used somewhere?

## Scope of the manual
9. **Mechanical/print depth:** should the manual cover the mechanical docs (print spec,
   BOM, assembly atlas Part B) as first-class chapters, or keep them as the current
   "read when parts arrive" pointers? (Current plan: pointers only.)
10. **C++ primer depth:** the plan teaches C++ *on this codebase only*. Do you also want
    small standalone exercises (scratch programs compiled outside the repos, e.g. in
    `learning-manual/exercises/`), or strictly read-and-run-tests with no new code?
11. **Language:** manual in English, or would Ukrainian (or bilingual key-terms) serve
    you better?
12. **Session cadence:** roughly how long is a typical study session for you? (Chapters
    are being sized to ~one session each; I'd rather size them to reality.)

## Small factual verifications (I'll confirm these in code next pass; flag if you already know)
13. GPIO26 (board #1 ← board #2 ack line) is spec'd "reserved, not driven" — confirm
    nothing is physically wired there in your planned harness.
14. The RP1 failsafe mode ("No Pulses" — finding A8) — has the receiver been configured
    yet, or is it still in its box?
15. The camera: BOM says already flashed + tuned (`majestic_fpv.yaml`). Do you know
    whether it's currently set to H.264 or H.265 (`.video0.codec`)? This is the ground
    station's #1 risk item and shapes how much the manual invests in the transcode path.
