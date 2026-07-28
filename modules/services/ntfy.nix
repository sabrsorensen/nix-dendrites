{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.ntfy =
    { config, lib, ... }:
    let
      cfg = config.my.ntfy;
    in
    {
      options.my.ntfy = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "ntfy";
          description = "Local hostname published for ntfy.";
        };
        baseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional external URL override for ntfy.";
        };
      };

      config = lib.mkIf config.my.host.services.ntfy {
        my.localDns.records = [ { hostname = cfg.hostName; } ];
        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* 127.0.0.1:6839
          ''
        ];
        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = if cfg.baseUrl != null then cfg.baseUrl else "https://${cfg.hostName}.${domain}";
            listen-http = ":6839";
            behind-proxy = true;
            enable-login = true;
            require-login = true;
          };
        };
      };
    };
}
