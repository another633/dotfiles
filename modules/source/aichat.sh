#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"
# shellcheck source=../../lib/github-release.sh
source "$DOTFILES_ROOT/lib/github-release.sh"

AICHAT_VERSION=0.30.0
AICHAT_BIN=$HOME/.local/bin/aichat

resolve_aichat_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      AICHAT_TARGET=x86_64-unknown-linux-musl
      AICHAT_SHA256=6b0cc08c5ceb551dc52bfac2221752f82215be5908c70605d655e9b91ab1557c
      ;;
    arm64)
      AICHAT_TARGET=aarch64-unknown-linux-musl
      AICHAT_SHA256=eb1cd0948569404c5d9d01c10b32b902e11f8231073315456454dec246bdf26e
      ;;
    *) die "AIChat 二进制安装仅支持 Debian amd64 和 arm64" ;;
  esac
  AICHAT_ASSET=aichat-v$AICHAT_VERSION-$AICHAT_TARGET.tar.gz
}

check_aichat() {
  [[ -x $AICHAT_BIN ]] \
    && "$AICHAT_BIN" --version 2>/dev/null | grep -Fx "aichat $AICHAT_VERSION" >/dev/null
}

apply_aichat() {
  check_aichat && { log "AIChat v$AICHAT_VERSION 已安装"; return 0; }
  resolve_aichat_asset
  mkdir -p -- "$HOME/.local/bin"
  download_github_release sigoden/aichat "v$AICHAT_VERSION" "$AICHAT_ASSET" "$AICHAT_SHA256"
  install_tar_binary aichat "$AICHAT_BIN"
  check_aichat || die "AIChat 安装后的验证失败"
}

case ${1:-} in
  check) check_aichat || { warn "AIChat v$AICHAT_VERSION 尚未安装"; exit 1; } ;;
  apply) apply_aichat ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
