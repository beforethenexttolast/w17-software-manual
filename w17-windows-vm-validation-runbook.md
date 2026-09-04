# W17 Windows-VM validation runbook

Owner decision A4 (`2026-09-02_readiness_program.md:21`): real-Windows validation for
`w17-ground-station` and the mapper it drives happens in a **VMware Fusion VM on the
owner's Apple Silicon Mac**, with USB passthrough. Claude drives the checks
**autonomously** once the VM exists; a real Windows PC is the final proof only at
handover. This document is the one-time owner setup plus the autonomous-drive design; the
scripts it drives live in `w17-ground-station/scripts/windows-validation/` (see that
directory's own `README.md` for what each script does and its non-automatable steps).
The three helpers that make it a set of commands rather than a set of instructions live in
this repo, at `scripts/vm/` (§2.4).

**Start at §1.0** — a numbered owner checklist, in order — and run
`scripts/vm/host-vm.sh doctor` before the first step. **Validated against the owner's actual
Mac on 2026-09-05** (§1.0.1), then reviewed adversarially and corrected the same day: every §1
step is marked OBSERVED-feasible, INFERRED, or BLOCKED for *this* host. **One step is BLOCKED
today: free host disk (§1.3) — about 20 GB available against a ~70 GB budget, so roughly
50 GB must be freed.** Nothing else in §1 is blocked by the Mac itself.

**Two things this document no longer leaves open**, because they change what you buy and where
you run things: the AP-capable Wi-Fi adapter question is **closed, negative** (§1.9 — no vendor
ships an ARM64 Windows driver for any candidate chipset, so `30-hotspot.ps1` runs on a real x64
PC, not on this VM), and Fusion's Bluetooth device sharing is **removed** (§1.11 — a Bluetooth
DualShock 4 will never appear in this guest, so USB is the only path).

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
> - §1.8's passthrough step presupposes a device that does not exist yet. §1.9's **driver**
>   half is no longer open, and the answer is **no** — see the next bullet.
> - **`30-hotspot.ps1` and the hotspot half of `40-mdns-udp.ps1` do not run on this VM at
>   all.** Their target is a **real x64 Windows PC** (a spare x64 laptop, or the giftee's own
>   PC before handover), because no vendor publishes an ARM64 Windows driver for any
>   candidate USB Wi-Fi chipset (§1.9, closed negative). The adapter purchase gates *that*
>   session, not this one. Buying the adapter is still required — it is what `30` tests on
>   x64 — but it will not make `30` work inside this guest.
> - If `30` is ever run here anyway it reports its clean "no usable hotspot backend" FAIL —
>   that is the script working, not a defect.
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

**Evidence labels.** Every value in this document that no session could execute and observe is
marked `[win-TBD]`. None are invented. The 2026-09-05 host-validation pass adds three more,
used wherever it says something new: **OBSERVED** (measured on the owner's Mac that day, and
the method is named), **INFERRED** (derived from a cited document, datasheet, or this
project's own build configuration — never from a run), and **BLOCKED** (needs an owner action,
and the action is named). `[win-TBD]` keeps its narrower meaning: *Windows itself decides this,
and no Windows has run.* Nothing labelled OBSERVED here is a fact about Windows, and no VM
result is ever promoted to a physical one.

---

## 1. One-time owner setup

This section is written for **the owner to do by hand**, once. Nothing in it is something
an unattended Claude Code session should attempt (VM creation, OS installation, and
license acceptance are all owner-facing GUI/account actions).

### 1.0 Owner checklist — do these in order, then stop

Run `scripts/vm/host-vm.sh doctor` before you start and again after each step: it re-prints
what is still missing, needs nothing installed, and changes nothing.

1. **Free about 50 GB more, so that at least 70 GB (decimal GB) is available** on the Mac's
   internal disk. **OBSERVED 2026-09-05: 20.3 GB free** of a 245.1 GB container (`diskutil
   info /`; `df -h /` shows `19Gi` — see §1.0.1 for why the numerals differ).
   `scripts/vm/host-vm.sh doctor` prints the same figure and the amount still to free.
   **STOP here if you cannot** — nothing below fits (§1.3). External storage is the alternative.
2. Install **VMware Fusion** from the `.dmg` (§1.1). Not the `.mpkg` — reported to fail on
   macOS 26.
3. **Turn VoiceOver OFF** before powering on any VM (§1.1): a reported macOS 26 Fusion defect
   shuts the VM down at power-on while VoiceOver is active.
4. Download the **Windows 11 Arm64 ISO** (§1.2); note where it lands. **Do it in one sitting:
   Microsoft's generated download link expires in about 24 hours.**
5. Create the VM: **4 vCPU, 8 GB RAM, 100 GB disk, NAT networking** (§1.3). Install Windows.
   Create **one local account**; write down its exact name.
6. Install **VMware Tools** from Broadcom's package download (§1.4) — the Fusion menu item is
   greyed out on macOS 26.
7. Download **`PowerShell-7.6.5-win-arm64.msi`** (§1.6) to the Mac.
8. In the guest, run `ipconfig`. Write down the IPv4 address **and its subnet with the last
   octet set to 0** — address `192.168.230.5` → subnet `192.168.230.0/24`. Step 12 wants the
   *subnet*; `192.168.230.5/24` passes every validator in `guest-bootstrap.ps1` and then
   scopes sshd to the wrong thing.
9. On the Mac: `ssh-keygen -t ed25519 -f ~/.ssh/w17vm_ed25519 -C "w17-vm"`.
10. Add the `w17vm` block to `~/.ssh/config` (§1.5) using that address and account name.
11. Carry three files into the guest (Fusion shared folder or drag-and-drop, both need Tools):
    `w17vm_ed25519.pub`, the PowerShell MSI, and `scripts/vm/guest-bootstrap.ps1`.
12. In the guest, open **PowerShell as administrator** and run (note `powershell`, not
    `pwsh` — this script is what *installs* pwsh 7):
    `powershell -ExecutionPolicy Bypass -File guest-bootstrap.ps1 -NatSubnet <your /24> -PublicKeyPath <the .pub> -PwshMsiPath <the .msi> -SshUser <the account from step 5>`
    It must end in `RESULT: OK`. **`RESULT: ACTION REQUIRED` (exit 4) is not a pass** — it
    means Windows' own *unscoped* `OpenSSH Server` firewall rule is still enabled and sshd is
    reachable from every interface this guest raises. Do what the ACTION line says and re-run.
    (`RESULT: FAILED` is exit 1, not elevated is 2, wrong platform is 3.)
13. From the Mac: `ssh w17vm whoami` must succeed **with no password prompt**. A prompt is the
    failure §1.5 describes, not a minor annoyance — stop and fix it.
14. Set the VMX path — **keep the quotes, Fusion's default path contains a space:**
    `export W17_VMX="/Users/<you>/Virtual Machines.localized/<name>.vmwarevm/<name>.vmx"`
    then `scripts/vm/host-vm.sh check`. Every **gating** check must read PASS — including
    `sshd-firewall-scope`, which step 12 is what makes passable. **INFO lines are expected to
    be unmet today** (no adapter bought, no GCS box attached); gating FAILs are not.
15. `scripts/vm/host-vm.sh stop`, then `scripts/vm/host-vm.sh snapshot clean-giftee-pc`
    (§1.7). Snapshot the guest **powered off**: a live snapshot writes an ~8 GB memory image
    onto the disk that is already this program's blocker, and reverting to it restores a
    powered-*on* VM. `host-vm.sh snapshot` refuses a running VM for exactly that reason.
16. **STOP.** Everything after this is Claude-driven (§2–§3). Do not install the ground
    station or the mapper by hand — validating the *install* is the point.

