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
    C9b (`Esp32NvsStore`). **Now unblocked by C9b** (console + store side is explained/tested via
    mocks); the remaining gap is purely the real-flash proof.
34b. **UART0 tuning console on the bench (C9b → hardware).** `Esp32SerialConsole` (UART0, 115200)
    is excluded from native tests. Verify on a real ESP32 (`esp32dev_tuning` build) that typed
    lines read/write correctly, CRLF is tolerated, and the flood guard trips on an over-long line.
    D8 Phase 6/8. *The second half of this item ("confirm the console-free gift firmware still
    loads NVS-saved tuning") was ANSWERED NEGATIVELY by C10 (2026-07-05): the plain `esp32dev`
    build has **no load path at all** — superseded by #49.*

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
    — **ANSWERED by S3** (2026-07-05): documented in `EngineSynth.hpp:12–27` and matched by
    `packParams`/`applyPackedParams`. Layout of the one `std::atomic<uint32_t>`:
    **bits 0–15 = engineRpm** (0–65535), **bits 16–23 = volume** (0–255, 0 = silent),
    **bit 24 = ersWhine**, **bit 25 = limiterActive**, **bit 26 = overrunActive**,
    **bits 27–31 reserved**. One aligned 32-bit word ⇒ torn-free lock-free hand-off; the
    dead-man heartbeat is a *separate* atomic (ch07 §6). Note what is NOT in the word:
    throttle and ignition state (see #52c). The remaining half — that `main.cpp` actually
    packs EngineSim's output into this atomic each control tick, and **where the `volume`
    byte is derived from** (there is no `volume` field in `EngineState`) — is S5.
    (`03_sound_synthesis.md` §3.2, §0.)
44. Exact integer rounding in `shapeThrottle` (the ±1 question from chapter 10 §3).
    — **ANSWERED by C6** (2026-07-03 review): the integer math was re-derived
    line-by-line; chapter 10 §3's worked example (125) is exact, no ±1 drift. Chapter 10
    updated (2026-07-05).
45. `main.cpp` ordering details beyond ROADMAP's summary (the line-by-line pass).
    — **ANSWERED by C10** (2026-07-05): `code_explained/control_fw/10_main_integration.md` §4.
46. Contents of the two `ci.yml` workflows (currently described from ROADMAP only).
    — **Control-fw's ANSWERED by C10 §9** (push/PR triggers, cached PlatformIO, native tests +
    esp32dev + esp32dev_sim builds; note: `esp32dev_tuning` is NOT built by CI). Soundlight's
    diff remains for S5.
47. The HUD's exact widget-by-widget telemetry-vs-simulation precedence in
    `renderer/hud.js`.
48. `SimCrsfFeeder.cpp`'s script structure (phase timing table vs implementation).
    — **ANSWERED by C10 §5.4** (2026-07-05): the 10-phase implementation matches
    SIMULATION.md's demo table exactly; neither drifted.

## For you (project owner) — new, found by C10 (2026-07-05)

49. **How should bench tuning reach the delivered gift firmware?** C10 found that the plain
    `esp32dev` build compiles out the *entire* settings subsystem (every include and call sits
    behind `#ifdef W17_TUNING_CONSOLE` in `main.cpp`) — the NVS blob saved during bench tuning
    **persists in flash but is never read** by the delivered firmware, which runs compiled-in
    defaults. D8 Phase 11's "reflash plain `esp32dev` — the NVS-saved tuning persists" is
    literally true but functionally **discards the tuning**. Options: (a) transcribe the tuned
    values into the source-code defaults and rebuild plain; (b) deliver the `esp32dev_tuning`
    build (accepting an open UART0 console); (c) add a load-only NVS path to the plain build
    (a code change). Which is intended? (C10 §8; supersedes the load half of #34b.)

## Documentation / build-config consistency — new, found by S1 (2026-07-05)

50. **Dangling `hal` dependency in the copied `lib/link2/library.json` (soundlight).** The
    verbatim copy of link2 keeps `"dependencies": { "hal": "*" }` — correct in the control repo
    (where `Link2Sender` includes `hal/IByteSink.hpp`), but in `w17-soundlight-fw` there is **no
    `lib/hal`** and nothing `#include`s a hal header (`Link2Sender` wasn't copied). The dep is
    declared but points at nothing and is needed by nothing. **Benign for the native build**
    (verified: 40/40 pass — LDF never resolves it because nothing includes it); benign for
    `esp32dev`/`esp32dev_sim` is **very likely but PROVISIONAL until S5** (soundlight builds +
    ci.yml). It is arguably *intentional* — editing `library.json` would violate the do-not-fork
    rule; the cost of byte-identical copy discipline is one harmless stale metadata line. Low
    stakes; no action unless S5's build proves otherwise. (S1 §1.4)

51. **`VehicleState.rpm` (wheel rpm) has no consumer on board #2 — found by S2 (2026-07-05).**
    EngineSim derives engine rpm from *commanded throttle* (the spec's `Link2Frame.hpp` comment
    explicitly offers "derive engine revs from throttlePercent or scale this" — the former was
    taken), and a repo-wide grep finds **nothing** outside the link2 codec/monitor reading the
    received wheel-rpm field. Consequences: (a) the field is carried on the wire but presently
    decorative on the receiving end; (b) `Link2Monitor`'s "a stale rpm would drive the engine
    sound and speed readout" comment is defensive/forward-looking, not descriptive — the
    rpm-zeroing on staleness is still correct design (future consumers inherit safety). Not a
    defect; logged so S3–S5 walkthroughs confirm it in context and so a future feature (e.g. a
    speed-linked light effect) knows the field is free. (S2 §2.1, §11-observation)

52. **Repo module docs lag the `soundsynth` code — found by S3 (2026-07-05).** Reading every
    line of `EngineSynth.cpp` turned up three descriptions that overstate or misname what the
    code does. None is a defect (the code is correct and tested); all are documentation drift,
    and the repo files are read-only so only the *manual* was corrected. (a) **"Per-revolution
    amplitude modulation (the 'lumpy' idle)"** — advertised by `w17-soundlight-fw/CLAUDE.md`
    (soundsynth bullet) and echoed by ch07 §4 — **does not exist in `render()`**: there is no
    per-rev envelope; the idle's life comes entirely from S2's ±120 rpm wobble bending the
    pitch. The unused member `sampleCounter_` (written each frame at `EngineSynth.cpp:147`, read
    nowhere) may be that feature's fossil [I]. (b) **"Throttle-correlated noise"** (the
    `noiseAmpMax` field comment, the `render()` comment, and `CLAUDE.md`) is actually
    **rpm-correlated** (`noiseAmp = noiseAmpMax * rpm / 15000`, `EngineSynth.cpp:109`) — throttle
    is not even a synth input. The effect is throttle-correlated only *indirectly* (S2 maps
    throttle→rpm), so the wording is lineage, not a live bug. (c) Ch07 §6's packed-word field
    list said "rpm, throttle, flags" — the actual second field is **volume**, not throttle (#43).
    **Ch07 §4 and §6 have been corrected in the manual.** Minor stale code comments folded in
    here: `phaseIncForMilliHz` narrates a "avoid 64-bit divide" optimization it doesn't perform
    and misquotes its constant (194.98 vs ≈194.78); the `SineTable` comment narrates three
    abandoned designs. All cosmetic. Low stakes; no action beyond the manual corrections already
    made. (`03_sound_synthesis.md` §7, §4.1, §4.2, §4.7c/e.)

## For you (project owner) — new, found by S3 (2026-07-05)

53. **The synth's parameter smoother truncates and "parks" below its target — is that intended
    voicing?** `EngineSynth::render` smooths rpm/volume with `smooth += (target − smooth) >> 6`
    (`EngineSynth.cpp:82–83`). Two issues, both verified by a scratchpad harness compiled against
    the real source: (1) the code comment says "Move ~1/1024 of the gap each sample: ~23 ms time
    constant," but `>> 6` is **1/64** of the gap, τ ≈ **2.9 ms** — the comment is simply wrong
    (1/1024 would be `>> 10`). (2) More importantly, integer right-shift **truncates toward zero**,
    so an *upward* approach stops once the remaining gap is < 64: **volume target 255 approached
    from 0 parks at 192** (renders at 192/255 ≈ **75 % of full scale**), and **any volume target
    1–63 approached from silence stays exactly 0 — inaudible**. (rpm parks ≤ 63 low too, but that
    is a harmless ~0.4 % flat pitch.) A *downward* approach converges exactly (arithmetic shift of
    a negative gap keeps stepping), so `volume = 0` genuinely silences — which is why
    `test_zero_volume_is_silent` passes. Question for the owner: is "full = 75 %, and low volumes
    below 64 are silent" acceptable voicing, or an unnoticed off-by-shift? It **interacts with
    S5** (what volume values does `main.cpp` actually send? if only 0 and 255, the practical effect
    is just "full = 75 %") and **with bench voicing (#32)** (perceived loudness). If a fix is ever
    wanted, adding a rounding bias or a minimum step of 1 toward a nonzero target would close it.
    (`03_sound_synthesis.md` §4.7a, §7 finding 3.)
