{
  xdg.configFile."autostart/steam.desktop".text = ''
    [Desktop Entry]
    Name=Steam
    Comment=Application for managing and playing games on Steam
    Exec=steam -silent %U
    Icon=steam
    Terminal=false
    Type=Application
    Categories=Network;FileTransfer;Game;
    PrefersNonDefaultGPU=true
    X-KDE-RunOnDiscreteGpu=true
  '';
}
