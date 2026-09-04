#!/usr/bin/env bash

declare -a RESOLVED_PROFILES=()
declare -A PROFILE_STATE=()

validate_profile_name() {
  [[ $1 =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "invalid profile name: $1"
}

resolve_profile() {
  local profile=$1 dep state
  state=${PROFILE_STATE[$profile]:-}
  validate_profile_name "$profile"
  [[ -d $DOTFILES_ROOT/profiles/$profile ]] || die "unknown profile: $profile"
  [[ $state != visiting ]] || die "profile dependency cycle at: $profile"
  [[ $state != done ]] || return 0
  PROFILE_STATE[$profile]=visiting
  while IFS= read -r dep; do resolve_profile "$dep"; done < <(read_manifest "$DOTFILES_ROOT/profiles/$profile/deps")
  PROFILE_STATE[$profile]=done
  RESOLVED_PROFILES+=("$profile")
}

resolve_profiles() {
  RESOLVED_PROFILES=()
  PROFILE_STATE=()
  local profile
  for profile in "$@"; do resolve_profile "$profile"; done
}

profile_items() {
  local kind=$1 profile
  for profile in "${RESOLVED_PROFILES[@]}"; do
    read_manifest "$DOTFILES_ROOT/profiles/$profile/$kind"
  done | dedupe_lines
}

load_saved_profiles() { read_manifest "$DOTFILES_PROFILE_FILE"; }

save_profiles() {
  local -a profiles=("$@")
  mkdir -p -- "$DOTFILES_CONFIG_HOME"
  local tmp
  tmp=$(mktemp "$DOTFILES_CONFIG_HOME/profiles.XXXXXX")
  printf '%s\n' "${profiles[@]}" > "$tmp"
  mv -- "$tmp" "$DOTFILES_PROFILE_FILE"
}

list_profiles() {
  local active='' profile marker
  [[ -f $DOTFILES_PROFILE_FILE ]] && active=$(load_saved_profiles | tr '\n' ' ')
  printf 'Available profiles:\n'
  for profile in "$DOTFILES_ROOT"/profiles/*; do
    [[ -d $profile ]] || continue
    profile=${profile##*/}
    marker=' '
    [[ " $active " == *" $profile "* ]] && marker='*'
    printf ' %s %s\n' "$marker" "$profile"
  done
  printf '\n* active on this machine\n'
}
