#!/bin/bash
if [ "$(nmcli radio wifi)" = "enabled" ]; then
    nmcli radio wifi off
    notify-send "WiFi" "Turned off"
    pkill -RTMIN+10 waybar
else
    nmcli radio wifi on
    notify-send "WiFi" "Turned on"
    pkill -RTMIN+10 waybar
fi
