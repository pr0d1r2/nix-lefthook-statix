# shellcheck shell=bash
FRAGMENTS="@FRAGMENTS@" \
  out="$(pwd)" \
  FRAGMENTS_DIR="@FRAGMENTS_DIR@" \
  bash "@ASSEMBLE_SCRIPT@"
bash "@ENSURE_TIMEOUTS@"
