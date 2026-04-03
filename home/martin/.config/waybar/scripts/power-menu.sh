#!/bin/bash
choice=$(printf "Lock\nSuspend\nReboot\nShutdown\nLogout" | wofi --dmenu --prompt "Power" --width 200 --height 210 --cache-file /dev/null)

case "$choice" in
    Lock)     swaylock -f -c 000000 ;;
    Suspend)  systemctl suspend ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
    Logout)   swaymsg exit ;;
esac
