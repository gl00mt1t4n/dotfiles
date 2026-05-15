#!/usr/bin/env bash

# Opens a kitty window with two tabs:
#   Hyprland — the compositor's own log for the current session
#   Journal   — the system journal (NixOS services, hardware, kernel events)
#
# Triggered by SUPER+grave.

# Hyprland writes its log to a path containing a unique session hash.
# Find it dynamically each time this script runs.
HYPR_LOG=$(ls /run/user/$(id -u)/hypr/*/hyprland.log 2>/dev/null | head -1)

SESSION=$(mktemp /tmp/kitty-logs-XXXX.conf)

# Tab 1: Hyprland compositor log
echo "new_tab Hyprland" >> "$SESSION"
if [ -n "$HYPR_LOG" ]; then
    echo "launch tail -f $HYPR_LOG" >> "$SESSION"
else
    echo "launch bash -c 'echo No active Hyprland session log found; read'" >> "$SESSION"
fi

# Tab 2: System journal (NixOS services, hardware, kernel)
echo "" >> "$SESSION"
echo "new_tab Journal" >> "$SESSION"
echo "launch journalctl -f" >> "$SESSION"

kitty --session "$SESSION" --title "Logs"

rm -f "$SESSION"
