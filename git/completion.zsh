# Make `git check<TAB>` finish to `git checkout ` instead of opening a menu of
# check-attr/check-ignore/check-mailmap/check-ref-format/checkout-index.
#
# The active completion is git's *bundled* zsh wrapper (git-completion.zsh,
# symlinked into Homebrew's site-functions), NOT zsh's native _git. The wrapper
# classifies subcommands under its own tags — common-commands, alias-commands,
# all-commands — so the porcelain tag names from native _git (main-porcelain-
# commands, ancillary-*) match nothing and zsh lumps every real tag into one
# group, offering the union (= the noisy menu).
#
# Listing common+alias as the first group and all-commands as a fallback makes
# zsh try the porcelain set first: `git check` resolves to the lone match
# `checkout` and completes directly, while a prefix unique to a plumbing command
# (`git check-ig`, `git checkout-i`) still falls through to all-commands.
zstyle ':completion:*:*:git:*' tag-order \
  'common-commands alias-commands' 'all-commands'
