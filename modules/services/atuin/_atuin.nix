{
  config,
  lib,
  cfg,
  ...
}:
{
  my.caddy =
    if cfg.siteHostName == null then
      {
        apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            reverse_proxy /${cfg.pathSegment}/* ${config.services.atuin.host}:${toString config.services.atuin.port}
          ''
        ];
      }
    else
      {
        virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
          "reverse_proxy /* ${config.services.atuin.host}:${toString config.services.atuin.port}"
        ];
      };
  my.localDns.records = lib.optional (cfg.siteHostName != null) { hostname = cfg.siteHostName; };
  services.atuin = {
    enable = true;
    host = "127.0.0.1";
    port = 8888;
    openFirewall = true;
    openRegistration = cfg.openRegistration;
    path = "/${cfg.pathSegment}/";
  };
}
