{ luksUuid, ... }:
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-${luksUuid}".device = "/dev/disk/by-uuid/${luksUuid}";
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.buildMachines = [ ];
  nix.distributedBuilds = true;
}
