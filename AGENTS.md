# Repository Guidelines

## Project Structure & Module Organization
- Each top-level directory is a **GNU Stow package**. Its internal layout mirrors the destination relative to `$HOME` — e.g. `zsh/.zshrc` → `~/.zshrc`, `starship/.config/starship.toml` → `~/.config/starship.toml`, `claude/.claude/settings.json` → `~/.claude/settings.json`.
- `./dotfiles` runs `stow */` so adding a new tool is just `mkdir <tool>/<path-under-$HOME>` and rerunning — no script edits.
- Each `*.zsh` file in any directory is auto-sourced by `zsh/.zshrc`, which globs `$DOTFILES/**/*.zsh`. This is how tool-specific env vars, aliases, and PATH entries get loaded (e.g., `go/path.zsh`, `nvm/nvm.zsh`, `mise/mise.zsh`). `./dotfiles` passes `--ignore='\.zsh$'` to stow so these snippets don't get linked into `$HOME`.

### Directory inventory
| Directory | Purpose |
|-----------|---------|
| `zsh/` | `.zshrc`, `.zshenv`; antidote loader, prompt init |
| `bash/` | Bash fallback (`.bash_profile`, `.inputrc`) |
| `system/` | Auto-sourced env, aliases, PATH snippets (not stowed) |
| `vim/` | Legacy Vim config (`.vimrc`) |
| `nvim/` | Neovim LazyVim config (under `.config/nvim/`) |
| `alacritty/`, `ghostty/`, `kitty/` | Terminal emulator configs (each under `.config/<term>/`) |
| `starship/` | Starship prompt config (`.config/starship.toml`) |
| `tmux/` | Tmux config (`.tmux.conf`) |
| `git/` | Global gitignore + `gitconfig.zsh`, `completion.zsh` snippets |
| `brew/` | `.Brewfile`, `.Brewfile.lock.json` |
| `claude/` | Claude Code settings + hook audio files (under `.claude/`) |
| `codex/` | Codex config + notification script (under `.codex/`) |
| `aider/` | Aider conf and conventions |
| `antidote/` | `.zsh_plugins.txt` for the zsh plugin manager |
| `mise/`, `nvm/`, `go/`, `java/`, `ruby/`, `aws/` | Runtime/CLI loaders; mostly `*.zsh` snippets (auto-sourced) |
| `ag/`, `ack/`, `ctags/` | Search/index tool configs |
| `macos/` | macOS system defaults script (`.macos`) |

## Build, Test, and Development Commands
- `./dotfiles` runs `stow --no-folding --ignore='\.zsh$' */` to recreate every symlink in `$HOME`. Idempotent; safe to rerun.
- `brew bundle --file=~/.Brewfile` installs or updates formulae, casks, and App Store apps; run `brew bundle cleanup --file=~/.Brewfile` before pruning.
- `nvim --headless "+Lazy sync" "+qa"` keeps Lua plugin declarations and the lock file aligned after editing `nvim/.config/nvim/`.
- `zsh -n path/to/file.zsh` quickly parses shell scripts for syntax errors before sourcing them in a login shell.

## Coding Style & Naming Conventions
- Favor lowercase directory names matching the target tool.
- Shell scripts and Zsh functions stay POSIX-friendly, indent with two spaces, and add descriptive comments only around non-obvious blocks.
- Lua files follow `stylua` (`nvim/.config/nvim/stylua.toml`), enforcing 2-space indentation and 120-character lines; run `stylua lua/**/*.lua` before committing.
- Commit changes by editing the real file (e.g. `brew/.Brewfile`) rather than the symlink in `$HOME`.
- New tool init scripts follow the guard pattern: check if the tool is installed, then source/eval (see `mise/mise.zsh`, `nvm/nvm.zsh`, `ruby/chruby.zsh`).

## Zsh Plugin Management (antidote)
- Plugins are listed in `antidote/.zsh_plugins.txt` (→ `~/.zsh_plugins.txt`) and loaded by `zsh/.zshrc` via antidote's static-bundle mode (`~/.zsh_plugins.zsh`).
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
  3. Edit the `pin:<sha>` value for that bundle in `antidote/.zsh_plugins.txt`.
  4. Force a refresh: `rm -rf ~/.cache/antidote/github.com/<owner>/<repo> ~/.zsh_plugins.zsh && exec zsh`.
  5. Refresh the secrets baseline so detect-secrets accepts the new hex SHA: `detect-secrets scan --exclude-files '(^|/)(brew/\.Brewfile\.lock\.json|lazy-lock\.json)$' --baseline .secrets.baseline`. Without this the pre-commit hook will reject the commit.

## Testing Guidelines
- No automated test suite exists; validate manually by spawning a fresh shell (`zsh -l`) and opening Neovim to confirm configs load without warnings.
- Run `nvim --headless "+checkhealth" "+qa"` whenever plugins or LSP settings change.
- For shell utilities, lint with `shellcheck` when available (`shellcheck zsh/aliases.zsh`), or at minimum execute `zsh -n`.

## Commit & Pull Request Guidelines
- Keep commit subjects short (≤50 chars) and imperative (e.g., `Add mise init script`); separate unrelated tweaks into different commits.
- Reference the affected tool or script in the body and mention any required follow-up commands (`./dotfiles`, `brew bundle`, `Lazy sync`).
