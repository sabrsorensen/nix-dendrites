{ ... }:
{
  flake.modules.nixos.bluetooth =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.bluetooth {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      environment.persistence = lib.mkIf config.my.host.features.impermanence {
        "/persistent".directories = [ "/var/lib/bluetooth" ];
      };
    };
}
