git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global core.excludesfile ~/.gitignore

git config --global pull.rebase true
git config --global rebase.autoStash true

git config --global alias.delete-squashed '!f() { local targetBranch=${1:-main} && git checkout -q $targetBranch && git branch --merged | grep -v "\*" | xargs -n 1 git branch -d && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base $targetBranch $branch) && [[ $(git cherry $targetBranch $(git commit-tree $(git rev-parse $branch^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done; }; f'
git config --global alias.delete-merged '!git branch --merged | grep -v "\*" | grep -v master | grep -v main | xargs -n 1 git branch -d'
