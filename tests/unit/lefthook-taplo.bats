#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    LEFTHOOK_YML="$BATS_TEST_DIRNAME/../../lefthook.yml"
    FLAKE_NIX="$BATS_TEST_DIRNAME/../../flake.nix"
}

@test "lefthook pre-commit has taplo command" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep 'taplo:'"
    assert_success
}

@test "lefthook pre-push has taplo command" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep 'taplo:'"
    assert_success
}

@test "taplo pre-commit scopes to toml files" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'glob:.*\\.toml'"
    assert_success
}

@test "taplo pre-push scopes to toml files" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'glob:.*\\.toml'"
    assert_success
}

@test "taplo pre-commit has timeout" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'timeout'"
    assert_success
}

@test "taplo pre-push has timeout" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'timeout'"
    assert_success
}

@test "taplo pre-commit uses staged_files" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'staged_files'"
    assert_success
}

@test "taplo pre-push uses push_files" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'push_files'"
    assert_success
}

@test "taplo pre-commit runs lint subcommand" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'taplo:' | grep 'taplo lint'"
    assert_success
}

@test "flake.nix includes taplo" {
    run grep 'taplo' "$FLAKE_NIX"
    assert_success
}
