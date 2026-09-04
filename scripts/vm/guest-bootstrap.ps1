#Requires -Version 5.1
<#
.SYNOPSIS
  One-time, elevated setup of the W17 Windows validation guest.

.DESCRIPTION
  Turns a freshly installed Windows 11 (Arm64) guest into the machine the
  W17 validation suite can be driven against over SSH from the Mac. It does
  exactly four things, each idempotent:

    1. installs and starts the Windows inbox OpenSSH Server;
    2. places the Mac's public key in the CORRECT authorized_keys file for
       the account -- administrators and ordinary users use DIFFERENT files
       under Windows OpenSSH, and the admin one needs its ACL tightened or
       sshd silently refuses it;
    3. creates ONE scoped inbound firewall rule for sshd -- Private profile,
       and only from the Fusion NAT subnet you name -- AND disables Windows'
       own inbox 'OpenSSH Server' rule group, which is UNSCOPED (any remote
       address) and silently re-opens what the scoped rule narrows;
    4. installs PowerShell 7 (the whole validation suite is
       `#Requires -Version 7.0`; Windows 11 ships only 5.1).

  It then PRINTS the snapshot instruction; it cannot take the snapshot,
  which is a host-side `vmrun` action (scripts/vm/host-vm.sh snapshot).

  This script itself runs under Windows PowerShell 5.1 on purpose: it is what
  installs pwsh 7, so it cannot require it.

.NOTES
  SAFETY (workspace CLAUDE.md rules 1-7). Nothing here flashes, powers, or
  connects hardware; no serial port is opened; nothing touches CRSF, servos,
  the gimbal, or the ESC. Nothing here discharges A2, Phase B, R15, or any
  FIRST_ACTIVE unlock item -- a configured VM is a Windows-software target,
  never physical proof.

  FIREWALL SCOPE IS DELIBERATE. The rule is Private-profile only and
  restricted to the NAT subnet you pass. Do not widen it: during
  30-hotspot.ps1 this same guest raises its OWN SoftAP interface, and that
  interface is exactly where an unauthenticated service must not appear
  (runbook 1.5, MAP-8 / boundaries-3).

  -Profile Private is NOT isolation on its own -- Windows commonly classifies
  a hosted-network/SoftAP adapter as Private too. The RemoteAddress scope is
  the only thing keeping sshd off that interface, which is why -NatSubnet is
  validated as an actual RFC1918 /16../30 range and not merely CIDR-SHAPED.

  Installing the OpenSSH.Server capability also installs Windows' own
  'OpenSSH Server' firewall rule group, which is unscoped. An earlier version
  only REPORTED it, tagged 'skipped' -- a tag that reads as "nothing to do"
  and never touched the exit code, so the scoped rule above was decorative.
  This script now disables those rules once the scoped one is in place. If it
  cannot (or -KeepInboxOpenSshRule is given) the step is 'action-required'
  and the script exits 4: configured, but a posture action is OUTSTANDING.

  DEFAULT SHELL IS LEFT ALONE. Windows OpenSSH runs cmd.exe as the login
  shell. That is why every documented invocation is
  `ssh w17vm 'pwsh -NoProfile -File C:\...\x.ps1 -Param value'` -- cmd passes
  backslash paths through unchanged. Repointing the default shell at pwsh
  changes the quoting rules for every command in the runbook, so this script
  does not do it.

.PARAMETER NatSubnet
  The Fusion NAT subnet the Mac reaches this guest on, in CIDR form, e.g.
  192.168.230.0/24. Read it from `ipconfig` in the guest or Fusion's own VM
  network settings pane. There is no default: an invented subnet would
  either lock you out or silently widen the rule.

.PARAMETER PublicKeyPath
  Path to the Mac's public key file (w17vm_ed25519.pub) staged on the guest.

.PARAMETER PublicKey
  The public key as a literal string, as an alternative to -PublicKeyPath.

.PARAMETER SshUser
  The Windows account that will LOG IN over ssh -- the `User` line in the Mac's
  ~/.ssh/config, which `host-vm.sh bootstrap` passes automatically. Windows
  OpenSSH picks the authorized_keys file from THAT account's group membership,
  not from whoever is running this elevated script. Defaults to $env:USERNAME,
  correct only when they are the same account (the normal case after runbook
  1.0 step 5). Getting it wrong produces the silent password prompt 1.5 warns
  about.

