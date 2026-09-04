#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"
# shellcheck source=../../lib/github-release.sh
source "$DOTFILES_ROOT/lib/github-release.sh"

ZEN_VERSION=1.21.16b
ZEN_ROOT=$HOME/.local/opt/zen-browser
ZEN_INSTALL=$ZEN_ROOT/$ZEN_VERSION
ZEN_CURRENT=$ZEN_ROOT/current
ZEN_BIN=$HOME/.local/bin/zen
ZEN_DESKTOP=$HOME/.local/share/applications/zen-browser.desktop

resolve_zen_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      ZEN_TARGET=x86_64
      ZEN_SHA256=1e4c3c391d10a82239d35afad84658fa3b3856b8ff72f93bbff7f57392acb942
      ;;
    arm64)
      ZEN_TARGET=aarch64
      ZEN_SHA256=7aa0c251c1dad6cbea374b3d5892d4c1948465479232c318aef89aa1cf183654
      ;;
    *) die "Zen Browser 官方二进制仅支持 Debian amd64 和 arm64" ;;
  esac
  ZEN_ASSET=zen.linux-$ZEN_TARGET.tar.xz
}

check_zen() {
  [[ -x $ZEN_INSTALL/zen ]] || return 1
  grep -Fx "Version=$ZEN_VERSION" "$ZEN_INSTALL/application.ini" >/dev/null || return 1
  [[ -L $ZEN_CURRENT && $(readlink "$ZEN_CURRENT") == "$ZEN_INSTALL" ]] || return 1
  [[ -L $ZEN_BIN && $(readlink "$ZEN_BIN") == "$ZEN_CURRENT/zen" ]] || return 1
  [[ -r $ZEN_DESKTOP ]]
}

backup_user_path() {
  local target=$1 backup
  [[ -e $target || -L $target ]] || return 0
  backup=$target.dotfiles-backup.$(date +%Y%m%d%H%M%S)
  mv -- "$target" "$backup"
  log "已备份 $target 到 $backup"
}

install_zen_desktop() {
  mkdir -p -- "${ZEN_DESKTOP%/*}"
  {
    printf '%s\n' '[Desktop Entry]'
    printf '%s\n' 'Name=Zen Browser'
    printf 'Exec=%s %%u\n' "$ZEN_CURRENT/zen"
    printf 'Icon=%s\n' "$ZEN_CURRENT/browser/chrome/icons/default/default128.png"
    printf '%s\n' 'Type=Application'
    printf '%s\n' 'Categories=Network;WebBrowser;'
    printf '%s\n' 'Terminal=false'
    printf '%s\n' 'StartupNotify=true'
    printf '%s\n' 'MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;'
  } > "$ZEN_DESKTOP"
}

apply_zen() {
  check_zen && { log "Zen Browser v$ZEN_VERSION 已安装"; return 0; }
  resolve_zen_asset
  mkdir -p -- "$ZEN_ROOT" "$HOME/.local/bin"
  download_github_release zen-browser/desktop "$ZEN_VERSION" "$ZEN_ASSET" "$ZEN_SHA256"
  tar -xJf "$GITHUB_RELEASE_ARCHIVE" -C "$GITHUB_RELEASE_TEMP_DIR"
  [[ -x $GITHUB_RELEASE_TEMP_DIR/zen/zen ]] || die "Zen Browser 压缩包中缺少可执行文件"
  [[ ! -e $ZEN_INSTALL ]] || backup_user_path "$ZEN_INSTALL"
  mv -- "$GITHUB_RELEASE_TEMP_DIR/zen" "$ZEN_INSTALL"
  [[ ! -e $ZEN_CURRENT && ! -L $ZEN_CURRENT ]] || backup_user_path "$ZEN_CURRENT"
  [[ ! -e $ZEN_BIN && ! -L $ZEN_BIN ]] || backup_user_path "$ZEN_BIN"
  ln -s "$ZEN_INSTALL" "$ZEN_CURRENT"
  ln -s "$ZEN_CURRENT/zen" "$ZEN_BIN"
  install_zen_desktop
  check_zen || die "Zen Browser 安装后验证失败"
}

case ${1:-} in
  check) check_zen || { warn "Zen Browser v$ZEN_VERSION 尚未安装"; exit 1; } ;;
  apply) apply_zen ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
