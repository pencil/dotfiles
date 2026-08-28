#!/usr/bin/env bash
# zsh/.zshrc looks for antidote under Homebrew first and then in ~/.antidote.
# On a machine with no Homebrew nothing provides it, so ~/.zsh_plugins.zsh is
# never generated and every plugin vanishes without a message — including the
# widgets that zsh/options.zsh binds to the arrow keys.
set -euo pipefail

# Pinned to a tag the same way the bundles in antidote/.zsh_plugins.txt are
# (v2.3.0). Change the SHA to move; the clone is re-pointed on the next run.
ANTIDOTE_SHA=9bb69ab99c6f05d6e6ae237f7ce222eeeb5b4a14

[[ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" ]] && exit 0
command -v git >/dev/null || exit 0

dest=$HOME/.antidote
if [[ ! -d "$dest/.git" ]]; then
  git clone --quiet https://github.com/mattmc3/antidote "$dest"
  echo "Cloned antidote into $dest"
fi

if [[ "$(git -C "$dest" rev-parse HEAD)" != "$ANTIDOTE_SHA" ]]; then
  git -C "$dest" fetch --quiet origin
  git -C "$dest" checkout --quiet "$ANTIDOTE_SHA"
  echo "Checked out antidote at $ANTIDOTE_SHA"
  # The generated bundle is stale once the plugin manager itself moves.
  rm -f "$HOME/.zsh_plugins.zsh"
fi
