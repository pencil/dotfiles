# Repository Guidelines

## Project Structure & Module Organization
- Each non-hidden top-level directory is either a **GNU Stow package** or a source-only directory excluded by `./dotfiles`. Stow packages mirror the destination relative to `$HOME` — e.g. `zsh/.zshrc` → `~/.zshrc` and `starship/.config/starship.toml` → `~/.config/starship.toml`.
- `./dotfiles` stows every package while excluding `bootstrap.d/` and `templates/`. Adding an ordinary tool is just `mkdir <tool>/<path-under-$HOME>` and rerunning — no script edits.
- `bootstrap.d/agent-configs/claude-settings.json` and `bootstrap.d/agent-configs/codex-config.toml` are portable fragments. `bootstrap.d/agent-configs/agent-configs.sh` recursively merges them into regular local files under `$HOME`; tracked values win, arrays are replaced, and local-only keys survive. Keep Codex MCP servers in the local config.
- On a machine with no Homebrew, `bootstrap.d/linux-packages.sh` and `bootstrap.d/linux-user-tools.sh` install what `brew/.Brewfile` covers on macOS: the first takes the distro packages from apt plus `mise` from its own apt repo, the second drops `starship` and `uv` (and the `pre-commit` / `detect-secrets` CLIs `uv` installs) into `~/.local/bin`. Both are guarded, so macOS and non-apt distros fall through untouched. `stow` is the one tool they cannot provide — `./dotfiles` exits before any step runs without it, so it is always the one manual install.
- The repository-level `mise.toml` loads `~/.config/gh/dotfiles.env` only while this repository is active. That external dotenv file provides `GH_TOKEN` to GitHub tools.
- Each `*.zsh` file outside `templates/` is auto-sourced by `zsh/.zshrc`, which globs `$DOTFILES/**/*.zsh`. This is how tool-specific env vars, aliases, and PATH entries get loaded (e.g., `go/path.zsh`, `nvm/nvm.zsh`, `mise/mise.zsh`). `./dotfiles` passes `--ignore='\.zsh$'` to stow so these snippets don't get linked into `$HOME`.

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
| `claude/` | Claude Code guidance plus stowed hook/audio files (under `.claude/`) |
| `codex/` | Codex guidance plus stowed hook/notification files (under `.codex/`) |
| `bootstrap.d/` | Guarded machine setup scripts and their private data files; not stowed |
| `templates/` | Reusable source files shared by tool configs; not stowed or auto-sourced |
| `aider/` | Aider conf and conventions |
| `antidote/` | `.zsh_plugins.txt` for the zsh plugin manager |
| `mise/`, `nvm/`, `go/`, `java/`, `ruby/`, `aws/` | Runtime/CLI loaders; mostly `*.zsh` snippets (auto-sourced) |
| `ag/`, `ack/`, `ctags/` | Search/index tool configs |
| `macos/` | macOS system defaults script (`.macos`) |

## Build, Test, and Development Commands
- `./dotfiles` restows every package, then runs the executable setup steps under `bootstrap.d/`. It skips source-only directories and `*.zsh` snippets. The agent-config step merges its portable fragments into their local files without deleting keys that are absent from the fragments. Idempotent; safe to rerun.
- On Linux the bootstrap steps install system packages, so `./dotfiles` can prompt for a sudo password on a fresh machine. Once everything is present the steps make no apt calls at all.
- `./dotfiles --clean` is a one-shot migration aid: only needed the first time on a machine that still has symlinks from the previous (Ruby) script. After that, plain `./dotfiles` is all you need.
- `brew bundle --file=~/.Brewfile` installs or updates formulae, casks, and App Store apps; run `brew bundle cleanup --file=~/.Brewfile` before pruning.
- `nvim --headless "+Lazy sync" "+qa"` keeps Lua plugin declarations and the lock file aligned after editing `nvim/.config/nvim/`.
- `zsh -n path/to/file.zsh` quickly parses shell scripts for syntax errors before sourcing them in a login shell.

## Coding Style & Naming Conventions
- Favor lowercase directory names matching the target tool.
- Shell scripts and Zsh functions stay POSIX-friendly, indent with two spaces, and add descriptive comments only around non-obvious blocks.
- Lua files follow `stylua` (`nvim/.config/nvim/stylua.toml`), enforcing 2-space indentation and 120-character lines; run `stylua lua/**/*.lua` before committing.
- Commit changes by editing the real file (e.g. `brew/.Brewfile`) rather than the symlink in `$HOME`. For agent configs, edit the fragment under `bootstrap.d/agent-configs/` for portable values and the regular file under `$HOME` for machine-local values.
- New tool init scripts follow the guard pattern: check if the tool is installed, then source/eval (see `mise/mise.zsh`, `nvm/nvm.zsh`, `ruby/chruby.zsh`).

## Zsh Plugin Management (antidote)
- Plugins are listed in `antidote/.zsh_plugins.txt` (→ `~/.zsh_plugins.txt`) and loaded by `zsh/.zshrc` via antidote's static-bundle mode (`~/.zsh_plugins.zsh`).
- antidote itself comes from Homebrew where it exists; elsewhere `bootstrap.d/antidote.sh` clones it into `~/.antidote` at its own pinned SHA. Without it `zsh/.zshrc` loads no plugins at all and the keybindings in `zsh/options.zsh` fail.
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
