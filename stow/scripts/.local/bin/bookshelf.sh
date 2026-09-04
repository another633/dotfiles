#!/usr/bin/bash

DIR="$HOME/Books"
MAX_LINES=10

for cmd in zathura; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
				echo "Error: $cmd not found" >&2
				exit 1
		fi
done

if [ ! -d "$DIR" ]; then
	mkdir -p "$DIR"
fi

BOOKS=$(find "$DIR/" -name '*.pdf')

count="$(printf '%s\n' "$BOOKS" | wc -l)"
# 计算 wmenu 行数
if [ "$count" -gt "$MAX_LINES" ]; then
		lines="$MAX_LINES"
else
		lines="$count"
fi

BOOK=$(echo "$BOOKS" | xargs -I {} basename {} | wmenu -i -l "$lines" -p "BookShelf: ")

BOOK=$(echo "$BOOKS" | grep "$BOOK")

if [ -z "$BOOK" ]; then
		notify-send -t 3000 "Book not found"
else
		if ! zathura "$BOOK" >/dev/null 2>&1; then
				notify-send -t 3000 "Open book failed : $BOOK"
		fi
fi
