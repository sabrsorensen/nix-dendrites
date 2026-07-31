{ ... }:
{
  flake.modules.nixos.beets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf (config.my.host.features.beets && config.my.host.home.enable) {
      home-manager.users.${username} = {
        home.packages = [ pkgs.beets ];
        xdg.configFile = {
          "beets/config.yaml".source = ./assets/config.yaml;
          "beets/plugins/demlo_compat.py".source = ./assets/plugins/demlo_compat.py;
        };
      };
    };
}
