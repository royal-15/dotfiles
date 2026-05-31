#!/usr/bin/env bash

set -euo pipefail

daemon="$1"
shift

pkill -x "$daemon" || true

while pgrep -x "$daemon" >/dev/null; do
    sleep 0.1
done

"$daemon" "$@" >/dev/null 2>&1 &
