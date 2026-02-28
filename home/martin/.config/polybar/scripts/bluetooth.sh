#!/bin/bash

# File to store Bluetooth state
STATE_FILE="$HOME/.config/polybar/tmp/bluetooth_state"

# Initialize state file if missing
if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "off" > "$STATE_FILE"
fi

# Apply saved state at startup (only if bluetoothd is running)
apply_saved_state() {
    local SAVED_STATE=$(cat "$STATE_FILE")
    if [ "$(systemctl is-active bluetooth.service)" = "active" ]; then
        local CURRENT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
        if [ "$SAVED_STATE" = "off" ] && [ "$CURRENT_STATE" = "yes" ]; then
            echo "power off" | bluetoothctl >/dev/null 2>&1
        elif [ "$SAVED_STATE" = "on" ] && [ "$CURRENT_STATE" = "no" ]; then
            echo "power on" | bluetoothctl >/dev/null 2>&1
        fi
    fi
}

generate_output() {
    if [ "$(systemctl is-active bluetooth.service)" != "active" ]; then
        echo "%{F#ff5555}BT (service off)%{F-}"
        return
    fi

    if bluetoothctl show 2>/dev/null | grep -q "Powered: no"; then
        echo "%{F#6272a4}BT (off)%{F-}"
        return
    fi

    local paired_devices=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')

    if [ -n "$paired_devices" ]; then
        local connected=""
        local device_info=$({
            for dev in $paired_devices; do
                echo "info $dev"
            done
        } | bluetoothctl 2>/dev/null)

        for dev in $paired_devices; do
            if echo "$device_info" | grep -A 20 "Device $dev" | grep -q "Connected: yes"; then
                local name=$(echo "$device_info" | grep -A 20 "Device $dev" | grep "Alias" | cut -d ' ' -f2- | head -n1)
                connected="$connected, $name"
            fi
        done

        if [ -z "$connected" ]; then
            echo "%{F#38d8a3}BT (on)%{F-}"
        else
            echo "%{F#38d8a3}BT%{F-} ${connected#, }"
        fi
        return
    fi

    echo "%{F#38d8a3}BT (on)%{F-}"
}

# Handle click (separate invocation)
if [ "$1" == "click" ]; then
    if bluetoothctl show 2>/dev/null | grep -q "Powered: no"; then
        # Turn on and connect first paired device
        echo "power on" | bluetoothctl >/dev/null 2>&1
        sleep 1

        dev=$(bluetoothctl devices Paired 2>/dev/null | head -n1 | awk '{print $2}')
        if [ -n "$dev" ]; then
            name=$(echo "info $dev" | bluetoothctl 2>/dev/null | grep "Alias" | cut -d ' ' -f2-)
            echo "connect $dev" | bluetoothctl >/dev/null 2>&1
            notify-send "Bluetooth" "Connecting to $name"
        else
            notify-send "Bluetooth" "Turned on"
        fi

        echo "on" > "$STATE_FILE"
    else
        # Disconnect and turn off
        paired_devices=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')

        if [ -n "$paired_devices" ]; then
            for dev in $paired_devices; do
                if echo "info $dev" | bluetoothctl 2>/dev/null | grep -q "Connected: yes"; then
                    echo "disconnect $dev" | bluetoothctl >/dev/null 2>&1
                fi
            done
        fi

        echo "power off" | bluetoothctl >/dev/null 2>&1
        notify-send "Bluetooth" "Turned off"
        echo "off" > "$STATE_FILE"
    fi

    sleep 1

    # Signal the tail instance to refresh immediately
    for pid in $(pgrep -f "bluetooth.sh"); do
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
