{
  flake.modules.homeManager."sam-home-communications" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.my.host.features.gui {
        home.packages = with pkgs; [
          discord
          ferdium
          signal-desktop
        ];
      };
    };
}