**First Claude-side step after the STOP** (not owner work, listed here so the handoff has no
gap): `scripts/vm/host-vm.sh stage` — it copies
`w17-ground-station/scripts/windows-validation/` to `C:\w17\scripts\` on the guest. Nothing
in steps 1–16 puts it there, and every §3 command runs `run-all.ps1` out of it. `suite` calls
`stage` before it runs, and `check` calls it *after* capturing `guest-check.json` (§4.1 rule 2
— the capture must see an unmodified guest), so this is a statement about *what happens*, not
another thing to remember.

Devices (§1.8, §1.11) whenever you have them: pass the GCS box's **FT232RL** and the
**DualShock 4** through over **USB**. The AP-capable 5 GHz adapter is **not bought yet** (§0).

### 1.0.1 This Mac, as measured — OBSERVED 2026-09-05

| fact | value | how |
|---|---|---|
| macOS | 26.3 (build 25D125) | `sw_vers` |
| CPU | Apple M4, 10 logical cores (4 P + 6 E) | `sysctl machdep.cpu.brand_string`, `hw.perflevel*.logicalcpu` |
| RAM | 16 GiB | `sysctl hw.memsize` |
| Free disk | **20.3 GB / 18.9 GiB** of a 245.1 GB container — and about **9 GB** of that is free only if macOS reclaims purgeable space | `diskutil info /` (Container Free Space, decimal GB), `df -h /` (`19Gi`), `df -g /` (`18`), and Foundation's `volumeAvailableCapacityFor*Usage` keys — four methods, see the note below |
| VMware Fusion | **not installed** | `/Applications/VMware Fusion.app` absent; `vmrun` not on `PATH` |
| Windows ISO | **none** | no `.iso` in `~/Downloads` |
| `pwsh` | **not on PATH** (a portable 7.7.0-preview.4 exists only in this session's scratchpad) | `which pwsh` |

> **Why the free-disk numeral keeps changing, and which one to trust.** macOS answers three
> different questions here: `diskutil` prints **decimal GB** (20.3), `df` prints **GiB** (19Gi
> / 18), and Foundation's *opportunistic* capacity key reports what is free **without**
> reclaiming purgeable content (~9 GB) — which is why an earlier measurement in this program
> read 9.6 GiB and another read 22.1 GB. They are the same volume. `20.3 GB == 18.9 GiB`; the
> drift from the 22.1 GB measured earlier on 2026-09-05 is real consumption in the hours since.
> **The document, `host-vm.sh doctor` and §1.3's table all use decimal GB**, and `doctor`
> prints the raw `df -h /` line beside it so the two numerals never have to be reconciled by
> hand. Whichever you start from, **~50 GB still has to be freed** (70 − 20.3 ≈ 50).

Every §1 step below was validated against **this** host. Where a step cannot be executed here,
it is labelled BLOCKED with the thing that blocks it — never quietly left as if it would work.

### 1.1 VMware Fusion

**Version.** Fusion moved off the `13.x` numbering to a calendar scheme. **Fusion Pro 26H1**
(released 2026-05-14) is the current line and **25H2 / 25H2u1** the prior one — **VERIFIED**
from Broadcom TechDocs read 2026-09-05 by the readiness program's **A3** research pass (a
session report, not a repo file — its findings are folded in here). An earlier draft of this
document implied a 13.x download, and a later one named 25H2 as current; **take whatever the
portal shows as current.** The version number is not load-bearing here — the macOS 26 items
below are. They were read against the **25H2** notes and have **not** been re-checked against
26H1: if 26H1 has fixed them, the workarounds still cost nothing.

**Host support.** Fusion 25H2's own system requirements are *"Any Mac that officially supports
macOS 15 Sequoia or later"*, minimum 8 GB of memory, *"1.5 GB of free disk space for Fusion Pro
and at least 5 GB of free disk space for each virtual machine"* (Broadcom TechDocs, *System
Requirements for Fusion Pro*, 25H2). **macOS 26.3 / M4 / 16 GiB therefore qualifies — INFERRED**
from that requirement text; this session did not install Fusion, so it is not OBSERVED.

**Licensing.** The 25H2 release notes state *"VMware Fusion Pro is now free for commercial,
educational, and personal use. You no longer require a license key."* The earlier
Broadcom-account-gated activation flow this document used to describe is **superseded**; you
still download from the Broadcom Support Portal, which does want an account.

**Two macOS 26 defects to read before you blame the VM — and a note on where they come from:**

1. **VoiceOver.** *"When VoiceOver is activated on macOS Tahoe 26, any attempt to power on a
   virtual machine, results in the VM shutting down abruptly."* Turn VoiceOver **off** before
   powering on a VM. A VM that dies instantly at power-on is this, not a broken image.
2. **Deployment package.** Deploying the `.mpkg` on macOS 26 is reported to error with
   *"Legacy Installer Package. This installer package is incompatible with this version of
   macOS."* Install from the ordinary `.dmg` instead. (§1.4 carries a third one, about
   VMware Tools.)

> **Provenance, stated rather than implied.** Two sessions in this program disagree about where
> the `.mpkg` and greyed-out-Tools items came from: one read them as Broadcom-documented known
> issues in the 25H2 release notes, the other (the **A3** research pass, §5) attributes them to a
> **forum thread**, explicitly *"not vendor-confirmed"*, and does not mention VoiceOver at all.
> Neither page is re-fetchable offline and this document does not adjudicate, so all three are
> labelled **INFERRED, and items 2 and the §1.4 one are possibly community-sourced.** The
> operational advice is harmless either way: installing from the `.dmg`, turning VoiceOver off
> and taking Broadcom's Tools package cost nothing if the defects turn out not to be real.

`[win-TBD]`: the exact download URL and portal flow still change independent of this project,
and this session did not walk it live — follow what the portal shows. The version, licensing
and host-requirement statements above are **INFERRED from Broadcom's TechDocs pages read
2026-09-05**, not from an install on this Mac.

### 1.2 Windows 11 ARM64 ISO

- Apple Silicon Fusion virtualizes **arm64**, not x64 — so the guest OS must be **Windows
  11 on Arm**, not the ordinary x64 retail ISO most people download.
- **RESOLVED — this is now a plain download, not a hunt.** Microsoft publishes an Arm64
  consumer ISO page: **<https://www.microsoft.com/software-download/windows11arm64>**, headed
  *"Download Windows 11 Disk Image (ISO) for Arm-based PCs"*, currently offering *"Windows 11
  2025 Update | Version 25H2"* as a *"multi-edition ISO which uses your product key to unlock
  the correct edition"*. **OBSERVED 2026-09-05** (page fetched and read this session). The
  previous drafts' Insider-preview and UUP-dump fallbacks are **no longer needed**; do not use
  third-party ISO mirrors.
- **The generated download link is time-limited — about 24 hours** (**A3** research pass, §5).
  Open the page and download in one sitting; a link opened today and used tomorrow is dead,
  and the page must be walked again.
- Budget ~6.5 GB for the download. The page states no size; the ~6.5 GB figure is
  **INFERRED** from the x64 ISO's ~7 GB and reporting that the Arm64 image runs a few hundred
  MB smaller — treat it as a planning number, not a measurement.
- The **Media Creation Tool makes x64 media only** and is useless here. Fusion boots the ISO
  directly, so no bootable USB is needed either.
- No product key is needed to install; Windows runs unactivated with a watermark and some
  personalisation locked. Nothing this suite tests depends on activation — **INFERRED**, and
  worth knowing before someone buys a licence for a throwaway validation VM.
- Fusion's own "Easy Install" for Windows on Arm has historically been less reliable than
  for x64 guests — if Easy Install fails or hangs, fall back to a manual ISO boot + attach
  VMware Tools afterward. `[win-TBD]`: not exercised this session.

### 1.3 VM sizing

No number below has been benchmarked against this project's actual workload (Electron +
Go binary + SDL2 + a WebRTC video pipeline that this VM will likely never receive real
video into, since there is no camera passthrough plan here) — `[win-TBD]` for all of them.
They are, however, now sized against **this specific Mac** (§1.0.1) rather than a generic one:
16 GiB of RAM and 10 cores, of which the host keeps its share.

- **CPU: 4 vCPUs.** The M4 has 4 performance + 6 efficiency cores (OBSERVED). Four leaves the
  host usable; more mostly buys contention.
- **RAM: 8 GB. Not 12–16.** An earlier draft called 12–16 GB "comfortable" — on a **16 GiB**
  host that is the whole machine, and macOS will swap the VM's own pages. 8 GB is enough for
  Windows 11 + Electron + one Go binary, and it is what leaves the Mac responsive while a
  sweep runs. Drop to 6 GB only if you must; Windows 11's own floor is 4 GB.
- **Disk: 100 GB virtual, thin-provisioned** (Fusion's default — the `.vmwarevm` grows as the
  guest fills it, so the *virtual* size is a ceiling, not an allocation). Windows 11 requires
  a 64 GB volume to install onto, which is why the virtual disk is large even though the real
  consumption is far smaller.
- **Networking: NAT.** Enough for SSH-from-Mac and this whole suite. The Mobile Hotspot backend
  under test (`30-hotspot.ps1`) creates its OWN separate SoftAP interface on the guest via the
  passed-through USB Wi-Fi adapter — it does not need or use the VM's virtual NIC to do that.
  Do not bridge the VM's virtual NIC to the AP-capable adapter; that adapter stays a raw USB
  passthrough device the guest OS drives directly (§1.8).

#### The real constraint is host disk, and today it is a BLOCKER

Thin provisioning caps what the VM *allocates*, not what it *consumes*. Planning budget for
what actually lands on the Mac's SSD:

| item | GB | basis |
|---|---|---|
| Fusion itself | 1.5 | Broadcom's stated requirement (§1.1) |
| Windows 11 Arm64 ISO | ~6.5 | INFERRED (§1.2) |
| Guest after install + Windows Update | ~30–40 | INFERRED from Windows 11's 64 GB volume requirement and typical post-update footprint. **Not measured — no VM exists.** |
| pwsh 7 + GS install + mapper bundle + results | ~2 | MSI 103 MiB (OBSERVED), NSIS + mapper bundle small |
| One `clean-giftee-pc` snapshot's delta | ~5–15 | INFERRED. Fusion snapshots grow with post-snapshot writes; a full validation sweep writes a lot. |
| **Total to plan against** | **~46–65 → plan 70** | the rows above sum to 45.5–65; rounded up to a round 70 for headroom, which is `host-vm.sh`'s `MIN_FREE_GB` |

**OBSERVED 2026-09-05: 20.3 GB free of a 245.1 GB container** (`diskutil info /`, decimal GB;
`df -h /` shows `19Gi`, `df -g /` shows `18` — same volume, GiB instead of GB, §1.0.1 has the
reconciliation). **This step is BLOCKED on an owner action: free about 50 GB so that ≥ 70 GB
is available, or put the VM bundle on external storage.** `scripts/vm/host-vm.sh doctor`
prints this verdict in the same decimal GB as the table above, alongside the raw `df -h /`
line, and re-prints it after you free space — so you never have to re-derive the number or
reconcile two numerals for one fact.

External storage is a real option but not a free one: `[win-TBD]` / INFERRED — keep the VM on
an **APFS or HFS+** volume (exFAT/FAT handle Fusion's sparse files badly), and expect slower
guest I/O over USB than the internal SSD, which inflates every timeout §1.9 already warns
about. The ISO can also live on external storage; it is read once during install.

### 1.4 VMware Tools

Install VMware Tools inside the guest once Windows itself is up. This is what makes
`vmrun captureScreen`, `vmrun getGuestIPAddress`, drag-and-drop / shared folders (how §1.0
step 11 gets three files into the guest) and graceful guest shutdown work, and what
`00-inventory.ps1`'s `VMTools` service check — and `scripts/vm/guest-check.ps1`'s
`vmware-tools` line — report on.

> **⚠ On macOS 26 the menu item is reported not to work.** *"The Install VMware Tools button
> is grayed out on a device that uses macOS 26 Tahoe operating system,"* with the workaround
> being to download the Tools package from Broadcom's own package downloads and attach the ISO
> to the VM by hand (Virtual Machine → Settings → CD/DVD → point it at the downloaded `.iso`,
> then run the installer from inside the guest). **INFERRED, and possibly community-sourced**
> — one session in this program read this as a Broadcom-documented 25H2 known issue, another
> attributes it to a forum thread and explicitly *"not vendor-confirmed"* (§1.1's provenance
> note). Not walked on this Mac, which has no Fusion. Following the workaround costs nothing
> if the defect is not real: try the menu item first, and fall back to the package.

`[win-TBD]`: not executed this session. Both `guest-check.ps1` and the inventory script say
plainly if Tools are missing or not running, so a skipped step here surfaces immediately
rather than as a mysterious `captureScreen` failure later.

### 1.5 Guest OpenSSH Server + key auth

**`scripts/vm/guest-bootstrap.ps1` does everything in this section**, idempotently, with the
admin-vs-user `authorized_keys` split and the ACL that Windows OpenSSH silently requires (see
§2.4). Run it at the guest console the first time — SSH is what it is setting up. What follows
is what it does, so the script is auditable rather than magic.

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

# AND disable Windows' OWN rule group, which Add-WindowsCapability installed and which is
# UNSCOPED (any remote address). While it is enabled the scoped rule above is decorative:
# sshd is reachable from every interface the guest raises, including the SoftAP that
# 30-hotspot.ps1 creates. guest-bootstrap.ps1 does this for you, AFTER creating the scoped
# rule -- so as long as the scoped rule names the RIGHT subnet, the Mac keeps its way in.
# A valid-but-wrong /24 (see 1.0 step 8) passes every validator and then locks ssh out until
# someone returns to the guest console; that is recoverable -- step 12 is a console step --
# but it is a wasted trip, so check the subnet before you run it.
Get-NetFirewallRule -DisplayGroup 'OpenSSH Server' | Disable-NetFirewallRule
```

