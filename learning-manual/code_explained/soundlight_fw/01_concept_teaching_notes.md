# S1 — Concept Teaching Notes

A beginner-first companion to
`01_link2_receiver_and_protocol_compatibility.md`. The batch document explains *the code
line-by-line*; this document explains *the ideas* behind it, one concept at a time, so the
lessons stick beyond this one module. Same format as the C9a/C9b/C10 teaching notes.

Every concept below follows the same six-step shape:

1. **Plain meaning** — what it is, no jargon.
2. **Why embedded needs it** — why this matters on a tiny microcontroller talking to
   another over a wire.
3. **S1 code** — the exact place it lives (file + the snippet or test).
4. **C8 connection** — how the sender side (batch C8) and receiver side (S1) meet here.
5. **Beginner traps** — the misunderstanding that bites people first.
6. **Bug prevented** — the concrete failure this concept exists to stop.

Reference map (read alongside):
`../control_fw/08_link2_outbound_protocol.md` (C8, the sender), chapter 09 (protocols at
spec level), `../../glossary.md`, `../../open_questions.md`.

---

## 1. Why link2 exists at all

**Plain meaning.** The car has two brains: ESP32 #1 ("control") reads the radio, drives
the motor and steering, and decides everything. ESP32 #2 ("sound + light") makes the
engine noise and runs the LED strip. #2 needs to *know what #1 is doing* — throttle,
gear, braking, whether the car is armed — so it can perform in sync. **link2** is the
private wire between them: a one-way stream of small messages, #1 → #2, ~20 times a
second.

**Why embedded needs it.** You could imagine one big ESP32 doing everything. But audio
synthesis is a greedy, unforgiving real-time job (thousands of samples per second — see
chapter 07 §6), and mixing it with the safety-critical control loop on one chip risks
one starving the other. Splitting the work across two chips isolates the timing. The cost
of splitting is that they must now *communicate* — and that communication needs rules.
That set of rules is a **protocol**.

**S1 code.** The whole format is documented at the top of
`w17-soundlight-fw/lib/link2/include/link2/Link2Frame.hpp` (lines 6–33) and in
`docs/link2_protocol.md`. The receiver's job starts at `Link2Monitor`.

**C8 connection.** C8 is board #1 *building and sending* these messages (`Link2Sender` →
`encodeFrame` → UART). S1 is board #2 *receiving and interpreting* them
(`Link2FrameAssembler` → `decodeFrame` → `Link2Monitor`). Same protocol, two ends.

**Beginner traps.** "It's just a wire, why not send the raw numbers?" Because a wire
delivers *bytes with no boundaries* — the receiver can't tell where one message ends and
the next begins, or whether a byte got corrupted, without agreed-upon rules.

**Bug prevented.** Without a defined protocol, board #2 would guess at message boundaries
and occasionally act on garbage — playing a scream when the car is parked, or missing a
"braking" event. A protocol turns a noisy byte stream into trustworthy events.

---

## 2. Sender side vs receiver side

**Plain meaning.** A protocol has two halves that must agree perfectly: the **sender**
packs meaning into bytes; the **receiver** unpacks bytes back into meaning. They're mirror
images — every "write byte 7 = low half of rpm" on the sender has a matching "read byte 7
as low half of rpm" on the receiver.

**Why embedded needs it.** The two halves usually run on *different chips*, compiled
separately, possibly written months apart. Nothing at runtime forces them to agree — no
shared memory, no type checker spanning both. The agreement is a *human* discipline,
enforced by tests, not by the compiler.

**S1 code.** Receiver side is `decodeFrame` (`Link2Codec.cpp:43–77`) and
`Link2FrameAssembler::feedByte` (lines 79–115). Sender side is `encodeFrame` (lines
17–41) — present in the copy but exercised here mainly by tests and the future sim feeder.

**C8 connection.** This *is* the C8↔S1 split. C8 owns `Link2Sender` (scaling, brake-light
hysteresis) — genuinely sender-only, and correctly **absent** from board #2's copy. Board
#2 keeps the codec + assembler because those are what a receiver runs.

**Beginner traps.** Thinking the receiver is "the same code run backwards." It isn't —
encoding and decoding are separate functions. What makes them safe to trust here is that
they're the *same source file* on both boards (concept 3).

**Bug prevented.** Sender/receiver disagreement — e.g. sender writes rpm low-byte-first,
receiver reads high-byte-first → rpm 1500 decodes as 56,325 and the engine screams at a
standstill. The mirror discipline (and golden-frame tests) catches exactly this.

---

## 3. Copied protocol code ("do not fork")

**Plain meaning.** Instead of writing board #2's link2 decoder from scratch, the project
**copies board #1's `lib/link2` folder verbatim** into board #2. The rule (in
`w17-soundlight-fw/CLAUDE.md`): *"copied VERBATIM from w17-control-fw; do not fork;
protocol changes happen there first."* One repo *owns* the protocol; the other mirrors it.

**Why embedded needs it.** Two hand-written implementations of the same protocol *will*
drift over time — someone fixes a bug on one side, forgets the other. Copying identical
source makes drift structurally impossible for the copied files: they either match
byte-for-byte or they don't.

