# flasher

A tiny macOS tool that runs in the background and, at random intervals, flashes an image full screen for a split second.

- Covers every display, including fullscreen apps and all Spaces
- No Dock icon, never steals focus, clicks pass through
- Point it at a single image or a folder (picks a random image each flash)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/JonasGoetz01/flasher/main/install.sh | sh
```

Requires macOS and the Xcode Command Line Tools (`xcode-select --install`). Installs to `~/.local/bin` (override with `FLASHER_INSTALL_DIR=/some/dir`).

## Usage

```sh
flasher ~/Pictures/pic.jpg                    # one image
flasher ~/Pictures/flashes/                   # random image from a folder
flasher pic.png --min 30 --max 300 --duration 100
flasher --stop                                # stop the background instance
```

| Option | Default | Meaning |
|---|---|---|
| `--min SEC` | 60 | shortest pause between flashes |
| `--max SEC` | 600 | longest pause between flashes |
| `--duration MS` | 150 | how long the image stays visible |
| `--foreground` | – | don't detach; run in the terminal (Ctrl-C to quit) |

Supported formats: png, jpg, gif, heic, tiff, bmp, webp.

## Uninstall

```sh
flasher --uninstall
```

Stops any running instance and deletes the binary.

## Build from source

```sh
swiftc -O flasher.swift -o flasher
```
