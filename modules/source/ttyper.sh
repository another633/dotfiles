#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"
# shellcheck source=../../lib/github-release.sh
source "$DOTFILES_ROOT/lib/github-release.sh"

TTYPER_VERSION=1.6.0
TTYPER_BIN=$HOME/.local/bin/ttyper

resolve_ttyper_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      TTYPER_TARGET=x86_64-unknown-linux-gnu
      TTYPER_SHA256=b41549968a8f08f93cdc05698402a8055507801e2363a1792aaef8a9f1081ffd
      ;;
    arm64)
      TTYPER_TARGET=aarch64-unknown-linux-musl
      TTYPER_SHA256=23f2f0282e2e4cbcf22834094c7488a218f781896192ac13878e49ee4434fbe1
      ;;
    *) die "Ttyper 二进制安装仅支持 Debian amd64 和 arm64" ;;
  esac
  TTYPER_ASSET=ttyper-$TTYPER_TARGET.tar.gz
}

check_ttyper() {
  [[ -x $TTYPER_BIN ]] \
    && "$TTYPER_BIN" --version 2>/dev/null | grep -Fx "ttyper $TTYPER_VERSION" >/dev/null
}

apply_ttyper() {
  check_ttyper && { log "Ttyper v$TTYPER_VERSION 已安装"; return 0; }
  resolve_ttyper_asset
  mkdir -p -- "$HOME/.local/bin"
  download_github_release max-niederman/ttyper "v$TTYPER_VERSION" \
    "$TTYPER_ASSET" "$TTYPER_SHA256"
  install_tar_binary ttyper "$TTYPER_BIN"
  check_ttyper || die "Ttyper 安装后的验证失败"
}

case ${1:-} in
  check) check_ttyper || { warn "Ttyper v$TTYPER_VERSION 尚未安装"; exit 1; } ;;
  apply) apply_ttyper ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
