#!/usr/bin/env bash

# Cycles keyboard backlight through all levels: 0 (off) → 1 → 2 → 3 → 0
DEVICE="/sys/class/leds/asus::kbd_backlight"

MAX=$(cat "$DEVICE/max_brightness") || exit 1
CURRENT=$(cat "$DEVICE/brightness") || exit 1
NEXT=$(( (CURRENT + 1) % (MAX + 1) ))

echo "$NEXT" > "$DEVICE/brightness"
