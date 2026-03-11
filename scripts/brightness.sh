#!/bin/bash

DISPLAY_ID=1
STEP=10

if [ "$1" == "up" ]; then
  ddcutil --display $DISPLAY_ID setvcp 10 + $STEP
elif [ "$1" == "down" ]; then
  ddcutil --display $DISPLAY_ID setvcp 10 - $STEP
fi

BRIGHTNESS=$(ddcutil --display $DISPLAY_ID getvcp 10 -t | awk '{print $4}')

notify-send -h string:x-dunst-stack-tag:brightness "☀️ Brightness" "${BRIGHTNESS}%"
