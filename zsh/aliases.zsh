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

alias whois='whois -H'
alias rake='noglob rake'
alias bundle='noglob bundle'
alias jsonpp='underscore print --color'