**Two things about scope that are easy to get wrong.** `-Profile Private` is **not** isolation
on its own — Windows commonly classifies a hosted-network/SoftAP adapter as Private too, so
`-RemoteAddress` is the only thing keeping sshd off that interface. And an over-wide CIDR
(`0.0.0.0/0` is CIDR-shaped) would undo it silently, which is why `guest-bootstrap.ps1`
validates `-NatSubnet` as a real RFC1918 range with a `/16`–`/30` prefix rather than merely
checking its shape.

`guest-check.ps1`'s `sshd-firewall-scope` is a **GATING** check, not an informational one: it
fails if any enabled inbound rule reaching TCP/22 is `Any`/`Public`-scoped. It can pass on a
clean guest precisely because the step above disables the inbox rules.

Then, from the Mac:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/w17vm_ed25519 -C "w17-vm"
# copy ~/.ssh/w17vm_ed25519.pub into the guest's
#   C:\Users\<user>\.ssh\authorized_keys   (Administrators use
#   C:\ProgramData\ssh\administrators_authorized_keys instead — Windows OpenSSH's
#   documented split; check which applies to the account this session logs in as)
```

Two things about that file bite silently, and are why `guest-bootstrap.ps1` scripts it:

- **The admin/user split is not a preference.** For any account in the local Administrators
  group, sshd reads `C:\ProgramData\ssh\administrators_authorized_keys` — a single shared file
  — and **ignores** that account's own `~/.ssh/authorized_keys`. A key placed in the wrong one
  produces a password prompt, not an error.
- **The ACL matters.** sshd refuses an `authorized_keys` whose ACL grants write access beyond
  Administrators + SYSTEM, and falls back to password auth without saying why. The script
  runs `icacls /inheritance:r` and grants only those two.

Verify with `ssh w17vm 'whoami'` before trusting anything else in this document — **and check
that it did not prompt for a password**. A working password prompt is exactly the failure mode
these two rules produce, and it looks like success.

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

### 1.6 PowerShell 7 in the guest — REQUIRED, and Windows does not ship it

**Use the ARM64 MSI, not `winget`.** This is a change from the previous draft, and it is
specific to *this* guest being ARM64 and driven over SSH:

```sh
# on the Mac — download once, carry it into the guest with the key (§1.0 step 11)
curl -LO https://github.com/PowerShell/PowerShell/releases/download/v7.6.5/PowerShell-7.6.5-win-arm64.msi
```

```powershell
# inside the guest, elevated — or let guest-bootstrap.ps1 -PwshMsiPath do it
msiexec /i PowerShell-7.6.5-win-arm64.msi /qn /norestart ADD_PATH=1
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'   # in a NEW shell
```

`PowerShell-7.6.5-win-arm64.msi` (107,790,336 bytes, release v7.6.5 published 2026-08-14) is
**OBSERVED** — queried from the PowerShell releases API on this Mac, 2026-09-05. Pick whatever
is current when you do this; the point is the **`win-arm64.msi`** asset.

Why not `winget install --id Microsoft.PowerShell` (what this document used to say):

- **winget 1.11+ installs the MSIX by default** for this package. The MSIX's `pwsh` is an *app
  execution alias* under `%LOCALAPPDATA%\Microsoft\WindowsApps` — a **per-user** path. It
  resolves for an interactive shell as that user, and does **not** resolve for another account
  or for machine-context tooling. The MSI installs `C:\Program Files\PowerShell\7\pwsh.exe` and
  puts it on the **machine** `PATH`, which is what `ssh w17vm 'pwsh -File …'` needs. INFERRED
  from the packaging difference; not exercised on a guest.
- winget itself needs the Microsoft Store's App Installer present and updated on a fresh image
  — one more thing that can be missing on the guest you are trying to bootstrap.

`guest-check.ps1` checks for the machine install specifically (`pwsh-machine-install`), not
merely that `pwsh` resolves, so an MSIX-only install is reported rather than discovered later.

This is not a preference and not a "nice to have". **Windows 11 ships only Windows
PowerShell 5.1**, and every script in `scripts/windows-validation/` carries
`#Requires -Version 7.0` because it means it: the shared command runner
(`lib/common.ps1`'s `Invoke-W17Command`) and `50-race-day.ps1` use
`System.Diagnostics.ProcessStartInfo.ArgumentList`, which exists only on .NET Core 2.1+ /
.NET 5+ — **not** on the .NET Framework that 5.1 runs on. Under 5.1 that property access
throws, and every script that shells out dies.

`run-all.ps1` **refuses to fall back** to `powershell.exe`: it resolves `pwsh`, checks its
major version, and otherwise throws one clear message. An earlier version preferred `pwsh` but
silently fell back, which on a fresh guest turned one solvable setup problem into eight
separate .NET stack traces.

> **⚠ That error message tells you to do the wrong thing.** `run-all.ps1`'s own text — and
> `w17-ground-station/scripts/windows-validation/README.md` — say *"Install it on the guest,
> then re-run: `winget install --id Microsoft.PowerShell --source winget`"*. **Do not follow
> it here.** winget 1.11+ installs the MSIX, whose `pwsh` is a per-user execution alias that a
> non-interactive `ssh … 'pwsh -File …'` cannot resolve, so you would hit the same error again
> for the reason argued above. Install `PowerShell-7.6.5-win-arm64.msi` instead. Correcting
> that message is a follow-up in `w17-ground-station`; this branch is read-only on that repo.

Do this **before** the `clean-giftee-pc` snapshot below, so every reverted session already
has PowerShell 7.

`[win-TBD]`: no installation of any kind was run by this session — there is no Windows here.
What is OBSERVED is only that the ARM64 MSI asset exists and its exact name and size.

### 1.7 Snapshot `clean-giftee-pc` BEFORE any W17 install

**Shut the guest down cleanly first** (`scripts/vm/host-vm.sh stop`), then take a VMware Fusion
snapshot named exactly `clean-giftee-pc` — **after** Windows + VMware Tools + OpenSSH are
working, and **before** the first `10-install-gs.ps1` run or any other W17-related install.
Powering off first is not fussiness: `vmrun snapshot` on a *running* VM captures the guest's
**memory** as well, which at §1.3's 8 GB guest is an ~8 GB `.vmem` written to a host whose free
disk is this program's hardest blocker (§1.3's "~5–15 GB snapshot delta" row does not include
it) — and reverting to a live snapshot restores a powered-**on** VM, so the documented
`revert && start` chain fails with *"already powered on"*. `host-vm.sh snapshot` refuses a
running VM unless you pass `--live`. This is the revert target every validation session starts
from (§2.1) — it is what makes the whole suite idempotent across VM sessions, not just
within one PowerShell run. Re-snapshot it (same name, or a new dated one — the owner's
call) only when a deliberate change to the "clean" baseline is wanted (e.g., after a
Windows Update the owner wants baked in).

