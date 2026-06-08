#!/usr/bin/env bash
# claude-tmux-mark.sh — toggle a "needs your input" marker on the tmux window
# name of the pane running this Claude Code session.
#
# Called by Claude Code hooks (see ~/.claude/settings.json):
#   on   — Claude is blocked waiting on you (asking a question / permission)
#   off  — you replied, or the turn ended
#
# The marker is a prefix on the window name. statusline-command.sh preserves it
# when it re-syncs the name to the /rename session title, so the two never fight.
#
# MARKER: a tmux style prefix that turns the whole window entry red while Claude
# is waiting on you — tmux interprets #[...] styles embedded in a window name
# rendered via #W. For a plain emoji indicator instead, use:  MARKER='🔴 '
# Keep this value in sync with the `marker` var in statusline-command.sh.
MARKER='#[fg=colour9,bold]● '

[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null || exit 0

cur=$(tmux display-message -p -t "$TMUX_PANE" '#{window_name}' 2>/dev/null) || exit 0
base=${cur#"$MARKER"}   # strip an existing marker to recover the bare name

case "$1" in
  on)
    if [ "$cur" = "$base" ]; then   # only add if not already marked (idempotent)
      tmux rename-window -t "$TMUX_PANE" "${MARKER}${base}" 2>/dev/null || true
    fi
    ;;
  off)
    tmux rename-window -t "$TMUX_PANE" "$base" 2>/dev/null || true
    ;;
esac
