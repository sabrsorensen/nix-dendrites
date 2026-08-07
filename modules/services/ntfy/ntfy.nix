{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.ntfy =
    args@{ config, lib, ... }:
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

      config = lib.mkIf config.my.host.services.ntfy (
        import ./_ntfy.nix (args // { inherit cfg domain; })
      );
    };
}