From the Mac, that is one command — and it refuses to retake a snapshot that already exists,
so it is safe to re-run:

```sh
scripts/vm/host-vm.sh stop            # powered off, for the reason above
scripts/vm/host-vm.sh snapshot clean-giftee-pc
```

### 1.8 USB passthrough for the three devices

In the VM's Settings → USB & Bluetooth (or the USB menu on a running VM), enable
passthrough for:

| # | device | what Windows actually sees | status |
|---|---|---|---|
| 1 | AP-capable 5 GHz USB Wi-Fi adapter (Mobile Hotspot backend under test) | **a raw USB device with no usable driver** — passthrough delivers the device, never the driver, and no vendor ships an ARM64 Windows driver for any candidate chipset (§1.9) | **not bought (§0) — AND no ARM64 driver exists for any candidate chipset (§1.9). Passing it through to THIS guest will not make `30-hotspot.ps1` work; that step runs on a real x64 PC.** |
| 2 | The GCS box's **FT232RL USB-UART**, which is how the **ELRS TX module** reaches the PC | a numbered **COM port**, USB **VID 0403** (FTDI), FT232R default **PID 6001** | on hand (`HARDWARE_INVENTORY.md:77`) |
| 3 | The DualShock 4, over **USB** | an HID device, VID **054C**, PID **05C4** / **09CC** (or **0BA0** for the dongle) | on hand |

**Row 2, stated precisely, because two things here are easy to get wrong.** The ELRS module
has **no PC driver of its own** — Windows only ever sees the serial adapter in front of it
(`w17-gcs-box-guide.md:184-186`, `w17-giftee-pc-install-guide.md:43-48`). And that adapter is
an **FT232RL** (`w17-gcs-box-guide.md:44`: *"FT232RL USB-UART, Type-C board variant"*;
`HARDWARE_INVENTORY.md:77`). VID `0403` is FTDI's assigned USB vendor id and `6001` the
FT232R's default product id — **INFERRED** from the part identity, not read off this hardware,
which is not in front of this session. `guest-check.ps1` flags any COM device with VID `0403`
for exactly this reason, and opens no port to do it.

**Row 3.** USB is the sure path for VM testing: a Bluetooth DS4 pairs to the **guest's own**
Bluetooth stack, and a Fusion guest on Apple silicon does not get one (§1.11). Transport for
the giftee's own PC is still `[TBD-at-bench]` in the booklet. There is a second reason to
prefer USB here: **the mapper's pad id differs between USB and Bluetooth** — SDL encodes the
bus in the GUID (`w17-mapper/configs/README.md:111-116`) — so a profile matched over one
transport is wrong over the other.

