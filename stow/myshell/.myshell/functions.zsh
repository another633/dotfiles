#!/usr/bin/bash

mpv() {
		local DIR="$HOME/Videos/recordings"
		#如果没有传入参数
		if [ -z "$1" ]; then
        local latest_mp3=$(ls -t "$DIR"/*.mp4 | head -1)

				/usr/bin/mpv --gpu-api=opengl --vo=gpu "$latest_mp3"
		else
				/usr/bin/mpv --gpu-api=opengl --vo=gpu "$@"
		fi
}
