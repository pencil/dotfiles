# dotfiles

My personal dotfiles, targeted towards macOS and Linux.

Some inspiration drawn by holman's dotfiles.

## Setup

Run `./dotfiles` to restow every package into `$HOME` and execute the guarded
setup steps under `bootstrap.d/`.

The repository-level `mise.toml` loads `~/.config/gh/dotfiles.env` only while
working in this repository. That dotenv file provides `GH_TOKEN` to GitHub tools.

## Agent configs

`claude/.claude/settings.json` and `codex/.codex/config.toml` are portable
fragments rather than symlink targets. `./dotfiles` recursively merges them into
the regular files at `~/.claude/settings.json` and `~/.codex/config.toml`.
Fragment values take precedence, including whole arrays; keys that exist only in
the local files are preserved for machine-specific and application-managed
state. Codex MCP servers belong only in the local config.

Removing a key from a fragment stops managing it but does not remove its last
value from machines where it was already applied. Delete that value from the
local config explicitly when it should disappear from a particular machine.
The TOML merge normalizes `~/.codex/config.toml` when its content changes, so
keep durable comments in the repository documentation rather than that file.
