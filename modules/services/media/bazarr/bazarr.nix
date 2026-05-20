{
  flake.modules.nixos.bazarr =
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
            redir /bazarr /bazarr/
            route /bazarr/* {
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/bazarr/aquamarine.css'></head>"
              }
              reverse_proxy /bazarr/* 127.0.0.1:${lib.toString config.services.bazarr.listenPort} {
                header_up -Accept-Encoding
              }
            }
            redir /bazarr4k /bazarr4k/
            route /bazarr4k/* {
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/bazarr/aquamarine.css'></head>"
              }
              reverse_proxy /bazarr4k/* 127.0.0.1:6768 {
                header_up -Accept-Encoding
              }
            }
          '';
        };
      };

      bazarr = {
        enable = true;
        openFirewall = true;
        listenPort = 6767;
        group = "media";
      };
    };

    users.users.sonarr.group = "media";
    systemd.services.bazarr4k = {
      description = "Bazarr 4K";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.bazarr}/bin/bazarr -c=/var/lib/bazarr4k --port=6768";
        KillSignal="SIGINT";
        Restart = "always";
        User = "bazarr";
        Group = "media";
      };
    };
  };
}