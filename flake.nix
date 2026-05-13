{
  description = "Scan for Syncthing file conflicts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          ...
        }:
        let
          buildInputs = with pkgs; [
            bats
            fd
            findutils
            shellcheck
          ];
        in
        {
          checks.default = pkgs.stdenv.mkDerivation {
            name = "syncthing-resolve-conflicts-tests";
            src = ./.;
            nativeBuildInputs = buildInputs;
            dontConfigure = true;
            dontBuild = true;
            doCheck = true;
            checkPhase = "bats test/";
            installPhase = "touch $out";
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = buildInputs;
          };
        };
      flake = { };
    };
}
