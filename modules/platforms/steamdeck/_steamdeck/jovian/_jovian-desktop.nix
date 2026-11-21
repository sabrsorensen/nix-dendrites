{
  config,
  lib,
  pkgs,
  ...
}:
{
  # The Plasma session, KDE apps and portal come from features.plasma
  # (modules/features/plasma/_plasma-nixos.nix).
  services.xserver.xkb = {
    layout = "us";
    variant = "dvorak";
  };
  environment = {
    systemPackages = with pkgs; [
      age
      curl
      gh
      git
      htop
      jovianPackages.jupiter-dock-updater-bin
      lm_sensors.bin
      nix-output-monitor
      nix-tree
      openssh
      rsync
      sops
      ssh-to-age
      jovianPackages.steamdeck-firmware
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
  # Flatpak itself (service, shared app list, remotes) comes from the
  # features/flatpak module; only the Steam Deck-specific apps live here.
  my.host.features.flatpak = lib.mkIf config.my.host.is.finalSystem (lib.mkDefault true);
  # Keep hand-installed Flatpaks (e.g. a locally built Pulsar that isn't
  # published to any remote yet) instead of pruning everything unmanaged.
  services.flatpak.uninstallUnmanaged = lib.mkForce false;
  services.flatpak.packages = lib.mkIf config.my.host.features.flatpak [
    "io.github.Geocld.XStreamingDesktop"
    "io.github.streetpea.Chiaki4deck"
    "io.github.unknownskl.greenlight"
  ];
}
