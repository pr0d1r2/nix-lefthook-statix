#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    LEFTHOOK_YML="$BATS_TEST_DIRNAME/../../lefthook.yml"
}

@test "all guardrail commands run in both hooks" {
    for command in gitleaks git-conflict-markers git-no-local-paths markdownlint markdownlint-agentic yamllint; do
        run bash -c "awk '/^pre-commit:/,/^pre-push:/' '$LEFTHOOK_YML' | grep -E \"^    $command:\\$\""
        assert_success
        run bash -c "awk '/^pre-push:/,0' '$LEFTHOOK_YML' | grep -E \"^    $command:\\$\""
        assert_success
    done
}

@test "all guardrail commands have a timeout" {
    run awk '/^pre-commit:/,/^pre-push:/' "$LEFTHOOK_YML"
    assert_success
    refute_output --partial 'run: lefthook-'

    run awk '/^pre-push:/,0' "$LEFTHOOK_YML"
    assert_success
    refute_output --partial 'run: lefthook-'
}
