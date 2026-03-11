#!/bin/bash
#
# Save the current position of each external display, keyed by its EDID hash.
# Run after repositioning displays (e.g. via arandr) to remember the layout.
#

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/autorandr/display-positions.conf"
LOGFILE="/tmp/autorandr-hotplug.log"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/martin/.Xauthority}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [save] $1" >> "$LOGFILE"; }

# Get EDID hash for a given xrandr output name
get_edid_hash() {
    local output="$1"
    local edid_hex
    edid_hex=$(xrandr --prop 2>/dev/null | awk "
        /^${output} connected/  { found=1; next }
        found && /^[A-Za-z]/    { exit }
        found && /EDID:/        { edid=1; next }
        edid && /^\t\t/         { printf \"%s\", \$1; next }
        edid                    { exit }
    ")
    if [ -n "$edid_hex" ] && [ "$edid_hex" != "d41d8cd9" ]; then
        echo -n "$edid_hex" | md5sum | cut -c1-8
        return
    fi
}

# Determine relation between two outputs from current xrandr geometry
get_relation() {
    local target="$1" ref="$2"
    local info
    info=$(xrandr --query 2>/dev/null)

    # Parse geometry: WxH+X+Y
    local t_geom r_geom
    t_geom=$(echo "$info" | grep "^$target connected" | grep -oP '\d+x\d+\+\d+\+\d+')
    r_geom=$(echo "$info" | grep "^$ref connected" | grep -oP '\d+x\d+\+\d+\+\d+')

    [ -z "$t_geom" ] || [ -z "$r_geom" ] && echo "--right-of" && return

    local t_w t_h t_x t_y r_w r_h r_x r_y
    IFS='x+' read -r t_w t_h t_x t_y <<< "$t_geom"
    IFS='x+' read -r r_w r_h r_x r_y <<< "$r_geom"

    # Determine spatial relationship
    if [ "$t_x" -ge "$((r_x + r_w - 10))" ]; then
        echo "--right-of"
    elif [ "$((t_x + t_w))" -le "$((r_x + 10))" ]; then
        echo "--left-of"
    elif [ "$t_y" -ge "$((r_y + r_h - 10))" ]; then
        echo "--below"
    elif [ "$((t_y + t_h))" -le "$((r_y + 10))" ]; then
        echo "--above"
    else
        echo "--right-of"  # Overlap or same-origin — default
    fi
}

# ── Main ──
LAPTOP=$(xrandr --query 2>/dev/null | grep "^eDP" | grep " connected" | cut -d" " -f1)
EXTERNALS=$(xrandr --query 2>/dev/null | grep " connected" | grep -v "^eDP" | cut -d" " -f1)

if [ -z "$EXTERNALS" ]; then
    notify-send -u normal -t 3000 "No external display" "Nothing to save" 2>/dev/null
    exit 0
fi

# Ensure config file exists with header
[ -f "$CONF" ] || cat > "$CONF" << 'EOF'
# Display position preferences — auto-managed by save-display-position.sh
# Format: EDID_HASH=RELATION REFERENCE_OUTPUT
EOF

SAVED=""
PREV_REF="$LAPTOP"
for out in $EXTERNALS; do
    HASH=$(get_edid_hash "$out")
    if [ -z "$HASH" ] || [ "$HASH" = "d41d8cd9" ]; then
        log "Could not get EDID for $out — skipping"
        continue
    fi

    RELATION=$(get_relation "$out" "$PREV_REF")
    ENTRY="${HASH}=${RELATION} ${PREV_REF}"

    # Update or append
    if grep -q "^${HASH}=" "$CONF" 2>/dev/null; then
        sed -i "s|^${HASH}=.*|${ENTRY}|" "$CONF"
    else
        echo "$ENTRY" >> "$CONF"
    fi

    log "Saved position: $out ($HASH) → $RELATION $PREV_REF"
    SAVED="${SAVED}${out}: ${RELATION} ${PREV_REF}\n"
    PREV_REF="$out"
done

if command -v notify-send &>/dev/null && [ -n "$SAVED" ]; then
    notify-send -u normal -t 3000 "Display layout saved" "$(echo -e "$SAVED")"
fi
