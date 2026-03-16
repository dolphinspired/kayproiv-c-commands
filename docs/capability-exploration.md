# Kaypro 4 Capability Exploration

Programs for learning the Kaypro 4's capabilities via Z88DK C on CP/M 2.2.

---

## Platform Constraints (Know Before You Code)

| Constraint | Detail |
|---|---|
| CPU | Zilog Z80, 8-bit with 16-bit register pairs |
| RAM | ~56 KB Transient Program Area (TPA) in a stock 64 KB machine |
| `int` | 16-bit, range −32,768 to 32,767 |
| `long` | 32-bit, software-emulated (slower) |
| `float` | Software float — works, but noticeably slow |
| Console | 80×25 text, VT52-compatible escape codes |
| Graphics | 160×100 pseudo-pixels via 2×4 BIOS block characters |
| No RTC | No real-time clock; can't seed RNG from time |
| Filenames | CP/M 8.3 format — e.g. `IMAGE.BIN`, not `my_image_file.bin` |

Graphics (`#include <graphics.h>`, link with `-lgfxkp`) are **not true bitmap** — they use BIOS escape sequences to plot each "pixel" as one of four sub-cells in a 2×4 block character. This makes full-screen plots slow but very workable for line art, shapes, and sparse pixel art. Call `clg()` to initialize/clear the graphics screen, then use `plot(x, y)`, `draw(x1, y1, x2, y2)`, `circle(cx, cy, r, 0)`, etc.

---

## Programs You Proposed

### 1. Calculator (`CALC.COM`)
**Capabilities demonstrated:** integer arithmetic, input parsing, loop/menu structure, `int` vs `long` overflow

A REPL-style calculator: prompt for `expression`, print result, repeat. Suggested features:
- Operators: `+  -  *  /  %`
- Operands are integers (use `long` to get 32-bit range and avoid surprising overflow)
- Division-by-zero guard
- `Q` to quit

**Key learning moments:**
- `long` multiply/divide is software-emulated — you'll notice it in code size
- `scanf` on CP/M works fine but input is line-buffered (no raw keystrokes without BIOS calls)
- `%ld` format specifier for `long`; `%d` for `int`

**Stretch:** add a simple expression parser (no operator precedence — just left-to-right evaluation of `A op B op C ...`). That gets you into string tokenization, which is educational on its own.

---

### 2. Random Number Generator (`RAND.COM`)
**Capabilities demonstrated:** pseudo-random algorithms, integer arithmetic, 16-bit overflow as a feature

The Z80 has no hardware RNG. Use a **Linear Congruential Generator (LCG)**:
```
state = state * 1103515245 + 12345   (mod 2^32)
result = (state >> 16) & 0x7FFF      (upper 15 bits)
```

Because `long` is 32-bit and LCG multiplications happily overflow, this works naturally. Seed from **user input** (ask the user to type a number, or to mash keys — count keystrokes before Enter).

**Key learning moments:**
- Pseudo-random: same seed = same sequence. Determinism is a feature for testing.
- Upper bits of an LCG are much better quality than lower bits — the `>> 16` is important
- On an 8-bit machine, 32-bit multiply is several instructions; you'll see the .COM size grow

**Program interface:** `RAND min max count` — print `count` random integers in `[min, max]`. Good as a command-line utility with `argc`/`argv`.

---

### 3. Image Viewer (`IMGVIEW.COM`)
**Capabilities demonstrated:** file I/O, graphics library, binary data formats, CP/M limitations

The Kaypro 4 graphics canvas is 160×100 pixels. A full-screen image is 160×100 = 16,000 pixels = **2,000 bytes** when 1 bit per pixel, packed 8 pixels per byte (row-major, left-to-right).

**File format (suggested):**
```
Bytes 0-1:   width  (little-endian int, max 160)
Bytes 2-3:   height (little-endian int, max 100)
Bytes 4+:    pixel rows, 1 bit per pixel, packed MSB-first
```

**On the host (before running on Kaypro):**
Write a Python script `scripts/img2kp.py` that uses Pillow to convert a PNG → threshold → pack → write this binary format. Then copy the `.BIN` file into the RunCPM drive directory alongside the `.COM`.

**On the Kaypro:**
```c
clg();
fread(row_buf, 1, row_bytes, f);
for each row: unpack bits, call plot(x, y) for set pixels
```

