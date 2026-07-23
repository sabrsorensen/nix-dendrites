{ ... }:
{
  flake.modules.nixos.scrutiny =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.scrutiny;
    in
    {
      options.my.scrutiny.hostName = lib.mkOption {
        type = lib.types.str;
        default = "scrutiny";
      };
      config = lib.mkIf config.my.host.services.scrutiny {
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

        services.scrutiny = {
          enable = true;
          openFirewall = false;
          influxdb.enable = true;
          settings.web.listen = {
            host = "127.0.0.1";
            port = 8081;
          };
        };
      };
    };
}
