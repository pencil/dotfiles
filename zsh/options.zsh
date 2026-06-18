## History
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=10000
SAVEHIST=10000

setopt EXTENDED_HISTORY       # write `:start:elapsed;cmd` format
setopt HIST_EXPIRE_DUPS_FIRST # trim duplicates first
setopt HIST_IGNORE_DUPS       # don't record consecutive dupes
setopt HIST_IGNORE_ALL_DUPS   # delete old dupe when new one added
setopt HIST_IGNORE_SPACE      # leading space hides entry
setopt HIST_VERIFY            # show before executing history expansion
setopt HIST_FIND_NO_DUPS

## Directory
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
unsetopt CLOBBER              # require `>!` to overwrite

## Job control
setopt LONG_LIST_JOBS
setopt NOTIFY
unsetopt BG_NICE

## Misc
setopt INTERACTIVE_COMMENTS   # `#` comments at the prompt
setopt COMBINING_CHARS

## Keybindings (prezto default was emacs)
bindkey -e
# Up/Down: search history for entries matching the current prefix
# (history-substring-search plugin provides the widgets — antidote loads them)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
# Inside tmux (and other terminals in application-cursor-key mode) the arrows
# send the SS3 sequences ^[OA/^[OB instead of the CSI ^[[A/^[[B above. Bind
# whatever the current terminal actually emits, via terminfo.
zmodload -i zsh/terminfo
[[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" history-substring-search-up
[[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" history-substring-search-down

## Word boundaries (so ctrl-w/alt-b/etc. break on punctuation the prezto way)
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

## Terminal window/tab title — `<user>@<host>: <cwd>` when idle, command when running
case "$TERM" in
  xterm*|rxvt*|tmux*|screen*|ghostty|alacritty|*kitty*)
    autoload -Uz add-zsh-hook
    function _title_precmd { print -Pn "\e]0;%n@%m: %~\a" }
    function _title_preexec { print -Pn "\e]0;%n@%m: $1\a" }
    add-zsh-hook precmd _title_precmd
    add-zsh-hook preexec _title_preexec
    ;;
esac
