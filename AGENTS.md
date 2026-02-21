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

## Testing Guidelines
- No automated test suite exists; validate manually by spawning a fresh shell (`zsh -l`) and opening Neovim to confirm configs load without warnings.
- Run `nvim --headless "+checkhealth" "+qa"` whenever plugins or LSP settings change.
- For shell utilities, lint with `shellcheck` when available (`shellcheck zsh/aliases.zsh`), or at minimum execute `zsh -n`.

## Commit & Pull Request Guidelines
- Keep commit subjects short (≤50 chars) and imperative (e.g., `Add mise init script`); separate unrelated tweaks into different commits.
- Reference the affected tool or script in the body and mention any required follow-up commands (`./dotfiles`, `brew bundle`, `Lazy sync`).
