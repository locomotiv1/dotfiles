#!/bin/bash
INPUT_WS=$1

CURRENT_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

if [ "$CURRENT_MONITOR" == "DP-3" ]; then
    TARGET_WS=$((INPUT_WS + 10))
else
    TARGET_WS=$INPUT_WS
fi

hyprctl dispatch movetoworkspace $TARGET_WS