**S1 code.** `w17-soundlight-fw/lib/link2/` = `Link2Frame.hpp`, `Link2Codec.hpp`,
`Link2Codec.cpp`, `library.json` — all confirmed md5-identical to the control repo (S1
§1.1). `Link2Sender.{hpp,cpp}` are *not* copied (receiver doesn't send).

**C8 connection.** Everything C8 verified about the format — CRC, endianness, validation
order — transfers to S1 *for free*, because it's literally the same bytes of source. S1
references C8 instead of re-explaining.

**Beginner traps.** "Copy-paste is bad practice!" Usually yes — but here it's a
*deliberate* strategy with a guardrail (the diff/checksum check). The alternative (a
shared library both repos depend on) has its own costs (build coupling across two
projects). The trade-off is discussed in the batch doc's teaching-concepts list.

**Bug prevented.** Silent protocol drift: board #1 grows the payload, board #2's separately
maintained decoder doesn't — and every frame mis-decodes. Copy-discipline + a diff check
turns that into an obvious, catchable event.

---

## 4. Diff verification (proving the copy is really identical)

**Plain meaning.** "Copied verbatim" is a *claim*. Diff verification is the *proof*: run a
tool that compares the two folders and reports any difference. Two ways used in S1:
`diff -r` (shows differing lines/files) and `md5` checksums (a short fingerprint of a
file's exact bytes — same fingerprint ⇒ identical file).

**Why embedded needs it.** A comment saying "verbatim copy" can rot — someone edits one
copy "just a little." You don't want to *trust* the claim; you want to *check* it, and
checking is cheap.

**S1 code.** Method in S1 §1.1: `diff -r` output was just two lines (`Link2Sender.*` only
in control — expected); md5 matched on all four shared files; the spec doc
`docs/link2_protocol.md` matched too.

**C8 connection.** This is the single act C8 said had to happen before cross-repo
compatibility could move from **PROVISIONAL** to **VERIFIED**. C8 literally wrote: "VERIFIED
only once batch S1 diff-verifies the copy." S1 did it.

**Beginner traps.** Confusing this checksum (md5, an *identity* fingerprint of a whole
file) with the *protocol's* CRC (a *corruption* check on 12 wire bytes). Same math family,
totally different jobs — see concept 12 and the batch doc's teaching list.

**Bug prevented.** A stale "verbatim" comment hiding a real fork. If someone had tweaked
board #2's decoder, the md5 would differ and S1 would flag a finding instead of blessing a
broken assumption.

---

## 5. Frame assembly (bytes → messages)

**Plain meaning.** A UART delivers **one byte at a time**, with no markers for "message
starts here." A **frame assembler** is a little state machine that watches the byte stream
and re-groups bytes into complete messages ("frames"). link2's assembler has three states:
waiting for the start byte → reading the length byte → reading the body.

**Why embedded needs it.** Bytes arrive asynchronously, often one per interrupt. You can't
"wait for a whole message" in one blocking read — you feed bytes in as they come and let
the state machine tell you when a frame is complete.

**S1 code.** `Link2FrameAssembler::feedByte` (`Link2Codec.cpp:79–115`). Returns
`Incomplete` for the 13 in-progress bytes, then `FrameReady` or `FrameInvalid` on the
14th. Test: `test_assembler_hard_rejects_bad_length_byte` and
`test_assembler_resyncs_after_corruption` (S1 §6).

**C8 connection.** Same assembler code as C8 (copied). C8 introduced it as "present because
the lib is liftable"; S1 makes it the star — it's what board #2 actually runs on incoming
UART bytes.

**Beginner traps.** Expecting `feedByte` to return the frame. It returns a *status*; the
decoded frame lives in `assembler.lastState()`, valid only right after `FrameReady`.

**Bug prevented.** Treating stream position wrongly — e.g. assuming every 14th byte starts
a new frame. If one byte is dropped, a fixed-stride reader is misaligned forever. A
state machine that hunts for the start byte can **resync** (concept 15).

---

## 6. The start byte

**Plain meaning.** The first byte of every frame is a fixed, known value: `0xA5`. It marks
"a message probably begins here." It is *not* data — it's a signpost.

**Why embedded needs it.** After corruption or a mid-stream power-on, the receiver may be
"lost" in the middle of a frame. The start byte is the landmark it hunts for to get back
in sync.

**S1 code.** `kStartByte = 0xA5` (`Link2Frame.hpp:37`). The assembler's `WaitingForStart`
state ignores every byte until it sees `0xA5` (`Link2Codec.cpp:81–88`). Decode rejects a
wrong first byte as `BadStart` (`decodeFrame`, line 47; test case in
`test_decode_rejections`).

**C8 connection.** Identical value on both ends (checksum-verified). The golden frame's
byte [0] is `0xA5` in both repos' tests.

**Beginner traps.** Thinking the start byte is protected by the CRC. It isn't — the CRC
covers length + payload only (concept 12), because a framing marker's job is *alignment*,
not integrity. Also: `0xA5` can legitimately appear *inside* a payload (concept 15) — the
start byte is a hint, not a guarantee.

**Bug prevented.** Permanent desync. Without a start byte, a receiver that loses alignment
never recovers. With one, it just waits for the next `0xA5` and tries again.

---

## 7. The length byte

**Plain meaning.** The second byte says how many **payload** bytes follow (11, in v1). It
tells the receiver how much to read before expecting the checksum.

**Why embedded needs it.** It lets the receiver know a frame's size without hard-coding it
everywhere, and — crucially here — lets the receiver *reject nonsense sizes immediately*.

**S1 code.** `kPayloadLen = 11` (`Link2Frame.hpp:39`). The assembler's `ReadingLength`
state **hard-rejects** any length that isn't 11 the instant it arrives
(`Link2Codec.cpp:90–97`), returning `FrameInvalid` and resyncing. Test:
`test_assembler_hard_rejects_bad_length_byte`.

**C8 connection.** C8 explained *why* the hard-reject exists (a corrupt `0xFF` length would
otherwise make the receiver swallow 255 bytes ≈ a second of frames). S1 shows the receiver
actually doing it — and it's a **spec obligation** the soundlight brief repeats.

**Beginner traps.** Assuming "just buffer `length` bytes and let the CRC sort it out." On a
one-way link with a fixed protocol, a bad length is *known-bad now* — waiting wastes ~1 s
of good frames.

**Bug prevented.** The "swallowed second" bug: one corrupted length byte eats a burst of
following frames before the CRC finally fails and resync happens. Immediate rejection caps
the damage at one frame.

---

## 8. Payload layout

**Plain meaning.** The payload is the 11 bytes of actual content, in a fixed order both
sides memorize: [0] version, [1] throttle, [2] steering, [3] flags, [4] gear, [5–6] rpm,
[7–8] battery mV, [9] ERS %, [10] drive mode.

**Why embedded needs it.** There are no field names on the wire — just positions. "Byte 6
is the low half of rpm" is a shared convention. Compactness matters too: 11 bytes at 20 Hz
is trivial bandwidth; a text format ("rpm=1500;gear=3") would be bigger and slower to
parse.

**S1 code.** Layout documented in `Link2Frame.hpp:16–31`; written by `encodeFrame`
(`Link2Codec.cpp:17–41`) and read back by `decodeFrame` (lines 61–76). Every field is
checked in `test_decode_roundtrip` (S1 §6).

**C8 connection.** Byte-identical layout (same source). The batch doc's §1.2 checklist
confirms each field position matches between repos.

**Beginner traps.** Confusing *payload-relative* indices (version = payload byte 0) with
*frame-absolute* indices (version = frame byte 2, after start + length). C8 §1 flags this
exact trap; the code uses frame-absolute (`out[2]` = version).

**Bug prevented.** Field misalignment — reading gear where rpm lives. One wrong offset
cascades through the rest of the payload. The roundtrip test pins every position.

---

## 9. The protocol version byte

**Plain meaning.** The payload's first byte is a version number (`1`). It says "this frame
follows format version 1." If board #1 is later upgraded to version 2 with a different
layout, board #2 can *recognize* the mismatch instead of mis-decoding.

**Why embedded needs it.** The two boards get reflashed independently. A version byte is
cheap insurance against a future where one board is upgraded and the other isn't.

**S1 code.** `kProtocolVersion = 1` (`Link2Frame.hpp:38`). `decodeFrame` checks it **last**
and returns `BadVersion` if it's not 1 (`Link2Codec.cpp:57–59`). Test: the `BadVersion`
case in `test_decode_rejections`.

**C8 connection.** Same version constant. C8 introduced the "checked after CRC" ordering;
S1 verifies board #2 honors it (concept 13).

**Beginner traps.** Thinking `BadVersion` means "corruption." No — because CRC is checked
*first*, a `BadVersion` result means a *well-formed* frame that's simply newer. That's a
trustworthy "you need an update" signal, not noise.

**Bug prevented.** Silent mis-decode after a one-sided upgrade. Without a version byte,
board #2 would happily decode a version-2 frame using version-1 rules and produce
plausible-looking garbage.

---

## 10. The flags bitfield

**Plain meaning.** Byte [3] packs **eight yes/no facts into one byte**, one per bit:
bit0 braking, bit1 reverse (reserved), bit2 DRS open, bit3 armed, bit4 failsafe,
bit5 low-battery, bit6 ERS deploying, bit7 reserved. Each bit is a boolean.

**Why embedded needs it.** Sending eight separate boolean bytes would waste 7 bytes.
Packing them into one is standard for status flags — cheap and cache-friendly.

**S1 code.** Masks `kFlagBraking = 1u << 0` … `kFlagErsDeploying = 1u << 6`
(`Link2Frame.hpp:43–49`). Encoder ORs each true flag in (`Link2Codec.cpp:23–31`); decoder
tests each bit with `(flags & mask) != 0` (lines 63–70). The golden frame's flags byte is
`0x4C` = drsOpen | armed | ersDeploying, decoded correctly in `test_decode_roundtrip`.

**C8 connection.** Same masks. C8's `test_each_flag_bit_pinned` proves each bit
individually on the sender side; S1's roundtrip proves the combined `0x4C` decodes right
(the per-bit test wasn't re-copied — coverage transfers via source identity, S1 §6).

**Beginner traps.** Bit position vs bit *value*: `1u << 4` (failsafe) is the *value* `0x10`,
occupying bit position 4. Mixing "bit 4" with "the value 4" is a classic off-by-shift
error. Also: bit 7 is reserved — a receiver must **mask** the bits it knows and ignore the
rest, never reject a frame for an unexpected high bit.

**Bug prevented.** Reading the wrong flag — e.g. treating "armed" as "braking" because you
shifted by the wrong amount. Bit masks named as constants (not magic numbers) make this
hard to get wrong.

---

## 11. Little-endian multi-byte fields

**Plain meaning.** rpm and battery mV are 16-bit numbers, so each needs two bytes. link2
sends the **low byte first** ("little-endian"). rpm 1500 = `0x05DC` goes on the wire as
`DC 05`.

**Why embedded needs it.** A number bigger than 255 doesn't fit in one byte; you split it.
Both sides must agree which half comes first, because the wire is just a sequence.
Little-endian is common because it matches how many CPUs store integers.

**S1 code.** Encode: `out[7] = rpm & 0xFF; out[8] = rpm >> 8` (`Link2Codec.cpp:33–34`).
Decode: `rpm = data[7] | (data[8] << 8)` (line 72). Test: `test_decode_roundtrip` reads
`DC 05` → 1500 and `DC 1E` → 7900.

**C8 connection.** Here's the sharp edge: link2 is little-endian, but CRSF *telemetry*
(C4) is **big-endian** (high byte first). Same project, two conventions. C8 stressed
"don't carry C4's big-endian habit here"; S1 confirms board #2 reads little-endian.

**Beginner traps.** Reading `DC 05` as `0xDC05` = 56,325 instead of `0x05DC` = 1500. This
is *the* classic protocol bug and chapter 09's question 1. "Little-endian" = the byte you
see *first* is the *least* significant.

**Bug prevented.** A 37× wrong rpm. Decode 1500 as 56,325 and the synthesized engine
redlines at a standstill — the exact "screaming engine" failure the whole design fears.

---

## 12. Signed vs unsigned fields

**Plain meaning.** Throttle and steering can be negative (−100…+100), so they're stored as
**signed** bytes (`int8_t`, two's complement). rpm, battery, gear, etc. are never negative,
so they're **unsigned** (`uint16_t`/`uint8_t`). The *same 8 bits* mean different numbers
depending on which interpretation you apply.

**Why embedded needs it.** "Braking" is negative throttle; you need signed values to
represent it. But a raw byte is just 8 bits — `0xE7` is either 231 (unsigned) or −25
(signed). The **type** decides.

**S1 code.** `out[3] = (uint8_t)state.throttlePercent` on encode (reinterprets the signed
byte's bits); `out.throttlePercent = (int8_t)data[3]` on decode (`Link2Codec.cpp:21, 61`).
Test: `test_decode_roundtrip` proves `0xE7` → **−25** for steering.

**C8 connection.** Identical casts. C8's roundtrip pushed extremes (−100, +100); S1's uses
the golden −25. Same two's-complement round-trip on both boards.

**Beginner traps.** Expecting the raw byte to "look negative." `0xE7` = 231 as a plain
byte; only when you *declare it `int8_t`* does 231 become 231 − 256 = −25. Two's
complement: if the top bit is set, subtract 256.

**Bug prevented.** Braking read as full throttle. If board #2 decoded steering `0xE7` as
+231 (then clamped to +100), a hard-left command would read as hard-right. The signed cast
keeps the sign.

---

## 13. CRC coverage + validation order

**Plain meaning.** A **CRC** is a 1-byte fingerprint computed from the frame's contents;
the receiver recomputes it and rejects the frame if it doesn't match — that's how it
catches corruption. Two subtleties: **what the CRC covers** (bytes [1..12] = length +
payload, *not* the start byte) and **what order checks run** (start → length → CRC →
version).

**Why embedded needs it.** Wires pick up electrical noise; a bit can flip in transit. The
CRC turns "silently wrong data" into "detected-and-dropped." Ordering matters because it
determines what each rejection *means*.

**S1 code.** `computeCrc8` (`Link2Codec.cpp:5–15`, poly 0xD5). CRC computed over `out + 1,
1 + kPayloadLen` = bytes [1..12] (line 39); checked before version in `decodeFrame`
(lines 54, 57). Tests: `CrcMismatch` and `BadVersion` cases in `test_decode_rejections`.

**C8 connection.** Same CRC algorithm (deliberately duplicated so link2 needs no `lib/crsf`
— C8 §2). The one control-side test S1 *couldn't* copy is `crc_matches_crsf_implementation`
(no `lib/crsf` in this repo); the golden frame's `0xCE` pins it instead.

**Beginner traps.** (a) Thinking the CRC covers the whole frame — it skips the start byte
(a marker, not integrity-covered). (b) Thinking check order is cosmetic — it's what makes
`BadVersion` mean "well-formed but newer" (because a version byte corrupted by noise fails
the *earlier* CRC check first, reporting `CrcMismatch`).

**Bug prevented.** Acting on corrupted commands. A noise-flipped throttle byte changes the
payload → CRC mismatch → frame dropped → the monitor eventually goes stale rather than
executing a phantom command.

---

## 14. Golden-frame tests

**Plain meaning.** A **golden frame** is one exact, hand-verified message whose 14 bytes
are hard-coded in a test: `A5 0B 01 2A E7 4C 03 DC 05 DC 1E 3C 02 CE`. The test encodes a
known state and asserts it produces *exactly* those bytes. The same literal bytes live in
**both** repos' tests.

**Why embedded needs it.** It's the anti-drift anchor. If either board's code changes the
wire format, its golden-frame test breaks loudly. Because both repos hard-code the same
bytes, they can't silently diverge.

**S1 code.** `kGoldenFrame[]` + `test_golden_frame_bytes` (S1 §6). `makeGoldenState()`
builds the state; `encodeFrame` must reproduce the array exactly
(`TEST_ASSERT_EQUAL_UINT8_ARRAY`).

**C8 connection.** This is the "human-maintained contract between this repo, the protocol
doc, and board #2" that C8 named. S1 confirms all three copies (control test, soundlight
test, `docs/link2_protocol.md`) carry identical bytes.

**Beginner traps.** Thinking a passing golden test proves the *hardware* works. It proves
the *encoding logic* produces the agreed bytes — nothing about the wire (concept 20).

**Bug prevented.** Undetected format changes. Reorder two payload fields and the golden
test fails immediately, on whichever side changed — instead of shipping two incompatible
firmwares.

---

## 15. Corrupt-frame handling + resync

**Plain meaning.** When a frame fails any check (bad start, bad length, bad CRC), the
assembler throws it away and returns to hunting for the next start byte. This is
**resync**: recover cleanly, losing at most the one bad frame.

**Why embedded needs it.** Corruption is normal, not exceptional. A robust receiver
tolerates it — one glitchy frame must not derail the stream.

**S1 code.** On any failure the assembler sets `state_ = WaitingForStart; bufferLen_ = 0`
(`Link2Codec.cpp:94–95, 109–110`). Test: `test_assembler_resyncs_after_corruption` feeds a
CRC-broken frame, then a good one, and asserts `FrameReady`.

**C8 connection.** Same resync code. C8 also tested the *hard* case — a `0xA5` byte
legally *inside* a payload (throttle = −91 encodes as `0xA5`) causing a false sync. That
test is pinned **sender-side only**; S1's simpler resync test relies on source identity for
the hard case (S1 §6 coverage note).

**Beginner traps.** Assuming a `0xA5` in the middle of the stream always starts a frame.
It might be payload data. A false sync there just fails CRC a few bytes later and resyncs —
the stream self-heals within a frame or two.

**Bug prevented.** Cascading desync from one bad byte. Without resync, a single corruption
would misalign every subsequent frame permanently.

---

## 16. Stale-link timeout (the 500 ms rule)

**Plain meaning.** link2 is **one-way** — board #2 can never ask "are you still there?" So
board #2 watches the clock: if no CRC-valid frame arrives for **500 ms** (10 missed frames
at 20 Hz), it declares the link **Lost** and fails safe (engine silent, hazard blink).

**Why embedded needs it.** On a one-way link, a cut wire is *indistinguishable* from
"board #1 went quiet holding the last state." The only way to tell is time: silence long
enough = something's wrong. This is a mandatory receiver obligation in the spec.

**S1 code.** `Link2Monitor` (`Link2Monitor.cpp:23–55`). `stalenessMs = 500`
(`Link2Monitor.hpp:21`). The edge is `elapsed >= 500 ms` (**inclusive** — the `>=`).
`poll(nowMs)` must be called every tick even with no bytes — "that is how a silent link
becomes Lost." Tests: `test_staleness_flips_at_exactly_the_window` (499 → Up, 500 → Lost),
`test_recovers_on_next_good_frame`.

**C8 connection.** C8 verified the *sender* keeps transmitting even in failsafe (so a
"failsafe" frame is heard). S1 verifies the *other* failsafe: board #2's local staleness
timeout for when frames stop entirely. These are the "two independent mechanisms" C8
noted — now both in explained source.

**Beginner traps.** (a) Thinking `feedByte` alone maintains status — no, if bytes stop,
`feedByte` is never called; `poll()` is the heartbeat that notices silence. (b) Thinking a
stream of *corrupt* frames keeps the link alive — no, only **CRC-valid** frames refresh the
timer (concept 13 + 16 combine).

**Bug prevented.** A frozen performance after a cut wire — engine screaming the last rpm
forever. The timeout forces safety when the truth is "we no longer know what's happening."

---

## 17. Safe defaults before the first valid frame

**Plain meaning.** When board #2 powers on, board #1 may still be booting — **no frame has
ever arrived**. Board #2 must still be in a safe, sensible state: `failsafe = true`,
throttle 0, gear 1, ERS full, engine silent. That's the **NeverConnected** state.

**Why embedded needs it.** Boot order is unpredictable. A device must be safe *before* it
has any input, not just after. "No data yet" is a first-class state, distinct from "lost
contact."

**S1 code.** `VehicleState`'s in-struct defaults (`Link2Frame.hpp:51–66`, `failsafe = true`
etc.) *are* the boot state. The monitor's `recompute` returns a fresh `VehicleState{}` while
`!everReceived_` (`Link2Monitor.cpp:24–28`). Test: `test_boots_never_connected_and_failsafe`
— including that 100 s of `poll` never turns NeverConnected into Lost.

**C8 connection.** C8 called `failsafe = true` a "boot-safe default: never report a phantom
Active." On the sender that mattered so a default frame wasn't dangerous; on the receiver
it's *literally what the car performs on* before frame one.

**Beginner traps.** Confusing **NeverConnected** with **Lost**. NeverConnected = "board #1
hasn't spoken yet" (normal at power-on); Lost = "was talking, then stopped" (a real event).
The `everReceived_` flag separates them — and NeverConnected never times into Lost.

**Bug prevented.** A boot-time false alarm *or* a boot-time phantom drive. If the monitor
computed `now - lastFrameMs_` with `lastFrameMs_ = 0` at boot, it might wrongly declare
Lost (or, worse, Up) before any real frame. The `everReceived_` gate prevents both. (Mirror
of control finding A1: "no frame ever ⇒ safe.")

---

## 18. Effective state + per-field staleness projection

**Plain meaning.** The monitor doesn't hand consumers "the last frame received." It hands
them the **effective** state — sanitized for staleness. While Up, that's the last frame
verbatim. Once Lost, it **projects per field**: commands (throttle, steering, braking,
armed…) zeroed and `failsafe` forced true; rpm zeroed; but slow facts (battery, gear, ERS%,
drive mode, low-battery judgment) **held** last-known.

**Why embedded needs it.** Different data ages differently. A 500 ms-old *command* is
dangerous (the driver's intent may have changed). A 500 ms-old *battery voltage* is fine
(it barely moved). Blanking the slow facts would make the LED display flicker; keeping the
stale commands would drive a ghost. Sanitizing *once, centrally* means every consumer
(EngineSim, LightRenderer) gets safe data without each re-implementing the rules.

**S1 code.** `Link2Monitor::recompute` Lost branch (`Link2Monitor.cpp:38–55`): copy
`lastGood_`, then overwrite commands + rpm, force `failsafe`, leave the rest. Test:
`test_per_field_staleness_projection` asserts all 13 fields. `lastGood_` is never mutated,
so recovery is one frame.

**C8 connection.** New to S1 — the control repo has no counterpart (it's a *receiver*
concern). It realizes chapter 07 §2's staleness table in code, and completes C8's
"board #2's staleness handling is S1" forward-reference.

**Beginner traps.** Thinking "held" fields require special code. They don't — "held" means
those fields are simply *not overwritten* after the `lastGood_` copy. The quietest lines
are policy too, which is why the code comments them explicitly. Also: holding `gear`
specifically avoids phantom shift-blip *sounds* on recovery.

**Bug prevented.** Two opposite bugs at once: (a) acting on stale commands (ghost driving /
screaming engine), and (b) flickering displays / phantom gear-shift sounds from blanking
slow facts. The per-field split gets both right.

---

## 19. What native tests prove

**Plain meaning.** The tests run with `pio test -e native` — compiled and executed **on the
Mac**, not on an ESP32. They prove the *logic*: given these input bytes, the decoder
produces these values; given this timeline, the monitor reports these statuses.

**Why embedded needs it.** Native tests are fast, deterministic, and need no hardware. They
let you pound the tricky logic (bit-unpacking, boundary timing) thousands of times without
a chip on the bench. This is the whole reason `lib/*` code is "pure" (no Arduino headers) —
so it *can* run on the host.

**S1 code.** 40/40 soundlight tests pass; the S1-relevant 11 are `test_link2` (5) +
`test_link2monitor` (6). They prove: format round-trips, all rejection paths, resync,
staleness boundary, projection, recovery, config validation.

**C8 connection.** Same testing philosophy as every control batch. C8's 13 tests proved the
sender logic on the host; S1's prove the receiver logic on the host. Together they prove
*both ends of the format agree* — but only in software.

**Beginner traps.** Reading "40/40 PASSED" as "it works on the car." It means "the logic is
correct on this laptop." Necessary, not sufficient.

**Bug prevented.** Logic bugs — off-by-one offsets, wrong endianness, an inclusive/exclusive
boundary mistake, a projection that zeroes the wrong field. All caught cheaply before
hardware.

---

## 20. What native tests cannot prove — and what needs real ESP32/UART

**Plain meaning.** Native tests say nothing about **the physical world**: whether a real
wire from board #1's GPIO25 to board #2's GPIO16 actually delivers those bytes, whether the
two boards' clocks agree closely enough at 115200 baud, whether grounds are common, whether
the UART driver feeds bytes into `feedByte` at all. Those need the actual chips.

**Why embedded needs it.** Software correctness ≠ system correctness. The most careful
decoder is useless if the wire is noisy, the ground floats, or `main.cpp` forgets to call
`poll()`. Embedded work always has this software/hardware seam.

**S1 code.** Everything behind the `hal`-excluded boundary and the S5 `main.cpp` wiring is
**PROVISIONAL**: that UART bytes reach `feedByte` with `millis()` as `nowMs`, that `poll`
runs every tick, the config `static_assert`, and every electrical property. The pin map
(S1 §2) *names* the pins but a constant isn't a wire.

**C8 connection.** Exactly parallel to C8's own PROVISIONALs: C8 couldn't prove GPIO25 was
really wired or that the UART never blocks; S1 can't prove GPIO16 receives. The **wire in
the middle** is the one thing neither batch can close — only a bench can (D8-style
integration).

**Beginner traps.** Assuming "compatible source + passing tests" = "the boards will talk."
S1 proved they'd *agree if bytes arrive intact*. It did **not** prove bytes arrive intact.
(The analogy from the batch doc: both people memorized the same dictionary; we haven't
tested the phone line.)

**Bug prevented.** Overconfidence. Labeling wire-level compatibility VERIFIED before a bench
test would hide real risks (bad ground, clock skew, a forgotten `poll()`), which would then
surface as baffling intermittent failures on the car.

---

## Quiz — 20 questions

1. Why does the project use two ESP32s instead of one, and what does that force into
   existence?
2. Name the two "halves" of a protocol and give one link2 file that is genuinely
   *sender-only*.
3. What does "copied verbatim / do not fork" mean for `lib/link2`, and which two files are
   *not* copied to board #2?
4. Which two commands did S1 use to *prove* the copy is identical, and what did each show?
5. A UART gives you one byte at a time. What component turns that stream into whole
   messages, and what are its three states?
6. What is the start byte's value, and why is it deliberately *not* covered by the CRC?
7. What does the length byte contain, and what does the receiver do the instant it sees an
   unsupported value — and why not just buffer and let the CRC catch it?
8. Give the payload field at offset [7–8], its type, and its byte order on the wire.
9. Distinguish payload-relative index from frame-absolute index for the version field.
10. Why is `BadVersion` a *trustworthy* "you're outdated" signal rather than possible
    corruption?
11. The flags byte is `0x4C`. Which three flags are set? Show the bit math.
12. rpm 1500 is `0x05DC`. Write the two wire bytes in order, and say what value a
    big-endian reader would wrongly get.
13. The wire byte for steering is `0xE7`. What signed value is that, and show the
    two's-complement arithmetic.
14. What three byte-spans/fields does the link2 CRC cover, and what does it exclude?
15. State the validation order in `decodeFrame` and explain why the order (not just the
    checks) matters.
16. What is a golden frame, and why does hard-coding the *same* bytes in two repos prevent
    drift?
17. A frame fails its CRC. What does the assembler do next, and how much of the stream is
    lost?
18. Why must `poll()` be called even when no bytes arrive? What bug appears if you only
    update status inside `feedByte`?
19. During a Lost episode, classify these as zeroed / forced / held: `throttlePercent`,
    `failsafe`, `rpm`, `gear`, `lowBattery` — and give the reason for the "held" ones.
20. "40/40 native tests pass" — name two things that proves and two things it does *not*
    prove.

## Answer key

1. Audio is a greedy real-time job; isolating it from the safety-critical control loop on
   a second chip protects both timings. The cost: the two chips must now communicate → a
   protocol (link2) is required.
2. Sender (packs meaning → bytes) and receiver (bytes → meaning). Genuinely sender-only:
   `Link2Sender.hpp` / `Link2Sender.cpp` (scaling + brake-light hysteresis) — correctly
   absent from board #2.
3. Board #2's `lib/link2` is a byte-for-byte copy of board #1's; the control repo owns the
   protocol and all changes happen there first. Not copied: `Link2Sender.{hpp,cpp}` (a
   receiver doesn't send).
4. `diff -r` (showed only `Link2Sender.*` missing — expected) and `md5` checksums (matched
   on all four shared files → byte-identical). Spec doc matched too.
5. `Link2FrameAssembler`. States: `WaitingForStart` → `ReadingLength` → `ReadingBody`.
6. `0xA5`. It's a framing/alignment *marker*, not data; integrity is the CRC's job, and the
   receiver needs a fixed landmark to resync onto after corruption — so it can't itself be
   "protected" the same way.
7. The number of payload bytes (11 in v1). An unsupported value is hard-rejected
   immediately (`FrameInvalid`, resync). Buffering instead would swallow up to 255 bytes
   (~1 s ≈ 18 frames) of good data before the CRC finally failed.
8. rpm, `uint16_t`, **little-endian** (low byte first: `DC 05`).
9. Payload-relative: version is payload byte 0. Frame-absolute: version is frame byte 2
   (after start byte 0 and length byte 1). The code writes `out[2]` = version.
10. Because CRC is checked *before* version. A version byte flipped by noise would change
    the payload and fail the earlier CRC check (reporting `CrcMismatch`). So a `BadVersion`
    result means the frame was well-formed — genuinely a newer sender, not corruption.
11. `0x4C` = `0100 1100` = bit2 (0x04 drsOpen) | bit3 (0x08 armed) | bit6 (0x40
    ersDeploying). 0x04 + 0x08 + 0x40 = 0x4C.
12. Wire order: `DC 05` (low byte `0xDC` first, then high `0x05`). A big-endian reader would
    wrongly compute `0xDC05` = 56,325.
13. −25. `0xE7` = 231 unsigned; top bit set, so as `int8_t`: 231 − 256 = −25.
14. It covers the **length byte** and the **11 payload bytes** (frame bytes [1..12]). It
    **excludes** the start byte (frame byte 0). Result stored at frame byte 13.
15. start → length → CRC → version. Order matters because it defines each rejection's
    meaning: checking CRC before version is what makes `BadVersion` provably "well-formed
    but newer" rather than "maybe corrupted."
16. One exact, hand-verified frame (`A5 0B 01 … CE`) hard-coded in a test that asserts the
    encoder reproduces it exactly. Both repos hard-code the *same* bytes, so any format
    change breaks a test on whichever side changed — drift becomes impossible to ship
    silently.
17. It discards the frame, resets to `WaitingForStart`, and hunts for the next `0xA5`. At
    most one frame is lost (~50 ms); the stream self-heals.
18. If bytes stop (cut wire), `feedByte` is never called — so status would freeze at `Up`
    forever. `poll()` is the clock-driven heartbeat that lets a *silent* link become
    `Lost`. Bug prevented: a frozen "everything's fine" after the link actually died.
19. throttlePercent → **zeroed** (stale command mustn't drive); failsafe → **forced true**;
    rpm → **zeroed** (stale motion mustn't animate sound/lights); gear → **held** (avoids
    phantom shift-blip sounds; changes slowly); lowBattery → **held** (a *qualified
    judgment* board #1 already made; blanking would flicker the display).
20. Proves: the decode logic is correct (round-trips, endianness, boundaries) and the
    monitor's state logic is correct (staleness edge, projection, recovery) — on the host.
    Does not prove: the physical GPIO25→GPIO16 wire delivers bytes, the two clocks agree at
    115200, grounds are common, or that `main.cpp` actually feeds `feedByte`/`poll` (all
    bench/S5).

## Things to review before S2

- **C8 (`../control_fw/08_link2_outbound_protocol.md`)** — S2 builds *on top of* the
  effective `VehicleState` that this whole receiver chain produces; be fluent in the frame
  format and the two-failsafe picture.
- **Chapter 07 §3 (`../../07_soundlight_firmware_architecture.md`)** — the *ignition state
  machine* (Off / Cranking / Running). S2 is `EngineSim`; it consumes exactly the
  `armed` / `failsafe` / `throttle` fields the monitor projects. Know how link loss →
  `armed = false` → ignition `Off` → silence.
- **The projection table (concept 18)** — S2's inputs are the *effective* state, already
  sanitized. Don't re-derive staleness in your head while reading S2; trust the monitor.
- **Two's complement + little-endian (concepts 11–12)** — S2 does integer engine math
  (rpm inertia, gear blips); comfort with signed/unsigned and 16-bit values pays off.
- **Glossary terms added by S1** — Link2Monitor, LinkStatus, Effective state / per-field
  staleness projection.

## "Ready for S2?" checklist

- [ ] I can explain why link2 exists and name its two ends (sender/receiver).
- [ ] I can describe how "copied verbatim + diff/md5 check" makes the two boards agree, and
      why that's VERIFIED at source level but not at wire level.
- [ ] I can trace one frame through the assembler (start → length → body → decode) and say
      what each byte is.
- [ ] I can decode `DC 05` → 1500 and `0xE7` → −25 without hesitating (endianness + signed).
- [ ] I can state what the CRC covers, the validation order, and why `BadVersion` is
      trustworthy.
- [ ] I can explain the 500 ms staleness rule, why `poll()` is needed, and why only
      CRC-valid frames refresh it.
- [ ] I can list the three staleness classes (zeroed commands / zeroed motion / held slow
      facts) and justify each.
- [ ] I can distinguish NeverConnected from Lost and say which member variable separates
      them.
- [ ] I can say precisely what 40/40 native tests prove and what still needs the bench.
- [ ] I know that S2 (`EngineSim`) consumes the *effective* `VehicleState` and turns
      `armed`/`throttle` into engine sound — the next link in the chain.

If most boxes are checked, you're ready for S2. If several aren't, re-read the batch doc
sections named in each concept above — they're the shortest path back.

---

*Concept teaching notes for S1 complete. No source modified; written only in
`learning-manual/`. Awaiting approval before S2 ("The virtual engine": `lib/enginesim`).*
