#Requires -Version 7.0
<#
.SYNOPSIS
  Read-only readiness check for the W17 Windows validation guest.

.DESCRIPTION
  Answers one question: is this guest ready for the validation suite in
  w17-ground-station/scripts/windows-validation/, and did USB passthrough
  actually land? It changes nothing, and it is the pre-flight for that suite,
  not a duplicate of it:

    guest-check.ps1  -- is the ENVIRONMENT ready (pwsh, sshd, policy, Tools,
                        arch, and are the three USB devices visible)?
    00-inventory.ps1 -- the suite's own host survey, with the parsing and
                        result envelope the suite's other scripts share.

  They overlap on the Wi-Fi/COM/HID enumeration on purpose: this one runs
  BEFORE the suite is even staged, from scripts/vm/host-vm.sh check, so a
  missing passthrough or a missing pwsh is caught in one round trip instead
  of eight scripts failing one by one.

  Checks, each independently guarded so one failure never hides the rest:
    * Windows version, build, and PROCESSOR architecture (ARM64 expected on
      an Apple silicon Fusion guest; the GS installer and mapper are x64 and
      run under emulation -- runbook 1.9);
    * pwsh >= 7.4, and WHERE it resolves from (a per-user MSIX alias resolves
      for an interactive shell and not for machine-context tooling);
    * execution policy per scope;
    * sshd service state, plus the scope of any inbound rule on TCP/22;
    * VMware Tools service;
    * COM ports with VID:PID -- the ELRS TX rides an FT232RL (FTDI VID 0403),
      flagged when seen. READ-ONLY ENUMERATION: no port is ever opened;
    * DualShock 4 HID presence by VID:PID;
    * Wi-Fi drivers via `netsh wlan show drivers`: hosted-network support,
      Wi-Fi Direct / Wireless Display support, and the radio types listed,
      from which a 5 GHz hint (never a proof -- a driver string is not an
      observed radio) is derived.

.NOTES
  SAFETY (workspace CLAUDE.md rules 1-7). Read-only. No serial port is
  opened, nothing is flashed or powered, no control path is created. A green
  run here is a Windows-software fact and nothing more: A2 stays
  NOT-EXECUTED, Phase B stays BLOCKED, R15 stays NO-GO.

  Every value this script cannot observe is emitted as $null with a reason
  next to it. Nothing is invented.

.PARAMETER EvidencePath
  Where to write the JSON evidence. Default C:\w17\evidence\guest-check.json.

.PARAMETER Quiet
  Suppress the human-readable table; still writes the JSON and still prints
  the single W17VM_CHECK: line.

.PARAMETER SelfTest
  Run the pure parsers in this file against built-in fixtures and exit. Works
  on any platform (this is the only part of the script that can be executed
  off Windows) and asserts nothing about a guest.

.EXAMPLE
  ssh w17vm 'pwsh -NoProfile -File C:\w17\scripts\vm\guest-check.ps1'

.EXAMPLE
  pwsh -NoProfile -File scripts/vm/guest-check.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [string] $EvidencePath = 'C:\w17\evidence\guest-check.json',
    [switch] $Quiet,
    [switch] $SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The suite's own floor is `#Requires -Version 7.0`; 7.4 is the current LTS
# line and what this check demands so a guest is not left on an out-of-support
# 7.0-7.3 build.
$script:MinPwsh = [version]'7.4'

# ---------------------------------------------------------------------------
# PURE PARSERS -- no cmdlets, no platform assumptions, unit-testable anywhere.
# ---------------------------------------------------------------------------

