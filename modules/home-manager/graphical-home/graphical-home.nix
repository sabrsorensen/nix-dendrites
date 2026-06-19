{
  inputs,
  ...
}:
{
  flake.modules.homeManager."graphical-home" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.self.modules.homeManager; [
        home
        browser
        konsole
        office
        vscode
      ];

      config = lib.mkIf (lib.attrByPath [ "my" "host" "features" "gui" ] false config) {
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
