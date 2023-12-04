with import <nixpkgs> { }; mkShell.override { stdenv = swift.stdenv; } {
  buildInputs = with swiftPackages;[
    swift
    swiftpm
    Foundation
    darwin.apple_sdk.frameworks.AppKit
  ];
}
