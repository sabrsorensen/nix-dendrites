{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    videoDrivers = [
      "intel"
      "modesetting"
    ];
  };
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    geoclue2.enable = true;
  };
  security.pam.services.sddm.kwallet.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
  ];
  programs = {
    # plasma6 mkDefault-enables this, and it adds kmail/kontact/merkuro/akonadi
    # to systemPackages directly -- excludePackages can't remove them.
    kde-pim.enable = false;
    kdeconnect.enable = true;
    partition-manager.enable = true;
  };
  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kdePackages.krdc
  ];
}
