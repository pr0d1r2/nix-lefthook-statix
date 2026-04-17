# nix-lefthook-statix

[![CI](https://github.com/pr0d1r2/nix-lefthook-statix/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-statix/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [statix](https://github.com/nerdypepper/statix) wrapper, packaged as a Nix flake.

Filters `.nix` files from staged arguments and runs statix static analysis on them. Exits 0 when no matching files are found.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just `pkgs.statix` in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-statix
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-statix = {
  url = "github:pr0d1r2/nix-lefthook-statix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-statix.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    statix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_STATIX_TIMEOUT:-30} lefthook-statix {staged_files}
```

## Self-linting

> **Note:** This repo uses raw `statix check` and `deadnix --fail` commands
> in its own lefthook config instead of the flake-wrapped versions. This
> avoids circular flake dependencies — the nix-check repos and the base
> linter repos form a dependency cycle if they reference each other as flake
> inputs. Leaf repos that consume these checks do not have this limitation
> and use the wrapped versions normally.

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_STATIX_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-statix  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
