{ ... }:
{
  flake.modules.nixos.prowlarr =
    { config, lib, ... }:
    let
      cfg = config.my.prowlarr;
    in
    {
      options.my.prowlarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "prowlarr";
        description = "Path below the apex domain used for Prowlarr.";
      };

      config = lib.mkIf config.my.host.services.prowlarr {
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/prowlarr/aquamarine.css'></body>"
              }
              reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:9696 {
                header_up -Accept-Encoding
              }
            }
          ''
        ];
        services.prowlarr = {
          enable = true;
          openFirewall = false;
          settings.server = {
            urlbase = "/${cfg.pathSegment}";
            port = 9696;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };
}
