export HOMEBREW_NO_ANALYTICS=1
if type brew &>/dev/null
then
  export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix)/lib"
fi