.PARAMETER KeepInboxOpenSshRule
  Do NOT disable Windows' own unscoped 'OpenSSH Server' firewall rules. The
  script then reports 'action-required' and exits 4 rather than pretending the
  one-scoped-rule property holds.

.PARAMETER PwshMsiPath
  Path to a locally staged PowerShell 7 ARM64 MSI. PREFERRED over winget on
  this guest: the MSI installs to C:\Program Files\PowerShell\7\pwsh.exe and
  puts that on the MACHINE PATH, which a non-interactive `ssh host 'pwsh ...'`
  resolves. winget 1.11+ installs the MSIX by default, whose `pwsh` is an app
  execution alias under %LOCALAPPDATA%\Microsoft\WindowsApps -- a per-user
  path that is present for the SSH user but absent for any other account and
  for machine-context tooling.

.PARAMETER SkipPwsh
  Do not install PowerShell 7 (only sensible if it is already installed).

.PARAMETER EvidencePath
  Where to write the JSON record of what this run did. Default:
  C:\w17\evidence\guest-bootstrap.json

.PARAMETER DryRun
  Report what each step WOULD do and change nothing.

.EXAMPLE
  # powershell.exe (5.1), NOT pwsh: this script is what INSTALLS pwsh 7.
  powershell -ExecutionPolicy Bypass -File guest-bootstrap.ps1 `
       -NatSubnet 192.168.230.0/24 `
       -PublicKeyPath C:\w17\scripts\vm\w17vm.pub `
       -PwshMsiPath C:\w17\dist\PowerShell-7.6.5-win-arm64.msi `
       -SshUser w17
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$')]
    [string] $NatSubnet,

    [string] $PublicKeyPath,
    [string] $PublicKey,
    [string] $SshUser = $env:USERNAME,
    [string] $PwshMsiPath,
    [switch] $SkipPwsh,
    [switch] $KeepInboxOpenSshRule,
    [string] $EvidencePath = 'C:\w17\evidence\guest-bootstrap.json',
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The ValidatePattern above checks the SHAPE of a CIDR string and nothing
# more: it happily admits 0.0.0.0/0, 0.0.0.0/1 and 999.999.999.999/99. A typo
# or a copied example would then widen the sshd rule onto every interface this
# guest ever raises -- including the SoftAP 30-hotspot.ps1 creates, which is
# the one place the runbook (1.5) says an unauthenticated service must not
# appear. -Profile Private does not save you: Windows classifies a SoftAP
# adapter as Private too. So the SCOPE is validated here, before anything is
# created.
$octets = [int[]]($NatSubnet.Split('/')[0].Split('.'))
$prefix = [int]$NatSubnet.Split('/')[1]
if (@($octets | Where-Object { $_ -gt 255 }).Count -gt 0) {
    throw "invalid IPv4 in -NatSubnet: $NatSubnet"
}
if ($prefix -lt 16 -or $prefix -gt 30) {
    throw "-NatSubnet prefix /$prefix is out of range. A Fusion NAT segment is a /24. Anything wider than /16 would put sshd on every interface this guest ever raises, including the SoftAP that 30-hotspot.ps1 creates (runbook 1.5)."
}
if (-not ($octets[0] -eq 10 -or
          ($octets[0] -eq 172 -and $octets[1] -ge 16 -and $octets[1] -le 31) -or
          ($octets[0] -eq 192 -and $octets[1] -eq 168))) {
    throw "-NatSubnet must be an RFC1918 private range (10/8, 172.16/12, 192.168/16); got $NatSubnet. Read it from ``ipconfig`` in the guest, or from Fusion's VM network settings pane."
}

$script:Steps = New-Object System.Collections.ArrayList
$script:Failed = $false
$script:ActionRequired = $false

function Add-Step {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][ValidateSet('changed', 'already', 'skipped', 'action-required', 'failed', 'would-change')][string] $State,
        [string] $Detail = ''
    )
    [void]$script:Steps.Add([ordered]@{ step = $Name; state = $State; detail = $Detail })
    $tag = switch ($State) {
        'changed'      { 'CHANGED ' }
        'already'      { 'ALREADY ' }
        'skipped'      { 'SKIPPED ' }
        'action-required' { 'ACTION  ' }
        'failed'       { 'FAILED  ' }
        'would-change' { 'WOULD   ' }
    }
    Write-Host "$tag$Name$(if ($Detail) { " -- $Detail" })"
    if ($State -eq 'failed') { $script:Failed = $true }
    # Distinct from both SKIPPED (nothing to do) and FAILED (setup broken):
    # everything is configured, but a POSTURE action is outstanding. Exit 4.
    if ($State -eq 'action-required') { $script:ActionRequired = $true }
}

