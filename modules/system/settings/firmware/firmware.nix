{
  flake.modules.nixos.firmware = {
    services.fwupd.enable = true;
    hardware = {
      enableAllFirmware = true;
      enableRedistributableFirmware = true;
    };
    nixpkgs.config.allowUnfree = true; # enableAllFirmware depends on this
  };
}
