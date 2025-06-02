# ~/.GH/Qompass/QJP/flake.nix
# ---------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved
{
  description = "QJP - Qompass AI package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.callPackage ./. {};
        qjp = pkgs.callPackage ./. {};
      }
    );

    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          buildInputs = [
          ];
        };
      }
    );
  };
}
