{ ... }:
{
  flake.modules.nixos.airsonic =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "airsonic";
      cfg = config.my.airsonic;
      groupName = "media";
      localAddr = "127.0.0.1:4040";
      mediaCfg = config.my.media;
      containerIdentity = lib.attrByPath [ serviceName ] {
        uid = 2101;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      options.my.airsonic.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = serviceName;
        description = "Path below the apex domain used for Airsonic.";
      };

      options.my.host.services.airsonic = lib.mkEnableOption "Airsonic music service";
      config = lib.mkIf config.my.host.services.airsonic (
        import ./_airsonic.nix (
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
