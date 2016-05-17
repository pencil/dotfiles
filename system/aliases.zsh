# general
alias ls="ls -Gp"
alias nssh='ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'
alias nscp='scp -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'
alias flush-dns='sudo discoveryutil udnsflushcaches'

# development
alias git-delete-merged-branches='git branch --merged | grep -v "\*" | grep -v master | xargs -n 1 git branch -d'
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Resources/jsc'
alias ijs='jsc'
alias iphp='php -a'
alias rc='rails console'
alias qq='touch tmp/restart.txt'
alias b='bundle'
alias history='history 1'

# ssh wrapper that rename current tmux window to the hostname of the
# remote host.
ssh() {
  # Do nothing if we are not inside tmux or ssh is called without arguments
  if [[ $# == 0 || -z $TMUX ]]; then
    command ssh $@
    return
  fi
  # The hostname is the last parameter (i.e. ${(P)#})
  local remote="$(echo ${@: -1} | cut -f1 -d.)"
  local old_name="$(tmux display-message -p '#W')"
  local renamed=0
  # Save the current name
  if [[ $remote != -* ]]; then
    renamed=1
    tmux rename-window $remote
  fi
  command ssh $@
  if [[ $renamed == 1 ]]; then
    tmux rename-window "$old_name"
  fi
}
