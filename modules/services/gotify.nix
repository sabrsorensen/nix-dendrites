{ ... }:
{
  flake.modules.nixos.gotify =
    { config, lib, ... }:
    let
      cfg = config.my.gotify;
    in
    {
      options.my.gotify = {
        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "gotify";
          description = "Path below the apex domain used for Gotify.";
        };
        allowRegistrations = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Allow Gotify users to register themselves.";
        };
      };

      config = lib.mkIf config.my.host.services.gotify {
        my.caddy.apexRoutes = [
          ''
            import drop_scanners ${cfg.pathSegment}
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              uri strip_prefix /${cfg.pathSegment}
              reverse_proxy ${config.services.gotify.environment.GOTIFY_SERVER_LISTENADDR}:${toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
            }
          ''
        ];
        services.gotify = {
          enable = true;
          environment = {
            GOTIFY_SERVER_PORT = 1245;
            GOTIFY_SERVER_LISTENADDR = "127.0.0.1";
            GOTIFY_REGISTRATIONS = lib.boolToString cfg.allowRegistrations;
          };
        };
      };
    };
}
