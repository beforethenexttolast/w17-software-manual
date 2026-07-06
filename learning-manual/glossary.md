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

**Anisotropy / layer orientation** — FDM prints are weakest *between* layers; the print
spec's golden rule is to orient stressed parts so load runs along the layers. (05)

**Arm / ArmGate** — "armed" = the motor may respond to throttle. Requires arm switch ON
*and* throttle seen at neutral since the last disarm. `lib/channels/ArmGate`. (06, 10)

**ASA / PETG / PLA** — 3D-printing filaments: heat-resistant (fumes: see Styrene) /
tough / easy-but-soft. Assigned per part group by heat + load. (05)

**Attenuation (ADC, 11 dB)** — input-range setting letting the ESP32 ADC read up to
~2.5 V linearly. The divider was sized to fit under it. (03, 05)

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

**Brownout** — a supply-voltage dip that resets electronics; servo current spikes cause
it; the 1000 µF rail capacitor prevents it. (03, 05)

**Brushless motor / sensored** — the drive motor type; "sensored" adds position sensors
(extra ribbon cable) for smooth low-speed control. (03)

**Check value (CRC)** — the standard fingerprint for verifying a CRC implementation:
CRC of ASCII `"123456789"`. For CRC-8/DVB-S2 it is 0xBC. (05, 09)

**com0com / hub4com** — Windows virtual serial-port splitter: one owner mirrors a
physical COM port to several virtual ones. The planned fix for the FT232 telemetry
sharing problem. (08)

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

**Conductor (`main.cpp`)** — the control firmware's composition file: constructs every module,
injects the pins from `PinMap.hpp`, and schedules all cadences (50/20/10/5 Hz). Wiring and
scheduling only — no mechanisms of its own; excluded from native tests (`test_build_src = no`),
so its claims are source+build-verified, never test-verified. (C10)

**ControlSnapshot** — the struct the conductor fills with what the control tick *actually
commanded* (plus gear/rpm/battery/ERS at send time) and hands to `Link2Sender` at 20 Hz.
Boot-safe defaults (`failsafe = true`) so the first frame can never report a phantom Active.
(09, C10)

**Dead-man (audio)** — soundlight rule: synth params not refreshed ~500 ms ⇒ volume
ramps to 0. (07)

**DISARMED gating** — the tuning console refuses all *mutating* commands (`set`/`save`/`load`/
`reset`) while the car is armed; `get`/`status`/`help` stay allowed. Tuning is a "pit-lane"
activity — you can inspect a live car but never re-tune it. (09b)

**Drive mode** — the ch13 3-position policy wired in `main.cpp`: **0 = Training** (one
fixed gentle shape {400, 50}; paddles inert to output), **1 = Gearbox** (default — also
what an absent channel decodes to), **2 = Gearbox+ERS**. No raw pass-through by design:
top gear already *is* full power, and authority stays monotone along the switch. (06, C10)

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

**Endianness** — byte order of multi-byte numbers. link2 = little-endian; CRSF
telemetry payloads = big-endian. (09)

**ELRS (ExpressLRS)** — open-source 2.4 GHz RC radio link; TX module ↔ RP1 receiver;
also relays standard telemetry frames back. (01, 09)

**ERS** — Energy Recovery System (F1 concept). Simulated store: deploy via
boost/overtake, harvest while braking/coasting with wheels turning. `lib/ers`. (10)

**ERS whine** — the synth's electric-motor keening layer: a sine at 3× the firing
frequency (MGU-K crank-coupled feel), gated on by `ersDeploying` with a ~23 ms fade-in/out
so it can't click. `lib/soundsynth`. (07, S3)

**ESC** — electronic speed controller: converts 1000–2000 µs PWM into three-phase motor
power. Hobbywing 10BL120, sensored, forward/brake mode. (03)

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

**Fresh-neutral rule** — after *any* disarm or failsafe episode, throttle must be seen
at neutral again before power flows (closes finding A3). (10)

**Function-local static** — a variable declared `static` inside a function: initialized once
(the first time execution reaches it) and keeping its value across calls — static storage, not
the stack. Used for the sim status-print and feeder timestamps. (C10)

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

**Hysteresis** — different thresholds for turning on vs off, preventing chatter: switch
decode (±250), battery warning (7.0/7.4 V), brake flag. (06, 10)

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
dead-man heartbeat is a *separate* atomic. (07, S3; open q #43) See Phase accumulator.

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

**Preferences (Arduino)** — the Arduino-ESP32 library wrapping **NVS** as a simple named
key→blob store; `Esp32NvsStore` uses it to persist the settings blob (namespace `w17tune`, key
`settings`). Hardware-only; not exercised by native tests. (09b)

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

**Raw struct copy (serialization)** — packing a blob by `memcpy`-ing a struct's whole memory
image (members + alignment padding) rather than field-by-field. Deterministic only within one
build; `lib/settings` uses it (safe because the same build reads it back), unlike the portable
field-by-field wire formats of CRSF/link2. (09a)

**Regression test** — a test added after a bug so it can never silently return; A1's
fix added "no frame ever ⇒ Safe at every timestamp." (05)

**Rev limiter (ignition cut)** — the redline "braaap": the synth gates its whole output to
zero at 18 Hz, 50 % duty (an accumulator's top bit read as a square wave) while
`limiterActive`, mimicking an F1 ignition cut. EngineSim raises the flag; EngineSynth
renders it. (07, S3)

**RTSP** — classic IP-camera streaming protocol; the camera's native output. (08)

**Sample / sample rate** — one audio sample = one int16 telling the speaker cone where to
be; the rate is how many per second. This project uses 22,050 Hz (`kSampleRateHz`), so one
sample ≈ 45.4 µs. Stereo frames interleave L,R,L,R… (07, S3)

**Saturation (hard clip)** — clamping an out-of-range audio value to the int16 rail
(±32,767) instead of letting it wrap (signed overflow → glitch/UB). The synth's final
clamp is a saturating backstop; the headroom budget means it should never fire. (07, S3)

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

**W17_SIM_CRSF_FEEDER** — the build flag (env `esp32dev_sim`) compiling in the scripted CRSF
self-feeder + serial narration for Wokwi Stage 2; the whole module vanishes from the real
firmware. (C10, 11)

**W17_TUNING_CONSOLE** — the build flag that compiles in the serial tuning console + NVS store
(`esp32dev_tuning` env). The delivered gift firmware (plain `esp32dev`) is built *without* it —
no console surface, **and (C10 correction) no settings code at all**: the NVS-saved tuning
persists in flash but the plain build never reads it and runs compiled-in defaults (open
question #49). (09b, C10)

**WHEP** — HTTP handshake standard for *receiving* WebRTC streams; `renderer/whep.js`.
(08)

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
