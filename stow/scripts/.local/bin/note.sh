#!/usr/bin/env sh
set -eu

NOTES_DIR="${HOME}/Notes"
mkdir -p "$NOTES_DIR"
cd "$NOTES_DIR"

# 不带参数：创建临时文件，启用 g:note_save，并在退出后删除
if [ "$#" -eq 0 ]; then
  # macOS: mktemp 需要模板；Linux: 两种都兼容用这种写法
  tmpfile="$(mktemp "${NOTES_DIR}/note_tmp_XXXXXXXX.txt")"

  # 打开临时文件并开启 note_save
  vim -c 'let g:note_save=1' "$tmpfile"

  # 退出后删除临时文件（即使 Vim 里另存为了别的文件，这个临时壳也会被删）
  rm -f -- "$tmpfile"
  exit 0
fi

# 带参数：不设置 g:note_save，正常打开用户指定文件
exec vim "$@"
