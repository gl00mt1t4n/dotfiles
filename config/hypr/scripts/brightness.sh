#!/usr/bin/env bash
# caelestia monitors sysfs and shows the brightness OSD automatically on change
[ "$1" = "raise" ] && brightnessctl -d intel_backlight set +10% || brightnessctl -d intel_backlight set 10%-
