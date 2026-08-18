#!/usr/bin/env bash
# Keep Codex window names synced with thread titles while leaving runtime state
# available in the pane title for tmux status formatting.

[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null || exit 0

case "$1" in
  start)
    tmux set-option -wq -t "$TMUX_PANE" @codex_session 1 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" @codex_needs_input 2>/dev/null || true
    tmux set-option -wq -t "$TMUX_PANE" allow-rename on 2>/dev/null || true
    tmux set-option -wq -t "$TMUX_PANE" automatic-rename-format '#{s@^[^|]*[|][ ]*@@:pane_title}' 2>/dev/null || true
    tmux set-option -wq -t "$TMUX_PANE" automatic-rename on 2>/dev/null || true
    ;;
  end)
    tmux set-option -wuq -t "$TMUX_PANE" @codex_session 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" @codex_needs_input 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" allow-rename 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" automatic-rename 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" automatic-rename-format 2>/dev/null || true
    ;;
esac
