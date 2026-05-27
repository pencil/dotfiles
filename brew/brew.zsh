export HOMEBREW_NO_ANALYTICS=1

# Put brew on PATH. Apple Silicon, Intel macOS, and Linuxbrew install brew in
# different prefixes; pick whichever exists on this machine. Without this,
# fresh non-tmux shells (e.g. ssh logins) lack /opt/homebrew/bin and downstream
# tools like starship never get found.
for _brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$_brew_bin" ]]; then
    eval "$("$_brew_bin" shellenv)"
    break
  fi
done
unset _brew_bin

if type brew &>/dev/null
then
  export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix)/lib"
fi
