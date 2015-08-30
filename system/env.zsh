export TERM=screen-256color
export LC_ALL=en_US.UTF-8
export DISABLE_SPRING=1 # SPRING – NOT EVEN ONCE

export GREP_OPTIONS='--color=auto --exclude-dir=.cvs --exclude-dir=.git --exclude-dir=.hg --exclude-dir=.svn'

if [ -d "/opt/boxen" ]
then
  export BOXEN_HOME='/opt/boxen'
  export CFLAGS="-I$BOXEN_HOME/homebrew/include"
  export CPPFLAGS="-I$BOXEN_HOME/homebrew/include"
  export CPLUS_INCLUDE_PATH="$BOXEN_HOME/homebrew/include"
  export LIBRARY_PATH="$BOXEN_HOME/homebrew/lib"
fi
