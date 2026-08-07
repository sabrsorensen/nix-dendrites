{
  config,
  cfg,
  domain,
  ...
}:
{
  assertions = [
    {
      assertion = cfg.mediaLocation != null;
      message = "my.immich.mediaLocation must be set when Immich is enabled.";
    }
  ];
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
    ''
  ];
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    openFirewall = true;
    mediaLocation = cfg.mediaLocation;
    settings.server.externalDomain =
      if cfg.externalDomain != null then cfg.externalDomain else "https://${cfg.hostName}.${domain}/";
  };
}
