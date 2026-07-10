#!/usr/bin/env bash
# claude-tmux-mark.sh — sole owner of the tmux window name for the pane
# running this Claude Code session: a "needs your input" marker prefix plus
# the session title.
#
#   on          — Claude is blocked waiting on you (hooks: question / permission)
#   off         — the prompt resolved (any tool completed / denied), or the turn ended
#   sync <name> — set the window name to the /rename session title, keeping the
#                 marker state (called by statusline-command.sh on each render;
#                 disables tmux's automatic rename for the window as a side effect)
#
# MARKER: a tmux style prefix that renders the window name as a white-on-red
# badge while Claude is waiting on you — tmux interprets #[...] styles embedded
# in a window name rendered via #W. (A red foreground alone is low-contrast on
# the grey window-status background.) For a plain emoji indicator instead, use:
# MARKER='🔴 '
MARKER='#[bg=colour196,fg=colour231,bold] '

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
    if [ "$cur" != "$base" ]; then   # skip the rename when already unmarked (off runs after every tool call)
      tmux rename-window -t "$TMUX_PANE" "$base" 2>/dev/null || true
    fi
    ;;
  sync)
    [ -n "$2" ] || exit 0
    if [ "$cur" != "$base" ]; then new="${MARKER}$2"; else new="$2"; fi
    if [ "$cur" != "$new" ]; then   # skip the rename when already correct (sync runs on every statusline render)
      tmux rename-window -t "$TMUX_PANE" "$new" 2>/dev/null || true
    fi
    ;;
esac
