{ ... }:
{
  # Kamino's niri deltas on top of modules/features/niri.
  flake.modules.nixos.niri-kamino =
    { config, lib, ... }:
    lib.mkIf
      (config.my.host.name == "Kamino" && config.my.host.features.niri && config.my.host.home.enable)
      {
        home-manager.users.${config.my.host.home.username}.wayland.windowManager.niri.settings =
          import ./_niri.nix;
      };
}
