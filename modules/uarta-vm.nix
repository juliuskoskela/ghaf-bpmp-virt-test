{
  pkgs,
  config,
  microvm,
  jetpack-nixos,
  ...
}: {
  microvm.vms.uarta-vm = {
    inherit pkgs;

    config = {
      boot.kernelPackages = config.boot.kernelPackages;

      nixpkgs.overlays = [
        (_final: prev: {
          makeModulesClosure = x:
            prev.makeModulesClosure (x // {allowMissing = true;});
        })
      ];

      microvm = {
        hypervisor = "qemu";

        shares = [
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];
      };

      users.users.root.password = "root";

      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };

      system.stateVersion = "23.11";
    };
  };
}
