{ cfg, domain, ... }:
{
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:6839
    ''
  ];
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = if cfg.baseUrl != null then cfg.baseUrl else "https://${cfg.hostName}.${domain}";
      listen-http = ":6839";
      behind-proxy = true;
      enable-login = true;
      require-login = true;
    };
  };
}
