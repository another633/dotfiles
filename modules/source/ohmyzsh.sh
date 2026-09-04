#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

OHMYZSH_COMMIT=9112b53fa8b5ab556c7c893aa8be8a247ac512a0
OHMYZSH_SHA256=b8c77c58f1cbd065738bbffb613095805cbf732dd2b5d48edb0beefe319c3cfe
OHMYZSH_ROOT=$HOME/.local/share/oh-my-zsh
OHMYZSH_INSTALL=$OHMYZSH_ROOT/$OHMYZSH_COMMIT
OHMYZSH_CURRENT=$OHMYZSH_ROOT/current
OHMYZSH_TEMP_DIR=

check_ohmyzsh() {
  [[ -r $OHMYZSH_INSTALL/oh-my-zsh.sh ]] || return 1
  [[ -L $OHMYZSH_CURRENT && $(readlink "$OHMYZSH_CURRENT") == "$OHMYZSH_INSTALL" ]]
}

cleanup_ohmyzsh_temp() {
  [[ -n $OHMYZSH_TEMP_DIR && -d $OHMYZSH_TEMP_DIR ]] || return 0
  find "$OHMYZSH_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$OHMYZSH_TEMP_DIR"
}

backup_ohmyzsh_path() {
  local target=$1 backup
  [[ -e $target || -L $target ]] || return 0
  backup=$target.dotfiles-backup.$(date +%Y%m%d%H%M%S)
  mv -- "$target" "$backup"
  log "已备份 $target 到 $backup"
}

apply_ohmyzsh() {
  check_ohmyzsh && { log "Oh My Zsh $OHMYZSH_COMMIT 已安装"; return 0; }
  OHMYZSH_TEMP_DIR=$(mktemp -d)
  trap cleanup_ohmyzsh_temp EXIT
  local archive=$OHMYZSH_TEMP_DIR/ohmyzsh.tar.gz
  log "正在从 GitHub 下载 Oh My Zsh"
  curl -fL --retry 3 --output "$archive" \
    "https://github.com/ohmyzsh/ohmyzsh/archive/$OHMYZSH_COMMIT.tar.gz"
  printf '%s  %s\n' "$OHMYZSH_SHA256" "$archive" \
    | sha256sum --check --status || die "Oh My Zsh 归档校验失败"
  tar -xzf "$archive" -C "$OHMYZSH_TEMP_DIR"
  [[ -r $OHMYZSH_TEMP_DIR/ohmyzsh-$OHMYZSH_COMMIT/oh-my-zsh.sh ]] \
    || die "Oh My Zsh 归档内容不完整"
  mkdir -p -- "$OHMYZSH_ROOT"
  [[ ! -e $OHMYZSH_INSTALL ]] || backup_ohmyzsh_path "$OHMYZSH_INSTALL"
  mv -- "$OHMYZSH_TEMP_DIR/ohmyzsh-$OHMYZSH_COMMIT" "$OHMYZSH_INSTALL"
  [[ ! -e $OHMYZSH_CURRENT && ! -L $OHMYZSH_CURRENT ]] \
    || backup_ohmyzsh_path "$OHMYZSH_CURRENT"
  ln -s "$OHMYZSH_INSTALL" "$OHMYZSH_CURRENT"
  check_ohmyzsh || die "Oh My Zsh 安装后验证失败"
}

case ${1:-} in
  check) check_ohmyzsh || { warn "Oh My Zsh 尚未安装"; exit 1; } ;;
  apply) apply_ohmyzsh ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
