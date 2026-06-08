# Keep PATH/FPATH free of duplicates. Marking these as unique arrays makes zsh
# drop repeated entries (keeping the leftmost) on every assignment, so the
# non-idempotent prepend/append snippets stay tidy even when .zshrc is re-sourced
# by nested shells.
typeset -U path PATH fpath FPATH

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# mise: give non-interactive shells (scripts, automation, make children) the
# mise-managed node. The `mise activate` hook in .zshrc only adjusts PATH from a
# precmd hook, which never fires in non-interactive shells, so without this they
# fall back to the old system node. (mise's own shims are misconfigured on this
# box — they symlink to a directory — so resolve the node bin directly instead.)
# `typeset -U path` above dedupes if the interactive precmd hook adds it too.
if command -v mise >/dev/null 2>&1; then
  # Prefer the cwd's mise version (trusted .mise.toml); fall back to the global
  # default when the cwd has no/untrusted config. Guard against empty output so
  # we never prepend a bare "/bin" (which would shadow node with the system one).
  __mise_node_dir="$(mise where node 2>/dev/null)"
  [[ -z "$__mise_node_dir" ]] && __mise_node_dir="$(cd "$HOME" && mise where node 2>/dev/null)"
  [[ -n "$__mise_node_dir" && -d "$__mise_node_dir/bin" ]] && path=("$__mise_node_dir/bin" $path)
  unset __mise_node_dir
fi
