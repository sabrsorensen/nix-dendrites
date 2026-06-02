{
  flake.modules.nixos.mealie =
  {
    config,
    lib,
    ...
  }:
  let
    readBuildValue =
      path:
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
    localDomain = readBuildValue "domain.txt";
  in
  {
    services = {
      caddy = {
        virtualHosts."mealie.{$DOMAIN}" = {
          logFormat = ''
            output stdout
            format console
            level DEBUG
          '';
          extraConfig = ''
            reverse_proxy /* 127.0.0.1:${lib.toString config.services.mealie.port}
          '';
        };
      };
      mealie = {
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
  };
}