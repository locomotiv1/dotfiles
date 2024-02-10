#!/bin/bash

DIR=/home/kacper/desktop-wallpapers/2560x1440/
PICS=($(ls ${DIR}))

RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

if [[ $(pidof swaybg) ]]; then
  pkill swaybg
fi

swww query || swww init

#change-wallpaper using swww
swww img ${DIR}/${RANDOMPICS} --transition-fps 60 --transition-type grow --transition-duration 1 --transition-pos 2470,1400 #position works only on 1440p
