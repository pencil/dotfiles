export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1

# Stop Claude Code from capturing mouse events (scroll etc.) so the
# terminal/tmux native scrollback keeps working.
export CLAUDE_CODE_DISABLE_MOUSE=1

# Also skip the alternate-screen renderer: in alt-screen mode tmux either
# forwards scroll events into the pane (see the WheelUpPane binding in
# tmux/.tmux.conf) or has no scrollback to show, so inline rendering is the
# only way to get the transcript into the regular pane history.
export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1
