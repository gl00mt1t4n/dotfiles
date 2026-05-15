#!/usr/bin/env bash

# Single press: open region selector (drag to choose area)
# Double press: capture the full screen
#
# How it works: on first press, create a lock file and wait 0.3s.
# If a second press arrives within that window, the lock file is gone
# and the second press takes a full screenshot. If no second press
# arrives, the wait finishes and region select opens normally.

LOCK="/tmp/screenshot-double-press"
SAVEDIR="$HOME/Pictures"
FILENAME="$(date +%Y-%m-%d_%H-%M-%S).png"

if [ -f "$LOCK" ]; then
    # Second press within the window — full screenshot
    rm -f "$LOCK"
    grim "$SAVEDIR/$FILENAME"
else
    # First press — wait to see if a second press comes
    touch "$LOCK"
    sleep 0.3

    if [ -f "$LOCK" ]; then
        # No second press came — open region selector
        rm -f "$LOCK"
        grim -g "$(slurp)" "$SAVEDIR/$FILENAME"
    fi
    # If lock is gone, the second press already handled it
fi
