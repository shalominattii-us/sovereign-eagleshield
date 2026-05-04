# sovereign-eagleshield

Government-grade Windows security hardening and SOC monitoring for SOVEREIGN.

## Structure

- `scripts/` — PowerShell hardening & monitoring scripts
- `configs/` — JSON manifests and compliance mappings
- `dashboard/` — Standalone HTML SOC dashboard

## Quick Deploy

```powershell
# Elevate and harden
.\scripts\EagleShield-Hardening.ps1

# Start real-time monitor
.\scripts\EagleShield-EventMonitor.ps1
```

## Dashboard

Open `dashboard/index.html` in any browser for live SOC view.
