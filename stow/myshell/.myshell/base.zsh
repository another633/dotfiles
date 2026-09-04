# 禁 zsh 自己的蜂鸣（含补全/列表）
setopt NO_BEEP
setopt NO_LIST_BEEP
zstyle ':completion:*' beep false

# termux desktop configuration
# sudo chmod -R 777 /tmp

arch=$(uname -m)

if [[ "$arch" == "aarch64"  ]]; then
	export DISPLAY=:1 PULSE_SERVER=tcp:127.0.0.1:4713
fi

desktop(){
	dbus-launch --exit-with-session i3 > /dev/null 2>&1 &
}

undesktop(){
	pkill i3
}

#yt-dlp
yt-mp3(){
	yt-dlp -x --audio-format mp3 -o '~/Music/youtube/%(title)s.%(ext)s' $1
}

ncep(){
	/home/liushuan/Projects/c/ncep/build/ncep $1 $2
}

readera(){
	ssh termux "am start -n org.readera/com.readera.MainActivity" > /dev/null
}

# dict(){
# 	if [ -z "$2" ]; then
# 	/home/liushuan/Projects/c/ncep/build/ncep -d $1
# 	else
# 	/home/liushuan/Projects/c/ncep/build/ncep -d $1 -p $2
# 	fi
# }

. /usr/share/autojump/autojump.sh
# . "$HOME/.cargo/env"

alias vi="vim -u $HOME/Documents/dnvim2-code/code/essential.vim"

alias man='man -L zh_CN'

alias trans='trans -b '

export EDITOR='vim'
