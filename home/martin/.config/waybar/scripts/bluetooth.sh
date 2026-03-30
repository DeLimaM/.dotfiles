#!/bin/bash
# Bluetooth status module for waybar
# Left-click opens blueman-manager (handled by waybar on-click)

if [ "$(systemctl is-active bluetooth.service)" != "active" ] || bluetoothctl show 2>/dev/null | grep -q "Powered: no"; then
    echo '{"text": "bt off", "class": "off"}'
    exit 0
fi

connected=""
for dev in $(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}'); do
    info=$(bluetoothctl info "$dev" 2>/dev/null)
    if echo "$info" | grep -q "Connected: yes"; then
        name=$(echo "$info" | grep "Alias" | cut -d ' ' -f2- | head -n1)
        connected="${connected}, ${name}"
    fi
done

if [ -z "$connected" ]; then
    echo '{"text": "bt", "class": "on"}'
else
    echo "{\"text\": \"bt ${connected#, }\", \"class\": \"connected\"}"
fi
