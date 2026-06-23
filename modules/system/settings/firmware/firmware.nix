{
  flake.modules.nixos.firmware =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.firmware {
      services.fwupd.enable = true;
      hardware = {
        enableAllFirmware = true;
        enableRedistributableFirmware = true;
      };
      nixpkgs.config.allowUnfree = true; # enableAllFirmware depends on this
    };
}
