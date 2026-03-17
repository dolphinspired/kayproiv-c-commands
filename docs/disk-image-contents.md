# Kaypro Disk Image Contents

Listed via `scripts/read-image.sh` using cpmtools format `kpiv`.

---

## `usr-bin/kayproiv.img` — Kaypro IV Boot Disk

Used as the MAME boot image. Complete CP/M 2.2 system disk.

### User Area 0 — System & Utilities

| File | Description |
|---|---|
| `asm.com` | 8080 macro assembler (CP/M standard transient) |
| `basiclib.rel` | Relocatable BASIC library object |
| `config.com` | Kaypro CONFIG utility — reconfigure IOBYTE, keyboard, baud rate without reboot |
| `copy.com` | File copy utility (Kaypro-supplied, distinct from PIP) |
| `d.com` | Likely a compact directory lister |
| `ddt.com` | Dynamic Debugging Tool — CP/M's built-in machine-level debugger |
| `dgen.cmd` | Disk generator command file (likely drives `dgen.ovl`) |
| `dgen.ovl` | Overlay for disk generator utility |
| `dplay.bas` | BASIC program (purpose unknown) |
| `dump.asm` | Assembler source for the DUMP utility |
| `dump.com` | Hex dump of a file to console |
| `ed.com` | ED context text editor (CP/M standard transient) |
| `fac.bas` | BASIC program (purpose unknown) |
| `kslnews.par` | Parameter/configuration file (likely for a news or comms program) |
| `load.com` | Loads an Intel hex file and produces a `.COM` executable |
| `mfdisk.com` | Disk utility — **leaves residual state; hardware reset required after use** |
| `movcpm.com` | Relocates CP/M to a different memory size (used when configuring RAM) |
| `overlayb.com` | Overlay B — exact purpose unknown |
| `pip.com` | Peripheral Interchange Program — general-purpose file/device copy |
| `sbasic.com` | SuperBASIC interpreter |
| `sscopy.com` | Likely a screen or sector copy utility |
| `stat.com` | Show disk/file status and free space |
| `submit.com` | SUBMIT batch command processor |
| `sysgen.com` | Creates a bootable CP/M diskette |
| `userlib.rel` | Relocatable user library object |
| `xamn.bas` | BASIC program (purpose unknown) |
| `xsub.com` | Extended SUBMIT (resident command input buffer) — **leaves residual state; hardware reset required after use** |

### User Area 5 — Partition Tools (BASIC)

| File | Description |
|---|---|
| `partdefs.bas` | Likely defines partition structures or constants |
| `partlist.bas` | Likely lists partition information |
| `pcreate.bas` | Likely creates partitions |

These three BASIC programs appear to be a related suite for disk partitioning. Purpose and
compatibility with the Kaypro IV (vs 4/84) is unverified.

---

## `usr-bin/kayprocpm2.ima` — Unknown Kaypro Variant Disk

Origin and intended machine are unverified. Filename suggests CP/M 2 or Kaypro II.
No user area 5. Shares most files with `kayproiv.img` but has notable differences.

### User Area 0 — System & Utilities

| File | Description |
|---|---|
| `asm.com` | 8080 macro assembler |
| `basiclib.rel` | Relocatable BASIC library object |
| `baud.com` | Baud rate configuration utility *(not on kayproiv.img)* |
| `config.com` | Kaypro CONFIG utility |
| `copy.com` | File copy utility |
| `ddt.com` | Dynamic Debugging Tool |
| `dplay.bas` | BASIC program |
| `dump.asm` | Assembler source for DUMP |
| `dump.com` | Hex dump utility |
| `ed.com` | ED context text editor |
| `fac.bas` | BASIC program |
| `load.com` | Intel hex → .COM loader |
| `movcpm.com` | CP/M memory relocation utility |
| `overlayb.com` | Overlay B |
| `pip.com` | Peripheral Interchange Program |
| `sbasic.com` | SuperBASIC interpreter |
| `sscopy.com` | Screen/sector copy utility |
| `stat.com` | Disk/file status |
| `submit.com` | SUBMIT batch processor |
| `sysgen.com` | Bootable disk creator |
| `term.com` | Terminal emulator *(not on kayproiv.img)* |
| `userlib.rel` | Relocatable user library object |
| `xamn.bas` | BASIC program |
| `xsub.com` | Extended SUBMIT |

### Differences vs `kayproiv.img`

| | `kayproiv.img` | `kayprocpm2.ima` |
|---|---|---|
| `baud.com` | — | present |
| `term.com` | — | present |
| `d.com` | present | — |
| `dgen.cmd` / `dgen.ovl` | present | — |
| `kslnews.par` | present | — |
| `mfdisk.com` | present | — |
| User area 5 (partition BASIC) | present | — |

`kayprocpm2.ima` trades the disk-generator and partition tools for `baud.com` and `term.com`,
suggesting it may be oriented toward serial/terminal use. The absence of `mfdisk.com` means it
does not carry the memory-warning utilities. Machine compatibility is unverified — do not assume
it boots correctly on the Kaypro IV without testing.
