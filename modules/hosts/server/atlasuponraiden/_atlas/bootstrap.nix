{
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./filesystem.nix
    ./network.nix
    inputs.self.modules.nixos.systemd-boot
    inputs.self.modules.nixos.disko
  ];

  services.btrfs.autoScrub.enable = lib.mkForce false;
}
