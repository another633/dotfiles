# Repository Guidelines

## Project Structure & Module Organization

`dot` is the public Bash entry point. Shared behavior lives in `lib/`: `core.sh`
provides helpers, `profiles.sh` resolves dependencies, and `actions.sh` implements
commands. Machine roles are declared under
`profiles/{base,dev,desktop}/` using line-oriented manifests for APT, Flatpak,
mise, Stow packages, source modules, and system modules. User configuration mirrors `$HOME`
inside `stow/<package>/`. Privileged, idempotent operations belong in
`modules/system/`; user-level source builds belong in `modules/source/`. Tests live in `tests/`.

## Build, Test, and Development Commands

This repository has no build step. Use these commands from the repository root:

```sh
./dot list                         # Show available and active profiles
./dot check --profile base         # Perform a read-only machine check
./tests/run.sh                      # Run portable smoke tests
bats tests/dot.bats                 # Run Bats tests when Bats is installed
shellcheck dot lib/*.sh modules/{source,system}/*.sh tests/*.sh  # Lint Bash
bash -n dot lib/*.sh tests/run.sh   # Check syntax without extra tools
```

Do not run `bootstrap`, `apply`, or `unstow` merely to test: they modify the host.
Prefer a temporary `HOME` and stubbed system commands.

## Coding Style & Naming Conventions

Target Bash and begin executable scripts with `set -Eeuo pipefail`. Use two-space
indentation, lowercase `snake_case` functions and variables, and uppercase names
for exported constants. Quote expansions and use arrays for command arguments.
Keep human-readable script comments in Chinese; preserve machine directives such
as `# shellcheck`. Profile and module names must match
`[a-z0-9][a-z0-9_-]*`. Keep manifest entries one per line with optional `#`
comments.

## Testing Guidelines

Add fast regression coverage to `tests/run.sh`; use `tests/dot.bats` for CLI-level
scenarios. Bats test names should describe observable behavior, for example
`unknown profiles fail`. Verify failure paths, idempotence, profile ordering, and
that `check` never writes files or invokes `sudo`. Run syntax checks, smoke tests,
and `git diff --check` before submitting.

## Commit & Pull Request Guidelines

History currently contains only `first commit`, so no established convention
exists. Use short imperative subjects such as `Add Flatpak profile validation`.
Keep commits focused and avoid committing host-local files, generated state, or
secrets. Pull requests should explain the behavior change, list affected profiles,
include test commands and results, and call out any new package source, `sudo`
operation, or migration. Screenshots are only useful for visible desktop changes.

## Security & Configuration Tips

Never commit credentials. Store private overrides under
`${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local/`. System modules must restrict
changes to documented paths, implement read-only `check` and idempotent `apply`
actions, and back up existing system files before replacement.
