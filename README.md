# dotfiles

My personal dotfiles, targeted towards macOS and Linux.

Some inspiration drawn by holman's dotfiles.

## Setup

Run `./dotfiles` to restow every package into `$HOME` and execute the guarded
setup steps under `bootstrap.d/`.

The repository-level `mise.toml` loads `~/.config/gh/dotfiles.env` only while
working in this repository. That dotenv file provides `GH_TOKEN` to GitHub tools.

## Scarlett microphone

`bootstrap.d/scarlett-mic/` builds a small menu bar agent that copies Input 1 of
the Focusrite Scarlett Solo into VB-Cable, so apps that would otherwise mix in
the interface's Loopback channels get a clean microphone. `./dotfiles` compiles
it into `~/.local/bin` with the Swift toolchain, renders its launchd plist into
`~/Library/LaunchAgents`, and keeps it running. It signs the binary with an
Apple Development certificate when the keychain has one, so macOS keeps the
microphone permission across rebuilds. Without one, macOS asks again after each
code change, and the agent has no audio until you answer. The menu bar icon shows the
state and can pause forwarding. The Swift file's header explains the design and
the one-line check. The step is skipped on Linux and on Macs without `swiftc`.

## Agent configs

`bootstrap.d/agent-configs/claude-settings.json` and
`bootstrap.d/agent-configs/codex-config.toml` are portable fragments rather than
symlink targets. `./dotfiles` recursively merges them into the regular files at
`~/.claude/settings.json` and `~/.codex/config.toml`.
Fragment values take precedence, including whole arrays; keys that exist only in
the local files are preserved for machine-specific and application-managed
state. Codex MCP servers belong only in the local config.

Removing a key from a fragment stops managing it but does not remove its last
value from machines where it was already applied. Delete that value from the
local config explicitly when it should disappear from a particular machine.
The TOML merge normalizes `~/.codex/config.toml` when its content changes, so
keep durable comments in the repository documentation rather than that file.
