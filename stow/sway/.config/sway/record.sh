#!/usr/bin/bash

DIR="$HOME/Videos/recordings"
TIME=$(date +"%Y-%m-%d_%H:%M:%S")
FILE="$DIR/${TIME}.mp4"
RECORDING="$HOME/.cache"
mkdir -p "$RECORDING"
mkdir -p "$DIR"

# -----------------------------
# 工具检查
# -----------------------------
for cmd in slurp swaymsg notify-send; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
				echo "Error: $cmd not found" >&2
				exit 1
		fi
done

# notify-send 可选
have_notify() {
		command -v notify-send >/dev/null 2>&1
}

notify() {
		if have_notify; then
				# $1 = title, $2 = body
				notify-send -t $1 "$2" "$3"
		fi
}

check_recording() {
		if pgrep -f "wf-recorder" > /dev/null; then
				echo " [REC]" > "$RECORDING/recording"
				killall -SIGUSR1 i3status
		else
				notify 1500 "Recording failed" "录制失败"
		fi
}

remode() {
		swaymsg 'mode "default"' >/dev/null
}

#提示录制全屏或框选录制

case "$1" in
		full)
				wf-recorder --audio -f "$FILE" >/dev/null &

				check_recording

				remode
				exit 0
				;;

		select)
				if ! GEOM=$(slurp); then
						remode
						exit 1
				fi

				if [ -z "$GEOM" ]; then
						remode
						exit 1
				fi

				wf-recorder --audio -g "$GEOM" -f "$FILE" >/dev/null &

				check_recording

				remode
				exit 0
				;;
esac

#有进程就杀掉
if pgrep -f "wf-recorder" > /dev/null && pkill wf-recorder > /dev/null; then
		echo "" > "$RECORDING/recording"
		killall -SIGUSR1 i3status
		notify 3000 "录制已停止" "$FILE"
		exit 0
fi

notify 3000 "Recording captured" "按 f 录制全屏， s 录制框选 , esc 放弃录制"

swaymsg 'mode "record-preview"' >/dev/null
