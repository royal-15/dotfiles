#!/bin/bash

# Check if hyprsunset daemon is already running
if pgrep -x "hyprsunset" > /dev/null; then
    # Kill hyprsunset if it's running (switch to day mode)
    killall hyprsunset
    notify-send "Night Light" "Off" -u "low"
else
    # Start hyprsunset for night mode at 5000K temperature
    hyprsunset -t 5000 &
    notify-send "Night Light" "On" -u "low"
fi