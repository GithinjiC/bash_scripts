#!/bin/bash
set -euo pipefail

# Prompt for sudo password upfront and cache credentials.
# -v validates/refreshes the cached credentials, prompting if needed.
echo "This script requires sudo privileges. You may be prompted for your password."
if ! sudo -v; then
    echo "Failed to obtain sudo privileges. Exiting." >&2
    exit 1
fi

# Keep sudo credentials alive in the background for the duration of the script.
# This refreshes the timestamp every 60 seconds so long-running scripts
# don't re-prompt midway through.
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done
) &
SUDO_KEEPALIVE_PID=$!

# Make sure we kill the keepalive when the script exits, for any reason.
cleanup() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}
trap cleanup EXIT

# --- Your actual script work below ---

echo "Updating package lists..."
sudo apt-get update

echo "Installing packages..."
sudo apt-get install -y curl jq

echo "Restarting a service..."
sudo systemctl restart nginx

echo "Done."
