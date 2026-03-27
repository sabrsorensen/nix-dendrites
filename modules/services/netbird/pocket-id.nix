{
  inputs,
  ...
}:
{
  flake.modules.nixos.pocket-id =
    { config, pkgs, ... }:
    let
      domain = config.systemConstants.domain;
    in
    {
      sops.secrets = {
        pocket-id = {
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/pocket-id.env";
          key = "";
        };
      };

      services = {
        caddy = {
          virtualHosts."auth.{$DOMAIN}" = {
            logFormat = ''
              output stdout
              format console
              level DEBUG
            '';
            extraConfig = ''
              import cors https://auth.{$DOMAIN}
              reverse_proxy http://127.0.0.1:1411
            '';
          };
        };
        pocket-id = {
          enable = true;
          package = pkgs.pocket-id;
          settings = {
            APP_URL = "https://auth.${domain}";
            ANALYTICS_DISABLED = true;
            TRUST_PROXY = true;
          };
          environmentFile = config.sops.secrets.pocket-id.path;
        };
      };
    };
}
