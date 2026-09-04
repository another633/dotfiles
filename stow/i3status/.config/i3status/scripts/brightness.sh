#!/bin/bash

BL="/sys/class/backlight/intel_backlight"
cur=$(cat "$BL/brightness")
max=$(cat "$BL/max_brightness")
echo "$((cur * 100 / max))%" > ~/.cache/brightness