function Test-Elevated {
    if (-not $IsWindowsHost) { return $false }
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# $IsWindows exists only on PowerShell 6+; under 5.1 the platform is Windows
# by definition. A separate name avoids assigning to the automatic variable.
$IsWindowsHost = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }

Write-Host '=== W17 guest bootstrap ==='
Write-Host "  NAT subnet   : $NatSubnet"
Write-Host "  ssh login    : $SshUser"
Write-Host "  dry run      : $([bool]$DryRun)"
Write-Host ''

if (-not $IsWindowsHost) {
    Write-Host 'This script configures a Windows guest and does nothing on any other'
    Write-Host 'platform. On macOS/Linux it can only be parse-checked, not run.'
    exit 3
}

if (-not (Test-Elevated)) {
    Write-Host 'REFUSING: this script must run ELEVATED (Run as administrator).'
    Write-Host 'Adding a Windows capability, a service, and a firewall rule all'
    Write-Host 'require it, and a half-applied bootstrap is worse than none.'
    exit 2
}

# --- 1. OpenSSH Server -------------------------------------------------------
try {
    $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
        Select-Object -First 1
    if ($null -eq $cap) {
        # Without this, $cap.Name below throws under StrictMode and surfaces
        # as an opaque "You cannot call a method on a null-valued expression".
        Add-Step 'openssh-server-capability' 'failed' "this Windows image offers no OpenSSH.Server capability (Get-WindowsCapability -Online -Name 'OpenSSH.Server*' returned nothing). Check the image and Windows Update -- the whole autonomous-drive design (runbook 2.2) needs sshd."
    } elseif ($cap.State -eq 'Installed') {
        Add-Step 'openssh-server-capability' 'already' $cap.Name
    } elseif ($DryRun) {
        Add-Step 'openssh-server-capability' 'would-change' "would Add-WindowsCapability $($cap.Name)"
    } else {
        Add-WindowsCapability -Online -Name $cap.Name | Out-Null
        Add-Step 'openssh-server-capability' 'changed' $cap.Name
    }
} catch {
    Add-Step 'openssh-server-capability' 'failed' $_.Exception.Message
}

try {
    $svc = Get-Service -Name sshd -ErrorAction Stop
    $wantStart = $svc.Status -ne 'Running'
    $wantAuto = (Get-CimInstance Win32_Service -Filter "Name='sshd'").StartMode -ne 'Auto'
    if (-not $wantStart -and -not $wantAuto) {
        Add-Step 'sshd-service' 'already' 'running, StartupType Automatic'
    } elseif ($DryRun) {
        Add-Step 'sshd-service' 'would-change' 'would Set-Service -StartupType Automatic and Start-Service'
    } else {
        Set-Service -Name sshd -StartupType Automatic
        if ($wantStart) { Start-Service sshd }
        Add-Step 'sshd-service' 'changed' 'running, StartupType Automatic'
    }
} catch {
    Add-Step 'sshd-service' 'failed' "sshd service not present: $($_.Exception.Message)"
}

