#!/usr/bin/env bash

DOTFILES_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}/dotfiles
DOTFILES_PROFILE_FILE=$DOTFILES_CONFIG_HOME/profiles
DOTFILES_PROXY_FILE=$DOTFILES_CONFIG_HOME/local/proxy.env
PROXY_ENVIRONMENT_PREPARED=0

log() { printf '%s\n' "==> $*"; }
warn() { printf '%s\n' "warning: $*" >&2; }
die() { printf '%s\n' "error: $*" >&2; return 1; }

require_debian() {
  [[ -r /etc/os-release ]] || die "cannot identify operating system"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == debian ]] || die "this framework supports Debian only (found ${ID:-unknown})"
  local major=${VERSION_ID%%.*}
  [[ $major =~ ^[0-9]+$ && $major -ge 11 ]] || die "Debian 11 or newer is required"
}

read_manifest() {
  local file=$1 line
  [[ -f $file ]] || return 0
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%%#*}
    line=${line#"${line%%[![:space:]]*}"}
    line=${line%"${line##*[![:space:]]}"}
    [[ -n $line ]] && printf '%s\n' "$line"
  done < "$file"
  return 0
}

dedupe_lines() { awk 'NF && !seen[$0]++'; }

run_sudo() {
  if ((EUID == 0)); then
    "$@"
    return
  fi
  local name
  local -a proxy_environment=()
  for name in http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY; do
    [[ -n ${!name:-} ]] && proxy_environment+=("$name=${!name}")
  done
  if ((${#proxy_environment[@]})); then
    sudo env "${proxy_environment[@]}" "$@"
  else
    sudo "$@"
  fi
}

proxy_is_configured() {
  local name
  for name in https_proxy HTTPS_PROXY http_proxy HTTP_PROXY all_proxy ALL_PROXY; do
    [[ -n ${!name:-} ]] && return 0
  done
  return 1
}

load_proxy_config() {
  [[ -r $DOTFILES_PROXY_FILE ]] || return 0
  # shellcheck disable=SC1090
  source "$DOTFILES_PROXY_FILE"
}

write_proxy_config() {
  local proxy_url=$1 proxy_dir proxy_temp
  [[ $proxy_url =~ ^(https?|socks5h?)://[^[:space:]]+$ ]] \
    || die "代理地址必须以 http://、https://、socks5:// 或 socks5h:// 开头"
  proxy_dir=${DOTFILES_PROXY_FILE%/*}
  mkdir -p -- "$proxy_dir"
  chmod 0700 "$proxy_dir"
  proxy_temp=$(mktemp "$proxy_dir/proxy.env.XXXXXX")
  chmod 0600 "$proxy_temp"
  {
    printf '# 由 dotfiles 生成；此文件可包含代理凭据，请勿提交。\n'
    printf 'export http_proxy=%q\n' "$proxy_url"
    printf 'export https_proxy=%q\n' "$proxy_url"
    printf 'export all_proxy=%q\n' "$proxy_url"
    printf 'export HTTP_PROXY=%q\n' "$proxy_url"
    printf 'export HTTPS_PROXY=%q\n' "$proxy_url"
    printf 'export ALL_PROXY=%q\n' "$proxy_url"
    printf 'export no_proxy=%q\n' 'localhost,127.0.0.1,::1'
    printf 'export NO_PROXY=%q\n' 'localhost,127.0.0.1,::1'
  } > "$proxy_temp"
  mv -- "$proxy_temp" "$DOTFILES_PROXY_FILE"
}

prepare_proxy_environment() {
  ((PROXY_ENVIRONMENT_PREPARED == 0)) || return 0
  PROXY_ENVIRONMENT_PREPARED=1
  proxy_is_configured || load_proxy_config

  local prompt reply proxy_url
  if proxy_is_configured; then
    log "已检测到代理环境"
    prompt='是否重新配置代理以加快安装？[y/N] '
  else
    log "未检测到代理环境"
    prompt='是否配置代理以加快安装？[y/N] '
  fi
  if [[ ! -t 0 || ! -t 1 ]]; then
    log "非交互环境，继续使用当前代理设置"
    return 0
  fi
  read -r -p "$prompt" reply
  [[ $reply =~ ^[Yy]$ ]] || return 0
  read -r -p '代理地址（例如 http://127.0.0.1:7890）: ' proxy_url
  [[ -n $proxy_url ]] || { warn "未输入代理地址，保留当前设置"; return 0; }
  write_proxy_config "$proxy_url"
  load_proxy_config
  log "代理配置已保存到 $DOTFILES_PROXY_FILE"
}

backup_file() {
  local target=$1 backup
  [[ -e $target || -L $target ]] || return 0
  backup="${target}.dotfiles-backup.$(date +%Y%m%d%H%M%S)"
  run_sudo cp -a -- "$target" "$backup"
  log "backed up $target to $backup"
}
