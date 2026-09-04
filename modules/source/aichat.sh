#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

AICHAT_VERSION=0.30.0
AICHAT_BIN=$HOME/.local/bin/aichat

check_aichat() {
  [[ -x $AICHAT_BIN ]] \
    && "$AICHAT_BIN" --version 2>/dev/null | grep -Fx "aichat $AICHAT_VERSION" >/dev/null
}

apply_aichat() {
  check_aichat && { log "AIChat v$AICHAT_VERSION 已安装"; return 0; }
  command -v mise >/dev/null || die "安装 AIChat 需要 mise"
  mkdir -p -- "$HOME/.local/bin"
  log "正在通过 Cargo 安装 AIChat v$AICHAT_VERSION"
  CARGO_INSTALL_ROOT=$HOME/.local mise exec rust@latest -- \
    cargo install --locked --version "$AICHAT_VERSION" aichat
  check_aichat || die "AIChat 安装后的验证失败"
}

case ${1:-} in
  check)
    check_aichat || { warn "AIChat v$AICHAT_VERSION 尚未安装"; exit 1; }
    ;;
  apply) apply_aichat ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