# --- 2. authorized_keys, admin vs ordinary user ------------------------------
# Windows OpenSSH reads administrators_authorized_keys (a SINGLE shared file)
# for any account in the local Administrators group, and ignores that account's
# own ~/.ssh/authorized_keys. It also REFUSES either file whose ACL grants
# write access beyond Administrators + SYSTEM, silently falling back to
# password auth. Both facts are why this step is scripted rather than
# described in prose.
$keyText = $null
if ($PublicKey) {
    $keyText = $PublicKey.Trim()
} elseif ($PublicKeyPath) {
    if (Test-Path -LiteralPath $PublicKeyPath) {
        $keyText = ((Get-Content -LiteralPath $PublicKeyPath -Raw) -split "`n" |
            Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
    } else {
        Add-Step 'authorized-keys' 'failed' "public key file not found: $PublicKeyPath"
    }
}

if (-not $keyText) {
    if (-not $script:Failed) { Add-Step 'authorized-keys' 'skipped' 'no -PublicKey / -PublicKeyPath given' }
} elseif ($keyText -notmatch '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-\S+|sk-ssh-ed25519@openssh\.com)\s+\S+') {
    Add-Step 'authorized-keys' 'failed' 'the value given does not look like an OpenSSH public key (a PRIVATE key must never be copied to the guest)'
} else {
    try {
        # WHICH FILE? sshd picks it from the LOGIN account's group membership.
        # This script is guaranteed elevated (Test-Elevated ran), so
        # [WindowsIdentity]::GetCurrent() describes whoever RAN it -- which
        # under the normal UAC flow from a standard account is an ADMIN while
        # the ssh User is not. Keying off it wrote the key into
        # administrators_authorized_keys, which sshd does not read for a
        # non-admin login: the silent password prompt runbook 1.5 warns about,
        # produced by the very script written to prevent it. Resolve
        # -SshUser's group membership instead, and print which file and why.
        $isAdminAccount = $null
        $howResolved = ''
        $shortUser = $SshUser.Split('\')[-1]
        try {
            $admins = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop)
            $isAdminAccount = @($admins | Where-Object {
                    $_.Name -eq $SshUser -or $_.Name.Split('\')[-1] -eq $shortUser
                }).Count -gt 0
            $howResolved = "resolved from the Administrators group for '$SshUser'"
        } catch {
            # No Get-LocalGroupMember, or a domain/Entra oddity: fall back to
            # the running identity and SAY SO rather than guessing silently.
            $me = [Security.Principal.WindowsIdentity]::GetCurrent()
            $isAdminAccount = (New-Object Security.Principal.WindowsPrincipal($me)).IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator)
            $howResolved = "FALLBACK -- could not enumerate Administrators ($($_.Exception.Message)); used the ELEVATED identity '$($me.Name)', which is right only if it is also the ssh login account"
        }

        if ($isAdminAccount) {
            $akPath = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
            $akKind = "administrators_authorized_keys -- '$SshUser' is an administrator ($howResolved)"
        } else {
            $profileDir = Join-Path (Split-Path -Parent $env:USERPROFILE) $shortUser
            if (-not (Test-Path -LiteralPath $profileDir)) { $profileDir = $env:USERPROFILE }
            $akPath = Join-Path $profileDir '.ssh\authorized_keys'
            $akKind = "per-user authorized_keys for '$SshUser' ($howResolved)"
        }

        $existing = if (Test-Path -LiteralPath $akPath) { Get-Content -LiteralPath $akPath } else { @() }
        if ($existing -contains $keyText) {
            Add-Step 'authorized-keys' 'already' "$akKind already contains this key ($akPath)"
        } elseif ($DryRun) {
            Add-Step 'authorized-keys' 'would-change' "would append the key to $akPath and reset its ACL"
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $akPath) | Out-Null
            # UTF8 without BOM, LF-tolerant: sshd parses a BOM as part of the
            # key type and rejects the line.
            $lines = @($existing | Where-Object { $_.Trim() }) + $keyText
            [System.IO.File]::WriteAllLines($akPath, $lines, (New-Object System.Text.UTF8Encoding $false))

            if ($isAdminAccount) {
                # Required ACL: Administrators + SYSTEM only, inheritance off.
                & icacls.exe $akPath /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' | Out-Null
            } else {
                & icacls.exe $akPath /inheritance:r /grant "${shortUser}:F" /grant '*S-1-5-18:F' | Out-Null
            }
            Add-Step 'authorized-keys' 'changed' "$akKind at $akPath (ACL tightened)"
        }
    } catch {
        Add-Step 'authorized-keys' 'failed' $_.Exception.Message
    }
}

