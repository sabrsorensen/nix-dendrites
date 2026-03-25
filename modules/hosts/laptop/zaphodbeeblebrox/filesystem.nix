{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.ZaphodBeeblebrox = {
    boot.initrd.luks = {
      devices."crypted" = {
        device = lib.mkForce "/dev/disk/by-uuid/07263516-dd1e-4573-8f95-8c4d81e70f8f";
        allowDiscards = true; # Enable TRIM for SSDs
      };
    };

    imports = lib.optional (inputs ? disko) ./_disko-config.nix;
  };
}
