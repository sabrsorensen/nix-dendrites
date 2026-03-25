{
  flake.modules.nixos.flatpak = {
    services.flatpak = {
      enable = true;
      uninstallUnmanaged = true;
      packages = [
        "com.fastmail.Fastmail"
        "dev.krtirtho.Flemozi"
      ];
    };
  };
}