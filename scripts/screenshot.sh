#!/usr/bin/env bash

# Directory to save screenshots
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Filename format: screenshot_YYYY-MM-DD_HH-MM-SS.png
FILENAME="$SAVE_DIR/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

# 1. Get the name of the currently focused monitor (e.g., HDMI-A-1 or DP-3)
FOCUSED_MONITOR=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

# 2. Fallback just in case detection fails
if [ -z "$FOCUSED_MONITOR" ]; then
    echo "Could not detect monitor. Exiting."
    exit 1
fi

# 3. Execute based on the argument
case "$1" in
    clipboard)
        # grim captures the specific output (-o) and pipes it (-) to wl-copy
        grim -o "$FOCUSED_MONITOR" - | wl-copy
        notify-send "Screenshot Captured" "Monitor $FOCUSED_MONITOR copied to clipboard." -t 2000
        ;;
    file)
        # grim captures the specific output (-o) directly to the file
        grim -o "$FOCUSED_MONITOR" "$FILENAME"
        notify-send "Screenshot Saved" "Saved to $FILENAME" -t 2000
        ;;
    *)
        echo "Error: Invalid argument."
        echo "Usage: $0 {clipboard|file}"
        exit 1
        ;;
esac
