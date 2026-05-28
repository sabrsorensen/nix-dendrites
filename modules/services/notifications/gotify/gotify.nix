{
  flake.modules.nixos.gotify =
  {
    config,
    lib,
    ...
  }:
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            import drop_scanners gotify
            redir /gotify /gotify/
            route /gotify/* {
              uri strip_prefix /gotify
              reverse_proxy ${config.services.gotify.environment.GOTIFY_SERVER_LISTENADDR}:${lib.toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
            }
          '';
        };
      };

      gotify = {
        enable = true;
        environment = {
          GOTIFY_SERVER_PORT = 1245;
          GOTIFY_SERVER_LISTENADDR = "127.0.0.1";
          GOTIFY_REGISTRATIONS = "true";
        };
      };
    };
  };
}