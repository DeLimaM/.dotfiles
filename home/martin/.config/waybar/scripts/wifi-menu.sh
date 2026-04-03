#!/bin/bash
choice=$(printf "Connections\nWiFi On\nWiFi Off" | wofi --dmenu --prompt "WiFi" --width 250 --height 160 --cache-file /dev/null)

case "$choice" in
    "Connections") nm-connection-editor ;;
    "WiFi On")     nmcli radio wifi on && notify-send "WiFi" "Turned on" ;;
    "WiFi Off")    nmcli radio wifi off && notify-send "WiFi" "Turned off" ;;
esac
