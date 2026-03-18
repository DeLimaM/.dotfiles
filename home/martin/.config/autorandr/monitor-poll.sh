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

# Snapshot of connected outputs AND their active modes/geometry.
# This catches: new display, removed display, and reconnected-but-no-signal.
get_display_state() {
    xrandr --query 2>/dev/null | grep -E "^[A-Za-z].* connected" | sed 's/ (.*//'
}

PREV_STATE=$(get_display_state)
log "Initial display state: $(echo "$PREV_STATE" | tr '\n' '; ')"

# udevadm monitor blocks on netlink — zero CPU when idle.
# We filter to DRM subsystem change events only.
stdbuf -oL udevadm monitor --subsystem-match=drm --property 2>/dev/null |
    while read -r line; do
        # Only act on CHANGE actions (not ADD/REMOVE/BIND)
        if echo "$line" | grep -q "ACTION=change"; then
            log "DRM change event received — debouncing ${DEBOUNCE}s..."
            # Debounce: drain any further events for DEBOUNCE seconds
            while read -t "$DEBOUNCE" -r _; do :; done
            # Check if display state changed (outputs + active modes)
            CURRENT_STATE=$(get_display_state)
            if [ "$CURRENT_STATE" != "$PREV_STATE" ]; then
                log "Display state changed — running handler"
                "$HANDLER"
                PREV_STATE=$(get_display_state)
            else
                # Also check if any connected external has no active mode
                INACTIVE=$(xrandr --query 2>/dev/null | grep -E "^[A-Za-z]" | grep " connected" | grep -v "eDP" | grep -v "[0-9]x[0-9]")
                if [ -n "$INACTIVE" ]; then
                    log "Connected display without active mode detected — running handler"
                    "$HANDLER"
                    PREV_STATE=$(get_display_state)
                else
                    log "Display state unchanged — ignoring (power event?)"
                fi
            fi
        fi
    done
