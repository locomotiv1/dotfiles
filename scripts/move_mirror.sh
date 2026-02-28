#!/bin/bash

CURRENT_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# Calculate the target workspace and format as NUMBER:NAME
if [ "$CURRENT_WS" -ge 1 ] && [ "$CURRENT_WS" -le 9 ]; then
  TARGET_WS="$((CURRENT_WS + 10)):$CURRENT_WS"
elif [ "$CURRENT_WS" -ge 11 ] && [ "$CURRENT_WS" -le 19 ]; then
  BASE_WS=$((CURRENT_WS - 10))
  TARGET_WS="$BASE_WS:$BASE_WS"
else
  exit 0
fi

i3-msg move container to workspace number "$TARGET_WS"
