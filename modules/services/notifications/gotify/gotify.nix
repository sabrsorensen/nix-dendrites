{
  flake.modules.nixos.gotify =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.gotify;
      pathSegment = cfg.pathSegment;
    in
    {
      options.my.services.gotify = {
        enable = lib.mkEnableOption "Gotify notification service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "gotify";
        };

        allowRegistrations = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        my.caddy.apexRoutes = [
          ''
            import drop_scanners ${pathSegment}
            redir /${pathSegment} /${pathSegment}/
            route /${pathSegment}/* {
              uri strip_prefix /${pathSegment}
              reverse_proxy ${config.services.gotify.environment.GOTIFY_SERVER_LISTENADDR}:${lib.toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
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