**Important caveat:** Each `plot(x, y)` call goes through a BIOS escape sequence. Plotting all 16,000 pixels will be slow — probably 5–10 seconds on real hardware, much faster in RunCPM. This is worth experiencing: it teaches why 1980s games used direct memory-mapped video instead of terminal I/O.

---

## Additional Ideas

### 4. Mandelbrot Fractal (`MANDEL.COM`)
**Capabilities demonstrated:** fixed-point math, nested loops, graphics library depth

The classic fractal. Floating point is too slow on a Z80 — use **16-bit fixed-point** (Q8.8 or Q4.12 format): multiply two 16-bit values, shift right 8 to keep the decimal. Maps the 160×100 canvas to the complex plane. Even with fixed-point this will take a minute or two to render, which is authentic to the era.

Z88DK's `tools/z88dk/examples/graphics/mandel.c` has a reference implementation for other targets — it's a useful starting point to understand the fixed-point approach before adapting it.

---

### 5. Conway's Game of Life (`LIFE.COM`)
**Capabilities demonstrated:** 2D array manipulation, text-mode display, frame-by-frame animation

Run on the 80×24 character grid (one row reserved for status). Each cell is 1 byte (`0` or `1`). Use two alternating buffers to avoid in-place mutation. Press any key to step one generation; `Q` to quit.

**Key learning moments:**
- 80×24 = 1,920 cells, two buffers = 3,840 bytes — trivial in the TPA
- Screen redraw via `printf` with cursor-home escape (`\x1b[H` or VT52 `\x1bH`) is fast enough for text-mode
- Boundary wrap (toroidal grid) vs. dead edges — pick one

Not easily automatable in RunCPM (needs raw input), but works great in Z80Pack or on real hardware.

---

### 6. CP/M System Info (`SYSINFO.COM`)
**Capabilities demonstrated:** CP/M BDOS API, `bdos()` / `bios()` calls, disk parameter block

Print a snapshot of the system:
- Current drive and user area (`bdos(CPM_IDRV, 0)`, `bdos(CPM_SUID, 0xFF)`)
- CP/M version number (`bdos(CPM_VERS, 0)`)
- Disk Parameter Block for drive A: sectors/track, block size, directory capacity, total capacity

All of these come from `<cpm.h>` — no assembly required. This is a great first "non-hello-world" program because it forces you to read the CP/M BDOS spec to understand what you're querying.

---

### 7. Sine Wave / Lissajous Plotter (`LISSAJOUS.COM`)
**Capabilities demonstrated:** fixed-point trig, graphics library, iteration

Z88DK includes `<math.h>` with `sin()` / `cos()` as software floats. On a Z80 these are slow but usable for pre-computing a table. Plot a Lissajous figure by sampling:
```
x = A * sin(a * t + delta)
y = B * cos(b * t)
```
scaled to the 160×100 canvas. Varying `a`, `b`, and `delta` produces wildly different patterns.

Because the image is static (draw-and-wait), the render time is acceptable. Good companion to the Mandelbrot for showing off what the graphics library can actually do.

---

### 8. Hex Dump Utility (`HEXDUMP.COM`)
**Capabilities demonstrated:** file I/O, binary data, CP/M 8.3 filename constraints, formatted output

`HEXDUMP filename.ext` reads any file and prints 16 bytes per row: hex values on the left, printable ASCII on the right (dots for non-printable). Dead-simple to implement, immediately useful for inspecting your own image files and checking binary formats.

**Key learning moments:**
- `argv[1]` in CP/M — filenames come in uppercase, 8.3 format
- Reading in chunks with `fread` and handling partial last-block
- `isprint()` from `<ctype.h>` works fine on CP/M

---

## Recommended Build Order

1. **HEXDUMP** — No graphics, pure I/O. Good warm-up and immediately useful.
2. **CALC** — Pure arithmetic/IO. Tests your CP/M `scanf`/`printf` confidence.
3. **RAND** — Introduces `long` math and `argc`/`argv`.
4. **SYSINFO** — First real BDOS interaction; teaches you to read the CP/M manual.
5. **LIFE** — First text-mode "animation". Builds 2D array confidence.
6. **IMGVIEW** — First use of graphics lib + file I/O together. Needs the Python converter script first.
7. **LISSAJOUS / MANDEL** — Graphics lib push-to-the-limit programs. Best saved for last.