Fusion passes a USB device through to WHICHEVER of host-or-guest currently "owns" it — the
Mac cannot use a passed-through device at the same time the guest has it. `00-inventory.ps1`
(COM ports + DualShock4 HID), `scripts/vm/guest-check.ps1` (the same enumeration, before the
suite is even staged) and `30-hotspot.ps1` (Wi-Fi adapter capability) are how this session
confirms passthrough actually landed, rather than assuming the menu click worked.

### 1.9 ARM64 caveat (read before troubleshooting anything that "should just work")

The owner's ground-station and mapper builds are **x64** (electron-builder's default
target on this project's CI, and the mapper's release builds — see
`w17-mapper/Dockerfile.windows-amd64`). Running x64 binaries on a Windows-11-on-Arm guest
works through Microsoft's built-in x64 emulation layer, which is functionally transparent
but **not free** — expect slower boot/launch than a native x64 box, and budget for it in
any timeout this session's scripts use (`50-race-day.ps1`'s `-MapperWaitMs`,
`10-install-gs.ps1`'s installer timeout) rather than assuming x64-native speeds.

**The Wi-Fi adapter question is CLOSED, and the answer is no.** An AP-capable USB Wi-Fi
adapter passed through to this guest needs an **ARM64-native Windows driver** — passthrough
delivers the device, never the driver, and Windows' x64 emulation does not cover kernel-mode
drivers. As of 2026-09-05 **no vendor publishes an ARM64 Windows driver for any candidate USB
Wi-Fi chipset** (MT7612U, MT7921AU, RTL8812AU/BU, RTL8821CU/8811CU, RTL8852AU/8832AU; Qualcomm
and Intel ship no current USB Wi-Fi part at all). Realtek's own portal — the one authoritative
source the survey could not reach by fetch — lists a single 2018 package for the 8812AU/BU
line, *"32bit/64bit Windows7, Windows8.1, Windows10"*, v1030.25.0701.2017: **no ARM64 entry and
no Windows 11 entry** (**OBSERVED** in-browser 2026-09-05, the 2026-09-05 ARM64-driver survey's
Director addendum to the readiness program's **A3** research pass; the per-chipset survey is
that report's §1).

**Therefore `30-hotspot.ps1`, and `40-mdns-udp.ps1`'s hotspot-interface half, are ROUTED OFF
THIS VM.** They run on a **real x64 Windows machine** — a spare x64 laptop, or the giftee's own
PC before handover. **This is the plan, not a fallback.** **Everything else in the suite
(`00`, `10`, `20`, `50`, `60`) is unaffected and stays on the ARM64 VM.** Do not pass the
adapter through to this guest expecting `30` to work; buying the adapter is still required —
it is what `30` tests on x64 — but it does not unblock the VM.

`00-inventory.ps1`'s `netsh wlan show drivers` parse and `guest-check.ps1`'s
`wifi-hosted-network` line stay useful as evidence *that this is the state* — 0 adapters, 0
hosted-network-capable — not as a question still awaiting an answer.

The FT232RL is the opposite case — see below.

**The FT232RL has the same question, with a better-known answer.** Its driver is also
kernel-mode and also must be ARM64-native. Two things reduce the risk: Windows Update supplies
FTDI's VCP driver as a matter of course on 10/11 (`w17-gcs-box-guide.md:184`), and FTDI ships
ARM64 binaries in its CDM package. The catch reported for that package is that the
**`.exe` setup executable is x86/x64 only**, so on ARM64 the driver is installed *manually* —
Device Manager → the unknown device → Update driver → Browse → the unpacked CDM folder.
**INFERRED**, from search results summarising FTDI's driver pages; this session could not open
`ftdichip.com` directly (HTTP 403), so treat it as a plan, not a confirmed procedure, and let
Windows Update try first. `guest-check.ps1`'s `elrs-tx-serial-visible` line is the first real
evidence either way.

### 1.10 Exact guest software and drivers

Everything the guest needs, why, and where it comes from. Nothing here is optional-by-taste:
each row is something a script in the suite depends on or something Windows will ask you for.

| # | item | why | source | ARM64? |
|---|---|---|---|---|
| 1 | **VMware Tools** | `vmrun captureScreen` / `getGuestIPAddress`, graceful shutdown, drag-and-drop and shared folders | Broadcom package download — **the Fusion menu item is greyed out on macOS 26** (§1.4) | ships arm64 for Windows-on-Arm guests — INFERRED |
| 2 | **OpenSSH Server** | the entire autonomous-drive design (§2.2) | Windows **inbox optional capability**, `OpenSSH.Server~~~~0.0.1.0` — no download | inbox, so yes |
| 3 | **PowerShell 7** (`PowerShell-7.6.5-win-arm64.msi`) | every script is `#Requires -Version 7.0`; Windows 11 ships only 5.1 (§1.6) | GitHub PowerShell releases — **MSI, not winget/MSIX** | **arm64 MSI, OBSERVED to exist** |
| 4 | **FTDI VCP driver** (CDM) | the ELRS TX's FT232RL → a COM port (§1.8) | Windows Update first; FTDI's CDM package as fallback, installed manually on ARM64 (§1.9) | INFERRED yes, `.exe` installer is not |
| 5 | **DualShock 4 driver** | `60-hid-transition.ps1`, `20`'s pad id | **none — Windows inbox HID/XInput handles a USB DS4** | inbox, so yes |
| 6 | **AP-capable 5 GHz USB Wi-Fi driver** | `30-hotspot.ps1`, `40`'s hotspot half — **on a real x64 PC, not on this VM** | vendor x64 driver for whichever chipset is bought (§0, §1.9) | **No — closed negative (§1.9). This row is why 30/40-hotspot run on x64.** |
| 7 | **.NET / VC++ redistributables** | — | **NOT NEEDED. See below.** | n/a |

**Row 7 deserves the argument rather than the assertion**, because "install the VC++ redist"
is the reflexive answer and it is wrong here:

- **The ground station** is Electron 31 (`w17-ground-station/package.json` devDependencies).
  Electron carries its own runtime and links the Universal CRT, which is inbox on Windows 10+.
  It needs no .NET and no VC++ redist. Its one native module, `serialport`, is shipped
  **prebuilt and asar-unpacked** inside the package (`w17-ground-station/electron-builder.yml:51-53`),
  so nothing is compiled on the guest.
- **The mapper** is built by `w17-mapper/.github/workflows/w17-windows-release.yaml:74-78` with
  **`-tags static`** through **MinGW-w64 gcc** against **SDL2 2.28.1 dev libs**
  (`w17-mapper/Dockerfile.windows-amd64:39-45`). Static SDL2 + MinGW means the binary links
  `msvcrt.dll` (inbox) and carries SDL2 inside itself: **no `SDL2.dll` to ship, no MSVC
  runtime to install.** The `vc_redist.x64.exe` line in that Dockerfile
  (`w17-mapper/Dockerfile.windows-amd64:62-65`) is for the **builder image's** toolchain, not a
  runtime dependency of the produced exe.
- Both are **x64** binaries and run under the guest's x64 emulation (§1.9's timing warning
  applies), which needs nothing installed either.

INFERRED throughout — from the build configuration, not from an install on Windows. If
`10-install-gs.ps1` or a mapper launch fails with a missing-DLL dialog, that is a **new**
finding and this row is where to record it.

**Wi-Fi adapter driver: the ARM64 half is settled, the chipset choice is not.** §1.9 closes the
ARM64 question negatively for every candidate chipset, which is why row 6 targets x64. *Which*
adapter to buy is still the procurement workstream's call (the A3 survey §6 recommends
the RTL8812AU/BU class, e.g. an Alfa AWUS036ACH, on x64 driver maturity) — read that finding
before buying, and let it, not this row, name the part.

### 1.11 USB passthrough on Apple silicon: what it can and cannot do

