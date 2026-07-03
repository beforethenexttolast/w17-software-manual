# W17 RC Project — Learning Sessions

This parent folder holds three repos for a 1/10 FPV RC Formula 1 car, plus the learning
manual being written about them:

- `w17-control-fw` — ESP32 #1 control firmware (the main module; key docs in its `docs/`)
- `w17-soundlight-fw` — ESP32 #2 sound + light firmware
- `w17-ground-station` — Electron viewer app (video + HUD + telemetry)

## Goal

Help the user (beginner C++ programmer, strong on electronics/Linux) build a **complete,
beginner-friendly learning manual** for the whole project.

## Hard rules

1. **Never modify source code in the three repos** unless explicitly asked. Sessions are
   read-only on them; refactors/fixes/improvements only on explicit request.
2. **`learning-manual/` is the main persistent output.** Write manual content there,
   following its `05_manual_structure.md` and `06_learning_order.md`. Start each session
   by checking `learning-manual/README.md` for current status.
3. **Separate confirmed facts from assumptions.** Tag claims [C]/[I]/[A] (confirmed /
   inferred / assumption) and cite the evidence for inferences.

## Explanation style

- Detailed and beginner-friendly; never skip details because they seem "obvious to a
  programmer."
- Cover all relevant domains as they arise: C++, electronics, embedded systems, RC
  concepts, hardware communication, protocols, algorithms, and ground-station/desktop
  concepts.
- Always reference exact files, functions, classes, structs, constants, configs, or docs
  (e.g. `w17-control-fw/lib/failsafe/src/FailsafeStateMachine.cpp`).
- Prefer many structured markdown documents over one huge answer.
- Ignore build-output/dependency folders (`.pio/`, `node_modules/`) unless needed.
