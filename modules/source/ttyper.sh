#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

TTYPER_BIN=$HOME/.local/bin/ttyper

check_ttyper() {
  [[ -x $TTYPER_BIN ]] && "$TTYPER_BIN" --version >/dev/null 2>&1
}

apply_ttyper() {
  check_ttyper && { log "Ttyper 已安装"; return 0; }
  command -v mise >/dev/null || die "安装 Ttyper 需要 mise"
  mkdir -p -- "$HOME/.local/bin"
  log "正在通过 Cargo 安装 Ttyper"
  CARGO_INSTALL_ROOT=$HOME/.local mise exec rust@latest -- cargo install ttyper
  check_ttyper || die "Ttyper 安装后的验证失败"
}

case ${1:-} in
  check)
    check_ttyper || { warn "Ttyper 尚未安装"; exit 1; }
    ;;
  apply) apply_ttyper ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
