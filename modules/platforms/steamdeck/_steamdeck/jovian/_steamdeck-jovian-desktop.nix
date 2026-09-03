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
      maliit-keyboard
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
  services.flatpak.enable = true;
  programs.kdeconnect.enable = lib.mkIf (
    !builtins.elem "bootstrap" config.my.host.tags && !builtins.elem "installer" config.my.host.tags
  ) true;
  services.flatpak.packages =
    lib.mkIf
      (!builtins.elem "bootstrap" config.my.host.tags && !builtins.elem "installer" config.my.host.tags)
      [
        "io.github.Geocld.XStreamingDesktop"
        "io.github.unknownskl.greenlight"
      ];
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
}
