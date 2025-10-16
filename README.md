# dotfiles

My personal dotfiles, targeted towards OSX, Ruby, Vim and tmux.

Some inspiration drawn by holman's dotfiles.

## Symlink Overrides

`.symlink` files normally map to hidden files in `$HOME` (e.g. `vim/vimrc.symlink` → `~/.vimrc`).  
Insert `.target` directories in the path when you need a different destination.  
Example: `codex/codex.target/notify.py.symlink` produces `~/.codex/notify.py`; everything after the `.target` directory is appended under that dot-directory.
