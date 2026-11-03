# Copies the cloud server's save (public.db) to this PC: Documents\HelloBro-cloud-backups\hellobro-public-<date>.db, keeps 30 days.
# Runs every day by the scheduled task "Hello Bro cloud backup" (and when you log on, if the PC was off at that time).
#   powershell -ExecutionPolicy Bypass -File tools\vps\backup-to-pc.ps1            copy now
#   powershell -ExecutionPolicy Bypass -File tools\vps\backup-to-pc.ps1 -Install   make the scheduled task
# To use a backup: stop the cloud server, put the file back as /opt/hellobro/public.db (see docs/CLOUD-SERVER.md).
param([switch]$Install)
$Dest = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'HelloBro-cloud-backups'
$Key = Join-Path $HOME '.ssh\hellobro-oracle.key'
$Server = 'ubuntu@ninjaonline.duckdns.org'
$Keep = 30
$Ssh = "$env:SystemRoot\System32\OpenSSH\ssh.exe"; $Scp = "$env:SystemRoot\System32\OpenSSH\scp.exe"
$Opts = @('-i', $Key, '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=accept-new', '-o', 'ConnectTimeout=30')

if ($Install) {
  $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $when = @((New-ScheduledTaskTrigger -Daily -At 13:00), (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME))
  $set = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
  Register-ScheduledTask -TaskName 'Hello Bro cloud backup' -Action $act -Trigger $when -Settings $set -Force | Out-Null
  Write-Host "Scheduled: every day at 13:00 and at log-on. Backups go to $Dest"
  exit
}

New-Item -ItemType Directory -Force $Dest | Out-Null
$Log = Join-Path $Dest 'backup.log'
function Say($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm')  $m" | Add-Content $Log; Write-Host $m }
$File = Join-Path $Dest ("hellobro-public-{0}.db" -f (Get-Date -Format 'yyyy-MM-dd'))
$Tmp = "$File.part"
& $Ssh @Opts $Server 'sudo sh /opt/hellobro/tools/vps/snapshot.sh' 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Say "FAILED: the cloud server could not make a copy (is it on? exit $LASTEXITCODE)"; exit 1 }
& $Scp @Opts -q "${Server}:/tmp/hellobro-snapshot.db" $Tmp 2>&1 | Out-Null
$ok = $LASTEXITCODE -eq 0 -and (Test-Path $Tmp) -and (Get-Item $Tmp).Length -gt 4096
& $Ssh @Opts $Server 'rm -f /tmp/hellobro-snapshot.db' 2>&1 | Out-Null
if ($ok) {
  $head = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($Tmp), 0, 15)
  $ok = $head -eq 'SQLite format 3'
}
if (-not $ok) { Remove-Item $Tmp -ErrorAction SilentlyContinue; Say 'FAILED: the download did not arrive whole'; exit 1 }
Move-Item -Force $Tmp $File
Get-ChildItem $Dest -Filter 'hellobro-public-*.db' | Sort-Object Name -Descending | Select-Object -Skip $Keep | Remove-Item
Say ("OK  {0}  {1:N0} KB" -f (Split-Path $File -Leaf), ((Get-Item $File).Length / 1KB))
