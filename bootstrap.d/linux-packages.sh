#!/usr/bin/env bash
# Distro packages that the rest of this repo assumes are present: jq for
# bootstrap.d/agent-configs, plus the CLI tools the *.zsh snippets and the
# Neovim config reach for. macOS gets the same set from brew/.Brewfile.
#
# stow is deliberately in the list even though ./dotfiles already exits without
# it — this step runs after stowing, so the first install is always by hand.
#
# Debian/Ubuntu only; any other package manager falls through untouched.
# Installing needs root, so a fresh machine may prompt for a sudo password.
set -euo pipefail

command -v apt-get >/dev/null || exit 0

# fd and fzf carry different package names here than the Homebrew formulae.
packages=(curl fd-find fzf git gnupg jq neovim ripgrep stow zsh)

# Only touch apt when something is actually absent, so a rerun costs nothing.
apt_install() {
  local pkg missing=()
  for pkg in "$@"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
  fi
}

apt_install "${packages[@]}"

# mise ships from its own repo rather than the distro's, so it needs the keyring
# and source list before apt can see it.
if ! command -v mise >/dev/null; then
  sudo install -dm 755 /etc/apt/keyrings
  curl -fsSL https://mise.jdx.dev/gpg-key.pub |
    gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" |
    sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
  apt_install mise
fi
