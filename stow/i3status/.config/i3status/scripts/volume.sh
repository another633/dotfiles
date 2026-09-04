#!/bin/sh

volume="$HOME/.cache/volume"

AMIX=$(amixer get Master)
VOL=$(echo "$AMIX" | grep -o '[0-9]*%' | head -n 1)
MUTE=$(echo "$AMIX" | grep -o '\[on\]\|\[off\]' | head -n 1)

if [ "$MUTE" = "[off]" ]; then
    echo "󰖁 muted" > "$volume"
else
    echo " $VOL" > "$volume"
fi
