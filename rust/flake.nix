{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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
      ];

      perSystem = {
        pkgs,
        lib,
        system,
        ...
      }: let
        devComponents = [
          "rust-src"
          "rust-analyzer"
          "clippy"
          "rustfmt"
        ];

        toolchainFile = ./rust-toolchain.toml;
        toolchain =
          if builtins.pathExists toolchainFile
          then let
            spec = (lib.importTOML toolchainFile).toolchain;
          in
            pkgs.rust-bin.fromRustupToolchain (
              spec
              // {
                components = lib.unique ((spec.components or []) ++ devComponents);
              }
            )
          else pkgs.rust-bin.stable.latest.default.override {extensions = devComponents;};

        cargoToml =
          if builtins.pathExists ./Cargo.toml
          then lib.importTOML ./Cargo.toml
          else {};
        packageEdition = cargoToml.package.edition or null;
        edition =
          if builtins.isString packageEdition
          then packageEdition
          else
            cargoToml.workspace.package.edition or (
              if cargoToml ? package
              then "2015"
              else "2024"
            );

        shellHookMsg = ''
          echo '==== Rust dev shell ===='
          echo '  cargo run      build and run'
          echo '  cargo test     run tests'
          echo '  cargo clippy   lint'
          echo '  nix fmt        format everything'
          echo '  rust-toolchain.toml selects the toolchain (default: latest stable)'
        '';
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.rust-overlay.overlays.default];
        };

        treefmt.programs = {
          nixfmt.enable = true;
          rustfmt = {
            enable = true;
            package = toolchain;
            inherit edition;
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            toolchain
            pkgs.pkg-config
          ];

          buildInputs = [
          ];

          shellHook = ''
            export PATH="$PATH:''${CARGO_HOME:-$HOME/.cargo}/bin"
            ${shellHookMsg}
          '';
        };
      };
    };
}
