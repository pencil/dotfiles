if type brew &> /dev/null
then
  export GOROOT="$(brew --prefix)/opt/go/libexec"
fi
export GOPATH="$HOME/projects/go"

export PATH="$PATH:$GOPATH/bin"
