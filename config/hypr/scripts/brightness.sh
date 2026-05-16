#!/usr/bin/env bash
[ "$1" = "raise" ] && brightnessctl -d intel_backlight set +10% || brightnessctl -d intel_backlight set 10%-
CURRENT=$(brightnessctl -d intel_backlight get)
MAX=$(brightnessctl -d intel_backlight max)
PERCENT=$(( CURRENT * 100 / MAX ))
notify-send -t 1500 \
    -h int:value:"$PERCENT" \
    -h string:x-canonical-private-synchronous:brightness \
    "Brightness" "${PERCENT}%"
