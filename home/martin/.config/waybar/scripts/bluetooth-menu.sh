#!/bin/bash
RFKILL=/usr/sbin/rfkill

bt_status() {
    if $RFKILL list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
        echo "off"; return
    fi
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "on" || echo "off"
}

build_menu() {
    if [ "$(bt_status)" = "off" ]; then
        printf "Power On"
    else
        printf "Power Off\nDevices"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            mac=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | cut -d' ' -f3-)
            if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
                printf "\n  ✓ %s" "$name"
            else
                printf "\n  ○ %s" "$name"
            fi
        done < <(bluetoothctl devices Paired 2>/dev/null)
    fi
}

choice=$(build_menu | wofi --dmenu --prompt "Bluetooth" --width 280 --height 250 --cache-file /dev/null)

case "$choice" in
    "Power On")
        $RFKILL unblock bluetooth 2>/dev/null
        sleep 0.5
        bluetoothctl power on >/dev/null 2>&1
        notify-send "Bluetooth" "Powered on"
        pkill -RTMIN+9 waybar
        ;;
    "Power Off")
        for dev in $(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}'); do
            bluetoothctl disconnect "$dev" >/dev/null 2>&1
        done
        bluetoothctl power off >/dev/null 2>&1
        $RFKILL block bluetooth 2>/dev/null
        notify-send "Bluetooth" "Powered off"
        pkill -RTMIN+9 waybar
        ;;
    "Devices")
        blueman-manager ;;
    "  ✓ "*)
        name="${choice#  ✓ }"
        mac=$(bluetoothctl devices Paired 2>/dev/null | grep "$name" | awk '{print $2}')
        [ -n "$mac" ] && bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Disconnected $name"
        pkill -RTMIN+9 waybar
        ;;
    "  ○ "*)
        name="${choice#  ○ }"
        mac=$(bluetoothctl devices Paired 2>/dev/null | grep "$name" | awk '{print $2}')
        [ -n "$mac" ] && bluetoothctl connect "$mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Connecting to $name"
        pkill -RTMIN+9 waybar
        ;;
esac
