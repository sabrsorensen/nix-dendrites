{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.self.modules.homeManager."graphical-home"
        inputs.self.modules.homeManager.office
        inputs.self.modules.homeManager.vscode
      ];

      config = lib.mkIf config.my.host.features.gui {
        home.packages = with pkgs; [
          bitwarden-desktop
          clementine
          discord
          ferdium
          noson
          p7zip
          plex-desktop
          rclone
          signal-desktop
          stm32cubemx
          vlc
        ];
      };
    };
}
