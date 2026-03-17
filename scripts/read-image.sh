#!/usr/bin/env bash
# Lists the contents of a Kaypro IV CP/M disk image.
# Usage: read-image.sh <path-to-image>
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CPMLS="$REPO_DIR/tools/cpmtools/bin/cpmls"
DISKDEFS_DIR="$REPO_DIR/tools/cpmtools/share"

if [ ! -x "$CPMLS" ]; then
    echo "ERROR: cpmtools not found at $CPMLS"
    echo "Run 'make setup' first."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-image>"
    exit 1
fi

IMAGE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Image file not found: $IMAGE"
    exit 1
fi

# cpmtools looks for 'diskdefs' in the current directory first, so run from there
cd "$DISKDEFS_DIR"

"$CPMLS" -f kpiv -A "$IMAGE"
