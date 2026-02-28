#!/bin/bash

ACTION=$1
BASE_NUM=$2

CURRENT_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# Generate the NUMBER:NAME format (e.g., 15:5 or 5:5)
if [ "$CURRENT_WS" -ge 11 ] && [ "$CURRENT_WS" -le 19 ]; then
  TARGET_WS="$((BASE_NUM + 10)):$BASE_NUM"
else
  TARGET_WS="$BASE_NUM:$BASE_NUM"
fi

if [ "$ACTION" == "switch" ]; then
  i3-msg workspace number "$TARGET_WS"
elif [ "$ACTION" == "move" ]; then
  i3-msg move container to workspace number "$TARGET_WS"
fi
