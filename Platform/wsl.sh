#!/bin/bash
set -e

# General WSL environment setup: Windows interop + development tools.
# Idempotent: safe to re-run.

INTEROP_CONF="/etc/binfmt.d/WSLInterop.conf"
INTEROP_LINE=":WSLInterop:M::MZ::/init:PF"

echo "=== Restoring WSL Windows interop ==="

echo "--- Ensuring $INTEROP_CONF exists ---"
if [ ! -f "$INTEROP_CONF" ]; then
    sudo mkdir -p "$(dirname "$INTEROP_CONF")"
    echo "$INTEROP_LINE" | sudo tee "$INTEROP_CONF" > /dev/null
    echo "Created $INTEROP_CONF"
else
    echo "$INTEROP_CONF already exists"
fi

echo "--- Unmasking and (re)starting systemd-binfmt.service ---"
# systemd-binfmt.service is a static unit (no [Install] section), so it cannot be
# "enabled" with systemctl — it already runs at boot once unmasked. Unmasking removes
# the /dev/null symlink that was suppressing it; restart applies WSLInterop.conf now.
sudo systemctl unmask systemd-binfmt.service
sudo systemctl restart systemd-binfmt.service

echo "--- Verifying handler registration ---"
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    echo "WSLInterop handler registered:"
    cat /proc/sys/fs/binfmt_misc/WSLInterop
else
    echo "WARNING: WSLInterop handler not registered yet."
    echo "Try 'wsl --shutdown' from Windows and reopen WSL."
fi

echo "=== Done ==="

# --- Development tools ---

echo ""
echo "=== Installing development tools ==="

if command -v clangd &>/dev/null; then
    echo "clangd already installed: $(clangd --version | head -1)"
else
    echo "--- Installing clangd ---"
    sudo apt-get install -y clangd
fi

echo "=== WSL setup complete ==="
