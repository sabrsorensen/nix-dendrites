{
  flake.modules.nixos.scrutiny =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.scrutiny;
    in
    {
      options.my.services.scrutiny = {
        enable = lib.mkEnableOption "Scrutiny SMART monitoring service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "scrutiny";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          smartmontools
        ];

        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];

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
            };
          };
        };
      };
    };
}
