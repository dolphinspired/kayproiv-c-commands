# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make setup      # First-time setup: clone and build all tools into tools/ (~10-20 min for Z88DK)
make            # Compile all src/*.c → build/*.COM
make test       # Compile then run automated tests via RunCPM
make image      # Compile then bundle .COM files into disk/kaypro4.img
make clean      # Delete build/ and disk/
```

To compile a single file manually:
```bash
ZCCCFG=tools/z88dk/lib/config tools/z88dk/bin/zcc +kaypro -create-app -lndos -o build/FOO.COM src/foo.c
```

To run a program interactively in RunCPM:
```bash
mkdir -p tools/runcpm-drive/A/0
cp build/FOO.COM tools/runcpm-drive/A/0/
cd tools/runcpm-drive && ../runcpm/RunCPM
```

## Architecture

The pipeline has four stages: **compile → emulate (fast) → emulate (accurate) → deploy**.

**Compile** (`src/` → `build/`): Z88DK's `zcc` with `+kaypro` targets the Kaypro 4 specifically — it links the correct startup code and ADM-3A terminal init. `-lndos` uses a minimal CP/M I/O library. Output filenames must be uppercase `.COM` (CP/M convention); the Makefile handles this via the pattern rule.

**Fast emulation** (RunCPM): Treats a directory tree as CP/M drives — `tools/runcpm-drive/A/0/` maps to drive A. The test runner in `test/run_tests.sh` automates this by feeding stdin to RunCPM (program name from `input.txt` then `^C` to quit). RunCPM is an interactive shell, not a single-program launcher, so output includes a banner and prompt that the test runner strips with `sed` before diffing against `expected.txt`.

**Accurate emulation** (Z80Pack): Boots from an actual Kaypro IV disk image. Requires `disk/kaypro4.img` sourced from Archive.org (not in repo) — `scripts/make_image.sh` copies it and adds `.COM` files via cpmtools.

**Deploy** (greaseweazle): `gw write --drive A --format kaypro.800 disk/kaypro4.img` — format string may need verification against installed gw version.

## Adding a Test Case

Create `test/cases/<progname>/` with two files:
- `input.txt` — first line is the CP/M command to run (e.g. `HELLO`), subsequent lines are stdin to the program
- `expected.txt` — expected stdout (after RunCPM banner/prompt are stripped)

The test runner upcases the directory name to find the matching `.COM` in `build/`.

## Known Gotchas

- **cpmtools diskdefs**: `kaypro4` may not be in the default diskdefs file. If `cpmcp` fails, add this entry to `tools/cpmtools/share/cpmtools/diskdefs`:
  ```
  diskdef kaypro4
    seclen 512
    tracks 80
    sectrk 10
    heads 2
    blocksize 2048
    maxdir 64
    skew 0
    boottrk 2
    os 2.2
  end
  ```
- **RunCPM test automation**: Works for programs that read from stdin normally. Raw terminal / curses programs will not work with this approach and need an `expect` script.
- **Z88DK `ZCCCFG`**: Must be set to `tools/z88dk/lib/config` at both build time (setup.sh) and compile time (Makefile). Without it, zcc cannot find its configuration.
- **`tools/` is gitignored**: Running `make setup` on a fresh clone rebuilds everything from source.
