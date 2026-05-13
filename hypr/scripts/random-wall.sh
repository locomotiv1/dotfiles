#!/usr/bin/env bash

   WALL_DIR="$HOME/wallpapers"

   # Wait a second on startup to ensure the awww daemon is fully running
   sleep 1

   while true; do
       IMAGE=$(find "$WALL_DIR" -type f | shuf -n 1)

       # --transition-type options: random, wipe, wave, grow, center, fade, etc.
       awww img "$IMAGE" \
           --transition-type grow \
           --transition-fps 60 \
           --transition-step 30 \
           --transition-duration 2

   done
