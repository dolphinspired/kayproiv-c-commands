# Kaypro 4 C Development Toolchain

## Context
Set up a local development pipeline for writing C programs that compile to CP/M .COM binaries and run on a Kaypro 4. The physical deployment path is: compile → test in emulator → create floppy disk image → write to floppy via greaseweazle. Need both fast-iteration testing (RunCPM) and hardware-accurate testing (Z80Pack with Kaypro IV disk definitions).

All tools install locally into `tools/` inside the repo — no global installs except unavoidable system build dependencies (gcc, make, libncurses-dev). A `scripts/setup.sh` script handles everything; `make setup` calls it.

No tools are currently installed. Both repos (`/home/developers/Repos/kaypro`, `/home/mochi/Repos/kaypro`) are empty.

---

## Toolchain Overview

| Tool | Role | Install location |
|---|---|---|
| Z88DK | C compiler → CP/M .COM (Kaypro 4 target) | `tools/z88dk/` |
| RunCPM | Fast CP/M emulator (folder-based drives, scriptable) | `tools/runcpm/` |
| Z80Pack | Kaypro IV-accurate emulator (disk images) | `tools/z80pack/` |
| cpmtools | Create/manipulate CP/M disk images | `tools/cpmtools/` |

System prerequisites (must be installed globally by user, documented in README):
`build-essential`, `libncurses-dev`, `libboost-dev` (for Z88DK), `git`

---

## Phase 0: Write Plan to Repo

Before any other work, write this plan to `plans/kaypro_v01.md` in the repo root. This is the canonical plan doc for future reference.

---

## Phase 1: Project Structure

```
kaypro/
├── src/                    # C source files
│   └── hello.c
├── build/                  # Compiled .COM files (gitignored)
├── test/
│   ├── run_tests.sh        # Automated test runner (RunCPM)
│   └── cases/              # Input/expected-output pairs
│       └── hello/
│           ├── input.txt
│           └── expected.txt
├── disk/                   # CP/M disk images (gitignored)
├── tools/                  # All local tool installs (gitignored)
│   ├── z88dk/
│   ├── runcpm/
│   ├── z80pack/
│   └── cpmtools/
├── scripts/
│   └── setup.sh            # One-time setup: clone + build all tools
├── Makefile                # Targets: setup, all, test, clean, image
├── README.md
└── plans/
    └── kaypro_v01.md
```

---

## Phase 2: scripts/setup.sh

Single script that installs all tools locally. Idempotent — skips steps already done.

```bash
#!/usr/bin/env bash
set -e
TOOLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/tools"
mkdir -p "$TOOLS_DIR"

# --- Z88DK ---
if [ ! -f "$TOOLS_DIR/z88dk/bin/zcc" ]; then
    echo "==> Building Z88DK..."
    git clone --recursive --depth=1 https://github.com/z88dk/z88dk.git "$TOOLS_DIR/z88dk"
    cd "$TOOLS_DIR/z88dk"
    ZCCCFG="$TOOLS_DIR/z88dk/lib/config" ./build.sh
    cd -
fi

# --- RunCPM ---
if [ ! -f "$TOOLS_DIR/runcpm/RunCPM" ]; then
    echo "==> Building RunCPM..."
    git clone --depth=1 https://github.com/MockbaTheBorg/RunCPM.git "$TOOLS_DIR/runcpm-src"
    cd "$TOOLS_DIR/runcpm-src/RunCPM"
    make -f Makefile.linux
    mkdir -p "$TOOLS_DIR/runcpm"
    cp RunCPM "$TOOLS_DIR/runcpm/"
    cd -
fi

# --- Z80Pack (cpmsim) ---
if [ ! -f "$TOOLS_DIR/z80pack/cpmsim/cpmsim" ]; then
    echo "==> Building Z80Pack..."
    git clone --depth=1 https://github.com/udo-munk/z80pack.git "$TOOLS_DIR/z80pack"
    cd "$TOOLS_DIR/z80pack/cpmsim/srcsim"
    make
    cd -
fi

# --- cpmtools ---
if [ ! -f "$TOOLS_DIR/cpmtools/bin/cpmcp" ]; then
    echo "==> Building cpmtools..."
    git clone --depth=1 https://github.com/lipro-cpm4l/cpmtools.git "$TOOLS_DIR/cpmtools-src"
    cd "$TOOLS_DIR/cpmtools-src"
    ./autogen.sh
    ./configure --prefix="$TOOLS_DIR/cpmtools"
    make && make install
    cd -
fi

echo "==> Setup complete."
```

---

## Phase 3: Makefile

