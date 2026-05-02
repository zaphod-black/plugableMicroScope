# Plugable Microscope harness — Windows installer.
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Log($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- Dependencies --------------------------------------------------------
if (-not (Get-Command mpv -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log 'Installing mpv via winget'
        winget install --id mpv.net -e --accept-source-agreements --accept-package-agreements
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Log 'Installing mpv via scoop'
        scoop install mpv
    } else {
        Write-Error 'Neither winget nor scoop is available. Install mpv manually from https://mpv.io and re-run.'
        exit 1
    }
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log 'Installing ffmpeg via winget'
        winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install ffmpeg
    }
}

# --- Captures dirs -------------------------------------------------------
New-Item -ItemType Directory -Force -Path (Join-Path $ScriptDir 'Captures\Pictures') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ScriptDir 'Captures\Videos')   | Out-Null

# --- Install launcher ----------------------------------------------------
$BinDir = Join-Path $env:LOCALAPPDATA 'PlugableMicroscope'
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

$src = Join-Path $ScriptDir 'bin\plugable-microscope.ps1'
$dst = Join-Path $BinDir    'plugable-microscope.ps1'
Log "Installing launcher → $dst"
(Get-Content $src -Raw).Replace('__PMS_REPO_ROOT__', $ScriptDir) | Set-Content -Path $dst -Encoding UTF8

# --- Start Menu shortcut so it shows up in app search --------------------
$StartMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$Shortcut  = Join-Path $StartMenu 'Plugable Microscope.lnk'

Log "Creating Start Menu shortcut: $Shortcut"
$Shell = New-Object -ComObject WScript.Shell
$Link  = $Shell.CreateShortcut($Shortcut)
$Link.TargetPath       = 'powershell.exe'
$Link.Arguments        = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst`""
$Link.WorkingDirectory = $BinDir
$Link.Description      = 'Live preview from a Plugable USB digital microscope'
$Link.IconLocation     = 'imageres.dll,15'
$Link.Save()

Log "Done. Search 'Plugable Microscope' in the Start Menu."
