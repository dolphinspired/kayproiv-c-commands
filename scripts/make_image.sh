#!/usr/bin/env bash
# Creates disk/build.img — a blank Kaypro 4 CP/M disk containing all compiled
# .COM files. Intended for use as drive B alongside the base kaypro4.img.
# Requires disk/kaypro4.img to exist — see README for how to obtain it.
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MKFS="$REPO_DIR/tools/cpmtools/bin/mkfs.cpm"
CPMCP="$REPO_DIR/tools/cpmtools/bin/cpmcp"
DISKDEFS_DIR="$REPO_DIR/tools/cpmtools/share"
BASE_IMAGE="$REPO_DIR/disk/kaypro4.img"
BUILD_IMAGE="$REPO_DIR/disk/build.img"

# 80 tracks × 2 heads × 10 sectors × 512 bytes = 819200 bytes
DISK_SIZE=819200

if [ ! -f "$BASE_IMAGE" ]; then
    echo "ERROR: Base boot image not found at $BASE_IMAGE"
    echo "See README.md for instructions on obtaining the Kaypro 4 CP/M boot image."
    exit 1
fi

mkdir -p "$REPO_DIR/disk"

# cpmtools looks for 'diskdefs' in the current directory first, so run from there
cd "$DISKDEFS_DIR"

# Create a blank disk image and format it as kaypro4
dd if=/dev/zero of="$BUILD_IMAGE" bs=1 count=0 seek=$DISK_SIZE 2>/dev/null
"$MKFS" -f kaypro4 "$BUILD_IMAGE"

for f in "$REPO_DIR"/build/*.COM; do
    [ -f "$f" ] || continue
    echo "  Adding $(basename "$f")..."
    "$CPMCP" -f kaypro4 "$BUILD_IMAGE" "$f" "0:$(basename "$f")"
done

echo "Build image ready: $BUILD_IMAGE"
echo "To write to floppy: gw write --drive B --format kaypro.800 $BUILD_IMAGE"
