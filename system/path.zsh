# Keep the repo root OUT of PATH. It was only ever here to expose the `dotfiles`
# launcher, but it dragged every stow-package subdir (mise/, go/, ruby/, …) onto
# PATH as a directory. Tools that look themselves up on PATH and accept anything
# with the execute bit — directories included — then resolve to the wrong place:
# `mise` found `$DOTFILES/mise/` (a dir) before /usr/bin/mise and pointed all its
# shims at it. The launcher is an alias instead (see system/aliases.zsh).
export PATH="$HOME/.local/bin:$PATH"
