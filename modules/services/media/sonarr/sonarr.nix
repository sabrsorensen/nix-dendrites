{
  flake.modules.nixos.sonarr =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /sonarr /sonarr/
            route /sonarr/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/sonarr/aquamarine.css'></body>"
              }
              reverse_proxy /sonarr/* 127.0.0.1:8989 {
                  header_up -Accept-Encoding
              }
            }
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
          '';
        };
      };

      sonarr = {
        enable = true;
        openFirewall = true;
        group = "media";
        settings = {
          server = {
            urlbase = "/sonarr";
            port = 8989;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };

    users.users.sonarr.group = "media";
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
}