#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

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
