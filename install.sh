#!/bin/sh
# flasher installer: downloads the precompiled Apple Silicon binary.
#   curl -fsSL https://raw.githubusercontent.com/JonasGoetz01/flasher/main/install.sh | sh
set -eu

BIN_URL="https://raw.githubusercontent.com/JonasGoetz01/flasher/main/bin/flasher"
INSTALL_DIR="${FLASHER_INSTALL_DIR:-$HOME/.local/bin}"

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
    echo "flasher only runs on Apple Silicon Macs." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading flasher..."
curl -fsSL "$BIN_URL" -o "$TMP/flasher"
chmod +x "$TMP/flasher"
xattr -c "$TMP/flasher" 2>/dev/null || true

mkdir -p "$INSTALL_DIR"
mv "$TMP/flasher" "$INSTALL_DIR/flasher"

echo "Installed to $INSTALL_DIR/flasher"
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo
        echo "Note: $INSTALL_DIR is not in your PATH. Add it with:"
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
        ;;
esac
echo
echo "Usage:      flasher <image-or-folder> [--min SEC] [--max SEC] [--duration MS]"
echo "Stop:       flasher --stop"
echo "Uninstall:  flasher --uninstall"