# --- 3. Scoped firewall rule for sshd ---------------------------------------
try {
    $ruleName = 'W17-sshd'
    $existingRule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    $desired = @{
        Name          = $ruleName
        DisplayName   = 'OpenSSH Server (sshd) -- W17 validation, NAT subnet only'
        Enabled       = 'True'
        Direction     = 'Inbound'
        Protocol      = 'TCP'
        Action        = 'Allow'
        LocalPort     = 22
        Profile       = 'Private'
        RemoteAddress = $NatSubnet
    }
    if ($existingRule) {
        $addr = (Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $existingRule).RemoteAddress
        if ("$addr" -eq $NatSubnet -and "$($existingRule.Profile)" -eq 'Private') {
            Add-Step 'firewall-sshd' 'already' "$ruleName Private/$NatSubnet"
        } elseif ($DryRun) {
            Add-Step 'firewall-sshd' 'would-change' "would re-scope $ruleName to Private/$NatSubnet (currently $($existingRule.Profile)/$addr)"
        } else {
            Set-NetFirewallRule -Name $ruleName -Profile Private -RemoteAddress $NatSubnet -Enabled True | Out-Null
            Add-Step 'firewall-sshd' 'changed' "re-scoped $ruleName to Private/$NatSubnet"
        }
    } elseif ($DryRun) {
        Add-Step 'firewall-sshd' 'would-change' "would create $ruleName Private/$NatSubnet TCP/22"
    } else {
        New-NetFirewallRule @desired | Out-Null
        Add-Step 'firewall-sshd' 'changed' "$ruleName Private/$NatSubnet TCP/22"
    }

    # Installing the OpenSSH.Server capability brings Windows' OWN rule group
    # with it, and that one is UNSCOPED (any remote address). While it is
    # enabled, W17-sshd's narrow scope is decorative: sshd is reachable from
    # every interface the guest raises, including the SoftAP 30-hotspot.ps1
    # creates. Nothing used to disable it -- the step was tagged 'skipped',
    # which reads as "nothing to do" and never touched the exit code, and 1.0
    # step 14 told the owner INFO lines were expected to be unmet. So: disable
    # it, AFTER the scoped rule above exists, so this can never lock the Mac
    # out of the NAT subnet.
    $inbox = @(Get-NetFirewallRule -DisplayGroup 'OpenSSH Server' -ErrorAction SilentlyContinue |
        Where-Object { $_.Enabled -eq 'True' })
    $inboxNames = ($inbox | ForEach-Object { $_.Name }) -join ', '
    if ($inbox.Count -eq 0) {
        Add-Step 'firewall-inbox-openssh-rule' 'already' "no enabled unscoped 'OpenSSH Server' inbox rule -- only the scoped W17-sshd rule reaches TCP/22"
    } elseif ($KeepInboxOpenSshRule) {
        Add-Step 'firewall-inbox-openssh-rule' 'action-required' ("-KeepInboxOpenSshRule given, so Windows' UNSCOPED 'OpenSSH Server' rule(s) stay ENABLED ($inboxNames). " +
            'They widen what W17-sshd narrows, onto every interface including the SoftAP 30-hotspot.ps1 raises (runbook 1.5). ' +
            "Disable them with: Get-NetFirewallRule -DisplayGroup 'OpenSSH Server' | Disable-NetFirewallRule")
    } elseif ($DryRun) {
        Add-Step 'firewall-inbox-openssh-rule' 'would-change' "would disable Windows' unscoped 'OpenSSH Server' rule(s): $inboxNames"
    } else {
        try {
            $inbox | Disable-NetFirewallRule -ErrorAction Stop
            $stillOn = @(Get-NetFirewallRule -DisplayGroup 'OpenSSH Server' -ErrorAction SilentlyContinue |
                Where-Object { $_.Enabled -eq 'True' })
            if ($stillOn.Count -eq 0) {
                Add-Step 'firewall-inbox-openssh-rule' 'changed' "disabled Windows' unscoped 'OpenSSH Server' rule(s) ($inboxNames) -- only the scoped W17-sshd rule now reaches TCP/22"
            } else {
                Add-Step 'firewall-inbox-openssh-rule' 'action-required' ("tried to disable Windows' unscoped 'OpenSSH Server' rule(s), but $($stillOn.Count) are still ENABLED (" +
                    (($stillOn | ForEach-Object { $_.Name }) -join ', ') +
                    '). Group Policy can re-enable them. Disable them by hand, then re-run this script.')
            }
        } catch {
            Add-Step 'firewall-inbox-openssh-rule' 'action-required' ("could not disable Windows' unscoped 'OpenSSH Server' rule(s) ($inboxNames): $($_.Exception.Message). " +
                "Disable them by hand: Get-NetFirewallRule -DisplayGroup 'OpenSSH Server' | Disable-NetFirewallRule")
        }
    }
} catch {
    Add-Step 'firewall-sshd' 'failed' $_.Exception.Message
}

