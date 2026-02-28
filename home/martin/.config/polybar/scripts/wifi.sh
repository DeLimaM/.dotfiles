#!/bin/bash

STATE_FILE="$HOME/.config/polybar/tmp/wifi_state"

if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "on" > "$STATE_FILE"
fi

INTERFACE=$(ip link | grep -o 'wlp[0-9]s[0-9]\|wlan[0-9]' | head -n1)

if [ -z "$INTERFACE" ] && [ "$1" != "click" ]; then
    echo "%{F#ff5555}No WiFi%{F-}"
    # Keep running in case interface appears later
    while true; do
        INTERFACE=$(ip link | grep -o 'wlp[0-9]s[0-9]\|wlan[0-9]' | head -n1)
        if [ -n "$INTERFACE" ]; then
            break
        fi
        sleep 5
    done
fi

# Apply saved state at startup
apply_saved_state() {
    local SAVED_STATE=$(cat "$STATE_FILE")
    local CURRENT_STATE=$(nmcli radio wifi)
    if [ "$SAVED_STATE" = "off" ] && [ "$CURRENT_STATE" = "enabled" ]; then
        nmcli radio wifi off
    elif [ "$SAVED_STATE" = "on" ] && [ "$CURRENT_STATE" = "disabled" ]; then
        nmcli radio wifi on
    fi
}

generate_output() {
    if [ "$(nmcli radio wifi)" = "disabled" ]; then
        echo "%{F#6272a4}WiFi (off)%{F-}"
        return
    fi

    local CONNECTION=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d':' -f2)

    if [ -z "$CONNECTION" ]; then
        echo "%{F#f1fa8c}WiFi (on)%{F-}"
        return
    fi

    echo "%{F#38d8a3}WiFi%{F-} $CONNECTION"
}

# Handle click (separate invocation)
if [ "$1" == "click" ]; then
    if [ "$(nmcli radio wifi)" = "enabled" ]; then
        nmcli radio wifi off
        notify-send "WiFi" "Turned off"
        echo "off" > "$STATE_FILE"
    else
        nmcli radio wifi on
        notify-send "WiFi" "Turned on"
        echo "on" > "$STATE_FILE"
    fi

    # Signal the tail instance to refresh immediately
    for pid in $(pgrep -f "wifi.sh"); do
        [ "$pid" != "$$" ] && kill -USR1 "$pid" 2>/dev/null
    done
    exit 0
fi

# Apply saved state on first run
apply_saved_state

# Tail mode: USR1 interrupts sleep for instant refresh
trap 'true' USR1

while true; do
    generate_output
    sleep 5 &
    wait $!
done
