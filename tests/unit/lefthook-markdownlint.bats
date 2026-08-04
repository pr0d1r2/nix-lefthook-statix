#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    LEFTHOOK_YML="$BATS_TEST_DIRNAME/../../lefthook.yml"
    FLAKE_OUTPUTS_NIX="$BATS_TEST_DIRNAME/../../flake-outputs.nix"
}

@test "lefthook pre-commit has markdownlint command" {
    run grep -A3 'markdownlint:' "$LEFTHOOK_YML"
    assert_success
    # Verify it appears under pre-commit
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep 'markdownlint:'"
    assert_success
}

@test "lefthook pre-push has markdownlint command" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep 'markdownlint:'"
    assert_success
}

@test "markdownlint pre-commit scopes to md files" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'glob:.*\\.md'"
    assert_success
}

@test "markdownlint pre-push scopes to md files" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'glob:.*\\.md'"
    assert_success
}

@test "markdownlint pre-commit has timeout" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'timeout'"
    assert_success
}

@test "markdownlint pre-push has timeout" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'timeout'"
    assert_success
}

@test "markdownlint pre-commit uses staged_files" {
    run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'staged_files'"
    assert_success
}

@test "markdownlint pre-push uses push_files" {
    run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -A5 'markdownlint:' | grep 'push_files'"
    assert_success
}

@test "flake outputs include markdown fragment" {
    run grep '"markdown"' "$FLAKE_OUTPUTS_NIX"
    assert_success
}
