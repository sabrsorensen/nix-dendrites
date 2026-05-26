{
  flake.modules.nixos.sonarr =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    bindAddr = "127.0.0.1";
    groupName = "media";
    port = 8989;
    port4k = 8990;
    localAddr = "${bindAddr}:${lib.toString port}";
    localAddr4k = "${bindAddr}:${lib.toString port4k}";
    serviceName = "sonarr";
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
            redir /${serviceName}4k /${serviceName}4k/
            route /${serviceName}4k/* {
              filter {
                content_type text/html.*
                search_pattern </body>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></body>"
              }
              reverse_proxy /${serviceName}4k/* ${localAddr4k} {
                  header_up -Accept-Encoding
              }
            }
          '';
        };
      };

      sonarr = {
        enable = true;
        openFirewall = true;
        group = groupName;
        settings = {
          server = {
            urlbase = "/${serviceName}";
            port = port;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };

    users.users.${serviceName}.group = groupName;
    systemd.services.sonarr4k = {
      description = "Sonarr 4K";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sonarr}/bin/Sonarr -nobrowser -data=/var/lib/sonarr4k/";
        Restart = "always";
        User = serviceName;
        Group = groupName;
      };
    };
  };
}