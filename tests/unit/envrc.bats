#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    ENVRC="$BATS_TEST_DIRNAME/../../.envrc"
}

@test "watches nix/direnv.sh for changes" {
    run grep 'watch_file nix/direnv.sh' "$ENVRC"
    assert_success
}

@test "sources nix/direnv.sh" {
    run grep -F '. nix/direnv.sh' "$ENVRC"
    assert_success
}
