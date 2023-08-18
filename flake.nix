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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
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
    # Add bpmp-virt flake (main branch implied).
    bpmp-virt.url = "github:juliuskoskela/bpmp-virt";
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
        nixosConfigurations.ghaf-bpmp-virt-test = ghaf.nixosConfigurations.nvidia-jetson-orin-agx-debug.extendModules {
          modules = [
            bpmp-virt.nixosModules.bpmp-virt-host
            {
              ghaf = {
                graphics.weston = {
                  # use nixpkgs.libmkForce to force the priority of conflicting values from ghaf applications.nix and this file
                  #
                  # error: The option `ghaf.graphics.weston.enable' has conflicting definition values:
                  #       - In `/nix/store/10hjscs2lqhg66v5845jh00sg12nsq76-source/modules/profiles/applications.nix': true
                  #       - In `<unknown-file>': false
                  #       Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
                  # (use '--show-trace' to show detailed location information)
                  enable = nixpkgs.lib.mkForce false;
                  enableDemoApplications = nixpkgs.lib.mkForce false;
                };
                profiles.graphics.enable = false;
                windows-launcher.enable = nixpkgs.lib.mkForce false;
              };
            }
          ];
        };
        packages.aarch64-linux.ghaf-bpmp-virt-test = self.nixosConfigurations.ghaf-bpmp-virt-test.config.system.build.${self.nixosConfigurations.ghaf-bpmp-virt-test.config.formatAttr};

        packages.x86_64-linux.ghaf-bpmp-virt-test-flash-script = mkFlashScript {
          inherit nixpkgs jetpack-nixos;
          hostConfiguration = self.nixosConfigurations.ghaf-bpmp-virt-test;
          flash-tools-system = flake-utils.lib.system.x86_64-linux;
        };
      }
    ];
}
