{
  cfg,
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.smartmontools ];
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      basic_auth /* {
          sorenssa {$SCRUTINY_PASSWORD}
      }
      reverse_proxy /* ${config.services.scrutiny.settings.web.listen.host}:${lib.toString config.services.scrutiny.settings.web.listen.port}
    ''
  ];
  # Note: make sure /var/log/smartd exists and is writable by scrutiny
  services.scrutiny = {
    enable = true;
    openFirewall = false;
    influxdb.enable = true;
    settings = {
      web.listen = {
        host = "127.0.0.1";
        port = 8081;
      };
    };
  };
}
