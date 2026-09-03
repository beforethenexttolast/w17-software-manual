# W17 Windows-VM validation runbook

Owner decision A4 (`2026-09-02_readiness_program.md`): real-Windows validation for
`w17-ground-station` and the mapper it drives happens in a **VMware Fusion VM on the
owner's Apple Silicon Mac**, with the three real USB devices passed through (a 5.8 GHz
AP-capable USB Wi-Fi adapter for Mobile Hotspot, the ELRS TX over USB serial, and the
DualShock 4). Claude drives the checks **autonomously** once the VM exists; a real
Windows PC is the final proof only at handover. This document is the one-time owner setup
plus the autonomous-drive design; the scripts it drives live in
`w17-ground-station/scripts/windows-validation/` (see that directory's own `README.md` for
what each script does and its non-automatable steps).

**Nothing in this document or the scripts it drives flashes, uploads, or powers hardware,
or opens a serial port for control** (workspace `CLAUDE.md` safety rules). **A2 stays
NOT-EXECUTED and Phase B stays BLOCKED** regardless of anything this VM proves — a VM
validates the *Windows-side software*, not the RC car's hardware gates.

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
- Microsoft's mainstream consumer download page serves x64/x86 media. An ARM64 ISO is
  distributed through the **Windows Insider Preview ISO downloads** page (requires
  enrolling the download, not the resulting VM, in the Insider program) or via a UUP-dump
  style extraction from Windows Update — `[win-TBD]`: this session did not execute either
  path, so the exact current URL/flow is unverified. Pick whichever Microsoft-sanctioned
  path is live when the owner does this; avoid third-party ISO mirrors.
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
  (§1.5).

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
# allow it through Windows Defender Firewall (a fresh Windows install has no rule for it)
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
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

### 1.6 Snapshot `clean-giftee-pc` BEFORE any W17 install

Take a VMware Fusion snapshot named exactly `clean-giftee-pc` **immediately after** Windows
+ VMware Tools + OpenSSH are working, and **before** the first `10-install-gs.ps1` run or
any other W17-related install. This is the revert target every validation session starts
from (§2.1) — it is what makes the whole suite idempotent across VM sessions, not just
within one PowerShell run. Re-snapshot it (same name, or a new dated one — the owner's
call) only when a deliberate change to the "clean" baseline is wanted (e.g., after a
Windows Update the owner wants baked in).

### 1.7 USB passthrough for the three devices

In the VM's Settings → USB & Bluetooth (or the USB menu on a running VM), enable
passthrough for:

1. The 5.8 GHz AP-capable USB Wi-Fi adapter (Mobile Hotspot backend under test).
2. The ELRS TX handset, connected via USB serial.
3. The DualShock 4 controller (USB — `60-r15-pad-unplug.ps1`'s bench target; a Bluetooth
   DS4 pairs to the GUEST's own Bluetooth stack instead of USB passthrough, which needs the
   guest to see a Bluetooth radio at all — `[win-TBD]`, transport for the giftee's own PC
   is still marked TBD-at-bench in the booklet; USB is the sure path for VM testing).

Fusion passes a USB device through to WHICHEVER of host-or-guest currently "owns" it — the
Mac cannot use a passed-through device at the same time the guest has it. `00-inventory.ps1`
(COM ports + DualShock4 HID) and `30-hotspot.ps1` (Wi-Fi adapter capability) are how this
session confirms passthrough actually landed, rather than assuming the menu click worked.

### 1.8 ARM64 caveat (read before troubleshooting anything that "should just work")

The owner's ground-station and mapper builds are **x64** (electron-builder's default
target on this project's CI, and the mapper's release builds — see
`w17-mapper/Dockerfile.windows-amd64`). Running x64 binaries on a Windows-11-on-Arm guest
works through Microsoft's built-in x64 emulation layer, which is functionally transparent
but **not free** — expect slower boot/launch than a native x64 box, and budget for it in
any timeout this session's scripts use (`50-race-day.ps1`'s `-MapperWaitMs`,
`10-install-gs.ps1`'s installer timeout) rather than assuming x64-native speeds.

