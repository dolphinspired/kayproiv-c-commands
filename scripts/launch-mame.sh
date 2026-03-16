#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAME="${MAME:-/usr/games/mame}"
IMAGE="$REPO_DIR/disk/kaypro4.img"
BUILD_IMAGE="$REPO_DIR/disk/build.img"

if [ ! -x "$MAME" ]; then
    echo "ERROR: MAME not found at $MAME"
    echo "Install with: sudo apt install mame"
    echo "Or set the MAME environment variable to its path."
    exit 1
fi

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Base disk image not found at $IMAGE"
    echo "See README.md for instructions on obtaining the Kaypro 4 CP/M boot image."
    exit 1
fi

if [ ! -f "$BUILD_IMAGE" ]; then
    echo "ERROR: Build image not found at $BUILD_IMAGE"
    echo "Run 'make image' to build it first."
    exit 1
fi

exec "$MAME" kayproiv -flop1 "$IMAGE" -flop2 "$BUILD_IMAGE"
