{
  rootLuksUuid,
  swapLuksUuid,
  ...
}:
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd = {
    availableKernelModules = [
      "dm-crypt"
      "dm-mod"
    ];
    kernelModules = [ "dm-crypt" ];
    luks.devices."luks-${rootLuksUuid}" = {
      device = "/dev/disk/by-uuid/${rootLuksUuid}";
      allowDiscards = true;
    };
    luks.devices."luks-${swapLuksUuid}" = {
      device = "/dev/disk/by-uuid/${swapLuksUuid}";
      allowDiscards = true;
    };
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.buildMachines = [ ];
  nix.distributedBuilds = true;
}
