#!/bin/bash

# GPU utilization monitor for polybar (AMD)
# Reads directly from sysfs — no external tools spawned

GPU_PATH="/sys/class/drm/card0/device/gpu_busy_percent"

generate_output() {
    if [ ! -f "$GPU_PATH" ]; then
        echo "%{F#ff5555}GPU N/A%{F-}"
        return
    fi

    local usage=$(cat "$GPU_PATH")

    # Thresholds aligned with polybar's built-in ramp formula: round(pct * 7 / 100)
    local ramp
    if   [ "$usage" -lt 8  ]; then ramp="%{F#55aa55}▁▁%{F-}"
    elif [ "$usage" -lt 22 ]; then ramp="%{F#66bb55}▂▂%{F-}"
    elif [ "$usage" -lt 36 ]; then ramp="%{F#77cc55}▃▃%{F-}"
    elif [ "$usage" -lt 50 ]; then ramp="%{F#f5a70a}▄▄%{F-}"
    elif [ "$usage" -lt 65 ]; then ramp="%{F#f5a70a}▅▅%{F-}"
    elif [ "$usage" -lt 79 ]; then ramp="%{F#ff9933}▆▆%{F-}"
    elif [ "$usage" -lt 93 ]; then ramp="%{F#ff5555}▇▇%{F-}"
    else                           ramp="%{F#ff0000}██%{F-}"
    fi

    echo "%{F#38d8a3}GPU%{F-} ${usage}% ${ramp}"
}

while true; do
    generate_output
    sleep 2
done