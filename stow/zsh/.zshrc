# 此文件由 dotfiles 仓库管理。
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

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

arch=$(uname -m)

if [[ "$arch" == "x86_64"  ]]; then
		export http_proxy=http://127.0.0.1:7890
			export https_proxy=http://127.0.0.1:7890
				export socks_proxy=socks5://127.0.0.1:7891
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. $HOME/.cargo/env
export PATH=/home/liushuan/.cargo/bin:$PATH
# . ~/dlang/dmd-2.112.0/activate

eval "$(mihomosh shell-completion zsh)"
eval "$(zoxide init zsh)"

export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

for config_file in ~/.myshell/*.zsh ~/.myshell/*.sh; do
	  source "$config_file"
  done

eval "$(codex completion zsh)"
