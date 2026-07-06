#!/bin/bash
# $1 is the action (workspace, "move container to workspace", or toggle_monitor)
# $2 is the key pressed (1-10)

ACTION=$1
KEY=$2

# Get the name of the currently focused monitor
FOCUSED_MONITOR=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

# --- NEW MONITOR TOGGLE LOGIC ---
if [ "$ACTION" == "toggle_monitor" ]; then
    if [ "$FOCUSED_MONITOR" == "HDMI-A-1" ]; then
        swaymsg focus output DP-3
    else
        swaymsg focus output HDMI-A-1
    fi
    exit 0 # Stop the script here so it doesn't run the workspace logic below
fi
# --------------------------------

# If focused on the second monitor, route to the secondary workspaces
if [ "$FOCUSED_MONITOR" == "DP-3" ]; then
    TARGET="1${KEY}:${KEY}"
else
    TARGET="$KEY"
fi

swaymsg "$ACTION $TARGET"
