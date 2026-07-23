{ ... }:
{
  flake.modules.nixos.rpi-dns-monitoring =
    { config, lib, ... }:
    lib.mkIf (config.my.host.is.rpi && config.my.host.services.blocky) {
      services.prometheus.exporters.node = {
        enable = true;
        listenAddress = "0.0.0.0";
        openFirewall = true;
        enabledCollectors = [
          "hwmon"
          "systemd"
        ];
      };

      services.prometheus.exporters.smartctl = {
        enable = true;
        listenAddress = "0.0.0.0";
        openFirewall = true;
      };
    };
}
