#!/usr/bin/env bash
# Creates a bootable Kaypro 4 disk image containing all compiled .COM files.
# Requires disk/kaypro4.img — see README for how to obtain it.
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CPMCP="$REPO_DIR/tools/cpmtools/bin/cpmcp"
IMAGE="$REPO_DIR/disk/kaypro4.img"
BASE_IMAGE="$REPO_DIR/disk/kaypro4.img"

if [ ! -f "$BASE_IMAGE" ]; then
    echo "ERROR: Base boot image not found at $BASE_IMAGE"
    echo "See README.md for instructions on obtaining the Kaypro 4 CP/M boot image."
    exit 1
fi

mkdir -p "$REPO_DIR/disk"
cp "$BASE_IMAGE" "$IMAGE"

for f in "$REPO_DIR"/build/*.COM; do
    [ -f "$f" ] || continue
    echo "  Adding $(basename "$f")..."
    "$CPMCP" -f kaypro4 "$IMAGE" "$f" "0:$(basename "$f")"
done

echo "Image ready: $IMAGE"
echo "To validate in Z80Pack: tools/z80pack/cpmsim/cpmsim -d $IMAGE"
echo "To write to floppy:     gw write --drive A --format kaypro.800 $IMAGE"
