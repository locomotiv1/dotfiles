#!/bin/bash

ACTION=$1
BASE_NUM=$2

# Get the currently focused workspace number
CURRENT_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# If we are currently on the second monitor (workspaces 11-19), add 10 to our target
if [ "$CURRENT_WS" -ge 11 ] && [ "$CURRENT_WS" -le 19 ]; then
  TARGET_WS=$((BASE_NUM + 10))
else
  # Otherwise, assume monitor 1 and just use the base number (1-9)
  TARGET_WS=$BASE_NUM
fi

# Execute the requested i3 action
if [ "$ACTION" == "switch" ]; then
  i3-msg workspace number $TARGET_WS
elif [ "$ACTION" == "move" ]; then
  i3-msg move container to workspace number $TARGET_WS
fi
