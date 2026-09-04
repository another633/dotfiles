#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"
# shellcheck source=../../lib/github-release.sh
source "$DOTFILES_ROOT/lib/github-release.sh"

BOOKOKRAT_VERSION=0.3.12
BOOKOKRAT_BIN=$HOME/.local/bin/bookokrat

resolve_bookokrat_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      BOOKOKRAT_TARGET=x86_64-unknown-linux-gnu
      BOOKOKRAT_SHA256=fa7091a3482c00e723a327146b5d256559282be783ac7e0b82f4b408563760f3
      ;;
    arm64)
      BOOKOKRAT_TARGET=aarch64-unknown-linux-gnu
      BOOKOKRAT_SHA256=114739619aa85051566358fb2fc3c36840d2e77920a80b8d7310b15465089676
      ;;
    *) die "Bookokrat 二进制安装仅支持 Debian amd64 和 arm64" ;;
  esac
  BOOKOKRAT_ASSET=bookokrat-v$BOOKOKRAT_VERSION-$BOOKOKRAT_TARGET.tar.gz
}

check_bookokrat() {
  [[ -x $BOOKOKRAT_BIN ]] \
    && "$BOOKOKRAT_BIN" --version 2>/dev/null \
      | grep -Fx "bookokrat $BOOKOKRAT_VERSION" >/dev/null
}

apply_bookokrat() {
  check_bookokrat && { log "Bookokrat v$BOOKOKRAT_VERSION 已安装"; return 0; }
  resolve_bookokrat_asset
  mkdir -p -- "$HOME/.local/bin"
  download_github_release bugzmanov/bookokrat "v$BOOKOKRAT_VERSION" \
    "$BOOKOKRAT_ASSET" "$BOOKOKRAT_SHA256"
  install_tar_binary bookokrat "$BOOKOKRAT_BIN"
  check_bookokrat || die "Bookokrat 安装后的验证失败"
}

case ${1:-} in
  check) check_bookokrat || { warn "Bookokrat v$BOOKOKRAT_VERSION 尚未安装"; exit 1; } ;;
  apply) apply_bookokrat ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
