#!/bin/bash

# 1. Ask i3 for the exact dimensions of the currently focused monitor
GEOM=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true) | .rect | "\(.width)x\(.height)+\(.x)+\(.y)"')

# 2. Check if we want to copy to clipboard OR save to file
if [ "$1" == "clipboard" ]; then
  maim -g "$GEOM" | xclip -selection clipboard -t image/png
  notify-send "Screenshot" "Monitor copied to clipboard!"

elif [ "$1" == "file" ]; then
  FILE="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
  maim -g "$GEOM" "$FILE"
  notify-send "Screenshot" "Monitor saved to file!"
fi
