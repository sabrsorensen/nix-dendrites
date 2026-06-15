{
  lib,
  rootLuksUuid,
  ...
}:
{
  boot.initrd.luks = {
    devices."crypted" = {
      device = lib.mkForce "/dev/disk/by-uuid/${rootLuksUuid}";
      allowDiscards = true; # Enable TRIM for SSDs
    };
  };

  imports = [ ./disko-config.nix ];
}
