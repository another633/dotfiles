#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  mkdir -p "$HOME"
}

@test "help documents the public commands" {
  run "$ROOT/dot" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *bootstrap* ]]
  [[ "$output" == *unstow* ]]
}

@test "list shows all initial profiles" {
  run "$ROOT/dot" list
  [ "$status" -eq 0 ]
  [[ "$output" == *base* ]]
  [[ "$output" == *dev* ]]
  [[ "$output" == *desktop* ]]
}

@test "unknown profiles fail" {
  run "$ROOT/dot" check --profile unknown
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown profile"* ]]
}

@test "dev profile declares the Vim source module" {
  run grep -Fx vim "$ROOT/profiles/dev/source"
  [ "$status" -eq 0 ]
}

@test "dev profile declares the Bookokrat source module" {
  run grep -Fx bookokrat "$ROOT/profiles/dev/source"
  [ "$status" -eq 0 ]
}

@test "dev profile declares the Yazi source module" {
  run grep -Fx yazi "$ROOT/profiles/dev/source"
  [ "$status" -eq 0 ]
}

@test "desktop profile declares the Hack Nerd Font module" {
  run grep -Fx hack-nerd-font "$ROOT/profiles/desktop/source"
  [ "$status" -eq 0 ]
}

@test "dev profile declares the Ttyper source module" {
  run grep -Fx ttyper "$ROOT/profiles/dev/source"
  [ "$status" -eq 0 ]
}

@test "dev profile declares the AIChat source module" {
  run grep -Fx aichat "$ROOT/profiles/dev/source"
  [ "$status" -eq 0 ]
}

@test "desktop profile declares the Mihomo system module" {
  run grep -Fx mihomo "$ROOT/profiles/desktop/system"
  [ "$status" -eq 0 ]
}

@test "desktop profile declares Google Chrome and Zen Browser" {
  run grep -Fx google-chrome "$ROOT/profiles/desktop/system"
  [ "$status" -eq 0 ]
  run grep -Fx app.zen_browser.zen "$ROOT/profiles/desktop/flatpak"
  [ "$status" -eq 0 ]
}
