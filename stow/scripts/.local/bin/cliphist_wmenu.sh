#!/usr/bin/env bash

set -euo pipefail

# 获取剪贴板列表
entries="$(cliphist list)"

# 如果没有条目，直接退出
[ -z "$entries" ] && exit 0

# 统计条目数量
count="$(printf '%s\n' "$entries" | wc -l)"

# 最大显示行数
max_lines=10

# 计算 wmenu 行数
if [ "$count" -gt "$max_lines" ]; then
  lines="$max_lines"
else
  lines="$count"
fi

# 调出菜单并复制
printf '%s\n' "$entries" \
  | wmenu -i -l "$lines" \
  | cliphist decode \
  | wl-copy
