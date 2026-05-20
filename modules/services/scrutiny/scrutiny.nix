{
  flake.modules.nixos.scrutiny =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  {
    environment.systemPackages = with pkgs; [
      smartmontools
    ];
    services = {
      caddy = {
        virtualHosts."scrutiny.{$DOMAIN}" = {
          extraConfig = ''
            basic_auth /* {
                sorenssa {$SCRUTINY_PASSWORD}
            }
            reverse_proxy /* ${config.services.scrutiny.settings.web.listen.host}:${lib.toString config.services.scrutiny.settings.web.listen.port}
          '';
        };
      };
      # Note: make sure /var/log/smartd exists and is writable by scrutiny
      scrutiny = {
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