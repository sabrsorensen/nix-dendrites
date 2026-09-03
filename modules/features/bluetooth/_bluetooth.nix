{ config, lib }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  environment.persistence = lib.mkIf config.my.host.features.impermanence {
    "/persistent".directories = [ "/var/lib/bluetooth" ];
  };
}
