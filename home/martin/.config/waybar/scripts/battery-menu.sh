#!/bin/bash
CURRENT=$(powerprofilesctl get 2>/dev/null)
PERC=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

build_menu() {
    for p in power-saver balanced performance; do
        if [ "$p" = "$CURRENT" ]; then
            printf "● %s\n" "$p"
        else
            printf "  %s\n" "$p"
        fi
    done
}

choice=$(build_menu | wofi --dmenu --prompt "Power — ${PERC}% ${STATUS}" --width 280 --height 160 --cache-file /dev/null)

selected=$(echo "$choice" | sed 's/^[● ] *//')

case "$selected" in
    power-saver|balanced|performance)
        powerprofilesctl set "$selected" 2>/dev/null
        notify-send "Power" "Set to $selected"
        pkill -RTMIN+8 waybar
        ;;
esac
