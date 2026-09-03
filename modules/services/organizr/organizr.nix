{ ... }:
{
  flake.modules.nixos.organizr =
    args@{ config, lib, ... }:
    let
      cfg = config.my.organizr;
      groupName = "media";
      localAddr = "127.0.0.1:81";
      mediaCfg = config.my.media;
      serviceName = "organizr";
      containerIdentity = lib.attrByPath [ serviceName ] {
        uid = 2103;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      options.my.organizr.setAsApexBackend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Route otherwise-unmatched apex requests to Organizr.";
      };

      options.my.host.services.organizr = lib.mkEnableOption "Organizr media dashboard";
      config = lib.mkIf config.my.host.services.organizr (
        import ./_organizr.nix (
          args
          // {
            inherit
              cfg
              containerIdentity
              groupName
              localAddr
              mediaCfg
              serviceName
              ;
          }
        )
      );
    };
}
