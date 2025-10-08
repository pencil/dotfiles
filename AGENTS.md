# Repository Guidelines

## Project Structure & Module Organization
- Root directories map to individual tools (`zsh`, `vim`, `tmux`, `system`) and contain `.symlink`/`.dsymlink` assets that the repo links into `$HOME`.
- `config/nvim.dsymlink/` houses the Neovim LazyVim setup, with Lua modules under `lua/`, plugin locks in `lazy-lock.json`, and formatting rules in `stylua.toml`.
- `brew/Brewfile.symlink` defines Homebrew, cask, and MAS dependencies; source `brew/brew.zsh` after Homebrew installs.
- The Ruby `./dotfiles` script is the entry point for refreshing symlinks and creating parent directories where needed.

## Build, Test, and Development Commands
- `./dotfiles` regenerates dotfile symlinks in `$HOME` and should be rerun after adding or renaming any `*.symlink` assets.
- `brew bundle --file=brew/Brewfile.symlink` installs or updates formulae, casks, and App Store apps; run `brew bundle cleanup --file=brew/Brewfile.symlink` before pruning.
- `nvim --headless "+Lazy sync" "+qa"` ensures Lua plugin declarations and the lock file stay aligned after editing `config/nvim.dsymlink`.
- `zsh -n path/to/file.zsh` quickly parses shell scripts for syntax errors before sourcing them in a login shell.

## Coding Style & Naming Conventions
- Favor lowercase directory names matching the target tool; use `.symlink` for files that become dotfiles and `.dsymlink` for directories that should land under `$HOME/.<dir>`.
- Shell scripts and Zsh functions stay POSIX-friendly, indent with two spaces, and add descriptive comments only around non-obvious blocks.
- Lua files follow `stylua` (`config/nvim.dsymlink/stylua.toml`), enforcing 2-space indentation and 120-character lines; run `stylua lua/**/*.lua` before committing.
- Commit new dependencies by editing the relevant `*.symlink` file (e.g., `brew/Brewfile.symlink`) rather than the generated file in `$HOME`.

## Testing Guidelines
- No automated test suite exists; validate manually by spawning a fresh shell (`zsh -l`) and opening Neovim to confirm configs load without warnings.
- Run `nvim --headless "+checkhealth" "+qa"` whenever plugins or LSP settings change.
- For shell utilities, lint with `shellcheck` when available (`shellcheck zsh/aliases.zsh`), or at minimum execute `zsh -n`.

## Commit & Pull Request Guidelines
- Keep commit subjects short (≤50 chars) and imperative (e.g., `Make shift+enter work in Codex`); separate unrelated tweaks into different commits.
- Reference the affected tool or script in the body (e.g., “Update `brew/Brewfile` for tmux 3.4”) and mention any required follow-up commands.
- Pull requests should include a summary of impacted areas, manual verification steps taken (`./dotfiles`, `brew bundle`, `Lazy sync`), and screenshots when UI themes change.
- Link issues or upstream changelogs when importing updates and note any post-merge actions.
