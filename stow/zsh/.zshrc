# 此文件由 dotfiles 仓库管理。
export PATH="$HOME/.local/bin:$PATH"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

local_config=${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local/zshrc
[[ -r $local_config ]] && source "$local_config"
unset local_config
