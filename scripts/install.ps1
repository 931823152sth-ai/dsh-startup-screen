param(
  [switch]$Uninstall
)
$ErrorActionPreference = "Stop"

$name       = "dsh-startup-screen"
$repoRoot   = Split-Path -Parent $PSScriptRoot
$profileDir = Join-Path $env:USERPROFILE ".dsh\profiles\desktop"
$dest       = Join-Path $profileDir ("node_modules\" + $name)
$patch      = Join-Path $profileDir "cordis.patch.yml"
$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$utf8       = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $profileDir)) {
  Write-Host "DSH desktop profile not found: $profileDir"
  Write-Host "Run DeepSeek Harness once, then try again."
  exit 1
}

if ($Uninstall) {
  if (Test-Path $dest) {
    Remove-Item $dest -Recurse -Force
    Write-Host "removed plugin: $dest"
  }
  if (Test-Path $patch) {
    Copy-Item $patch ($patch + ".bak-" + $stamp) -Force
    $lines = [System.IO.File]::ReadAllLines($patch)
    $keep  = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^\s*- insert:\s*$' -and ($i + 2) -lt $lines.Count -and
          $lines[$i + 1] -match 'id:\s*startup-screen') {
        $i += 2
        continue
      }
      if ($lines[$i] -match 'dsh-startup-screen') { continue }
      $keep.Add($lines[$i])
    }
    [System.IO.File]::WriteAllLines($patch, $keep, $utf8)
    Write-Host "unregistered startup-screen row from cordis.patch.yml"
  }
  Write-Host "done. fully quit and relaunch DeepSeek Harness."
  exit 0
}

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $repoRoot "package.json")      $dest -Force
Copy-Item (Join-Path $repoRoot "cordis.patch.yml")  $dest -Force
Copy-Item (Join-Path $repoRoot "dsh")               (Join-Path $dest "dsh") -Recurse -Force
Write-Host "installed plugin: $dest"

if (-not (Test-Path $patch)) { [System.IO.File]::WriteAllText($patch, "", $utf8) }
$content = [System.IO.File]::ReadAllText($patch)
if ($content -notmatch 'dsh-startup-screen') {
  Copy-Item $patch ($patch + ".bak-" + $stamp) -Force
  $block = "`r`n# Startup screen (dsh-startup-screen) - delete these 4 lines to disable.`r`n" +
           "- insert:`r`n" +
           "    - id: startup-screen`r`n" +
           "      name: 'dsh-startup-screen'`r`n"
  [System.IO.File]::AppendAllText($patch, $block, $utf8)
  Write-Host "registered startup-screen row in cordis.patch.yml (backup: cordis.patch.yml.bak-$stamp)"
} else {
  Write-Host "startup-screen row already present in cordis.patch.yml"
}

Write-Host ""
Write-Host "Now FULLY quit DeepSeek Harness (including the tray icon) and open it again."
Write-Host "The boot animation plays once per session. ESC / click skips it."
