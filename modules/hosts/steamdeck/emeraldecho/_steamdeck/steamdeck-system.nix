{ lib, pkgs, ... }:
{
  networking.hostName = "EmeraldEcho";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  nix.settings = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    cores = 0;
    download-buffer-size = 1073741824;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://cache.thalheim.io" ];
    extra-trusted-public-keys = [ "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=" ];
    max-jobs = "auto";
  };

  # The Deck has limited internal storage, so prefer a smaller retained Nix
  # footprint than the shared workstation defaults.
  programs.nh.clean.extraArgs = lib.mkForce "--keep-since 2d --keep 2";
  nix = {
    settings = {
      keep-derivations = lib.mkForce false;
      keep-outputs = lib.mkForce false;
    };
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    rsync
    vim
    wget
    openssh
    ssh-to-age
    age
    sops
    gh
    nix-tree
    nix-output-monitor
    maliit-keyboard
    jupiter-dock-updater-bin
    steamdeck-firmware
  ];

  environment.variables = {
    FONTCONFIG_PATH = "/run/current-system/sw/etc/fonts";
    FONTCONFIG_FILE = "/run/current-system/sw/etc/fonts/fonts.conf";
  };

  # Might be useful for CJK fonts outside of Steam?
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      source-han-sans
      source-han-serif
      source-han-mono
      nerd-fonts.hack
    ];
  };

  time.timeZone = lib.mkForce "America/Denver"; # Force timezone to one recognized by Steam
  i18n.defaultLocale = "en_US.UTF-8";

  users.groups.plugdev = { };
  users.groups.input = { };

  console.keyMap = "dvorak";
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "dvorak";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  services.flatpak.enable = true;

  system.stateVersion = "26.05";

  # Disable drkonqi crash handler to prevent Qt6-related boot slowdowns
  #systemd.services."drkonqi-coredump-launcher@" = {
  #  enable = false;
  #};
  #systemd.services."drkonqi-coredump-processor@" = {
  #  enable = false;
  #};
  ## Disable coredump handling to prevent cascade crashes
  #systemd.settings.Manager = {
  #  DefaultLimitCORE = 0;
  #};
}
