# shellcheck shell=bash
# Lefthook-compatible statix wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
  exit 0
fi

files=()
for f in "$@"; do
  [ -f "$f" ] || continue
  case "$f" in
    *.nix) files+=("$f") ;;
  esac
done

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

status=0
for f in "${files[@]}"; do
  output="$(cd "$(dirname "$f")" && statix check --unrestricted "./$(basename "$f")" 2>&1)"
  check_status=$?
  printf '%s\n' "$output"
  if [ "$check_status" -ne 0 ] || printf '%s\n' "$output" | grep -qE '\[W[0-9]+\]'; then
    status=1
  fi
done
exit "$status"
