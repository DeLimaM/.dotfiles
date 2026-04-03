#!/bin/bash
choice=$(printf "Display Settings\nInternal Only\nMirror\nExtend Right\nExtend Left" | wofi --dmenu --prompt "Display" --width 250 --height 210 --cache-file /dev/null)

INTERNAL=$(swaymsg -t get_outputs | grep -o '"eDP-[^"]*"' | tr -d '"' | head -1)
EXTERNAL=$(swaymsg -t get_outputs | grep -o '"[A-Z]*-[A-Z]*-[0-9]*"' | tr -d '"' | grep -v eDP | head -1)

case "$choice" in
    "Display Settings") wdisplays ;;
    "Internal Only")
        [ -n "$EXTERNAL" ] && swaymsg output "$EXTERNAL" disable
        swaymsg output "$INTERNAL" enable
        notify-send "Display" "Internal only"
        ;;
    "Mirror")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$EXTERNAL" enable position 0 0
            swaymsg output "$INTERNAL" enable position 0 0
            notify-send "Display" "Mirrored"
        fi
        ;;
    "Extend Right")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" enable position 0 0
            swaymsg output "$EXTERNAL" enable position 1920 0
            notify-send "Display" "Extended right"
        fi
        ;;
    "Extend Left")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$EXTERNAL" enable position 0 0
            swaymsg output "$INTERNAL" enable position 1920 0
            notify-send "Display" "Extended left"
        fi
        ;;
esac
