#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR")" ]; then
    echo "Wallpaper directory not found or empty."
    exit 1
fi

RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

swaymsg output "*" bg "$RANDOM_WALLPAPER" fill
