#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../syncthing-resolve-conflicts"

@test "-o -f lists conflict files in the given directory" {
    touch "$BATS_TEST_TMPDIR/notes.sync-conflict-20240101-120000-ABCDEFG.txt"
    run bash "$SCRIPT" -o -f -d "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sync-conflict"* ]]
}

@test "-o -f includes conflicts inside .stversions (not filtered in output mode)" {
    mkdir -p "$BATS_TEST_TMPDIR/.stversions"
    touch "$BATS_TEST_TMPDIR/.stversions/notes.sync-conflict-20240101-120000-ABCDEFG.txt"
    run bash "$SCRIPT" -o -f -d "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *".stversions"* ]]
}

@test "identical conflict and original are automatically deleted without interaction" {
    echo "hello" >"$BATS_TEST_TMPDIR/notes.txt"
    cp "$BATS_TEST_TMPDIR/notes.txt" \
        "$BATS_TEST_TMPDIR/notes.sync-conflict-20240101-120000-ABCDEFG.txt"
    export DIFFPROG=true
    run bash "$SCRIPT" -f --nocolor -d "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [ ! -f "$BATS_TEST_TMPDIR/notes.sync-conflict-20240101-120000-ABCDEFG.txt" ]
    [ -f "$BATS_TEST_TMPDIR/notes.txt" ]
}
