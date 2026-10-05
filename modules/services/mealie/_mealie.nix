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
  # nltk's import-time Downloader() raises "Could not find a default download
  # directory" when ~ can't be expanded, which kills init_db under the
  # upstream module's DynamicUser (no HOME, no resolvable passwd home).
  systemd.services.mealie.environment.HOME = "/var/lib/mealie";
  warnings = [
    ''
      services.mealie: setting HOME=/var/lib/mealie on mealie.service so nltk
      can import under DynamicUser (upstream nixos/modules/services/web-apps/
      mealie.nix sets no HOME; init_db otherwise dies with "ValueError: Could
      not find a default download directory"). Remove the override in
      modules/services/mealie/_mealie.nix once upstream sets HOME -- check with:
        grep -n HOME "$(nix eval --raw .#nixosConfigurations.atlasuponraiden.pkgs.path)/nixos/modules/services/web-apps/mealie.nix"
    ''
  ];
}
