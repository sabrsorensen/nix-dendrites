{
  flake.modules.nixos.ntfy-sh =
    {
      config,
      ...
    }:
    let
      localDomain = config.systemConstants.domain;
    in
    {
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
}
