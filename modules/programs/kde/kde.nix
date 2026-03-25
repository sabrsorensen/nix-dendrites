{
  pkgs,
  ...
}:
{
  flake.modules.nixos.kde = {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager = {
        sddm.enable = true;
      };
      # Enable geoclue2 service
      # Used by KDE to obtain location
      geoclue2.enable = true;
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      kate
    ];

    programs = {
      kdeconnect.enable = true;
      partition-manager.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kcalc
      kdePackages.krdc
    ];
  };
}