# `netsh wlan show drivers` prints one block per adapter. The block header is
# an UNINDENTED "Interface name: <name>"; every field inside it is INDENTED.
# (00-inventory.ps1 documents the same shape and the bug of assuming a "Name:"
# line -- `show drivers` has no such line, that belongs to `show interfaces`.)
function ConvertFrom-W17WlanDriverText {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Text)

    $adapters = New-Object System.Collections.ArrayList
    $current = $null
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -notmatch '^(\s*)([^:]+?)\s*:\s*(.*)$') { continue }
        $indent = $Matches[1]
        $label = $Matches[2].Trim()
        $value = $Matches[3].Trim()

        if ($indent.Length -eq 0) {
            if ($label -match '^(Interface name|Schnittstellenname|Nom de l.interface)$') {
                if ($null -ne $current) { [void]$adapters.Add($current) }
                $current = [ordered]@{
                    interfaceName          = $value
                    driverDescription      = $null
                    hostedNetworkSupported = $null
                    wifiDirectSupported    = $null
                    radioTypesSupported    = $null
                    radioTypes             = @()
                    likely5GHzCapable      = $null
                    bandWhy                = 'no radio-type line seen'
                }
            }
            continue
        }
        if ($null -eq $current) { continue }

        switch -Regex ($label) {
            '^(Description|Beschreibung)$' {
                if (-not $current.driverDescription) { $current.driverDescription = $value }
            }
            'Hosted network' {
                $current.hostedNetworkSupported = ConvertTo-W17Tristate $value
            }
            'Wi-?Fi Direct' {
                # Several distinct "Wi-Fi Direct <role> Supported" lines exist;
                # any one of them saying yes means the driver advertises it.
                $v = ConvertTo-W17Tristate $value
                if ($v -eq $true) { $current.wifiDirectSupported = $true }
                elseif ($null -eq $current.wifiDirectSupported) { $current.wifiDirectSupported = $v }
            }
            'Radio types supported' {
                $current.radioTypesSupported = $value
                $band = Get-W17BandClass $value
                $current.radioTypes = $band.tokens
                $current.likely5GHzCapable = $band.likely5GHzCapable
                $current.bandWhy = $band.why
            }
        }
    }
    if ($null -ne $current) { [void]$adapters.Add($current) }
    , @($adapters)
}

function ConvertTo-W17Tristate {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Value)
    if ($Value -match '^(Yes|Ja|Oui|S[ií])\b') { return $true }
    if ($Value -match '^(No|Nein|Non)\b') { return $false }
    $null
}

# A radio-type list is a HINT about band capability, never an observation of a
# radio. 802.11a/ac/ax/be define 5 GHz (or 5/6 GHz) modes; b/g are 2.4 GHz
# only; n is dual-band-capable and therefore says nothing on its own.
function Get-W17BandClass {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Value)
    # @() is load-bearing under Set-StrictMode: a pipeline yielding exactly one
    # match returns a bare [string], and $tokens.Count then throws rather than
    # returning 1. Caught by the self-test's single-token cases.
    $tokens = @([regex]::Matches($Value, '802\.11\s*([abgnacxeAX]+)') |
            ForEach-Object { '802.11' + $_.Groups[1].Value.ToLowerInvariant() } |
            Select-Object -Unique)
    if ($tokens.Count -eq 0) {
        return @{ tokens = @(); likely5GHzCapable = $null; why = 'no 802.11 PHY token found' }
    }
    $fiveOnly = @($tokens | Where-Object { $_ -in @('802.11a', '802.11ac') })
    $fiveHint = @($tokens | Where-Object { $_ -in @('802.11ax', '802.11be') })
    $twoOnly = @($tokens | Where-Object { $_ -in @('802.11b', '802.11g') })
    if ($fiveOnly.Count -gt 0) {
        return @{ tokens = $tokens; likely5GHzCapable = $true; why = "5 GHz PHY listed: $($fiveOnly -join ',')" }
    }
    if ($fiveHint.Count -gt 0) {
        return @{ tokens = $tokens; likely5GHzCapable = $true; why = "5/6 GHz-capable PHY listed: $($fiveHint -join ',') (also defines 2.4 GHz modes -- hint, not proof)" }
    }
    if ($twoOnly.Count -gt 0) {
        return @{ tokens = $tokens; likely5GHzCapable = $false; why = "only 2.4 GHz PHYs listed: $($twoOnly -join ',')" }
    }
    @{ tokens = $tokens; likely5GHzCapable = $null; why = "band-ambiguous PHYs only: $($tokens -join ',')" }
}

# PNPDeviceID -> VID/PID. Returns $nulls rather than throwing on a non-USB id.
function Get-W17VidPid {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $PnpDeviceId)
    $m = [regex]::Match($PnpDeviceId, 'VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})')
    if (-not $m.Success) { return @{ vid = $null; pid = $null } }
    @{ vid = $m.Groups[1].Value.ToUpperInvariant(); pid = $m.Groups[2].Value.ToUpperInvariant() }
}

