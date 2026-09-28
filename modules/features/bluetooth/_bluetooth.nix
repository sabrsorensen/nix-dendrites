{ config, lib }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  environment.persistence = lib.mkIf (
    config.my.host.features.persistenceSystem && !config.my.host.persistence.varOnOwnSubvolumes
  ) { "/persist".directories = [ "/var/lib/bluetooth" ]; };
}
