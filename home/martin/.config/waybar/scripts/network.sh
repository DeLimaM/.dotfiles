#!/bin/bash
IFACE=$(ip -o link show | awk -F': ' '/wlp/{print $2}' | head -1)
[ -z "$IFACE" ] && echo '{"text": "\uf1eb off", "class": "disconnected"}' && exit 0

RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
sleep 1
RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)

DL=$(( (RX2 - RX1) ))
UL=$(( (TX2 - TX1) ))

fmt() {
    if [ "$1" -ge 1048576 ]; then
        printf "%5.1fM" "$(echo "scale=1; $1/1048576" | bc)"
    elif [ "$1" -ge 1024 ]; then
        printf "%5.1fK" "$(echo "scale=1; $1/1024" | bc)"
    else
        printf "%5.1fB" "$(echo "scale=1; $1/1" | bc)"
    fi
}

ESSID=$(iwgetid -r 2>/dev/null || echo "wifi")
SIGNAL=$(awk 'NR==3{printf "%.0f", $3*100/70}' /proc/net/wireless 2>/dev/null)
IP=$(ip -4 addr show $IFACE 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)

TEXT="$(fmt $DL)↓ $(fmt $UL)↑"
TOOLTIP="${ESSID} — ${SIGNAL}%\n${IP}\n↓ $(fmt $DL)/s  ↑ $(fmt $UL)/s"

echo "{\"text\": \"\\uf1eb ${TEXT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"connected\"}"
