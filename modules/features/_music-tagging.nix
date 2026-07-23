{ inputs, ... }:
{
  flake.modules.nixos.music-tagging =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mediaConsumer =
        config.my.host.services.airsonic || config.my.host.services.gonic || config.my.host.services.plex;
      package = inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    lib.mkMerge [
      (lib.mkIf mediaConsumer {
        environment.systemPackages = [ package ];
      })
      (lib.mkIf config.my.host.features.musicTagging {
        home-manager.users.sam = {
          home.packages = [
            pkgs.beets
            package
          ];
          xdg.configFile = {
            "beets/config.yaml".source = ../assets/beets/config.yaml;
            "beets/plugins/demlo_compat.py".source = ../assets/beets/plugins/demlo_compat.py;
            "demlo/config.lua".source = ../assets/demlo/config.lua;
            "demlo/scripts/60-path.lua".source = ../assets/demlo/scripts/60-path.lua;
            "demlo/scripts/70-cover.lua".source = ../assets/demlo/scripts/70-cover.lua;
            "demlo/scripts/10-tag-normalize.lua".source = ../assets/demlo/scripts/10-tag-normalize.lua;
            "demlo/scripts/30-tag-case.lua".source = ../assets/demlo/scripts/30-tag-case.lua;
          };
        };
      })
    ];
}
