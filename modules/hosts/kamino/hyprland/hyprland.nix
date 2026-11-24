{ ... }:
{
  # Kamino's Hyprland deltas on top of modules/features/hyprland.
  flake.modules.nixos.hyprland-kamino =
    { config, lib, ... }:
    lib.mkIf
      (config.my.host.name == "Kamino" && config.my.host.features.hyprland && config.my.host.home.enable)
      {
        home-manager.users.${config.my.host.home.username}.wayland.windowManager.hyprland.settings =
          import ./_hyprland.nix;
      };
}
