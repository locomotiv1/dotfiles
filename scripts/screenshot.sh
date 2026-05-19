#!/usr/bin/env bash

# Directory to save screenshots
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Filename format: screenshot_YYYY-MM-DD_HH-MM-SS.png
FILENAME="$SAVE_DIR/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

# 1. Get current mouse coordinates
eval $(xdotool getmouselocation --shell)
# This command exposes $X and $Y as shell variables

# 2. Find the geometry of the monitor containing the mouse cursor
GEOMETRY=$(xrandr | grep ' connected' | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+' | while read -r geom; do
    # Extract width, height, x-offset, y-offset from a string like 1920x1080+1920+0
    w=$(echo "$geom" | cut -d'x' -f1)
    rest=$(echo "$geom" | cut -d'x' -f2)
    h=$(echo "$rest" | cut -d'+' -f1)
    x=$(echo "$rest" | cut -d'+' -f2)
    y=$(echo "$rest" | cut -d'+' -f3)

    # Check if the mouse (X, Y) falls inside this specific monitor's bounding box
    if [ "$X" -ge "$x" ] && [ "$X" -lt "$((x + w))" ] && \
       [ "$Y" -ge "$y" ] && [ "$Y" -lt "$((y + h))" ]; then
        echo "$geom"
        break
    fi
done)

# 3. Fallback to full screen if detection fails for any reason
if [ -z "$GEOMETRY" ]; then
    GEOMETRY="root"
fi

# 4. Execute based on the argument provided by your dwm config
case "$1" in
    clipboard)
        if [ "$GEOMETRY" = "root" ]; then
            maim -u | xclip -selection clipboard -t image/png
        else
            maim -u -g "$GEOMETRY" | xclip -selection clipboard -t image/png
        fi
        notify-send "Screenshot Captured" "Current monitor copied to clipboard." -i "accessories-screenshot" -t 2000
        ;;
    file)
        if [ "$GEOMETRY" = "root" ]; then
            maim -u "$FILENAME"
        else
            maim -u -g "$GEOMETRY" "$FILENAME"
        fi
        notify-send "Screenshot Saved" "Saved to $FILENAME" -i "accessories-screenshot" -t 2000
        ;;
    *)
        echo "Error: Invalid argument."
        echo "Usage: $0 {clipboard|file}"
        exit 1
        ;;
esac
