{ ... }:
{
  flake.modules.nixos.sonarr =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.sonarr;
    in
    {
      options.my.sonarr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "sonarr";
        description = "Path below the apex domain used for Sonarr.";
      };

      config = lib.mkIf config.my.host.services.sonarr (import ./_sonarr.nix (args // { inherit cfg; }));
    };
}
