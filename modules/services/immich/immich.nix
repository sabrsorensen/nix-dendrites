{
  flake.modules.nixos.immich =
    { config, lib, ... }:
    let
      cfg = config.my.services.immich;
      localDomain = config.systemConstants.domain;
      externalDomain =
        if cfg.externalDomain != null then
          cfg.externalDomain
        else
          "https://${cfg.hostName}.${localDomain}/";
    in
    {
      options.my.services.immich = {
        enable = lib.mkEnableOption "Immich photo service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "immich";
        };

        mediaLocation = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        externalDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.mediaLocation != null;
            message = "my.services.immich.mediaLocation must be set when Immich is enabled.";
          }
        ];

        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];

        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
          ''
        ];

        services.immich = {
          enable = true;
          port = 2283;
          host = "127.0.0.1";
          openFirewall = true;
          mediaLocation = cfg.mediaLocation;
          settings.server.externalDomain = externalDomain;
        };
      };
    };
}
