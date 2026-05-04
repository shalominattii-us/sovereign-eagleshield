#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Real-time security event monitor for Eagle Shield SOC.
#>
param(
    [string]$OutputDir = "C:\EagleShield\forensics",
    [int]$PollSeconds = 30
)

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$signatures = @{
    "BruteForce" = @{ LogName='Security'; ID=4625; Threshold=5; WindowMinutes=5 }
    "PrivEsc"    = @{ LogName='Security'; ID=4673,4674; Threshold=3; WindowMinutes=10 }
    "Malware"    = @{ LogName='System';   ID=1001,1015; Threshold=2; WindowMinutes=60 }
    "Lateral"    = @{ LogName='Security'; ID=4648,4624; Threshold=10; WindowMinutes=15 }
}

$timestamps = @{}

while ($true) {
    Clear-Host
    Write-Host "EAGLE SHIELD EVENT MONITOR — $(Get-Date)" -ForegroundColor Cyan
    Write-Host "─" * 60

    foreach ($name in $signatures.Keys) {
        $sig = $signatures[$name]
        $startTime = (Get-Date).AddMinutes(-$sig.WindowMinutes)
        try {
            $events = Get-WinEvent -FilterHashtable @{
                LogName = $sig.LogName
                ID = $sig.ID
                StartTime = $startTime
            } -ErrorAction SilentlyContinue
        } catch { $events = @() }

        $count = ($events | Measure-Object).Count
        $status = if ($count -ge $sig.Threshold) { "ALERT" } else { "OK" }
        Write-Host "$status [$name] Count: $count / Threshold: $($sig.Threshold)"

        if ($count -ge $sig.Threshold) {
            $file = Join-Path $OutputDir "$name`_$(Get-Date -Format yyyyMMdd_HHmmss).csv"
            $events | Select-Object TimeCreated, Id, LevelDisplayName, Message |
                Export-Csv -Path $file -NoTypeInformation
            Write-Host "    -> Exported to $file" -ForegroundColor Yellow
        }
    }

    Write-Host "─" * 60
    Write-Host "Sleeping $PollSeconds seconds... (Ctrl+C to stop)"
    Start-Sleep -Seconds $PollSeconds
}
