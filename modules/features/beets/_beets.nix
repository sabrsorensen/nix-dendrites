{ pkgs, ... }:
{
  home.packages = [ pkgs.beets ];
  xdg.configFile = {
    "beets/config.yaml".source = ./assets/config.yaml;
    "beets/plugins/demlo_compat.py".source = ./assets/plugins/demlo_compat.py;
  };
}
