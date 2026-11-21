{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Shared by features.desktop hosts (SDDM) and the Steam Deck (Jovian picks
  # the session; see modules/platforms/steamdeck). features.desktop defaults
  # this feature on.
  services.desktopManager.plasma6.enable = true;
  # Unlock the KDE wallet from the SDDM login password. Gated on the repo's
  # greeter, not services.displayManager.sddm: Jovian runs SDDM for its
  # passwordless autologin, where there is no password to unlock with.
  security.pam.services.sddm.kwallet.enable = lib.mkIf config.my.host.features.sddm true;
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
    # Not on bootstrap/installer images (EmeraldEcho's pre-enrollment stages).
    kdeconnect.enable = lib.mkIf config.my.host.is.finalSystem true;
    partition-manager.enable = true;
  };
  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    krdc
  ];
}
