{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.frigate =
    args@{ config, lib, ... }:
    let
      cfg = config.my.frigate;
      nginxPort = 8972;
      publicHost = "${cfg.siteHostName}.${domain}";
    in
    {
      options.my.frigate = {
        pathSegment = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Unsupported legacy path publication setting; keep null for a dedicated Frigate hostname.";
        };
        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "frigate";
          description = "Dedicated local and public hostname for Frigate.";
        };
      };

      config = lib.mkIf config.my.host.services.frigate (
        import ./_content.nix (args // { inherit cfg nginxPort publicHost; })
      );
    };
}
