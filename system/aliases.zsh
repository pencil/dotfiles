# general
alias ls="ls -Gp"
alias nssh='ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'
alias nscp='scp -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'

# development
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Helpers/jsc'
alias history='history 1'

# ssh wrapper that rename current tmux window to the hostname of the
# remote host.
ssh() {
  # Do nothing if we are not inside tmux or ssh is called without arguments
  if [[ $# == 0 || -z $TMUX ]]; then
    command ssh $@
    return
  fi

  local remote=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -*) shift ;;
      *)  remote="$(echo ${1} | cut -f1 -d.)"; break ;;
    esac
  done
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
