# ~/.GH/Qompass/QJP/flake.nix
# ---------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved
{
  description = "QJP - Qompass AI JetPack";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    hardwareConfigs = {
      orin-agx-devkit = { som = "orin-agx"; carrierBoard = "devkit"; };
      orin-nx-devkit = { som = "orin-nx"; carrierBoard = "devkit"; };
      orin-nano-devkit = { som = "orin-nano"; carrierBoard = "devkit"; };
      orin-nx-devkit-super = { som = "orin-nx"; carrierBoard = "devkit"; super = true; };
      orin-nano-devkit-super = { som = "orin-nano"; carrierBoard = "devkit"; super = true; };
    };
    platformConfigs = {
      aarch64_native = {
        nixpkgs = {
          buildPlatform = "aarch64-linux";
          hostPlatform = "aarch64-linux";
        };
      };
      aarch64_cross = {
        nixpkgs = {
          buildPlatform = "x86_64-linux";
          hostPlatform = "aarch64-linux";
        };
      };
    };
    baseInstallerConfig = {
      imports = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        self.nixosModules.default
      ];
      disabledModules = ["profiles/all-hardware.nix"];
      hardware.nvidia-jetpack.enable = true;
    };
    mkPackagesForSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      supportedNixOSConfigurations = lib.mapAttrs (name: config:
        (nixpkgs.lib.nixosSystem {
          modules = [
            platformConfigs.aarch64_cross
            self.nixosModules.default
            {
              hardware.nvidia-jetpack = {enable = true;} // config;
              networking.hostName = "${config.som}-${config.carrierBoard}";
            }
          ];
        }).config
      ) hardwareConfigs;
      genScripts = scriptType: prefix:
        lib.mapAttrs' (name: config: 
          lib.nameValuePair "${prefix}-${name}" 
          config.system.build.${scriptType}
        ) supportedNixOSConfigurations;
    in if system == "x86_64-linux" then {
      iso_minimal = self.nixosConfigurations.installer_minimal_cross.config.system.build.isoImage;
      inherit (self.legacyPackages.${system})
        board-automation
        python-jetson;
      inherit (self.legacyPackages.${system}.cudaPackages)
        nsight_systems_host
        nsight_compute_host;
    } // genScripts "flashScript" "flash"
      // genScripts "initrdFlashScript" "initrd-flash" 
      // genScripts "uefiCapsuleUpdate" "uefi-capsule-update"
    else if system == "aarch64-linux" then {
      iso_minimal = self.nixosConfigurations.installer_minimal.config.system.build.isoImage;
    } else {};
    mkLegacyPackages = system: let
      basePackages = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaCapabilities = ["7.2" "8.7"];
          cudaSupport = true;
        };
        overlays = [
          self.overlays.default
          (final: prev: {
            inherit (final.nvidia-jetpack) cudaPackages;
            opencv4 = prev.opencv4.override {inherit (final) cudaPackages;};
          })
        ];
      };
    in basePackages.nvidia-jetpack;
  in {
    nixosConfigurations = {
      installer_minimal = nixpkgs.lib.nixosSystem {
        modules = [platformConfigs.aarch64_native baseInstallerConfig];
      };
      installer_minimal_cross = nixpkgs.lib.nixosSystem {
        modules = [platformConfigs.aarch64_cross baseInstallerConfig];
      };
    };
    nixosModules.default = import ./modules/default.nix;
    overlays.default = import ./overlay.nix;
    packages = lib.genAttrs supportedSystems mkPackagesForSystem;
    checks = lib.genAttrs supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatting = pkgs.runCommand "repo-formatting" {
        nativeBuildInputs = with pkgs; [nixpkgs-fmt];
      } ''
        nixpkgs-fmt --check ${self} && touch $out
      '';
      flake-check = pkgs.runCommand "flake-check" {
        nativeBuildInputs = with pkgs; [nix];
      } ''
        nix flake check ${self} && touch $out
      '';
    });
    formatter = lib.genAttrs supportedSystems (system: 
      nixpkgs.legacyPackages.${system}.nixpkgs-fmt
    );
    legacyPackages = lib.genAttrs supportedSystems mkLegacyPackages;
    devShells = lib.genAttrs supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "qjp-dev";
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nix-tree
          nvd
          nix-diff
          alejandra
        ];
        shellHook = ''
          echo "🚀 QJP Development Environment"
          echo "📦 Available commands:"
          echo "  - nixpkgs-fmt: Format Nix files"
          echo "  - nix flake check: Validate flake"
          echo "  - nix build .#<package>: Build packages"
        '';
      };
    });
    apps = lib.genAttrs supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      format = {
        type = "app";
        program = "${pkgs.writeShellScript "format" ''
          ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt .
        ''}";
      };
      update = {
        type = "app";
        program = "${pkgs.writeShellScript "update" ''
          nix flake update && nix flake check
        ''}";
      };
    });
    hydraJobs = {
      inherit (self) packages checks devShells;
      nixosConfigurations = lib.mapAttrs (_: config: config.config.system.build.toplevel) 
        self.nixosConfigurations;
    };
  };
}
