{ ... }:
{
  flake.modules.nixos.wine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.wine {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
      environment.systemPackages = with pkgs; [
        wineWow64Packages.stable
        bottles
        winetricks
        wine-staging
        corefonts
        vista-fonts
      ];
      nixpkgs.overlays = [
        (final: prev: {
          openldap = prev.openldap.overrideAttrs (_: {
            doCheck = false;
          });
        })
      ];
      programs.dconf.enable = true;
      fonts.packages = with pkgs; [
        corefonts
        vista-fonts
        liberation_ttf
        dejavu_fonts
      ];
      services.pulseaudio.support32Bit = true;
      hardware.graphics.enable32Bit = true;
      my.unfreePackageNames = [
        "corefonts"
        "vista-fonts"
      ];
    };
}
