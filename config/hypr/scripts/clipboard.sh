#!/bin/bash
#############################
### CLIPBOARD OPERATIONS ###
#############################

# Show clipboard history and paste selection
clipboard_history() {
    cliphist list | rofi -dmenu -theme "$HOME/.config/rofi/themes/applets/clipboard-compact" | cliphist decode | wl-copy
}

# Clear clipboard history
clipboard_wipe() {
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
