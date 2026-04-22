#!/usr/bin/env bash

dir="$HOME/.config/rofi/themes/launchers"
theme="list-compact"

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
