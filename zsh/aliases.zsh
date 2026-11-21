# search for file name
function ff { ag -g $1 }

# speed up rbenv init by adding --no-rehash
function rbenv {
  if [ "$1" = 'init' ]
  then
    set -- $* --no-rehash
  fi
  command rbenv $*
}

function arc {
  if [ "$1" = 'land' ]
  then
    set -- $* --delete-remote
  fi
  command arc $*
}

alias jsonpp='underscore print --color'
#alias ssh='TERM=xterm-color ssh'
alias xkcdpass='rl -c 4 /usr/share/dict/words | xargs echo'
alias http_server='python3 -m http.server'
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'

# attach or create new tmux session
alias atmux='tmux new -As0'
