#!/usr/bin/bash

# gh 仓库快速打开至浏览器
# 使用wmenu选择仓库

if ! command -v gh &> /dev/null
then
	echo "gh could not be found, please install gh first."
	exit 1
fi

gh repo list | wmenu -i -l 10 -p "Select: " | awk '{print $1}' | xargs -I {} gh repo view {} --web
