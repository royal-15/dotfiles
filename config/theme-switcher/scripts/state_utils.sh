#!/usr/bin/env bash

STATE_FILE="${STATE_FILE:-}"

ensure_state_file() {
    mkdir -p "$(dirname "$STATE_FILE")"

    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" <<EOF
ACTIVE_THEME=
ACTIVE_WALLPAPER=
ACTIVE_WAYBAR_LAYOUT=
EOF
    fi
}

load_state() {
    ensure_state_file

    # shellcheck disable=SC1090
    source "$STATE_FILE"
}

save_state() {
    ensure_state_file

    cat > "$STATE_FILE" <<EOF
ACTIVE_THEME=${ACTIVE_THEME:-}
ACTIVE_WALLPAPER=${ACTIVE_WALLPAPER:-}
ACTIVE_WAYBAR_LAYOUT=${ACTIVE_WAYBAR_LAYOUT:-}
EOF
}

save_key() {
    local key="$1"
    local value="$2"

    ensure_state_file

    if grep -q "^${key}=" "$STATE_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$STATE_FILE"
    else
        echo "${key}=${value}" >> "$STATE_FILE"
    fi
}