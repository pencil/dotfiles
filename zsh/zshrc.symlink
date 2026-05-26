: ${DOTFILES:=$HOME/.dotfiles}
export DOTFILES

# Private overrides not checked in
[[ -f ~/.localrc ]] && source ~/.localrc

# Plugin manager: antidote (static bundle mode for fast startup and to avoid
# antidote capturing git stderr into the generated bundle). Load before the
# per-tool snippets below so ez-compinit's `compdef` queueing stub is in place
# for any snippet that registers completions (e.g. phabricator's bashcompinit).
if [[ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh"
elif [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
  source "$HOME/.antidote/antidote.zsh"
fi
if type antidote >/dev/null; then
  if [[ ! -r ~/.zsh_plugins.zsh || ~/.zsh_plugins.txt -nt ~/.zsh_plugins.zsh ]]; then
    antidote bundle <~/.zsh_plugins.txt >|~/.zsh_plugins.zsh 2>/dev/null
  fi
  source ~/.zsh_plugins.zsh
fi

# Auto-source per-tool config snippets (history opts, env vars, aliases, etc.)
config_files=($DOTFILES/**/*.zsh)
for file in $config_files; do
  source $file
done
unset config_files file

# Prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# Sharing is caring... I don't care!
unsetopt SHARE_HISTORY

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
