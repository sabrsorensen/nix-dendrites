{
  flake.modules.nixos.prowlarr =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    bindAddr = "127.0.0.1";
    port = 9696;
    localAddr = "${bindAddr}:${lib.toString port}";
    serviceName = "prowlarr";
  in
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            route /${serviceName}/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></body>"
              }
              reverse_proxy /${serviceName}/* ${localAddr} {
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
            urlbase = "/${serviceName}";
            port = port;
            bindaddress = bindAddr;
          };
        };
      };
    };
  };
}