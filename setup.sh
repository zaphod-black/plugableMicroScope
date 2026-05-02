#!/usr/bin/env bash
# Plugable Microscope harness — installer for Linux and macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; }

install_linux_deps() {
    if command -v pacman >/dev/null 2>&1; then
        log "Installing via pacman: mpv ffmpeg v4l-utils"
        sudo pacman -S --needed --noconfirm mpv ffmpeg v4l-utils
    elif command -v apt-get >/dev/null 2>&1; then
        log "Installing via apt: mpv ffmpeg v4l-utils"
        sudo apt-get update
        sudo apt-get install -y mpv ffmpeg v4l-utils
    elif command -v dnf >/dev/null 2>&1; then
        log "Installing via dnf: mpv ffmpeg v4l-utils"
        sudo dnf install -y mpv ffmpeg v4l-utils
    elif command -v zypper >/dev/null 2>&1; then
        log "Installing via zypper: mpv ffmpeg v4l-utils"
        sudo zypper install -y mpv ffmpeg v4l-utils
    else
        err "No supported package manager found (pacman/apt/dnf/zypper). Install mpv, ffmpeg, and v4l-utils manually, then re-run."
        exit 1
    fi
}

install_mac_deps() {
    if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew not found. Install from https://brew.sh and re-run."
        exit 1
    fi
    log "Installing via brew: mpv ffmpeg"
    brew install mpv ffmpeg
}

# Substitute __PMS_REPO_ROOT__ in the launcher template, install to dest, chmod +x.
install_launcher() {
    local dest="$1"
    sed "s|__PMS_REPO_ROOT__|$SCRIPT_DIR|g" "$SCRIPT_DIR/bin/plugable-microscope" > "$dest"
    chmod 0755 "$dest"
}

install_linux() {
    install_linux_deps

    local BIN_DIR="$HOME/.local/bin"
    local APP_DIR="$HOME/.local/share/applications"
    mkdir -p "$BIN_DIR" "$APP_DIR" "$SCRIPT_DIR/Captures/Pictures" "$SCRIPT_DIR/Captures/Videos"

    log "Installing launcher → $BIN_DIR/plugable-microscope"
    install_launcher "$BIN_DIR/plugable-microscope"

    log "Installing desktop entry"
    install -m 0644 "$SCRIPT_DIR/share/applications/plugable-microscope.desktop" \
        "$APP_DIR/plugable-microscope.desktop"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
    fi

    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) log "note: $BIN_DIR is not on your PATH — add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell rc";;
    esac

    log "Done. Search 'Plugable Microscope' in your launcher, or run: plugable-microscope"
}

install_mac() {
    install_mac_deps

    local BIN_DIR="$HOME/.local/bin"
    local APP_DIR="$HOME/Applications"
    local APP_BUNDLE="$APP_DIR/Plugable Microscope.app"
    mkdir -p "$BIN_DIR" "$APP_BUNDLE/Contents/MacOS" \
        "$SCRIPT_DIR/Captures/Pictures" "$SCRIPT_DIR/Captures/Videos"

    log "Installing launcher → $BIN_DIR/plugable-microscope"
    install_launcher "$BIN_DIR/plugable-microscope"

    log "Building $APP_BUNDLE"
    cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Plugable Microscope</string>
    <key>CFBundleDisplayName</key><string>Plugable Microscope</string>
    <key>CFBundleIdentifier</key><string>org.plugable.microscope</string>
    <key>CFBundleVersion</key><string>0.1.0</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleExecutable</key><string>launcher</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSCameraUsageDescription</key><string>Plugable Microscope shows a live preview from a USB microscope.</string>
    <key>LSUIElement</key><false/>
</dict>
</plist>
PLIST

    cat > "$APP_BUNDLE/Contents/MacOS/launcher" <<EOF
#!/usr/bin/env bash
exec "$BIN_DIR/plugable-microscope"
EOF
    chmod 0755 "$APP_BUNDLE/Contents/MacOS/launcher"

    if command -v mdimport >/dev/null 2>&1; then
        mdimport "$APP_BUNDLE" >/dev/null 2>&1 || true
    fi

    log "Done. Search 'Plugable Microscope' in Spotlight, or run: plugable-microscope"
}

case "$OS" in
    Linux)  install_linux ;;
    Darwin) install_mac ;;
    *)      err "Unsupported OS: $OS — use setup.ps1 on Windows."; exit 1 ;;
esac
