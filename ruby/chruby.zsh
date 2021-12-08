if type brew &>/dev/null && [ -d "$(brew --prefix)/opt/chruby/share/chruby" ]
then
  source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh
  source $(brew --prefix)/opt/chruby/share/chruby/auto.sh
fi
