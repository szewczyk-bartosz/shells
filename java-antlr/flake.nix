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
        useTests = true;
        jdk = pkgs.jdk21;
        shellHookMsg = ''
          echo 'Java + ANTLR dev shell'
          echo '  gradle run     generate parser, build and run'
          echo '  gradle test    run tests (src/test/java)'
          echo '  grammar lives in src/main/antlr/'
          echo '  nix fmt        format everything'
        '';
      in {
        treefmt.programs = {
          nixfmt.enable = true;
          google-java-format.enable = true;
        };

        pre-commit.check.enable = false;
        pre-commit.settings.hooks.tests = {
          enable = useTests;
          name = "gradle test";
          entry = "${pkgs.gradle}/bin/gradle test";
          pass_filenames = false;
        };

        devShells.default = pkgs.mkShell {
          packages =
            [
              jdk
              pkgs.gradle
            ]
            ++ config.pre-commit.settings.enabledPackages;

          JAVA_HOME = jdk.home;

          shellHook = ''
            ${config.pre-commit.installationScript}
            ${shellHookMsg}
          '';
        };
      };
    };
}
