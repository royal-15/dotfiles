#!/usr/bin/env bash

set -euo pipefail

pamixer --default-source --get-mute 2>/dev/null || printf 'false\n'
