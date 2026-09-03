# 02 — Repository Map

How the code is organized, and — more important — *why* it's organized that way. Once
you understand the pattern in §1 you can navigate any module without help. §2–§4 map
the three *original* code repos in depth; §6 places the repos the workspace has grown
since (the mapper fork, the design system, the fabrication repo) — the full
workspace-level registry is `../WORKSPACE_MAP.md`.

## 1. The house pattern: pure logic + thin hardware shells

**[C]** Stated as a rule in `w17-control-fw/CLAUDE.md` §5 ("no ESP32/Arduino headers in
the pure-logic files") and `w17-soundlight-fw/CLAUDE.md`; verified in the tree.

Both firmware repos split every feature into up to three pieces:

```mermaid
flowchart TD
  subgraph pure["lib/<module>  — PURE LOGIC (no hardware knowledge)"]
    LOGIC["e.g. lib/outputs/EscOutput<br/>math + rules only"]
  end
  subgraph seam["lib/hal — INTERFACES (the seam)"]
    IFACE["e.g. hal::IPwmOutput<br/>abstract: 'something that can<br/>emit a pulse of N microseconds'"]
  end
  subgraph impls["two interchangeable implementations"]
    REAL["lib/outputs_hal_esp32/Esp32LedcPwm<br/>real chip registers (ESP32 only)"]
    MOCK["test/mocks/MockPwmOutput<br/>just records the last value (laptop)"]
  end
  LOGIC -->|"calls through"| IFACE
  IFACE --- REAL
  IFACE --- MOCK
  MAIN["src/main.cpp — the only file that<br/>knows both sides, wires REAL in"] --> LOGIC
  MAIN --> REAL
  TEST["test/test_outputs — wires MOCK in"] --> LOGIC
  TEST --> MOCK
```

Why this matters to you as a learner:

- You can read and *run* `lib/gearbox`, `lib/failsafe`, `lib/ers`, the whole sound
  synthesizer, etc. on your Mac. The hardware-specific code is a thin, boring layer.
- The pattern has a name in general software engineering — *dependency inversion* /
  *ports and adapters* — but you don't need the theory; you'll see the same three-file
  shape repeated a dozen times.

Standard shapes inside every `lib/<module>/`:

```
lib/gearbox/
├── include/gearbox/Gearbox.hpp   ← public header: what the module offers
├── src/Gearbox.cpp               ← implementation
└── library.json                  ← PlatformIO metadata (name, build rules)
```

## 2. `w17-control-fw` — the control board

```
w17-control-fw/
├── CLAUDE.md            founding brief: hardware, spec, safety rules
├── platformio.ini       build config: 4 environments (see chapter 11)
├── wokwi.toml, diagram.json   virtual-hardware simulation (chapter 11)
├── docs/                the documentation home (chapter 05)
├── src/
│   ├── main.cpp         THE entry point (~630 lines): wires everything, runs the loop
│   └── SimCrsfFeeder.{hpp,cpp}   scripted fake radio for the simulator build only
├── lib/                 one folder per module — the heart of the repo
└── test/                one folder per module's Unity test suite + shared mocks
```

### The pure-logic libraries (all laptop-runnable)

| Library | Central classes/functions | Job (one line) |
|---|---|---|
| `lib/config` | `pinmap::k*Pin` constants | Every GPIO number, in one header (`PinMap.hpp`) |
| `lib/hal` | `IPwmOutput`, `IClock`, `IByteSink`, `ICharIO`, `IVoltageSensor`, `IWheelPulseSensor`, `ISettingsStore` | The hardware interfaces (seams) |
| `lib/crsf` | `CrsfFrameAssembler`, `decodeRcChannels`/`decodeLinkStatistics` (in `CrsfParser`), `CrsfReceiver`, `CrsfFrameBuilder` | Radio protocol in *and* telemetry frames out |
| `lib/channels` | `ChannelDecoder`, `ArmGate` | Raw channels → named, normalized controls; the arm safety gate |
| `lib/failsafe` | `FailsafeStateMachine` | Link healthy? → `Active`/`Safe` (the safety core) |
| `lib/gearbox` | `shapeThrottle()`, `Gearbox` | Virtual gears: per-gear power cap + expo curve |
| `lib/ers` | `ErsSystem` | F1-style energy store: boost/overtake deploy, brake/coast harvest |
| `lib/outputs` | `ServoOutput`, `EscOutput`, `DrsOutput` | Normalized commands → pulse microseconds |
| `lib/telemetry` | `BatteryMonitor`, `WheelSpeed` | Sensor readings → volts / rpm, with filtering + warnings |
| `lib/link2` | `Link2Codec` (encode/decode/assembler), `Link2Sender` | The board#1→#2 protocol |
| `lib/settings` | `Settings`, `kDefaults` | Bench-tunable values + save/load blob for flash |
| `lib/console` | `Console`, `ConsoleRunner` | The serial tuning console (`get/set/save…`) |
| `lib/reset_diag` | `RawResetReason`, `ResetClass`, `classify()` | Boot-reset forensics (R5-b): why did this boot happen, what reset class, boot count — feeds the one-line boot diagnostic |

> Every library above now has a **line-by-line deep dive** in `code_explained/control_fw/`
> (batches C1–C10; the file↔batch map is in `source_code_progress.md`).

### The ESP32-only shells

| Library | Wraps | Used by |
|---|---|---|
| `lib/crsf_hal_esp32` (`Esp32CrsfUart`) | UART2 @ 420,000 baud (GPIO16 RX / GPIO17 TX) | radio in, telemetry out |
| `lib/outputs_hal_esp32` (`Esp32LedcPwm`) | the ESP32 "LEDC" PWM peripheral, 50 Hz | all five servo/ESC outputs |
| `lib/telemetry_hal_esp32` (`Esp32BatteryAdc`, `Esp32HallPulseCounter`) | ADC pin GPIO34; interrupt on GPIO35 | battery + wheel speed |
| `lib/link2_hal_esp32` (`Esp32Link2Uart`) | UART1 TX-only on GPIO25 | link2 to board #2 |
| `lib/settings_hal_esp32` (`Esp32NvsStore`) | flash storage (NVS) | **every** build loads saved tuning at boot; only *saving* comes from the console |
| `lib/console_hal_esp32` (`Esp32SerialConsole`) | USB serial (UART0) | tuning build only |

### Tests

`test/test_<module>/test_main.cpp` per module (13 suites), `test/mocks/` shared fakes.
Run `pio test -e native` for the live count — the suite has grown steadily with the
repo (**330 tests as of 2026-09-03**, reproduced via `pio test -e native`; the "147"/
"229" quoted in older docs/chapters are the 2026-07-03- and 2026-08-17-era sizes).
Notable: `test_link2` contains `test_golden_frame_bytes` pinning
the exact wire bytes of the link2 protocol, and `test_crsf` pins each outgoing
telemetry frame — the ground station asserts the *same bytes* in its own tests.

## 3. `w17-soundlight-fw` — the sound/light board

Same pattern, smaller:

| Library | Central classes | Job |
|---|---|---|
| `lib/config` | `pinmap::*` | Board #2's pins (link2 RX 16; I2S 26/25/22; LEDs 4) |
| `lib/link2` | `Link2Codec`, `Link2FrameAssembler` | **Verbatim copy** from the control repo — the protocol owner. [C] "do not fork; protocol changes happen there first" (`CLAUDE.md`) |
| `lib/link2monitor` | `Link2Monitor`, `LinkStatus` | Staleness watchdog: last good state while link Up, safe projection when Lost |
| `lib/enginesim` | `EngineSim`, `Ignition` | Virtual engine: rpm inertia, starter, rev limiter, shift blips, overrun |
| `lib/soundsynth` | `EngineSynth`, `ISampleSource`, `SynthProfiles` | The DSP: turns engine state into audio samples (all integer math); named voice profiles `v10()` (default) / `v6TurboHybrid()` |
| `lib/lights` | `LightRenderer` | Pixel compositor: brake/indicators/rain/halo/ignition/DRS-tell/hazard + gamma + power cap |
| `lib/audiodecision` | `audiodecision::*` | Pure audio-task decisions shared verbatim by `main.cpp` and the tests (dead-man boundary can't drift into a test copy) |
| `lib/audiostartup` | `audiostartup::*` | Graceful degradation when I2S audio startup fails (lights keep running) |
| `lib/audio_hal_esp32` | `Esp32I2sAudio` | I2S output @ 22,050 Hz to the MAX98357A |
| `lib/lights_hal_esp32` | `Esp32NeoPixelStrip` | WS2812 via the Adafruit NeoPixel library |

> Every library above now has a **line-by-line deep dive** in `code_explained/soundlight_fw/`
> (batches S1–S5; the file↔batch map is in `source_code_progress.md`).

`src/main.cpp` (~220 lines) is special: it splits work across the ESP32's **two CPU
cores** — control logic on core 1, audio rendering on core 0 — sharing exactly one
atomic 32-bit word + a heartbeat (chapter 07). `src/SimLink2Feeder.{hpp,cpp}` scripts a
fake board-#1 for the standalone bench demo. Tests: 9 suites (**137 tests as of
2026-09-03**, reproduced via `pio test -e native`; run it yourself for the live
count), including a pure end-to-end `test_integration` (frames in → audio out).

## 4. `w17-ground-station` — the laptop app

JavaScript, not C++. Electron apps have two worlds (chapter 08): the **main process**
(Node.js — files, serial ports, child processes) and the **renderer** (a Chromium
browser page — the visible UI). They talk over IPC (inter-process messages).

```
w17-ground-station/
├── package.json          npm manifest; `main/main.js` is the entry point
├── main/                 MAIN PROCESS
│   ├── main.js           window creation, telemetry source selection, IPC push
│   ├── appWiring.js + sessionRuntime.js   composition + per-session runtime state
│   ├── mediamtx.js       starts/supervises the bundled mediamtx video server
│   │                     (restarted keyed on the selected video profile)
│   ├── CrsfSerialSource.js  reads CRSF telemetry from a serial port
│   ├── preload.cjs       the safe bridge exposed to the renderer
│   ├── wifiManager.js · hotspot*.js · adapterMonitor.js · wifiSim.js
│   │                     PIT WALL: Wi-Fi scan/join, hotspot lifecycle, adapter picker
│   ├── settingsStore.js + credentialStore.js   persisted choices; the one secret
│   │                     (hotspot password) encrypted at rest via safeStorage
│   ├── HudDiscovery.js   mDNS iPhone-HUD address *suggestions* (advisory-only, CB4)
│   ├── elrsLauncher.js   launches the mapper detached (GRID's LAUNCH button)
│   ├── raceDayOrchestrator.js + mapperRunner.js   one-action race-day start:
│   │                     spawns the mapper with an argv whitelist + scrubbed env
│   │                     (companions: shared/racePrep.mjs, shared/raceDayView.mjs)
│   ├── IphoneTelemetryBridge.js + iphoneBridgeConfig.js   W2: telemetry → iPhone,
│   │                     UDP 5601, SEND-ONLY, off by default (W17_IPHONE_BRIDGE)
│   └── HeadTrackingReceiver.js + headTrackingConfig.js    W3: iPhone → Windows,
│                         UDP 5602, LOG-ONLY dead end, off by default (W17_HEADTRACK)
├── renderer/             RENDERER (the visible HUD web page)
│   ├── index.html, hud.css, hud.js   gamepad mirroring + simulated dash + overlay
│   ├── setupFlow.js      the pre-ride setup-flow UI (GARAGE → … → GRID; ch08 §7)
│   ├── padPreview.js · wheelPreview.js · uiNav.js · sounds.js   SEAT FIT previews,
│   │                     keyboard navigation, radio-sound chirps
│   └── whep.js           WebRTC video client
├── shared/               PURE, unit-tested logic used by both worlds
│   ├── crsf.js           CRSF decoder — a faithful JS port of the firmware's
│   ├── crsfAssembler.js  byte-stream → frames
│   ├── crsfTelemetry.js  frames → Telemetry fields
│   ├── telemetry.js      the normalized Telemetry object (contract: docs/TELEMETRY.md)
│   ├── linkState.mjs     the 4-state HUD link model (audit F2; ch08 §3)
│   ├── setupSteps.mjs + checklist.mjs + setupSummary.mjs   the setup-flow step
│   │                     machine + the GRID checklist engine (ch08 §7)
│   ├── settings.js · lowBattery.mjs · videoProfiles.mjs · wheelProfile.mjs ·
│   │   inputPresets.mjs · cameraMode.mjs · …   one pure module per flow concern
│   ├── replaySource.js   fake telemetry for `npm run demo`
│   ├── feelConstants.js  ERS feel numbers shared with the firmware
│   ├── telemetrySnapshot.js  W2: pure iPhone-packet builder (bridge contract)
│   └── headTracking.js   W3: pure packet validator + diagnostics monitor (LOG-ONLY)
├── mediamtx/mediamtx.yml pinned server config (camera RTSP URL goes here)
├── scripts/              run/setup helpers (Electron repair, mediamtx download,
│                         the Electron boot-smoke harness, proto/feel sync checks)
├── test/                 67 vitest files, 1447 tests as of 2026-09-03 (incl. the
│                         shared CRSF golden fixture, audit F3, and the
│                         no-control-path guards); run `npm test` for the live count
├── .github/workflows/ci.yml   `test` job (Ubuntu fast gate) + `package-smoke` job
│                         (Windows: suite, real Electron boot smoke, --dir build,
│                         unsigned NSIS giftee installer + artifact upload)
└── docs/                 SETUP.md (bench risks), TELEMETRY.md (contract),
                          CODESIGNING.md, video_profiles.md, the setup-flow bench
                          checklist, windows_bridge_contract.md (implementation
                          copy — canonical lives in Codex-owned iPhone_rc) + bridge
                          readiness/test-plan notes
```

> **Inventory note (updated 2026-07-09, G0 pass):** tree re-verified file-by-file; the
> audit fixes (F2/F3/F4) and the iPhone-bridge work (W1–W3, 2026-07-07/08) added the
> files marked W2/W3/F above and grew the test suite from 20 to 118 vitest tests
> (run that session: 118/118). The W3 head-tracking receiver is **LOG-ONLY by safety
> boundary** (it must never reach CRSF, servos, or the gimbal) and its real-device
> validation is **still pending** (open question #58). Batch placement of every file:
> `source_code_explanation_plan.md` (G1–G5b); the shared pure core now has its
> line-by-line deep dive.

> **Inventory note 2 (2026-08-17, wave-2 staleness pass):** the tree above was
> re-drawn against main at `2c56898`. Since the G0 pass the repo absorbed the
> **setup-flow redesign** (GARAGE → PIT WALL → SEAT FIT → SETUP → GRID — chapter 08
> §7), hotspot lifecycle, mDNS HUD discovery, the low-battery banner, video
> profiles, race-day one-action orchestration, and the NSIS installer CI step; the
> suite is **1435 tests across 67 files**. The new `main/` and `shared/` files are
> *not yet* in the line-by-line campaign inventory
> (`source_code_explanation_plan.md` still maps the G0-era tree) — the campaign has
> been paused since 2026-07-09. (Main moved twice more *during* this repair pass —
> `ca1cb86` video profiles, then `2c56898` race day; treat any count here as its
> dated snapshot and trust `npm test`.)

> Deep dive: `shared/`'s pure core (CRSF decode, telemetry model, link state, golden
> fixture) is explained line-by-line in
> `code_explained/ground_station/01_shared_pure_core.md` (batch G1, incl. a
> JS-for-C++-readers primer); the main process + telemetry sources (`main/main.js`,
> `preload.cjs`, `mediamtx.js`, `CrsfSerialSource.js`, `shared/replaySource.js`) in
> `02_main_process_and_telemetry_sources.md` (batch G2); the renderer
> (`renderer/index.html`, `hud.css`, `hud.js`, `whep.js` — the HUD, the widget
> precedence, WHEP video, the command mirror) in `03_renderer_hud_and_whep.md`
> (batch G3, incl. a browser-concepts primer); and the deployment story (npm scripts,
> Electron packaging, the `mediamtx.yml` config, and CI) in
> `04_scripts_packaging_and_ci.md` (batch G4). The remaining batches G5a/G5b
> (iPhone bridge) are planned in `source_code_explanation_plan.md`.

## 5. Who owns what (cross-repo relationships)

```mermaid
flowchart LR
  CF["w17-control-fw<br/>OWNS: link2 spec,<br/>CRSF golden vectors"]
  SL["w17-soundlight-fw<br/>copies lib/link2 verbatim"]
  GS["w17-ground-station<br/>ports lib/crsf to JS"]
  CF -->|"lib/link2 (copy, verbatim)"| SL
  CF -->|"docs/link2_protocol.md (copy)"| SL
  CF -->|"golden frame bytes (re-asserted in vitest)"| GS
```

**[C]** `w17-soundlight-fw/CLAUDE.md`: "copied VERBATIM … do not fork; protocol changes
happen there first." `w17-ground-station/docs/TELEMETRY.md`: "every emitted frame is
pinned by an identical golden vector in *both* the firmware … and here."

Practical consequence: if you ever want to change a protocol, the change starts in
`w17-control-fw` and propagates outward — never the reverse.

## 6. The rest of the workspace — repos this chapter doesn't map in depth

The three trees above were the whole Claude-side code world when this chapter was
written; the workspace has since grown to six Claude-side repos
(**[C]** `../WORKSPACE_MAP.md`, the authoritative registry):

- **`w17-mapper`** — the fourth *code* repo (Go, not C++/JS): the owned GPL fork of
  `elrs-joystick-control` that turns the DualShock into CRSF and hosts the log-only
  head-intent pipeline. Its anatomy, node graph, and safety story have their own
  chapter — **ch15 §2–§4** (repo shape and Go primer), **§9–§10** (head intent and
  the guards). Not yet in the line-by-line campaign (see
  `source_code_explanation_plan.md`).
- **`w17-design-system`** — reference-only, no runtime code: the visual source of
  truth for the ground station's setup-flow redesign (`w17.css` tokens, component
  cards, 1280×800 screen mockups). The `w17-ground-station/renderer/` is the
  *implementation*, not a copy.
