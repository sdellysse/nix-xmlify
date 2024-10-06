{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
  };

  outputs =
    { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        functions = import ./functions.nix { nixpkgsLib = nixpkgs.lib; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.git ];
        };

        xmlify = functions.xmlify;
      }
    );
}
