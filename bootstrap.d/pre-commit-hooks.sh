#!/usr/bin/env bash
# Install this repo's pre-commit hooks (detect-secrets etc.) so commits to the
# dotfiles repo get checked. Runs with the repo root as cwd (set by ./dotfiles).
# Skipped inside a git worktree, where .git is a file pointing at the shared
# common dir and `pre-commit install` would clobber the main checkout's hooks.
set -euo pipefail

command -v pre-commit >/dev/null || exit 0

git_dir=$(git rev-parse --git-dir 2>/dev/null || true)
git_common=$(git rev-parse --git-common-dir 2>/dev/null || true)
if [[ -n "$git_dir" && "$git_dir" != "$git_common" ]]; then
  echo "Skipping pre-commit install (inside a git worktree)"
else
  pre-commit install
fi
