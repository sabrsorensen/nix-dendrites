{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    cura-appimage
    hunspell
    hunspellDicts.en_US
    keymapp
    libreoffice-qt
    lshw
    orca-slicer
    prismlauncher
    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        pyqt5
        requests
      ]
    ))
    qt5.qtbase
    qt5.qttools
    qt5.qtwayland
    qt5.qtx11extras
    unstable.uv
    xwayland
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "discord"
      "keymapp"
      "nvidia-persistenced"
      "nvidia-settings"
      "nvidia-x11"
      "plex-desktop"
      "steam"
      "steam-unwrapped"
    ];
}
