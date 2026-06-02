# Keep PATH/FPATH free of duplicates. Marking these as unique arrays makes zsh
# drop repeated entries (keeping the leftmost) on every assignment, so the
# non-idempotent prepend/append snippets stay tidy even when .zshrc is re-sourced
# by nested shells.
typeset -U path PATH fpath FPATH

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
