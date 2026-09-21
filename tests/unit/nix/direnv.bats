#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

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

@test "watches nix/setting-hook.sh for changes" {
    run grep 'watch_file nix/setting-hook.sh' "$DIRENV_SH"
    assert_success
}

@test "watches nix/confirm.sh for changes" {
    run grep 'watch_file nix/confirm.sh' "$DIRENV_SH"
    assert_success
}

@test "watches nix/unit-tests.sh for changes" {
    run grep 'watch_file nix/unit-tests.sh' "$DIRENV_SH"
    assert_success
}

@test "uses flake" {
    run grep 'use flake' "$DIRENV_SH"
    assert_success
}
