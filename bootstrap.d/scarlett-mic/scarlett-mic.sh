#!/usr/bin/env bash
# Builds scarlett-mic (see scarlett-mic.swift for what it does and why) into
# ~/.local/bin and keeps it running as a launchd agent. The plist is rendered
# from the template next to this script rather than stowed, because launchd
# needs absolute paths and the home directory differs between machines.
#
# Skipped on Linux and on Macs without a Swift toolchain (Xcode or Command Line
# Tools). Rebuilds only when the source is newer than the binary, and restarts
# the agent only when the binary or the plist changed.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0
xcrun -f swiftc >/dev/null 2>&1 || exit 0

here=bootstrap.d/scarlett-mic
label=com.local.scarlett-mic
bin=$HOME/.local/bin/scarlett-mic
plist=$HOME/Library/LaunchAgents/$label.plist
domain=gui/$(id -u)

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

changed=0
if [[ ! -x "$bin" || "$here/scarlett-mic.swift" -nt "$bin" ]]; then
  # Build beside the target and move into place so a running agent keeps its
  # old inode until launchd restarts it below.
  xcrun swiftc -O -framework CoreAudio -framework AppKit -o "$bin.tmp" "$here/scarlett-mic.swift"
  mv -f "$bin.tmp" "$bin"
  echo "Built $bin"
  changed=1
fi

rendered=$(sed "s|__HOME__|$HOME|g" "$here/$label.plist")
if [[ ! -f "$plist" || "$rendered" != "$(cat "$plist")" ]]; then
  printf '%s\n' "$rendered" > "$plist"
  echo "Wrote $plist"
  changed=1
fi

if (( changed )) || ! launchctl print "$domain/$label" >/dev/null 2>&1; then
  launchctl bootout "$domain/$label" 2>/dev/null || true
  launchctl bootstrap "$domain" "$plist"
  echo "Loaded $label"
fi
