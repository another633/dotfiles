#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

VIM_VERSION=9.2.1036
VIM_TAG=v9.2.1036
VIM_COMMIT=f1b454912996d6417acd0d738de0eb7b60902c56
VIM_CACHE_ROOT=${XDG_CACHE_HOME:-"$HOME/.cache"}/dotfiles/sources
VIM_SOURCE_DIR=$VIM_CACHE_ROOT/vim-$VIM_VERSION
VIM_OPT_ROOT=$HOME/.local/opt/vim
VIM_INSTALL_DIR=$VIM_OPT_ROOT/v$VIM_VERSION
VIM_CURRENT=$VIM_OPT_ROOT/current
VIM_BIN_DIR=$HOME/.local/bin
VIM_REPOSITORY=https://github.com/vim/vim.git
VIM_COMMANDS=(vim vimdiff view ex rvim rview xxd)

verify_vim_binary() {
  local binary=$1 output feature
  [[ -x $binary ]] || return 1
  # 强制使用 C locale，避免 gettext 翻译版本和功能描述。
  output=$(LC_ALL=C "$binary" --version 2>/dev/null) || return 1
  grep -Fq 'VIM - Vi IMproved 9.2' <<< "$output" || return 1
  grep -Eq '^Included patches: 1-1036$' <<< "$output" || return 1
  grep -Fq 'Huge version without GUI.' <<< "$output" || return 1
  for feature in +lua +python3 +perl -ruby -tcl +terminal +clipboard +X11 +xterm_clipboard +wayland +wayland_clipboard; do
    grep -Eq "(^|[[:space:]])\\${feature}([[:space:]]|$)" <<< "$output" || return 1
  done
}

managed_link_target() {
  local link=$1 target
  [[ -L $link ]] || return 1
  target=$(readlink -f -- "$link") || return 1
  [[ $target == "$VIM_OPT_ROOT"/* ]]
}

check_links() {
  local command link expected
  [[ -L $VIM_CURRENT ]] || return 1
  [[ $(readlink -f -- "$VIM_CURRENT") == "$VIM_INSTALL_DIR" ]] || return 1
  for command in "${VIM_COMMANDS[@]}"; do
    link=$VIM_BIN_DIR/$command
    expected=$VIM_INSTALL_DIR/bin/$command
    [[ -L $link && $(readlink -f -- "$link") == "$(readlink -f -- "$expected")" ]] || return 1
  done
}

check_vim() {
  verify_vim_binary "$VIM_INSTALL_DIR/bin/vim" && check_links
}

check_link_conflicts() {
  local command link
  if [[ -e $VIM_CURRENT || -L $VIM_CURRENT ]]; then
    managed_link_target "$VIM_CURRENT" || die "Vim current 路径已存在且不受本模块管理：$VIM_CURRENT"
  fi
  for command in "${VIM_COMMANDS[@]}"; do
    link=$VIM_BIN_DIR/$command
    if [[ -e $link || -L $link ]]; then
      managed_link_target "$link" || die "目标已存在且不受 Vim 模块管理：$link"
    fi
  done
}

prepare_source() {
  local clone_dir origin head
  mkdir -p -- "$VIM_CACHE_ROOT"
  if [[ ! -d $VIM_SOURCE_DIR/.git ]]; then
    [[ ! -e $VIM_SOURCE_DIR ]] || die "源码缓存路径已存在但不是 Git 仓库：$VIM_SOURCE_DIR"
    clone_dir=$VIM_CACHE_ROOT/.vim-$VIM_VERSION.clone.$$
    git clone --depth 1 --branch "$VIM_TAG" -- "$VIM_REPOSITORY" "$clone_dir"
    head=$(git -C "$clone_dir" rev-parse HEAD)
    [[ $head == "$VIM_COMMIT" ]] || die "Vim 下载提交不匹配：期望 $VIM_COMMIT，实际 $head"
    mv -- "$clone_dir" "$VIM_SOURCE_DIR"
  fi

  origin=$(git -C "$VIM_SOURCE_DIR" remote get-url origin)
  head=$(git -C "$VIM_SOURCE_DIR" rev-parse HEAD)
  [[ $origin == "$VIM_REPOSITORY" ]] || die "Vim 源码仓库地址不匹配：$origin"
  [[ $head == "$VIM_COMMIT" ]] || die "Vim 源码提交不匹配：期望 $VIM_COMMIT，实际 $head"
}

build_vim() {
  local jobs failed_dir
  jobs=$(nproc 2>/dev/null || printf '1')
  if [[ -e $VIM_INSTALL_DIR ]]; then
    failed_dir=$VIM_OPT_ROOT/.incomplete-v$VIM_VERSION-$(date +%Y%m%d%H%M%S)
    mv -- "$VIM_INSTALL_DIR" "$failed_dir"
    warn "已将不完整安装移动到：$failed_dir"
  fi

  make -C "$VIM_SOURCE_DIR" distclean >/dev/null 2>&1 || true
  (
    cd "$VIM_SOURCE_DIR"
    ./configure \
      --prefix="$VIM_INSTALL_DIR" \
      --with-features=huge \
      --disable-gui \
      --with-x \
      --with-wayland \
      --enable-luainterp=yes \
      --with-lua-prefix=/usr \
      --enable-python3interp=yes \
      --with-python3-command=/usr/bin/python3 \
      --enable-perlinterp=yes \
      --disable-rubyinterp \
      --disable-tclinterp \
      --enable-cscope \
      --enable-terminal \
      --enable-canberra \
      --enable-fail-if-missing
    make -j"$jobs"
    make install
  )
  verify_vim_binary "$VIM_INSTALL_DIR/bin/vim" || die "Vim 构建完成，但版本或功能验证失败"
}

activate_vim() {
  local command
  mkdir -p -- "$VIM_OPT_ROOT" "$VIM_BIN_DIR"
  for command in "${VIM_COMMANDS[@]}"; do
    [[ -x $VIM_INSTALL_DIR/bin/$command ]] || die "Vim 安装缺少命令：$command"
  done
  ln -sfn -- "$VIM_INSTALL_DIR" "$VIM_CURRENT"
  for command in "${VIM_COMMANDS[@]}"; do
    ln -sfn -- "$VIM_CURRENT/bin/$command" "$VIM_BIN_DIR/$command"
  done
}

apply_vim() {
  check_vim && { log "Vim $VIM_VERSION 已满足要求"; return 0; }
  check_link_conflicts
  prepare_source
  mkdir -p -- "$VIM_OPT_ROOT"
  build_vim
  activate_vim
  check_vim || die "Vim 安装后的最终验证失败"
  log "Vim $VIM_VERSION 已安装到 $VIM_INSTALL_DIR"
}

case ${1:-} in
  check)
    check_vim || { warn "Vim $VIM_VERSION 缺失、版本不符或功能不完整"; exit 1; }
    ;;
  apply) apply_vim ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
