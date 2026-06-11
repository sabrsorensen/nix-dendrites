{
  flake.modules.homeManager.beets =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        beets
      ];

      xdg.configFile = {
        "beets/config.yaml".source = ./config.yaml;
        "beets/plugins/demlo_compat.py".source = ./plugins/demlo_compat.py;
      };
    };
}
