{
  flake.modules.homeManager."sam-home-creative" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.my.host.features.gui {
        home.packages = with pkgs; [
          gimp3-with-plugins
        ];
      };
    };
}
