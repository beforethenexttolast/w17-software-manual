# W17 giftee-PC install guide

**Who this is for:** whoever sets up the ground station on the giftee's own Windows PC before
handover — the owner, standing in as "pit crew." **Not for Lola** — her copy of the instructions
is the printed booklet (`learning-manual/14_glovebox_owners_booklet.md`); this guide is the
one-time technical setup behind that booklet's one-cable, one-button promise.

**Status: nothing in this guide has been run on a real Windows machine** (the workspace has no
Windows box and no VM as of this writing; see `w17-parts-to-gift-master-sequence.md` stage 11,
`WINDOWS-VM` gate) — that is true of every step below, whether or not the step carries an inline
tag. This guide is written from the source code and the GCS box guide, not from an observed
install. Where the code is explicit about a behavior (a file path, a flag, a dialog string it
prints), that part is cited as fact, not guessed — but "cited from code" is not "observed on
Windows," so treat it as equally unverified until stage 11's VM pass or stage 13's real dry run.
The inline **`[win-TBD]`** marker is narrower than "touches Windows": it flags the specific places
where **Windows itself, not this guide's cited code, decides the outcome** — driver naming,
SmartScreen wording, firewall prompt count, and the like — so a step describing a well-documented
Windows UI flow (SmartScreen's "More info" button, a controller showing up in Device Manager)
without an inline tag is not thereby confirmed; it is simply not an open question about *this
app's* behavior.

**§6–§7 are no longer blocked.** The 2026-09-02 grand-review findings that used to stop the RACE
DAY path here are closed in code: MAP-1 (the config double-wrap panic) and MAP-2/SYN-2 (RACE DAY
never starting the radio link) landed at mapper `ebf89fa` (`pkg/client/grpc_client.go:50-65`
`configPayload`, `:200-203`→`selfStartLink` `:268-310`), and the ground-station side landed at
`263e69a` (`main/raceDayOrchestrator.js:76` `STEP_ORDER`, `renderer/setupFlow.js:305-322` OD-6
auto-GRID). **`[win-TBD]`** still stands: none of this has been run on the giftee's own Windows
box — that is exactly what the WS3 Windows-VM validation run (`w17-parts-to-gift-master-sequence.md`
stage 11, `WINDOWS-VM` gate) exists to prove, and it has not happened yet. Read §6's table below as
"closed in code, unproven on Windows," not as "done."

---

## 1. What's in the kit

| Item | What it is | Where it lives |
|---|---|---|
| **The station box** ("GCS box") | One 3D-printed enclosure holding the radio module that talks to the car, a Wi-Fi adapter that hosts the phone's network, and a USB hub tying them together | Plugs into the PC with **one USB cable** — that's the box's whole job (`w17-gcs-box-guide.md` §1, "the one-cable promise") |
| **The controller** | A PlayStation-style DualShock gamepad | Connects to the PC directly — cable vs Bluetooth pairing is `[TBD-at-bench]` (the booklet carries the same open marker); **use the USB cable if in doubt** — it needs no pairing step and cannot drop out |
| **A USB flash drive or download link** with the ground-station installer and the mapper folder | Software | See §2–§3 |
| Optional: a 12 V adapter for the station box | Only needed if the box's own USB power budget comes up short on the bench (`w17-gcs-box-guide.md` §4) | `[bench-TBD]` whether this ships at all |

**One thing NOT in the box:** the box's radio module — branded **ELRS** (ExpressLRS, the same
2.4 GHz radio system the car's onboard receiver uses) — has **no PC driver of its own**; Windows
only ever sees the serial adapter inside the box (an "FTDI" chip, which shows up as a numbered
**COM port**, e.g. `COM5`). If Windows ever asks you to find a driver for "the ELRS module," you
are looking at the wrong device — the serial adapter is the one that needs recognizing
(`w17-gcs-box-guide.md` §5 table).

---

## 2. Plug in the station box first

1. Plug the station box's single USB cable into a **blue (USB 3.x) port** on the PC, not a black
   USB 2.0 port. The box's own power budget is thin on paper (`w17-gcs-box-guide.md` §4: roughly
   775–810 mA worst-case against a 900 mA USB 3.x port's budget, versus only 500 mA on USB 2.0) —
   a USB 2.0 port may brown out the radio module under load. **That 775–810 mA figure was computed
   with the RT5370 as the hotspot's ≤160 mA contributor** (`w17-gcs-box-guide.md` §4); the
   2026-08-17 addendum demotes the RT5370 to spare/2.4 GHz fallback and adds a dual-band adapter as
   the primary hotspot host instead, whose own draw is not yet folded into this total — so treat
   775–810 mA as **pre-addendum** and `[bench-TBD]` regardless. Until a real number exists, always
   prefer USB 3.x.
2. Windows should recognize two devices inside the box on its own: the serial adapter (shows up
   as a COM port) and the Wi-Fi adapter that will host the phone's hotspot. **If this happens
   instead — Windows asks to search online for a driver or shows a yellow warning icon in Device
   Manager:** note which device it is (serial adapter or Wi-Fi adapter) and try Windows Update
   before anything else; both device classes are expected to have in-box or Windows-Update
   drivers on 10/11, but this is unverified on a real machine (`w17-gcs-box-guide.md` §5,
   `[win-TBD]`).
3. **Write down the COM port number Windows assigns** (Device Manager → Ports (COM & LPT)). You
   will need it in §5.

---

## 3. Install the ground station

The ground station ships as an **unsigned installer** (`.exe`, built automatically by **CI** — the
project's automated build pipeline that runs on every code change,
`w17-ground-station/.github/workflows/ci.yml` — using **`electron-builder --win nsis`**, the tool
that packages the app into a standard Windows installer). "Unsigned" means it has no
Microsoft-recognized publisher certificate — expected for a one-off gift build, not a sign of a
corrupted file, but Windows will warn about it. This is standard Windows behavior for any unsigned
installer, not something specific to this app.

1. Run the installer. Windows SmartScreen will most likely show a blue screen: **"Windows
   protected your PC" / "Microsoft Defender SmartScreen prevented an unrecognized app from
   starting."**
2. Click **"More info"** — a line appears naming the file and a "Run anyway" button.
3. Click **"Run anyway."** The installer proceeds normally from there.
4. **If this happens instead — no "More info" link appears, only a red-shielded "Don't run"
   button:** this usually means the organization's Windows edition/policy blocks unsigned apps
   entirely; a personal/home PC should not hit this. `[win-TBD]` — not observed.

**Before you run the installer, know this:** the CI-built installer as of this writing does **not**
contain the video-relay program (`mediamtx.exe`) it needs for the camera feed to work
(`boundaries-1` in the 2026-09-02 grand review — `w17-ground-station/.github/workflows/ci.yml:53`
never runs the fetch step). **Confirm `CURRENT_STATUS.md` records `boundaries-1` closed before
you install a "final" kit build**, or the giftee will get a working car with no picture. This is
a `[fix-wave: boundaries-1]` item — track it, don't work around it.

---

## 4. First launch

1. Open the ground station from the Start menu.
2. Windows Firewall will likely prompt once or more, asking whether to allow the app on private
   networks (it needs to talk to the car's radio module and host the phone's Wi-Fi network).
   **Choose "Allow access" / check "Private networks."** The exact number and wording of these
   prompts is `[win-TBD]` — the review's structural read is "several," not a confirmed count.
3. The app opens to a screen called **GARAGE** — this is always the first screen on a fresh
   install or a relaunch (`w17-ground-station/README.md:89`; this specific fact is current, but
   the 2026-09-02 review found other parts of that same README stale on the setup flow's step
   count and the start-lights default — a GS docs branch is fixing it, so treat any *other* README
   claim this guide doesn't independently cite with the same caution).
4. **If this happens instead — the window never appears, or the app seems to hang:** check Task
   Manager for a process still running with no window (a known defect, `SYN-1` /
   `correctness-1`/`lifecycle-concurrency-1` in the 2026-09-02 review — cancelling an earlier
   quit prompt after the window closed can leave a windowless "zombie" process). End the process
   and relaunch. **This is a `[fix-wave: SYN-1]` item** — confirm it is closed in
   `CURRENT_STATUS.md` before relying on a clean relaunch every time.

---

## 5. One-time setup (do this once, before handover — not something Lola ever touches)

### 5.1 Network — first-time hotspot configuration

1. From GARAGE, open the setup flow's network step (**PIT WALL**). Choose the **hotspot** option
   (the ground station hosts a Wi-Fi network for the phone, rather than joining an existing one).
2. Set the hotspot name and password — these become the values printed in the handover checklist
   / booklet blanks. The default network name in the code is **`W17-GRID`**
   (`w17-ground-station/shared/settings.js` `DEFAULT_SETTINGS.network.hotspot.ssid`); change it
   here if you want something else, then write down whatever you actually set.
3. The app tries Windows's modern **Mobile Hotspot** feature first, falling back to the older
   `netsh wlan hostednetwork` method if that's unavailable (`w17-ground-station/main/hotspot.js`
   header comment — the file has no adapter- or band-selection logic of its own; this step is
   entirely Windows's own settings, not something the app configures for you). **Pin the hotspot
   to the 5 GHz band, hosted from the station box's own dual-band adapter** — not the PC's
   built-in Wi-Fi (`w17-gcs-box-guide.md` Addendum 2026-08-17, owner decision): the box carries a
   dual-band adapter whose driver can **host** a 5 GHz Mobile Hotspot, and the car's camera radio
   (an RTL8812EU) **joins that hotspot as a client** to send its video back — one network serving
   both the phone bridge and the camera feed. The older RT5370 dongle is now spare / a 2.4 GHz
   fallback only, not the primary hotspot host. **If this happens instead — Windows's Mobile
   Hotspot settings don't offer a way to pick which adapter hosts it, or only show one band:**
   this is a real open question, not yet observed on real hardware (`[win-TBD]`) — if Windows
   insists on using the PC's built-in Wi-Fi instead of the box's adapter, or won't offer 5 GHz,
   stop and report rather than guessing at Windows's per-adapter hotspot UI.
4. **If this happens instead — the hotspot won't start, or Windows says no network profile
   exists to tether from:** this is a documented Windows quirk with the modern Mobile Hotspot API
   (it wants an active internet-connected profile to tether from) — connect the PC to any Wi-Fi
   or Ethernet network first, then retry. `[win-TBD]`, not bench-observed.

### 5.2 Controller

1. Plug the DualShock controller in via USB (or pair it, once the pairing method is bench-
   confirmed — see the kit-contents note in §1).
2. From GARAGE, continue to **SEAT FIT** — the app detects the pad automatically and shows a
   live button-mapping preview (`w17-ground-station/README.md:127-129`; current as far as this
   specific claim goes, same README-staleness caveat as §4 step 3 above).

### 5.3 The drive program and its saved profile (RACE DAY setup — a pit-crew step)

This is the step that makes the single **RACE DAY** button do its job — normally invisible to
Lola, done once here.

1. Copy the mapper program (`elrs-joystick-control.exe`) and its `configs\w17-ds4.json` profile
   onto the PC — **`%LOCALAPPDATA%\W17\mapper\`** is the recommended location, not a folder under
   the ground station's own install directory. Reason: the ground station ships as a default
   one-click NSIS installer (no `oneClick`/`perMachine` override in
   `w17-ground-station/electron-builder.yml`), and that installer type removes the entire previous
   install directory (`RMDir /r $INSTDIR`) before laying down an update — §8 of this guide already
   has you reinstall when the kit build changes, and a mapper/profile folder living inside that
   directory would be silently deleted along with it. `%LOCALAPPDATA%\W17\mapper\` survives a
   reinstall because it's outside `$INSTDIR` entirely. There is no other required location — only
   the two settings fields below must point at wherever you actually put the files.
2. Open the ⚙ settings panel in the ground station and find the **RACE DAY** section. Fill in:
   - **drive program** — the full, **absolute** path to `elrs-joystick-control.exe`
     (`w17-ground-station/renderer/index.html` field id `setMapperPath`)
   - **saved profile** — the full, **absolute** path to `w17-ds4.json`
     (field id `setProfilePath`)
   A relative path in either field is refused outright — RACE DAY only accepts an absolute path in
   either Windows (`C:\...`) or POSIX form (`w17-ground-station/main/raceDayOrchestrator.js:60-69`)
   — so always paste the full path, never a shortcut-relative one. The two fields are **not**
   all-or-nothing: each is checked **independently** — a wrong-typed saved value is reset to empty
   on load, while a well-formed but wrong path is left exactly as typed and only fails at race-day
   start with a plain message (`w17-ground-station/shared/racePrep.mjs:35-44`) — so a bad value in
   one field never wipes the other; check both after saving.
3. **Before that profile will do anything, two placeholders inside it must be filled with values
   from THIS PC** (`w17-mapper/configs/README.md`): `REPLACE-WITH-DS4-ID` (a fingerprint of the
   controller, different on this PC than on the owner's bench, and different again if the pad is
   later used over Bluetooth instead of USB) and `REPLACE-WITH-COM-PORT` (the COM port you wrote
   down in §2). **Two ways to read them, both with the pad plugged in.** Prefer running
   `elrs-joystick-control -list-devices` from a terminal (Command Prompt or PowerShell, from
   wherever you put the program in step 1): it prints one JSON document — the gamepad's
   `id`/`name`/`guid`/`bus`, plus the machine's `serial_ports` — and exits, opening no serial
   port, binding no network port, and starting no server at all
   (`w17-mapper/cmd/elrs-joystick-control/main.go:114-131`,
   `w17-mapper/configs/README.md:57-84`); this avoids step 5's exposure below entirely. The other
   way still works too — briefly open the mapper's own web page at `http://localhost:3000` while
   it is running with the pad plugged in, and read the id off its gamepad list — but that is the
   path step 5 warns about. Either way this is a build-time/pit-crew step, never something the
   giftee sees or needs to do. Edit both placeholders in `w17-ds4.json` with a plain text editor,
   save, and leave the mapper closed afterward.
4. **Until both placeholders are filled, the profile fails safe, not silently dangerous** — every
   channel sits at its disarmed default and the car simply never arms
   (`w17-mapper/configs/README.md`: "the profile is fail-safe until both are set"). That said,
   nothing today warns you if you forget one (`[fix-wave: MAP-5]`) — double-check both values
   yourself.
5. **The mapper's gRPC (`:10000`) and Web-UI (`:3000`) ports bind to this PC only by default, not
   the network** — `DefaultBindHost` is `127.0.0.1` for both listeners, an owner decision made for
   exactly this product (`w17-mapper/pkg/server/controller.go:22-37`, owner decision OD-8(a);
   `w17-mapper/pkg/http/controller.go:35-37`). Opening the mapper's web page for step 3 does not,
   by itself, make it reachable from anything else on the giftee's home Wi-Fi or the car's own
   hotspot. That loopback default only opens up if someone explicitly passes `-bind-all`
   (`w17-mapper/cmd/elrs-joystick-control/main.go:84-91`, `:136-143`) — neither this guide nor RACE DAY
   ever does that: the ground station's mapper launcher only ever passes `-config-file-path`, with
   no way to append `-bind-all` or any other flag
   (`w17-ground-station/main/raceDayOrchestrator.js:44`). The one thing still reachable while the
   web page is open is a browser on this **same** PC, and the mapper's CORS rule now limits that to
   its own origin (`w17-mapper/pkg/http/controller.go:102`), so another tab or page open on this
   machine can't read its responses either. `-list-devices` still opens no network listener at
   all, which is why step 3 prefers it; if you do use the web page, close the mapper afterward
   rather than leaving it running unattended.
6. **The firewall rule below is defence-in-depth, not the fix for an open exposure — the mapper
   already refuses connections from the network by default (step 5).** It is still worth setting
   up once, during this setup, so that a future run is never accidentally reachable from the
   network even if someone later passes `-bind-all` by mistake:
   - Open **Windows Defender Firewall with Advanced Security** (search for it from the Start
     menu) → **Inbound Rules** → **New Rule…**
   - Rule type: **Custom**. Program: browse to `elrs-joystick-control.exe` (wherever you put it
     in step 1). Protocol: **TCP**, Local ports: **3000, 10000** (the mapper's web page and its
     control channel). Scope: leave remote addresses as **Any**. Action: **Block the connection**.
     Apply to whichever network profile the hotspot uses (Private is the common case).
   - This blocks connections arriving over the network to those two ports — redundant with the
     loopback default unless `-bind-all` is ever used — but does **not** block the ground station
     or your own browser talking to the mapper on **this same PC** (`localhost`/`127.0.0.1`
     traffic never leaves the machine, so it isn't affected by this rule) — RACE DAY and the
     mapper's web page (whether from step 3 or opened fresh here) keep working exactly as before.
   - `[win-TBD]` — this rule is not yet bench-verified on a real Windows box; confirm both halves
     after setting it up: the mapper's own web page still opens from this PC, and (if you have a
     second device on the same network to test with) it no longer opens from that second device.

---

## 6. RACE DAY — what it does today, closed in code, unproven on Windows

**Read this before you demonstrate RACE DAY to anyone.** The one-action promise — press RACE DAY,
the hotspot comes up, the drive program starts with the saved profile, the phone link switches on
— was blocked by 2026-09-02 grand-review findings. Those are now closed in code:

| Finding | What used to happen | Fix-wave id | Closed at |
|---|---|---|---|
| The mapper panics on its own committed profile | `elrs-joystick-control.exe` crashed on startup with the exact `w17-ds4.json` this guide has you install, before it ever reached the controller | `MAP-1` | mapper `ebf89fa`, `pkg/client/grpc_client.go:50-65` (`configPayload` unwraps before the server re-wraps) |
| RACE DAY never started the radio link | Pressing RACE DAY brought up the hotspot and started the drive program, but the program never opened the COM port to the car — no control signal ever left the PC | `MAP-2` / `SYN-2` | mapper `ebf89fa`, `pkg/client/grpc_client.go:200-203` → `selfStartLink` `:268-310`; ground station `263e69a`, `main/raceDayOrchestrator.js:76` (`STEP_ORDER` includes `mapper`) |
| The booklet's "one press" does not match the app | The app needed RACE DAY, then a separate "straight to the grid" press, then START | owner decision OD-6 | ground station `263e69a`, `renderer/setupFlow.js:305-322` — a bring-up that reports a positive link claim auto-advances to GRID and arms the last press; a failed bring-up still leaves the operator at the card |

**`[win-TBD]`** — none of the above has run on the giftee's own Windows box. The code path is
closed and native/unit-tested at both trunks; the WS3 Windows-VM run
(`w17-parts-to-gift-master-sequence.md` stage 11, `WINDOWS-VM` gate) is the only thing that turns
"closed in code" into "works on her PC," and it has not happened yet. **Do not demonstrate RACE DAY
as proven until `CURRENT_STATUS.md` records a WS3 pass.**

The current sequence is:

1. Press **RACE DAY** on the GARAGE screen.
2. The card shows four steps in order — hotspot, mapper (drive program + radio link), telemetry,
   phone bridge — each turning green as it completes
   (`w17-ground-station/main/raceDayOrchestrator.js:76` `STEP_ORDER`; owner decision OD-4 puts
   `telemetry` after `mapper` because it reads that program's own stream).
3. If any step fails, the ones already up **stay up** — nothing is wound back — and the failed
   step shows a plain-language reason (the same module's header comment). Pressing RACE DAY again
   is always safe; it re-runs **idempotently** — pressing it five times in a row lands in the same
   state as pressing it once, never five copies of anything running on top of each other.
4. A bring-up is only walked straight through to GRID-and-armed when the mapper step reports a
   positive link claim (`kind === 'running'`, `renderer/setupFlow.js:320`); a first bring-up
   whose 5 s link window (`LINK_UP_WAIT_MS`, `main/raceDayOrchestrator.js:97`, itself `[bench-TBD]`)
   closes before the radio answers reports `link-not-yet` and still reaches GRID, but does not
   auto-fire the last press.

---

## 7. The phone (optional, "an extra")

The phone HUD is a nice-to-have, never the primary display (the laptop screen is). Per the
2026-09-02 owner decision, it ships as a **free Apple-account sideload**, which means:

- The app must be **re-signed from the owner's Mac roughly every 7 days**, or it stops opening on
  the phone.
- This is a real, recurring pit-crew task, not a one-time install — put a standing reminder on
  the owner's calendar and record the last re-sign date in the handover checklist.
- The install procedure itself lives in `iPhone_rc/docs/GIFTEE_INSTALL.md`, which is **being
  written as a sibling readiness task** — reference that path once it lands; nothing here repeats
  or guesses its content.
- Today, nothing in the ground station can tell you whether the phone app has expired
  (`giftee-ux-10` in the grand review, `w17-ground-station/shared/raceDayView.mjs:82`) — if the
  phone HUD suddenly stops connecting, check the re-sign date before assuming a network problem.

---

## 8. Quick reference — "if this happens"

| Symptom | Likely cause | What to do |
|---|---|---|
| SmartScreen blocks the installer | Unsigned `.exe`, expected | More info → Run anyway (§3) |
| App window never opens / process lingers with no window | Cancelled a quit prompt after the window closed (`SYN-1`) | End the process in Task Manager, relaunch; confirm `SYN-1` closed |
| No video / black cockpit view | Installer built before `boundaries-1` was fixed | Check `CURRENT_STATUS.md`; rebuild/reinstall from a fixed CI run |
| Mapper crashes on launch | `MAP-1` (config double-wrap) was the cause; closed in code at mapper `ebf89fa` (`pkg/client/grpc_client.go:50-65`) | `[win-TBD]` — if it still happens on this PC, it is a new defect, not `MAP-1`; report it rather than re-checking §5.3 |
| RACE DAY says "running" but the car never responds | `MAP-2`/`SYN-2` used to leave the radio link never started; closed in code at mapper `ebf89fa` (`selfStartLink`, `grpc_client.go:268-310`) and GS `263e69a` | `[win-TBD]` — the mapper step only claims `running` on a positive link answer (`main/raceDayOrchestrator.js:102` `LINK_BEARING_KINDS`); if it still happens on this PC, check the profile's `tx.port` against the actual COM port before assuming new software |
| Car never arms, no error shown | An unfilled `REPLACE-WITH-*` placeholder (§5.3 step 3/4) | Re-check both placeholders in `w17-ds4.json` |
| Hotspot won't start | Windows Mobile Hotspot needs an active internet-connected profile first (`[win-TBD]`) | Connect to any network first, then retry |
| Settings seem to have silently reset | `correctness-2` — an unreadable `settings.json` resets to defaults and can overwrite its own backup | Confirm `correctness-2` closed before this kit is considered final |
| Worried the mapper's controls are reachable from the network while it's open | They aren't, by default — `MAP-8`'s loopback-only bind closed that (§5.3 step 5) | Prefer `-list-devices` (§5.3 step 3) over the web page; the §5.3 step 6 firewall rule is defence-in-depth only, needed if `-bind-all` is ever used |
| Phone HUD stopped connecting | The 7-day sideload signature may have expired (§7) | Check the re-sign date before troubleshooting the network |

---

## Cross-references

- `w17-parts-to-gift-master-sequence.md` — stage 10 (code blockers), stage 11 (ground side),
  stage 13 (this guide), stage 14 (phone).
- `w17-gcs-box-guide.md` §5 — the driver story this guide's §2 is built from.
- `w17-mapper/configs/README.md` — the profile and its placeholders (§5.3).
- `w17-ground-station/README.md`, `main/raceDayOrchestrator.js`, `main/hotspot.js`,
  `shared/settings.js` — the code this guide describes (read-only; this program does not edit
  `w17-ground-station`).
- `w17-handover-checklist.md` — the day-of checklist this guide feeds into.
- `iPhone_rc/docs/GIFTEE_INSTALL.md` (being written) — the phone install procedure proper.
