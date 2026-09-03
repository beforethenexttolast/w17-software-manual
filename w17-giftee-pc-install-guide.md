# W17 giftee-PC install guide

**Who this is for:** whoever sets up the ground station on the giftee's own Windows PC before
handover — the owner, standing in as "pit crew." **Not for Lola** — her copy of the instructions
is the printed booklet (`learning-manual/14_glovebox_owners_booklet.md`); this guide is the
one-time technical setup behind that booklet's one-cable, one-button promise.

**Status: every step below that touches a real Windows machine is `[win-TBD]`** — none of this
has been run on Windows yet (the workspace has no Windows box and no VM as of this writing; see
`w17-parts-to-gift-master-sequence.md` stage 11, `WINDOWS-VM` gate). This guide is written from
the source code and the GCS box guide, not from an observed install. Where the code is explicit
about a behavior (a file path, a flag, a dialog string it prints), that part is cited, not
guessed; where Windows itself decides the behavior (driver install, SmartScreen wording, firewall
prompt count), it is marked `[win-TBD]`.

**Do not run this guide's final stages (§6–§7) yet.** Six 2026-09-02 grand-review findings mean
the RACE DAY button does not work end to end today for reasons that have nothing to do with
hardware readiness — see the callout in §6. Everything up through §5 (unpacking, installing,
first launch, pairing the controller) is safe to do any time; treat §6–§7 as blocked until
`CURRENT_STATUS.md` records those findings closed.

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
   a USB 2.0 port may brown out the radio module under load. `[bench-TBD]` confirms the real
   number; until then, always prefer USB 3.x.
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

