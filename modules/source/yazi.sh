#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

YAZI_BIN=$HOME/.local/bin/yazi
YA_BIN=$HOME/.local/bin/ya

check_yazi() {
  [[ -x $YAZI_BIN && -x $YA_BIN ]] || return 1
  "$YAZI_BIN" --version >/dev/null 2>&1 || return 1
  "$YA_BIN" --version >/dev/null 2>&1
}

apply_yazi() {
  check_yazi && { log "Yazi 已安装"; return 0; }
  command -v mise >/dev/null || die "安装 Yazi 需要 mise"
  mkdir -p -- "$HOME/.local/bin"
  log "正在通过 Cargo 安装 Yazi"
  CARGO_INSTALL_ROOT=$HOME/.local mise exec rust@latest -- cargo install --force yazi-build
  check_yazi || die "Yazi 安装后的验证失败"
}

case ${1:-} in
  check)
    check_yazi || { warn "Yazi 尚未安装或缺少 ya 命令"; exit 1; }
    ;;
  apply) apply_yazi ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
