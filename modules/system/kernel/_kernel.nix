{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Repo-wide kernel default. Priority 900 outranks input mkDefaults (1000),
  # e.g. nixos-hardware's raspberry-pi-4 linux_rpi kernel, which is not in any
  # binary cache and turns routine changes into a multi-hour local build.
  # A host overrides it with a plain `boot.kernelPackages` definition in its
  # hosts/<host>/hardware payload. Steam Deck keeps Jovian's Valve kernel.
  # See "Kernel selection" in docs/architecture.md.
  boot.kernelPackages = lib.mkIf (config.my.host.platform != "steamdeck") (
    lib.mkOverride 900 pkgs.linuxPackages_latest
  );
}
