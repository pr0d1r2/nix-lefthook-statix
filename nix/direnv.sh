# shellcheck shell=bash
watch_file flake.nix
watch_file flake.lock
watch_file dev.sh
watch_file nix/setting-hook.sh
watch_file nix/confirm.sh
watch_file nix/unit-tests.sh
use flake
