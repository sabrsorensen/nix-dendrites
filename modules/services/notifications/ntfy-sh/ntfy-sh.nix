{
  flake.modules.nixos.ntfy-sh =
  {
    ...
  }:
  let
    localDomain = readBuildValue "domain.txt";
  in
  {
    services = {
      caddy = {
        virtualHosts."ntfy.{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy /* 127.0.0.1:6839
          '';
        };
      };

      ntfy-sh = {
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