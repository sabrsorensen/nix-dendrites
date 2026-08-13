{ ... }:
{
  flake.modules.nixos.radarr =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.radarr;
    in
    {
      options.my.radarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "radarr";
        description = "Path below the apex domain used for Radarr.";
      };

      options.my.host.services.radarr = lib.mkEnableOption "Radarr media service";
      config = lib.mkIf config.my.host.services.radarr (import ./_radarr.nix (args // { inherit cfg; }));
    };
}
