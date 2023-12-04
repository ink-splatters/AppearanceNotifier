{
  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        buildInputs = with pkgs;[
          swift
          swiftpm
          swiftPackages.Foundation
          darwin.apple_sdk.frameworks.AppKit
        ];


      in
      {
        #     packages.default = pkgs.swift.stdenv.buildEnv {
        # 	name="swift shell";
        # 	paths = buildInputs; 
        # };

        packages.default = pkgs.stdenv.mkDerivation rec {
          name = "env";
          inherit buildInputs;
          #env = pkgs.buildEnv { name = name; paths = buildInputs; };
        };

        devShells.default = pkgs.mkShell {
          inherit buildInputs;

        };
      });

}
