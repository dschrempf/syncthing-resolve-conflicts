#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../syncthing-resolve-conflicts"

setup() {
    # shellcheck source=../syncthing-resolve-conflicts
    source "$SCRIPT"
}

@test "get_syncthing_folders extracts absolute folder paths" {
    local result
    result=$(get_syncthing_folders "$BATS_TEST_DIRNAME/fixtures/config.xml")
    [[ "$result" == *"/test/path/Documents"* ]]
    [[ "$result" == *"/test/path/Pictures"* ]]
}

@test "get_syncthing_folders expands leading tilde to HOME" {
    local result
    result=$(get_syncthing_folders "$BATS_TEST_DIRNAME/fixtures/config-tilde.xml")
    [ "$result" = "$HOME/Documents" ]
}

@test "get_syncthing_folders excludes the defaults block" {
    local result
    result=$(get_syncthing_folders "$BATS_TEST_DIRNAME/fixtures/config.xml")
    # The defaults block (id="") is filtered by grep -v; exactly 2 folders remain.
    [ "$(echo "$result" | wc -l)" -eq 2 ]
}

@test "find_syncthing_config finds config via STCONFDIR" {
    touch "$BATS_TEST_TMPDIR/config.xml"
    STCONFDIR="$BATS_TEST_TMPDIR"
    run find_syncthing_config
    [ "$status" -eq 0 ]
    [ "$output" = "$BATS_TEST_TMPDIR/config.xml" ]
}

@test "find_syncthing_config falls back to STHOMEDIR when STCONFDIR unset" {
    touch "$BATS_TEST_TMPDIR/config.xml"
    unset STCONFDIR
    STHOMEDIR="$BATS_TEST_TMPDIR"
    run find_syncthing_config
    [ "$status" -eq 0 ]
    [ "$output" = "$BATS_TEST_TMPDIR/config.xml" ]
}

@test "find_syncthing_config returns failure when no config exists" {
    unset STCONFDIR
    unset STHOMEDIR
    HOME="$BATS_TEST_TMPDIR"
    # Stub syncthing so 'syncthing paths' is not consulted.
    syncthing() { :; }
    export -f syncthing
    run find_syncthing_config
    [ "$status" -ne 0 ]
}
