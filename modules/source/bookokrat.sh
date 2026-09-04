#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

BOOKOKRAT_BIN=$HOME/.local/bin/bookokrat

check_bookokrat() {
  [[ -x $BOOKOKRAT_BIN ]] && "$BOOKOKRAT_BIN" --version >/dev/null 2>&1
}

apply_bookokrat() {
  check_bookokrat && { log "Bookokrat 已安装"; return 0; }
  command -v mise >/dev/null || die "安装 Bookokrat 需要 mise"
  mkdir -p -- "$HOME/.local/bin"
  log "正在通过 Cargo 安装 Bookokrat"
  CARGO_INSTALL_ROOT=$HOME/.local mise exec rust@latest -- cargo install bookokrat
  check_bookokrat || die "Bookokrat 安装后的验证失败"
}

case ${1:-} in
  check)
    check_bookokrat || { warn "Bookokrat 尚未安装"; exit 1; }
    ;;
  apply) apply_bookokrat ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
