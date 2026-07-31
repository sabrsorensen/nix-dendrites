{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.plex =
    args@{ config, lib, ... }:
    let
      cfg = config.my.plex;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      plexIdentity = lib.attrByPath [ "plex" ] {
        uid = 2104;
        gid = 2096;
      } config.my.media.containerIdentities;
      tautulliIdentity = lib.attrByPath [ "tautulli" ] {
        uid = 2106;
        gid = 2096;
      } config.my.media.containerIdentities;
    in
    {
      options.my.plex.hostName = lib.mkOption {
        type = lib.types.str;
        default = "plex";
        description = "Local hostname published for Plex.";
      };

      config = lib.mkIf config.my.host.services.plex (
        import ./_content.nix (
          args
          // {
            inherit
              cfg
              domain
              plexIdentity
              tautulliIdentity
              toInt
              ;
          }
        )
      );
    };
}
