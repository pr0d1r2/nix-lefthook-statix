{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-statix";
          runtimeInputs = [ pkgs.statix ];
          text = builtins.readFile ./lefthook-statix.sh;
        };
        setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
      });

      devShells = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
          sys = pkgs.stdenv.hostPlatform.system;
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-assert
            p.bats-file
            p.bats-support
          ]);
          shells = set-and-setting.lib.mkDevShells {
            inherit pkgs;
            basePackages = mat.packages ++ [
              self.packages.${sys}.default
              batsWithLibs
            ];
            defaultShellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
            settingHook =
              builtins.replaceStrings
                [
                  "@SETTING_BIN@"
                  "@FRAGMENTS@"
                  "@FRAGMENTS_DIR@"
                  "@ASSEMBLE_SCRIPT@"
                ]
                [
                  "${self.packages.${sys}.setting}"
                  "${builtins.concatStringsSep " " fragments}"
                  "${set-and-setting}/setting/integrations/lefthook"
                  "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                ]
                (builtins.readFile ./nix/setting-hook.sh);
          };
        in
        shells
        // {
          # Retain the pre-migration, hook-free CI shell interface.
          ci = pkgs.mkShell {
            packages = mat.packages ++ [
              self.packages.${sys}.default
              batsWithLibs
            ];
            BATS_LIB_PATH = "${batsWithLibs}/share/bats";
          };
        }
      );

      checks = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-assert
            p.bats-file
            p.bats-support
          ]);
        in
        (set-and-setting.lib.checksFor {
          inherit pkgs fragments;
          src = ./.;
        })
        // {
          dep-graph = set-and-setting.lib.mkDepGraphCheck {
            inherit pkgs;
            projectRoot = ./.;
          };
          unit =
            pkgs.runCommand "unit-tests"
              {
                nativeBuildInputs = mat.packages ++ [
                  self.packages.${pkgs.stdenv.hostPlatform.system}.default
                  batsWithLibs
                  pkgs.bash
                  pkgs.coreutils
                ];
              }
              (
                builtins.replaceStrings
                  [
                    "@SOURCE@"
                    "@FRAGMENTS@"
                    "@FRAGMENTS_DIR@"
                    "@ASSEMBLE_SCRIPT@"
                    "@BATS_LIB_PATH@"
                  ]
                  [
                    "${./.}"
                    "${builtins.concatStringsSep " " fragments}"
                    "${set-and-setting}/setting/integrations/lefthook"
                    "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                    "${batsWithLibs}/share/bats"
                  ]
                  (builtins.readFile ./nix/unit-tests.sh)
              );
          default = pkgs.runCommand "checks" { } "touch $out";
        }
      );

      apps = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
        in
        {
          confirm = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "confirm";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.diffutils
                  pkgs.findutils
                  pkgs.gawk
                  pkgs.git
                  pkgs.gnugrep
                ]
                ++ mat.packages;
                text =
                  builtins.replaceStrings
                    [
                      "@FRAGMENTS_DIR@"
                      "@ASSEMBLE_SCRIPT@"
                      "@DETECT_SCRIPT@"
                      "@SETTING_SRC@"
                      "@CONFIRM_SCRIPT@"
                      "@CONFIRM_REV@"
                    ]
                    [
                      "${set-and-setting}/setting/integrations/lefthook"
                      "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                      "${set-and-setting}/setting/lib/detect-fragments.sh"
                      "${self.packages.${pkgs.stdenv.hostPlatform.system}.setting}"
                      "${set-and-setting}/lib/confirm.sh"
                      "${set-and-setting.rev or "unknown"}"
                    ]
                    (builtins.readFile ./nix/confirm.sh);
              }
            }/bin/confirm";
          };
        }
      );
    };
}
