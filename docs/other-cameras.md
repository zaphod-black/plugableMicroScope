# Adapting the harness for other USB cameras

The launcher matches a video device by its USB product string. If your camera does not contain `Plugable`, `Etron`, or `Microscope` in its product string, add a pattern.

## 1. Find your camera's identifier

### Linux
```sh
ls /dev/v4l/by-id/
v4l2-ctl --list-devices
```

### macOS
```sh
ffmpeg -f avfoundation -list_devices true -i ""
```

### Windows
```powershell
Get-PnpDevice -Class Camera -PresentOnly | Select-Object FriendlyName
```

## 2. Add it to the matcher

### Linux / macOS, in `bin/plugable-microscope`

Add a `by-id` glob to `find_linux_device()`:
```bash
'/dev/v4l/by-id/*YourCameraName*-video-index0' \
```

For macOS, extend the regex in `find_mac_index()`:
```awk
if (tolower(rest) ~ /microscope|etron|yourcameraname/) { print idx; exit }
```

### Windows, in `bin/plugable-microscope.ps1`

Extend the `Where-Object` filter:
```powershell
Where-Object { $_.FriendlyName -match 'Microscope|Etron|Plugable|YourCameraName' }
```

## 3. Resolution and capture mode

The launcher passes no resolution flags so mpv uses the device default. Force a mode by appending mpv flags:
```sh
plugable-microscope --demuxer-lavf-o=video_size=1920x1080,input_format=yuyv422
```

List supported modes:
```sh
v4l2-ctl --device=/dev/videoN --list-formats-ext
```

## 4. Autofocus

Pressing `Alt+F` calls `v4l2-ctl --set-ctrl=focus_automatic_continuous=<0|1>` (or `focus_auto` on older kernels). If neither control exists, the OSD reports "autofocus not supported on this device". Verify support with:
```sh
v4l2-ctl --device=/dev/videoN --list-ctrls | grep -i focus
```

The Plugable USB2-MICRO-250x is manual focus only and will report unsupported.

## 5. Other UVC controls

`v4l2-ctl` exposes brightness, contrast, exposure, white balance, gain, sharpness, and more. Examples:
```sh
v4l2-ctl --device=/dev/video2 --list-ctrls
v4l2-ctl --device=/dev/video2 --set-ctrl=brightness=10
v4l2-ctl --device=/dev/video2 --set-ctrl=auto_exposure=1               # 1 = manual
v4l2-ctl --device=/dev/video2 --set-ctrl=exposure_time_absolute=200
v4l2-ctl --device=/dev/video2 --set-ctrl=white_balance_automatic=0
v4l2-ctl --device=/dev/video2 --set-ctrl=white_balance_temperature=4500
```

These can be set before launching the viewer or while it is running.

## 6. App entry name and icon

If you want the app launcher to read something other than "Plugable Microscope":

- **Linux**: edit `share/applications/plugable-microscope.desktop` (`Name=`, `Icon=`, `Keywords=`).
- **macOS**: edit the `CFBundleName` / `CFBundleDisplayName` block in `setup.sh`'s `install_mac()`.
- **Windows**: edit the shortcut path and `Description` in `setup.ps1`.

Then re-run the relevant setup script.
