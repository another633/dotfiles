#!/usr/bin/env bash

dict_history=$HOME/.dict_history
MAX_LINES=10
MAX_HISTORY=100
TOFI_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

# 查询新单词时杀掉 tofi
pgrep -f "tofi" > /dev/null && pkill tofi
pgrep -f "wmenu" > /dev/null && pkill wmenu

if [ ! -f "$dict_history" ]; then
	touch "$dict_history"
fi

history_count="$(wc -l < "$dict_history")"
if [ "$history_count" -gt "$MAX_HISTORY" ]; then
	sed -i "1,$((history_count - MAX_HISTORY))d" "$dict_history"
fi

count="$(wc -l < "$dict_history")"
# 计算 wmenu 行数
if [ "$count" -gt "$MAX_LINES" ]; then
		lines="$MAX_LINES"
else
		lines="$count"
fi

entry=$(tac "$dict_history" | wmenu -p "单词:" -i -l "$lines" -N 000000)
# 查词加'.'可避免匹配长单词(包含查询单词)。'.'在此处去除
entry=$(printf '%s\n' "$entry" | sed 's/\.//g')

if [ -n "$entry" ]; then
	if [ "$(tail -n 1 "$dict_history")" != "$entry" ]; then
		printf '%s\n' "$entry" >> "$dict_history"
		history_count="$(wc -l < "$dict_history")"
		if [ "$history_count" -gt "$MAX_HISTORY" ]; then
			sed -i "1,$((history_count - MAX_HISTORY))d" "$dict_history"
		fi
	fi
	/usr/local/bin/dict "$entry" - | tofi --output "$TOFI_OUTPUT" --width 80% > /dev/null &
	#play
	/usr/local/bin/dict "$entry" > /dev/null
fi
