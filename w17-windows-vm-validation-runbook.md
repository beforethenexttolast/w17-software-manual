# W17 Windows-VM validation runbook

Owner decision A4 (`2026-09-02_readiness_program.md:21`): real-Windows validation for
`w17-ground-station` and the mapper it drives happens in a **VMware Fusion VM on the
owner's Apple Silicon Mac**, with USB passthrough. Claude drives the checks
**autonomously** once the VM exists; a real Windows PC is the final proof only at
handover. This document is the one-time owner setup plus the autonomous-drive design; the
scripts it drives live in `w17-ground-station/scripts/windows-validation/` (see that
directory's own `README.md` for what each script does and its non-automatable steps).

## 0. Standing rules for everything below

**What A4 itself says, and what this document adds.** A4's own words about hardware are
only *"the owner connects the adapters"*. The specific device list below (an AP-capable
5 GHz USB Wi-Fi adapter, the ELRS TX over USB serial, the DualShock 4) comes from the B4
brief and from what the scripts need — it is **not** quoted from A4, and this document
should not be read as if A4 had specified a chipset.

> **⚠ One device on that list has not been bought yet — it gates part of this program**
>
> `CURRENT_STATUS.md:72` lists the **5 GHz AP-capable adapter** under **"Owner residue:
> shopping only"**. The adapter `HARDWARE_INVENTORY.md:183` records as **on hand** is an
> **RT5370**, which is 2.4 GHz, and its row says AP-mode support on Win 10/11 is *"still
> to verify on the bench"*.
>
> Consequences, so the sequencing is explicit rather than discovered late:
> - §1.8's passthrough step and §1.9's ARM64-driver `[win-TBD]` both presuppose a device
>   that does not exist yet. §1.9 is therefore **doubly open**: unknown chipset AND
>   unknown driver, for an unbought part.
> - `30-hotspot.ps1` and the hotspot-interface half of `40-mdns-udp.ps1` cannot pass until
>   the purchase is made and an ARM64 driver is confirmed. Until then `30` reports its
>   clean "no usable hotspot backend" FAIL — that is the script working, not a defect.
> - `00-inventory.ps1` will honestly report `likely5GHzCapable = false` against an RT5370.
> - **Everything else in the suite (`00`, `10`, `20`, `50`, `60`) is unaffected** and can
>   run as soon as the VM exists. Do not hold the whole program for this one purchase.
>
> Whether the RT5370 can serve as an interim 2.4 GHz-only hotspot backend is `[win-TBD]`:
> its own inventory row leaves AP mode unverified, and this session could not test it.

**Nothing in this document or the scripts it drives flashes, uploads, or powers hardware,
or opens a serial port for control** (workspace `CLAUDE.md` safety rules). One boundary of
that claim is worth stating up front rather than in a footnote: §3's step 7 tracks a mapper
the **operator** started by hand, and such a mapper has its COM port open and is
transmitting. That is outside the claim, which is about the scripts — see **§3.1** before
running it, and run it only with the **car unpowered or its RX unbound**.

**A2 stays NOT-EXECUTED and Phase B stays BLOCKED** regardless of anything this VM proves
— a VM validates the *Windows-side software*, not the RC car's hardware gates. So does
**R15**, and every other FIRST_ACTIVE unlock item: nothing in this suite discharges any of
them (`CURRENT_STATUS.md:1375`, "R15 remains NO-GO"; see §3.1 and §4).

Every value in this document that this session could not itself execute and observe is
marked `[win-TBD]`. None are invented.

---

## 1. One-time owner setup

This section is written for **the owner to do by hand**, once. Nothing in it is something
an unattended Claude Code session should attempt (VM creation, OS installation, and
license acceptance are all owner-facing GUI/account actions).

### 1.1 VMware Fusion

- Fusion is free for personal use as of the Broadcom acquisition, gated behind a **Broadcom
  account** (free to create) rather than a purchased license key. Sign in with a Broadcom
  account inside Fusion's own activation flow the first time it's opened.
- Download the Apple Silicon (arm64) build of Fusion — there is no x86 build relevant here
  since the host is Apple Silicon.
- `[win-TBD]`: the exact current download URL and account-linking flow are a Broadcom
  Support Portal detail that changes independent of this project; this session did not
  walk it live. If the flow presented differs from "sign in, download, launch," that is
  expected — follow whatever Broadcom's own portal shows rather than this document.

### 1.2 Windows 11 ARM64 ISO

- Apple Silicon Fusion virtualizes **arm64**, not x64 — so the guest OS must be **Windows
  11 on Arm**, not the ordinary x64 retail ISO most people download.
- **Check Microsoft's ordinary "Download Windows 11" page FIRST.** An earlier draft of
  this document asserted that page serves only x64/x86 media and steered the owner
  straight to the Insider path; that assertion was not verified by this session and is
  believed to be out of date — official Windows 11 **Arm64** ISOs have been offered
  through the standard consumer download page since 24H2. `[win-TBD]`: this session could
  not open the page to confirm what it offers today. Look for an Arm64 option there
  before doing anything more elaborate.
- If (and only if) no Arm64 media is offered there, the fallbacks are the **Windows
  Insider Preview ISO downloads** page (enrolling the *download account*, not the
  resulting VM) or a UUP-dump-style extraction from Windows Update — `[win-TBD]` for both;
  this session executed neither. Pick whichever Microsoft-sanctioned path is live; avoid
  third-party ISO mirrors.
- Fusion's own "Easy Install" for Windows on Arm has historically been less reliable than
  for x64 guests — if Easy Install fails or hangs, fall back to a manual ISO boot + attach
  VMware Tools afterward. `[win-TBD]`: not exercised this session.

### 1.3 VM sizing

No number below has been benchmarked against this project's actual workload (Electron +
Go binary + SDL2 + a WebRTC video pipeline that this VM will likely never receive real
video into, since there is no camera passthrough plan here) — `[win-TBD]` for all of them.
Reasonable starting points, revise once `00-inventory.ps1` and a real `npm run build` /
install cycle show it's tight:

