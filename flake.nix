# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "Ghafderi - Ghaf based configuration";

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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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
    bpmp-virt = {
      url = "github:juliuskoskela/bpmp-virt";
    };
  };

  outputs = {
    self,
    ghaf,
    nixpkgs,
    jetpack-nixos,
    flake-utils,
    bpmp-virt,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
    mkFlashScript = import (ghaf + "/lib/mk-flash-script.nix");
  in
    # Combine list of attribute sets together
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      (flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))

      {
        nixosConfigurations.ghafderi-ghaf-debug = ghaf.nixosConfigurations.nvidia-jetson-orin-agx-debug.extendModules {
          modules = [
            bpmp-virt.nixosModules.bpmp-virt-host
          ];
        };
        packages.aarch64-linux.ghafderi-ghaf-debug = self.nixosConfigurations.ghafderi-ghaf-debug.config.system.build.${self.nixosConfigurations.ghafderi-ghaf-debug.config.formatAttr};

        packages.x86_64-linux.ghafderi-ghaf-debug-flash-script = mkFlashScript {
          inherit nixpkgs jetpack-nixos;
          hostConfiguration = self.nixosConfigurations.ghafderi-ghaf-debug;
          flash-tools-system = flake-utils.lib.system.x86_64-linux;
        };
      }
    ];
}