# ---------------------------------------------------------------------------
# SELF-TEST (the only executable-off-Windows part of this file)
# ---------------------------------------------------------------------------
if ($SelfTest) {
    $fails = 0
    function Assert-Eq {
        param($Expected, $Actual, [string] $What)
        $e = if ($null -eq $Expected) { '<null>' } else { "$Expected" }
        $a = if ($null -eq $Actual) { '<null>' } else { "$Actual" }
        if ($e -eq $a) { Write-Host "  ok   $What" }
        else { Write-Host "  FAIL $What -- expected '$e', got '$a'"; $script:fails++ }
    }

    $fixtureEn = @'
Interface name: Wi-Fi

    Driver                    : W17 Test 802.11ac USB Adapter
    Vendor                    : W17
    Description               : W17 Test 802.11ac USB Adapter
    Hosted network supported  : Yes
    Radio types supported     : 802.11b 802.11g 802.11n 802.11ac
    Wi-Fi Direct Device Supported : Yes

Interface name: Wi-Fi 2

    Driver                    : Legacy 2.4 GHz Dongle
    Description               : Legacy 2.4 GHz Dongle
    Hosted network supported  : No
    Radio types supported     : 802.11b 802.11g
    Wi-Fi Direct Device Supported : No
'@

    Write-Host 'ConvertFrom-W17WlanDriverText (EN, two adapters):'
    $parsed = ConvertFrom-W17WlanDriverText -Text $fixtureEn
    Assert-Eq 2 $parsed.Count 'adapter count'
    Assert-Eq 'Wi-Fi' $parsed[0].interfaceName 'adapter 0 interface name'
    Assert-Eq $true $parsed[0].hostedNetworkSupported 'adapter 0 hosted network'
    Assert-Eq $true $parsed[0].likely5GHzCapable 'adapter 0 5 GHz hint'
    Assert-Eq $true $parsed[0].wifiDirectSupported 'adapter 0 Wi-Fi Direct'
    Assert-Eq $false $parsed[1].hostedNetworkSupported 'adapter 1 hosted network'
    Assert-Eq $false $parsed[1].likely5GHzCapable 'adapter 1 5 GHz hint'

    Write-Host 'ConvertFrom-W17WlanDriverText (empty / no wireless interface):'
    Assert-Eq 0 (ConvertFrom-W17WlanDriverText -Text '').Count 'empty text -> no adapters'

    Write-Host 'Get-W17BandClass:'
    Assert-Eq $null (Get-W17BandClass '802.11n').likely5GHzCapable 'n alone is band-ambiguous'
    Assert-Eq $true (Get-W17BandClass '802.11a 802.11n').likely5GHzCapable 'a implies 5 GHz'
    Assert-Eq $null (Get-W17BandClass 'not a phy list').likely5GHzCapable 'garbage -> null, not a guess'

    Write-Host 'ConvertTo-W17Tristate:'
    Assert-Eq $true (ConvertTo-W17Tristate 'Yes') 'Yes'
    Assert-Eq $false (ConvertTo-W17Tristate 'No') 'No'
    Assert-Eq $null (ConvertTo-W17Tristate 'Nicht verfuegbar') 'unknown word -> null'

    Write-Host 'Get-W17VidPid:'
    Assert-Eq '0403' (Get-W17VidPid 'USB\VID_0403&PID_6001\A50285BI').vid 'FT232RL vid'
    Assert-Eq '6001' (Get-W17VidPid 'USB\VID_0403&PID_6001\A50285BI').pid 'FT232RL pid'
    Assert-Eq $null (Get-W17VidPid 'ACPI\PNP0501\1').vid 'non-USB id -> null, not a throw'

    Write-Host ''
    if ($script:fails -gt 0) { Write-Host "SELF-TEST FAILED ($script:fails)"; exit 1 }
    Write-Host 'SELF-TEST PASSED'
    exit 0
}

# ---------------------------------------------------------------------------
# LIVE CHECKS (Windows only)
# ---------------------------------------------------------------------------
$isWin = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
if (-not $isWin) {
    Write-Host 'guest-check.ps1 inspects a Windows guest. On this platform only'
    Write-Host '-SelfTest can run. Nothing was checked and nothing was written.'
    exit 3
}

$notes = New-Object System.Collections.ArrayList
$checks = New-Object System.Collections.ArrayList
$data = [ordered]@{}

