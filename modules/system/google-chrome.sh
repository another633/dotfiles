#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=../../lib/core.sh
source "$DOTFILES_ROOT/lib/core.sh"

CHROME_PACKAGE=google-chrome-stable
CHROME_KEY_URL=https://dl.google.com/linux/linux_signing_key.pub
CHROME_KEY_FINGERPRINT=EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796
CHROME_KEYRING=/usr/share/keyrings/google-chrome.gpg
CHROME_SOURCE=/etc/apt/sources.list.d/google-chrome.sources
CHROME_SOURCE_TEMPLATE=$DOTFILES_ROOT/modules/system/google-chrome.sources
CHROME_TEMP_DIR=

check_chrome_architecture() {
  case $(dpkg --print-architecture) in
    amd64|arm64) ;;
    *) die "Google Chrome 模块仅支持 Debian amd64 和 arm64" ;;
  esac
}

chrome_key_is_valid() {
  [[ -s $CHROME_KEYRING ]] || return 1
  gpg --batch --no-options --show-keys --with-colons "$CHROME_KEYRING" 2>/dev/null \
    | awk -F: -v expected="$CHROME_KEY_FINGERPRINT" \
      '$1 == "fpr" && $10 == expected { found=1 } END { exit !found }'
}

chrome_source_is_valid() {
  [[ -r $CHROME_SOURCE ]] || return 1
  grep -Eq '^Types:[[:space:]]*deb[[:space:]]*$' "$CHROME_SOURCE" \
    && grep -Eq '^URIs:[[:space:]]*https://dl\.google\.com/linux/chrome(-stable)?/deb/?[[:space:]]*$' "$CHROME_SOURCE" \
    && grep -Eq '^Suites:[[:space:]]*stable[[:space:]]*$' "$CHROME_SOURCE" \
    && grep -Eq '^Components:[[:space:]]*main[[:space:]]*$' "$CHROME_SOURCE" \
    && grep -Eq '^Signed-By:[[:space:]]*/usr/share/keyrings/google-chrome\.gpg[[:space:]]*$' "$CHROME_SOURCE"
}

check_chrome() {
  check_chrome_architecture
  command -v gpg >/dev/null || return 1
  chrome_key_is_valid || return 1
  chrome_source_is_valid || return 1
  dpkg-query -W -f='${db:Status-Status}\n' "$CHROME_PACKAGE" 2>/dev/null | grep -qx installed
}

cleanup_chrome_temp() {
  [[ -n $CHROME_TEMP_DIR && -d $CHROME_TEMP_DIR ]] || return 0
  find "$CHROME_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$CHROME_TEMP_DIR"
}

download_chrome_key() {
  CHROME_TEMP_DIR=$(mktemp -d)
  trap cleanup_chrome_temp EXIT
  curl -fL --retry 3 --output "$CHROME_TEMP_DIR/google-chrome.pub" "$CHROME_KEY_URL"
  gpg --batch --no-options --show-keys --with-colons "$CHROME_TEMP_DIR/google-chrome.pub" 2>/dev/null \
    | awk -F: -v expected="$CHROME_KEY_FINGERPRINT" \
      '$1 == "fpr" && $10 == expected { found=1 } END { exit !found }' \
    || die "Google Chrome 签名密钥指纹校验失败"
  gpg --batch --yes --dearmor \
    --output "$CHROME_TEMP_DIR/google-chrome.gpg" "$CHROME_TEMP_DIR/google-chrome.pub"
}

install_chrome_repository() {
  if ! chrome_key_is_valid; then
    download_chrome_key
    [[ ! -e $CHROME_KEYRING ]] || backup_file "$CHROME_KEYRING"
    run_sudo install -o root -g root -m 0644 \
      "$CHROME_TEMP_DIR/google-chrome.gpg" "$CHROME_KEYRING"
  fi
  if ! chrome_source_is_valid; then
    [[ ! -e $CHROME_SOURCE ]] || backup_file "$CHROME_SOURCE"
    run_sudo install -o root -g root -m 0644 "$CHROME_SOURCE_TEMPLATE" "$CHROME_SOURCE"
  fi
}

apply_chrome() {
  check_chrome_architecture
  command -v gpg >/dev/null || die "缺少 gpg，请先安装 desktop 配置中的 APT 依赖"
  if check_chrome; then
    log "Google Chrome 已满足要求"
    return 0
  fi
  install_chrome_repository
  run_sudo apt-get update
  run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$CHROME_PACKAGE"
  check_chrome || die "Google Chrome 安装后验证失败"
  log "Google Chrome 已安装"
}

case ${1:-} in
  check)
    check_chrome || { warn "Google Chrome 或其官方 APT 源未正确安装"; exit 1; }
    ;;
  apply) apply_chrome ;;
  *) die "用法：${0##*/} check|apply" ;;
esac
