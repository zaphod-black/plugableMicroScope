#!/usr/bin/env bash
# Plugable Microscope harness — installer for Linux and macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; }

install_linux_deps() {
    local need=()
    command -v mpv       >/dev/null 2>&1 || need+=(mpv)
    command -v ffmpeg    >/dev/null 2>&1 || need+=(ffmpeg)
    command -v v4l2-ctl  >/dev/null 2>&1 || need+=(v4l-utils)
    if [ ${#need[@]} -eq 0 ]; then
        log "All dependencies already present — skipping package install."
        return
    fi

    if command -v pacman >/dev/null 2>&1; then
        log "Installing via pacman: ${need[*]}"
        sudo pacman -S --needed --noconfirm "${need[@]}"
    elif command -v apt-get >/dev/null 2>&1; then
        log "Installing via apt: ${need[*]}"
        sudo apt-get update
        sudo apt-get install -y "${need[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        log "Installing via dnf: ${need[*]}"
        sudo dnf install -y "${need[@]}"
    elif command -v zypper >/dev/null 2>&1; then
        log "Installing via zypper: ${need[*]}"
        sudo zypper install -y "${need[@]}"
    else
        err "No supported package manager found (pacman/apt/dnf/zypper). Install ${need[*]} manually, then re-run."
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

# Inject an `export PMS_REPO_ROOT=...` line right after the shebang so the
# installed launcher always knows where to find the Lua + Captures dir,
# regardless of cwd or how it was invoked.
install_launcher() {
    local dest="$1"
    {
        head -n 1 "$SCRIPT_DIR/bin/plugable-microscope"
        printf 'export PMS_REPO_ROOT=%q\n' "$SCRIPT_DIR"
        tail -n +2 "$SCRIPT_DIR/bin/plugable-microscope"
    } > "$dest"
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
    # Use absolute path for Exec= so graphical launchers that don't inherit
    # ~/.local/bin in PATH (walker, Omarchy, etc.) can still find the launcher.
    sed "s|^Exec=plugable-microscope$|Exec=$BIN_DIR/plugable-microscope|" \
        "$SCRIPT_DIR/share/applications/plugable-microscope.desktop" \
        > "$APP_DIR/plugable-microscope.desktop"
    chmod 0644 "$APP_DIR/plugable-microscope.desktop"

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
