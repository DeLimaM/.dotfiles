#!/bin/bash
#
# Monitor hotplug daemon — event-driven via udevadm monitor.
# Blocks on a kernel netlink socket (zero CPU when idle).
# Only wakes when a DRM subsystem event fires — then debounces
# and runs the hotplug handler.
#
# Started by systemd user service: monitor-hotplug.service
#

HANDLER="$HOME/.config/autorandr/hotplug-handler.sh"
LOGFILE="/tmp/autorandr-hotplug.log"
DEBOUNCE=3  # seconds to wait after first event before acting

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [monitor] $1" >> "$LOGFILE"; }

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/martin/.Xauthority}"

log "Event daemon started (udevadm monitor, debounce=${DEBOUNCE}s)"

# udevadm monitor blocks on netlink — zero CPU when idle.
# We filter to DRM subsystem change events only.
stdbuf -oL udevadm monitor --subsystem-match=drm --property 2>/dev/null |
    while read -r line; do
        # Only act on CHANGE actions (not ADD/REMOVE/BIND)
        if echo "$line" | grep -q "ACTION=change"; then
            log "DRM change event received — debouncing ${DEBOUNCE}s..."
            # Debounce: drain any further events for DEBOUNCE seconds
            while read -t "$DEBOUNCE" -r _; do :; done
            log "Debounce done — running handler"
            "$HANDLER"
        fi
    done
