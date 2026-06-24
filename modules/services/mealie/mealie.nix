{
  flake.modules.nixos.mealie =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.mealie;
      localDomain = config.systemConstants.domain;
      baseUrl = if cfg.baseUrl != null then cfg.baseUrl else "https://${cfg.hostName}.${localDomain}";
    in
    {
      options.my.services.mealie = {
        enable = lib.mkEnableOption "Mealie recipe service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "mealie";
        };

        allowSignup = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        baseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];

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
          #openFirewall = true;
          listenAddress = "127.0.0.1";
          settings = {
            BASE_URL = baseUrl;
            ALLOW_SIGNUP = lib.boolToString cfg.allowSignup;
          };
          extraOptions = [ ];
          credentialsFile = null;
          database.createLocally = true;
        };
      };
    };
}
