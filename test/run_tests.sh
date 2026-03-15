#!/usr/bin/env bash
# Automated test runner using RunCPM.
# For each test case in test/cases/, copies the .COM to the RunCPM drive,
# feeds input.txt via stdin, and diffs output against expected.txt.
#
# NOTE: RunCPM does not run a single program and exit — it is an interactive
# CP/M shell. This script feeds a command sequence via stdin: the program name
# followed by ^C (to exit RunCPM). If your program is interactive and requires
# expect-style automation, add an expect script alongside input.txt and adjust
# the invocation here.
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNCPM="$REPO_DIR/tools/runcpm/RunCPM"
DRIVE_DIR="$REPO_DIR/tools/runcpm-drive"
CASES_DIR="$(dirname "$0")/cases"
PASS=0
FAIL=0

if [ ! -f "$RUNCPM" ]; then
    echo "ERROR: RunCPM not found at $RUNCPM — run 'make setup' first."
    exit 1
fi

mkdir -p "$DRIVE_DIR/A/0"

for case_dir in "$CASES_DIR"/*/; do
    [ -d "$case_dir" ] || continue
    prog=$(basename "$case_dir")
    prog_upper=$(echo "$prog" | tr '[:lower:]' '[:upper:]')
    com_file="$REPO_DIR/build/${prog_upper}.COM"

    if [ ! -f "$com_file" ]; then
        echo "SKIP: $prog (no $com_file)"
        continue
    fi

    cp "$com_file" "$DRIVE_DIR/A/0/"

    input="$case_dir/input.txt"
    expected="$case_dir/expected.txt"

    # Feed: the program invocation from input.txt, then exit RunCPM
    actual=$(cd "$DRIVE_DIR" && (cat "$input"; printf '\x03') | timeout 10 "$RUNCPM" 2>/dev/null || true)

    # Strip RunCPM banner lines (everything before the first program output).
    # RunCPM prints "RunCPM vX.X" and a blank line before the CP/M prompt.
    # We strip leading non-blank header lines and the prompt itself.
    actual_clean=$(echo "$actual" | sed '/^RunCPM/d' | sed '/^$/d' | sed 's/^A0>//')

    if diff -q <(printf '%s\n' "$actual_clean") "$expected" > /dev/null 2>&1; then
        echo "PASS: $prog"
        ((PASS++))
    else
        echo "FAIL: $prog"
        echo "  --- expected ---"
        cat "$expected"
        echo "  --- actual ---"
        printf '%s\n' "$actual_clean"
        echo "  --- diff ---"
        diff <(printf '%s\n' "$actual_clean") "$expected" || true
        ((FAIL++))
    fi
done

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
