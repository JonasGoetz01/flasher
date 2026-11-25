#!/bin/sh
# flasher installer: downloads the precompiled Apple Silicon binary.
#   curl -fsSL https://raw.githubusercontent.com/JonasGoetz01/flasher/main/install.sh | sh
set -eu

REPO_RAW="https://raw.githubusercontent.com/JonasGoetz01/flasher/main"
INSTALL_DIR="${FLASHER_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="$HOME/.local/share/flasher"
IMAGE="$DATA_DIR/flash.jpeg"

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
    echo "flasher only runs on Apple Silicon Macs." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading flasher..."
curl -fsSL "$REPO_RAW/bin/flasher" -o "$TMP/flasher"
curl -fsSL "$REPO_RAW/assets/flash.jpeg" -o "$TMP/flash.jpeg"
chmod +x "$TMP/flasher"
xattr -c "$TMP/flasher" 2>/dev/null || true

# stop a previously installed instance before replacing it
[ -x "$INSTALL_DIR/flasher" ] && "$INSTALL_DIR/flasher" --stop >/dev/null 2>&1 || true

mkdir -p "$INSTALL_DIR" "$DATA_DIR"
mv "$TMP/flasher" "$INSTALL_DIR/flasher"
mv "$TMP/flash.jpeg" "$IMAGE"

echo "Installed to $INSTALL_DIR/flasher"
"$INSTALL_DIR/flasher" "$IMAGE" --min 10 --max 60
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
