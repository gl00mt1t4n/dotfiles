#!/usr/bin/env bash
hyprctl dispatch workspace +1
sleep 0.1
active_id=$(hyprctl monitors -j | jq '[.[] | select(.focused)] | .[0].activeWorkspace.id')
count=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $active_id)] | length")
[ "$count" -eq 0 ] && hyprlauncher
