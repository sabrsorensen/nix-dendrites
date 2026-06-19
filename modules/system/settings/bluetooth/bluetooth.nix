{ ... }:
{

  flake.modules.nixos.bluetooth =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.bluetooth {
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
    };
}
