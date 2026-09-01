#!/usr/bin/env bash
# The tools this repo needs that no Debian/Ubuntu package provides, installed
# unprivileged into ~/.local/bin (already on PATH via system/path.zsh):
#
#   starship  zsh/.zshrc only initializes the prompt when it is on PATH, so
#             without it the shell silently falls back to the bare zsh prompt.
#   uv        provides the two Python CLIs this repo's own hooks need —
#             pre-commit runs them and detect-secrets is the hook that scans.
#
# macOS gets all of these from brew/.Brewfile.
#
# The filename has to sort before pre-commit-hooks.sh: ./dotfiles runs the steps
# in glob order, and that step exits quietly when pre-commit is missing, so
# installing it afterwards would delay the hooks until the next run.
set -euo pipefail

[[ "$(uname -s)" == "Linux" ]] || exit 0

# The installers below land binaries here, but this step may run in a shell that
# predates ~/.local/bin existing on PATH.
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

if ! command -v starship >/dev/null; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
fi

if ! command -v uv >/dev/null; then
  curl -fsSL https://astral.sh/uv/install.sh | sh
fi

for tool in pre-commit detect-secrets; do
  command -v "$tool" >/dev/null || uv tool install "$tool"
done
