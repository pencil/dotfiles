export HOMEBREW_NO_ANALYTICS=1

# Prepend Homebrew's bin/sbin to PATH so its tooling outranks Apple's older
# bundled binaries (e.g. /usr/bin/git 2.50.1 vs brew git 2.54.0). The matching
# completion file in FPATH below assumes the brew-shipped binary; without this,
# `git` completion shells out to Apple git and prints "unknown option" errors.
for _brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$_brew_bin" ]]; then
    _brew_prefix="${_brew_bin%/bin/brew}"
    export PATH="$_brew_prefix/bin:$_brew_prefix/sbin:$PATH"
    break
  fi
done
unset _brew_bin _brew_prefix

if type brew &>/dev/null
then
  export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix)/lib"
fi
