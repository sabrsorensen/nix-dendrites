{
  flake.modules.nixos.ntfy-sh =
    {
      config,
      lib,
      ...
    }:
    let
      localDomain = config.systemConstants.domain;
    in
    {
      config = lib.mkIf config.my.media.enable {
        my.localDns.records = [
          { hostname = "ntfy"; }
        ];

        my.caddy.virtualHosts."ntfy.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* 127.0.0.1:6839
          ''
        ];

        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = "https://ntfy.${localDomain}";
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
