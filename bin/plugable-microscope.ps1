# plugable-microscope.ps1 — live preview of a Plugable USB microscope on Windows.
#
# Controls (inside the viewer window):
#   SPACE          take a screenshot       -> $env:PMS_CAPTURES\Pictures
#   Ctrl+SPACE     toggle video recording  -> $env:PMS_CAPTURES\Videos
#   click "SNAP"   take a screenshot
$ErrorActionPreference = 'Stop'

$Viewer = if ($env:PMS_VIEWER) { $env:PMS_VIEWER } else { 'mpv' }

# setup.ps1 prepends `$env:PMS_REPO_ROOT = '<abs-path>'` above this line in
# the installed copy so the value survives launch from any cwd. When run
# from the repo we self-resolve from our own script path.
if (-not $env:PMS_REPO_ROOT) {
    $env:PMS_REPO_ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}
$RepoRoot = $env:PMS_REPO_ROOT

$LuaScript = if ($env:PMS_LUA) { $env:PMS_LUA } else { Join-Path $RepoRoot 'share\plugable-microscope.lua' }
if (-not $env:PMS_CAPTURES) { $env:PMS_CAPTURES = Join-Path $RepoRoot 'Captures' }

if (-not (Get-Command $Viewer -ErrorAction SilentlyContinue)) {
    Write-Error "$Viewer not found. Run setup.ps1 first."
    exit 1
}

$cam = Get-PnpDevice -Class Camera -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match 'Microscope|Etron|Plugable' } |
    Select-Object -First 1

if (-not $cam) {
    $cam = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -match 'Microscope|Etron' } |
        Select-Object -First 1
}

if (-not $cam) {
    Write-Error 'Plugable Microscope not found. Plug it in and try again.'
    exit 1
}

$mpvArgs = @(
    "av://dshow:video=$($cam.FriendlyName)",
    '--profile=low-latency',
    '--force-window=yes',
    '--title=Plugable Microscope'
)
if (Test-Path $LuaScript) { $mpvArgs += "--script=$LuaScript" }
$mpvArgs += $args

& $Viewer @mpvArgs
