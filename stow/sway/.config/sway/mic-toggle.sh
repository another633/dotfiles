#!/bin/bash

pactl set-source-mute @DEFAULT_SOURCE@ toggle

if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes; then
    notify-send -t 3500 "🎤 麦克风已关闭"
else
    notify-send -t 3500 "🎤 麦克风已开启"
fi
