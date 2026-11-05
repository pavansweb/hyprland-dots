#!/usr/bin/env bash
# Switch to the next available empty workspace
current_workspaces=$(hyprctl workspaces -j 2>/dev/null)
active_id=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1' 2>/dev/null)

if command -v jq &>/dev/null && [ -n "$current_workspaces" ]; then
    occupied=$(echo "$current_workspaces" | jq -r '.[] | select(.windows > 0) | .id')
    target=1
    while echo "$occupied" | grep -qx "$target" || [ "$target" -eq "${active_id:-0}" ]; do
        target=$((target + 1))
    done
    hyprctl dispatch workspace "$target"
else
    hyprctl dispatch workspace empty
fi
