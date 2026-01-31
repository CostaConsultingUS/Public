<#
.SYNOPSIS
    Script for uninstalling apps from workstations.
    Script also disables services.

.DESCRIPTION
    Removes AppX packages, provisioned packages, optional features,
    and selected applications. Also disables Hyper-V services and
    removes OneDrive.

.NOTES
    Filename: RemoveBloat.ps1
    Author: Patrick Costa
    Modified: 2022-03-16

    Version 2.1
    - Fixed AppX array syntax
    - Fixed Hyper-V service disable loop
    - Cleaned unused/commented blocks
    - Ensured no vendor identifiers
#>

# -------------------------------
# AppX / Provisioned Packages
# -------------------------------

# Remove these AppX packages (delete from array to keep)
$AppPackages = @(
    'news',
    'Microsoft.todos',
    'microsoftteams',
    'Microsoft.GamingApp',
    'Microsoft.WindowsSoundRecorder',
    'office',
    'photos',
    'WindowsStore',
    'xbox',
    'skype',
    'zune',
    'Stickynotes',
    'camera',
    'wallet',
    'phone',
    'weather',
    'getstarted',
    'Solitaire',
    'MixedReality.Portal',
    'Maps',
    'storepurchaseapp',
    'groove',
    'microsoft.windowscommunicationsapp',
    'people',
    'feedback',
    'GetHelp',
    'Microsoft.soundrecorder',
    'Microsoft.549981C3F5F10'
)

# Remove provisioned packages (future users)
foreach ($app in $AppPackages) {
    Get-ProvisionedAppxPackage -Online |
        Where-Object { $_.PackageName -match $app } |
        ForEach-Object {
            Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName
        }
}

# -------------------------------
# Remove OneDrive
# -------------------------------
Start-Process "C:\Windows\SysWOW64\OneDriveSetup.exe" "/uninstall"

# -------------------------------
# Disable Hyper-V
# -------------------------------
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart

$allHV = Get-Service *HyperV* -ErrorAction SilentlyContinue

foreach ($HVService in $allHV) {
    Stop-Service -Name $HVService.Name -Force -ErrorAction SilentlyContinue
    Set-Service -Name $HVService.Name -StartupType Disabled
}

# -------------------------------
# Boot Timeout
# -------------------------------
bcdedit /timeout 5

# -------------------------------
# Final Message
# -------------------------------
Write-Host "Reboot and validate BIOS settings"