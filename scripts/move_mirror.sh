#!/bin/bash

# Get the currently focused workspace number using i3-msg and jq
CURRENT_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# Calculate the target workspace
if [ "$CURRENT_WS" -ge 1 ] && [ "$CURRENT_WS" -le 9 ]; then
  # If on monitor 1 (1-9), add 10 to send to monitor 2
  TARGET_WS=$((CURRENT_WS + 10))
elif [ "$CURRENT_WS" -ge 11 ] && [ "$CURRENT_WS" -le 19 ]; then
  # If on monitor 2 (11-19), subtract 10 to send to monitor 1
  TARGET_WS=$((CURRENT_WS - 10))
else
  # Do nothing if on a workspace outside of these ranges (e.g., 10 or 20)
  exit 0
fi

# Move the currently focused container to the target workspace
i3-msg move container to workspace number $TARGET_WS
