# nix-lefthook-statix

## §D — Description

nix-lefthook-statix is a Nix flake that packages a lefthook-compatible wrapper around [statix](https://github.com/nerdypepper/statix), a static analysis tool for Nix files.
The wrapper filters `.nix` files from staged arguments, silently skips missing files, and runs statix on each remaining file, exiting non-zero if any check fails.
It is consumed by other Nix projects either as a lefthook remote (pulling `lefthook-remote.yml`) or as a flake input providing a `lefthook-statix` executable.
Target users are Nix developers who want automated statix linting in their git pre-commit and pre-push hooks.

## §V — Invariants

1. `lefthook-statix` exits 0 when called with no arguments.
2. `lefthook-statix` exits 0 when none of the arguments are `.nix` files.
3. `lefthook-statix` silently skips files that do not exist on disk.
4. `lefthook-statix` exits 0 for clean `.nix` files and non-zero when statix reports warnings.
5. Non-`.nix` files in a mixed argument list are filtered out and never passed to statix.
6. The dev shell hook sets `BATS_LIB_PATH` from the `@BATS_LIB_PATH@` placeholder.
7. The dev shell hook runs `lefthook install` only when `.git/hooks/pre-commit` is absent.
8. The flake builds on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
9. CI runs on both Linux and macOS (macOS on push/dispatch only).
10. Every lefthook command has a timeout (default 30s via `LEFTHOOK_STATIX_TIMEOUT`).
11. All lefthook checks run in both `pre-commit` and `pre-push` hooks.
12. Shell scripts contain no functions; logic is in separate scripts invoked inline.
13. No embedded shell in Nix files; shell code is read from external `.sh` files.
14. All bats tests are non-destructive, using temporary directories cleaned up in teardown.

## §I — Interfaces

### CLI

| Command | Arguments | Description |
|---|---|---|
| `lefthook-statix` | `[file...]` | Filter `.nix` files from arguments, run `statix check` on each. Exit 0 if no files match or all pass; exit 1 if any fail. |

### Flake outputs

| Output | Type | Description |
|---|---|---|
| `packages.${system}.default` | `writeShellApplication` | The `lefthook-statix` wrapper with `statix` in `runtimeInputs`. |
| `devShells.${system}.default` | `mkShell` | Full dev shell with all tools, lefthook wrappers, and `dev.sh` shellHook. |
| `devShells.${system}.ci` | `mkShell` | CI-oriented shell without shellHook; sets `BATS_LIB_PATH` env var directly. |

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `LEFTHOOK_STATIX_TIMEOUT` | `30` | Timeout in seconds for the statix lefthook command. |
| `BATS_LIB_PATH` | Set by `dev.sh` | Path to bats helper libraries (bats-support, bats-assert, bats-file). |

### Config files

| File | Format | Purpose |
|---|---|---|
| `lefthook.yml` | YAML | Local lefthook config with remote integrations and statix commands. |
| `lefthook-remote.yml` | YAML | Consumed by other repos via lefthook remote; defines statix pre-commit/pre-push commands using the wrapper. |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits (default 4096, lock 65536, nix 10240). |
| `.yamllint.yml` | YAML | yamllint config: disables truthy key checks and line-length. |
| `.markdownlint.yml` | YAML | markdownlint config: disables MD013 (line length). |
| `.editorconfig` | INI | Editor defaults: UTF-8, LF, 2-space indent, trailing whitespace trim. |

## §T — Tasks

| status | id | goal |
|---|---|---|
| `x` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, and `dev.sh` per direnv skill rules. |
| `x` | T2 | Add markdownlint lefthook check for `.md` files (config exists at `.markdownlint.yml` but no lefthook command uses it). |
| `x` | T3 | ~~Update `actions/checkout` in `update-pins.yml` from `@v4` to `@v6` to match `ci.yml`.~~ Obsolete — `update-pins.yml` was removed. |
| `x` | T4 | Add test for exit code when mixing passing and failing `.nix` files in one invocation. |
| `x` | T5 | Add test for files with spaces or special characters in names. |
| `x` | T6 | Add TOML linter to lefthook for `.rtk/filters.toml` (linter skill requires every tracked file type to have a linter). |
| `x` | T7 | Harmonize bats library loading: `dev.bats` uses `load.bash` extension while `lefthook-statix.bats` uses `load` without extension. |
| `x` | T8 | Add `nix/direnv.sh` extraction per flake skill (dev shell invocations should use an extracted shell script). |

## §B — Bugs / Known Issues

1. ~~**`.envrc` missing `watch_file` entries.**~~ Resolved — `.envrc` now watches `flake.nix`, `flake.lock`, and `dev.sh`.

2. ~~**Inconsistent `actions/checkout` versions.**~~ Resolved — `update-pins.yml` was removed.

3. ~~**Inconsistent bats library loading.**~~ Resolved — all bats test files now use the explicit `.bash` extension (`load.bash`) with braced variable syntax (`${BATS_LIB_PATH}`).

4. ~~**No markdownlint lefthook command.**~~ Resolved — `lefthook.yml` now has markdownlint in both `pre-commit` and `pre-push`.

5. ~~**No TOML linter.**~~ Resolved — `lefthook.yml` now has a `taplo lint` command in both `pre-commit` and `pre-push` scoped to `*.toml`, and `taplo` is in both dev shells.

6. **Sequential file processing in wrapper.** `lefthook-statix.sh` processes files one-at-a-time in a loop rather than passing all files to `statix check` at once. This is less efficient for large changesets but ensures per-file error reporting.

7. **SPEC.md exceeds file-size-check default limit.** `SPEC.md` (5825 bytes) exceeded the default 4096-byte limit in `config/lefthook/file_size_limits.yml`, causing `file-size-check` to fail in CI. Fixed by adding `md: 8192` extension override.

8. **Orphaned `tests/unit/update-pins.bats` after `update-pins.yml` removal.** The pin-refresh commit dropped `.github/workflows/update-pins.yml` but left its test file, causing two bats failures in CI. Fixed by removing the orphaned test file.

9. **Missing `lefthook-markdownlint` / `lefthook-markdownlint-agentic` wrappers.** `lefthook.yml` invoked `lefthook-markdownlint` and `lefthook-markdownlint-agentic`,
but `flake.nix` never packaged those wrappers, so both commands exited 127 in CI's `build-linux`.
Fixed by adding the flake inputs and wrapping them in `lefthookWrappersFor`.

10. **Duplicate `default` attribute in `packages` output.** Migration commit introduced a stale `mkShell` block as a second `default` inside `packages`,
causing `nix flake check` to fail with "attribute 'default' already defined".
Fixed by removing the orphaned `mkShell` block that referenced undefined variables (`ciCommon`, `batsWithLibs`).

11. **Confirm app missing materialized packages on PATH.** The `nix run .#confirm` coherence check verifies that every `lefthook-*` command in
`lefthook.yml` is on PATH, but the confirm app's `runtimeInputs` only included basic coreutils—not the fragment-provided lefthook wrappers.
Also, `flake.lock` was stale (missing `set-and-setting` input).
Fixed by adding `mat.packages` from `materializationFor` to the confirm app's `runtimeInputs` and regenerating `flake.lock`.
