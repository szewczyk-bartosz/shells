{
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
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
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [python];
    };
  };
}
