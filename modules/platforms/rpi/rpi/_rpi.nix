{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;
}
