{ inputs, ... }:
let
  localDomain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.profilarr =
    args@{ config, lib, ... }:
    let
      serviceName = "profilarr";
      cfg = config.my.profilarr;
      groupName = "media";
      localAddr = "127.0.0.1:6868";
      mediaCfg = config.my.media;
      containerIdentity = lib.attrByPath [ serviceName ] {
        uid = 2105;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      options.my.profilarr = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
          description = "Local hostname published for Profilarr.";
        };
        origin = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional public URL override for Profilarr.";
        };
      };

      config = lib.mkIf config.my.host.services.profilarr (
        import ./_profilarr.nix (
          args
          // {
            inherit
              cfg
              containerIdentity
              groupName
              localAddr
              localDomain
              mediaCfg
              serviceName
              ;
          }
        )
      );
    };
}
