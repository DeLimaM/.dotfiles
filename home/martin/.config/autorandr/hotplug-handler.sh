#!/bin/bash
#
# Monitor hotplug handler — "plug and play" for any display.
# Triggered by udevadm monitor daemon via systemd.
#
# Flow:
#   1. Acquire lock (flock) to prevent parallel runs from rapid events
#   2. Wait for DRM to settle
#   3. If a known autorandr profile matches → apply it
#   4. Otherwise → build a single xrandr command to enable all externals
#   5. Relaunch polybar, reset wallpaper
#
# Optimized to issue a single xrandr call to minimize display flicker.
#

LOCKFILE="/tmp/autorandr-hotplug.lock"
LOGFILE="/tmp/autorandr-hotplug.log"
POSITIONS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/autorandr/display-positions.conf"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"; }

# ── Acquire exclusive lock (non-blocking — skip if another instance runs) ──
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped (another instance holds the lock)" >> "$LOGFILE"
    exit 0
fi

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/martin/.Xauthority}"

# Let DRM/xrandr settle after the physical plug event
sleep 2

log "=== Hotplug event ==="

# ── Single xrandr call to get all output info + EDID properties ──
XRANDR_PROP=$(xrandr --prop 2>/dev/null)

# Parse connected/disconnected outputs from the cached data
LAPTOP=$(echo "$XRANDR_PROP" | grep "^eDP" | grep " connected" | cut -d" " -f1)
EXTERNALS=$(echo "$XRANDR_PROP" | grep " connected" | grep -v "^eDP" | cut -d" " -f1)
DISCONNECTED=$(echo "$XRANDR_PROP" | grep " disconnected" | cut -d" " -f1)

# Get EDID hash from cached xrandr --prop output (no extra xrandr call)
get_edid_hash() {
    local output="$1"
    local edid_hex
    edid_hex=$(echo "$XRANDR_PROP" | awk "
        /^${output} connected/  { found=1; next }
        found && /^[A-Za-z]/    { exit }
        found && /EDID:/        { edid=1; next }
        edid && /^\t\t/         { printf \"%s\", \$1; next }
        edid                    { exit }
    ")
    if [ -n "$edid_hex" ]; then
        echo -n "$edid_hex" | md5sum | cut -c1-8
    fi
}

get_saved_position() {
    local hash="$1"
    [ -f "$POSITIONS_CONF" ] || return 1
    grep -m1 "^${hash}=" "$POSITIONS_CONF" 2>/dev/null | cut -d= -f2-
}

if [ -z "$EXTERNALS" ]; then
    # ── No externals: undocked — single xrandr call ──
    log "No external monitors — undocked mode"
    XRANDR_CMD="xrandr --output $LAPTOP --auto --primary"
    for out in $DISCONNECTED; do
        XRANDR_CMD="$XRANDR_CMD --output $out --off"
    done
    eval "$XRANDR_CMD" 2>>"$LOGFILE"
else
    # ── Try autorandr for a known profile first ──
    DETECTED=$(autorandr 2>/dev/null | grep "(detected)")
    if [ -n "$DETECTED" ]; then
        PROFILE=$(echo "$DETECTED" | awk '{print $1}' | head -1)
        log "Known profile: $PROFILE — applying"
        autorandr --change --default undocked >> "$LOGFILE" 2>&1
    else
        # ── Build a single xrandr command for all outputs at once ──
        log "Unknown display(s): $EXTERNALS — enabling with saved positions"
        XRANDR_CMD="xrandr --output $LAPTOP --auto --primary"
        PREV="$LAPTOP"
        for out in $EXTERNALS; do
            HASH=$(get_edid_hash "$out")
            SAVED_POS=""
            if [ -n "$HASH" ]; then
                SAVED_POS=$(get_saved_position "$HASH")
            fi
            if [ -n "$SAVED_POS" ]; then
                # shellcheck disable=SC2086
                XRANDR_CMD="$XRANDR_CMD --output $out --auto $SAVED_POS"
                log "  $out ($HASH) saved: $SAVED_POS"
            else
                XRANDR_CMD="$XRANDR_CMD --output $out --auto --right-of $PREV"
                log "  $out ($HASH) default: --right-of $PREV"
            fi
            PREV="$out"
        done
        log "  Command: $XRANDR_CMD"
        eval "$XRANDR_CMD" 2>>"$LOGFILE"
    fi
fi

# ── Post-switch hooks (no i3 reload — i3 picks up RandR changes automatically) ──
log "Running post-switch hooks..."

# Polybar
if [ -x "$HOME/.config/polybar/launch.sh" ]; then
    "$HOME/.config/polybar/launch.sh" >> "$LOGFILE" 2>&1 &
fi

# Wallpaper
feh --no-fehbg --bg-fill /home/martin/Pictures/wallpapers/dark-synth.jpg 2>>"$LOGFILE"

# Notification
if command -v notify-send &>/dev/null; then
    if [ -n "$EXTERNALS" ]; then
        notify-send -u normal -t 3000 "Display connected" "$EXTERNALS"
    else
        notify-send -u normal -t 3000 "Display disconnected" "Laptop only"
    fi
fi

log "=== Done ==="
flock -u 9
