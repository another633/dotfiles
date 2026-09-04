#光标最近位置的单词插入命令行替换符号: $()
#例:
# git clone clip => git clone $(clip)
_wrap_last_word_cmd_subst() {
    # 保存初始光标
    local pos=$CURSOR

    # ⬅ 找最近单词的开头
    zle backward-word
    local start=$CURSOR

    # ➡ 找最近单词的结尾
    zle forward-word
    local end=$CURSOR

    # zsh 下标从 1 开始
    local s=$(( start + 1 ))
    local e=$(( end ))

    # 取出 word
    local word="${BUFFER[s,e]}"

    # --- 去除 word 后面多余空格 ---
    word="${word%"${word##*[![:space:]]}"}"
    # 上面的写法会 trim 右侧的所有空格（zsh 原生）

    # 构造 $(word)
    local wrapped='$('"${word}"')'

    # 重新组装 BUFFER
    BUFFER="${BUFFER[1,start]}${wrapped}${BUFFER[end+1,-1]}"

    # 光标放在右括号后
    CURSOR=$(( start + ${#wrapped} ))
}

zle -N _wrap_last_word_cmd_subst
bindkey '\em' _wrap_last_word_cmd_subst   # Alt+m

_dict() {
  emulate -L zsh -o no_aliases

  # 只在当前行非空时触发
  [[ -z "$BUFFER" ]] && { zle redisplay; return }

  local orig="$BUFFER"

  # 把 ZLE 的重绘刷下去，否则直接 print 会和提示符重叠
  zle -I

  # 在新的一行先回显原输入（加个前缀，避免误执行）
  # print -r -- ""
  # print -r -- "▶ aichat < $orig"

  dict $orig

  # 末尾补一个空行，让提示符更清楚
  print -r -- ""

  # 清空编辑缓冲区并重置光标，然后重绘一个全新的提示符
  BUFFER=""
  CURSOR=0
  # zle reset-prompt
}

zle -N _dict
bindkey '^[t' _dict
