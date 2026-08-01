{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.hawkbit =
    args@{ config, lib, ... }:
    let
      cfg = config.my.hawkbit;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      hawkbitIdentity = lib.attrByPath [ "hawkbit" ] {
        uid = 2201;
        gid = 2096;
      } config.my.media.containerIdentities;
    in
    {
      options.my.hawkbit.hostName = lib.mkOption {
        type = lib.types.str;
        default = "hawkbit";
        description = "Local hostname published for hawkBit.";
      };

      config = lib.mkIf config.my.host.services.hawkbit (
        import ./_content.nix (
          args
          // {
            inherit
              cfg
              domain
              hawkbitIdentity
              toInt
              ;
          }
        )
      );
    };
}
