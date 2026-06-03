{
  systemPackages =
    pkgs: with pkgs; [
      # bitwarden-desktop
      deskflow
      noson
      rclone
      signal-desktop
      vlc
    ];

  homePackages =
    pkgs: with pkgs; [
      # bitwarden-desktop
      ferdium
      noson
      p7zip
      rclone
      signal-desktop
      vlc
    ];
}
