# offsite-backup.ps1 - 3rd copy of the homelab restic repos on this Windows PC
#  - Pulls NEW snapshots from ShiNAS's rest-reader (append-only, LAN-only, port 8501)
#      shinas         = Vaultwarden, Immich, Authentik
#      shineoriserver = Dawarich, Karakeep, Paperless, addy, Uptime Kuma, sites
#  - Stores them in its OWN repo (own password) in iCloud Drive\Backups\restic-offsite (synced off-site by iCloud)
#  - Same retention as the NAS (7 daily / 4 weekly / 12 monthly = 1 year) so copy doesn't re-pull old ones
#  - Prunes + verifies 5% of the data on Sundays; Discord alert if anything fails
$ErrorActionPreference = 'Stop'

$Base   = 'C:\Backups'
$Keys   = "$Base\keys"
$Nas    = '<nas-lan-ip>:8501'                  # rest-reader on the NAS
$Repos  = @('shinas', 'shineoriserver')               # each needs keys\<name>.pass
$Log    = "$Base\logs\offsite-$(Get-Date -Format yyyy-MM).log"

$Restic = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\restic.exe"
if (-not (Test-Path $Restic)) {                     # winget sometimes skips the shortcut: use newest installed exe
  $Restic = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\restic.restic_*\restic_*.exe" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
  if (-not $Restic) { throw 'restic not found, reinstall with: winget install restic.restic' }
}

$env:RESTIC_REPOSITORY    = 'C:\Users\shineori\iCloudDrive\Backups\restic-offsite'   # pinned "Always keep on this device"; iCloud uploads it
$env:RESTIC_PASSWORD_FILE = "$Keys\offsite.pass"
$env:RESTIC_CACHE_DIR     = "$Base\cache"
$env:RESTIC_PROGRESS_FPS  = '0.016'                   # ~1 progress line/min in the log, not spam

function Log($msg) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Tee-Object -FilePath $Log -Append }

function Notify($msg) {                                # webhook lives in a locked file, never in this script
  $hook = "$Keys\discord-webhook.txt"
  if (-not (Test-Path $hook)) { return }
  try {
    $body = @{ content = $msg } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri (Get-Content $hook -Raw).Trim() -Method Post -ContentType 'application/json; charset=utf-8' `
      -Body ([Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
  } catch { Log "WARN: Discord alert failed: $_" }
}

function Run-Restic([string[]]$ResticArgs) {
  $ErrorActionPreference = 'Continue'               # PS 5.1: restic's stderr must not count as a crash
  & $Restic @ResticArgs 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $Log -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "restic $($ResticArgs[0]) exited with code $LASTEXITCODE" }
}

try {
  Log '== offsite backup start'

  # 0) All the keys present?
  $needed = @("$Keys\offsite.pass", "$Keys\rest-reader.pass") + ($Repos | ForEach-Object { "$Keys\$_.pass" })
  $missing = $needed | Where-Object { -not (Test-Path $_) -or (Get-Item $_).Length -eq 0 }
  if ($missing) { throw "missing password file(s): $($missing -join ', ')" }
  $reader = (Get-Content "$Keys\rest-reader.pass" -Raw).Trim()

  # iCloud signed out / folder gone? Stop instead of quietly writing somewhere unsynced
  if (-not (Test-Path (Split-Path $env:RESTIC_REPOSITORY))) { throw "iCloud Drive folder not found: $(Split-Path $env:RESTIC_REPOSITORY)" }

  # 1) Create the PC repo on the very first run
  if (-not (Test-Path "$env:RESTIC_REPOSITORY\config")) {
    $env:RESTIC_FROM_REPOSITORY    = "rest:http://windows-pc:$reader@$Nas/$($Repos[0])/"
    $env:RESTIC_FROM_PASSWORD_FILE = "$Keys\$($Repos[0]).pass"
    Log 'creating new repo (first run)'
    Run-Restic @('init', '--copy-chunker-params')       # same chunking as the NAS = better dedup
  }

  # 2) Pull new snapshots from each NAS repo
  foreach ($r in $Repos) {
    $env:RESTIC_FROM_REPOSITORY    = "rest:http://windows-pc:$reader@$Nas/$r/"
    $env:RESTIC_FROM_PASSWORD_FILE = "$Keys\$r.pass"
    Log "copying from $r"
    Run-Restic @('copy')
  }
  Remove-Item Env:RESTIC_FROM_REPOSITORY, Env:RESTIC_FROM_PASSWORD_FILE -ErrorAction SilentlyContinue

  # 3) Weekly (Sundays): retention matching the NAS, prune, verify 5% of the data
  #    (weekly, not daily: the NAS also prunes weekly, so daily forgets here would just get re-copied)
  if ((Get-Date).DayOfWeek -eq 'Sunday') {
    Log 'weekly forget + prune + check'
    Run-Restic @('forget', '--group-by', 'host,tags', '--keep-daily', '7', '--keep-weekly', '4', '--keep-monthly', '12')
    Run-Restic @('prune')
    Run-Restic @('check', '--read-data-subset=5%')
  }

  Log '== offsite backup OK'
}
catch {
  Log "ERROR: $_"
  Notify "$([char]::ConvertFromUtf32(0x274C)) **PC offsite backup FAILED**: $_ (log: $Log)"
  exit 1
}