# Add-Check records a named verdict. $Ok = $null means UNKNOWN, which is
# never rendered as a pass.
function Add-Check {
    param(
        [Parameter(Mandatory)][string] $Name,
        [AllowNull()][object] $Ok,
        [Parameter(Mandatory)][string] $Detail,
        [switch] $Advisory      # informational: never fails the run
    )
    [void]$checks.Add([ordered]@{
            name = $Name; ok = $Ok; advisory = [bool]$Advisory; detail = $Detail
        })
}

function Invoke-Guarded {
    param([Parameter(Mandatory)][string] $What, [Parameter(Mandatory)][scriptblock] $Body)
    try { & $Body } catch { [void]$notes.Add("$What failed: $($_.Exception.Message)") }
}

# --- OS / architecture -------------------------------------------------------
Invoke-Guarded 'os' {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    # PROCESSOR_ARCHITECTURE reports the *process* architecture; an x64 shell
    # emulated on ARM64 reports AMD64 and sets PROCESSOR_ARCHITEW6432. Report
    # both so an emulated pwsh can never be mistaken for a native one.
    $data.os = [ordered]@{
        caption          = $os.Caption
        version          = $os.Version
        buildNumber      = $os.BuildNumber
        osArchitecture   = $os.OSArchitecture
        processArch      = $env:PROCESSOR_ARCHITECTURE
        nativeArch       = $env:PROCESSOR_ARCHITEW6432   # set only under emulation
        manufacturer     = $cs.Manufacturer
        model            = $cs.Model
        totalMemoryBytes = $cs.TotalPhysicalMemory
        logicalProcessors = $cs.NumberOfLogicalProcessors
    }
    $arm = ($os.OSArchitecture -match 'ARM') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') -or ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64')
    Add-Check 'windows-arm64' $arm -Advisory ("OSArchitecture='$($os.OSArchitecture)'. ARM64 is expected on an Apple silicon Fusion guest; the ground-station installer and the mapper are x64 and run under emulation (runbook 1.9). NOT a failure either way.")
    Add-Check 'windows-build' $true "$($os.Caption) build $($os.BuildNumber)"
}

# --- PowerShell 7 ------------------------------------------------------------
Invoke-Guarded 'pwsh' {
    $running = $PSVersionTable.PSVersion
    $machineExe = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    $resolved = (Get-Command pwsh -ErrorAction SilentlyContinue)
    $data.powershell = [ordered]@{
        runningVersion     = $running.ToString()
        runningExe         = (Get-Process -Id $PID).Path
        resolvedOnPath     = if ($resolved) { $resolved.Source } else { $null }
        machineInstallExe  = if (Test-Path -LiteralPath $machineExe) { $machineExe } else { $null }
        edition            = $PSVersionTable.PSEdition
    }
    Add-Check 'pwsh-version' ($running -ge $script:MinPwsh) "running $running (need >= $($script:MinPwsh); the validation suite's own floor is 7.0)"
    if (-not (Test-Path -LiteralPath $machineExe)) {
        Add-Check 'pwsh-machine-install' $false ("no C:\Program Files\PowerShell\7\pwsh.exe. pwsh resolved from " +
            "'$(if ($resolved) { $resolved.Source } else { '<nowhere>' })'. A winget MSIX install puts pwsh on a PER-USER " +
            'path only; install the ARM64 MSI so machine-context and other accounts resolve it too (runbook 1.6).')
    } else {
        Add-Check 'pwsh-machine-install' $true $machineExe
    }
}

# --- execution policy --------------------------------------------------------
Invoke-Guarded 'execution-policy' {
    $pol = Get-ExecutionPolicy -List | ForEach-Object {
        [ordered]@{ scope = "$($_.Scope)"; policy = "$($_.ExecutionPolicy)" }
    }
    $data.executionPolicy = @($pol)
    $eff = Get-ExecutionPolicy
    # `pwsh -File` runs a script from disk, so an effective Restricted /
    # AllSigned policy blocks the whole suite. RemoteSigned or Bypass is fine;
    # files copied by scp are not mark-of-the-web tagged, but say so rather
    # than relying on it.
    Add-Check 'execution-policy' ($eff -in @('RemoteSigned', 'Unrestricted', 'Bypass')) "effective policy '$eff' (Restricted/AllSigned would block `pwsh -File`)"
}

