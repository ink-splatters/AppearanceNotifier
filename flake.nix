{
  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell.override { stdenv = pkgs.swift.stdenv; } {
          buildInputs = with pkgs;[
            swift
            swiftpm
            swiftPackages.Foundation
            darwin.apple_sdk.frameworks.AppKit
          ];

          # https://github.com/NixOS/nix/issues/6677
          shellHook = ''
            export PS1='\n\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] '
          '';
        };
      });
}