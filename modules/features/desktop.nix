{ ... }:
{
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.is.desktopSession {
      services.xserver = {
        enable = true;
        videoDrivers = [
          "nvidia"
          "intel"
          "modesetting"
        ];
      };
      services = {
        desktopManager.plasma6.enable = true;
        displayManager.sddm.enable = true;
        geoclue2.enable = true;
      };
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
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
