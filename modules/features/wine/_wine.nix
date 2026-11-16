{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # WoW64 Wine runs both 32- and 64-bit Windows apps from one prefix.
    wineWow64Packages.stable
    winetricks
    # Bottles for GUI Wine prefix management
    bottles
  ];

  # Wine/Proton use /dev/ntsync for in-kernel NT sync primitives when present
  # (mainline since 6.14, built as a module); otherwise they fall back to
  # wineserver round-trips.
  boot.kernelModules = [ "ntsync" ];

  # Required for the Bottles GUI.
  programs.dconf.enable = true;

  # Windows fonts for app compatibility.
  fonts.packages = with pkgs; [
    corefonts
    vista-fonts
    liberation_ttf
    dejavu_fonts
  ];

  # 32-bit Mesa/Vulkan for 32-bit Windows apps. (32-bit audio comes from
  # features.audio's PipeWire alsa.support32Bit.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  my.unfreePackageNames = [
    "corefonts"
    "vista-fonts"
  ];
}
