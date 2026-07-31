{
  cfg,
  config,
  lib,
  pathSegment,
  ...
}:
{
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
}