- CPU: 4 vCPUs (Electron + Go binary + SDL2 device polling; leave headroom for the host).
- RAM: 8 GB minimum, 12–16 GB comfortable (Electron alone is not light).
- Disk: 80–100 GB (Windows 11 itself wants ~64 GB free after updates; leave room for the
  NSIS installer, a couple of `dist\` builds, and VM snapshots, which are NOT thin by
  default in Fusion once several accumulate).
- Networking: **NAT is enough for SSH-from-Mac + this validation suite.** The Mobile
  Hotspot backend under test (`30-hotspot.ps1`) creates its OWN separate SoftAP interface
  on the guest via the passed-through USB Wi-Fi adapter — it does not need or use the VM's
  own virtual NIC to do that; do not bridge the VM's virtual NIC to the AP-capable adapter,
  that adapter needs to stay a raw USB passthrough device the guest OS drives directly
  (§1.8).

### 1.4 VMware Tools

Install VMware Tools inside the guest once Windows itself is up (Fusion's guest menu:
Virtual Machine → Install VMware Tools). This is what makes `vmrun captureScreen` and
graceful guest shutdown work, and what `00-inventory.ps1`'s
`Get-W17VirtualizationInfo`/`VMTools` service check reports on. `[win-TBD]`: not executed
this session; the inventory script will say plainly if Tools are missing or not running.

### 1.5 Guest OpenSSH Server + key auth

Windows 11 ships an OpenSSH Server as an optional Windows capability:

```powershell
# inside the guest, elevated PowerShell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
# Allow it through Windows Defender Firewall (a fresh Windows install has no rule for it).
# SCOPED deliberately: Private profile only, and only from the Fusion NAT subnet the Mac
# reaches the guest on. An unscoped rule (all profiles, any remote address) is low risk on
# a NAT'd VM, but this guest also brings up its OWN SoftAP interface during 30-hotspot.ps1,
# and that interface is exactly where MAP-8/boundaries-3 already put unauthenticated
# services within reach. Do not widen sshd onto it for free.
# Replace the -RemoteAddress value with your Fusion NAT subnet (`ipconfig` in the guest,
# or Fusion's VM network settings pane); 192.168.x.0/24 below is a placeholder, [win-TBD].
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True `
  -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 `
  -Profile Private -RemoteAddress 192.168.x.0/24
```

Then, from the Mac:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/w17vm_ed25519 -C "w17-vm"
# copy ~/.ssh/w17vm_ed25519.pub into the guest's
#   C:\Users\<user>\.ssh\authorized_keys   (Administrators use
#   C:\ProgramData\ssh\administrators_authorized_keys instead — Windows OpenSSH's
#   documented split; check which applies to the account this session logs in as)
```

`~/.ssh/config` on the Mac:

```
Host w17vm
    HostName <the VM's guest IP — Fusion NAT typically gives it a 192.168.x.x address;
              `ipconfig` inside the guest, or Fusion's own VM network settings pane, has it>
    User <the Windows account name>
    IdentityFile ~/.ssh/w17vm_ed25519
    # a NAT-assigned DHCP address can change across VM restarts — pin a static
    # guest IP (or a Fusion DHCP reservation) once the address is known, or this
    # line needs updating each session; [win-TBD], not exercised this session.
```

Verify with `ssh w17vm 'whoami'` before trusting anything else in this document.

### 1.6 PowerShell 7 in the guest — REQUIRED, and Windows does not ship it

```powershell
# inside the guest
winget install --id Microsoft.PowerShell --source winget
# then open a NEW shell so PATH picks up pwsh, and confirm:
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

This is not a preference and not a "nice to have". **Windows 11 ships only Windows
PowerShell 5.1**, and every script in `scripts/windows-validation/` carries
`#Requires -Version 7.0` because it means it: the shared command runner
(`lib/common.ps1`'s `Invoke-W17Command`) and `50-race-day.ps1` use
`System.Diagnostics.ProcessStartInfo.ArgumentList`, which exists only on .NET Core 2.1+ /
.NET 5+ — **not** on the .NET Framework that 5.1 runs on. Under 5.1 that property access
throws, and every script that shells out dies.

`run-all.ps1` **refuses to fall back** to `powershell.exe`: it resolves `pwsh`, checks its
major version, and otherwise throws one clear message naming the `winget` line above. An
earlier version preferred `pwsh` but silently fell back, which on a fresh guest turned one
solvable setup problem into eight separate .NET stack traces.

Do this **before** the `clean-giftee-pc` snapshot below, so every reverted session already
has PowerShell 7.

`[win-TBD]`: the `winget` invocation itself was not run by this session (no Windows). If
`winget` is unavailable on the guest, the MSI from Microsoft's PowerShell releases is the
documented alternative.

### 1.7 Snapshot `clean-giftee-pc` BEFORE any W17 install

Take a VMware Fusion snapshot named exactly `clean-giftee-pc` **immediately after** Windows
+ VMware Tools + OpenSSH are working, and **before** the first `10-install-gs.ps1` run or
any other W17-related install. This is the revert target every validation session starts
from (§2.1) — it is what makes the whole suite idempotent across VM sessions, not just
within one PowerShell run. Re-snapshot it (same name, or a new dated one — the owner's
call) only when a deliberate change to the "clean" baseline is wanted (e.g., after a
Windows Update the owner wants baked in).

### 1.8 USB passthrough for the three devices

In the VM's Settings → USB & Bluetooth (or the USB menu on a running VM), enable
passthrough for:

1. The AP-capable 5 GHz USB Wi-Fi adapter (Mobile Hotspot backend under test) — **not yet
   purchased; see §0's box before planning around this step**.
2. The ELRS TX handset, connected via USB serial.
3. The DualShock 4 controller (USB — `60-hid-transition.ps1`'s bench target; a Bluetooth
   DS4 pairs to the GUEST's own Bluetooth stack instead of USB passthrough, which needs the
   guest to see a Bluetooth radio at all — `[win-TBD]`, transport for the giftee's own PC
   is still marked TBD-at-bench in the booklet; USB is the sure path for VM testing).

Fusion passes a USB device through to WHICHEVER of host-or-guest currently "owns" it — the
Mac cannot use a passed-through device at the same time the guest has it. `00-inventory.ps1`
(COM ports + DualShock4 HID) and `30-hotspot.ps1` (Wi-Fi adapter capability) are how this
session confirms passthrough actually landed, rather than assuming the menu click worked.

### 1.9 ARM64 caveat (read before troubleshooting anything that "should just work")

The owner's ground-station and mapper builds are **x64** (electron-builder's default
target on this project's CI, and the mapper's release builds — see
`w17-mapper/Dockerfile.windows-amd64`). Running x64 binaries on a Windows-11-on-Arm guest
works through Microsoft's built-in x64 emulation layer, which is functionally transparent
but **not free** — expect slower boot/launch than a native x64 box, and budget for it in
any timeout this session's scripts use (`50-race-day.ps1`'s `-MapperWaitMs`,
`10-install-gs.ps1`'s installer timeout) rather than assuming x64-native speeds.

The bigger open question is the **Wi-Fi adapter driver**: the AP-capable 5 GHz USB
adapter this program needs (a B4-brief requirement, not something A4 itself specifies —
and **still unbought**, §0) needs an **ARM64-native Windows driver** to be usable
inside an ARM64 guest at all (a passed-through USB device still needs a driver matching the
GUEST's CPU architecture — x64 emulation does not cover kernel-mode drivers). Whether an
RTL8812BU/AU-class chipset (the common class of 5 GHz-capable, hosted-network/Mobile
Hotspot–capable USB adapter) ships an ARM64 driver from the vendor is **`[win-TBD]`** — this
session has not identified a chipset or vendor driver availability — and cannot, because
the adapter has not been chosen or bought (`CURRENT_STATUS.md:72`, "Owner residue:
shopping only"). This `[win-TBD]` is therefore doubly open: unknown part, unknown driver. `00-inventory.ps1`'s `netsh wlan show drivers` parse is the first real
evidence either way once the adapter and driver are in hand.

**Fallback, if the ARM64 driver does not exist:** a real x64 Windows PC (or an x64 VM on
x64 hardware, which this Mac is not) becomes the validation target instead of this VM for
the hotspot-specific scripts (`30`, and `40`'s reachability-from-hotspot-subnet checks);
everything else in this suite (`00`, `10`, `20`, `50`, `60`) does not depend on the AP-capable
adapter at all and stays valid on the ARM64 VM regardless.

---

## 2. Autonomous-drive design

Once §1 is done once, every validation session below is meant to run **without** the owner
sitting at the VM console, driven entirely from the Mac's terminal (this is what "Claude
must drive the checks autonomously" means in owner decision A4) — with the sole, explicit
exception of `60-hid-transition.ps1`'s physical unplug/replug, which needs a human hand at
the actual USB cable (and, per §3.1, the car unpowered) (see that script's own docs and
`w17-ground-station/scripts/windows-validation/README.md`'s non-automatable-steps list).

### 2.1 VM lifecycle from the Mac: `vmrun`

`vmrun` ships with Fusion (`/Applications/VMware Fusion.app/Contents/Public/vmrun`; add
that directory to `PATH` or call it by full path). The `-T fusion` flag selects the Fusion
host type.

```sh
VMX=~/Virtual\ Machines.localized/w17-giftee-pc.vmwarevm/w17-giftee-pc.vmx   # path is whatever Fusion actually created — confirm with `vmrun -T fusion list` while it's running once

# start headless (no Fusion window needs to be open)
vmrun -T fusion start "$VMX" nogui

# revert to the pre-install baseline before a validation sweep that installs anything
vmrun -T fusion revertToSnapshot "$VMX" clean-giftee-pc

# a screenshot for anything a human should eyeball (e.g. step 7's unplug window,
# or a Windows Defender Firewall prompt 40-mdns-udp.ps1 can only report on, not click)
vmrun -T fusion captureScreen "$VMX" /tmp/w17vm-screen.png

# clean shutdown when done
vmrun -T fusion stop "$VMX" soft
```

`revertToSnapshot` + `start` is the idempotency boundary ABOVE what each script's own
"safe to re-run" contract gives: every script in `scripts/windows-validation/` is
individually idempotent (lib/common.ps1's own header), but reverting to `clean-giftee-pc`
before a sweep is what makes "did the LAST run leave something behind" not a question that
compounds across sessions — start every validation session that installs software with a
revert unless deliberately testing something that depends on a prior session's install
(e.g., a second `10-install-gs.ps1` run's idempotency itself).

### 2.2 Script execution: `ssh w17vm pwsh -File`

See `w17-ground-station/scripts/windows-validation/README.md` §"Driving them from the Mac over SSH" for the
concrete invocation pattern and how to `scp` results back. In short:

```sh
ssh w17vm 'pwsh -File C:\w17\scripts\windows-validation\run-all.ps1 <params...>'
scp -r w17vm:'C:\w17\scripts\windows-validation\results\<timestamp>' ./evidence/
```

A plain (non-interactive) `ssh host 'command'` works for every script except
`60-hid-transition.ps1`'s default (Read-Host) mode — either use `ssh -t` for that one, or
its own `-NonInteractive` switch paired with a `vmrun captureScreen` (or the owner
physically present) to know when to act. Through `run-all.ps1` the equivalent switches are
`-IncludeHidTransition` and `-HidTransitionNonInteractive`.

`run-all.ps1` will refuse to start if the guest has no PowerShell 7 (§1.6) — that is the
intended behaviour, not a bug; it names the `winget` line in its own error.

### 2.3 Getting the build onto the guest

None of the scripts in this suite build the GS or the mapper — they validate an ALREADY
BUILT artifact. Getting that artifact onto the guest is either:

- **From CI — PREFER THIS.** Download the `w17-ground-station-nsis-unsigned` artifact
  (and, once a W17-mapper release job exists — readiness program Workstream 2 — the mapper
  zip) from the relevant GitHub Actions run, then `scp` it to the guest. CI builds it on
  `windows-latest` (`w17-ground-station/.github/workflows/ci.yml:27`, `:67`), and the ground station's own
  README calls that artifact **"the gift-kit deliverable"** (`w17-ground-station/README.md:71`).
  Validating the artifact the giftee will actually receive is the point of this whole VM.
- **From a local `npm run build` on the Mac — `[win-TBD]`, and probably not usable.** An
  earlier draft of this document stated flatly that this "produces an x64 Windows installer
  under `dist\` … (electron-builder cross-builds)". That was unhedged and unverified, and
  there is a concrete reason to doubt it: `npm run build` is
  `app:rebuild && electron-builder --win`, and `app:rebuild` is
  `electron-rebuild -f -w serialport` — which rebuilds the **native serialport module for
  the HOST** (darwin-arm64), while `w17-ground-station/electron-builder.yml:38-39` asar-**unpacks**
  `node_modules/serialport/**` and `node_modules/@serialport/**` into the Windows package.
  So the installer would carry a native module built for the wrong platform, and the
  serial path is precisely what the mapper/ELRS work depends on. Whether electron-builder
  substitutes a correct prebuilt, fails, or ships the darwin binary was **not** tested by
  this session — hence `[win-TBD]`. **Use the CI artifact.** If a local build is ever
  needed, verify what actually landed inside
  `resources\app.asar.unpacked\node_modules\serialport\` on the guest before trusting it.

```sh
scp dist/W17*Setup*.exe w17vm:'C:\w17\dist\'
scp -r <mapper build dir> w17vm:'C:\w17\mapper\'
```

---

## 3. Run sequence, mapped to scripts

A full sweep, in order (matches `run-all.ps1`'s own sequencing and skip logic — see
`w17-ground-station/scripts/windows-validation/README.md` for each script's full description):

| # | command (via `ssh w17vm`) | what it needs from you | evidence it produces |
|---|---|---|---|
| 0 | `vmrun -T fusion revertToSnapshot "$VMX" clean-giftee-pc && vmrun -T fusion start "$VMX" nogui` | the VMX path | a known-clean starting state |
| 1 | `pwsh -File 00-inventory.ps1` | nothing | host survey JSON — confirm the Wi-Fi adapter, COM port, and DS4 all show up as expected BEFORE spending time on anything else |
| 2 | `pwsh -File 10-install-gs.ps1 -InstallerPath ...` | the installer, scp'd on first (§2.3) | install verified; **expected to FAIL on `boundaries-1`** (mediamtx missing) against a CI-built artifact until that CI defect is fixed |
| 3 | `pwsh -File 20-mapper-stage.ps1 -MapperExe ... -Profile ...` | the mapper binary + profile, scp'd | racePrep staged into settings.json; FAILS if the profile still has `REPLACE-WITH-` placeholders (MAP-5) |
| 4 | `pwsh -File 30-hotspot.ps1 -InstallDir ... -Password ...` | the real hotspot password (never invented) | hotspot start/verify/teardown through the app's own code; clean FAIL if no AP-capable adapter/driver landed (§1.9); **the adapter is not bought yet — see §0** |
| 5 | `pwsh -File 40-mdns-udp.ps1 -InstallDir ...` | nothing new | firewall state, a real mDNS query, a UDP 5601 replay-telemetry receive |
| 6 | `pwsh -File 50-race-day.ps1 -InstallDir ... -UserDataDir ...` | step 3 to have run; **car unpowered** (§3.1's MAP-8 note) | reproduces MAP-1 (mapper panic) if it still bites, plus MAP-8 port-reachability evidence while the mapper is briefly alive. MAP-2/SYN-2 reproduce **every** run and are recorded in `data.expectedFindingsReproduced` rather than the exit code — so a **FAIL here means something NEW**, not the finding we already know about |
| 7 | **⚠ read §3.1 FIRST** — (human present) `pwsh -File 60-hid-transition.ps1 -MapperExe ...` via `ssh -t`, mapper started by hand first | a human at the DS4 cable, **and the car unpowered / RX unbound** | Windows HID-transition + mapper-**process** continuity; MAP-6 code citation. **Not R15 evidence — R15 stays NO-GO** |
| — | `vmrun -T fusion stop "$VMX" soft` | | |

Or, for everything automatable in one call: `run-all.ps1` with whichever parameters are
available (see its own `.DESCRIPTION` — it skips, never fails, a step it lacks parameters
for). Step 7 is opt-in there too: pass `-IncludeHidTransition`.

### 3.1 Step 7 safety precondition — the one place a live TX is involved

Row 7 says *"mapper started by hand first"*, and `60-hid-transition.ps1`'s own header says
it needs a mapper that is **actually running and driving**. A mapper that is driving was
started with `-tx-serial-port-name`, which means **the COM port IS open and CRSF IS being
transmitted** by that operator-started process.

That sits **outside** §4's "no serial port is ever opened by this suite" claim. The claim
is about the SCRIPTS, and it stays true of every one of them — `60` only reads the OS
process table and the HID bus. It was never a claim about a mapper the operator launched
themselves, and this document previously left that distinction implicit.

**Before running step 7:**

1. **The car must be UNPOWERED, or its RX UNBOUND.** Not optional.
2. Treat it as a **bench procedure under FIRST_ACTIVE, which is NO-GO**. It discharges
   nothing and unlocks nothing.
3. It is **not** an R15 test. `R1–R16` is the FIRST_ACTIVE **unlock** checklist
   (`CURRENT_STATUS.md` §2.3.11.6, arbiter code parked on `u4-arbiter`), and R15
   (`CURRENT_STATUS.md:1356`) is *device loss ⇒ **arbiter** disarm*.
   `CURRENT_STATUS.md:1375`: **"R15 remains NO-GO"** — and it stays NO-GO after a green
   run of step 7. The script's own result carries a `data.r15Status` field saying so.

**Why this is not theoretical.** `CURRENT_STATUS.md:1373-1376` records that on gamepad
loss the mapper *"still transmits at full rate … fail-to-neutral, not fail-silent, so the
firmware's radio-loss failsafe still does not fire"*, with switch channels latching
downstream (RESIDUAL A). Pulling the pad on a live transmitter with a powered car is
exactly the situation that residual describes.

**One related note on the MAP-8 window (step 6).** While `50-race-day.ps1` runs, the
mapper's gRPC `:10000` is up, unauthenticated, on all interfaces with reflection on, and
`StartLink` — the one RPC that opens the COM port and transmits — is among the RPCs it
exposes. Nothing in the suite calls it and the ground station has no client that could,
so the suite's no-serial-port claim holds by construction; but run step 6 on the **NAT'd
VM**, with the car unpowered, rather than on a shared network.

---

## 4. Evidence this collects, and what it does NOT settle

**Collects, with citations back to code, every run:**
- Whether the shipped installer actually contains a working video relay (`boundaries-1`).
- Whether a staged profile carries unfilled placeholders (`MAP-5`).
- Whether the app's own hotspot/mDNS/UDP-telemetry code paths work on real Windows
  networking APIs, not just their unit-test fakes.
- Whether race day's mapper step crashes against the REAL committed profile shape
  (`MAP-1`), and — structurally, every run — that the RF link is never started by race day
  regardless (`MAP-2`).
- Whether the mapper's gRPC (`:10000`) and grpc-web (`:3000`) ports are reachable on all
  interfaces while the mapper is briefly alive (`MAP-8`).
- Windows-visible HID continuity across a physical DS4 unplug/replug, and whether the
  mapper PROCESS survives it — evidence toward `MAP-6`. **Not R15.**

**Does NOT and cannot settle** (each already called out at the point it matters, in the
scripts and in `w17-ground-station/scripts/windows-validation/README.md`'s non-automatable-steps list — not
repeated as a gap here, just indexed):
- Whether CRSF frames actually reach the receiver over real RF (no serial port is ever
  opened by this suite, by design).
- Whether control resumes after a DS4 replug (the mapper's own gamepad registry is not
  independently queryable without a control-path probe this suite deliberately does not
  build).
- **R15, or any other FIRST_ACTIVE unlock item.** Nothing in this suite discharges R15;
  it remains NO-GO (`CURRENT_STATUS.md:1375`). Step 7 measures Windows HID transitions and
  mapper-process liveness, which is a different question from arbiter disarm on device
  loss. See §3.1.
- Any hardware fact under Phase B / A2 — this VM is a Windows-software validation target,
  never a stand-in for the bench gates in `CURRENT_STATUS.md`.
- Whether `w17-ground-station/main/hotspotLifecycle.js` (the module race day actually calls) sequences the
  hotspot correctly. `30-hotspot.ps1` drives `w17-ground-station/main/hotspot.js` and
  `w17-ground-station/main/hotspotVerify.js`
  DIRECTLY, and `50-race-day.ps1` stubs the hotspot and bridge steps out — so that
  module's retry/teardown POLICY is exercised by nothing here. `[win-TBD]`; it would need
  a dedicated step or a real race-day run.
- Anything about a REAL x64 giftee PC beyond what an ARM64 VM under x64 emulation can
  stand in for (§1.9) — the giftee's actual PC gets its own pass at handover, by hand.

---

## 5. What a validation session discharges

A session that runs this runbook's §2–§3 sequence and reports its results back into
`CURRENT_STATUS.md` (the workspace's only file for commit hashes / gate status — this
runbook and the scripts it drives do not themselves carry that state) discharges exactly:
Workstream 3 of `2026-09-02_readiness_program.md` ("Windows validation path... Session runs
when the owner installs the VM"). It does NOT discharge A2, Phase B, or **R15 / any
FIRST_ACTIVE unlock item** (restated because these are the rules most likely to be misread
from a green run here) — those stay gated on real hardware and on arbiter code that is
still parked, independent of how clean a VM run looks.

A green sweep also does not mean the hotspot path is proven: until the AP-capable 5 GHz
adapter in §0 is bought and shown to have an ARM64 driver, `30` and `40`'s hotspot half
are SKIPPED-or-cleanly-FAILING, not passing.

### 5.1 One experiment worth running while the VM exists

`boundaries-5` (`w17-ground-station.v2report.json`) is **UNVERIFIED-LOW**, and its own
residual says exactly what would settle it: the JS-side `W17_*` env scrub is case-sensitive
in plain sight (`w17-ground-station/main/mapperRunner.js`), but whether the mapper's Go-side `os.LookupEnv` is
case-insensitive on Windows was reasoned from the platform, never observed. On the guest:

```powershell
setx w17_headtrack_ingest 1     # deliberately lower-case
# open a NEW shell, then re-run step 6
```

If the mapper picks the flag up, `boundaries-5` is confirmed. This is a **supervised**
experiment, not part of any script: it leaves a persistent user environment variable on the
guest (remove it with `REG delete HKCU\Environment /F /V w17_headtrack_ingest`, or just
revert to `clean-giftee-pc`). Enabling the head-track ingest changes nothing
control-relevant — W3 is LOG-ONLY, workspace `CLAUDE.md` safety boundary 5 — the point is
the silent, ambient nature of the toggle.
