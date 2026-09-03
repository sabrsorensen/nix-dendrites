{ ... }:
{
  flake.modules.nixos.bazarr =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.bazarr;
    in
    {
      options.my.bazarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "bazarr";
        description = "Path below the apex domain used for Bazarr.";
      };

      options.my.host.services.bazarr = lib.mkEnableOption "Bazarr media service";
      config = lib.mkIf config.my.host.services.bazarr (import ./_bazarr.nix (args // { inherit cfg; }));
    };
}
