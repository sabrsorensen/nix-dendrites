{
  steamUser ? "sam",
}:
{
  lib,
  pkgs,
  ...
}:
{
  jovian = {
    devices.steamdeck.enable = true;
    hardware.has.amd.gpu = true;
    steam = {
      autoStart = true;
      enable = true;
      environment = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
      };
      updater.splash = "jovian";
      user = steamUser;
      desktopSession = "plasma";
    };
  };

  # This is the core CJK font fix for Steam
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraLibraries =
        pkgs: with pkgs; [
          # Font packages for CJK and emoji support
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          source-han-sans
          source-han-serif
          source-han-mono
          fontconfig
        ];
    };
  };

  programs.steam = {
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