# --- sshd + its firewall scope ----------------------------------------------
Invoke-Guarded 'sshd' {
    $svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
    $startMode = if ($svc) { (Get-CimInstance Win32_Service -Filter "Name='sshd'").StartMode } else { $null }
    $data.sshd = [ordered]@{
        present   = [bool]$svc
        status    = if ($svc) { "$($svc.Status)" } else { $null }
        startMode = "$startMode"
    }
    Add-Check 'sshd-running' ($svc -and $svc.Status -eq 'Running') "service sshd: $(if ($svc) { "$($svc.Status), start=$startMode" } else { 'not installed' })"
}

Invoke-Guarded 'firewall-22' {
    $rules = Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction Stop |
        Where-Object {
            $ports = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
            $ports -and ($ports.LocalPort -contains '22' -or $ports.LocalPort -contains 22)
        }
    $data.inboundRulesOnPort22 = @($rules | ForEach-Object {
            $addr = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
            [ordered]@{
                name          = $_.Name
                displayName   = $_.DisplayName
                profile       = "$($_.Profile)"
                remoteAddress = if ($addr) { @($addr.RemoteAddress) } else { @() }
            }
        })
    $wide = @($data.inboundRulesOnPort22 | Where-Object {
            $_.profile -match 'Any|Public' -or $_.remoteAddress -contains 'Any'
        })
    # ADVISORY, not a gate: an unscoped rule is a posture problem worth
    # naming, but it is not what stops the suite from running.
    Add-Check 'sshd-firewall-scope' ($wide.Count -eq 0) -Advisory ("$($data.inboundRulesOnPort22.Count) enabled inbound rule(s) on TCP/22; " +
        "$($wide.Count) of them unscoped (Any/Public). This guest raises its OWN SoftAP during 30-hotspot.ps1 -- " +
        'an unscoped sshd rule follows it onto that interface (runbook 1.5).')
    $data.firewallProfiles = @(Get-NetFirewallProfile | ForEach-Object {
            [ordered]@{ name = "$($_.Name)"; enabled = [bool]$_.Enabled; inboundAction = "$($_.DefaultInboundAction)" }
        })
}

# --- VMware Tools ------------------------------------------------------------
Invoke-Guarded 'vmware-tools' {
    $tools = Get-Service -Name 'VMTools', 'VMwareCAFCommAmqpListener' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    $data.vmwareTools = [ordered]@{
        present = [bool]$tools
        status  = if ($tools) { "$($tools.Status)" } else { $null }
    }
    Add-Check 'vmware-tools' ($tools -and $tools.Status -eq 'Running') -Advisory ("VMTools service: $(if ($tools) { $tools.Status } else { 'absent' }). " +
        'Needed for `vmrun captureScreen`, getGuestIPAddress and graceful shutdown. On macOS 26 the ' +
        "Install VMware Tools menu item is greyed out -- install the ISO from Broadcom's package portal instead (runbook 1.4).")
}

# --- COM ports (READ-ONLY enumeration; no port is opened) --------------------
Invoke-Guarded 'com-ports' {
    $ports = Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.Name -match '\(COM\d+\)' -or $_.PNPClass -eq 'Ports' } |
        ForEach-Object {
            $vp = Get-W17VidPid $_.PNPDeviceID
            [ordered]@{
                name    = $_.Name
                com     = ([regex]::Match($_.Name, '\(COM(\d+)\)')).Groups[1].Value
                vid     = $vp.vid
                pid     = $vp.pid
                status  = $_.Status
                problem = $_.ConfigManagerErrorCode
                isFtdi  = ($vp.vid -eq '0403')
            }
        }
    $data.comPorts = @($ports)
    $ftdi = @($ports | Where-Object { $_.isFtdi })
    # The ELRS TX handset reaches the PC through the GCS box's FT232RL
    # USB-UART (w17-gcs-box-guide.md:44, HARDWARE_INVENTORY.md:77); FTDI's
    # USB vendor id is 0403 and the FT232R's default product id 6001. The
    # ELRS module itself has NO PC driver -- Windows only ever sees this
    # serial adapter (w17-giftee-pc-install-guide.md:43-48).
    Add-Check 'elrs-tx-serial-visible' ($ftdi.Count -gt 0) -Advisory ("$($ports.Count) COM device(s), $($ftdi.Count) with FTDI VID 0403. " +
        'Zero is expected until the GCS box is passed through to this VM (runbook 1.8). No port was opened.')
}

