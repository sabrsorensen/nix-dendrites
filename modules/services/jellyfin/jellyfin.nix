{ ... }:
{
  flake.modules.nixos.jellyfin =
    args@{ config, lib, ... }:
    let
      cfg = config.my.jellyfin;
      groupName = "media";
      localAddr = "127.0.0.1:8096";
    in
    {
      options.my.jellyfin.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin";
        description = "Path below the apex domain used for Jellyfin.";
      };

      config = lib.mkIf config.my.host.services.jellyfin (
        import ./_jellyfin.nix (args // { inherit cfg groupName localAddr; })
      );
    };
}
