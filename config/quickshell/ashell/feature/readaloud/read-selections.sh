#!/usr/bin/env bash

# feature/readaloud/read-selections.sh
# Real-time TTS speech pipeline with audio pacing & RMS level analyzer for Quickshell ActiveStateOsd

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIDFILE="${XDG_CACHE_HOME:-$HOME/.cache}/ashell_readaloud.pid"
mkdir -p "$(dirname "$PIDFILE")"

# Support explicit stop command
if [[ "$1" == "--stop" ]]; then
    if [[ -f "$PIDFILE" ]]; then
        OLD_PID=$(cat "$PIDFILE" 2>/dev/null || true)
        if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
            pkill -P "$OLD_PID" 2>/dev/null || true
            kill -TERM "$OLD_PID" 2>/dev/null || true
        fi
        rm -f "$PIDFILE"
    fi
    pkill -f "audio_pacer.py" 2>/dev/null || true
    exit 0
fi

# Mutual exclusion: kill any previous running instance before starting a new one
if [[ -f "$PIDFILE" ]]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null || true)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        pkill -P "$OLD_PID" 2>/dev/null || true
        kill -TERM "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
fi
pkill -f "audio_pacer.py" 2>/dev/null || true

# Record own PID
echo "$$" > "$PIDFILE"

# Clean up PIDFILE on exit
cleanup_trap() {
    trap - SIGTERM SIGINT EXIT
    rm -f "$PIDFILE"
    pkill -P $$ 2>/dev/null || true
    exit 0
}
trap cleanup_trap SIGINT SIGTERM EXIT

MODEL="${1:-${MODEL:-/usr/share/piper-voices/en/en_US/ryan/high/en_US-ryan-high.onnx}}"

# Retrieve text from primary selection first, clipboard as fallback
TEXT=$(wl-paste --primary 2>/dev/null || true)
TRIMMED=$(printf "%s" "$TEXT" | tr -d '[:space:]')

if [[ -z "$TRIMMED" ]]; then
    TEXT=$(wl-paste --no-newline 2>/dev/null || true)
    TRIMMED=$(printf "%s" "$TEXT" | tr -d '[:space:]')
fi

# Check for empty or whitespace-only content
if [[ -z "$TRIMMED" ]]; then
    echo "ERROR:no_selection"
    rm -f "$PIDFILE"
    exit 0
fi

# Verify piper voice model existence
if [[ ! -f "$MODEL" ]]; then
    echo "ERROR:model_not_found"
    rm -f "$PIDFILE"
    exit 1
fi

# Verify required system binaries
if ! command -v piper-tts &>/dev/null; then
    echo "ERROR:piper_not_found"
    rm -f "$PIDFILE"
    exit 1
fi

if ! command -v pw-play &>/dev/null; then
    echo "ERROR:pw_play_not_found"
    rm -f "$PIDFILE"
    exit 1
fi

# Detect sample rate from voice model config JSON (fallback: 22050)
CONFIG="${MODEL}.json"
RATE=22050
if [[ -f "$CONFIG" ]]; then
    DETECTED_RATE=$(grep -Po '"sample_rate"\s*:\s*\K[0-9]+' "$CONFIG" 2>/dev/null || true)
    [[ -n "$DETECTED_RATE" ]] && RATE="$DETECTED_RATE"
fi

echo "STATUS:started"

# Stream TTS from piper through python pacer and level analyzer
printf "%s" "$TEXT" | tr '\n' ' ' | piper-tts -m "$MODEL" --output-raw 2>/dev/null | python3 -u "$SCRIPT_DIR/audio_pacer.py" "$RATE"
