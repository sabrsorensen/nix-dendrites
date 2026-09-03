{ ... }:
{
  flake.modules.nixos.prowlarr =
    args@{ config, lib, ... }:
    let
      cfg = config.my.prowlarr;
    in
    {
      options.my.prowlarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "prowlarr";
        description = "Path below the apex domain used for Prowlarr.";
      };

      options.my.host.services.prowlarr = lib.mkEnableOption "Prowlarr media service";
      config = lib.mkIf config.my.host.services.prowlarr (
        import ./_prowlarr.nix (args // { inherit cfg; })
      );
    };
}
