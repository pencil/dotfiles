# Repository Guidelines

## Project Structure & Module Organization
- Root directories map to individual tools and contain `.symlink`/`.dsymlink` assets that the repo links into `$HOME`.
- Each `*.zsh` file in any directory is auto-sourced by `zsh/zshrc.symlink`, which globs `$DOTFILES/**/*.zsh`. This is how tool-specific env vars, aliases, and PATH entries get loaded (e.g., `go/path.zsh`, `nvm/nvm.zsh`, `mise/mise.zsh`).

### Symlink conventions
- **`.symlink`** files become hidden dotfiles in `$HOME`: `vim/vimrc.symlink` → `~/.vimrc`.
- **`.dsymlink`** directories become dirs under `$HOME/.`: `config/nvim.dsymlink` → `~/.config/nvim`.
- **`.target`** parent directories override the destination: `claude/claude.target/settings.json.symlink` → `~/.claude/settings.json`.

### Directory inventory
| Directory | Purpose |
|-----------|---------|
| `zsh/` | Zshrc, zshenv, aliases |
| `prezto/` | Prezto framework config (zpreztorc, zlogin, zlogout, zprofile) |
| `bash/` | Bash fallback (bash_profile, inputrc) |
| `system/` | System-wide env, aliases, PATH |
| `vim/` | Legacy Vim config |
| `config/nvim.dsymlink/` | Neovim LazyVim setup (Lua plugins, stylua.toml, lazy-lock.json) |
| `tmux/` | Tmux config |
| `git/` | Git aliases (gitconfig.zsh) and global gitignore |
| `brew/` | Homebrew Brewfile and loader |
| `claude/` | Claude Code settings and hook audio files (via .target) |
| `codex/` | Codex config and notification script (via .target) |
| `aider/` | Aider conf and conventions |
| `mise/` | mise runtime manager activation |
| `config/ghostty/` | Ghostty terminal config |
| `config/kitty/` | Kitty terminal config |
| `config/alacritty/` | Alacritty terminal config |
| `ruby/` | chruby loader |
| `go/` | GOPATH/GOROOT setup |
| `java/` | JAVA_HOME and Android SDK paths |
| `nvm/` | Node Version Manager loader |
| `ag/`, `ack/` | Search tool configs (agignore, ackrc) |
| `aws/` | AWS CLI setup |
| `macos/` | macOS system defaults script |
| `teamocil/` | Tmux session templates |

## Build, Test, and Development Commands
- `./dotfiles` (Ruby) regenerates all symlinks in `$HOME`; rerun after adding or renaming any `*.symlink`/`*.dsymlink` assets.
- `brew bundle --file=brew/Brewfile.symlink` installs or updates formulae, casks, and App Store apps; run `brew bundle cleanup --file=brew/Brewfile.symlink` before pruning.
- `nvim --headless "+Lazy sync" "+qa"` ensures Lua plugin declarations and the lock file stay aligned after editing `config/nvim.dsymlink`.
- `zsh -n path/to/file.zsh` quickly parses shell scripts for syntax errors before sourcing them in a login shell.

## Coding Style & Naming Conventions
- Favor lowercase directory names matching the target tool.
- Shell scripts and Zsh functions stay POSIX-friendly, indent with two spaces, and add descriptive comments only around non-obvious blocks.
- Lua files follow `stylua` (`config/nvim.dsymlink/stylua.toml`), enforcing 2-space indentation and 120-character lines; run `stylua lua/**/*.lua` before committing.
- Commit new dependencies by editing the relevant `*.symlink` file (e.g., `brew/Brewfile.symlink`) rather than the generated file in `$HOME`.
- New tool init scripts follow the guard pattern: check if the tool is installed, then source/eval (see `mise/mise.zsh`, `nvm/nvm.zsh`, `ruby/chruby.zsh`).

## Zsh Plugin Management (antidote)
- Plugins are listed in `antidote/zsh_plugins.txt.symlink` (→ `~/.zsh_plugins.txt`) and loaded by `zsh/zshrc.symlink` via antidote's static-bundle mode (`~/.zsh_plugins.zsh`).
- Every plugin is pinned to a specific commit SHA via `pin:<sha>`. `antidote update` explicitly skips pinned bundles, making installs reproducible and immune to upstream tag/branch movement.
- **Do not bump pinned versions unless the user explicitly asks.** Treat the SHAs as locked.
- When the user asks to bump a plugin:
  1. **Audit before pinning.** Treat each bump as a supply-chain decision, not a rubber-stamp:
     - Compare the new SHA against the old: `git -C ~/.cache/antidote/github.com/<owner>/<repo> log --oneline <old>..<new>`. Skim commit messages, authors, and any unusually large diffs. Be suspicious of force-pushed history, new maintainers, or post-install/build hooks added to the plugin.
     - If the repo was tagged, prefer the tag SHA over default-branch HEAD — tag-then-immediately-bump is a common attack pattern.
     - If anything looks off (compromised account chatter, unexplained binary additions, obfuscated zsh), surface it to the user before pinning.
  2. Resolve the new SHA from the upstream remote — pick the right form:
     - Default-branch HEAD: `git ls-remote https://github.com/<owner>/<repo> HEAD`
     - Lightweight tag: `git ls-remote https://github.com/<owner>/<repo> refs/tags/<tag>`
     - Annotated tag (peel to commit): `git ls-remote https://github.com/<owner>/<repo> 'refs/tags/<tag>^{}'`
  3. Edit the `pin:<sha>` value for that bundle in `antidote/zsh_plugins.txt.symlink`.
  4. Force a refresh: `rm -rf ~/.cache/antidote/github.com/<owner>/<repo> ~/.zsh_plugins.zsh && exec zsh`.
  5. Refresh the secrets baseline so detect-secrets accepts the new hex SHA: `detect-secrets scan --exclude-files '(^|/)(brew/Brewfile\.lock\.json\.symlink|lazy-lock\.json)$' --baseline .secrets.baseline`. Without this the pre-commit hook will reject the commit.

## Testing Guidelines
- No automated test suite exists; validate manually by spawning a fresh shell (`zsh -l`) and opening Neovim to confirm configs load without warnings.
- Run `nvim --headless "+checkhealth" "+qa"` whenever plugins or LSP settings change.
- For shell utilities, lint with `shellcheck` when available (`shellcheck zsh/aliases.zsh`), or at minimum execute `zsh -n`.

## Commit & Pull Request Guidelines
- Keep commit subjects short (≤50 chars) and imperative (e.g., `Add mise init script`); separate unrelated tweaks into different commits.
- Reference the affected tool or script in the body and mention any required follow-up commands (`./dotfiles`, `brew bundle`, `Lazy sync`).
