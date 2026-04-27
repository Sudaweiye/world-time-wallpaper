$ErrorActionPreference = "Stop"

$rainmeter = "C:\Program Files\Rainmeter\Rainmeter.exe"
if (-not (Test-Path -LiteralPath $rainmeter)) {
  throw "Rainmeter was not found at $rainmeter. Install Rainmeter first: https://www.rainmeter.net/"
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$skinSource = Join-Path $repoRoot "rainmeter\WorldTimeOverlay"
if (-not (Test-Path -LiteralPath (Join-Path $skinSource "WorldTimeOverlay.ini"))) {
  throw "WorldTimeOverlay.ini was not found under $skinSource"
}

$documents = [Environment]::GetFolderPath("MyDocuments")
$skinRoot = Join-Path $documents "Rainmeter\Skins"
$skinTarget = Join-Path $skinRoot "WorldTimeOverlay"
New-Item -ItemType Directory -Force -Path $skinRoot | Out-Null
if (Test-Path -LiteralPath $skinTarget) {
  Remove-Item -LiteralPath $skinTarget -Recurse -Force
}
Copy-Item -LiteralPath $skinSource -Destination $skinTarget -Recurse -Force

$configDir = Join-Path $env:APPDATA "Rainmeter"
$configPath = Join-Path $configDir "Rainmeter.ini"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if (Test-Path -LiteralPath $configPath) {
  $content = Get-Content -LiteralPath $configPath -Raw
} else {
  $content = "[Rainmeter]`r`nSkinPath=$skinRoot\`r`n"
}

if ($content -notmatch "(?m)^SkinPath=") {
  $content = $content -replace "(?m)^\[Rainmeter\]\s*", "[Rainmeter]`r`nSkinPath=$skinRoot\`r`n"
}

foreach ($section in "Clock", "Disk", "System", "Welcome") {
  $pattern = "(?ms)\[illustro\\$section\](.*?)(?=\r?\n\[|\z)"
  if ($content -match $pattern) {
    $content = $content -replace $pattern, "[illustro\$section]`r`nActive=0`r`n"
  }
}

$overlay = @"
[WorldTimeOverlay]
Active=1
WindowX=0
WindowY=822
ClickThrough=1
Draggable=0
SnapEdges=1
KeepOnScreen=1
AlwaysOnTop=-2
"@

if ($content -match "(?m)^\[WorldTimeOverlay\]") {
  $content = $content -replace "(?ms)\[WorldTimeOverlay\](.*?)(?=\r?\n\[|\z)", $overlay
} else {
  $content = $content.TrimEnd() + "`r`n`r`n" + $overlay + "`r`n"
}
Set-Content -LiteralPath $configPath -Value $content -Encoding Unicode

$startup = [Environment]::GetFolderPath("Startup")
$linkPath = Join-Path $startup "Rainmeter.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($linkPath)
$shortcut.TargetPath = $rainmeter
$shortcut.WorkingDirectory = Split-Path $rainmeter
$shortcut.IconLocation = "$rainmeter,0"
$shortcut.Save()

Get-Process Rainmeter -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process -FilePath $rainmeter -WindowStyle Hidden
Start-Sleep -Seconds 3
& $rainmeter !RefreshApp
Start-Sleep -Milliseconds 800
& $rainmeter !ActivateConfig "WorldTimeOverlay" "WorldTimeOverlay.ini"
& $rainmeter !Move 0 822 "WorldTimeOverlay" "WorldTimeOverlay.ini"
& $rainmeter !ZPos -2 "WorldTimeOverlay" "WorldTimeOverlay.ini"
& $rainmeter !Draggable 0 "WorldTimeOverlay" "WorldTimeOverlay.ini"
& $rainmeter !ClickThrough 1 "WorldTimeOverlay" "WorldTimeOverlay.ini"

Write-Host "WorldTimeOverlay installed and configured to start with Windows."
Write-Host "Startup shortcut: $linkPath"
