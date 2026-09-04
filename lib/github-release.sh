#!/usr/bin/env bash

GITHUB_RELEASE_TEMP_DIR=
GITHUB_RELEASE_ARCHIVE=

cleanup_github_release() {
  [[ -n $GITHUB_RELEASE_TEMP_DIR && -d $GITHUB_RELEASE_TEMP_DIR ]] || return 0
  find "$GITHUB_RELEASE_TEMP_DIR" -mindepth 1 -delete
  rmdir -- "$GITHUB_RELEASE_TEMP_DIR"
}

download_github_release() {
  local repository=$1 tag=$2 asset=$3 sha256=$4
  GITHUB_RELEASE_TEMP_DIR=$(mktemp -d)
  GITHUB_RELEASE_ARCHIVE=$GITHUB_RELEASE_TEMP_DIR/$asset
  trap cleanup_github_release EXIT
  log "正在从 GitHub 下载 $repository $tag"
  curl -fL --retry 3 --output "$GITHUB_RELEASE_ARCHIVE" \
    "https://github.com/$repository/releases/download/$tag/$asset"
  printf '%s  %s\n' "$sha256" "$GITHUB_RELEASE_ARCHIVE" \
    | sha256sum --check --status || die "GitHub Release 资产校验失败：$asset"
}

install_tar_binary() {
  local member=$1 target=$2 extracted
  extracted=$GITHUB_RELEASE_TEMP_DIR/extracted-${target##*/}
  tar -xOzf "$GITHUB_RELEASE_ARCHIVE" -- "$member" > "$extracted"
  [[ -s $extracted ]] || die "压缩包中的二进制文件为空：$member"
  install -m 0755 "$extracted" "$target"
}

install_zip_binary() {
  local member=$1 target=$2 extracted
  extracted=$GITHUB_RELEASE_TEMP_DIR/extracted-${target##*/}
  unzip -p "$GITHUB_RELEASE_ARCHIVE" "$member" > "$extracted"
  [[ -s $extracted ]] || die "压缩包中的二进制文件为空：$member"
  install -m 0755 "$extracted" "$target"
}
