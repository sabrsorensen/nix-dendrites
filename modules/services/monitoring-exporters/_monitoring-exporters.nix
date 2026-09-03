{ }:
{
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
}
