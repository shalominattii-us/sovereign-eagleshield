#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Eagle Shield — Government-grade Windows hardening (SOC 2 Type II aligned)
.DESCRIPTION
    Hardens ROG Ally X / Windows 11 workstation for SOC compliance.
    Run as Administrator.
#>
param(
    [string]$LogPath = "C:\EagleShield\logs\hardening_$(Get-Date -Format yyyyMMdd_HHmmss).log",
    [switch]$AuditOnly
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
function Write-Log($msg) {
    $line = "[$(Get-Date -Format o)] $msg"
    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

Write-Log "=== EAGLE SHIELD HARDENING STARTED ==="

$servicesToDisable = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "XblAuthManager", "XblGameSave", "XboxNetApiSvc")
foreach ($svc in $servicesToDisable) {
    try {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Log "Disabled service: $svc"
    } catch { Write-Log "WARN: Could not disable $svc" }
}

Write-Log "Hardening Windows Defender..."
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableArchiveScanning $false
Set-MpPreference -DisableRemovableDriveScanning $false
Set-MpPreference -EnableControlledFolderAccess Enabled
Set-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 -AttackSurfaceReductionRules_Actions Enabled
Write-Log "Defender hardened."

Write-Log "Configuring Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow -Enabled True
Write-Log "Firewall locked down."

Write-Log "Enabling advanced audit policies..."
auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Object Access" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Policy Change" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Process Tracking" /success:enable /failure:enable | Out-Null
Write-Log "Audit policies enabled."

Write-Log "Applying registry hardening..."
$regSettings = @{
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
        "EnableLUA" = 1
        "ConsentPromptBehaviorAdmin" = 2
        "PromptOnSecureDesktop" = 1
    }
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" = @{
        "DisableBehaviorMonitoring" = 0
        "DisableOnAccessProtection" = 0
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" = @{
        "LimitBlankPasswordUse" = 1
        "AuditBaseObjects" = 1
    }
}
foreach ($path in $regSettings.Keys) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    foreach ($name in $regSettings[$path].Keys) {
        Set-ItemProperty -Path $path -Name $name -Value $regSettings[$path][$name] -Type DWord -Force
    }
}
Write-Log "Registry hardened."

Write-Log "Maximizing UAC..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2

Write-Log "Disabling SMBv1..."
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
Write-Log "SMBv1 disabled."

Write-Log "=== EAGLE SHIELD HARDENING COMPLETE ==="
Write-Log "Log saved to: $LogPath"
