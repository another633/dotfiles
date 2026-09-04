#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
failures=0

assert_eq() {
  local expected=$1 actual=$2 message=$3
  if [[ $expected != "$actual" ]]; then
    printf 'FAIL: %s (expected %q, got %q)\n' "$message" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

for file in "$ROOT/dot" "$ROOT"/lib/*.sh "$ROOT"/modules/source/*.sh "$ROOT"/modules/system/*.sh "$ROOT/tests/run.sh"; do
  bash -n "$file" || failures=$((failures + 1))
done

if grep -H 'cargo install' "$ROOT/modules/source/aichat.sh" \
  "$ROOT/modules/source/bookokrat.sh" "$ROOT/modules/source/yazi.sh" \
  "$ROOT/modules/source/ttyper.sh" >/dev/null; then
  printf 'FAIL: a GitHub binary module still invokes cargo install\n' >&2
  failures=$((failures + 1))
fi

export DOTFILES_ROOT=$ROOT
export HOME
HOME=$(mktemp -d)
trap 'rm -rf -- "$HOME"' EXIT
# shellcheck source=../lib/core.sh
source "$ROOT/lib/core.sh"
# shellcheck source=../lib/profiles.sh
source "$ROOT/lib/profiles.sh"
# shellcheck source=../lib/github-release.sh
source "$ROOT/lib/github-release.sh"

write_proxy_config 'http://127.0.0.1:7890'
unset http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
load_proxy_config
assert_eq 'http://127.0.0.1:7890' "$https_proxy" 'saved proxy configuration is loaded'
assert_eq 'localhost,127.0.0.1,::1' "$NO_PROXY" 'local addresses bypass the proxy'
assert_eq '600' "$(stat -c '%a' "$DOTFILES_PROXY_FILE")" 'proxy configuration permissions are private'

GITHUB_RELEASE_TEMP_DIR=$(mktemp -d)
printf '%s\n' '#!/usr/bin/env bash' 'printf "fixture\\n"' > "$GITHUB_RELEASE_TEMP_DIR/fixture"
tar -czf "$GITHUB_RELEASE_TEMP_DIR/fixture.tar.gz" -C "$GITHUB_RELEASE_TEMP_DIR" fixture
GITHUB_RELEASE_ARCHIVE=$GITHUB_RELEASE_TEMP_DIR/fixture.tar.gz
install_tar_binary fixture "$HOME/.local-fixture"
assert_eq 'fixture' "$($HOME/.local-fixture)" 'GitHub tar binary is extracted and installed'
cleanup_github_release

resolve_profiles desktop dev base
assert_eq 'base desktop dev' "${RESOLVED_PROFILES[*]}" 'profiles resolve dependencies once and in order'

mapfile -t apt_items < <(profile_items apt)
assert_eq 'ca-certificates' "${apt_items[0]}" 'base packages come first'
[[ " ${apt_items[*]} " == *' build-essential '* ]] || {
  printf 'FAIL: development package is not included\n' >&2
  failures=$((failures + 1))
}

mapfile -t source_items < <(profile_items source)
[[ " ${source_items[*]} " == *' vim '* ]] || {
  printf 'FAIL: Vim source module is not included\n' >&2
  failures=$((failures + 1))
}
[[ " ${source_items[*]} " == *' ohmyzsh '* ]] || {
  printf 'FAIL: Oh My Zsh source module is not included\n' >&2
  failures=$((failures + 1))
}
[[ " ${source_items[*]} " == *' yazi '* ]] || {
  printf 'FAIL: Yazi source module is not included\n' >&2
  failures=$((failures + 1))
}
[[ " ${source_items[*]} " == *' aichat '* ]] || {
  printf 'FAIL: AIChat source module is not included\n' >&2
  failures=$((failures + 1))
}
[[ " ${source_items[*]} " == *' zen-browser '* ]] || {
  printf 'FAIL: Zen Browser source module is not included\n' >&2
  failures=$((failures + 1))
}

mapfile -t system_items < <(profile_items system)
[[ " ${system_items[*]} " == *' google-chrome '* ]] || {
  printf 'FAIL: Google Chrome system module is not included\n' >&2
  failures=$((failures + 1))
}
save_profiles base dev
assert_eq $'base\ndev' "$(load_saved_profiles)" 'selected profiles persist outside the repository'

list_output=$("$ROOT/dot" list)
[[ $list_output == *base* && $list_output == *desktop* && $list_output == *dev* ]] || {
  printf 'FAIL: list does not show every initial profile\n' >&2
  failures=$((failures + 1))
}

if "$ROOT/dot" check --profile does-not-exist >/dev/null 2>&1; then
  printf 'FAIL: unknown profile was accepted\n' >&2
  failures=$((failures + 1))
fi

git config --file "$ROOT/stow/git/.gitconfig" --list >/dev/null || failures=$((failures + 1))

stow_ignore_count=$(grep -c -- '--ignore="$STOW_IGNORE_REGEX"' "$ROOT/lib/actions.sh")
assert_eq '3' "$stow_ignore_count" 'all Stow operations ignore Vim swap files'
stow_no_folding_count=$(grep -c -- '--no-folding' "$ROOT/lib/actions.sh")
assert_eq '3' "$stow_no_folding_count" 'all Stow operations disable directory folding'
vim_install="$HOME/.local/opt/vim/v9.2.1036"
mkdir -p "$vim_install/bin" "$HOME/.local/bin"
printf '%s\n' '#!/usr/bin/env bash' \
  'if [[ ${LC_ALL:-} == C ]]; then' \
  "  cat <<'EOF'" \
  'VIM - Vi IMproved 9.2' \
  'Included patches: 1-1036' \
  'Huge version without GUI.' \
  '+lua +python3 +perl -ruby -tcl +terminal +clipboard +X11 +xterm_clipboard +wayland +wayland_clipboard' \
  'EOF' \
  'else' \
  "  cat <<'EOF'" \
  'VIM - Vi IMproved 9.2' \
  '包含补丁：1-1036' \
  '无图形界面的巨大版本。' \
  '+lua +python3 +perl -ruby -tcl +terminal +clipboard +X11 +xterm_clipboard +wayland +wayland_clipboard' \
  'EOF' \
  'fi' > "$vim_install/bin/vim"
chmod +x "$vim_install/bin/vim"
for command in vimdiff view ex rvim rview xxd; do
  ln -s vim "$vim_install/bin/$command"
done
ln -s "$vim_install" "$HOME/.local/opt/vim/current"
for command in vim vimdiff view ex rvim rview xxd; do
  ln -s "$HOME/.local/opt/vim/current/bin/$command" "$HOME/.local/bin/$command"
done
"$ROOT/modules/source/vim.sh" check >/dev/null || {
  printf 'FAIL: valid Vim installation was rejected\n' >&2
  failures=$((failures + 1))
}
sed -i 's/ +X11//' "$vim_install/bin/vim"
if "$ROOT/modules/source/vim.sh" check >/dev/null 2>&1; then
  printf 'FAIL: Vim without X11 clipboard support was accepted\n' >&2
  failures=$((failures + 1))
fi

printf '%s\n' '#!/usr/bin/env bash' 'printf "bookokrat 0.3.12\\n"' > "$HOME/.local/bin/bookokrat"
chmod +x "$HOME/.local/bin/bookokrat"
"$ROOT/modules/source/bookokrat.sh" check >/dev/null || {
  printf 'FAIL: valid Bookokrat installation was rejected\n' >&2
  failures=$((failures + 1))
}

for command in yazi ya; do
  printf '%s\n' '#!/usr/bin/env bash' "printf '$command\\n    Version: 26.9.1 (test)\\n'" > "$HOME/.local/bin/$command"
  chmod +x "$HOME/.local/bin/$command"
done
"$ROOT/modules/source/yazi.sh" check >/dev/null || {
  printf 'FAIL: valid Yazi installation was rejected\n' >&2
  failures=$((failures + 1))
}

printf '%s\n' '#!/usr/bin/env bash' 'printf "ttyper 1.6.0\\n"' > "$HOME/.local/bin/ttyper"
chmod +x "$HOME/.local/bin/ttyper"
"$ROOT/modules/source/ttyper.sh" check >/dev/null || {
  printf 'FAIL: valid Ttyper installation was rejected\n' >&2
  failures=$((failures + 1))
}

printf '%s\n' '#!/usr/bin/env bash' 'printf "aichat 0.30.0\\n"' > "$HOME/.local/bin/aichat"
chmod +x "$HOME/.local/bin/aichat"
"$ROOT/modules/source/aichat.sh" check >/dev/null || {
  printf 'FAIL: valid AIChat installation was rejected\n' >&2
  failures=$((failures + 1))
}

ohmyzsh_install="$HOME/.local/share/oh-my-zsh/9112b53fa8b5ab556c7c893aa8be8a247ac512a0"
mkdir -p "$ohmyzsh_install"
printf '%s\n' '# Oh My Zsh test fixture' > "$ohmyzsh_install/oh-my-zsh.sh"
ln -s "$ohmyzsh_install" "$HOME/.local/share/oh-my-zsh/current"
"$ROOT/modules/source/ohmyzsh.sh" check >/dev/null || {
  printf 'FAIL: valid Oh My Zsh installation was rejected\n' >&2
  failures=$((failures + 1))
}

zen_install="$HOME/.local/opt/zen-browser/1.21.16b"
mkdir -p "$zen_install" "$HOME/.local/share/applications"
printf '%s\n' '#!/usr/bin/env bash' > "$zen_install/zen"
printf '%s\n' 'Version=1.21.16b' > "$zen_install/application.ini"
chmod +x "$zen_install/zen"
ln -s "$zen_install" "$HOME/.local/opt/zen-browser/current"
ln -s "$HOME/.local/opt/zen-browser/current/zen" "$HOME/.local/bin/zen"
printf '%s\n' '[Desktop Entry]' > "$HOME/.local/share/applications/zen-browser.desktop"
"$ROOT/modules/source/zen-browser.sh" check >/dev/null || {
  printf 'FAIL: valid Zen Browser installation was rejected\n' >&2
  failures=$((failures + 1))
}

if grep -Eq 'google-chrome\.sources|linux_signing_key|chrome/deb/' \
  "$ROOT/modules/system/google-chrome.sh"; then
  printf 'FAIL: Google Chrome module still manages an APT repository\n' >&2
  failures=$((failures + 1))
fi

if ((failures)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf 'All tests passed\n'
