#!/usr/bin/env bash

set -euo pipefail

close_panel() {
  command -v swaync-client >/dev/null 2>&1 && swaync-client -cp >/dev/null 2>&1 || true
}

close_panel

if command -v qs >/dev/null 2>&1; then
  qs -c ashell ipc call theme toggle || true
elif command -v quickshell >/dev/null 2>&1; then
  quickshell -c ashell ipc call theme toggle || true
fi
