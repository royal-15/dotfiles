#!/bin/sh

# Check AC / Line power
if grep -q 1 /sys/class/power_supply/*/online 2>/dev/null; then
    ac=1
elif grep -q 0 /sys/class/power_supply/*/online 2>/dev/null; then
    ac=0
elif ! ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    ac=1
else
    ac=0
fi

# Check Battery status
if grep -q -x -F "Charging" /sys/class/power_supply/BAT*/status 2>/dev/null; then
    status="Charging"
elif grep -q -x -F "Discharging" /sys/class/power_supply/BAT*/status 2>/dev/null; then
    status="Discharging"
elif grep -q -x -F "Full" /sys/class/power_supply/BAT*/status 2>/dev/null; then
    status="Full"
elif grep -q -x -F "Not charging" /sys/class/power_supply/BAT*/status 2>/dev/null; then
    status="Not charging"
else
    status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
fi

# Check Battery percentage / capacity
cap=$(awk '{sum += $1; n++} END {if (n > 0) print int(sum / n)}' /sys/class/power_supply/BAT*/capacity 2>/dev/null)

printf "%s|%s|%s\n" "$ac" "${status:-}" "${cap:-}"