# --- DualShock 4 HID ---------------------------------------------------------
Invoke-Guarded 'ds4' {
    # 054C:05C4 first-gen DS4, 054C:09CC second-gen, 054C:0BA0 the USB dongle.
    $ds4 = Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.PNPDeviceID -match 'VID_054C&PID_(05C4|09CC|0BA0)' } |
        ForEach-Object {
            $vp = Get-W17VidPid $_.PNPDeviceID
            [ordered]@{ name = $_.Name; vid = $vp.vid; pid = $vp.pid; class = $_.PNPClass; status = $_.Status }
        }
    $data.dualShock4Devices = @($ds4)
    Add-Check 'dualshock4-visible' ($ds4.Count -gt 0) -Advisory ("$($ds4.Count) DualShock 4 device node(s). " +
        'USB is the sure path for VM testing -- a Bluetooth pad pairs to the GUEST Bluetooth stack, which a Fusion ' +
        'guest on Apple silicon does not get (runbook 1.11). Note the pad id differs between USB and Bluetooth ' +
        '(w17-mapper/configs/README.md).')
}

# --- Wi-Fi drivers -----------------------------------------------------------
Invoke-Guarded 'wlan' {
    $raw = (& netsh.exe wlan show drivers 2>&1 | Out-String)
    $adapters = ConvertFrom-W17WlanDriverText -Text $raw
    $data.wlan = [ordered]@{
        raw      = $raw          # kept verbatim: locale/format is [win-TBD]
        adapters = @($adapters)
    }
    $hosted = @($adapters | Where-Object { $_.hostedNetworkSupported -eq $true })
    $fiveGhz = @($adapters | Where-Object { $_.likely5GHzCapable -eq $true })
    Add-Check 'wifi-hosted-network' ($hosted.Count -gt 0) -Advisory ("$($adapters.Count) Wi-Fi driver(s); $($hosted.Count) advertise hosted-network support, " +
        "$($fiveGhz.Count) list a 5 GHz PHY. A driver string is a HINT, not an observed radio. The AP-capable 5 GHz " +
        'adapter is NOT BOUGHT YET and its ARM64 driver is unknown (runbook 0 and 1.9), so 0/0 here is the expected ' +
        'answer today and is not a defect.')
    Invoke-Guarded 'wlan-interfaces' {
        $data.wlanInterfacesRaw = (& netsh.exe wlan show interfaces 2>&1 | Out-String)
    }
}

# --- verdict -----------------------------------------------------------------
$gating = @($checks | Where-Object { -not $_.advisory })
$failed = @($gating | Where-Object { $_.ok -ne $true })
$result = [ordered]@{
    script    = 'guest-check'
    ok        = ($failed.Count -eq 0)
    summary   = "$($gating.Count - $failed.Count)/$($gating.Count) gating checks passed; $(@($checks | Where-Object { $_.advisory }).Count) advisory"
    checks    = @($checks)
    data      = $data
    notes     = @($notes)
    machine   = $env:COMPUTERNAME
    utc       = (Get-Date).ToUniversalTime().ToString('o')
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host '=== W17 guest check ==='
    foreach ($c in $checks) {
        $tag = if ($c.advisory) { 'INFO' } elseif ($c.ok -eq $true) { 'PASS' } elseif ($null -eq $c.ok) { 'UNKN' } else { 'FAIL' }
        Write-Host ("{0}  {1,-26} {2}" -f $tag, $c.name, $c.detail)
    }
    foreach ($n in $notes) { Write-Host "NOTE  $n" }
    Write-Host ''
    Write-Host $result.summary
}

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $EvidencePath) | Out-Null
    [System.IO.File]::WriteAllText($EvidencePath,
        (($result | ConvertTo-Json -Depth 12) + [Environment]::NewLine),
        (New-Object System.Text.UTF8Encoding $false))
    Write-Host "evidence: $EvidencePath"
} catch {
    Write-Host "  (could not write evidence file: $($_.Exception.Message))"
}

# One compact machine-readable line, through [Console]::Out for the same
# reason lib/common.ps1 does it: Write-Output would be captured by the
# `exit (...)` idiom and never reach stdout.
[Console]::Out.WriteLine('W17VM_CHECK: ' + ($result | ConvertTo-Json -Depth 12 -Compress))

if ($failed.Count -gt 0) { exit 1 }
exit 0
