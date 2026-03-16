#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <cpm.h>

/* File-scope so sccz80 inline asm can reference it as (_s_r_byte) */
static unsigned char s_r_byte;

/*
 * Reads the Z80 R (memory refresh) register into s_r_byte.
 *
 * The R register is a 7-bit counter the Z80 increments automatically on every
 * memory fetch. Its value at any given moment depends on exactly how many
 * instructions have executed since power-on, which is effectively unpredictable
 * from the user's perspective. XOR'd with the keyboard-timing tick count it
 * adds a cheap second source of entropy for seeding srand().
 *
 * sccz80 mangles C identifiers with a leading underscore in asm, so the
 * file-scope variable s_r_byte is referenced here as (_s_r_byte).
 */
static void capture_r_register(void) {
#asm
    ld a, r
    ld (_s_r_byte), a
#endasm
}

static int read_line(char *buf, int size) {
    if (fgets(buf, size, stdin) == NULL) { buf[0] = '\0'; return 0; }
    buf[strcspn(buf, "\r\n")] = '\0';
    return buf[0] != '\0';
}

/* Returns 1 on success, 0 on failure (non-numeric, trailing garbage, out of int range) */
static int parse_int(const char *buf, int *out) {
    char *endptr;
    long val;
    if (buf[0] == '\0') return 0;
    val = strtol(buf, &endptr, 10);
    if (*endptr != '\0') return 0;
    if (val < (long)INT_MIN || val > (long)INT_MAX) return 0;
    *out = (int)val;
    return 1;
}

/* Prompts, reprompts on bad input. Empty input returns default_val. */
static int prompt_int(const char *prompt, int default_val) {
    char buf[16];
    int val;
    for (;;) {
        printf("%s", prompt);
        if (!read_line(buf, sizeof(buf))) return default_val;
        if (parse_int(buf, &val)) return val;
        printf("Invalid input.\n");
    }
}

int main(int argc, char *argv[]) {
    unsigned int ticks;
    int min_val, max_val, result;

    if (argc > 1) {
        /* Seed-injection mode: skip interactive seeding (used in tests) */
        srand((unsigned int)strtol(argv[1], NULL, 10));
    } else {
        /* Interactive mode: count BDOS polls until keypress, XOR with R register */
        ticks = 0;
        printf("Press any key to generate your number...\n");
        while (bdos(CPM_ICON, 0) == 0) ticks++;
        bdos(CPM_RCON, 0);
        capture_r_register();
        srand(ticks ^ (unsigned int)s_r_byte);
    }

    min_val = prompt_int("Minimum (default 1): ", 1);

    for (;;) {
        max_val = prompt_int("Maximum (default 100): ", 100);
        if (max_val > min_val) break;
        printf("Maximum must be greater than minimum (%d).\n", min_val);
    }

    result = min_val + rand() % (max_val - min_val + 1);
    printf("Your lucky number is: %d\n", result);
    return 0;
}
