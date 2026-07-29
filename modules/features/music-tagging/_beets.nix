{ ... }:
{
  flake.modules.nixos.beets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.musicTagging.beets.enable && config.my.host.home.enable) {
      home-manager.users.sam = {
        home.packages = [ pkgs.beets ];
        xdg.configFile = {
          "beets/config.yaml".source = ./beets/config.yaml;
          "beets/plugins/demlo_compat.py".source = ./beets/plugins/demlo_compat.py;
        };
      };
    };
}