```makefile
TOOLS    := tools
ZCC      := ZCCCFG=$(TOOLS)/z88dk/lib/config $(TOOLS)/z88dk/bin/zcc
RUNCPM   := $(TOOLS)/runcpm/RunCPM
CPMCP    := $(TOOLS)/cpmtools/bin/cpmcp

SRCS     := $(wildcard src/*.c)
TARGETS  := $(patsubst src/%.c,build/%.COM,$(SRCS))

.PHONY: all setup test clean image

setup:
	bash scripts/setup.sh

all: $(TARGETS)

build/%.COM: src/%.c | build
	$(ZCC) +kaypro -create-app -lndos -o $@ $<

build:
	mkdir -p build

test: all
	bash test/run_tests.sh

image: all
	bash scripts/make_image.sh

clean:
	rm -rf build/ disk/
```

Z88DK flags:
- `+kaypro`: Kaypro platform target (correct startup, ADM-3A terminal init)
- `-create-app`: produces .COM file
- `-lndos`: minimal CP/M I/O, smaller output

---

## Phase 4: Automated Testing (RunCPM)

RunCPM uses a folder hierarchy as CP/M drives: `A/0/` = drive A.
Tests work by copying a .COM into the drive folder, running RunCPM with a scripted command sequence, and diffing stdout against expected output.

```bash
#!/usr/bin/env bash
# test/run_tests.sh
set -e
RUNCPM="$(dirname "$0")/../tools/runcpm/RunCPM"
DRIVE_DIR="$(dirname "$0")/../tools/runcpm-drive"
PASS=0; FAIL=0

mkdir -p "$DRIVE_DIR/A/0"

for case_dir in "$(dirname "$0")"/cases/*/; do
    prog=$(basename "$case_dir")
    com_file="$(dirname "$0")/../build/${prog^^}.COM"

    cp "$com_file" "$DRIVE_DIR/A/0/"

    input="$case_dir/input.txt"
    expected="$case_dir/expected.txt"
    actual=$(cd "$DRIVE_DIR" && timeout 5 "$RUNCPM" < "$input" 2>/dev/null || true)

    if diff -q <(echo "$actual") "$expected" > /dev/null 2>&1; then
        echo "PASS: $prog"; ((PASS++))
    else
        echo "FAIL: $prog (diff below):"
        diff <(echo "$actual") "$expected" || true
        ((FAIL++))
    fi
done
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

Note: RunCPM stdin automation may require `expect` for interactive programs — investigate during implementation and adjust if needed.

---

## Phase 5: Z80Pack Validation

Before writing to floppy, boot a Kaypro IV disk image in Z80Pack for hardware-accurate verification.

```bash
# scripts/make_image.sh — create a bootable Kaypro 4 disk image with all .COM files
CPMCP="tools/cpmtools/bin/cpmcp"
IMAGE="disk/kaypro4.img"

cp disk/kaypro4.img "$IMAGE"   # base image with CP/M 2.2 BIOS
for f in build/*.COM; do
    "$CPMCP" -f kaypro4 "$IMAGE" "$f" "0:$(basename $f)"
done

echo "Image ready: $IMAGE"
echo "Launch Z80Pack: tools/z80pack/cpmsim/cpmsim -d $IMAGE"
```

The base boot image (`disk/kaypro4.img`) must be sourced from Archive.org (kaypro-disk-cpm-2.2-and-s-basic) — not included in repo, documented in README.

---

## Phase 6: Floppy Deployment

```bash
# Write finished image to physical 5.25" DSDD floppy via greaseweazle
gw write --drive A --format kaypro.800 disk/kaypro4.img
```
Kaypro 4 format: 5.25" DSDD, 800KB. Verify greaseweazle format string during implementation.

---

## Example First Program (src/hello.c)

```c
#include <stdio.h>

int main(void) {
    char name[32];
    printf("Enter your name: ");
    fgets(name, sizeof(name), stdin);
    printf("Hello, %s!\n", name);
    return 0;
}
```

---

## Verification Checklist

- [ ] `make setup` runs to completion without errors
- [ ] `make` compiles `src/hello.c` → `build/HELLO.COM`
- [ ] `HELLO.COM` runs correctly in RunCPM (interactive)
- [ ] `make test` passes automated test for hello world
- [ ] `make image` creates a bootable Kaypro 4 disk image
- [ ] Image boots and program runs correctly in Z80Pack
- [ ] README covers: prerequisites, `make setup`, `make`, `make test`, deploy steps

---

## Open Questions / Risks

- RunCPM stdin automation: interactive programs may need `expect` for interactive programs — investigate during impl.
- Z80Pack Kaypro IV BIOS ROM: need to confirm a legal source for boot image (Archive.org has it). Boot image is not committed to repo; README must document how to obtain it.
- Z88DK build time is significant (~10-20 min). `setup.sh` must be idempotent so reruns are fast.
- cpmtools `diskdefs` file: `kaypro4` format may not be in the default diskdefs; may need to add a custom entry. Kaypro 4 format: 80 tracks, 10 sectors/track, 512 bytes/sector, 2 sides.
- greaseweazle format string for Kaypro 4 needs verification when doing physical deployment.
