#!/usr/bin/env bash
# Expose whether the Codex session in this pane needs input without taking
# ownership of the window name. Codex can therefore keep the name in sync with
# its thread title through terminal-title escape sequences.

[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null || exit 0

case "$1" in
  start)
    tmux set-option -wq -t "$TMUX_PANE" allow-rename on 2>/dev/null || true
    tmux set-option -wq -t "$TMUX_PANE" automatic-rename-format '#{pane_title}' 2>/dev/null || true
    tmux set-option -wq -t "$TMUX_PANE" automatic-rename on 2>/dev/null || true
    ;;
  on)
    tmux set-option -wq -t "$TMUX_PANE" @codex_needs_input 1 2>/dev/null || true
    ;;
  off)
    tmux set-option -wuq -t "$TMUX_PANE" @codex_needs_input 2>/dev/null || true
    ;;
  end)
    tmux set-option -wuq -t "$TMUX_PANE" @codex_needs_input 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" allow-rename 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" automatic-rename 2>/dev/null || true
    tmux set-option -wuq -t "$TMUX_PANE" automatic-rename-format 2>/dev/null || true
    ;;
esac
