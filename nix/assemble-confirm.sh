#!/usr/bin/env bash
set -euo pipefail

bash "@ASSEMBLE_SCRIPT@"
(
  # `out` is provided by the runCommand environment and is the assembly target.
  : "${out:?out must be set by the Nix build environment}"
  cd "$out"
  bash "@ENSURE_TIMEOUTS@"
)
