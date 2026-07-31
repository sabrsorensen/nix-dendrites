{ ... }:
{
  flake.modules.nixos.deluge =
    args@{ config, lib, ... }:
    let
      cfg = config.my.deluge;
      groupName = "media";
      localAddr = "127.0.0.1:8112";
      mediaCfg = config.my.media;
      serviceName = "deluge";
      delugeIdentity = lib.attrByPath [ serviceName ] {
        uid = 2102;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      options.my.deluge.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = serviceName;
        description = "Path below the apex domain used for Deluge.";
      };

      config = lib.mkIf config.my.host.services.deluge (
        import ./_content.nix (
          args
          // {
            inherit
              cfg
              delugeIdentity
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
