{
  description = "pnpm + Vite project";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    name = "my-site";
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pnpm = pkgs.pnpm_10.override { nodejs-slim = pkgs.nodejs_26; };
    in {
      devShells.default = pkgs.mkShell {
        packages = [pkgs.nodejs_26 pnpm];
        shellHook = ''
          if [ -n "$WEB_DEV_SHELL" ]; then
            echo "WARNING!!!!"
            echo "ALREADY IN A SHELL"
            echo "WARNING!!!!"
            exit
          fi
          export WEB_DEV_SHELL=1
          echo "${name} dev shell loaded! Run pnpm dev to start the dev server."
        '';
      };

      packages.default = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = name;
        version = "1.0.0";
        src = ./.;

        nativeBuildInputs = with pkgs; [
          nodejs_26
          pnpmConfigHook
          pnpm
        ];

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
    })
    // {
      nixosModules.default = {
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
