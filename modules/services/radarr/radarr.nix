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

      config = lib.mkIf config.my.host.services.radarr (import ./_content.nix (args // { inherit cfg; }));
    };
}
