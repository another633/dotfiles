#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"
# shellcheck source=../../lib/github-release.sh
source "$DOTFILES_ROOT/lib/github-release.sh"

YAZI_VERSION=26.9.1
YAZI_BIN=$HOME/.local/bin/yazi
YA_BIN=$HOME/.local/bin/ya

resolve_yazi_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      YAZI_TARGET=x86_64-unknown-linux-gnu
      YAZI_SHA256=a02fe91d3304294048c681f010f1100856872a4e98ecf6927328e888d40a6ad2
      ;;
    arm64)
      YAZI_TARGET=aarch64-unknown-linux-gnu
      YAZI_SHA256=02807f08d6b589b65b7516a4e259d83f5995d7a23bb12b3a155141385b370b3a
      ;;
    *) die "Yazi 二进制安装仅支持 Debian amd64 和 arm64" ;;
  esac
  YAZI_ASSET=yazi-$YAZI_TARGET.zip
}

check_yazi() {
  [[ -x $YAZI_BIN && -x $YA_BIN ]] || return 1
  "$YAZI_BIN" --version 2>/dev/null | grep -F "Version: $YAZI_VERSION " >/dev/null || return 1
  "$YA_BIN" --version 2>/dev/null | grep -F "Version: $YAZI_VERSION " >/dev/null
}

apply_yazi() {
  check_yazi && { log "Yazi v$YAZI_VERSION 已安装"; return 0; }
  command -v unzip >/dev/null || die "安装 Yazi 需要 unzip"
  resolve_yazi_asset
  mkdir -p -- "$HOME/.local/bin"
  download_github_release sxyazi/yazi "v$YAZI_VERSION" "$YAZI_ASSET" "$YAZI_SHA256"
  install_zip_binary "yazi-$YAZI_TARGET/yazi" "$YAZI_BIN"
  install_zip_binary "yazi-$YAZI_TARGET/ya" "$YA_BIN"
  check_yazi || die "Yazi 安装后的验证失败"
}

case ${1:-} in
  check) check_yazi || { warn "Yazi v$YAZI_VERSION 尚未安装或缺少 ya 命令"; exit 1; } ;;
  apply) apply_yazi ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
