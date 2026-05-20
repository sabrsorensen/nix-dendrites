{
  flake.modules.nixos.mealie =
  {
    config,
    lib,
    ...
  }:
  let
    localDomain = readBuildValue "domain.txt";
  in
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /mealie /mealie/
            reverse_proxy /mealie/* 127.0.0.1:${lib.toString config.services.mealie.port}
          '';
        };
      };
      mealie = {
        enable = true;
        #openFirewall = true;
        listenAddress = "127.0.0.1";
        settings = {
          BASE_URL = "https://mealie.${localDomain}";
          ALLOW_SIGNUP = false;
        };
        extraOptions = {};
        credentialsFile = "";
        database.createLocally = true;
      };
    };
  };
}