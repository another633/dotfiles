#!/usr/bin/bash

SCTOOLKIT_DIR=$HOME/Projects/vim/SCToolkit.vim
SCAPI_DIR=$HOME/Projects/c#/SurvivalcraftApi

. $SCTOOLKIT_DIR/shell/src/utils/filemanager.sh

# 工具名：mycs（你可以改成你的工具名）
_sctoolkit_completion() {
    local cur prev base_dir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    # prev="${COMP_WORDS[COMP_CWORD-1]}"

	COMPREPLY=( $(GetFiles "$SCAPI_DIR" "cs") )

    # case "$prev" in
    #     # 如果你的工具支持子命令
    #     compile|run|test|debug)
    #         # 补全 .cs 文件
    #         COMPREPLY=( $(find "$cs_dir" -name "*.cs" -type f 2>/dev/null |
    #                     sed "s|^$cs_dir/||" |  # 去掉目录前缀
    #                     grep -i -- "^$cur") )
    #         ;;
    #     # 如果是其他参数
    #     --file|-f)
    #         COMPREPLY=( $(find "$cs_dir" -name "*.cs" -type f 2>/dev/null |
    #                     sed "s|^$cs_dir/||" |
    #                     grep -i -- "^$cur") )
    #         ;;
    #     *)
    #         # 显示工具选项 + .cs 文件
    #         local options="compile run test debug --help --file -f --list"
    #         local files=( $(find "$cs_dir" -name "*.cs" -type f 2>/dev/null |
    #                       sed "s|^$cs_dir/||" |
    #                       grep -i -- "^$cur") )
    #         local opts=( $(compgen -W "$options" -- "$cur") )
    #         COMPREPLY=( "${files[@]}" "${opts[@]}" )
    #         ;;
    # esac
}

# 注册补全
complete -F _sctoolkit_completion sctoolkit
