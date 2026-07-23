{ ... }:
{
  flake.modules.nixos.beets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.musicTagging {
      home-manager.users.sam = {
        home.packages = [ pkgs.beets ];
        xdg.configFile = {
          "beets/config.yaml".source = ./beets/config.yaml;
          "beets/plugins/demlo_compat.py".source = ./beets/plugins/demlo_compat.py;
        };
      };
    };
}
