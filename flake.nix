{
  inputs = {
    devenv.url = "github:cachix/devenv";
  };
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
  outputs = { self, nixpkgs, devenv, flake-utils, }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
          ({ pkgs, config, ... }: {

            languages.nix.enable = true;
            
            pre-commit.hooks = {
                nixpkgs-fmt.enable = true;
                yamllint.enable = true;
            };

            # This is your devenv configuration
            packages = with pkgs; [
              swift
              swiftpm
              swiftPackages.Foundation
              darwin.apple_sdk.frameworks.AppKit
             ];

            
            # https://github.com/NixOS/nix/issues/6677
            enterShell = ''
              export PS1='\n\[\033[1;32m\][nix-shell:\w]\$\[\033[0m\] '
            '';
          })
        ];

        };
  });
}
