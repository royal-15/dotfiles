#!/bin/bash
#############################
### CLIPBOARD OPERATIONS ###
#############################

# Show clipboard history via native Quickshell Dynamic Island (with rofi fallback)
clipboard_history() {
    if quickshell -c ashell ipc call clipboard toggle >/dev/null 2>&1; then
        return 0
    fi
    cliphist list | rofi -dmenu -theme "$HOME/.config/rofi/themes/applets/clipboard-compact" | cliphist decode | wl-copy
}

# Clear clipboard history
clipboard_wipe() {
    quickshell -c ashell ipc call clipboard wipe >/dev/null 2>&1 || true
    cliphist wipe
    # Reset entry numbers by resetting the database
    rm -f "$HOME/.cache/cliphist/db"
}

# Main entry point
case "${1:-history}" in
    history)
        clipboard_history
        ;;
    wipe)
        clipboard_wipe
        ;;
    *)
        echo "Usage: $0 {history|wipe}"
        exit 1
        ;;
esac