- **`w17-3d-codex`** — fabrication: model inventory, materials, slicing specs, test
  prints, finishing/decals, printed-part assembly. Consulted by the rebuild track
  (chapters 17–18).

Two further repos are **ChatGPT-Codex-owned** and out of Claude-side editing scope:
`iPhone_rc` (the thin iPhone HUD client) and `w17-rc-print-codex` (print decisions).
The manual cites them but never maps their internals.

## Confirmed vs inferred

**Confirmed [C]:** the folder trees and file lists (first verified by directory
listing 2026-07-03; firmware/GS trees re-verified 2026-08-17 against control-fw
`9f00f2e`, soundlight `1c19260`, GS `2c56898`); the pure-vs-HAL rule and the
`lib_ignore` enforcement (`platformio.ini [env:native]`); test counts as-of-dated in
the text above; ownership rules (quoted above); the §6 repo set
(`../WORKSPACE_MAP.md`).

**Inferred [I]:** the description of *why* the seam pattern exists (testability) is the
docs' own stated motivation, generalized. *(The old note here — "exactly what
`preload.cjs` exposes awaits the code-reading phase" — was answered by G2, 2026-07-09:
it exposes exactly three functions, `getConfig` / `onTelemetry` / `sendCommandMirror`,
as `window.groundStation`; see the G2 deep dive §3.)*

**Assumed [A]:** none of significance in this chapter.

## Questions to check your understanding

1. You want to change the ESC's neutral pulse width. Which of the three layers (pure
   lib, hal interface, esp32 shell) would you expect that constant to live in, and why?
2. Why does `platformio.ini`'s `[env:native]` list five `*_hal_esp32` libraries under
   `lib_ignore`? What would happen without it?
3. `lib/link2` exists in two repos. Which copy is authoritative, and what is the rule
   when the protocol needs a change?
4. In the ground station, why is the CRSF decoder in `shared/` rather than in `main/` or
   `renderer/`?
5. Name the four files you would open first to answer: "which GPIO pin drives the DRS
   servo, and what module decides its position?"
