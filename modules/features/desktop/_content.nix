{ pkgs, ... }:
{
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
    xserver.xkb = {
      # Keep US QWERTY as the login default, with Dvorak available before
      # authentication through Ctrl+Shift in SDDM and the Plasma session.
      layout = "us,us";
      variant = ",dvorak";
      options = "grp:ctrl_shift_toggle";
    };
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
    kdeconnect.enable = true;
    partition-manager.enable = true;
  };
  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kdePackages.krdc
  ];
}
