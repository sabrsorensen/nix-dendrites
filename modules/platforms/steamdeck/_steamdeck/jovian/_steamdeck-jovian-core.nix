{
  lib,
  pkgs,
  ...
}:
{
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };
  jovian = {
    devices.steamdeck.enable = true;
    hardware.has.amd.gpu = true;
    steam = {
      autoStart = true;
      enable = true;
      user = "sam";
      # Jovian validates this against installed display-manager sessions.
      # Enable Plasma below so Desktop Mode is both valid and available.
      desktopSession = "plasma";
      updater.splash = "jovian";
      environment = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
      };
    };
  };
  programs.steam = {
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraPackages = [ pkgs.hidapi ];
  };
  # Steam's bundled runtime needs these fonts available as extra
  # libraries for CJK and emoji text in Gaming Mode.
  nixpkgs.config.packageOverrides = pkgs': {
    steam = pkgs'.steam.override {
      extraLibraries =
        steamPkgs: with steamPkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          source-han-sans
          source-han-serif
          source-han-mono
          fontconfig
        ];
    };
  };
  nix.settings = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    cores = 0;
    download-buffer-size = 1073741824;
    extra-substituters = [ "https://jovian-experiments.cachix.org" ];
    extra-trusted-public-keys = [
      "jovian-experiments.cachix.org-1:lwPS3KgK5sJlI2B9KBY4VpbWNGbAjCcKVkUyqfzVrJE="
    ];
    # The Steam Deck has limited storage, so retain fewer build outputs.
    keep-derivations = lib.mkForce false;
    keep-outputs = lib.mkForce false;
    max-jobs = "auto";
  };
  programs.nh.clean.extraArgs = lib.mkForce "--keep-since 2d --keep 2";
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];
}
