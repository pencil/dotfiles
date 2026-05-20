if [[ -n "$CLAUDECODE" ]]; then
  # neutralize prezto autoload stubs that won't resolve in CC's snapshot
  for fn in make diff compinit git-info async prompt-pwd; do
    unfunction $fn 2>/dev/null
  done
fi
