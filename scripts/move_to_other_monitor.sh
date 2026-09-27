#!/usr/bin/env bash

# Check dependencies
for cmd in swaymsg jq; do
  if ! command -v "$cmd" &>/dev/null; then
    notify-send "Sway Error" "$cmd is required but not installed."
    exit 1
  fi
done

# Get the name of the focused workspace
CURRENT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

if [[ -z "$CURRENT_WS" ]]; then
  exit 0
fi

# Map workspace between HDMI-A-1 and DP-3
# Format on DP-3: "1<N>:<N>" (e.g., 14:4, 110:10)
# Format on HDMI-A-1: "<N>" (e.g., 4, 10)
if [[ "$CURRENT_WS" =~ ^1[0-9]+:([0-9]+)$ ]]; then
  # Window is on DP-3, target is the counterpart on HDMI-A-1
  TARGET_WS="${BASH_REMATCH[1]}"
elif [[ "$CURRENT_WS" =~ ^[0-9]+$ ]]; then
  # Window is on HDMI-A-1, target is the counterpart on DP-3
  TARGET_WS="1${CURRENT_WS}:${CURRENT_WS}"
else
  # Fallback for unmapped or named workspaces: simply send to the next output
  swaymsg move container to output right
  exit 0
fi

# Move the container and retain focus
swaymsg "move container to workspace \"$TARGET_WS\"; workspace \"$TARGET_WS\""
