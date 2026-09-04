#!/usr/bin/env bash

STOW_IGNORE_REGEX='\.swp'

check_dependencies() {
  local failed=0 command
  for command in git curl stow; do
    command -v "$command" >/dev/null || { warn "missing command: $command"; failed=1; }
  done
  if [[ -n $(profile_items flatpak) ]]; then
    command -v flatpak >/dev/null || { warn "missing command: flatpak"; failed=1; }
  fi
  if [[ -n $(profile_items mise) ]]; then
    command -v mise >/dev/null || { warn "missing command: mise"; failed=1; }
  fi
  return "$failed"
}

check_apt() {
  local package failed=0
  while IFS= read -r package; do
    [[ $package =~ ^[a-z0-9][a-z0-9+.:~-]*$ ]] || { warn "invalid APT package name: $package"; failed=1; continue; }
    dpkg-query -W -f='${db:Status-Status}\n' "$package" 2>/dev/null | grep -qx 'installed' || {
      warn "APT package missing: $package"; failed=1;
    }
  done < <(profile_items apt)
  return "$failed"
}

check_flatpak() {
  local app failed=0
  [[ -z $(profile_items flatpak) ]] && return 0
  command -v flatpak >/dev/null || return 1
  flatpak remotes --user --columns=name 2>/dev/null | grep -qx flathub || { warn "user Flatpak remote missing: flathub"; failed=1; }
  while IFS= read -r app; do
    [[ $app =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { warn "invalid Flatpak application ID: $app"; failed=1; continue; }
    flatpak info --user "$app" >/dev/null 2>&1 || { warn "Flatpak app missing: $app"; failed=1; }
  done < <(profile_items flatpak)
  return "$failed"
}

validate_mise_manifest() {
  local line tool version failed=0
  declare -A versions=()
  while IFS= read -r line; do
    read -r tool version extra <<< "$line"
    if [[ -z ${tool:-} || -z ${version:-} || -n ${extra:-} ]]; then
      warn "invalid mise entry (expected 'tool version'): $line"; failed=1; continue
    fi
    if [[ ! $tool =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ || ! $version =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]]; then
      warn "invalid mise tool or version: $line"; failed=1; continue
    fi
    if [[ -n ${versions[$tool]:-} && ${versions[$tool]} != "$version" ]]; then
      warn "conflicting mise versions for $tool: ${versions[$tool]} and $version"; failed=1
    fi
    versions[$tool]=$version
  done < <(profile_items mise)
  return "$failed"
}

check_mise() {
  validate_mise_manifest || return 1
  [[ -z $(profile_items mise) ]] && return 0
  command -v mise >/dev/null || return 1
  local tool version failed=0
  while read -r tool version; do
    mise where "$tool@$version" >/dev/null 2>&1 || { warn "mise tool missing: $tool@$version"; failed=1; }
  done < <(profile_items mise)
  return "$failed"
}

check_stow() {
  local package output failed=0
  command -v stow >/dev/null || return 1
  while IFS= read -r package; do
    [[ $package =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { warn "invalid Stow package name: $package"; failed=1; continue; }
    [[ -d $DOTFILES_ROOT/stow/$package ]] || { warn "unknown Stow package: $package"; failed=1; continue; }
    if ! output=$(stow --no --no-folding --verbose=1 --ignore="$STOW_IGNORE_REGEX" --target="$HOME" --dir="$DOTFILES_ROOT/stow" "$package" 2>&1); then
      warn "Stow conflict in package: $package"; failed=1;
      printf '%s\n' "$output" >&2
    fi
  done < <(profile_items stow)
  return "$failed"
}

run_system_modules() {
  local action=$1 module script failed=0
  while IFS= read -r module; do
    [[ $module =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { warn "invalid system module name: $module"; failed=1; continue; }
    script=$DOTFILES_ROOT/modules/system/$module.sh
    [[ -x $script ]] || { warn "system module is missing or not executable: $module"; failed=1; continue; }
    "$script" "$action" || failed=1
  done < <(profile_items system)
  return "$failed"
}

run_source_modules() {
  local action=$1 module script failed=0
  while IFS= read -r module; do
    [[ $module =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { warn "invalid source module name: $module"; failed=1; continue; }
    script=$DOTFILES_ROOT/modules/source/$module.sh
    [[ -x $script ]] || { warn "source module is missing or not executable: $module"; failed=1; continue; }
    "$script" "$action" || failed=1
  done < <(profile_items source)
  return "$failed"
}

check_all() {
  require_debian
  log "profiles: ${RESOLVED_PROFILES[*]}"
  local failed=0
  check_dependencies || failed=1
  check_apt || failed=1
  check_flatpak || failed=1
  check_mise || failed=1
  check_stow || failed=1
  run_source_modules check || failed=1
  run_system_modules check || failed=1
  ((failed == 0)) || die "check found unresolved items"
  log "all checks passed"
}

install_apt_packages() {
  local -a missing=()
  local package
  while IFS= read -r package; do
    [[ $package =~ ^[a-z0-9][a-z0-9+.:~-]*$ ]] || die "invalid APT package name: $package"
    dpkg-query -W -f='${db:Status-Status}\n' "$package" 2>/dev/null | grep -qx installed || missing+=("$package")
  done < <(profile_items apt)
  ((${#missing[@]})) || return 0
  log "installing APT packages: ${missing[*]}"
  run_sudo apt-get update
  run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
}

install_mise() {
  command -v mise >/dev/null && return 0
  log "installing mise through extrepo"
  run_sudo apt-get install -y --no-install-recommends extrepo
  run_sudo extrepo enable mise
  run_sudo apt-get update
  run_sudo apt-get install -y --no-install-recommends mise
}

apply_flatpak() {
  [[ -z $(profile_items flatpak) ]] && return 0
  flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  local app
  while IFS= read -r app; do
    [[ $app =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "invalid Flatpak application ID: $app"
    flatpak install --user -y flathub "$app"
  done < <(profile_items flatpak)
}

apply_mise() {
  validate_mise_manifest
  [[ -z $(profile_items mise) ]] && return 0
  install_mise
  local tool version
  while read -r tool version; do mise use --global "$tool@$version"; done < <(profile_items mise)
}

apply_stow() {
  local package
  check_stow || die "resolve Stow conflicts before applying"
  while IFS= read -r package; do
    log "正在链接 Stow 包：$package"
    stow --restow --verbose=1 --no-folding --ignore="$STOW_IGNORE_REGEX" \
      --target="$HOME" --dir="$DOTFILES_ROOT/stow" "$package"
  done < <(profile_items stow)
}

apply_all() {
  require_debian
  prepare_proxy_environment
  log "applying profiles: ${RESOLVED_PROFILES[*]}"
  validate_mise_manifest
  install_apt_packages
  check_stow || die "resolve Stow conflicts before applying"
  apply_flatpak
  apply_mise
  apply_stow
  run_source_modules apply
  run_system_modules apply
  log "apply complete"
}

bootstrap() {
  local -a selected=("$@")
  require_debian
  prepare_proxy_environment
  install_apt_packages
  [[ -n $(profile_items mise) ]] && install_mise
  apply_all
  save_profiles "${selected[@]}"
}

unstow_all() {
  require_debian
  command -v stow >/dev/null || die "stow is not installed"
  local package
  while IFS= read -r package; do
    [[ -d $DOTFILES_ROOT/stow/$package ]] || die "unknown Stow package: $package"
    log "正在取消链接 Stow 包：$package"
    stow --delete --verbose=1 --no-folding --ignore="$STOW_IGNORE_REGEX" \
      --target="$HOME" --dir="$DOTFILES_ROOT/stow" "$package"
  done < <(profile_items stow)
  log "Stow links removed; packages and system settings were left unchanged"
}
