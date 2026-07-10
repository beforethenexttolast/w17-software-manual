# Glossary

Terms as used *in this project*. Each entry notes where the term matters most
(manual chapter numbers in parentheses).

**A-arm** — the wishbone-shaped suspension link letting a front wheel move up/down;
damped by the shock. Atlas MECH-03. (05)

**ADC (analog-to-digital converter)** — chip peripheral turning a pin voltage into a
number. Reads the battery divider on GPIO34. (03, 06)

**Additive synthesis** — building a sound by summing sine-wave *partials* (a fundamental
plus harmonics at integer multiples of it). `EngineSynth`'s 6-partial stack is additive;
the per-partial amplitudes *are* the engine's timbre. (07, S3)

**Adversarial review** — a review whose goal is to *break* the code: hunt inputs and
timings that misbehave. Produced ROADMAP findings A1–A13. (05)

**Aliasing / Nyquist limit** — a sampled signal can only faithfully carry frequencies
below half the sample rate (here 22,050 / 2 = 11,025 Hz); anything higher "folds back" as
a false lower tone (aliasing). The synth's highest partial reaches ~7.5 kHz at redline —
safely under the limit. (07, S3)

**allow-scripts (lavamoat)** — a supply-chain safety tool that **blocks npm packages'
install-time scripts** by default (a malicious `postinstall` can't run). The ground
station enables it (`package.json` `lavamoat.allowScripts`), which is *why* Electron's
own postinstall (that unpacks its binary) never runs — the gap `ensure-electron.js`
then repairs. (08, G4 §2.4/§4)

**asar** — Electron's app-archive format: at package time the app's JS/HTML/CSS are
bundled into one `app.asar` blob (faster loads, tidier install). Files a **native**
binary must reach by real filesystem path can't live inside it, so they are listed under
`asarUnpack` (the ground station unpacks `serialport`). See **Native module**. (08, G4 §6.5)

**Anisotropy / layer orientation** — FDM prints are weakest *between* layers; the print
spec's golden rule is to orient stressed parts so load runs along the layers. (05)

**Arm / ArmGate** — "armed" = the motor may respond to throttle. Requires arm switch ON
*and* throttle seen at neutral since the last disarm. `lib/channels/ArmGate`. (06, 10)

**ASA / PETG / PLA** — 3D-printing filaments: heat-resistant (fumes: see Styrene) /
tough / easy-but-soft. Assigned per part group by heat + load. (05)

**Attenuation (ADC, 11 dB)** — input-range setting letting the ESP32 ADC read up to
~2.5 V linearly. The divider was sized to fit under it. (03, 05)

**Audio pump / backpressure pacing** — soundlight's core-0 task loop: apply params →
render 256 frames (~11.6 ms) → `i2s.write`, where the *blocking* write into the DMA ring
is the only clock — the hardware drains samples at exactly 22,050 Hz, so the loop can't
run fast or slow ("self-pacing"). No timer, no delay; the blocking also feeds core 0's
IDLE task, keeping the task watchdog happy. `audioTask` in `main.cpp`. (07, S5)

**Balance charging** — charging a multi-cell LiPo while equalizing each cell's voltage;
the charger must support 2S balance (BOM open item). (05)

**BEC / UBEC** — (Universal) Battery Eliminator Circuit: DC-DC regulator making a 5 V
rail from the battery. Two here: Rail A clean, Rail B servos. (03)

**Bind phrase** — ExpressLRS pairing secret; TX modules and receivers flashed with the
same phrase (and same major.minor version) auto-bind. (01, 05)

**Blob (settings)** — the versioned, checksummed byte buffer a `Settings` struct is packed
into for flash: `[version][raw struct bytes][crc8]`. Not a portable wire format — the struct
bytes are a raw copy, meaningful only to the same firmware build. (09a)

**Boot arm hold** — `EscOutput` holds neutral ~2 s from the first throttle command so
the ESC's own arming succeeds; anchored to first use after finding A5. (06, 10)

**Breathe (waiting animation)** — the lights' `NeverConnected` rendering: a calm 2 s
teal triangle pulse on the halo, everything else dark. Deliberately *not* the hazard —
"board #1 hasn't spoken yet" is normal at power-on, not an emergency. (07, S4)

**Brownout** — a supply-voltage dip that resets electronics; servo current spikes cause
it; the 1000 µF rail capacitor prevents it. (03, 05)

**Brushless motor / sensored** — the drive motor type; "sensored" adds position sensors
(extra ribbon cable) for smooth low-speed control. (03)

**Check value (CRC)** — the standard fingerprint for verifying a CRC implementation:
CRC of ASCII `"123456789"`. For CRC-8/DVB-S2 it is 0xBC. (05, 09)

**Child process / `spawn`** — a program started (and owned) by another program.
Node's `spawn(binary, [args])` returns a handle with `stdout`/`stderr` streams and an
`exit` event; killing the parent does *not* reliably kill children, which is why the
ground station supervises mediamtx explicitly (`main/mediamtx.js`: spawn,
restart-on-crash after 2 s, latch-guarded kill on quit). (08, G2)

**CI (continuous integration) / job** — a cloud service (here **GitHub Actions**) that
runs a defined pipeline of steps on every push. A *job* is one such pipeline on one
*runner* (a fresh VM — `ubuntu-latest` or `windows-latest`). The ground station's
`.github/workflows/ci.yml` has two: `test` (the 118 vitest tests on Linux) and
`package-smoke` (an Electron build on Windows). "CI green" means the logic passed and the
app packaged — **not** that video, serial, or a real device works. (11 §7, G4 §8)

**Code signing (CSC)** — attaching a cryptographic certificate to a Windows/macOS app so
the OS trusts its origin and stops "unknown publisher" warnings. `electron-builder`
reads the cert from `CSC_LINK`/`CSC_KEY_PASSWORD` **environment variables** — no secret
lives in the repo; unset ⇒ an unsigned build. (08, G4 §6.4)

**com0com / hub4com** — Windows virtual serial-port splitter: one owner mirrors a
physical COM port to several virtual ones. The planned fix for the FT232 telemetry
sharing problem. (08)

**Command mirror** — the ground station's one renderer→main message
(`sendCommandMirror`, ~20 Hz rate-limited): a read-only copy of the command values
*as drawn on the HUD* (throttle/brake/steering/camera + whether video is playing),
forwarded outward to the iPhone telemetry bridge — or dropped when the bridge is off.
One-way by construction; it never feeds control (elrs-joystick-control drives the
car), and nothing returns on the channel. A picture of the operator's inputs, not a
control path — and not proof the bridge works end-to-end (#58). (08, G2 §2.8, G3 §7)

**Content-Security-Policy (CSP)** — a page-level allowlist (here a `<meta>` tag in
`renderer/index.html`) declaring what a web page may load or connect to; the browser
enforces it. The HUD's pins scripts/styles to its own files, media to live streams,
and `fetch` to the localhost WHEP endpoint only — defense-in-depth *inside* the
Electron sandbox. (G3 §2.1)

**CRC-8 (poly 0xD5)** — the 1-byte checksum (CRC-8/DVB-S2) used by both CRSF and link2;
corrupted frames are rejected. (09)

**Creep** — slow permanent deformation of plastic under sustained load + warmth; why
the camera duct is PETG, not PLA. (05)

**CRSF (Crossfire)** — the RC serial protocol: sync 0xC8 frames at 420,000 baud
carrying RC channels (0x16), link stats (0x14), telemetry (0x08/0x02/0x21).
`lib/crsf`. (09)

**Console (tuning)** — the bench-only command interface (`lib/console`): a *pure* `Console`
parses a typed line (`get/set/save/load/reset/status/help`) and returns a `Result`, while
`ConsoleRunner` does the actual serial I/O and flash storage. Compiled out of the gift firmware
(`W17_TUNING_CONSOLE`). (09b)

**Compositor (lights)** — building the LED frame in layers, each painting over the last
(the "painter's algorithm"): base tail+halo → low-battery → brake/rain/indicators, with
the failsafe hazard and NeverConnected breathe as early-return overrides. Priority = code
order; whoever paints last wins the pixel. `lib/lights/LightRenderer`. (07, S4)

**Conductor (`main.cpp`)** — the control firmware's composition file: constructs every module,
injects the pins from `PinMap.hpp`, and schedules all cadences (50/20/10/5 Hz). Wiring and
scheduling only — no mechanisms of its own; excluded from native tests (`test_build_src = no`),
so its claims are source+build-verified, never test-verified. (C10)

**ControlSnapshot** — the struct the conductor fills with what the control tick *actually
commanded* (plus gear/rpm/battery/ERS at send time) and hands to `Link2Sender` at 20 Hz.
Boot-safe defaults (`failsafe = true`) so the first frame can never report a phantom Active.
(09, C10)

**CommonJS / ES modules (CJS/ESM)** — JavaScript's two module systems. CJS:
`require()` / `module.exports`, Node's original, synchronous — used by the ground
station's `.js` files because Electron's main process is CJS. ESM: `import`/`export`,
the modern standard browsers and vitest speak natively — `shared/linkState.mjs` opts in
via the `.mjs` extension because its consumers are the renderer + vitest. The repo
deliberately mixes both. (G1 §1)

**Dead-man (audio)** — soundlight rule: synth params not refreshed ~500 ms ⇒ volume
ramps to 0. S5 found the implementation: `audioTask` compares `millis()` against the
heartbeat atomic before every block; if older than exactly 500 ms it forces
`setParams(0, 0, false, false, false)` — the "ramp" is the synth's own ~3 ms smoother.
Lives in `main.cpp` (native-excluded), so it has never been test-executed — a priority
bench check (open q #57). The speaker's third failsafe layer, after link staleness (S1)
and ignition-off (S2). (07, S5)

**DISARMED gating** — the tuning console refuses all *mutating* commands (`set`/`save`/`load`/
`reset`) while the car is armed; `get`/`status`/`help` stay allowed. Tuning is a "pit-lane"
activity — you can inspect a live car but never re-tune it. (09b)

**DMA ring (I2S)** — a chain of buffers that **DMA** (direct memory access — hardware
copying memory to a peripheral with no CPU work) feeds to the I2S output continuously.
Soundlight: 6 buffers × 256 frames ≈ 70 ms of queued audio; `i2s_write` blocks until ring
space frees (see Audio pump), and `tx_desc_auto_clear` makes an underrun play *silence*
rather than repeating stale samples — fail-quiet at the lowest layer. `Esp32I2sAudio`.
(07, S5)

**DOM (Document Object Model)** — the browser's live object tree parsed from HTML;
JS reads and mutates it (`document.getElementById`, `.textContent`, `.classList`)
and the screen follows — no explicit "redraw" call. The renderer's version of
setPixel-then-show, with the show implicit. (08, G3 §1)

**Drift guard (link2 CI job)** — the CI step added to *both* firmware repos by audit fix
F3 (risk R06): it clones the sibling repo and fails the build if the four copied link2
contract files (`Link2Frame.hpp`, `Link2Codec.hpp`, `Link2Codec.cpp`,
`link2_protocol.md`) differ. Machine enforcement of the "verbatim copy, do not fork"
rule that previously relied on human discipline. A deliberate protocol change now
requires updating both repos back-to-back. (11, 12)

**Drive mode** — the ch13 3-position policy wired in `main.cpp`: **0 = Training** (one
fixed gentle shape {400, 50}; paddles inert to output), **1 = Gearbox** (default — also
what an absent channel decodes to), **2 = Gearbox+ERS**. No raw pass-through by design:
top gear already *is* full power, and authority stays monotone along the switch. (06, C10)
The **user-facing labels** (canonical across the HUD, TELEMETRY.md and link2_protocol.md) are
**TRAINING / RACE / ERS** — i.e. "gearbox" = RACE, "gearbox+ERS" = ERS. (audit R19)

**DRS** — Drag Reduction System; here, a wing flap on an MG90S servo toggled by a
switch. (01, 06)

**eFuse calibration** — ADC correction data burned into the ESP32 at the factory;
`analogReadMilliVolts` uses it. Older chips fall back to a default reference (worse
accuracy) — D8 logs which type the board reports. (05)

**EMA (exponential moving average)** — smoothing filter; battery voltage uses one,
seeded from the first sample to avoid a boot false-alarm. (10)

**EMI** — electromagnetic interference; motor noise inducing phantom sensor pulses.
Defended physically (scope + snubbing cap), by timing (2 ms lockout), and logically
(5000 rpm plausibility clamp). (03, 10)

**Electron Builder** — the packaging tool (`electron-builder.yml` + `npm run package`)
that turns the ground station's source into a distributable Windows app: it bundles the
listed `files` into an **asar**, copies `extraResources` (mediamtx) alongside, unpacks
native modules, and can produce an installer (**NSIS**). Its `--dir` mode assembles the
unpacked app folder *without* an installer — used by CI's package-smoke job. (08, G4 §6)

**Endianness** — byte order of multi-byte numbers. link2 = little-endian; CRSF
telemetry payloads = big-endian. (09)

**ELRS (ExpressLRS)** — open-source 2.4 GHz RC radio link; TX module ↔ RP1 receiver;
also relays standard telemetry frames back. (01, 09)

**Environment variable (env var)** — a named string in a process's environment,
inherited by child processes; read in Node as `process.env.NAME` (unset =
`undefined`). The ground station's *entire* configuration system: `W17_TELEMETRY_SOURCE`,
`W17_TELEMETRY_PORT`, `W17_WHEP_URL`, `W17_IPHONE_BRIDGE`, `W17_HEADTRACK`… — the
runtime, no-rebuild cousin of the firmware's compile-time `-D` build flags. (08, G2)

**ERS** — Energy Recovery System (F1 concept). Simulated store: deploy via
boost/overtake, harvest while braking/coasting with wheels turning. `lib/ers`. (10)

**ERS whine** — the synth's electric-motor keening layer: a sine at 3× the firing
frequency (MGU-K crank-coupled feel), gated on by `ersDeploying` with a ~23 ms fade-in/out
so it can't click. `lib/soundsynth`. (07, S3)

**ESC** — electronic speed controller: converts 1000–2000 µs PWM into three-phase motor
power. Hobbywing 10BL120, sensored, forward/brake mode. (03)

**Event listener** — a callback registered on a browser element or the page
(`addEventListener('keydown', fn)`); the browser calls it when the named event fires,
delivering an event object with the details. Push-style input (ISR-flavored), in
contrast to the polled Gamepad API — the HUD uses both. (G3 §1)

**Expo** — exponential stick curve: softens response near center, keeps endpoints.
Per-gear in the gearbox. (10)

**Facade (pattern)** — a single friendly interface over several lower-level pieces;
`CrsfReceiver` is the facade over assembler + parsers. (06)

**Failsafe** — every layer that forces safety on communication loss: the control FSM
(500 ms timeout + LQ latch), link2 staleness (500 ms), HUD fallback (1 s), audio
dead-man. (10)

**Firing frequency** — the engine-sound fundamental: f = rpm/60 × firingsPerRev. 5
firings/rev = "V10 flavor"; across 3,500–15,000 rpm that is ~292–1,250 Hz, chosen to sit
in a small speaker's usable band. `EngineSynth`. (07, S3)

**First-decode seeding** — the ChannelDecoder sets initial switch levels from the first
frame *without* emitting edges, so boot can't fire phantom gear shifts. (05, 06)

**FPV** — first-person view: driving via the onboard camera's live video. (01)

**Frame (protocol)** — one delimited message on a byte stream. (09)

**Free-running blink** — deriving a blinker's on/off purely from the wall clock
(`nowMs % period < period/2`) instead of restarting a timer on trigger: all segments
sharing a period blink in phase, and re-triggering can't reset a half-finished blink.
The lights' indicators/hazard/rain all use it. (07, S4)

**Fresh-neutral rule** — after *any* disarm or failsafe episode, throttle must be seen
at neutral again before power flows (closes finding A3). (10)

**Function-local static** — a variable declared `static` inside a function: initialized once
(the first time execution reaches it) and keeping its value across calls — static storage, not
the stack. Used for the sim status-print and feeder timestamps. (C10)

**Gamepad API** — the browser's controller interface: `navigator.getGamepads()`
returns arrays of `axes` (−1…1 floats) and `buttons` (`{pressed, value}` — triggers
are analog). **Polled** each frame, not event-driven (only connect/disconnect are
events). Indices follow the W3C "standard gamepad" layout; that a DualShock lands on
them as the HUD assumes (R2=7 throttle, L2=6 brake…) is browser/OS behavior — a
demo-run check. (08, G3 §1/§5.2)

**Gamma correction (LED)** — re-mapping brightness values through `out = in^2.2` (a
256-entry LUT) so *perceived* LED brightness tracks the input linearly (raw PWM looks
"all bright, no lows" to the eye). Applied after the brightness cap; crushes low inputs
toward zero — why the dim layers render at 1–3/255 duty (open q #55). (07, S4)

**GitHub Actions (CI)** — the hosted service running `.github/workflows/ci.yml` on every
push/PR: native tests + the `esp32dev` and `esp32dev_sim` builds (`esp32dev_tuning` is not in
CI). No hardware attached — proves logic + compilation only. (C10)

**Golden test / golden vector** — a test asserting exact bytes, duplicated on both ends
of a protocol so implementations can't drift. (09)

**GPIO** — general-purpose input/output pin. All assignments in `PinMap.hpp`. (02)

**Gyroid** — a wavy 3D infill pattern, strong in all directions; the print spec's
default. See Infill. (05)

**HAL (hardware abstraction layer)** — the `hal::I*` interfaces + `*_hal_esp32`
implementations separating logic from hardware. (02, 04)

**Hall sensor (A3144)** — magnetic switch; an N35 neodymium magnet on the axle gives
one pulse/revolution = wheel speed. (03)

**Headroom (audio)** — the gap between the loudest possible synth output and the int16
clip rail. `EngineSynthConfig::valid()` proves the summed partial + noise + whine peak
(24,600) stays under `kHeadroomPeak` (30,000) so the normal mix can't clip. (07, S3)

**Heat-set insert** — brass threaded insert melted into printed plastic with a
soldering iron so steel bolts bite metal, not plastic. (05)

**HUD link states (sim / live / LINK LOST / TELEMETRY LOST)** — the ground station's
four-way telemetry-health display, derived on the ground from link quality + staleness
(`shared/linkState.mjs`, added by audit fix F2): **sim** = no source ever live (gamepad
simulation shown), **live** = fresh telemetry with LQ > 0, **LINK LOST** = fresh
telemetry but `linkQualityPct == 0` (the ground TX still reports stats after the radio
link to the car drops), **TELEMETRY LOST** = a previously-live source silent > 1 s
(last real values held dimmed — the HUD never silently resumes simulated numbers). (08)

**Hysteresis** — different thresholds for turning on vs off, preventing chatter: switch
decode (±250), battery warning (7.0/7.4 V), brake flag, turn indicators (latch at |steer|
≥ 40, hold 20–39, self-cancel < 20 — S4). (06, 10, S4)

**I2S** — three-wire digital audio bus (BCLK/LRCLK/DIN) to the MAX98357A amp. (03, 07)

**Infill** — the interior fill percentage/pattern of a 3D print; walls usually matter
more for strength. See Gyroid, Rectilinear, Perimeters. (05)

**Idle wobble** — EngineSim's ±120 rpm, 400 ms-period triangle added to the *audible*
rpm at idle (fading linearly to zero at full throttle) so the idle sounds like a machine
hunting, not a test tone. Perceptual only — the internal `rpm_` never wobbles. (07, S2)

**Ignition state machine (Off/Cranking/Running)** — EngineSim's aliveness FSM, driven
*only* by the effective `armed` flag: disarm/failsafe/stale-link/boot all mean Off
(silence, rpm reported 0 immediately); arming plays 600 ms of starter whir at 1,800 rpm
(Cranking) before the engine "catches" (rpm snapped to idle, Running). Every return from
Off replays the crank. (07, S2)

**Inertia (asymmetric, EngineSim)** — rpm chases its throttle target by a *fraction of
the remaining gap* per tick (`rpm += gap·rate·dtMs/1000`): 6 ‰/ms up, 3 ‰/ms down
(12 %/6 % per 20 ms tick) — engines spin up harder than they wind down. ≈0.5 s idle→max,
≈1 s+ back. The exponential-approach cousin of C7's EMA. (07, S2)

**IPC (Electron)** — messages between main and renderer processes; carries telemetry to
the HUD. (08)

**IRAM_ATTR** — ESP32 attribute placing a function in RAM; required for ISRs because
executing from flash inside an interrupt can crash. (04, 05)

**ISR (interrupt service routine)** — code run by hardware on an event (Hall edge);
tiny, `IRAM_ATTR`, atomic counters, 2 ms lockout. (04)

**JSDoc** — structured JS comments (`/** @typedef ... */`) that *document* types in a
language with no compile-time types; the ground station's `Telemetry` "struct" is a
JSDoc typedef enforced by nothing but tests. (G1 §1–2)

**Keyframe / lerp** — animation vocabulary the replay source borrows: a *keyframe* is
a full value-set pinned at a time point; *lerp* (linear interpolation,
`a + (b−a)·f`) fills the gap between two keyframes. `shared/replaySource.js` lerps
numeric telemetry between its 9 keyframes, rounds `gear` to whole shifts, and steps
booleans/`driveMode` from the earlier keyframe. (G2 §6)

**King pin** — the vertical pin a steering knuckle pivots on. (05)

**Knuckle (steering)** — the part that holds a front wheel's bearings and swings on the
king pin to steer. (05)

**Layer height** — print resolution per layer: 0.2 mm default here, 0.12–0.16 mm on
visible bodywork. (05)

**LDF (Library Dependency Finder)** — PlatformIO's automatic dependency resolver: a
library joins a build only if something `#include`s it. Why conditional includes keep
whole libraries out of the gift build, and why `[env:native]`'s `lib_ignore` exists as
the hard override. (09b, C10)

**LEDC** — the ESP32 PWM peripheral generating servo pulses. `Esp32LedcPwm`. (03, 06)

**link2** — this project's one-way UART protocol, board #1 → #2: 0xA5-framed 14-byte
frames, 20 Hz, 500 ms staleness rule. Spec: `docs/link2_protocol.md`. (09)

**Link2Monitor** — board #2's staleness watchdog (`lib/link2monitor`): wraps the copied
`Link2FrameAssembler`, stamps the arrival time of each CRC-valid frame, and returns the
*effective* VehicleState — the last good frame while the link is `Up`, a safe per-field
projection once it goes stale. Time is a plain `nowMs` argument (no `hal::IClock`); the
staleness edge is `elapsed >= 500 ms` (inclusive). (07, S1)

**LinkStatus** — the monitor's three-way link health signal: **NeverConnected** (no valid
frame ever — board #1 maybe still booting), **Up** (a valid frame within the window),
**Lost** (was Up, then silent ≥ 500 ms). Three states not a boolean because the lights
distinguish "never spoke" from "stopped speaking." (07, S1)

**Effective state / per-field staleness projection** — the monitor's core idea: consumers
(EngineSim, LightRenderer) act on `state()`, which sanitizes stale data *once, centrally*.
On link loss, **commands** (throttle/steering/braking/drsOpen/armed/ersDeploying) are zeroed
and `failsafe` forced true, **motion telemetry** (rpm) is zeroed, but **slow facts / latched
judgments** (batteryMv, lowBattery, gear, ersPercent, driveMode) are held last-known to keep
displays steady and avoid phantom shift-blips. `lastGood_` is never mutated, so recovery is
one frame. (07, 09, S1)

**LiPo (2S)** — two-cell lithium-polymer battery: 8.4 V full, 7.4 V nominal; warn
threshold 7.0 V here. Soft-case, ≤75×45×25 mm envelope. (03)

**Loopback (UART)** — wiring a transmitter back into its own receiver; the Wokwi sim's
gold TX2→RX2 wire that lets the firmware feed itself CRSF. (05, 11)

**LQ (link quality)** — ELRS packet-success %, 0–100. LQ=0 in stats = receiver declared
link loss; latched as the RX failsafe flag. (06, 09)

**mediamtx** — bundled media server converting camera RTSP → WebRTC for the HUD. (08)

**Mermaid** — the text-to-diagram library the atlas (and this manual) use; the atlas
loads it from a CDN, so first view needs internet. (05)

**Mix (transmitter)** — a radio's own channel-shaping math (offsets, scales, curves). A
mix that never crosses −250 would make the ARM switch impossible to turn off — D8
Phase 4 checks for exactly this. (05)

**MSP** — MultiWii Serial Protocol; the *rejected* telemetry alternative (standard CRSF
frames won). (08, 09)

**Native module (electron-rebuild / ABI)** — an npm package with a compiled C/C++ binary
(here `serialport`). Because Electron ships its *own* Node with a different **ABI**
(application binary interface — the compiled-in calling convention), such a module must
be **rebuilt against Electron's ABI** (`app:rebuild` / `electron-rebuild`) or it throws
a version-mismatch at load. This is the packaging half of the ground station's
optional-serialport degradation. See **asar**. (08, G4 §6.5)

**Netlist** — a list of pin-to-pin connections describing a circuit; `diagram.json`'s
`connections` array is one. (05)

**"No Pulses" (ELRS failsafe mode)** — receiver goes silent on link loss (vs "Set
Position", which keeps sending hold frames and would defeat the firmware's timeout —
finding A8). RP1 must be set to No Pulses. (05, 06)

**Never-brick chain** — the `Settings::deserialize` guard order **length → CRC → version →
valid()**: a stored blob is applied only if all four pass, else the firmware keeps the
compiled-in `kDefaults`. Means "a bad blob can never make the car run invalid settings"; does
NOT mean the flash worked, the lifecycle is wired, or the firmware is un-brickable in general
(those are C9b/C10/hardware). (09a)

**npm / package.json** — Node's package manager and the manifest it reads. `package.json`
declares the app's identity, its entry point (`main`: `main/main.js`), its **scripts**,
and its dependency buckets. The ground station's has **no `dependencies`** — only
`optionalDependencies` (serialport) + `devDependencies` — so its runtime code depends on
nothing that must install, matching the app's graceful-degradation design. (08, G4 §2)

**npm script** — a named command under `package.json` `"scripts"`, run with `npm run
<name>` (`start`/`test`/`install` need no `run`). The ground station's eight scripts are
its whole entry-point surface: `start`, `demo`, `test`, `setup`, `build`, `package`,
`fetch-mediamtx`, `postinstall`. (08, G4 §2.2)

**NSIS** — Nullsoft Scriptable Install System: the Windows installer format
`electron-builder` targets for the shipped `.exe`. CI's package-smoke job **skips** it
(`--dir` only), so "it packages" is not "the installer works". (08, G4 §6.4)

**NVS** — ESP32 non-volatile storage (flash key-value); persists tuning settings via
the never-brick guard chain. (06)

**Open-collector** — output that can only pull low; needs a pull-up. The Hall output.
(03)

**Overrun (crackle window)** — the race-engine pop-and-bang after a sharp lift from high
revs. EngineSim *detects* it (throttle drop ≥ 40 points in one tick from ≥ 10,400 rpm)
and opens a 900 ms eligibility flag (`overrunActive`); the synth adds the actual gated
noise bursts. Hard braking counts as a lift (signed math: drop 100−(−100) = 200). (07, S2)

**Packed parameter word (cross-core)** — the single `std::atomic<uint32_t>` carrying synth
params from core 1 to core 0: bits 0–15 engineRpm, 16–23 volume, 24 ersWhine, 25 limiter,
26 overrun, 27–31 reserved. One aligned 32-bit word = a torn-free, lock-free hand-off. The
dead-man heartbeat is a *separate* atomic. S5 confirmed the word in the flesh
(`gSynthParams`, `main.cpp`): stored each 50 Hz control tick, re-read before every audio
block, both ends `memory_order_relaxed` — sufficient because no invariant spans the two
atomics. Word value 0 decodes to silence, making boot safe by initial value.
(07, S3, S5; open q #43 — closed) See Phase accumulator, Volume map.

**Parasitic powering** — driving a signal into an unpowered chip leaks current through
its protection diodes, half-powering it; why the link2 spec warns against driving the
line into an unpowered board #2 for long. (05)

**Perimeters / walls** — the solid outline loops of each printed layer; 4–5 on
structural parts because walls carry most of the load. (05)

**Phase accumulator** — an oscillator's position stored as a `uint32_t` where 0…2³²−1
spans one cycle; add a fixed increment each sample and the natural wraparound at 2³² *is*
the cycle repeat. inc = freq × 2³² / sampleRate (computed in milli-Hz here for precision).
The synth's partials, whine, and limiter gate all use one. (07, S3)

**Phase-lock** — timing logic that *depends* on a sender's exact frame spacing; the
link2 spec forbids receivers from doing it. (05, 09)

**Pinion / spur / pitch (48DP)** — the motor's small gear / the big driven gear / their
tooth size. Both must be 48-pitch or they won't mesh — "the one mesh-killer." (05)

**PlatformIO** — the embedded build system both firmware repos use: `platformio.ini`
declares *environments* (`esp32dev` / `esp32dev_sim` / `esp32dev_tuning` / `native`);
`pio run` / `pio test` build and test them. (11, C10)

**POM (acetal/Delrin)** — slippery, wear-resistant engineering plastic; the spur gear's
material. (05)

**Power budget (LED)** — `LightConfig::valid()` computes the worst-case strip current
(all 30 pixels amber at the brightness cap: `(2·20mA·cap)/255 × 30`) and refuses configs
over 900 mA — electricity rejected at compile time. Estimate is pre-gamma and
both-channels-full, so ~5× conservative (safe direction). (03, 07, S4)

**Preferences (Arduino)** — the Arduino-ESP32 library wrapping **NVS** as a simple named
key→blob store; `Esp32NvsStore` uses it to persist the settings blob (namespace `w17tune`, key
`settings`). Hardware-only; not exercised by native tests. (09b)

**Preload / contextBridge (Electron)** — the small privileged script
(`main/preload.cjs`) that runs between Electron's sandboxed page and Node:
`contextBridge.exposeInMainWorld` publishes a hand-picked API object into the page
(here `window.groundStation`: exactly `getConfig` / `onTelemetry` /
`sendCommandMirror`). The page never sees `require`, `ipcRenderer`, or any Node
primitive — the whole machine-access surface is those three functions. (08, G2)

**Promise / `async`–`await`** — JS's "value that arrives later": a Promise represents
a pending result; `await p` inside an `async` function suspends *that function* (not
the process) until the result lands. Used for Electron boot
(`app.whenReady().then(async …)`), request/response IPC (`ipcRenderer.invoke`), and
the CJS→ESM dynamic `import()` of `linkState.mjs`. (G2 §1)

**Potentiometer (pot)** — a knob-adjustable voltage divider; the Wokwi stand-in for the
battery divider (preset 69% ≈ 2.27 V ≈ 8.4 V pack). (05, 11)

**Pull-up resistor** — resistor to a supply giving a floating line a defined high.
10 kΩ to 3.3 V on the Hall line. (03)

**Pure logic / pure function** — code with no hardware access and no hidden state/clock;
the project's testability foundation. (02, 04)

**PWM (servo PWM)** — 50 Hz pulses, width 1000–2000 µs (servos up to 500–2500) encoding
position/throttle. (03)

**Rectilinear (infill)** — straight-line fill pattern; used here only at 100% density.
(05)

**Rain light (harvest cue)** — the 2-pixel white 4 Hz flash shown while ERS is
*harvesting* (the real-F1 cue). The frame has no harvest flag, so it's **derived
locally**: `ersPercent` strictly rising while `driveMode == 2`, remembered for 400 ms
per rise (first frame only seeds the baseline). Deploying makes the percent *fall* and
never triggers it. (07, S4)

**Raw struct copy (serialization)** — packing a blob by `memcpy`-ing a struct's whole memory
image (members + alignment padding) rather than field-by-field. Deterministic only within one
build; `lib/settings` uses it (safe because the same build reads it back), unlike the portable
field-by-field wire formats of CRSF/link2. (09a)

**Regular expression (regex)** — a text-pattern mini-language; `/G(\d+)/` means
"letter G, then one-or-more digits, captured". `shared/crsf.js`'s `parseFlightMode`
uses three of them to read `"G3 M2 E55"` tolerantly — the ground half of the
firmware's `snprintf("G%u M%u E%u")`. (G1 §4.5)

**Regression test** — a test added after a bug so it can never silently return; A1's
fix added "no frame ever ⇒ Safe at every timestamp." (05)

**requestAnimationFrame (render loop)** — the browser API that calls your function
right before the next screen repaint (~60 Hz, display-synced, paused when hidden);
re-requesting inside the callback makes a render loop — the renderer's answer to the
firmware's 50 Hz tick, with the *display* as the clock. The HUD's `frame()` also
clamps `dt` to 50 ms so a stall drops time instead of catching up (the tick-guard
policy, one `Math.min`). (G3 §1/§7.2)

**Rev limiter (ignition cut)** — the redline "braaap": the synth gates its whole output to
zero at 18 Hz, 50 % duty (an accumulator's top bit read as a square wave) while
`limiterActive`, mimicking an F1 ignition cut. EngineSim raises the flag; EngineSynth
renders it. (07, S3)

**Risk register** — a numbered, ranked list of everything that could still go wrong,
each entry carrying severity, confidence, a verification verdict (CONFIRMED / ADJUSTED /
REFUTED / PLAUSIBLE), whether hardware is needed to close it, and when to fix it. This
project's lives in `w17-control-fw/project-review/10_risk_register.md`: 22 stable
`R##` entries (4 High, 13 Medium, 5 Low). Referenced by commit messages and CI job
names. (12)

**RTSP** — classic IP-camera streaming protocol; the camera's native output. (08)

**Sample / sample rate** — one audio sample = one int16 telling the speaker cone where to
be; the rate is how many per second. This project uses 22,050 Hz (`kSampleRateHz`), so one
sample ≈ 45.4 µs. Stereo frames interleave L,R,L,R… (07, S3)

**Saturation (hard clip)** — clamping an out-of-range audio value to the int16 rail
(±32,767) instead of letting it wrap (signed overflow → glitch/UB). The synth's final
clamp is a saturating backstop; the headroom budget means it should never fire. (07, S3)

**SDP offer/answer (WebRTC handshake)** — how two WebRTC peers agree on a media
session: one sends an **offer** (an SDP text blob describing what it can receive),
the other returns an **answer**, then media flows. **WHEP** compresses the exchange
into a single HTTP POST (body = offer, response = answer) — `renderer/whep.js` is the
whole protocol in one `fetch`. (08, G3 §1/§8)

**Sensored** — see Brushless motor.

**Serialize / deserialize (settings)** — `serialize` packs a `Settings` into a blob (version +
raw struct + CRC); `deserialize` runs the never-brick guard chain and returns the values only
if every guard passes, leaving the caller's settings untouched on any failure. Pure functions
over byte buffers — no flash, no store. (09a)

**Servo horn (25T)** — the arm on a servo's output shaft; "25T" = 25 splines, which
must match the servo. The DS3235SG ships one. (05)

**Servo saver** — a spring-loaded steering horn that absorbs impacts before they reach
the servo's gears (`servosaverv7` printed part). (05)

**Silvering (decals)** — silvery haze from micro-air trapped under a decal applied to a
matte surface; why gloss clear goes on *before* decals. (05)

**Sine table / wavetable** — a precomputed table of one sine cycle (256 signed entries,
amplitude ±256) indexed by the top 8 bits of a phase accumulator, so render-time trig is a
table read, not a `sin()` call. Built once at startup — the only place float is allowed
(house rule). (07, S3)

**Skeptical audit** — the independent, pre-hardware review of all three repos
(2026-07, output in `w17-control-fw/project-review/`) that treated all code as "guilty
until proven correct": ten dimension investigations, cross-dimension dedupe, then an
adversarial re-check of every High/Medium finding (some were downgraded or refuted).
Produced the risk register, the hardware validation plan, and — after owner triage —
the F1–F4 fix batches. Chapter 12 is the guided tour. (12)

**Smoke test** — first power-on check that nothing obviously misbehaves before
connecting valuable loads; D8 Phase 1. (05)

**Staleness** — "data too old to trust": every consumer has a timeout (see Failsafe).
(07, 09, 10)

**Static initialization** — C++ constructs global objects before `setup()` runs; timing
anchored there (instead of first use) caused finding A5. (04, 05)

**static_assert + valid()** — compile-time config validation: invalid config = build
error. (04)

**Strapping pins** — ESP32 pins sampled at boot (0/2/12/15); avoided for outputs. (03)

**Stub axle** — the short fixed shaft a front wheel's bearings spin on. (05)

**Styrene** — the fume ASA emits while printing; enclosed *and* ventilated printing
required. (05)

**Task pinning (FreeRTOS)** — creating a task locked to one CPU core
(`xTaskCreatePinnedToCore`). Soundlight: `audioTask` pinned to core 0 (priority 5,
4096-**byte** stack — ESP-IDF counts bytes where vanilla FreeRTOS counts words); Arduino's
`loopTask` (running `setup()`/`loop()`) is created by the framework on core 1, priority 1.
Priorities compete only within a core. The task watchdog watches only core 0's IDLE task
(framework default), which is why a never-blocking `loop()` is safe while the audio task
must block regularly — and does, in `i2s.write`. (07, S5)

**Telemetry backchannel** — car→ground data over the ELRS downlink as standard CRSF
frames (0x08 battery, 0x02 GPS/speed, 0x21 flight-mode string, 0x14 LQ). (09)

**Tick guard (phase-accumulating)** — the `now - last >= period` cadence check with
`last = now`: time lost to a stall is dropped, never "caught up." The alternative
(`last += period`) would fire a burst of make-up ticks after a stall — rejected in the
conductor because nothing integrates tick count. (C10)

**Toe** — the inward/outward angle of the front wheels seen from above; set by
adjusting the turnbuckle lengths. (05)

**Trial-copy validation** — the console's `set` writes the new value onto a *copy* of the
settings (`next = s`), validates it (`next.valid()`), and commits (`s = next`) only if valid —
so an invalid value never touches the live RAM settings. The runtime cousin of C9a's
deserialize guard. (09b)

**Turnbuckle** — a rod threaded oppositely at each end: rotating it lengthens/shortens
the link without disconnecting it. Sets toe; sacrificial in crashes. (05)

**Two-point calibration** — calibrating with measurements at two known values (~6.5 V
and 8.4 V) to correct both offset and slope; D8 Phase 8's battery ADC procedure. (05)

**UART** — universal asynchronous serial port; three in use on board #1 (CRSF 420k,
link2 115200, console 115200). (03)

**Unity** — the C unit-test framework used by `pio test`. (04, 11)

**Validation gate (hardware gate)** — a rule of the form "activity X is forbidden until
check Y has passed *and been recorded*" — how the project keeps software confidence from
quietly being treated as hardware proof. Current gates (see `../CURRENT_STATUS.md` for
live status): Phase-A software items A1.1–A1.6 complete; the **A2 no-power multimeter
checklist is committed but NOT executed**; **Phase B (any powered bring-up) is blocked**
until A2 is filled in, reviewed, and approved; ESC motor power stays disconnected until
the failsafe + arm chain is proven live. (11, 12)

**Version byte / versioned blob** — the first byte of a settings blob (`kBlobVersion`). On any
layout change the version is bumped, so an old persisted blob fails the version guard and the
firmware falls back to defaults — the flash analogue of link2's `BadVersion`. (09a)

**VIN** — the DevKit pin accepting ~5 V input power. The Wokwi diagram wires virtual
servos to it (cosmetic — real servos are powered from Rail B, never the DevKit). (05)

**Virtual channel** — an RC channel that terminates in software state (gear, boost,
overtake, mode) instead of a physical output wire. Atlas ELEC-04. (05, 06)

**Virtual gearbox** — software gears: per-gear output cap + expo, scale-not-clip.
`lib/gearbox`. (10)

**vitest** — the JS test runner in the ground station. (08)

**Volume map (`volumeFor`)** — the 12-line policy in soundlight's `main.cpp` that derives
the synth's volume byte from the two `EngineState` fields that don't cross the cores:
`Ignition::Off → 0` (the load-bearing silence path — rpm 0 alone does NOT silence the
synth), `Cranking → 70`, `Running → 90 + throttle·165/100` (90..255). Glue policy living
at the composition layer, owned by neither EngineSim nor EngineSynth. Answered open q #43;
interacts with the smoother's parking quirk (#53): full throttle renders ≈75 %, the crank
whir ≈2.7 %. (07, S5)

**W17_SIM_CRSF_FEEDER** — the build flag (env `esp32dev_sim`) compiling in the scripted CRSF
self-feeder + serial narration for Wokwi Stage 2; the whole module vanishes from the real
firmware. (C10, 11)

**W17_SIM_LINK2_FEEDER** — the build flag (env `esp32dev_sim`, soundlight) compiling in
`SimLink2Feeder`: a scripted 14 s drive injected through the real assembler+monitor path
(incl. a true 1 s dropout → staleness → hazard demo), with `[sim] phase:` narration on
UART0. The whole module vanishes from the real firmware — the soundlight twin of
W17_SIM_CRSF_FEEDER. (11, S5)

**W17_TUNING_CONSOLE** — the build flag that compiles in the serial tuning console + NVS store
(`esp32dev_tuning` env). The delivered gift firmware (plain `esp32dev`) is built *without* it —
no console surface, **and (C10 correction) no settings code at all**: the NVS-saved tuning
persists in flash but the plain build never reads it and runs compiled-in defaults (open
question #49). (09b, C10)

**WHEP** — HTTP handshake standard for *receiving* WebRTC streams; `renderer/whep.js`.
See SDP offer/answer. (08, G3 §8)

**Wokwi** — browser/VS-Code ESP32 simulator running the real firmware against the
virtual circuit in `diagram.json`. (05, 11)

**WS2812B** — addressable RGB LEDs; one data wire, 30 LEDs, level-shift fixes required.
(03)

**xorshift32 (LFSR noise)** — a fast pseudo-random generator (three XOR-with-shifted-self
steps) in the linear-feedback-shift-register family; deterministic given its seed, so the
synth's noise is bit-exactly reproducible for tests. Seed 0 is a dead fixed point (the
constructor guards it to 1). (07, S3)

**XT60 / XT30** — battery/accessory power connectors; the XT60 **Y-split** feeds ESC +
both BECs from one pack. (03, 05)

**Zipper noise / parameter smoothing** — audible stepping when a parameter (volume, rpm)
jumps on ~50 Hz control updates. The synth hides it with a per-sample one-pole smoother
(`s += (target − s) >> 6`). Same exponential-approach family as C7's EMA and S2's inertia
— but its integer truncation parks short of the target (open q #53). (07, S3)
