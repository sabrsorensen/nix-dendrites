{ config, lib }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  environment.persistence = lib.mkIf config.my.host.features.persistenceBluetooth {
    "/persistent".directories = [ "/var/lib/bluetooth" ];
  };
}
