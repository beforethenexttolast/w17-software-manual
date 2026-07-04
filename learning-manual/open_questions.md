# Open Questions

Things the manual cannot resolve from the repos alone. Grouped by who/what can answer
them. When one is answered, the affected chapters get updated and the [A] tags
upgraded.

## For you (project owner)

### Hardware & project state
1. **Where does the physical build stand right now?** Docs say nothing printed, D8
   pending (as of 2026-07-03). Have parts started arriving? Anything bench-tested?
2. **Have the orders actually been placed?** The BOM is "verified against the saved
   AliExpress cart (40 lines parsed)" — a cart snapshot, not an order confirmation.
   The belt set is flagged "⚠ stock runs low," so timing matters.
3. **Is an ESP32 available to flash today**, even bare? (Enables "flash and watch"
   exercises early; otherwise we lean on Wokwi + native tests.)
4. **Wokwi**: do you have the free license set up? Ever run `esp32dev_sim`
   interactively?
5. **Channel mapping**: the ch1/ch3/ch5…ch13 defaults are marked "verify at bench"
   (ROADMAP D2). Any of it already confirmed in elrs-joystick-control?

### History & intent
6. **Who wrote/reviewed what?** The repos read as AI-assisted builds with you as
   reviewer (CLAUDE.md "handoff", ROADMAP's adversarial reviews). Which parts do you
   already know well (so the manual can go lighter) — e.g. the electronics?
7. **The "runbooks 02–06"** referenced by `00_BUILD_SHEET.md` ("Detail in runbooks
   02–06") are not in the repo. Do they exist elsewhere (private notes?), or are the
   BOM/print-spec/atlas their surviving distillation?
8. **`camera_blower_duct.scad`** — `print_spec_v2.md` says a "parametric starter file
   provided separately." It is not in any of the three repos. Where does it live?
9. **Target machines**: is the daily dev machine this Mac, with a Windows laptop for
   gift day? (`npm run build` targets Windows; video is "verified on the target
   machine.")
10. **elrs-joystick-control**: already used with the DualShock, or bench-pending?
    Should the manual include a setup chapter for it (it's a third-party tool)?
11. **`docs/f1_hud.html`**: confirm it's the historical design mockup for the ground
    station renderer (the manual currently infers this from three evidence points),
    not something still in use.

### Manual scope & style
12. **Mechanical depth**: keep print/BOM/assembly at the current level (explained in
    chapter 05, pointers elsewhere), or write full build-along chapters?
13. **Exercises**: strictly read-and-run-tests, or also standalone practice programs in
    a new `learning-manual/exercises/` folder?
14. **Language**: English only, or bilingual key terms (Ukrainian)?
15. **Session length**: how long is a typical study session, so deep-dive chapters can
    be sized to reality?

## For the build (purchase/print confirmations recorded in the docs themselves)

From `bill_of_materials_v2.md` "Open confirmations" + `print_spec_v2.md` "Sort before
build week" + `00_BUILD_SHEET.md`:

16. **Spur ↔ belt-pulley bolt pattern** matches (check when the belt set arrives).
17. **King-pin bore = 3 mm** — measure the knuckle bore in the slicer before printing.
18. **XT60 variant** actually selected at checkout (the listing also sells XT30).
19. **TX16S internal module type** — ExpressLRS or 4-in-1? Decides whether the ES24TX
    Pro is the primary PC module or moves to the TX16S for the backup role.
20. **Printed rim + Tamiya tyre test-fit** before gluing all four (bead Ø44 front /
    Ø47 rear).
21. **Charger does 2S balance** (charger is at work; unverified).
22. **Turnbuckle count** — parts list wanted ×2 (1 + crash spare); cart line may be ×1.
23. **Shop stocks ASA** — the one un-substitutable filament (rear axle/drivetrain).
24. **`Spring_mount_2_REVISION_1` rocker seats the 68 mm coilover?** (slicer check)
    Decides hybrid vs original rear end — gates which rear parts get printed.

## For the bench (can only be answered with hardware)

These mirror the repos' own checklists — listed here so the manual tracks them:

25. **Camera codec H.264 vs H.265** (`majestic.yaml` `.video0.codec`) — the ground
    station's #1 risk (SETUP.md §1). Determines whether the WebRTC path works
    untouched.
26. **RP1 failsafe mode set to "No Pulses"** (finding A8) — receiver still in its box?
27. **ELRS link-loss characterization** (D8 Phase 2): LQ=0 burst count/timing, ~100 ms
    stats cadence, disconnect-declaration latency at the chosen packet rate,
    no-RC-before-first-bind, and whether serial-CRSF ELRS even has a Set-Position mode
    — the D4 design's assumptions, to be measured.
28. **FT232 COM-port sharing**: does elrs-joystick-control forward telemetry, or is
    com0com/hub4com needed (TELEMETRY.md)?
29. **ESC behavior**: arming timing, forward/brake configuration procedure — one bench
    session budgeted purely for ESC characterization (ROADMAP risks).
30. **Battery ADC eFuse calibration type** the boards report (default-Vref fallback =
    worse accuracy; log it during two-point calibration, D8 Phase 8).
31. **Hall line EMI at full throttle** — scope near the motor; add 1–10 nF across the
    sensor output if the edge is ugly.
32. **Synth voicing on the real speaker** — config knobs ready; PCM fallback seam
    exists (soundlight SIMULATION.md).
33. **GPIO26** (reserved ack line): confirm nothing gets wired to it (link2 spec:
    "do not connect anything to it yet").
34. **WiFi module tuning values** (`bitrate_max=12, bitrate_min=2,
    dbm_threshold=-52`, BOM) — semantics live in the OpenIPC ecosystem; verify effect
    on the real link.
34a. **Settings persistence end-to-end (C9a → hardware).** The pure `serialize`/`deserialize`
    guard chain is native-test-proven, but flash behaviour is not: verify on a real ESP32 that
    (a) edit-over-console → `save` → power-cycle actually preserves `steer.trim`/`batt.ppt`/gear
    table, and (b) a firmware **version bump + reflash** makes a device with an *old* blob in NVS
    correctly fall back to defaults (the whole point of `kBlobVersion`). D8 Phase 6/8; depends on
    C9b (`Esp32NvsStore`).

## For the simulator first run (Wokwi platform facts, from SIMULATION.md's checklist)

35. Pin labels in `diagram.json` load (devkit-v1 silkscreen names — wrong names fail
    fast with a list of valid pins).
36. CRSF actually decodes at 420,000 baud over the TX2→RX2 loopback (first `[state]`
    line shows `failsafe=0` within ~3 s); fallback = a sim-only baud-override flag.
37. The pot's `value: "69"` attr really presets the position (expect `batt≈8400mV` at
    boot).
38. `firmware.bin` boots as-is, or Wokwi needs an esptool `merge_bin` image pointed at
    from `wokwi.toml`.
39. Button bounce lands inside the 2 ms ISR lockout (rpm counts not inflated).
40. **Should `diagram.json` grow pan/tilt servos (GPIO19/23)?** The circuit predates
    the gimbal feature (D7 built 07-02; gimbal landed 07-03), so the sim doesn't
    exercise it. (A question of scope, not a defect.)

## Documentation consistency notes (small, low-stakes)

41. **D8 Phase 10 wording lags B3.8**: it says speed/gear/ERS "stay gamepad-simulated
    by design," but ROADMAP B3.8 later added real speed/gear/mode/ERS over GPS/
    FLIGHTMODE frames. The runbook step still works; its rationale sentence is stale.
42. **Atlas offline viewing**: Mermaid loads from a CDN — diagrams won't render without
    internet on first view. Worth caching locally if the atlas is needed at a bench
    with no network.

## For the next code-reading phase (the manual will answer these itself)

43. Exact bit layout of the soundlight cross-core atomic parameter word.
44. Exact integer rounding in `shapeThrottle` (the ±1 question from chapter 10 §3).
45. `main.cpp` ordering details beyond ROADMAP's summary (the line-by-line pass).
46. Contents of the two `ci.yml` workflows (currently described from ROADMAP only).
47. The HUD's exact widget-by-widget telemetry-vs-simulation precedence in
    `renderer/hud.js`.
48. `SimCrsfFeeder.cpp`'s script structure (phase timing table vs implementation).