The ground station ships as an **unsigned installer** (`.exe`, built by
`w17-ground-station/.github/workflows/ci.yml`, `electron-builder --win nsis`). "Unsigned" means it
has no Microsoft-recognized publisher certificate — expected for a one-off gift build, not a sign
of a corrupted file, but Windows will warn about it. This is standard Windows behavior for any
unsigned installer, not something specific to this app.

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
   install or a relaunch (`w17-ground-station/README.md`).
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
   header comment) — the fallback sometimes needs you to approve an administrator prompt. **Pin
   the hotspot to the 5 GHz band if your adapter (and the box's 5.8 GHz-capable adapter) supports
   it** (`w17-gcs-box-guide.md` addendum, 2026-08-17) — this keeps the hotspot's radio out of the
   way of the car's own 5.8 GHz camera link, which the PC also has to join at the same time.
4. **If this happens instead — the hotspot won't start, or Windows says no network profile
   exists to tether from:** this is a documented Windows quirk with the modern Mobile Hotspot API
   (it wants an active internet-connected profile to tether from) — connect the PC to any Wi-Fi
   or Ethernet network first, then retry. `[win-TBD]`, not bench-observed.

### 5.2 Controller

1. Plug the DualShock controller in via USB (or pair it, once the pairing method is bench-
   confirmed — see the kit-contents note in §1).
2. From GARAGE, continue to **SEAT FIT** — the app detects the pad automatically and shows a
   live button-mapping preview (`w17-ground-station/README.md`).

### 5.3 The drive program and its saved profile (RACE DAY setup — a pit-crew step)

This is the step that makes the single **RACE DAY** button do its job — normally invisible to
Lola, done once here.

1. Copy the mapper program (`elrs-joystick-control.exe`) and its `configs\w17-ds4.json` profile
   onto the PC — a folder under the ground station's own install directory is a reasonable choice
   if you have no other preference; there is no required location, only two settings fields that
   must point at wherever you put them (next step).
2. Open the ⚙ settings panel in the ground station and find the **RACE DAY** section. Fill in:
   - **drive program** — the full path to `elrs-joystick-control.exe`
     (`w17-ground-station/renderer/index.html` field id `setMapperPath`)
   - **saved profile** — the full path to `w17-ds4.json`
     (field id `setProfilePath`)
   Both are saved together as one settings block; a garbage value in either repairs to empty, not
   a partial mix (`w17-ground-station/shared/racePrep.mjs`).
3. **Before that profile will do anything, two placeholders inside it must be filled with values
   from THIS PC** (`w17-mapper/configs/README.md`): `REPLACE-WITH-DS4-ID` (a fingerprint of the
   controller, different on this PC than on the owner's bench, and different again if the pad is
   later used over Bluetooth instead of USB) and `REPLACE-WITH-COM-PORT` (the COM port you wrote
   down in §2). **Today, the only way to read the controller's id is to briefly open the mapper's
   own web page** at `http://localhost:3000` while it is running with the pad plugged in, and
   read the id off its gamepad list — a build-time/pit-crew step, never something the giftee sees
   or needs to do. (A simpler picker is planned but does not exist yet — tracked as
   `[fix-wave: MAP-9]`.) Edit both placeholders in `w17-ds4.json` with a plain text editor, save,
   and leave the mapper closed afterward.
4. **Until both placeholders are filled, the profile fails safe, not silently dangerous** — every
   channel sits at its disarmed default and the car simply never arms (`w17-mapper/configs/
   README.md`: "the profile is fail-safe until both are set"). That said, nothing today warns you
   if you forget one (`[fix-wave: MAP-5]`) — double-check both values yourself.
5. **While the mapper is running for this step, both the web page you just opened and its
   underlying control channel are reachable from every device on the same network, not just
   this PC** — neither is limited to this machine, and neither checks who is asking
   (`w17-mapper/pkg/server/controller.go:81`, `w17-mapper/pkg/http/controller.go:102`;
   `[fix-wave: MAP-8]`). On the giftee's home Wi-Fi or the car's own hotspot this means anything
   else already on that network could, in principle, start or stop the radio link the same way
   this guide has the pit crew do from the browser. Keep this step to a private/trusted network
   and close the mapper afterward; do not leave it running unattended.

---

## 6. RACE DAY — what it does today, and what still doesn't work

**Read this before you demonstrate RACE DAY to anyone.** The one-action promise — press RACE DAY,
the hotspot comes up, the drive program starts with the saved profile, the phone link switches on
— is the design intent, but the 2026-09-02 grand review found it is not fully wired yet:

| Finding | What happens today | Fix-wave id |
|---|---|---|
| The mapper panics on its own committed profile | `elrs-joystick-control.exe` crashes on startup with the exact `w17-ds4.json` this guide has you install, before it ever reaches the controller | `MAP-1` |
| RACE DAY never starts the radio link | Even once MAP-1 is fixed, pressing RACE DAY brings up the hotspot and starts the drive program, but the program never opens the COM port to the car — no control signal ever leaves the PC | `MAP-2` / `SYN-2` |
| The booklet's "one press" does not match the app | The booklet (as of this writing) says one press brings up the cockpit view and checks the camera/controller/radio; the app needs RACE DAY, then a separate "straight to the grid" press, then START — and RACE DAY's checks don't cover camera/controller/radio at all | `giftee-ux-3` (owner-gated wording choice, not yet resolved) |

**None of this is a hardware problem, and none of it means A2 or Phase B is unfinished** — it is
pure ground-station/mapper software that a separate fix wave (readiness WS-1) is closing. This
guide names the findings so nobody demonstrates RACE DAY to the owner or to Lola and reports it
broken as if it were new. **Check `CURRENT_STATUS.md` for each id's status before relying on RACE
DAY at all.**

Once those land, the expected sequence is:

1. Press **RACE DAY** on the GARAGE screen.
2. The card shows three steps in order — hotspot, drive program, phone link — each turning green
   as it completes (`w17-ground-station/main/raceDayOrchestrator.js` `STEP_ORDER`).
3. If any step fails, the ones already up **stay up** — nothing is wound back — and the failed
   step shows a plain-language reason (the same module's header comment). Pressing RACE DAY again
   is always safe; it re-runs idempotently rather than starting a second copy of anything.

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
| Mapper crashes on launch | `MAP-1` (config double-wrap) not yet fixed | Do not proceed past §5.3 until `CURRENT_STATUS.md` shows it closed |
| RACE DAY says "running" but the car never responds | `MAP-2`/`SYN-2` — the radio link never actually starts | Confirm fix-wave status; this is not a wiring or COM-port mistake |
| Car never arms, no error shown | An unfilled `REPLACE-WITH-*` placeholder (§5.3 step 3/4) | Re-check both placeholders in `w17-ds4.json` |
| Hotspot won't start | Windows Mobile Hotspot needs an active internet-connected profile first (`[win-TBD]`) | Connect to any network first, then retry |
| Settings seem to have silently reset | `correctness-2` — an unreadable `settings.json` resets to defaults and can overwrite its own backup | Confirm `correctness-2` closed before this kit is considered final |
| Someone else on the network could reach the mapper's controls while it's open | `MAP-8` — the mapper's network ports aren't limited to this PC and have no login (§5.3 step 5) | Only run §5.3 on a trusted network; confirm `MAP-8` closed before this kit is considered final |
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
