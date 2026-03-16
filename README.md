# Kaypro 4 C Development Toolchain

Write C programs, compile to CP/M `.COM` binaries, and deploy to a physical Kaypro 4 via floppy disk.

## Prerequisites

```bash
sudo apt install build-essential libncurses-dev libboost-dev git
```

You'll also need greaseweazle installed for floppy writing, and a CP/M 2.2 boot image (see `disk/README.md`).

## First-time setup

```bash
make setup
```

Clones and builds all tools (Z88DK, RunCPM, Z80Pack, cpmtools) into `tools/`. Z88DK takes 10–20 minutes.

## Workflow

## Programs

| Program | Description |
|---------|-------------|
| `HELLO.COM` | Prompts for your name and prints a greeting |
| `RAND.COM` | Generates a lucky number in a user-specified range. Seeds from keyboard-timing entropy XOR the Z80 R register. Run as `RAND` interactively, or `RAND <seed>` to specify a seed. |

**1. Write your program** in `src/`. See `src/hello.c` for an example.

**2. Compile:**
```bash
make
```
Produces `build/PROGNAME.COM` for each `src/progname.c`.

**3. Test in emulation:**
```bash
make test
```
Runs each program in RunCPM and diffs output against `test/cases/<progname>/expected.txt`.

For interactive testing, run RunCPM directly:
```bash
mkdir -p tools/runcpm-drive/A/0
cp build/HELLO.COM tools/runcpm-drive/A/0/
cd tools/runcpm-drive && ../runcpm/RunCPM
```

**4. Validate on accurate hardware emulation (optional):**
```bash
make launch-mame
```
Launches MAME with the Kaypro IV driver in a windowed 1120×480 display (2× integer scale of the native 560×240). Press **Alt+F4** to close.

```bash
make image
tools/z80pack/cpmsim/cpmsim -d disk/kaypro4.img
```

**5. Write to floppy:**
```bash
make image
gw write --drive A --format kaypro.800 disk/kaypro4.img
```

## Boot Image

`make image` requires a base CP/M 2.2 boot image. See `disk/README.md` for instructions.
