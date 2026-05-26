{
  flake.modules.nixos.bazarr =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    groupName = "media";
    listenPort = 6767;
    listenPort4k = 6768;
    localAddr = "127.0.0.1:${lib.toString listenPort}";
    localAddr4k = "127.0.0.1:${lib.toString listenPort4k}";
    serviceName = "bazarr";
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
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></head>"
              }
              reverse_proxy /${serviceName}/* ${localAddr} {
                header_up -Accept-Encoding
              }
            }
            redir /${serviceName}4k /${serviceName}4k/
            route /${serviceName}4k/* {
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></head>"
              }
              reverse_proxy /${serviceName}4k/* ${localAddr4k} {
                header_up -Accept-Encoding
              }
            }
          '';
        };
      };

      bazarr = {
        enable = true;
        openFirewall = true;
        listenPort = listenPort;
        group = groupName;
      };
    };

    users.users."${serviceName}".group = "media";
    systemd.services."${serviceName}4k" = {
      description = "Bazarr 4K";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.bazarr}/bin/bazarr -c=/var/lib/bazarr4k --port=${lib.toString listenPort4k}";
        KillSignal="SIGINT";
        Restart = "always";
        User = serviceName;
        Group = groupName;
      };
    };
  };
}