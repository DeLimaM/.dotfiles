#!/bin/bash
# Battery + power profile module for waybar
# Left-click cycles through power-profiles-daemon profiles

if [ "$1" == "click" ]; then
    CURRENT=$(powerprofilesctl get 2>/dev/null)
    case "$CURRENT" in
        power-saver)  NEW="balanced" ;;
        balanced)     NEW="performance" ;;
        performance)  NEW="power-saver" ;;
        *)            NEW="balanced" ;;
    esac
    powerprofilesctl set "$NEW" 2>/dev/null
    notify-send "Power: $NEW"
    pkill -RTMIN+8 waybar
    exit 0
fi

PROFILE=$(powerprofilesctl get 2>/dev/null)
case "$PROFILE" in
    power-saver)  PLABEL="ECO" ;;
    balanced)     PLABEL="BAL" ;;
    performance)  PLABEL="PERF" ;;
    *)            PLABEL="?" ;;
esac

PERC=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")
STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null | tr '[:upper:]' '[:lower:]')

case "$STATUS" in
    charging)    text="\uf0e7 ${PERC}%+ ${PLABEL}"; class="charging" ;;
    discharging) text="\uf242 ${PERC}% ${PLABEL}"; [ "$PERC" != "?" ] && [ "$PERC" -lt 15 ] && class="critical" || class="discharging" ;;
    *)           text="\uf240 ${PERC}% ${PLABEL}"; class="full" ;;
esac

echo "{\"text\": \"${text}\", \"class\": \"${class}\"}"
