{ ... }:
{
  flake.modules.nixos.bazarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.bazarr;
    in
    {
      options.my.bazarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "bazarr";
        description = "Path below the apex domain used for Bazarr.";
      };

      config = lib.mkIf config.my.host.services.bazarr {
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/bazarr/aquamarine.css'></head>"
              }
              reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:6767 {
                header_up -Accept-Encoding
              }
            }
          ''
          ''
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
          ''
        ];
        services.bazarr = {
          enable = true;
          openFirewall = false;
          listenPort = 6767;
          group = "media";
        };
        systemd.services.bazarr4k = {
          description = "Bazarr 4K";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.bazarr}/bin/bazarr -c=/var/lib/bazarr4k --port=6768";
            Restart = "always";
            User = "bazarr";
            Group = "media";
            KillSignal = "SIGINT";
          };
        };
      };
    };
}
