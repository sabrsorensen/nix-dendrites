{
  flake.modules.homeManager."sam-home-media-clients" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.my.host.features.gui {
        home.packages = with pkgs; [
          clementine
          noson
          plex-desktop
          vlc
        ];
      };
    };
}
