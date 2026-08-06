#!/usr/bin/env bash
set -euo pipefail

bash "@ASSEMBLE_SCRIPT@"
(
  cd "$out"
  bash "@ENSURE_TIMEOUTS@"
)
