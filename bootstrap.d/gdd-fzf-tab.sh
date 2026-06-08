#!/usr/bin/env bash
# On systems where /usr/bin/dd is the Rust uutils rewrite (e.g. Ubuntu 25),
# `dd iflag=nonblock` blocks on tty reads anyway, which breaks fzf-tab. If GNU
# coreutils is also installed as gnudd, expose it as ~/.local/bin/gdd so
# fzf-tab picks it up via its `gdd` lookup.
set -euo pipefail

if [[ -x /usr/bin/gnudd && ! -e "$HOME/.local/bin/gdd" ]]; then
  mkdir -p "$HOME/.local/bin"
  ln -s /usr/bin/gnudd "$HOME/.local/bin/gdd"
  echo "Symlinked $HOME/.local/bin/gdd -> /usr/bin/gnudd (works around uutils dd)"
fi
