#!/bin/bash

# Get the exact workspace ID of the currently focused window
CURRENT_WS=$(hyprctl activewindow -j | jq '.workspace.id')

# Guard against pressing the keybind on an empty desktop (no window focused)
if [ -z "$CURRENT_WS" ] || [ "$CURRENT_WS" == "null" ]; then
    exit 0
fi

# Calculate the target workspace on the other monitor
if [ "$CURRENT_WS" -ge 1 ] && [ "$CURRENT_WS" -le 9 ]; then
    TARGET_WS=$((CURRENT_WS + 10))
elif [ "$CURRENT_WS" -ge 11 ] && [ "$CURRENT_WS" -le 19 ]; then
    TARGET_WS=$((CURRENT_WS - 10))
else
    exit 0
fi

# Move the window silently (your focus stays on the current screen)
hyprctl dispatch movetoworkspacesilent $TARGET_WS
