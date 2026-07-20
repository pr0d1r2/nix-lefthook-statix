# shellcheck shell=bash
cp -R "@SOURCE@" source
chmod -R u+w source
cd source || exit 1
FRAGMENTS="@FRAGMENTS@" \
  out="$PWD" \
  FRAGMENTS_DIR="@FRAGMENTS_DIR@" \
  bash "@ASSEMBLE_SCRIPT@"
export BATS_LIB_PATH="@BATS_LIB_PATH@"
bats tests/unit
# shellcheck disable=SC2154
touch "$out"