# --- 4. PowerShell 7 ---------------------------------------------------------
if ($SkipPwsh) {
    Add-Step 'powershell-7' 'skipped' '-SkipPwsh given'
} else {
    try {
        $pwshExe = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
        $found = Get-Command pwsh -ErrorAction SilentlyContinue
        if ((Test-Path -LiteralPath $pwshExe) -or $found) {
            $where = if (Test-Path -LiteralPath $pwshExe) { $pwshExe } else { $found.Source }
            $ver = (& $where -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') 2>$null
            Add-Step 'powershell-7' 'already' "$where ($ver)"
        } elseif ($DryRun) {
            Add-Step 'powershell-7' 'would-change' $(if ($PwshMsiPath) { "would msiexec /i $PwshMsiPath" } else { 'would winget install Microsoft.PowerShell' })
        } elseif ($PwshMsiPath) {
            if (-not (Test-Path -LiteralPath $PwshMsiPath)) { throw "MSI not found: $PwshMsiPath" }
            $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList @(
                '/i', "`"$PwshMsiPath`"", '/qn', '/norestart',
                'ADD_PATH=1', 'ENABLE_PSREMOTING=0', 'REGISTER_MANIFEST=1')
            if ($p.ExitCode -ne 0) { throw "msiexec exited $($p.ExitCode)" }
            Add-Step 'powershell-7' 'changed' "installed from $PwshMsiPath"
        } else {
            Add-Step 'powershell-7' 'skipped' 'no -PwshMsiPath. Prefer the ARM64 MSI (see .PARAMETER PwshMsiPath); winget''s MSIX puts pwsh only on a per-user PATH.'
        }
    } catch {
        Add-Step 'powershell-7' 'failed' $_.Exception.Message
    }
}

# --- record + next step ------------------------------------------------------
$result = [ordered]@{
    script  = 'guest-bootstrap'
    ok      = (-not $script:Failed)
    actionRequired = $script:ActionRequired
    dryRun  = [bool]$DryRun
    subnet  = $NatSubnet
    sshUser = $SshUser
    steps   = @($script:Steps)
    machine = $env:COMPUTERNAME
    utc     = (Get-Date).ToUniversalTime().ToString('o')
}
try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $EvidencePath) | Out-Null
    [System.IO.File]::WriteAllText($EvidencePath,
        (($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
        (New-Object System.Text.UTF8Encoding $false))
    Write-Host ''
    Write-Host "evidence: $EvidencePath"
} catch {
    Write-Host "  (could not write evidence file: $($_.Exception.Message))"
}

Write-Host ''
if ($script:Failed) {
    Write-Host 'RESULT: FAILED -- fix the FAILED lines above and re-run (this script is idempotent).'
    exit 1
}
if ($script:ActionRequired) {
    Write-Host 'RESULT: ACTION REQUIRED (exit 4) -- everything is configured, but the'
    Write-Host 'ACTION line(s) above are a POSTURE problem, not a cosmetic note: sshd is'
    Write-Host 'still reachable from every interface this guest raises, including the'
    Write-Host 'SoftAP 30-hotspot.ps1 creates (runbook 1.5). Do what the line says, then'
    Write-Host 're-run this script. guest-check.ps1 GATES on this.'
    exit 4
}
Write-Host 'RESULT: OK'
Write-Host ''
Write-Host 'NEXT, in this order:'
Write-Host '  1. From the Mac:  ssh -F ~/.ssh/config w17vm whoami'
Write-Host '     It must succeed with NO password prompt before you go on.'
Write-Host '  2. Verify the guest:  scripts/vm/host-vm.sh check'
Write-Host '  3. THEN take the baseline snapshot, from the MAC (a snapshot is a'
Write-Host '     host-side action -- this script cannot take one). POWER THE VM'
Write-Host '     OFF FIRST: a live snapshot writes an ~8 GB memory image onto'
Write-Host '     the disk that is this program''s hardest blocker, and reverting'
Write-Host '     to it restores a powered-ON VM. host-vm.sh snapshot REFUSES a'
Write-Host '     running VM for that reason (runbook 1.0 step 15, 1.7):'
Write-Host '        scripts/vm/host-vm.sh stop'
Write-Host '        scripts/vm/host-vm.sh snapshot clean-giftee-pc'
Write-Host '     Take it BEFORE the first 10-install-gs.ps1 run (runbook 1.7);'
Write-Host '     it is the revert target every later validation session starts from.'
