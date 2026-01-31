<#
.SYNOPSIS
    Script for removing Fireflies.ai from user's Outlook, Teams, and system.

.DESCRIPTION
    Adds:
    - Pre-flight scanner
    - Footprint reporting
    - Confirmation prompt (default No)
    - DryRun mode

.NOTES
    Filename: RemoveFirefliesaiFromOutlook.ps1
    Author: Patrick Costa with Copilot
    Modified: 01/29/2026
#>

param(
    [switch]$DryRun
)

function Invoke-Action {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Host "[DryRun] $Description"
        Write-Host "         This action would be performed:"
        Write-Host "         $($Action.ToString())"
    } else {
        Write-Host $Description
        & $Action
    }
}

Write-Host "=== Fireflies.ai Removal Script ==="
if ($DryRun) { Write-Host "Running in DRY RUN mode — no changes will be made." }

# ---------------------------------------------------------
# Pre-flight Scan
# ---------------------------------------------------------

$footprints = @{}

# Service
$svc = Get-Service -Name "Fireflies*" -ErrorAction SilentlyContinue
if ($svc) { $footprints["Service"] = $svc.Name }

# Scheduled Tasks
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -match "Fireflies" }
if ($tasks) { $footprints["ScheduledTasks"] = $tasks.TaskName }

# Outlook Add-in
$addinOutlook = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Office\16.0\Wef" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match "Fireflies" }
if ($addinOutlook) { $footprints["OutlookAddin"] = $addinOutlook.Name }

# Teams Add-in
$addinTeams = Get-ChildItem "$env:APPDATA\Microsoft\Teams\Addins" -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -match "Fireflies" }
if ($addinTeams) { $footprints["TeamsAddin"] = $addinTeams.Name }

# Program Files
$programFiles = @(
    "$env:LOCALAPPDATA\Programs\fireflies*",
    "$env:LOCALAPPDATA\fireflies*",
    "$env:APPDATA\fireflies*"
) | ForEach-Object { Get-ChildItem $_ -ErrorAction SilentlyContinue }

if ($programFiles) { $footprints["ProgramFiles"] = $programFiles.FullName }

# Registry
$regPaths = @(
    "HKCU:\Software\Microsoft\Office\Outlook\Addins",
    "HKCU:\Software\Microsoft\Office\Teams\Addins",
    "HKCU:\Software",
    "HKLM:\Software",
    "HKLM:\Software\WOW6432Node"
)

$regHits = foreach ($path in $regPaths) {
    Get-ChildItem $path -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Fireflies" }
}

if ($regHits) { $footprints["Registry"] = $regHits.Name }

# ---------------------------------------------------------
# Report Findings
# ---------------------------------------------------------

if ($footprints.Count -eq 0) {
    Write-Host "No Fireflies.ai footprints detected."
    if ($DryRun) { Write-Host "DryRun complete." }
    return
}

Write-Host ""
Write-Host "Fireflies.ai footprints detected:"
foreach ($key in $footprints.Keys) {
    Write-Host " - $key"
}

Write-Host ""
$choice = Read-Host "Continue with uninstall? (Y/N) [Default: N]"

if ($choice -ne "Y" -and $choice -ne "y") {
    Write-Host "Uninstall canceled."
    return
}

Write-Host ""
Write-Host "Proceeding with uninstall..."
Write-Host ""

# ---------------------------------------------------------
# Stop and remove Fireflies service
# ---------------------------------------------------------
Invoke-Action "Stopping Fireflies services..." {
    $svc = Get-Service -Name "Fireflies*" -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        sc.exe delete $svc.Name | Out-Null
    }
}

# ---------------------------------------------------------
# Remove scheduled tasks
# ---------------------------------------------------------
Invoke-Action "Removing scheduled tasks..." {
    Get-ScheduledTask |
        Where-Object { $_.TaskName -match "Fireflies" } |
        Unregister-ScheduledTask -Confirm:$false
}

# ---------------------------------------------------------
# Remove Outlook add-ins
# ---------------------------------------------------------
Invoke-Action "Removing Outlook add-ins..." {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Office\16.0\Wef\Fireflies*" -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------
# Remove Teams add-ins
# ---------------------------------------------------------
Invoke-Action "Removing Teams add-ins..." {
    Remove-Item "$env:APPDATA\Microsoft\Teams\Addins\Fireflies*" -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------
# Remove program files
# ---------------------------------------------------------
Invoke-Action "Removing Fireflies program files..." {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\fireflies*",
        "$env:LOCALAPPDATA\fireflies*",
        "$env:APPDATA\fireflies*"
    )

    foreach ($p in $paths) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------
# Clean registry entries
# ---------------------------------------------------------
Invoke-Action "Cleaning registry entries..." {
    $regPaths = @(
        "HKCU:\Software\Microsoft\Office\Outlook\Addins\Fireflies*",
        "HKCU:\Software\Microsoft\Office\Teams\Addins\Fireflies*",
        "HKCU:\Software\Fireflies*",
        "HKLM:\Software\Fireflies*",
        "HKLM:\Software\WOW6432Node\Fireflies*"
    )

    foreach ($reg in $regPaths) {
        Remove-Item $reg -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Fireflies.ai removal process complete."
if ($DryRun) {
    Write-Host "DryRun mode: No changes were made."
} else {
    Write-Host "Reboot recommended."
}