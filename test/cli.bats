#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../syncthing-resolve-conflicts"

@test "--help exits 0 and prints usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--version exits 0 and prints version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"1.3.0"* ]]
}

@test "unknown option exits 1" {
    run "$SCRIPT" --unknown-option
    [ "$status" -eq 1 ]
}

@test "-c and -d are mutually exclusive" {
    run "$SCRIPT" -c -d "$BATS_TEST_TMPDIR"
    [ "$status" -eq 1 ]
}

@test "-d with non-existent path exits 1" {
    run "$SCRIPT" -d /no/such/path/xyz
    [ "$status" -eq 1 ]
}

@test "shellcheck passes on script" {
    run shellcheck "$SCRIPT"
    [ "$status" -eq 0 ]
}
