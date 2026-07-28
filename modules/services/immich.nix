{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.immich =
    { config, lib, ... }:
    let
      cfg = config.my.immich;
    in
    {
      options.my.immich = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "immich";
        };
        externalDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        mediaLocation = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Immich media storage path for this host.";
        };
      };
      config = lib.mkIf config.my.host.services.immich {
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
      };
    };
}
