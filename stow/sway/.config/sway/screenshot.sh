#!/usr/bin/env bash

DIR="$HOME/Pictures/screenshots"
PENDING="/tmp/swayshot_pending.png"
mkdir -p "$DIR"

# -----------------------------
# 工具检查
# -----------------------------
for cmd in slurp grim swaymsg swayimg; do
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

# -----------------------------
# 处理动作：save / delete / reselect
# -----------------------------
case "$1" in
		floating)
				#悬浮显示图片
        if [ ! -f "$PENDING" ]; then
							notify 3500 "Screenshot not found" "截图不存在"
            exit 1
        fi
				swayimg "$PENDING"
        rm -f "$PENDING"
        swaymsg 'mode "default"' >/dev/null
				exit 0
				;;

    save)
        if [ ! -f "$PENDING" ]; then
            exit 1
        fi

				# pgrep -f "swayimg $PENDING" > /dev/null && pkill swayimg
        TIME=$(date +"%Y-%m-%d_%H:%M:%S")
        FILE="$DIR/${TIME}.png"

        if mv "$PENDING" "$FILE"; then
            # 复制到剪贴板（可选）
            if command -v wl-copy >/dev/null 2>&1; then
                wl-copy < "$FILE"
            fi
            notify 1500 "Screenshot saved" "已保存到：$FILE"
        fi

        swaymsg 'mode "default"' >/dev/null
        exit 0
        ;;

    delete)
				# pgrep -f "swayimg $PENDING" > /dev/null && pkill swayimg
        rm -f "$PENDING"
        notify 1500 "Screenshot deleted" "截图已删除"
        swaymsg 'mode "default"' >/dev/null
        exit 0
        ;;

    reselect)
				pgrep -f "swayimg $PENDING" > /dev/null && pkill swayimg
        rm -f "$PENDING"
        swaymsg 'mode "default"' >/dev/null
        # 重新执行自己，相当于重新框选
        exec "$0"
        ;;
esac

# -----------------------------
# 第一次调用：框选 + 截图
# -----------------------------
GEOM=$(slurp) || exit 1
[ -z "$GEOM" ] && exit 1

if ! grim -g "$GEOM" "$PENDING"; then
    exit 1
fi

# 截完图后用通知提示用户当前在 screenshot-preview 模式
notify 3000 "Screenshot captured" "按 f 悬浮显示图片, s 保存, d 删除, r 重选（当前为 screenshot-preview 模式）"

# 进入 screenshot-preview 模式（在 sway 配置里绑定 s/d/r）
swaymsg 'mode "screenshot-preview"' >/dev/null
