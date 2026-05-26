# Hide git plumbing/helper subcommands from completion.
# Without this, `git check<TAB>` offers check-attr/check-ignore/check-mailmap/
# check-ref-format alongside checkout. Restricting tag-order keeps only the
# porcelain-ish groups, so unambiguous prefixes like `check` finish to `checkout`.
zstyle ':completion:*:*:git:*' tag-order \
  main-porcelain-commands user-commands third-party-commands aliases \
  ancillary-manipulator-commands ancillary-interrogator-commands \
  interaction-commands
