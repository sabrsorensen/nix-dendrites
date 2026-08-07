{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.mealie =
    args@{ config, lib, ... }:
    let
      cfg = config.my.mealie;
    in
    {
      options.my.mealie = {
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
      config = lib.mkIf config.my.host.services.mealie (
        import ./_mealie.nix (args // { inherit cfg domain; })
      );
    };
}
