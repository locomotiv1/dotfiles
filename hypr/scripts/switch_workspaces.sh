#!/bin/bash

# Get the active window's workspace ID
CURRENT_WS=$(hyprctl activewindow -j | jq '.workspace.id')

# Exit if no window is focused or if it's on a special workspace (negative ID)
if [ -z "$CURRENT_WS" ] || [ "$CURRENT_WS" -le 0 ]; then
    exit 0
fi

# Calculate the equivalent workspace on the other monitor
if [ "$CURRENT_WS" -le 10 ]; then
    TARGET_WS=$((CURRENT_WS + 10))
elif [ "$CURRENT_WS" -le 20 ]; then
    TARGET_WS=$((CURRENT_WS - 10))
else
    # Do nothing if somehow above 20
    exit 0 
fi

# Move the window to the target workspace and switch your focus to it
hyprctl dispatch movetoworkspace $TARGET_WS
