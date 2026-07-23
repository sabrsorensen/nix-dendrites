{ ... }:
{
  flake.modules.nixos.radarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.radarr;
    in
    {
      options.my.radarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "radarr";
        description = "Path below the apex domain used for Radarr.";
      };

      config = lib.mkIf config.my.host.services.radarr {
        systemd.tmpfiles.rules = [ "d /var/lib/radarr4k 0750 radarr media -" ];
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/radarr/aquamarine.css'></body>"
              }
              reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:7878 {
                header_up -Accept-Encoding
              }
            }
          ''
          ''
            redir /radarr4k /radarr4k/
            route /radarr4k/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/radarr/aquamarine.css'></body>"
              }
              reverse_proxy /radarr4k/* 127.0.0.1:7879 {
                header_up -Accept-Encoding
              }
            }
          ''
        ];
        services.radarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server = {
            urlbase = "/${cfg.pathSegment}";
            port = 7878;
            bindaddress = "127.0.0.1";
          };
        };
        systemd.services.radarr4k = {
          description = "Radarr 4K";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.radarr}/bin/Radarr -nobrowser -data=/var/lib/radarr4k";
            Restart = "always";
            User = "radarr";
            Group = "media";
          };
        };
      };
    };
}