The bigger open question is the **Wi-Fi adapter driver**: the 5.8 GHz AP-capable USB
adapter owner decision A4 specifies needs an **ARM64-native Windows driver** to be usable
inside an ARM64 guest at all (a passed-through USB device still needs a driver matching the
GUEST's CPU architecture — x64 emulation does not cover kernel-mode drivers). Whether an
RTL8812BU/AU-class chipset (the common class of 5 GHz-capable, hosted-network/Mobile
Hotspot–capable USB adapter) ships an ARM64 driver from the vendor is **`[win-TBD]`** — this
session has not identified the owner's specific adapter's chipset or vendor driver
availability. `00-inventory.ps1`'s `netsh wlan show drivers` parse is the first real
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
exception of `60-r15-pad-unplug.ps1`'s physical unplug/replug, which needs a human hand at
the actual USB cable (see that script's own docs and
`scripts/windows-validation/README.md`'s non-automatable-steps list).

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

# a screenshot for anything a human should eyeball (e.g. the R15 unplug window,
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

See `scripts/windows-validation/README.md` §"Driving them from the Mac over SSH" for the
concrete invocation pattern and how to `scp` results back. In short:

```sh
ssh w17vm 'pwsh -File C:\w17\scripts\windows-validation\run-all.ps1 <params...>'
scp -r w17vm:'C:\w17\scripts\windows-validation\results\<timestamp>' ./evidence/
```

A plain (non-interactive) `ssh host 'command'` works for every script except
`60-r15-pad-unplug.ps1`'s default (Read-Host) mode — either use `ssh -t` for that one, or
its own `-NonInteractive` switch paired with a `vmrun captureScreen` (or the owner
physically present) to know when to act.

### 2.3 Getting the build onto the guest

None of the scripts in this suite build the GS or the mapper — they validate an ALREADY
BUILT artifact. Getting that artifact onto the guest is either:

- **From CI**: download the `w17-ground-station-nsis-unsigned` artifact (and, once a
  W17-mapper release job exists — readiness program Workstream 2 — the mapper zip) from
  the relevant GitHub Actions run, then `scp` it to the guest.
- **From a local build**: `npm run build` on the Mac produces an x64 Windows installer
  under `dist\` even though the Mac itself is arm64 (electron-builder cross-builds; the
  mapper's own Go cross-compile is `w17-mapper`'s concern, not this repo's) — `scp` that
  instead.

```sh
scp dist/W17*Setup*.exe w17vm:'C:\w17\dist\'
scp -r <mapper build dir> w17vm:'C:\w17\mapper\'
```

---

## 3. Run sequence, mapped to scripts

A full sweep, in order (matches `run-all.ps1`'s own sequencing and skip logic — see
`scripts/windows-validation/README.md` for each script's full description):

| # | command (via `ssh w17vm`) | what it needs from you | evidence it produces |
|---|---|---|---|
| 0 | `vmrun -T fusion revertToSnapshot "$VMX" clean-giftee-pc && vmrun -T fusion start "$VMX" nogui` | the VMX path | a known-clean starting state |
| 1 | `pwsh -File 00-inventory.ps1` | nothing | host survey JSON — confirm the Wi-Fi adapter, COM port, and DS4 all show up as expected BEFORE spending time on anything else |
| 2 | `pwsh -File 10-install-gs.ps1 -InstallerPath ...` | the installer, scp'd on first (§2.3) | install verified; **expected to FAIL on `boundaries-1`** (mediamtx missing) against a CI-built artifact until that CI defect is fixed |
| 3 | `pwsh -File 20-mapper-stage.ps1 -MapperExe ... -Profile ...` | the mapper binary + profile, scp'd | racePrep staged into settings.json; FAILS if the profile still has `REPLACE-WITH-` placeholders (MAP-5) |
| 4 | `pwsh -File 30-hotspot.ps1 -InstallDir ... -Password ...` | the real hotspot password (never invented) | hotspot start/verify/teardown through the app's own code; clean FAIL if no AP-capable adapter/driver landed (§1.8) |
| 5 | `pwsh -File 40-mdns-udp.ps1 -InstallDir ...` | nothing new | firewall state, a real mDNS query, a UDP 5601 replay-telemetry receive |
| 6 | `pwsh -File 50-race-day.ps1 -InstallDir ... -UserDataDir ...` | step 3 to have run | **expected to FAIL** — reproduces CONFIRMED blockers MAP-1 (mapper panic) and MAP-2 (RF link never started), plus MAP-8 port-reachability evidence while the mapper is briefly alive |
| 7 | (human present) `pwsh -File 60-r15-pad-unplug.ps1 -MapperExe ...` via `ssh -t`, mapper started by hand first | a human at the DS4 cable | R15 HID-transition evidence; MAP-6 code citation |
| — | `vmrun -T fusion stop "$VMX" soft` | | |

Or, for everything automatable in one call: `run-all.ps1` with whichever parameters are
available (see its own `.DESCRIPTION` — it skips, never fails, a step it lacks parameters
for).

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
  mapper PROCESS survives it (R15 / evidence toward `MAP-6`).

**Does NOT and cannot settle** (each already called out at the point it matters, in the
scripts and in `scripts/windows-validation/README.md`'s non-automatable-steps list — not
repeated as a gap here, just indexed):
- Whether CRSF frames actually reach the receiver over real RF (no serial port is ever
  opened by this suite, by design).
- Whether control resumes after a DS4 replug (the mapper's own gamepad registry is not
  independently queryable without a control-path probe this suite deliberately does not
  build).
- Any hardware fact under Phase B / A2 — this VM is a Windows-software validation target,
  never a stand-in for the bench gates in `CURRENT_STATUS.md`.
- Anything about a REAL x64 giftee PC beyond what an ARM64 VM under x64 emulation can
  stand in for (§1.8) — the giftee's actual PC gets its own pass at handover, by hand.

---

## 5. What a validation session discharges

A session that runs this runbook's §2–§3 sequence and reports its results back into
`CURRENT_STATUS.md` (the workspace's only file for commit hashes / gate status — this
runbook and the scripts it drives do not themselves carry that state) discharges exactly:
Workstream 3 of `2026-09-02_readiness_program.md` ("Windows validation path... Session runs
when the owner installs the VM"). It does NOT discharge A2 or Phase B (§0, restated because
it is the rule most likely to be misread from a green run here) — those stay gated on real
hardware, independent of how clean a VM run looks.
