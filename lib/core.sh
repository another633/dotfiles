#!/usr/bin/env bash

DOTFILES_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}/dotfiles
DOTFILES_PROFILE_FILE=$DOTFILES_CONFIG_HOME/profiles

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
  if ((EUID == 0)); then "$@"; else sudo "$@"; fi
}

backup_file() {
  local target=$1 backup
  [[ -e $target || -L $target ]] || return 0
  backup="${target}.dotfiles-backup.$(date +%Y%m%d%H%M%S)"
  run_sudo cp -a -- "$target" "$backup"
  log "backed up $target to $backup"
}
