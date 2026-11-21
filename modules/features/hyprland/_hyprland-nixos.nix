{ ... }:
{
  # Installs Hyprland, registers its session with the display manager, and
  # sets up xdg-desktop-portal-hyprland, polkit and the Wayland session
  # plumbing that the Home Manager module deliberately leaves to NixOS.
  # Enabling this feature defaults features.sddm on, which lists the session.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
