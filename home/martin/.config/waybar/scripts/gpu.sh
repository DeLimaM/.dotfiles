#!/bin/bash
GPU_PATH="/sys/class/drm/card0/device/gpu_busy_percent"

if [ ! -f "$GPU_PATH" ]; then
    echo '{"text": "gpu --", "class": "error"}'
    exit 0
fi

usage=$(cat "$GPU_PATH")

if   [ "$usage" -lt 8  ]; then ramp="<span color='#55aa55'>▁</span>"
elif [ "$usage" -lt 22 ]; then ramp="<span color='#66bb55'>▂</span>"
elif [ "$usage" -lt 36 ]; then ramp="<span color='#77cc55'>▃</span>"
elif [ "$usage" -lt 50 ]; then ramp="<span color='#f5a70a'>▄</span>"
elif [ "$usage" -lt 65 ]; then ramp="<span color='#f5a70a'>▅</span>"
elif [ "$usage" -lt 79 ]; then ramp="<span color='#ff9933'>▆</span>"
elif [ "$usage" -lt 93 ]; then ramp="<span color='#ff5555'>▇</span>"
else                           ramp="<span color='#ff0000'>█</span>"
fi

echo "{\"text\": \"\uf26c ${usage}%\", \"tooltip\": \"GPU: ${usage}% ${ramp}\", \"class\": \"gpu\"}"
