# Wrap ssh so an unclean disconnect can't leave the local terminal wedged.
#
# A remote tmux/vim enables mouse tracking, focus events, and bracketed paste by
# sending DECSET sequences up to the terminal, and disables them on exit. If the
# link dies first (laptop sleep, broken pipe) the disable never arrives, so the
# local terminal keeps emitting raw input — e.g. a click shows up as `0;45;12M`.
# (Nesting tmux makes this visible: you land back in a live local shell where the
# leftover sequences print as garbage instead of the pane simply closing.)
#
# ssh reports connection-layer failures as exit 255, so on that exit — and only
# when we own a real TTY (interactive session) — we replay the disable sequences
# ourselves. They're no-ops when the modes were already off, so a clean logout
# (exit 0) is left untouched.

# Replay the "disable" sequences for input modes a remote app may have left on.
_ssh_reset_input_modes() {
  # mouse: normal(1000) btn-event(1002) any-event(1003) utf8(1005) sgr(1006)
  # urxvt(1015); plus focus reporting(1004) and bracketed paste(2004).
  printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?1004l\033[?2004l'
}

ssh() {
  command ssh "$@"
  local ret=$?
  # Interactive (stdout is a TTY) + connection-layer failure = unclean disconnect.
  [[ -t 1 && $ret -eq 255 ]] && _ssh_reset_input_modes
  return $ret
}
