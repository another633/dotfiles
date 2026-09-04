# 此文件由 dotfiles 仓库管理。
export PATH="$HOME/.local/bin:$PATH"

export ZSH="$HOME/.local/share/oh-my-zsh/current"
ZSH_THEME="robbyrussell"
plugins=(git)
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# 语法高亮必须在其他 Zsh 插件之后加载。
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

local_config=${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local/zshrc
[[ -r $local_config ]] && source "$local_config"
unset local_config
