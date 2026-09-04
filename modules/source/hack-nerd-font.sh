#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

FONT_VERSION=3.5.1
FONT_SHA256=cdd389472e10e2261520140ff1b382b4f8a226af5fd0b2735b975d31151d9c3c
FONT_URL=https://github.com/ryanoasis/nerd-fonts/releases/download/v$FONT_VERSION/Hack.tar.xz
FONT_ROOT=${XDG_DATA_HOME:-"$HOME/.local/share"}/fonts
FONT_INSTALL_DIR=$FONT_ROOT/Hack
FONT_TEMP_DIR=

check_hack_font() {
  command -v fc-list >/dev/null || return 1
  fc-list 2>/dev/null | grep -F 'Hack Nerd Font Mono' >/dev/null
}

cleanup_font_temp() {
  [[ -n $FONT_TEMP_DIR && -d $FONT_TEMP_DIR ]] || return 0
  find "$FONT_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$FONT_TEMP_DIR"
}

apply_hack_font() {
  check_hack_font && { log "Hack Nerd Font 已安装"; return 0; }
  command -v curl >/dev/null || die "安装 Hack Nerd Font 需要 curl"
  command -v fc-cache >/dev/null || die "安装 Hack Nerd Font 需要 fontconfig"
  [[ ! -e $FONT_INSTALL_DIR ]] || die "字体目录已存在且不受本模块管理：$FONT_INSTALL_DIR"

  FONT_TEMP_DIR=$(mktemp -d)
  trap cleanup_font_temp EXIT
  mkdir -p -- "$FONT_TEMP_DIR/files"
  log "正在下载 Hack Nerd Font $FONT_VERSION"
  curl -fL --retry 3 --output "$FONT_TEMP_DIR/Hack.tar.xz" "$FONT_URL"
  printf '%s  %s\n' "$FONT_SHA256" "$FONT_TEMP_DIR/Hack.tar.xz" | sha256sum --check --status \
    || die "Hack Nerd Font 下载文件校验失败"
  tar -xJf "$FONT_TEMP_DIR/Hack.tar.xz" -C "$FONT_TEMP_DIR/files"
  mkdir -p -- "$FONT_ROOT"
  mv -- "$FONT_TEMP_DIR/files" "$FONT_INSTALL_DIR"
  fc-cache -f "$FONT_INSTALL_DIR"
  check_hack_font || die "Hack Nerd Font 安装后的验证失败"
  log "Hack Nerd Font $FONT_VERSION 已安装"
}

case ${1:-} in
  check)
    check_hack_font || { warn "Hack Nerd Font 尚未安装"; exit 1; }
    ;;
  apply) apply_hack_font ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
