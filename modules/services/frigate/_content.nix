{
  lib,
  cfg,
  nginxPort,
  publicHost,
  ...
}:
{
  assertions = [
    {
      assertion = cfg.siteHostName != null;
      message = "Frigate requires my.frigate.siteHostName for dedicated Caddy-subdomain publication.";
    }
    {
      assertion = cfg.pathSegment == null;
      message = "Frigate supports only its dedicated Caddy subdomain, not apex-path publication.";
    }
  ];
  my.caddy.virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:${toString nginxPort}
    ''
  ];
  my.localDns.records = [ { hostname = cfg.siteHostName; } ];
  services.nginx.virtualHosts.${publicHost}.listen = lib.mkForce [
    {
      addr = "127.0.0.1";
      port = nginxPort;
    }
  ];
  services.frigate = {
    enable = true;
    hostname = publicHost;
    settings = { };
  };
}
