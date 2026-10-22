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
        ...
      }: let
        shellHookMsg = ''
          ===
          Marimo dev shell
            marimo edit [filename]   open notebook in editor
            marimo run [filename]    run notebook as an app
            ruff check               lint
            nix fmt                  format everything
          ===
        '';

        python = pkgs.python3.withPackages (ps:
          with ps; [
            marimo
            pandas
            scipy
            scikit-learn
            matplotlib
            seaborn
          ]);
      in {
        treefmt.programs = {
          nixfmt.enable = true;
          ruff-format.enable = true;
        };

        pre-commit.check.enable = false;

        devShells.default = pkgs.mkShell {
          packages =
            [
              python
              pkgs.ruff
            ]
            ++ config.pre-commit.settings.enabledPackages;
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo '${shellHookMsg}'
          '';
        };
      };
    };
}
