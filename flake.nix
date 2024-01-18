# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "Bpmp Virtualization Test - Ghaf based configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    flake-utils.url = "github:numtide/flake-utils";

    jetpack-nixos = {
      url = "github:anduril/jetpack-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghaf = {
      url = "github:tiiuae/ghaf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        jetpack-nixos.follows = "jetpack-nixos";
      };
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    ghaf,
    nixpkgs,
    jetpack-nixos,
    flake-utils,
    microvm,
  }: let
    system = "aarch64-linux";
    mkFlashScript = import (ghaf + "/lib/mk-flash-script");
    pkgs = import nixpkgs {inherit system;};
    config = self.nixosConfigurations.ghaf-bpmp-virt-test.config;
  in {
    nixosConfigurations.ghaf-bpmp-virt-test = ghaf.nixosConfigurations.nvidia-jetson-orin-agx-debug-nodemoapps.extendModules {
      modules = [
        (import ./modules/uarta-vm.nix {inherit pkgs config microvm jetpack-nixos;})
      ];
    };

    packages.aarch64-linux.ghaf-bpmp-virt-test = self.nixosConfigurations.ghaf-bpmp-virt-test.config.system.build.${self.nixosConfigurations.ghaf-bpmp-virt-test.config.formatAttr};

    packages.x86_64-linux.ghaf-bpmp-virt-test-flash-script = mkFlashScript {
      inherit nixpkgs jetpack-nixos;
      hostConfiguration = self.nixosConfigurations.ghaf-bpmp-virt-test;
      flash-tools-system = flake-utils.lib.system.x86_64-linux;
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
