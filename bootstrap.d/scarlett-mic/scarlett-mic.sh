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

# Bootstrap a fresh instance. bootout is asynchronous, so wait for any prior
# instance to leave the domain first; even then bootstrap can briefly return
# EIO (5) during teardown, so retry. Without this the agent ends up unloaded
# and the microphone goes silent.
bootstrap_agent() {
  local i
  for i in $(seq 1 50); do
    launchctl print "$domain/$label" >/dev/null 2>&1 || break
    sleep 0.1
  done
  for i in $(seq 1 25); do
    launchctl bootstrap "$domain" "$plist" 2>/dev/null && return 0
    sleep 0.2
  done
  echo "Failed to load $label" >&2
  return 1
}

binChanged=0
if [[ ! -x "$bin" || "$here/scarlett-mic.swift" -nt "$bin" ]]; then
  # Build beside the target and move into place so a running agent keeps its
  # old inode until it is restarted below.
  xcrun swiftc -O -framework CoreAudio -framework AppKit -o "$bin.tmp" "$here/scarlett-mic.swift"
  # macOS ties the microphone permission to the code signature, and the agent's
  # audio waits until the permission dialog is answered. An ad-hoc signature
  # changes with every build, so each rebuild would ask again; a development
  # certificate keeps one identity across rebuilds. Without one, stay ad-hoc.
  identity=$(security find-identity -v -p codesigning 2>/dev/null | awk '/"Apple Development:/ {print $2; exit}')
  codesign --force --identifier "$label" --sign "${identity:--}" "$bin.tmp" 2>/dev/null ||
    codesign --force --identifier "$label" --sign - "$bin.tmp"
  mv -f "$bin.tmp" "$bin"
  echo "Built $bin"
  binChanged=1
fi

plistChanged=0
rendered=$(sed "s|__HOME__|$HOME|g" "$here/$label.plist")
if [[ ! -f "$plist" || "$rendered" != "$(cat "$plist")" ]]; then
  printf '%s\n' "$rendered" > "$plist"
  echo "Wrote $plist"
  plistChanged=1
fi

if ! launchctl print "$domain/$label" >/dev/null 2>&1; then
  bootstrap_agent && echo "Loaded $label"
elif (( plistChanged )); then
  # The service definition changed, so it must be replaced.
  launchctl bootout "$domain/$label" 2>/dev/null || true
  bootstrap_agent && echo "Reloaded $label"
elif (( binChanged )); then
  # Only the binary changed. kickstart relaunches the program from disk in
  # place, with none of the bootout/bootstrap teardown race.
  launchctl kickstart -k "$domain/$label"
  echo "Restarted $label"
fi
