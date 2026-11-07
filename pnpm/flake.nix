{
  description = "pnpm + Vite project";

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

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }: let
    name = "my-site";
  in
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
        nodejs = pkgs.nodejs_26;
        pnpm = pkgs.pnpm_10.override {nodejs-slim = nodejs;};
        shellHookMsg = ''
          echo '==== ${name} dev shell ===='
          echo '  pnpm install   install dependencies'
          echo '  pnpm dev       start the dev server'
          echo '  pnpm build     build into dist/'
          echo '  nix fmt        format everything'
        '';
      in {
        treefmt.programs = {
          nixfmt.enable = true;
          prettier.enable = true;
        };

        pre-commit.check.enable = false;

        devShells.default = pkgs.mkShell {
          packages =
            [
              nodejs
              pnpm
            ]
            ++ config.pre-commit.settings.enabledPackages;
          shellHook = ''
            if [ -n "$WEB_DEV_SHELL" ]; then
              echo "WARNING!!!!"
              echo "ALREADY IN A SHELL"
              echo "WARNING!!!!"
              exit
            fi
            export WEB_DEV_SHELL=1
            ${config.pre-commit.installationScript}
            ${shellHookMsg}
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = name;
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [
            nodejs
            pkgs.pnpmConfigHook
            pnpm
          ];

          # Needs pnpm-lock.yaml. Run `pnpm install`, then `nix build` once and
          # paste the hash it reports in place of fakeHash.
          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) src pname;
            inherit pnpm;
            fetcherVersion = 4;
            hash = pkgs.lib.fakeHash;
          };

          buildPhase = ''
            runHook preBuild
            pnpm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r dist $out
            runHook postInstall
          '';
        });
      };

      flake.nixosModules.default = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.services.${name};
      in {
        options.services.${name}.enable = lib.mkEnableOption "${name} static site";

        config = lib.mkIf cfg.enable {
          services.caddy = {
            enable = true;
            virtualHosts."http://${config.networking.hostName}".extraConfig = ''
              root * ${self.packages.${pkgs.stdenv.hostPlatform.system}.default}
              file_server
            '';
          };
        };
      };
    };
}
