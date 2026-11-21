# modules/services/example/example.nix
{ ... }:
{
  flake.modules.nixos.example =
    args@{ config, lib, ... }:
    let
      cfg = config.my.example;
      port = 8080;
    in
    {
      # Host-specific service data lives beside the service declaration, not
      # in an import helper.
      options.my.example.hostName = lib.mkOption {
        type = lib.types.str;
        default = "example";
        description = "Short hostname published to local DNS and Caddy.";
      };

      options.my.host.services.example = lib.mkEnableOption "Example service";
      config = lib.mkIf config.my.host.services.example (
        import ./_example.nix (args // { inherit cfg port; })
      );
    };
}

# modules/services/example/_example.nix
{ cfg, port, ... }:
{
  services.example = {
    enable = true;
    inherit port;
  };

  # Publication: the service owns its names; the host edge owns the address.
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:${toString port}
    ''
  ];
}
