{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
  };
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
  outputs = { self, nixpkgs, devenv, flake-utils, }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # fully rebuilds the toolchain - not a replacement for nixpkgs.mkShell.override
        pkgs = import nixpkgs {
          inherit system;
          config.replaceStdEnv = { pkgs }: pkgs.swift.stdenv;
        };
      in
      {
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            ({ pkgs, config, ... }: {
              languages.nix.enable = true;

              pre-commit.hooks = {
                nixpkgs-fmt.enable = true;
                yamllint.enable = true;
              };


              # https://github.com/NixOS/nix/issues/6677
              enterShell = ''
                export PS1='\n\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] '
              '';

              packages = with pkgs;[
                swift
                swiftpm
                swiftPackages.Foundation
                darwin.apple_sdk.frameworks.AppKit
              ];
            })
          ];
        };
      });
}
