{ ... }:
{
  flake.modules.nixos.sonarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.sonarr;
    in
    {
      options.my.sonarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "sonarr";
        description = "Path below the apex domain used for Sonarr.";
      };

      config = lib.mkIf config.my.host.services.sonarr {
        systemd.tmpfiles.rules = [ "d /var/lib/sonarr4k 0750 sonarr media -" ];
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/sonarr/aquamarine.css'></body>"
              }
              reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:8989 {
                header_up -Accept-Encoding
              }
            }
          ''
          ''
            redir /sonarr4k /sonarr4k/
            route /sonarr4k/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/sonarr/aquamarine.css'></body>"
              }
              reverse_proxy /sonarr4k/* 127.0.0.1:8990 {
                header_up -Accept-Encoding
              }
            }
          ''
        ];
        services.sonarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server = {
            urlbase = "/${cfg.pathSegment}";
            port = 8989;
            bindaddress = "127.0.0.1";
          };
        };
        systemd.services.sonarr4k = {
          description = "Sonarr 4K";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.sonarr}/bin/Sonarr -nobrowser -data=/var/lib/sonarr4k/";
            Restart = "always";
            User = "sonarr";
            Group = "media";
          };
        };
      };
    };
}
