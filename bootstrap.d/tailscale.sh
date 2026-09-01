#!/usr/bin/env bash
# Install Tailscale on Linux via the vendor installer, which adds the APT/RPM
# repo for the running distro and enables tailscaled. macOS gets the
# tailscale-app cask from brew/.Brewfile instead, so this step is a no-op there.
# The installer needs root, so a fresh machine may prompt for a sudo password.
set -euo pipefail

[[ "$(uname -s)" == "Linux" ]] || exit 0
command -v tailscale >/dev/null && exit 0

curl -fsSL https://tailscale.com/install.sh | sh
echo "Tailscale installed — run \`sudo tailscale up\` to join the tailnet."
