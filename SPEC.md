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
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits (default 4096, lock 131072, nix 10240). |
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
| `x` | T6 | ~~Add TOML linter to lefthook for `.rtk/filters.toml`.~~ Obsolete — referenced guardrails have no TOML fragment. |
| `x` | T7 | Harmonize bats library loading: `dev.bats` uses `load.bash` extension while `lefthook-statix.bats` uses `load` without extension. |
| `x` | T8 | Add `nix/direnv.sh` extraction per flake skill (dev shell invocations should use an extracted shell script). |

## §B — Bugs / Known Issues

1. ~~**`.envrc` missing `watch_file` entries.**~~ Resolved — `.envrc` now watches `flake.nix`, `flake.lock`, and `dev.sh`.

2. ~~**Inconsistent `actions/checkout` versions.**~~ Resolved — `update-pins.yml` was removed.

3. ~~**Inconsistent bats library loading.**~~ Resolved — all bats test files now use the explicit `.bash` extension (`load.bash`) with braced variable syntax (`${BATS_LIB_PATH}`).

4. ~~**No markdownlint lefthook command.**~~ Resolved — `lefthook.yml` now has markdownlint in both `pre-commit` and `pre-push`.

5. ~~**No TOML linter.**~~ Obsolete — the referenced standard has no TOML fragment; `.rtk/filters.toml` is tool configuration rather than a consumer interface.

6. **Sequential file processing in wrapper.** `lefthook-statix.sh` processes files one-at-a-time in a loop rather than passing all files to `statix check` at once. This is less efficient for large changesets but ensures per-file error reporting.

7. **SPEC.md exceeds file-size-check default limit.** `SPEC.md` (5825 bytes) exceeded the default 4096-byte limit in `config/lefthook/file_size_limits.yml`, causing `file-size-check` to fail in CI. Fixed by adding `md: 8192` extension override.

8. **Orphaned `tests/unit/update-pins.bats` after `update-pins.yml` removal.** The pin-refresh commit dropped `.github/workflows/update-pins.yml` but left its test file, causing two bats failures in CI. Fixed by removing the orphaned test file.

9. **Missing `lefthook-markdownlint` / `lefthook-markdownlint-agentic` wrappers.** `lefthook.yml` invoked `lefthook-markdownlint` and `lefthook-markdownlint-agentic`,
but `flake.nix` never packaged those wrappers, so both commands exited 127 in CI's `build-linux`.
Fixed by adding the flake inputs and wrapping them in `lefthookWrappersFor`.

10. **Flake manifest rejected the outputs definition.** The guardrails manifest check disallowed helper bindings and a constructed `outputs` attrset in `flake.nix`. Fixed by delegating `outputs` to the separately formatted `flake-outputs.nix` module.

10. **Duplicate `default` attribute in `packages` output.** Migration commit introduced a stale `mkShell` block as a second `default` inside `packages`,
causing `nix flake check` to fail with "attribute 'default' already defined".

11. **Guardrail commands without timeouts.** The first three `lefthook.yml` guardrails were missing the timeout wrapper, causing the guardrail unit test to fail. Fixed by applying `timeout --foreground` consistently to every guardrail command in both hooks.
Fixed by removing the orphaned `mkShell` block that referenced undefined variables (`ciCommon`, `batsWithLibs`).

11. **Confirm app missing materialized packages on PATH.** The `nix run .#confirm` coherence check verifies that every `lefthook-*` command in
`lefthook.yml` is on PATH, but the confirm app's `runtimeInputs` only included basic coreutils—not the fragment-provided lefthook wrappers.
Also, `flake.lock` was stale (missing `set-and-setting` input).
Fixed by adding `mat.packages` from `materializationFor` to the confirm app's `runtimeInputs` and regenerating `flake.lock`.

12. **Embedded shell in flake.nix fails nix-no-embedded-shell-check.** The `settingHook` and `apps.confirm.text` attributes used inline `'' ... ''` shell strings,
violating the no-embedded-shell invariant enforced by `set-and-setting.lib.checksFor`.
Fixed by extracting shell to `nix/setting-hook.sh` and `nix/confirm.sh` with `@PLACEHOLDER@` substitution via `builtins.replaceStrings` + `builtins.readFile`.

13. **`flake.lock` exceeds file-size-check `.lock` limit after pin refresh.** The `nix flake update` in the pin-refresh commit grew `flake.lock` to 120413 bytes,
exceeding the 65536-byte `.lock` limit in `config/lefthook/file_size_limits.yml`.
Fixed by raising the `.lock` limit to 131072 (128 KB) to accommodate the nested `nixpkgs-lock` dependency chain.

14. **`flake-outputs.nix` was not formatted.** The flake manifest migration left the imported outputs module indented four spaces, causing the `nixfmt-check` guardrail to fail. Fixed by applying nixfmt formatting to the module.

15. **Markdown fragment test checked the wrong flake module.** The outputs migration moved fragment declarations from `flake.nix` to `flake-outputs.nix`, but the unit test still searched the former. Fixed the test to inspect the module that owns the declaration.

16. **External base fragment omitted guardrail timeouts.** The assembled `gitleaks`, conflict-marker, and local-path commands came from the pinned external fragment without timeouts, despite the repository YAML including them. Fixed by normalizing generated lefthook commands at the assembly boundary.

17. **Checked-in `lefthook.yml` drifted from the pinned fragment assembly.** The manually maintained file omitted the generated remotes, parallel settings, and fragment commands, so the guardrail fidelity check failed. Fixed by restoring the canonical assembled configuration.

18. **Checked-in `lefthook.yml` was regenerated through the dev-shell materializer rather than the fidelity assembler.** That path stripped the canonical remotes and fragment commands, causing the guardrail fidelity check to fail. Fixed by restoring the exact fragment-assembled configuration.

19. **Checked-in `lefthook.yml` did not contain the timeout-normalized guardrail commands or the generated pre-push guardrails.** The dev-shell materializer added these commands, so CI fidelity failed. Fixed by committing the materializer's canonical output.

20. **ShellCheck rejected the timeout assembler.** The generated shell parameter expansion was embedded in a single-quoted `sed` expression (`SC2016`), and the confirm assembler used the Nix `out` build variable without declaring its required environment contract (`SC2154`). Fixed by escaping the intentionally literal generated expansion and validating `out` before use.

21. **Canonical `lefthook.yml` was ignored and absent from the checkout.** The guardrail fidelity check could not compare the repository configuration with the fragment assembly because `.gitignore` excluded the generated artifact. Fixed by committing the canonical assembled, timeout-normalized `lefthook.yml`.

22. **Checked-in `lefthook.yml` diverged from the pinned fragment assembler.** The previous restoration retained locally added timeout wrappers and pre-push commands while omitting the pinned `actionlint` commands, so the guardrail fidelity check failed. Fixed by synchronizing the file exactly with the pinned assembly output.

23. **Canonical `actions` fragment referenced an unavailable actionlint wrapper.** The generated configuration included `lefthook-actionlint`, but consumer shells did not put that command on PATH. Fixed by packaging the wrapper and adding it to development, CI, and confirm environments.
