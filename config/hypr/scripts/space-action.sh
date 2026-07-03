#!/usr/bin/env bash
set -euo pipefail

workspace_id="$(hyprctl -j activeworkspace | jq -r '.id')"
client_count="$(
  hyprctl -j clients \
    | jq --argjson workspace_id "$workspace_id" '[.[] | select(.mapped == true and .workspace.id == $workspace_id)] | length'
)"

if [ "$client_count" -eq 0 ]; then
  hyprctl dispatch global caelestia:launcher
else
  hyprctl dispatch global caelestia:showall
fi
