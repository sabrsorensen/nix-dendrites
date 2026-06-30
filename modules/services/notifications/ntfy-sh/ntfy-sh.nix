{
  flake.modules.nixos.ntfy-sh =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.ntfy;
      localDomain = config.systemConstants.domain;
      hostName = cfg.hostName;
    in
    {
      options.my.services.ntfy = {
        enable = lib.mkEnableOption "ntfy notification service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "ntfy";
        };

        baseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        my.localDns.records = [
          { hostname = hostName; }
        ];

        my.caddy.virtualHosts."${hostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* 127.0.0.1:6839
          ''
        ];

        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = if cfg.baseUrl != null then cfg.baseUrl else "https://${hostName}.${localDomain}";
            listen-http = ":6839";
            #cache-file = ""
            behind-proxy = true;
            enable-login = true;
            require-login = true;
          };
        };
      };
    };
}
