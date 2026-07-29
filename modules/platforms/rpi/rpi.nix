{ lib, ... }:
{
  imports = [ ./_rpi-cache.nix ];

  flake.modules.nixos.platform-rpi =
    { config, lib, ... }:
    {
      config = lib.mkIf (config.my.host.platform == "rpi") {
        nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
        boot.loader.generic-extlinux-compatible.enable = true;
        boot.loader.grub.enable = false;
      };
    };
}
