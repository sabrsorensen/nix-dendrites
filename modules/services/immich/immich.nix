{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.immich =
    args@{ config, lib, ... }:
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
      config = lib.mkIf config.my.host.services.immich (
        import ./_content.nix (args // { inherit cfg domain; })
      );
    };
}
