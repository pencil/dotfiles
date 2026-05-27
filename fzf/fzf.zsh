if type fzf &>/dev/null
then
  # `fzf --zsh` snapshots all shell options and restores them via `eval`,
  # which trips "can't change option: zle" warnings on every shell start
  # because `zle` is read-only post-startup. The output is otherwise
  # well-formed, so drop stderr from this eval specifically.
  eval "$(fzf --zsh)" 2>/dev/null
fi
