#!/bin/sh
# flasher installer: downloads the source, compiles it and installs the binary.
#   curl -fsSL https://raw.githubusercontent.com/JonasGoetz01/flasher/main/install.sh | sh
set -eu

REPO_RAW="https://raw.githubusercontent.com/JonasGoetz01/flasher/main"
INSTALL_DIR="${FLASHER_INSTALL_DIR:-$HOME/.local/bin}"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "flasher only supports macOS." >&2
    exit 1
fi

if ! command -v swiftc >/dev/null 2>&1; then
    echo "swiftc not found. Install the Xcode Command Line Tools first:" >&2
    echo "  xcode-select --install" >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading flasher..."
curl -fsSL "$REPO_RAW/flasher.swift" -o "$TMP/flasher.swift"

echo "Compiling..."
swiftc -O "$TMP/flasher.swift" -o "$TMP/flasher"

mkdir -p "$INSTALL_DIR"
mv "$TMP/flasher" "$INSTALL_DIR/flasher"
chmod +x "$INSTALL_DIR/flasher"

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
