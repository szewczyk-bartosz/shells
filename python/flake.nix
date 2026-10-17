{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        lib,
        ...
      }: let
        useTests = true;
        shellHookMsg = ''
          Default python dev shell! (change this if you want)
        '';

        python = pkgs.python3.withPackages (ps:
          [
          ]
          ++ lib.optional useTests ps.pytest);
      in {
        treefmt.programs = {
          nixfmt.enable = true;
          ruff-format.enable = true;
        };

        pre-commit.check.enable = false;
        pre-commit.settings.hooks.tests = {
          enable = useTests;
          name = "pytest";
          entry = "${python}/bin/pytest";
          pass_filenames = false;
        };

        devShells.default = pkgs.mkShell {
          packages =
            [
              python
              pkgs.ruff
            ]
            ++ config.pre-commit.settings.enabledPackages;
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo ${shellHookMsg}
          '';
        };
      };
    };
}
