# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Installed launcher could not locate the Lua overlay script — the placeholder
  substitution clobbered both the value and the detection guard, so SPACE /
  Ctrl+SPACE fell through to mpv defaults (pause) and the SNAP button did not
  render. The launcher now receives an injected `export PMS_REPO_ROOT=...`
  line at install time instead.
- App-launcher entries showed *Command not found* because graphical launchers
  do not inherit `~/.local/bin` from the user's shell. The installed `.desktop`
  file now uses the launcher's absolute path.

### Changed
- `setup.sh` skips the package-manager step entirely when `mpv`, `ffmpeg`, and
  `v4l2-ctl` are all already present, so it no longer prompts for `sudo` on a
  fully-set-up system.
- Screenshot and recording OSD popups now show the full saved path for ~3
  seconds.

## [0.1.0] — 2026-05-02

### Added
- Cross-platform setup scripts:
  - Linux via pacman / apt / dnf / zypper
  - macOS via Homebrew
  - Windows via winget or scoop
- `plugable-microscope` launcher that auto-detects the device by USB product string and opens a live preview in `mpv`.
- OS-native app entries so the microscope appears in app search:
  - Linux `.desktop` file
  - macOS `.app` bundle
  - Windows Start Menu shortcut
- `PMS_SIZE` and `PMS_VIEWER` environment variables for overriding capture resolution and viewer binary.
