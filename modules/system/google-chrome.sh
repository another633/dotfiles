#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

CHROME_PACKAGE=google-chrome-stable
CHROME_TEMP_DIR=

resolve_chrome_asset() {
  case $(dpkg --print-architecture) in
    amd64) CHROME_ARCH=amd64 ;;
    arm64) CHROME_ARCH=arm64 ;;
    *) die "Google Chrome 官方 DEB 仅支持 Debian amd64 和 arm64" ;;
  esac
  CHROME_ASSET=google-chrome-stable_current_$CHROME_ARCH.deb
  CHROME_URL=https://dl.google.com/linux/direct/$CHROME_ASSET
}

check_chrome() {
  dpkg-query -W -f='${db:Status-Status}\n' "$CHROME_PACKAGE" 2>/dev/null | grep -qx installed
}

cleanup_chrome_temp() {
  [[ -n $CHROME_TEMP_DIR && -d $CHROME_TEMP_DIR ]] || return 0
  find "$CHROME_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$CHROME_TEMP_DIR"
}

apply_chrome() {
  check_chrome && { log "Google Chrome 已安装"; return 0; }
  resolve_chrome_asset
  CHROME_TEMP_DIR=$(mktemp -d)
  trap cleanup_chrome_temp EXIT
  log "正在从 Google 官网下载 Chrome"
  curl -fL --retry 3 --output "$CHROME_TEMP_DIR/$CHROME_ASSET" "$CHROME_URL"
  [[ $(dpkg-deb -f "$CHROME_TEMP_DIR/$CHROME_ASSET" Package) == "$CHROME_PACKAGE" ]] \
    || die "Google Chrome DEB 包名校验失败"
  [[ $(dpkg-deb -f "$CHROME_TEMP_DIR/$CHROME_ASSET" Architecture) == "$CHROME_ARCH" ]] \
    || die "Google Chrome DEB 架构校验失败"
  run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "$CHROME_TEMP_DIR/$CHROME_ASSET"
  check_chrome || die "Google Chrome 安装后验证失败"
}

case ${1:-} in
  check) check_chrome || { warn "Google Chrome 尚未安装"; exit 1; } ;;
  apply) apply_chrome ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
