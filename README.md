# Plugable Microscope Harness

Cross-platform launcher for Plugable USB digital microscopes (and other UVC microscope cameras built on the Etron chipset). Installs a small viewer plus an OS-native launcher entry called **Plugable Microscope** so the device opens from your normal app search.

## Quick start

### Linux — Arch, Ubuntu/Debian, Fedora, openSUSE
```sh
./setup.sh
```

### macOS
```sh
./setup.sh
```
Requires [Homebrew](https://brew.sh).

### Windows
```powershell
.\setup.ps1
```
Run from PowerShell. Requires [winget](https://aka.ms/winget) or [scoop](https://scoop.sh).

After install, plug the microscope in and search **Plugable Microscope** in your launcher / Spotlight / Start Menu.

## In-viewer controls
| input                       | action                                                              |
|-----------------------------|---------------------------------------------------------------------|
| click the green **[ SNAP ]** button | take a screenshot                                            |
| **Space**                   | take a screenshot                                                   |
| **Ctrl + Space**            | start / stop video recording (red **● REC** indicator while active) |
| **Q** or close window       | quit                                                                |

Captures land next to the harness:
- screenshots → `Captures/Pictures/microscope-YYYYMMDD-HHMMSS.png`
- recordings  → `Captures/Videos/microscope-YYYYMMDD-HHMMSS.mkv`

Override the destination with `PMS_CAPTURES=/some/path`.

> Recordings are **raw YUYV** in a Matroska container — playable in any modern
> player, but ~20 MB/s. To shrink:
> `ffmpeg -i microscope-XXX.mkv -c:v libx264 -preset fast -crf 23 microscope-XXX.mp4`

## What it does
- Installs `mpv` and `ffmpeg` (plus `v4l-utils` on Linux) via the platform's package manager.
- Drops a `plugable-microscope` launcher into your user `bin` directory.
- Bundles a small mpv Lua overlay that adds the SNAP button, REC indicator, and key bindings.
- Registers an OS-native app entry so the microscope shows up in app search:
  - **Linux** — `~/.local/share/applications/plugable-microscope.desktop`
  - **macOS** — `~/Applications/Plugable Microscope.app`
  - **Windows** — Start Menu shortcut named *Plugable Microscope*

The launcher auto-detects the device by USB product string ("USB Microscope" / "Etron"), so the same script works regardless of which `/dev/videoN` index it lands on or which Plugable model you have.

## Manual usage
```sh
plugable-microscope                            # uses the device's default mode
PMS_CAPTURES=~/Desktop/scope plugable-microscope
```

To pick a fixed capture mode, pass mpv flags on the launcher's command line, e.g.:
```sh
plugable-microscope --demuxer-lavf-o=video_size=1280x720,input_format=yuyv422
```

## Troubleshooting
- **"not found"** — unplug and replug, then try again. On Linux, confirm it appears in `v4l2-ctl --list-devices`.
- **Wrong device picked up** — list candidates:
  - Linux: `v4l2-ctl --list-devices`
  - macOS: `ffmpeg -f avfoundation -list_devices true -i ""`
  - Windows: `Get-PnpDevice -Class Camera`
- **Slow at 1600×1200** — the sensor caps that mode at 7 fps. Use `PMS_SIZE=1280x720` for 11 fps or `640x480` for 30 fps.
- **Linux: launcher not on PATH** — add `export PATH="$HOME/.local/bin:$PATH"` to your shell rc.

## Uninstall
```sh
# Linux
rm -f ~/.local/bin/plugable-microscope ~/.local/share/applications/plugable-microscope.desktop

# macOS
rm -rf ~/Applications/"Plugable Microscope.app" ~/.local/bin/plugable-microscope

# Windows (PowerShell)
Remove-Item "$env:LOCALAPPDATA\PlugableMicroscope" -Recurse -Force
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Plugable Microscope.lnk"
```

## Supported hardware
Tested with the Plugable USB 2.0 Digital Microscope (reports as *Etron Technology, Inc. USB Microscope*). Any UVC microscope whose USB product string contains "Microscope" or "Etron" should be picked up automatically.
