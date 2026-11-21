{ lib, ... }:
{
  # Lists every registered session (Plasma, Hyprland, niri). Plasma-specific
  # PAM (kwallet) lives in features.plasma.
  services.displayManager.sddm = {
    enable = true;
    # SDDM needs X or a Wayland greeter, and a Hyprland/niri-only host has no
    # X. Same value plasma6 already mkDefaults, so Plasma hosts are unchanged.
    wayland.enable = lib.mkDefault true;
  };
}
