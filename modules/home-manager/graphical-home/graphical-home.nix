{
  inputs,
  ...
}:
{
  flake.modules.homeManager."graphical-home" =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        home
        browser
        office
      ];

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
        vlc
      ];
    };
}
