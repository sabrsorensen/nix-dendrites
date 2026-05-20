{
  flake.modules.nixos.radarr =
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
            redir /radarr /radarr/
            route /radarr/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/radarr/aquamarine.css'></body>"
              }
              reverse_proxy /radarr/* 127.0.0.1:7878 {
                header_up -Accept-Encoding
              }
            }
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
          '';
        };
      };

      radarr = {
        enable = true;
        openFirewall = true;
        group = "media";
        settings = {
          server = {
            urlbase = "/radarr";
            port = 7878;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };

    users.users.radarr.group = "media";
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
}