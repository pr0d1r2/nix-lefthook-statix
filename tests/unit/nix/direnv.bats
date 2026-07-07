#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    DIRENV_SH="$BATS_TEST_DIRNAME/../../../nix/direnv.sh"
}

@test "watches flake.nix for changes" {
    run grep 'watch_file flake.nix' "$DIRENV_SH"
    assert_success
}

@test "watches flake.lock for changes" {
    run grep 'watch_file flake.lock' "$DIRENV_SH"
    assert_success
}

@test "watches dev.sh for changes" {
    run grep 'watch_file dev.sh' "$DIRENV_SH"
    assert_success
}

@test "uses flake" {
    run grep 'use flake' "$DIRENV_SH"
    assert_success
}
