#!/usr/bin/env bash

# Kill old bars
polybar-msg cmd quit
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# Launch one bar per connected monitor
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main 2>&1 | tee -a /tmp/polybar-$m.log &
done

echo "Bars launched..."


