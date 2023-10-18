# Bpmp Virtualization Test Build

This repository contains a simple test for building a downstream derivation of the Ghaf system for Nvidia Jetson Orin Agx with bpmp virtualization enabled.

1. Build (on x86 platform for Linux Tegra). Requires a build configuration that can build for Linux Tegra (arm).

```
nix build .#packages.x86_64-linux.ghaf-bpmp-virt-test-flash-script
```

2. Shut down Jetson, press down middle button and put back power.

3. Run flash script.

```
sudo bash result/bin/flash-ghaf
```
