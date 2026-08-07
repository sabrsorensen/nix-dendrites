{
  config,
  lib,
  cfg,
  domain,
  ...
}:
{
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}" = {
    logFormat = ''
      output stdout
      format console
      level DEBUG
    '';
    routes = [
      ''
        reverse_proxy /* 127.0.0.1:${lib.toString config.services.mealie.port}
      ''
    ];
  };
  services.mealie = {
    enable = true;
    listenAddress = "127.0.0.1";
    settings = {
      BASE_URL = if cfg.baseUrl != null then cfg.baseUrl else "https://${cfg.hostName}.${domain}";
      ALLOW_SIGNUP = lib.boolToString cfg.allowSignup;
    };
    extraOptions = [ ];
    credentialsFile = null;
    database.createLocally = true;
  };
}
