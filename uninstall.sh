#!/usr/bin/env bash
set -euo pipefail

MARKER_START="# >>> pyalert-system >>>"
MARKER_END="# <<< pyalert-system <<<"
INSTALL_DIR="$HOME/.error_alert"
SERVICE_NAME="pyalert.service"
SERVICE_DIR="$HOME/.config/systemd/user"

remove_block() {
    local rc_file="$1"
    if [ -f "$rc_file" ] && grep -qF "$MARKER_START" "$rc_file" 2>/dev/null; then
        sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$rc_file"
    fi
}

remove_block "$HOME/.bashrc"
remove_block "$HOME/.zshrc"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable "$SERVICE_NAME" >/dev/null 2>&1 || true
    systemctl --user stop "$SERVICE_NAME" >/dev/null 2>&1 || true
fi

rm -f "$SERVICE_DIR/$SERVICE_NAME"
rm -rf "$INSTALL_DIR"

echo "PyAlert uninstalled."
echo "Open a new shell or run: source ~/.bashrc"
