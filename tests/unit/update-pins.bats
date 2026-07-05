#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    UPDATE_PINS_YML="$BATS_TEST_DIRNAME/../../.github/workflows/update-pins.yml"
    CI_YML="$BATS_TEST_DIRNAME/../../.github/workflows/ci.yml"
}

@test "update-pins.yml uses actions/checkout@v6" {
    run grep 'actions/checkout@v6' "$UPDATE_PINS_YML"
    assert_success
}

@test "update-pins.yml checkout version matches ci.yml" {
    ci_version=$(grep -o 'actions/checkout@v[0-9]*' "$CI_YML" | head -1)
    pins_version=$(grep -o 'actions/checkout@v[0-9]*' "$UPDATE_PINS_YML" | head -1)
    [ "$ci_version" = "$pins_version" ]
}

@test "update-pins.yml does not use actions/checkout@v4" {
    run grep 'actions/checkout@v4' "$UPDATE_PINS_YML"
    assert_failure
}
