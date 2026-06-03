{
  flake.modules.nixos.mealie =
  {
    config,
    lib,
    ...
  }:
  let
    localDomain = config.systemConstants.domain;
  in
  {
    my.localDns.records = [
      { hostname = "mealie"; }
    ];

    my.caddy.virtualHosts."mealie.{$DOMAIN}" = {
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
      #openFirewall = true;
      listenAddress = "127.0.0.1";
      settings = {
        BASE_URL = "https://mealie.${localDomain}";
        ALLOW_SIGNUP = "false";
      };
      extraOptions = [];
      credentialsFile = null;
      database.createLocally = true;
    };
  };
}
