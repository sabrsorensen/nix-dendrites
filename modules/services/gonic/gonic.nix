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

      options.my.host.services.gonic = lib.mkEnableOption "Gonic music service";
      config = lib.mkIf config.my.host.services.gonic (
        import ./_gonic.nix (args // { inherit cfg mediaCfg; })
      );
    };
}
