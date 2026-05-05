# Eagle Shield Hardening
param([switch]$Full, [switch]$SOC2)
function Log($m){Write-Host $m -ForegroundColor Cyan}
Log '=== Eagle Shield Hardening ==='
$svcs = @('Spooler','Fax','DiagTrack','dmwappushservice')
foreach($s in $svcs){Set-Service $s -StartupType Disabled -EA SilentlyContinue; Stop-Service $s -Force -EA SilentlyContinue; Log "Disabled $s"}
if($Full){netsh advfirewall set allprofiles state on; netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound; netsh advfirewall firewall add rule name=SOVEREIGN dir=in action=allow protocol=tcp localport=8443,7946; Log 'Firewall locked'}
if($SOC2){auditpol /set /subcategory:'Logon' /success:enable /failure:enable; auditpol /set /subcategory:'Account Logon' /success:enable /failure:enable; Log 'SOC2 audit on'}
Log '=== Hardening Complete ==='
