#!/bin/bash
INPUT_WS=$1

# Look specifically at the focused MONITOR, not the workspace
CURRENT_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

# If the active monitor is DP-1, shift to 11-19
if [ "$CURRENT_MONITOR" == "DP-3" ]; then
    TARGET_WS=$((INPUT_WS + 10))
else
    # Otherwise, stay on 1-9 (HDMI-A-1)
    TARGET_WS=$INPUT_WS
fi

hyprctl dispatch workspace $TARGET_WS
