# shellcheck shell=bash
@SETTING_BIN@/bin/sync-setting .
_assemble_out="$(mktemp -d)"
FRAGMENTS="@FRAGMENTS@" \
  out="$_assemble_out" \
  FRAGMENTS_DIR="@FRAGMENTS_DIR@" \
bash "@ASSEMBLE_SCRIPT@"
cp -f "$_assemble_out/lefthook.yml" lefthook.yml
bash "@ENSURE_TIMEOUTS@"
rm -rf "$_assemble_out"
