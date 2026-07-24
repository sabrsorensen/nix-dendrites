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
        (
          final: prev:
          let
            patool = prev.python314Packages.patool.overrideAttrs (_: {
              # Patool 4.0.5's archive-discovery tests assume older file and
              # compressor behavior. Bottles needs Patool at runtime, but not
              # this incompatible test suite.
              doInstallCheck = false;
            });
          in
          {
            openldap = prev.openldap.overrideAttrs (_: {
              doCheck = false;
            });
            bottles-unwrapped = prev.bottles-unwrapped.overrideAttrs (old: {
              propagatedBuildInputs = map (
                dependency: if ((dependency.pname or null) == "patool") then patool else dependency
              ) old.propagatedBuildInputs;
            });
            bottles = prev.bottles.override {
              bottles-unwrapped = final.bottles-unwrapped;
            };
          }
        )
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
