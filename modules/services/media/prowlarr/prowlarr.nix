{
  flake.modules.nixos.prowlarr =
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
            redir /prowlarr /prowlarr/
            route /prowlarr/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/prowlarr/aquamarine.css'></body>"
              }
              reverse_proxy /prowlarr/* ${config.services.prowlarr.settings.server.bindaddress}:${lib.toString config.services.prowlarr.settings.server.port} {
                header_up -Accept-Encoding
              }
            }
          '';
        };
      };

      prowlarr = {
        enable = true;
        openFirewall = true;
        settings = {
          server = {
            urlbase = "/prowlarr";
            port = 9696;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };
  };
}