#!/usr/bin/env bash
# Symlink this repo's Firefox prefs (Betterfox base + personal overrides) into
# the active Firefox profile. The profile dir name is randomly generated per
# install (e.g. ys2w2mao.default-release), so it can't be a plain Stow package —
# we resolve the live profile from profiles.ini at runtime instead.
#
# Source of truth: bootstrap.d/firefox/user.js (a data file, not executable, so
# the ./dotfiles run loop skips it). Edit that file to change prefs, then rerun
# ./dotfiles. Idempotent; the first run backs up any pre-existing real user.js.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$script_dir/user.js"
[[ -f "$src" ]] || { echo "firefox/user.js missing next to installer; skipping" >&2; exit 0; }

# Locate the Firefox data dir (macOS first, then Linux). Skip if not installed.
firefox_dir=""
for d in "$HOME/Library/Application Support/Firefox" "$HOME/.mozilla/firefox"; do
  [[ -d "$d" ]] && { firefox_dir="$d"; break; }
done
[[ -n "$firefox_dir" ]] || exit 0

# Resolve the active profile. The [InstallXXXX] section of profiles.ini pins it
# as `Default=<path>` (relative to firefox_dir); the [ProfileN] sections use
# `Default=0/1`, which we filter out. Fall back to globbing if it's absent.
profile_dir=""
ini="$firefox_dir/profiles.ini"
if [[ -f "$ini" ]]; then
  rel="$(grep -E '^Default=' "$ini" | grep -vE '^Default=[01]$' | head -n1 | cut -d= -f2-)"
  [[ -n "$rel" ]] && profile_dir="$firefox_dir/$rel"
fi
if [[ -z "$profile_dir" || ! -d "$profile_dir" ]]; then
  profile_dir="$(find "$firefox_dir/Profiles" "$firefox_dir" -maxdepth 1 -type d \
    \( -name '*.default-release' -o -name '*.default' \) 2>/dev/null | head -n1)"
fi
[[ -n "$profile_dir" && -d "$profile_dir" ]] || {
  echo "No Firefox profile found under $firefox_dir; skipping user.js" >&2
  exit 0
}

dst="$profile_dir/user.js"
if [[ -L "$dst" ]]; then
  ln -sf "$src" "$dst"                      # already ours — repoint if needed
else
  if [[ -e "$dst" ]]; then
    [[ -e "$dst.pre-dotfiles" ]] || cp "$dst" "$dst.pre-dotfiles"  # one-time backup
  fi
  ln -sf "$src" "$dst"
  echo "Linked $dst -> $src"
fi
