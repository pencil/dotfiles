# general
alias ls="ls -Gp"
alias nssh='ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'
alias nscp='scp -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null'

# dotfiles launcher (repo root is intentionally NOT on PATH; see system/path.zsh)
alias dotfiles="\$DOTFILES/dotfiles"

# development
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Helpers/jsc'
alias history='history 1'
