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

      config = lib.mkIf config.my.host.services.prowlarr (
        import ./_content.nix (args // { inherit cfg; })
      );
    };
}
