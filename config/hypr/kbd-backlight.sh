#!/usr/bin/env bash
DEVICE="/sys/class/leds/asus::kbd_backlight"

if [ ! -d "$DEVICE" ]; then
    notify-send -t 3000 "Keyboard Backlight" "Not available on this hardware yet"
    exit 1
fi

CURRENT=$(cat "$DEVICE/brightness")
MAX=$(cat "$DEVICE/max_brightness")

if [ "$CURRENT" -gt 0 ]; then
    echo 0 > "$DEVICE/brightness"
else
    echo "$MAX" > "$DEVICE/brightness"
fi
