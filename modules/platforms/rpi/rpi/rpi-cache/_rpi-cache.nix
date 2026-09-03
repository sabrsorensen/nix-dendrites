{ ... }:
{
  flake.modules.nixos.rpi-cache =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.is.rpi {
      # The generic aarch64 Nixpkgs kernel is available from cache.nixos.org.
      # Do not select nixos-hardware's downstream linux_rpi kernel here: it is
      # not consistently cached and turns ordinary DNS changes into a kernel build.
      # This outranks nixos-hardware's Pi-kernel mkDefault while retaining all
      # of its firmware, device-tree, and boot-loader defaults.
      boot.kernelPackages = lib.mkOverride 900 pkgs.linuxPackages;
    };
}
