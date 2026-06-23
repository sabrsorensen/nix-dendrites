{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    hunspell
    hunspellDicts.en_US
    # libreoffice-qt
    lshw
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
    uv
    xwayland
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "discord"
      "nvidia-persistenced"
      "nvidia-settings"
      "nvidia-x11"
      "plex-desktop"
      "steam"
      "steam-unwrapped"
    ];
}
