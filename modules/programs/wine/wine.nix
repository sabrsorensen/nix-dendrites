{
  lib,
  pkgs,
  ...
}:
{
  flake.modules.nixos.wine =
  {
    pkgs,
    ...
  }:
  {
    # Enable Wine with WoW64 support for running 32-bit and 64-bit Windows apps
    environment.systemPackages = with pkgs; [
      # Wine with 64-bit and 32-bit support
      wineWow64Packages.stable

      # Bottles for easy Wine prefix management
      bottles

      # Winetricks for easy Windows component installation
      winetricks

      # Wine utilities
      wine-staging # Alternative wine with additional patches

      # Windows fonts for better compatibility
      corefonts
      vista-fonts
    ];

    # Enable 32-bit support in nixpkgs for Wine
    nixpkgs.config = {
      allowUnfree = true;
      # Enable 32-bit support for Wine
      allowUnsupportedSystem = true;
    };

    # Wine-specific system configuration
    programs.dconf.enable = true; # Required for Bottles GUI

    # Fonts needed for Windows applications
    fonts.packages = with pkgs; [
      corefonts
      vista-fonts
      liberation_ttf
      dejavu_fonts
    ];

    # Audio support for Wine applications
    hardware.pulseaudio.support32Bit = true;

    # Graphics drivers 32-bit support (you already have NVIDIA configured)
    hardware.opengl = {
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [
        # Add 32-bit graphics packages if needed
      ];
    };

    # Allow unfree packages needed for Wine and Windows apps
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "corefonts"
        "vista-fonts"
      ];
  };
}