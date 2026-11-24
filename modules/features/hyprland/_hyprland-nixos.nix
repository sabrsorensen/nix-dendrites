{ inputs, pkgs, ... }:
let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # Installs Hyprland, registers its session with the display manager, and
  # sets up xdg-desktop-portal-hyprland, polkit and the Wayland session
  # plumbing that the Home Manager module deliberately leaves to NixOS.
  # Enabling this feature defaults features.sddm on, which lists the session.
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  hardware.graphics = {
    package = pkgs-unstable.mesa;
    enable32Bit = true;
    package32 = pkgs-unstable.pkgsi686Linux.mesa;
  };
}
