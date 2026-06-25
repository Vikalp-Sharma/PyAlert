#!/usr/bin/env bash
set -euo pipefail

MARKER_START="# >>> pyalert-system >>>"
MARKER_END="# <<< pyalert-system <<<"

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run this installer with sudo/root."
  echo "Run: bash install.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.error_alert"
BIN_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="pyalert.service"
BASH_RC="$HOME/.bashrc"
ZSH_RC="$HOME/.zshrc"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$SERVICE_DIR"

cp "$SCRIPT_DIR/trigger_alert.py" "$INSTALL_DIR/trigger_alert.py"
cp "$SCRIPT_DIR/notify_error.py"  "$INSTALL_DIR/notify_error.py"
chmod +x "$INSTALL_DIR/trigger_alert.py" "$INSTALL_DIR/notify_error.py"

cat > "$INSTALL_DIR/pyalert_shell_hook.bash" <<'EOF'
__pyalert_fire() {
    "$HOME/.error_alert/notify_error.py" >/dev/null 2>&1
}

__pyalert_check() {
    local status="$1"
    local cmd="$2"

    [ "${PYALERT_DISABLE:-0}" = "1" ] && return 0
    [ "$status" -eq 0 ] && return 0
    [ "$status" -eq 130 ] && return 0
    [ -z "$cmd" ] && return 0

    case "$cmd" in
        *notify_error.py*|*trigger_alert.py*|*pyalert_shell_hook*)
            return 0
            ;;
    esac

    local first_token first_base
    set -- $cmd
    first_token="${1:-}"
    first_base="$(basename -- "$first_token")"

    case "$first_base" in
        python|python[0-9]*|pypy|pypy[0-9]*)
            __pyalert_fire
            return 0
            ;;
    esac

    case "$cmd" in
        *python*|*/python* )
            __pyalert_fire
            ;;
    esac
}

__pyalert_preexec() {
    __pyalert_did_exec=1
}

__pyalert_prompt_hook() {
    local status="$?"
    
    # If the user just pressed Enter, no new command was executed
    if [ "${__pyalert_did_exec:-0}" -eq 0 ]; then
        return 0
    fi
    __pyalert_did_exec=0

    local cmd
    cmd="$(HISTTIMEFORMAT= history 1 2>/dev/null | sed 's/^ *[0-9]\+ *//')"
    __pyalert_check "$status" "$cmd"
}

trap "__pyalert_preexec" DEBUG

case ";${PROMPT_COMMAND:-};" in
    *";__pyalert_prompt_hook;"*) ;;
    *)
        if [ -n "${PROMPT_COMMAND:-}" ]; then
            PROMPT_COMMAND="__pyalert_prompt_hook;${PROMPT_COMMAND}"
        else
            PROMPT_COMMAND="__pyalert_prompt_hook"
        fi
        ;;
esac
EOF

cat > "$INSTALL_DIR/pyalert_shell_hook.zsh" <<'EOF'
__pyalert_last_command=""

__pyalert_fire() {
    "$HOME/.error_alert/notify_error.py" >/dev/null 2>&1
}

__pyalert_check() {
    local status="$1"
    local cmd="$2"

    [ "${PYALERT_DISABLE:-0}" = "1" ] && return 0
    [ "$status" -eq 0 ] && return 0
    [ "$status" -eq 130 ] && return 0
    [ -z "$cmd" ] && return 0

    case "$cmd" in
        *notify_error.py*|*trigger_alert.py*|*pyalert_shell_hook*)
            return 0
            ;;
    esac

    local first_token first_base
    first_token="${cmd%%[[:space:]]*}"
    first_base="${first_token:t}"

    case "$first_base" in
        python|python[0-9]*|pypy|pypy[0-9]*)
            __pyalert_fire
            return 0
            ;;
    esac

    case "$cmd" in
        *python*|*/python* )
            __pyalert_fire
            ;;
    esac
}

__pyalert_preexec() {
    __pyalert_last_command="$1"
}

__pyalert_precmd() {
    local status="$?"
    local cmd="${__pyalert_last_command:-}"
    __pyalert_last_command=""
    __pyalert_check "$status" "$cmd"
}

autoload -Uz add-zsh-hook 2>/dev/null || true
add-zsh-hook preexec __pyalert_preexec 2>/dev/null || true
add-zsh-hook precmd __pyalert_precmd 2>/dev/null || true
EOF

cat > "$SERVICE_DIR/$SERVICE_NAME" <<EOF
[Unit]
Description=PyAlert daemon
After=default.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/trigger_alert.py
Restart=always
RestartSec=2
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=default.target
EOF

ln -sf "$INSTALL_DIR/trigger_alert.py" "$BIN_DIR/pyalert-trigger"
ln -sf "$INSTALL_DIR/notify_error.py" "$BIN_DIR/pyalert-notify"

touch "$BASH_RC" "$ZSH_RC"

append_block() {
    local rc_file="$1"
    local hook_file="$2"
    [ -f "$rc_file" ] || return 0
    if grep -qF "$MARKER_START" "$rc_file" 2>/dev/null; then
        return 0
    fi
    cat >> "$rc_file" <<EOF

$MARKER_START
if [ -f "$hook_file" ]; then
    . "$hook_file"
fi
$MARKER_END
EOF
}

append_block "$BASH_RC" "$INSTALL_DIR/pyalert_shell_hook.bash"
append_block "$ZSH_RC" "$INSTALL_DIR/pyalert_shell_hook.zsh"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
    systemctl --user enable "$SERVICE_NAME" >/dev/null 2>&1 || true
    systemctl --user restart "$SERVICE_NAME" >/dev/null 2>&1 || systemctl --user start "$SERVICE_NAME" >/dev/null 2>&1 || true
fi

if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$USER" >/dev/null 2>&1 || true
fi

cat <<EOF

PyAlert installed.

Next:
  1) Open a new terminal or run: source "$BASH_RC"   (or "$ZSH_RC")
  2) Check service: systemctl --user status $SERVICE_NAME
  3) Test:
       python3 -c "raise Exception('test')"
       /home/mazo/.local/bin/python3.14 -c "raise Exception('test')"

The daemon runs in the background and sends E to the Arduino over serial.
EOF
