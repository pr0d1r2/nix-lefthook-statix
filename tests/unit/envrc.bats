#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    ENVRC="$BATS_TEST_DIRNAME/../../.envrc"
}

@test "watches flake.nix for changes" {
    run grep 'watch_file flake.nix' "$ENVRC"
    assert_success
}

@test "watches flake.lock for changes" {
    run grep 'watch_file flake.lock' "$ENVRC"
    assert_success
}

@test "watches dev.sh for changes" {
    run grep 'watch_file dev.sh' "$ENVRC"
    assert_success
}
