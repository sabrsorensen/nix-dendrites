{ ... }:
{
  flake.modules.nixos.gonic =
    args@{ config, lib, ... }:
    let
      cfg = config.my.gonic;
      mediaCfg = config.my.media;
    in
    {
      options.my.gonic.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "gonic";
        description = "Path below the apex domain used for Gonic.";
      };

      config = lib.mkIf config.my.host.services.gonic (
        import ./_content.nix (args // { inherit cfg mediaCfg; })
      );
    };
}