Mostly INFERRED (from how VMware Fusion's USB passthrough and Apple silicon virtualization
work, plus this project's own device list), **not observed** — no Fusion exists on this Mac.
Two rows are stronger than that and say so inline: the Wi-Fi adapter row is a **closed
negative** (§1.9) and the Bluetooth row is **VERIFIED** from Broadcom's own documentation. Each
row says what to check after connecting, so a wrong assumption is caught in one command instead
of at the end of a sweep.

| thing | can Fusion pass it to the guest? | what to check after connecting |
|---|---|---|
| A USB serial adapter (the FT232RL) | **Yes** — a plain USB device | `host-vm.sh check` → `elrs-tx-serial-visible`, and a COM device with VID `0403` |
| A USB HID gamepad (DS4 over cable) | **Yes** | `host-vm.sh check` → `dualshock4-visible` |
| A USB Wi-Fi adapter | **Yes, as a raw USB device — and it will not work here.** The guest still needs its own ARM64 driver, and none exists for any candidate chipset (§1.9, closed negative). Passthrough delivers the device, never the driver | `host-vm.sh check` → `wifi-hosted-network` will read 0/0. That is the **expected** answer, not a defect; `30-hotspot.ps1` belongs on a real x64 PC |
| The Mac's **built-in** Wi-Fi | **No.** It is not a USB device; the guest gets only the virtual NIC | — (this is why the hotspot needs its own USB adapter at all) |
| The Mac's **Bluetooth radio** | **No — VERIFIED.** Broadcom's own *Sharing Bluetooth Devices with a Virtual Machine*: *"Bluetooth device support is removed in VMware Fusion 13.6 and later."* Fusion is well past 13.6 (§1.1), so the feature is gone — this is not an Apple-silicon inference | a Bluetooth DS4 will simply never appear — use USB (§1.8 row 3), which is therefore the **only** path, not merely the sure one |
| A camera / video capture | **Yes** in principle, but **out of scope** — there is no camera passthrough plan, which is why §1.3 notes this VM will likely never receive real video |
| The Mac's internal SSD or a Thunderbolt device | **No** — USB passthrough only | — |

Four consequences worth stating rather than discovering:

1. **Passthrough is exclusive.** While the guest owns a device the Mac cannot use it, and
   vice versa. If a device "disappears" from the guest, check whether macOS grabbed it back.
2. **Passthrough is not a driver.** Every row above that says "yes" still needs an ARM64
   driver in the guest. That is §1.9 — **closed negative** for the Wi-Fi adapter (no ARM64
   driver exists for any candidate chipset, so the hotspot moves to a real x64 PC), still
   only **INFERRED-positive** for the FT232RL and the DS4, whose drivers Windows is expected
   to supply but which nobody has watched enumerate on ARM64 yet.
3. **USB is the only path for the DS4, not merely the sure one** — Fusion removed Bluetooth
   device sharing in 13.6 (row 5, VERIFIED), so §1.8 row 3's preference is now a requirement.
4. **A hub is one decision, not many.** The GCS box presents its contents through an internal
   USB hub (`w17-gcs-box-guide.md` §1's one-cable promise). Fusion attaches devices, not hubs,
   so expect to enable **each** device behind it individually, and re-check after replug.

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
VMX="$HOME/Virtual Machines.localized/w17-giftee-pc.vmwarevm/w17-giftee-pc.vmx"   # KEEP THE QUOTES — the default path contains a space. Path is whatever Fusion actually created; confirm with `vmrun -T fusion list` while it's running once

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
# Preferred: session-aware, and the only form §4.1's evidence layout expects.
scripts/vm/host-vm.sh check                       # opens the session, stamp in .current-session
scripts/vm/host-vm.sh suite <allow-listed params...>

# The raw equivalent, for driving one script by hand. <stamp> is that same
# session stamp; `suite` passes -ResultsRoot for you precisely so the pull
# carries THIS run and not runs 1..N.
ssh w17vm 'pwsh -File C:\w17\scripts\windows-validation\run-all.ps1 -ResultsRoot C:\w17\results\<stamp> <params...>'
scp -r w17vm:'C:\w17\results\<stamp>' ./evidence/<stamp>/results
```

A plain (non-interactive) `ssh host 'command'` works for every script except
`60-hid-transition.ps1`'s default (Read-Host) mode — either use `ssh -t` for that one, or
its own `-NonInteractive` switch paired with a `vmrun captureScreen` (or the owner
physically present) to know when to act. Through `run-all.ps1` the equivalent switches are
`-IncludeHidTransition` and `-HidTransitionNonInteractive`.

`run-all.ps1` will refuse to start if the guest has no PowerShell 7 (§1.6) — that is the
intended behaviour, not a bug. **Its error text recommends `winget install --id
Microsoft.PowerShell`; do NOT follow it.** winget 1.11+ installs the MSIX, whose `pwsh` is a
per-user execution alias that a non-interactive `ssh … 'pwsh -File …'` cannot resolve, so you
would trip the same error again — §1.6 has the argument. Install
`PowerShell-7.6.5-win-arm64.msi` instead. Correcting that message is a follow-up in
`w17-ground-station`, which this branch is read-only on.

**`run-all.ps1` has to be ON the guest first**, and nothing in §1 puts it there: §1.0 step 11
carries the key, the MSI and `guest-bootstrap.ps1`, and §2.3 below covers the GS installer and
the mapper bundle. `scripts/vm/host-vm.sh stage` copies
`w17-ground-station/scripts/windows-validation/` to `C:\w17\scripts\`; `suite` calls it
before it runs and `check` calls it after its own capture (§4.1 rule 2), so the only way to hit
"file not found" is to run the raw `ssh` line above before ever running either verb.

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

- **The validation suite itself** — `w17-ground-station/scripts/windows-validation/`, which is
  where `run-all.ps1` and the seven numbered scripts live. It is not an *artifact*, but it is
  the third thing that has to reach the guest and nothing in §1 carries it:
  `scripts/vm/host-vm.sh stage` does, into `C:\w17\scripts\windows-validation\`. `suite`
  stages before it runs and `check` stages after its own capture, so in normal use it happens
  by itself; run it by hand only when driving the numbered scripts directly over `ssh`.

```sh
scripts/vm/host-vm.sh stage                       # the suite itself
scp dist/W17*Setup*.exe w17vm:'C:\w17\dist\'
scp -r <mapper build dir> w17vm:'C:\w17\mapper\'
```

(If a backslash path ever comes back mangled, forward slashes work too —
`w17vm:'C:/w17/dist/'`. Windows' SFTP server accepts both.)

### 2.4 The three helper scripts (`scripts/vm/`)

Committed in this repo, executable, and each carrying its own full header. They exist so a
validation session is a sequence of named verbs rather than hand-typed `vmrun` paths, and so
the two guest-side setup steps that bite silently (the `authorized_keys` split, the MSIX-vs-MSI
`pwsh` path) are scripted rather than described.

| script | runs on | what it does |
|---|---|---|
| `scripts/vm/host-vm.sh` | the **Mac** | `vmrun` + `ssh`/`scp` wrapper: `doctor start stop status snapshot revert snapshots screenshot ip ssh push pull stage bootstrap check suite selftest`. Every verb is idempotent; `--dry-run` prints the exact commands and executes none. Every `ssh`/`scp` runs `BatchMode=yes` + `ConnectTimeout=10` so the password prompt §1.5 predicts fails fast instead of hanging an unattended run; `--interactive` drops BatchMode for the one deliberate `ssh -t` case. `--session STAMP` pins the evidence session (§4.1). |
| `scripts/vm/guest-bootstrap.ps1` | the **guest**, elevated | OpenSSH Server + service; `authorized_keys` in the file **the ssh login account** (`-SshUser`) will actually be read from, with the correct ACL; ONE scoped firewall rule (Private profile, your NAT subnet only, validated as a real RFC1918 range) **and Windows' own unscoped inbox rule disabled**; PowerShell 7 from the ARM64 MSI. Idempotent; `-DryRun` reports without changing. Exits 0 OK / 1 failed / 2 not elevated / 3 not Windows / **4 configured but a posture action is outstanding**. Runs under Windows PowerShell 5.1 on purpose — it is what installs pwsh 7. |
| `scripts/vm/guest-check.ps1` | the **guest** | Read-only readiness verdict + JSON evidence: Windows version/arch, pwsh ≥ 7.4 **and where it resolved from**, execution policy, sshd + **a GATING check on the scope of every enabled rule reaching TCP/22**, VMware Tools, COM ports with VID:PID (FTDI flagged), DS4 HID, and `netsh wlan show drivers` parsed for hosted-network / Wi-Fi Direct / radio types. |

Five properties worth knowing before you rely on them:

- **`doctor` needs nothing installed.** It is the one thing runnable on this Mac today, and it
  prints one `BLOCKED` line per outstanding owner action (§1.0). Run it first, and again after
  each step.
- **`suite` forwards an ALLOW-LIST and exits 2 on everything else.** The parameters it will
  pass to `run-all.ps1` are `-InstallerPath -InstallDir -UserDataDir -MapperExe -Profile
  -Ssid -Password -MdnsTimeoutMs -MapperWaitMs -Shell`, spelled in full. `-IncludeHidTransition`
  and `-HidTransitionNonInteractive` are therefore refused — and so is every spelling
  PowerShell would bind to them, which is the point: PowerShell matches parameter names
  **case-insensitively and by unambiguous prefix**, so `-Inc`, `-Hid`, `-INC`, `--Inc` and
  `-hid:$true` all set those switches, and a first version of this guard that listed the two
  full names let all of them through. Step 7 needs a human at the DS4 cable and the car
  unpowered / RX unbound (§3.1), so a wrapper must not be able to start it by accident. Run
  that one deliberately, by hand, over `ssh -t` (`host-vm.sh --interactive ssh '…'`). Enforced
  in `suite_guard()`, and re-proved on demand by `host-vm.sh selftest` — 31 host-only cases,
  no VM, no ssh, nothing powered — because an earlier version printed the denial three lines
  above the command that did it, twice.
- **`stage` is what puts the suite on the guest.** Nothing in §1 does (§2.2, §2.3). `suite`
  stages before it runs; `check` stages *after* it has captured `guest-check.json`, so the
  gap only bites someone driving the numbered scripts by raw `ssh`.
- **`check` opens the evidence session.** It writes `evidence/.current-session`, and `suite`
  and `screenshot` reuse that stamp, so one session is one directory (§4.1 rule 1). Before,
  each verb minted its own stamp and scattered a session across three.
- **`guest-check.ps1` is a pre-flight, not a second `00-inventory.ps1`.** It runs *before* the
  suite is staged — `check` stages only after the pull — so a missing `pwsh` or a passthrough
  that did not land costs one round trip instead of eight failing scripts, and
  `guest-check.json` still describes an unmodified guest (§4.1 rule 2). The one thing that
  reaches the guest ahead of it is `guest-check.ps1` itself: it is the instrument, it installs
  nothing. `00-inventory.ps1` remains the suite's own survey, in the
  suite's own result envelope.

**Executed on macOS, under PowerShell 7.7.0-preview.4 (three times: the authoring pass, an
adversarial review + fix pass, and an independent re-verification + second fix pass, all
2026-09-05):** `bash -n` over `host-vm.sh`; `Parser::ParseFile` over both `.ps1` files (0
errors); `guest-check.ps1 -SelfTest` — **26 assertions, all PASSING** — over the `netsh`
parser, the band classifier, the yes/no tristate, the VID:PID extractor and the StrictMode
counting helper; `host-vm.sh selftest` — **31 assertions, all PASSING** — over the step-7
allow-list, including every abbreviation and case variant a reviewer got past the first
version of that guard; `host-vm.sh doctor` for real against this Mac; every verb under
`--dry-run`, including a VMX path containing spaces and arguments containing spaces;
`guest-bootstrap.ps1`'s `-NatSubnet` validation across ten inputs; and the workspace link
checker both ways.

The self-test grew because running the code found two more instances of the same
`Set-StrictMode` `.Count` trap the first pass fixed once — and in the states that matter: with
**zero** devices attached the enumeration *threw* and the two passthrough checks silently
vanished from the output, and with **exactly one** device it reported the hashtable's key count
("7 COM device(s)").

**Correction, 2026-09-05.** An earlier draft of this paragraph said the obvious repair,
`@($x)`, could not fix the zero-device case, because `@($null).Count` is 1. That claim was
wrong and the sentence is withdrawn: an **empty pipeline** does not assign `$null`, it assigns
`[AutomationNull]::Value`, which `@()` wraps to an **empty** array — `@($x).Count` is **0**
(VERIFIED twice on this Mac, pwsh 7.7.0-preview.4: empty pipeline → 0, real `$null` → 1).
A plain `@($x)` would have worked for both guest states above. The shipped fix is still a
guarded helper, for the narrower and honest reason that a **real** `$null` — a hashtable field
never set, a cmdlet that returns `$null` instead of an empty pipeline — *does* wrap to a
one-element array and would report one device when none are attached. Its self-test pins all
three shapes separately: `$null` → 0, `@()` → 0, empty pipeline → 0.

**NOT executed, and nothing here claims otherwise:** every Windows-only cmdlet —
`Add-WindowsCapability`, `Get-Service sshd`, `New-NetFirewallRule`, `Disable-NetFirewallRule`,
`Get-LocalGroupMember`, `Get-CimInstance Win32_PnPEntity`, `netsh`, `icacls`, `msiexec` — and
every `vmrun`, `ssh` and `scp` call against a guest. `shellcheck` is not installed on this Mac,
so `host-vm.sh` has had `bash -n` and dry-runs only. A parse check does not run code; the
defects above are proof that only running it finds that class of bug, and the Windows half has
not been run.

---

## 3. Run sequence, mapped to scripts

A full sweep, in order (matches `run-all.ps1`'s own sequencing and skip logic — see
`w17-ground-station/scripts/windows-validation/README.md` for each script's full description):

| # | command (via `ssh w17vm`) | what it needs from you | evidence it produces |
|---|---|---|---|
| 0 | `scripts/vm/host-vm.sh revert clean-giftee-pc && scripts/vm/host-vm.sh start` | the VMX path (`W17_VMX`, quoted) | a known-clean starting state. Use the wrapper, not raw `vmrun`: `revert` powers the VM off first, and `start` is a no-op when it is already running — a raw `revertToSnapshot && start` chain fails with *"already powered on"* whenever the snapshot was taken live |
| 1 | `pwsh -File 00-inventory.ps1` | nothing | host survey JSON — confirm the Wi-Fi adapter, COM port, and DS4 all show up as expected BEFORE spending time on anything else |
| 2 | `pwsh -File 10-install-gs.ps1 -InstallerPath ...` | the installer, scp'd on first (§2.3) | install verified. **The meaning of a FAIL here has flipped, and this row used to say the opposite:** `boundaries-1` (and `boundaries-6`) are **CLOSED WITH EVIDENCE** on GS `main` — CI fetches mediamtx before packaging and `scripts/assert-packaged.js` gates it (`w17-ground-station/scripts/windows-validation/README.md:47`; `W17_CURRENT_STATE.md` §1, GS `b632409`, first green `windows-latest` run). A miss now is a **regression**, or something NSIS drops that CI's `dist\win-unpacked` assertion cannot see — not a known defect reproducing |
| 3 | `pwsh -File 20-mapper-stage.ps1 -MapperExe ... -Profile ...` | the mapper binary + profile, scp'd | racePrep staged into settings.json; FAILS if the profile still has `REPLACE-WITH-` placeholders (MAP-5) |
| 4 | `pwsh -File 30-hotspot.ps1 -InstallDir ... -Password ...` — **on a real x64 Windows PC, NOT on this VM** (§1.9) | the real hotspot password (never invented), the bought adapter, and an x64 host | hotspot start/verify/teardown through the app's own code. Run here it reports a clean "no usable hotspot backend" FAIL, because no ARM64 driver exists for any candidate chipset — that is the script working. **The adapter is not bought yet — see §0** |
| 5 | `pwsh -File 40-mdns-udp.ps1 -InstallDir ...` | nothing new | firewall state, a real mDNS query, a UDP 5601 replay-telemetry receive. Its **hotspot-interface half** belongs with row 4 on the x64 PC (§1.9); the rest runs here |
| 6 | `pwsh -File 50-race-day.ps1 -InstallDir ... -UserDataDir ...` | step 3 to have run; **car unpowered** (§3.1's MAP-8 note) | reproduces MAP-1 (mapper panic) if it still bites, plus MAP-8 port-reachability evidence while the mapper is briefly alive. MAP-2/SYN-2 reproduce **every** run and are recorded in `data.expectedFindingsReproduced` rather than the exit code — so a **FAIL here means something NEW**, not the finding we already know about |
| 7 | **⚠ read §3.1 FIRST** — (human present) `pwsh -File 60-hid-transition.ps1 -MapperExe ...` via `ssh -t`, mapper started by hand first | a human at the DS4 cable, **and the car unpowered / RX unbound** | Windows HID-transition + mapper-**process** continuity; MAP-6 code citation. **Not R15 evidence — R15 stays NO-GO** |
| — | `vmrun -T fusion stop "$VMX" soft` | | |

Or, for everything automatable in one call: `scripts/vm/host-vm.sh suite <params…>`, which runs
`run-all.ps1` with whichever parameters are available (see its own `.DESCRIPTION` — it skips,
never fails, a step it lacks parameters for). **`suite` forwards an allow-list of parameters
and exits 2 on anything else**, so `-IncludeHidTransition`, `-HidTransitionNonInteractive` and
every abbreviation PowerShell would bind to them (`-Inc`, `-Hid`, `--Inc`, `-hid:$true` …) are
all refused (§2.4); step 7 is opt-in only when `run-all.ps1` is invoked by hand, deliberately,
with §3.1 read first.

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

**One related note on the MAP-8 window (step 6), superseded by OD-8.** This used to say
that while `50-race-day.ps1` runs, the mapper's gRPC `:10000` was up, unauthenticated, on
**all interfaces** with reflection on, and that `StartLink` — the one RPC that opens the
COM port and transmits — was among the RPCs it exposed, with "the ground station has no
client that could [call it]" as the mitigating fact. Both premises are now stale: mapper
`5d4e12d` (MAP-8, owner decision OD-8a) made **`127.0.0.1` the default bind** for both the
gRPC and HTTP listeners — the wildcard only comes back if someone explicitly passes
`-bind-all`, which neither this runbook nor race day's argv whitelist ever does — and the
ground station is no longer client-less: it now runs **two read-only gRPC consumers**
against the mapper (`getTelemetryStream` via
`w17-ground-station/main/mapperTelemetryGrpcConnect.js:20`, and the link-state stream via
`main/MapperLinkStateClient.js`; the mutating RPC surface, including `StartLink`, is not in
either client's vocabulary — `main/mapperStreamsProto.js:8`). The safety conclusion is
**stronger** than the old paragraph claimed (loopback-only by default, not merely
unreached), but the stated premise (all-interfaces, no client) was false at this trunk. As
before, run step 6 on the **NAT'd VM**, with the car unpowered, rather than on a shared
network — that discipline does not depend on which premise is current.

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
- Whether the mapper's gRPC (`:10000`) and grpc-web (`:3000`) ports are reachable **from
  off-host** while the mapper is briefly alive (`MAP-8`). Since mapper `5d4e12d` (OD-8a) both
  listeners default to **`127.0.0.1`**, so the **expected finding is "not reachable"**; a
  reachable result is a regression or an unexpected `-bind-all` (§3.1). This bullet used to say
  "on all interfaces", which is the stale premise §3.1 exists to retract.
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

### 4.1 `evidence/` capture convention for VM sessions

One layout, so a later reader can tell **which run** a number came from and **what state the
guest was in** when it was produced. `scripts/vm/host-vm.sh` writes this shape on its own;
anything captured by hand goes in the same place, by the same rules.

```
evidence/
  .current-session                 # the open session's stamp; host-vm.sh check writes it
  <UTC stamp>/                     # 20260905T084500Z — one directory per SESSION
    guest-check.json               # host-vm.sh check   — readiness BEFORE anything is staged
    guest-bootstrap.json           # pulled by check when present — the record of the firewall
                                   #   scope, the authorized_keys ACL and the pwsh install
    results/                       # host-vm.sh suite — THIS run only (the guest's ResultsRoot
                                   #   is C:\w17\results\<UTC stamp>, one per session)
      <run stamp>.json             # run-all.ps1's combined table
      <run stamp>/00-inventory.json  # each numbered script's own envelope
      <run stamp>/10-install-gs.json
      ...
    screen-<UTC stamp>.png         # host-vm.sh screenshot — one per thing a human must eyeball
    NOTES.md                       # scaffolded by check; the four lines below are yours
```

The two stamps are different clocks and that is deliberate: the **outer** one is the Mac-side
session (UTC, `20260905T084500Z`), the **inner** one is `run-all.ps1`'s own
(`yyyyMMdd-HHmmss`, guest local). One outer directory therefore holds exactly one sweep's
results, and `guest-check.json` beside them.

**Rules, all four of which exist because their absence has cost a re-run somewhere:**

1. **One directory per session, named for the UTC instant it started.** Never overwrite a
   previous one; a re-run is a new directory. `host-vm.sh check` **opens** the session and
   records its stamp in `evidence/.current-session`; `suite` and `screenshot` reuse it, and
   `--session STAMP` pins it by hand. (Each of the three used to mint its own stamp, which put
   one session in three directories and quietly defeated rule 2.)
2. **`guest-check.json` is captured first, before anything is installed or staged.** It is the
   only record of what the guest looked like *un*modified — including whether passthrough
   landed. A results directory without it cannot be interpreted later. So **run `check`
   before `suite`**: that ordering is what makes rule 1's session pointer exist. `check` also
   pulls `guest-bootstrap.json` if the guest has one — that file, not the check output, is the
   record of the firewall scope and the ACL.
3. **Raw output is kept, not just the parse.** `guest-check.ps1` keeps `data.wlan.raw`, and
   `00-inventory.ps1` keeps its own `netsh` text, precisely because the locale and format of
   that output are `[win-TBD]`: if the parser is wrong, the evidence must still be readable.
4. **`NOTES.md` carries four lines, and a session is not finished without them** (`check`
   scaffolds the headings, it cannot fill them in): the snapshot
   the session started from (`clean-giftee-pc`, or which other); which artifacts were staged
   and **from which CI run** (§2.3); which USB devices were passed through; and which steps
   were **skipped**, with why. Steps skipped for a missing parameter are invisible in
   `run-all.ps1`'s exit code by design — it skips, never fails, a step it lacks parameters for.

**What goes in `CURRENT_STATUS.md` afterwards**, and what does not: the *conclusions* and the
evidence paths go there (it is the workspace's only file for gate status). The JSON and PNGs do
not — they stay under `evidence/`, which `.gitignore` keeps out of the repo. And no line in
either place may promote a VM result to a physical one: a green sweep is a Windows-software
fact. **A2 stays NOT-EXECUTED, Phase B stays BLOCKED, R15 stays NO-GO** (§0, §3.1, §5).

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

A green sweep also says **nothing at all** about the hotspot path: `30` and `40`'s hotspot half
are **not run on this VM** (§1.9 — no ARM64 driver exists for any candidate chipset). They are
an **x64 task**, on a separate machine, gated on the adapter purchase. A green VM sweep never
speaks to them, and must not be reported as if it did.

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
