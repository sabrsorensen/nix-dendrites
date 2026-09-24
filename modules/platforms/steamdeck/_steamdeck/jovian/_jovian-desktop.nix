{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.partition-manager.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "dvorak";
  };
  environment = {
    plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      kate
    ];
    systemPackages = with pkgs; [
      age
      curl
      gh
      git
      htop
      jupiter-dock-updater-bin
      kdePackages.kcalc
      kdePackages.krdc
      lm_sensors.bin
      nix-output-monitor
      nix-tree
      openssh
      rsync
      sops
      ssh-to-age
      steamdeck-firmware
      vim
      wget
    ];
    variables = {
      FONTCONFIG_PATH = "/run/current-system/sw/etc/fonts";
      FONTCONFIG_FILE = "/run/current-system/sw/etc/fonts/fonts.conf";
    };
  };
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-mono
      source-han-sans
      source-han-serif
    ];
  };
  programs.kdeconnect.enable = lib.mkIf config.my.host.is.finalSystem true;
  # Flatpak itself (service, shared app list, remotes) comes from the
  # features/flatpak module; only the Steam Deck-specific apps live here.
  my.host.features.flatpak = lib.mkIf config.my.host.is.finalSystem (lib.mkDefault true);
  # Keep hand-installed Flatpaks (e.g. a locally built Pulsar that isn't
  # published to any remote yet) instead of pruning everything unmanaged.
  services.flatpak.uninstallUnmanaged = lib.mkForce false;
  services.flatpak.packages = lib.mkIf config.my.host.features.flatpak [
    "io.github.Geocld.XStreamingDesktop"
    "io.github.unknownskl.greenlight"
  ];
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
}
