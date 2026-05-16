#!/usr/bin/env bash

# Single press: open region selector (drag to choose area)
# Double press: capture the full screen
#
# After capturing:
#   - Saved to ~/Pictures/Screenshots/ with a timestamp name
#   - Copied to clipboard immediately
#   - Dialog asks if you want to rename it (blank or cancel = keep timestamp name)
#
# Cleanup: timestamp-named screenshots older than 14 days are deleted on each run.
# If you renamed a screenshot, it's kept forever — only the default names get cleaned up.

LOCK="/tmp/screenshot-double-press"
SAVEDIR="$HOME/Pictures/Screenshots"
FILENAME="$(date +%Y-%m-%d_%H-%M-%S).png"

mkdir -p "$SAVEDIR"

# Delete timestamp-named screenshots older than 14 days.
# The pattern matches exactly YYYY-MM-DD_HH-MM-SS.png — renamed files don't match and are skipped.
find "$SAVEDIR" -maxdepth 1 \
    -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].png" \
    -mtime +14 -delete

take_screenshot() {
    local mode="$1"
    local filepath="$SAVEDIR/$FILENAME"

    if [ "$mode" = "full" ]; then
        grim "$filepath"
    else
        # slurp opens the interactive region selector — exits non-zero if cancelled
        grim -g "$(slurp)" "$filepath" || return 1
    fi

    # Copy to clipboard so you can paste immediately
    wl-copy < "$filepath"

    # Ask for an optional name — blank or cancel keeps the timestamp name
    local newname
    newname=$(zenity --entry \
        --title="Screenshot saved" \
        --text="Rename? Leave blank to keep timestamp name." \
        --entry-text="" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$newname" ]; then
        mv "$filepath" "$SAVEDIR/$newname.png"
    fi
}

if [ -f "$LOCK" ]; then
    # Second press within the 0.3s window — full screenshot
    rm -f "$LOCK"
    take_screenshot full
else
    # First press — wait briefly to see if a second press comes
    touch "$LOCK"
    sleep 0.3

    if [ -f "$LOCK" ]; then
        # No second press — open region selector
        rm -f "$LOCK"
        take_screenshot region
    fi
    # If lock file is gone, the second press already handled it
fi
