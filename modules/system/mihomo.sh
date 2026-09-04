#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

MIHOMO_VERSION=1.19.30
MIHOMO_BIN=/usr/local/bin/mihomo
MIHOMO_CONFIG_DIR=/etc/mihomo
MIHOMO_CONFIG=$MIHOMO_CONFIG_DIR/config.yaml
MIHOMO_LOCAL_CONFIG=${XDG_CONFIG_HOME:-"$HOME/.config"}/dotfiles/local/mihomo/config.yaml
MIHOMO_UNIT=/etc/systemd/system/mihomo.service
MIHOMO_UNIT_SOURCE=$DOTFILES_ROOT/modules/system/mihomo.service
MIHOMO_TEMP_DIR=

resolve_mihomo_asset() {
  case $(dpkg --print-architecture) in
    amd64)
      MIHOMO_ASSET=mihomo-linux-amd64-v1-v$MIHOMO_VERSION.gz
      MIHOMO_SHA256=cbe553d0319a414bd3a372c5976a252155b2c4882b66bce88a4d6bba9571a553
      ;;
    arm64)
      MIHOMO_ASSET=mihomo-linux-arm64-v$MIHOMO_VERSION.gz
      MIHOMO_SHA256=58896873736d28628f66de3677c8654fa0f180662523148e136cff4f6e890069
      ;;
    *) die "Mihomo 模块仅支持 Debian amd64 和 arm64" ;;
  esac
  MIHOMO_URL=https://github.com/MetaCubeX/mihomo/releases/download/v$MIHOMO_VERSION/$MIHOMO_ASSET
}

check_mihomo_binary() {
  [[ -x $MIHOMO_BIN ]] || return 1
  "$MIHOMO_BIN" -v 2>/dev/null | grep -F "Mihomo Meta v$MIHOMO_VERSION " >/dev/null || return 1
  [[ $(stat -c '%U:%G:%a' "$MIHOMO_BIN" 2>/dev/null) == root:root:755 ]]
}

mihomo_version_matches() {
  [[ -x $MIHOMO_BIN ]] \
    && "$MIHOMO_BIN" -v 2>/dev/null | grep -F "Mihomo Meta v$MIHOMO_VERSION " >/dev/null
}

check_mihomo() {
  check_mihomo_binary || return 1
  [[ -s $MIHOMO_CONFIG ]] || return 1
  cmp -s -- "$MIHOMO_UNIT_SOURCE" "$MIHOMO_UNIT" || return 1
  systemctl is-enabled --quiet mihomo.service || return 1
  systemctl is-active --quiet mihomo.service
}

cleanup_mihomo_temp() {
  [[ -n $MIHOMO_TEMP_DIR && -d $MIHOMO_TEMP_DIR ]] || return 0
  find "$MIHOMO_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$MIHOMO_TEMP_DIR"
}

prepare_mihomo_config() {
  if [[ ! -s $MIHOMO_CONFIG ]]; then
    [[ -s $MIHOMO_LOCAL_CONFIG ]] \
      || die "缺少 Mihomo 配置，请创建 $MIHOMO_LOCAL_CONFIG"
    run_sudo install -d -m 0755 "$MIHOMO_CONFIG_DIR"
    run_sudo install -m 0600 "$MIHOMO_LOCAL_CONFIG" "$MIHOMO_CONFIG"
  else
    run_sudo chmod 0600 "$MIHOMO_CONFIG"
  fi
}

download_mihomo() {
  resolve_mihomo_asset
  MIHOMO_TEMP_DIR=$(mktemp -d)
  trap cleanup_mihomo_temp EXIT
  log "正在下载 Mihomo v$MIHOMO_VERSION"
  curl -fL --retry 3 --output "$MIHOMO_TEMP_DIR/$MIHOMO_ASSET" "$MIHOMO_URL"
  printf '%s  %s\n' "$MIHOMO_SHA256" "$MIHOMO_TEMP_DIR/$MIHOMO_ASSET" \
    | sha256sum --check --status || die "Mihomo 下载文件校验失败"
  gzip -dc -- "$MIHOMO_TEMP_DIR/$MIHOMO_ASSET" > "$MIHOMO_TEMP_DIR/mihomo"
  chmod 0755 "$MIHOMO_TEMP_DIR/mihomo"
  "$MIHOMO_TEMP_DIR/mihomo" -v 2>/dev/null \
    | grep -F "Mihomo Meta v$MIHOMO_VERSION " >/dev/null \
    || die "下载的 Mihomo 版本验证失败"
}

install_mihomo_binary() {
  if ! mihomo_version_matches; then
    [[ -x ${MIHOMO_TEMP_DIR:-}/mihomo ]] || download_mihomo
    [[ ! -e $MIHOMO_BIN ]] || backup_file "$MIHOMO_BIN"
    run_sudo install -o root -g root -m 0755 "$MIHOMO_TEMP_DIR/mihomo" "$MIHOMO_BIN"
  else
    run_sudo chown root:root "$MIHOMO_BIN"
    run_sudo chmod 0755 "$MIHOMO_BIN"
  fi
}

install_mihomo_unit() {
  if ! cmp -s -- "$MIHOMO_UNIT_SOURCE" "$MIHOMO_UNIT"; then
    [[ ! -e $MIHOMO_UNIT ]] || backup_file "$MIHOMO_UNIT"
    run_sudo install -o root -g root -m 0644 "$MIHOMO_UNIT_SOURCE" "$MIHOMO_UNIT"
  fi
}

apply_mihomo() {
  check_mihomo && { log "Mihomo v$MIHOMO_VERSION 系统服务已满足要求"; return 0; }
  prepare_mihomo_config
  if ! mihomo_version_matches; then
    download_mihomo
    run_sudo "$MIHOMO_TEMP_DIR/mihomo" -t -d "$MIHOMO_CONFIG_DIR" >/dev/null \
      || die "Mihomo 配置验证失败，未替换现有二进制"
  else
    run_sudo "$MIHOMO_BIN" -t -d "$MIHOMO_CONFIG_DIR" >/dev/null \
      || die "Mihomo 配置验证失败，未更新服务"
  fi
  install_mihomo_binary
  install_mihomo_unit
  run_sudo systemctl daemon-reload
  run_sudo systemctl enable mihomo.service
  run_sudo systemctl restart mihomo.service
  check_mihomo || die "Mihomo 系统服务安装后的验证失败"
  log "Mihomo v$MIHOMO_VERSION 系统服务已安装并启动"
}

case ${1:-} in
  check)
    check_mihomo || { warn "Mihomo 系统服务缺失、版本不符或未运行"; exit 1; }
    ;;
  apply) apply_mihomo ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
