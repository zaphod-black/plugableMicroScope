# Changelog

All notable changes to this project will be documented in this file.

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
