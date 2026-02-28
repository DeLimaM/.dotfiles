#!/bin/bash

# File to store current mode
MODE_FILE="$HOME/.config/polybar/tmp/power_mode_state"

# Initialize mode file if missing
if [ ! -f "$MODE_FILE" ]; then
    mkdir -p "$(dirname "$MODE_FILE")"
    echo "ECO" > "$MODE_FILE"
fi

generate_output() {
    local MODE=$(cat "$MODE_FILE")
    local BAT_PATH="/sys/class/power_supply/BAT0"
    local PERC=$(cat "$BAT_PATH/capacity")
    local STATUS=$(cat "$BAT_PATH/status" | tr '[:upper:]' '[:lower:]')

    if [ "$STATUS" == "charging" ]; then
        echo "%{F#38d8a3}BAT (charging)%{F-} $PERC% %{F#38d8a3}[$MODE]%{F-}"
    elif [ "$STATUS" == "discharging" ]; then
        if [ "$PERC" -lt 15 ]; then
            echo "%{F#ff5555}BATTERY LOW%{F-} $PERC% %{F#38d8a3}[$MODE]%{F-}"
        else
            echo "%{F#38d8a3}BAT (discharging)%{F-} $PERC% %{F#38d8a3}[$MODE]%{F-}"
        fi
    else
        echo "%{F#38d8a3}BAT (fully charged)%{F-} $PERC% %{F#38d8a3}[$MODE]%{F-}"
    fi
}

# Handle click (separate invocation)
if [ "$1" == "click" ]; then
    MODE=$(cat "$MODE_FILE")
    case "$MODE" in
        ECO)
            MODE="BAL"
            cpupower frequency-set -g ondemand 2>/dev/null
            ;;
        BAL)
            MODE="PERF"
            cpupower frequency-set -g performance 2>/dev/null
            ;;
        PERF)
            MODE="ECO"
            cpupower frequency-set -g powersave 2>/dev/null
            ;;
    esac
    echo "$MODE" > "$MODE_FILE"
    notify-send "Power mode switched" "$MODE"

    # Signal the tail instance to refresh immediately
    for pid in $(pgrep -f "battery.sh"); do
        [ "$pid" != "$$" ] && kill -USR1 "$pid" 2>/dev/null
    done
    exit 0
fi

# Tail mode: USR1 interrupts sleep for instant refresh
trap 'true' USR1

while true; do
    generate_output
    sleep 5 &
    wait $!
done
