#!/bin/bash

# Get CPU temp (Package id 0 is common on Intel)
temp=$(sensors | grep -m 1 'Package id 0:' | awk '{print $4}' | tr -d '+°C')

# Fallback if above fails (AMD or different label)
if [ -z "$temp" ]; then
  temp=$(sensors | grep -m 1 'Tctl:' | awk '{print $2}' | tr -d '+°C')
fi

# Output for Waybar
echo "{\"text\": \" ${temp}°C\", \"tooltip\": \"CPU Temp: ${temp}°C\"}"