#!/usr/bin/env bash

set -euo pipefail

pamixer --get-mute 2>/dev/null || printf 'false\n'
